unit HookDDraw;

interface

uses
     Winapi.Windows,
     System.SysUtils,
     Winapi.DirectDraw;

function h_DirectDrawCreateEx(lpGUID: PGUID; out lplpDD: IDirectDraw7;
    const iid: TGUID; pUnkOuter: IUnknown): HResult; stdcall;
function h_DirectDrawEnumerateExA(lpCallback: TDDEnumCallbackExA; lpContext: Pointer;
     dwFlags: DWORD): HResult; stdcall;

implementation
uses
     HookDLL;

const
     DLLName = 'ddraw.dll';

var
     realDLL: HMODULE = 0;
     r_DirectDrawCreateEx: function (lpGUID: PGUID; out lplpDD: IDirectDraw7;
          const iid: TGUID; pUnkOuter: IUnknown): HResult; stdcall;
     r_DirectDrawEnumerateExA: function (lpCallback: TDDEnumCallbackExA;
          lpContext: Pointer; dwFlags: DWORD): HResult; stdcall;

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

function h_DirectDrawCreateEx(lpGUID: PGUID; out lplpDD: IDirectDraw7;
    const iid: TGUID; pUnkOuter: IUnknown): HResult; stdcall;
const
     HookFuncName = 'DirectDrawCreateEx';
begin
     WriteToLog(HookFuncName + ' called');
     r_DirectDrawCreateEx := CheckAndLoadRealFunc(HookFuncName);
     WriteToLog('Transferring control to the real ' + HookFuncName + ' function...');
     Result := r_DirectDrawCreateEx(lpGUID, lplpDD, iid, pUnkOuter);
end;

function h_DirectDrawEnumerateExA(lpCallback: TDDEnumCallbackExA; lpContext: Pointer;
     dwFlags: DWORD): HResult; stdcall;
const
     HookFuncName = 'DirectDrawEnumerateExA';
begin
     WriteToLog(HookFuncName + ' called');
     r_DirectDrawEnumerateExA := CheckAndLoadRealFunc(HookFuncName);
     WriteToLog('Transferring control to the real ' + HookFuncName + ' function...');
     Result := r_DirectDrawEnumerateExA(lpCallback, lpContext, dwFlags);
end;

end.