library DX1HookDLL;

uses
     HookDLL in '..\HookDLL.pas',
     HookDDraw in '..\HookDDraw.pas';

{$R *.res}

procedure h_TranslateMessage; assembler; stdcall;
asm
     pushad
     call CheckAndFixCursor
     popad
     pop esi
     mov eax, [ClrCallAddr]
     call dword ptr [eax]
     push esi
end;

exports
     h_DirectDrawCreate name 'DirectDrawCreate',
     h_DirectDrawEnumerateExA name 'DirectDrawEnumerateExA';

begin
     Sequence := [$C6, $45, $FC, $08, $8D, $4D, $98, $51, $FF, $15];
     CodeOffset := $0A;
     BytesCount := $10;
     ReplFunc := h_TranslateMessage;
     InitDLL;
end.
