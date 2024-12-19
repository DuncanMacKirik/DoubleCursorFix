library KswHookDLL;

uses
     HookDLL in '..\HookDLL.pas',
     HookDSound in '..\HookDSound.pas';
     //HookDInput8 in '..\HookDInput8.pas';


{$R *.res}

exports
     h_DirectSoundCreate name 'DirectSoundCreate',
     h_DirectSoundEnumerateW name 'DirectSoundEnumerateW',
     h_DirectSoundCaptureCreate name 'DirectSoundCaptureCreate',
     h_DirectSoundCaptureEnumerateW name 'DirectSoundCaptureEnumerateW',
     h_DirectSoundCreate8 name 'DirectSoundCreate8';

procedure h_DispatchMessageA; stdcall; assembler;
asm
     pushad
     call CheckAndFixCursor
     popad
     pop ebx
     mov eax, [OldCallAddr]
     call dword ptr [eax]
     push ebx
end;

begin
     Sequence := [$8D, $4C, $24, $0C, $51, $FF, $D5, $8D, $54, $24, $0C, $52,
          $FF, $15];
     CodeOffset := $0E;
     ReplFunc := h_DispatchMessageA;
     BytesCount := $20;
     MaxCallCount := 8;
     InitDLL;
end.
