(*******************************************************************************

  Jean-Pierre LESUEUR (@DarkCoderSc)
  https://www.phrozen.io/
  jplesueur@phrozen.io

  License : MIT

  Version: 1.0 Stable.

  Description:
  ------------------------------------------------------------------------------

    This version doesn't work with programs such as Netcat in the scenario of an
    initial reverse / bind shell.

    Check my Github : https://github.com/darkcodersc to find the version that
    supports netcat ;-)

    Don't forgget to leave a star and follow if you found my work useful ! =P

*******************************************************************************)

program RunAsAttached;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Windows,
  Classes,
  UntFunctions in 'Units\UntFunctions.pas',
  UntApiDefs in 'Units\UntApiDefs.pas',
  UntGlobalDefs in 'Units\UntGlobalDefs.pas',
  UntStdHandlers in 'Units\UntStdHandlers.pas',
  UntTypeDefs in 'Units\UntTypeDefs.pas';

var SET_USERNAME         : String = '';
    SET_PASSWORD         : String = '';
    SET_DOMAINNAME       : String = '';

    LStdoutHandler       : TStdoutHandler;
    AExitCode            : Cardinal;
    LCommand             : AnsiString;

{-------------------------------------------------------------------------------
  Usage Banner
-------------------------------------------------------------------------------}
function DisplayHelpBanner() : String;
begin
  result := '';
  ///

  WriteLn;

  WriteLn('-----------------------------------------------------------');

  Write('RunAsAttached By ');

  WriteColoredWord('Jean-Pierre LESUEUR ');

  Write('(');

  WriteColoredWord('@DarkCoderSc');

  WriteLn(')');


  WriteLn('https://www.phrozen.io/');
  WriteLn('https://github.com/darkcodersc');
  WriteLn('-----------------------------------------------------------');

  WriteLn;

  WriteLn('RunAsAttached.exe -u <username> -p <password> [-d <domain>]');
  WriteLn;
end;

{-------------------------------------------------------------------------------
  Program Entry
-------------------------------------------------------------------------------}
begin
  isMultiThread := True;
  try
    {
      Parse Parameters
    }
    if NOT GetCommandLineOption('u', SET_USERNAME) then
      raise Exception.Create('');

    if NOT GetCommandLineOption('p', SET_PASSWORD) then
      raise Exception.Create('');

    GetCommandLineOption('d', SET_DOMAINNAME);

    {
      Create Handlers (stdout, stdin, stderr)
    }
    try
      LStdoutHandler := TStdoutHandler.Create(SET_USERNAME, SET_PASSWORD, SET_DOMAINNAME);
      LStdoutHandler.Resume();
      ///

      {
        Wait for commands (stdin)
      }
      while True do begin
        ReadLn(LCommand);
        ///

        LCommand := LCommand + #13#10;

        {
          We could replace "PostThreadMessage" by WriteFile directly from main thread.

          We would just need to retrieve the "FPipeOutWrite" handle from StdHandler thread.
        }
        PostThreadMessage(
                            LStdoutHandler.ThreadID,
                            WM_COMMAND,
                            NativeUInt(LCommand),
                            (Length(LCommand) * SizeOf(AnsiChar))
        );

        {
          Check if our StdHandler thread is still alive
        }
        GetExitCodeThread(LStdoutHandler.Handle, AExitCode);
        if (AExitCode <> STILL_ACTIVE) then
          break;
      end;

      {
        Close secondary thread if not already
      }
      GetExitCodeThread(LStdoutHandler.Handle, AExitCode);
      if (AExitCode = STILL_ACTIVE) then begin
        LStdoutHandler.Terminate();
        LStdoutHandler.WaitFor();
      end;
    finally
      if Assigned(LStdoutHandler) then
        FreeAndNil(LStdoutHandler);
    end;
  except
    on E: Exception do begin
      if (E.Message <> '') then
        Debug(Format('Exception in class=[%s], message=[%s]', [E.ClassName, E.Message]), dlError)
      else
        DisplayHelpBanner();
    end;
  end;
end.
