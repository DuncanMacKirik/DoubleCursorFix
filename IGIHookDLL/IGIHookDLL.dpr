library IGIHookDLL;

uses
     HookDLL in '..\HookDLL.pas',
     HookDInput in '..\HookDInput.pas';

{$R *.res}

exports
     h_DirectInputCreateA name 'DirectInputCreateA',
     h_DirectInputCreateEx name 'DirectInputCreateEx';

procedure h_Sleep_500; assembler; stdcall;
asm
     pushad
     call CheckAndFixCursor
     popad
     pop ebx
     pop eax
     push eax
     mov eax, [OldCallAddr]
     call dword ptr [eax]
     push ebx
end;

begin
     Sequence := [$EB, $0B, $68, $F4, $01, $00, $00, $FF, $15];
     CodeOffset := $09;
     ReplFunc := h_Sleep_500;
     //MaxCallCount := 30;
     InitDLL;
end.
