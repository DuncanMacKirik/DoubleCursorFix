library IGI2HookDLL;

uses
     HookDLL in '..\HookDLL.pas',
     HookDInput8 in '..\HookDInput8.pas';

{$R *.res}

exports
     h_DirectInput8Create name 'DirectInput8Create';

procedure h_TranslateMessage; stdcall; assembler;
asm
     pushad
     call CheckAndFixCursor
     popad
     pop esi
     pop eax
     push eax
     mov eax, [ClrCallAddr]
     call dword ptr [eax]
     push esi
end;

begin
     Sequence := [$8D, $4C, $24, $4C, $51, $FF, $15];
     CodeOffset := $07;
     ReplFunc := h_TranslateMessage;
     InitDLL;
end.
