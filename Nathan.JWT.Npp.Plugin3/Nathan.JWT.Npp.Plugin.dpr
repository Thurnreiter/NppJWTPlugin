library Nathan.JWT.Npp.Plugin;

{$R 'Nathan.JWT.res' 'Nathan.JWT.rc'}

uses
  SciSupport in 'lib\SciSupport.pas',
  npptypes in 'lib\npptypes.pas',
  Nathan.Npp.Plugin.Jwt in 'Nathan.Npp.Plugin.Jwt.pas',
  Nathan.Npp.Plugin in 'base\Nathan.Npp.Plugin.pas',
  Nathan.JWT.Builder.Impl in 'JWT\Service\Nathan.JWT.Builder.Impl.pas',
  Nathan.JWT.Builder.Intf in 'JWT\Service\Nathan.JWT.Builder.Intf.pas',
  Nathan.JWT.Service in 'JWT\Service\Nathan.JWT.Service.pas';

{$R *.res}

exports isUnicode, beNotified, setInfo, getName, messageProc, getFuncsArray;

begin
  ReportMemoryLeaksOnShutdown := (DebugHook <> 0);
  NppRegister(TNathanNppPluginJwt);
end.
