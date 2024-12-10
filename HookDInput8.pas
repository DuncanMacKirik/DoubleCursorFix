unit HookDInput8;

interface

uses
     Winapi.Windows,
     System.SysUtils,
     Winapi.DirectInput;

function h_DirectInput8Create(hinst: THandle; dwVersion: DWORD; const riidltf: TGUID;
     out ppvOut: Pointer; punkOuter: IUnknown): HResult; stdcall;

implementation
uses
     HookDLL; //, OldDirectInput;

const
     DLLName = 'dinput8.dll';

var
     realDLL: HMODULE = 0;
     r_DirectInput8Create: function (hinst: THandle; dwVersion: DWORD; const riidltf: TGUID;
          out ppvOut: Pointer; punkOuter: IUnknown): HResult; stdcall;

procedure CheckAndLoadDLL;
var
     DLLpath: string;
begin
     if realDLL <> 0 then
          Exit;
     DLLpath :=  IncludeTrailingPathDelimiter(GetSysDir) + DLLName;
     realDLL := LoadLibrary(LPCWSTR(DLLpath));
     if realDLL <> 0 then
          WriteToLog('Loading real DLL done!')
     else
          WriteToLog('*** Loading real DLL FAILED !!! ***');
end;

function CheckAndLoadRealFunc(const HookFuncName: string): Pointer;
begin
     CheckAndLoadDLL;
     Result := GetProcAddress(realDLL, LPCWSTR(HookFuncName));
     if Addr(Result) <> nil then
          WriteToLog('Loading real ' + HookFuncName + ' function done!')
     else
          WriteToLog('*** Loading real ' + HookFuncName + ' function FAILED !!! ***');
end;

function h_DirectInput8Create(hinst: THandle; dwVersion: DWORD; const riidltf: TGUID;
     out ppvOut: Pointer; punkOuter: IUnknown): HResult; stdcall;
const
     HookFuncName = 'DirectInput8Create';
begin
     WriteToLog(HookFuncName + ' called');
     r_DirectInput8Create := CheckAndLoadRealFunc(HookFuncName);
     WriteToLog('Transferring control to the real ' + HookFuncName + ' function...');
     Result := r_DirectInput8Create(hinst, dwVersion, riidltf, ppvOut, punkOuter);
end;

end.