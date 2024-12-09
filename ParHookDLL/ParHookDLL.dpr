library ParHookDLL;

uses
     HookDLL in '..\HookDLL.pas',
     Winapi.DirectDraw;

{$R *.res}

exports
     DirectDrawCreate;

begin
     Sequence := [$53, $55, $56, $57, $89, $4C, $24, $10,
          $8B, $08, $33, $FF, $3B, $CF];
     CodeOffset := $2A;
     InitDLL;
end.
