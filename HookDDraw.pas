unit HookDDraw;

interface

uses
     Winapi.Windows,
     System.SysUtils,
     Winapi.DirectDraw;

function h_DirectDrawCreateEx(lpGUID: PGUID; out lplpDD: IDirectDraw7;
    const iid: TGUID; pUnkOuter: IUnknown): HResult; stdcall;

implementation
uses
     HookDLL;

const
     HookFuncName = 'DirectDrawCreateEx';

var
     realDLL: HMODULE;
     r_DirectDrawCreateEx: function (lpGUID: PGUID; out lplpDD: IDirectDraw7;
          const iid: TGUID; pUnkOuter: IUnknown): HResult; stdcall;

function h_DirectDrawCreateEx(lpGUID: PGUID; out lplpDD: IDirectDraw7;
    const iid: TGUID; pUnkOuter: IUnknown): HResult; stdcall;
var
     DLLpath: string;
begin
     WriteToLog(HookFuncName + ' called');
     DLLpath :=  IncludeTrailingPathDelimiter(GetSysDir) + 'ddraw.dll';
     realDLL := LoadLibrary(LPCWSTR(DLLpath));
     if realDLL <> 0 then
          WriteToLog('Loading real DLL done!')
     else
          WriteToLog('*** Loading real DLL FAILED !!! ***');
     r_DirectDrawCreateEx := GetProcAddress(realDLL, HookFuncName);
     if Addr(r_DirectDrawCreateEx) <> nil then
          WriteToLog('Loading real ' + HookFuncName + ' function done!')
     else
          WriteToLog('*** Loading real ' + HookFuncName + ' function FAILED !!! ***');
     WriteToLog('Transferring control to the real ' + HookFuncName + ' function...');
     Result := r_DirectDrawCreateEx(lpGUID, lplpDD, iid, pUnkOuter);
end;

end.