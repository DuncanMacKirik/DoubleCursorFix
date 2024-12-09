library TVHookDLL;

uses
     HookDLL in '..\HookDLL.pas',
     Winapi.DirectDraw;

{$R *.res}

exports
     DirectDrawCreate;

begin
     Sequence := [$53, $56, $8B, $F1, $83, $38, $00, $57,
          $89, $65, $F0, $0F, $84];
     CodeOffset := $28;
     InitDLL;
end.
