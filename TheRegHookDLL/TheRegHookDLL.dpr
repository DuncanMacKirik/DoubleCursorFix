library TheRegHookDLL;

uses
     HookDLL in '..\HookDLL.pas',
     HookDDraw in '..\HookDDraw.pas';

{$R *.res}

procedure h_GameTick; assembler; stdcall;
asm
     pushad
     call CheckAndFixCursor
     popad
     pop edx

     mov eax, fs:[0]
     push eax
     push edx
end;

exports
     h_DirectDrawCreate name 'DirectDrawCreate',
     h_DirectDrawCreateEx name 'DirectDrawCreateEx',
     h_DirectDrawEnumerateExA name 'DirectDrawEnumerateExA';

begin
     Sequence := [$33, $FF,   // xor edi, edi
          $89, $7D, $FC,      // mov [ebp-4], edi
          $C6, $45, $FC, $01, // mov byte ptr [ebp-4], 1
          $0F, $31,           // rdtsc
          $F7, $D8];          // neg eax
     CodeOffset := -42;
     DumpOffset := -43;
     BytesCount := $10;
     WriteNewBytes := True;
     NewBytesOffset := -43;
     NewBytes := [$B8, $FF, $FF, $FF, $FF,   // mov eax, ...
          $FF, $D0];                         // call eax
     ReplFunc := h_GameTick;
     DirectCall := True;
     DoNotReVP := True;
     InitDLL;
end.
