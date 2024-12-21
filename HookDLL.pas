unit HookDLL;


interface

procedure InitDLL;
procedure h_StatsClear; stdcall;
procedure CheckAndFixCursor; stdcall;

var
     Sequence: array of Byte;
     CodeOffset: Int32;
     OldCallAddr: Pointer = nil;
     MaxCallCount: Integer = 60;
     ReplFunc: procedure stdcall = h_StatsClear;
     BytesCount: Integer = $30;
     DumpOffset: Integer = 0;
     CallIsRelative: Boolean = False;
     CallInstrSize: Integer = 5;
     WriteNewBytes: Boolean = False;
     NewBytes: array of Byte;
     NewBytesOffset: Int32;
     DirectCall: Boolean = False;
     DoNotReVP: Boolean = False;

function GetSysDir: string;
procedure WriteToLog(const Msg: AnsiString);
procedure DumpBytes(const Prefix: AnsiString = ''; p: PByte = nil; Count: Integer = 0);


implementation

uses
     System.SysUtils,
     System.Classes,
     Windows;

var
     JobDone: Boolean = False;
     CallCounter: Integer = 0;
     NewCallAddr: Pointer = nil;
     LogFilename: AnsiString = '_hook.log';

// PEB definitions courtesy of Mormot Framework
type
  _PPS_POST_PROCESS_INIT_ROUTINE = ULONG;

  PUNICODE_STRING = ^UNICODE_STRING;
  UNICODE_STRING = packed record
    Length: word;
    MaximumLength: word;
    {$ifdef CPUX64}
    _align: array[0..3] of byte;
    {$endif}
    Buffer: PWideChar;
  end;

  PMS_PEB_LDR_DATA = ^MS_PEB_LDR_DATA;
  MS_PEB_LDR_DATA = packed record
    Reserved1: array[0..7] of BYTE;
    Reserved2: array[0..2] of pointer;
    InMemoryOrderModuleList: LIST_ENTRY;
  end;

  PMS_RTL_USER_PROCESS_PARAMETERS = ^MS_RTL_USER_PROCESS_PARAMETERS;
  MS_RTL_USER_PROCESS_PARAMETERS = packed record
    Reserved1: array[0..15] of BYTE;
    Reserved2: array[0..9] of pointer;
    ImagePathName: UNICODE_STRING;
    CommandLine: UNICODE_STRING ;
  end;

  PMS_PEB = ^MS_PEB;
  MS_PEB = packed record
    Reserved1: array[0..1] of BYTE;
    BeingDebugged: BYTE;
    Reserved2: array[0..0] of BYTE;
    {$ifdef CPUX64}
    _align1: array[0..3] of byte;
    {$endif}
    Reserved3: array[0..1] of pointer;
    Ldr: PMS_PEB_LDR_DATA;
    ProcessParameters: PMS_RTL_USER_PROCESS_PARAMETERS;
    Reserved4: array[0..103] of BYTE;
    Reserved5: array[0..51] of pointer;
    PostProcessInitRoutine: _PPS_POST_PROCESS_INIT_ROUTINE; // for sure not pointer, otherwise SessionId is broken
    Reserved6: array[0..127] of BYTE;
    {$ifdef CPUX64}
    _align2: array[0..3] of byte;
    {$endif}
    Reserved7: array[0..0] of pointer;
    SessionId: ULONG;
    {$ifdef CPUX64}
    _align3: array[0..3] of byte;
    {$endif}
  end;


function AddPtr(const Base: PByte; Offset: Int32): PByte; inline;
begin
     Result := PByte(Int32(Base) + Offset);
end;

function PtrToHex(const P: Pointer): AnsiString; inline;
begin
     Result := '0x' + IntToHex(UInt32(P), 8);
end;

function GetSysDir: string;
var
     Buffer: array[0..MAX_PATH] of Char;
begin
     GetSystemDirectory(Buffer, MAX_PATH - 1);
     SetLength(Result, StrLen(Buffer));
     Result := Buffer;
end;

procedure WriteToLog(const Msg: AnsiString);
{$IFDEF DEBUG}
const
     CRLF: array [0..1] of Byte = ($0D, $0A);
