library DevHookDLL;

uses
     HookDLL in '..\HookDLL.pas',
     HookDDraw in '..\HookDDraw.pas';

{$R *.res}

exports
     h_DirectDrawCreate name 'DirectDrawCreate';

begin
     Sequence := [$53, $56, $8B, $F1, $8B, $08, $33, $DB,
          $3B, $CB, $57, $89, $65, $F0];
     CodeOffset := $2A;
     InitDLL;
end.
