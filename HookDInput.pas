unit HookDInput;

interface

uses
     Winapi.Windows,
     System.SysUtils,
     Winapi.DirectInput;

function h_DirectInputCreateA(hinst: THandle; dwVersion: DWORD; out ppDI: IDirectInputA; punkOuter: IUnknown): HResult; stdcall;
function h_DirectInputCreateEx(hinst: THandle; dwVersion: DWORD; const riidltf: TGUID; out ppvOut: Pointer; punkOuter: IUnknown): HResult; stdcall;

implementation
uses
     HookDLL; //, OldDirectInput;

const
     DLLName = 'dinput.dll';

var
     realDLL: HMODULE = 0;
     r_DirectInputCreateA: function (hinst: THandle; dwVersion: DWORD;
          out ppDI: IDirectInputA; punkOuter: IUnknown): HResult; stdcall;
     r_DirectInputCreateEx: function (hinst: THandle; dwVersion: DWORD;
          const riidltf: TGUID; out ppvOut{: Pointer}; punkOuter: IUnknown): HResult; stdcall;

procedure CheckAndLoadDLL;
var
     DLLpath: string;
begin
     if realDLL <> 0 then
          Exit;
     DLLpath :=  IncludeTrailingPathDelimiter(GetSysDir) + DLLName;
     realDLL := LoadLibrary(LPCWSTR(DLLpath));
     if realDLL <> 0 then
          WriteToLog('Loading real DLL done!')
     else
          WriteToLog('*** Loading real DLL FAILED !!! ***');
end;

function CheckAndLoadRealFunc(const HookFuncName: string): Pointer;
begin
     CheckAndLoadDLL;
     Result := GetProcAddress(realDLL, LPCWSTR(HookFuncName));
     if Addr(Result) <> nil then
          WriteToLog('Loading real ' + HookFuncName + ' function done!')
     else
          WriteToLog('*** Loading real ' + HookFuncName + ' function FAILED !!! ***');
end;

function h_DirectInputCreateA(hinst: THandle; dwVersion: DWORD; out ppDI: IDirectInputA; punkOuter: IUnknown): HResult; stdcall;
const
     HookFuncName = 'DirectInputCreateA';
begin
     WriteToLog(HookFuncName + ' called');
     r_DirectInputCreateA := CheckAndLoadRealFunc(HookFuncName);
     WriteToLog('Transferring control to the real ' + HookFuncName + ' function...');
     Result := r_DirectInputCreateA(hinst, dwVersion, ppDI, punkOuter);
end;

function h_DirectInputCreateEx(hinst: THandle; dwVersion: DWORD; const riidltf: TGUID;
     out ppvOut: Pointer; punkOuter: IUnknown): HResult; stdcall;
const
     HookFuncName = 'DirectInputCreateEx';
begin
     WriteToLog(HookFuncName + ' called');
     r_DirectInputCreateEx := CheckAndLoadRealFunc(HookFuncName);
     WriteToLog('Transferring control to the real ' + HookFuncName + ' function...');
     Result := r_DirectInputCreateEx(hinst, dwVersion, riidltf, ppvOut, punkOuter);
end;

end.