var
     F: TFileStream;
begin
     try
          try
               if FileExists(LogFilename) then
               begin
                    F := TFileStream.Create(LogFilename, fmOpenWrite);
                    F.Seek(0, TSeekOrigin.soEnd);
               end
               else
                    F := TFileStream.Create(LogFilename, fmCreate);
               F.Write(Msg[1], Length(Msg));
               F.Write(CRLF[0], 2);
          finally
               FreeAndNil(F);
          end;
     except
          // what can we do, anyway?
     end;
{$ELSE}
begin
{$ENDIF}
end;

procedure DumpBytes(const Prefix: AnsiString = ''; p: PByte = nil; Count: Integer = 0);
{$IFDEF DEBUG}
var
     S: AnsiString;
     i: Integer;
begin
     S := '';
     if DumpOffset <> 0 then
          p := PByte(Int32(p) + DumpOffset);
     for i := 1 to Count do
     begin
          S := S + IntToHex(p^, 2);
          Inc(p);
          if i <> Count then
               S := S + ' ';
     end;
     WriteToLog(Prefix + S);
{$ELSE}
begin
{$ENDIF}
end;

function FindSequence(const StartAddr: PByte;
     const Size: UInt32; var FoundAddr: PByte): Boolean;
var
     i: UInt32;
     P, EndAddr: PByte;
     PS: PByteArray;
     FS: Boolean;
begin
     P := StartAddr;
     EndAddr := AddPtr(StartAddr, Size);
     while P < EndAddr do
     begin
          // find first byte
          if P^ = Sequence[0] then
          begin
               PS := PByteArray(P);
               FS := True;
               for i := 1 to Length(Sequence)-1 do
                    if PS^[i] <> Sequence[i] then
                    begin
                         FS := False;
                         Break;
                    end;
               if FS then
               begin
                    FoundAddr := P;
                    Exit(True);
               end;
          end;
          Inc(P);
     end;
     Result := False;
end;

procedure CheckAndFixCursor; stdcall;
var
     ci: TCURSORINFO;
     Res: LongBool;
begin
     Inc(CallCounter);
     if CallCounter >= MaxCallCount then
     begin
          CallCounter := 0;
          ci.cbSize := sizeof(ci);
          Res := GetCursorInfo(ci);
          if Res then
               if (ci.flags = CURSOR_SHOWING) then
                    ShowCursor(False);
     end;
end;

procedure h_StatsClear; stdcall; assembler;
asm
     pushad
     call CheckAndFixCursor
     popad
     mov eax, [OldCallAddr]
     call dword ptr [eax]
end;

procedure DoTheJob;
var
     PEB: PMS_PEB;
     ImgBase, P_VP, P_OEP: PByte;
     o_p, o_p2, sz_VP: DWORD;
     DosHdr: PImageDosHeader;
     WinHdr: PImageNtHeaders32;
     MinOfs, MaxOfs, FoundAddr, WriteAddr: PByte;
     CallAddr: PPointer;
