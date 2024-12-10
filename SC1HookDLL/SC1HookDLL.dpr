library SC1HookDLL;

uses
     HookDLL in '..\HookDLL.pas',
     HookDDraw in '..\HookDDraw.pas';

{$R *.res}

procedure h_TranslateMessage; stdcall; assembler;
asm
     pushad
     call CheckAndFixCursor
     popad
     pop ebx
     pop eax
     push eax
     mov eax, [ClrCallAddr]
     call dword ptr [eax]
     push ebx
end;

exports
     h_DirectDrawCreateEx name 'DirectDrawCreateEx';

begin
     Sequence := [$C7, $02, $01, $00, $00, $00, $8D, $45, $90, $50, $FF, $15];
     CodeOffset := $0C;
     ReplFunc := h_TranslateMessage;
     InitDLL;
end.
