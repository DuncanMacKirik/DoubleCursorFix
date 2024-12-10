library A51HookDLL;

uses
     HookDLL in '..\HookDLL.pas',
     HookDInput8 in '..\HookDInput8.pas';

{$R *.res}

exports
     h_DirectInput8Create name 'DirectInput8Create';

procedure h_GetTickCount; stdcall; assembler;
asm
     pushad
     call CheckAndFixCursor
     popad
     mov eax, [ClrCallAddr]
     call dword ptr [eax]
end;

begin
     Sequence := [$FF, $D3, $6A, $00, $6A, $00, $6A, $00, $6A, $00, $68, $40];
     CodeOffset := $2D;
     ReplFunc := h_GetTickCount;
     InitDLL;
end.