begin
     try
          try
               WriteToLog('Hook worked!');
               asm
                   push eax
                   mov eax, fs:[30h]
                   mov dword ptr [PEB], eax
                   pop eax
               end;
               WriteToLog('PEB is at ' + PtrToHex(PEB));
               WriteToLog('PEB Loader Data is at ' + PtrToHex(PEB.Ldr));
               ImgBase := PEB.Reserved3[1];
               WriteToLog('ImageBase = ' + PtrToHex(ImgBase));
               DosHdr := PImageDosHeader(ImgBase);
               if DosHdr.e_magic = $5A4D then
               begin
                    WriteToLog('Found DOS MZ header');
                    WriteToLog('PE header offset: 0x' + IntToHex(DosHdr^._lfanew, 8));
                    WinHdr := PImageNtHeaders32(AddPtr(ImgBase, DosHdr^._lfanew));
                    if WinHdr^.Signature = $4550 then
                    begin
                         WriteToLog('Found Win32 PE header');
                         WriteToLog('EP offset = 0x' + IntToHex(WinHdr^.OptionalHeader.AddressOfEntryPoint, 8));
                         P_OEP := AddPtr(ImgBase, WinHdr^.OptionalHeader.AddressOfEntryPoint);
                         WriteToLog('OEP = ' + PtrToHex(P_OEP));
                         MinOfs := AddPtr(ImgBase, WinHdr.OptionalHeader.BaseOfCode);
                         with WinHdr.OptionalHeader do
                              MaxOfs := AddPtr(ImgBase, BaseOfCode + SizeOfCode);
                         WriteToLog('MinOfs = ' + PtrToHex(MinOfs));
                         WriteToLog('MaxOfs = ' + PtrToHex(MaxOfs));
                         WriteToLog('Searching for code sequence...');
                         if FindSequence(MinOfs, WinHdr.OptionalHeader.SizeOfCode, FoundAddr) then
                         begin
                              WriteToLog('FOUND at: ' + PtrToHex(FoundAddr));
                              CallAddr := PPointer(AddPtr(FoundAddr, CodeOffset));
                              if CallIsRelative then
                              begin
                                   WriteToLog('Call address ' + PtrToHex(CallAddr^) + ' is relative, converting to real:');
                                   OldCallAddr := Pointer(Int32(CallAddr^) - Int32(CallAddr) + CallInstrSize);
                                   WriteToLog(PtrToHex(CallAddr^) + ' - ' + PtrToHex(CallAddr) + ' + ' + CallInstrSize.ToString + ' = ' +
                                        PtrToHex(OldCallAddr)
                                   );
                              end
                              else
                              begin
                                   WriteToLog('Saving call address: ' + PtrToHex(CallAddr^) + ' => [' + PtrToHex(Addr(OldCallAddr)) + ']');
                                   OldCallAddr := CallAddr^;
                              end;
                              WriteToLog('Preparing to patch...');
                              P_VP := AddPtr(ImgBase, WinHdr.OptionalHeader.BaseOfCode);
                              sz_VP := WinHdr.OptionalHeader.SizeOfCode;
                              WriteToLog('Trying to unVP: ' + PtrToHex(P_VP));
                              if VirtualProtect(P_VP, sz_VP, PAGE_EXECUTE_READWRITE, o_p) then
                                   WriteToLog('Success')
                              else
                                   WriteToLog('FAILED');
                              NewCallAddr := Addr(ReplFunc);
                              WriteToLog('Writing hook call address: ' + PtrToHex(NewCallAddr) +
                                   ' => ' + PtrToHex(Addr(NewCallAddr)));
                              DumpBytes('Bytes at code site: ', FoundAddr, BytesCount);
                              if WriteNewBytes then
                              begin
                                   WriteAddr := AddPtr(FoundAddr, NewBytesOffset);
                                   WriteToLog('Writing new bytes to ' + PtrToHex(WriteAddr));
                                   Move(NewBytes[0], WriteAddr^, Length(NewBytes));
                              end;
                              WriteToLog('Patching...');
                              if DirectCall then
                                   CallAddr^ := NewCallAddr
                              else
                                   CallAddr^ := Addr(NewCallAddr);
                              DumpBytes('Bytes after patch:  ', FoundAddr, BytesCount);
                              if DoNotReVP then
                                   WriteToLog('ReVP is not needed.')
                              else
                              begin
                                   WriteToLog('Trying to reVP...');
                                   if VirtualProtect(P_VP, sz_VP, o_p, o_p2) then
                                        WriteToLog('Success')
                                   else
                                        WriteToLog('FAILED');
                              end;
                         end
                         else
                              WriteToLog('NOT FOUND.');
                    end
                         else
                              raise Exception.Create('Win32 PE header not found!');
               end
                    else
                         raise Exception.Create('DOS MZ header not found!');
          except
               on E: Exception do
               begin
                    WriteToLog('*** EXCEPTION CAUGHT: ***');
                    WriteToLog('### ' + E.Message);
                    WriteToLog('*** EXITING... ***');
               end;
          end;
     finally
          JobDone := True;
     end;
end;

procedure InitDLL;
begin
     if not JobDone then
          DoTheJob;
end;

end.