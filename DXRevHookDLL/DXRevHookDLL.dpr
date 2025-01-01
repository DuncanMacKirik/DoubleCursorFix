library DXRevHookDLL;

uses
     HookDLL in '..\HookDLL.pas',
     HookDSound in '..\HookDSound.pas';

{$R *.res}

procedure h_ProcessMsgs; assembler; stdcall;
asm
     pushfd
     pushad
     call CheckAndFixCursor
     popad
     popfd
     lea eax, [esp + 10h]
     push eax
     call ebx
end;

exports
     h_DirectSoundCreate name 'DirectSoundCreate',
     h_DirectSoundEnumerateW name 'DirectSoundEnumerateW',
     h_DirectSoundCaptureCreate name 'DirectSoundCaptureCreate',
     h_DirectSoundCaptureEnumerateW name 'DirectSoundCaptureEnumerateW',
     h_DirectSoundCreate8 index 11 name 'DirectSoundCreate8';

begin
     Sequence := [$8D, $4C, $24, $10, $51, $FF, $D3];
     CodeOffset := 1;
     BytesCount := $10;

     WriteNewBytes := True;
     NewBytesOffset := $00;
     NewBytes := [$B8, $FF, $FF, $FF, $FF,   // mov eax, 0xFFFFFFFF <= new call addr
          $FF, $D0];                         // call eax
     ReplFunc := h_ProcessMsgs;
     DirectCall := True;
     InitDLL;
end.
