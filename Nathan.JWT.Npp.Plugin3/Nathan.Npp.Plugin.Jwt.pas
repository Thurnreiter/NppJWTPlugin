unit Nathan.Npp.Plugin.Jwt;

interface

uses
  npptypes,
  Nathan.Npp.Plugin;

type
  TNathanNppPluginJwt = class(TNppPlugin)
  strict private
    FSecurityCode: string;
  protected
    procedure SetToolbarIcon(out ToolbarIcon: TToolbarIcons); override;
  public
    constructor Create(); override;
    destructor Destroy(); override;

    procedure InputSecurityCode();
//    procedure GetAllText();
    procedure GetJwtSplitter();
    procedure About();
  end;

implementation

uses
  System.SysUtils,
  scisupport,
  Vcl.Dialogs,
  Winapi.Windows,
  Nathan.JWT.Builder.Impl,
  Nathan.JWT.Service;

{ **************************************************************************** }

procedure _InputSecurityCode(); cdecl;
begin
  (GetNPPPluginInstance as TNathanNppPluginJwt).InputSecurityCode;
end;

//procedure _GetAllText(); cdecl;
//begin
//  (GetNPPPluginInstance as TNathanNppPluginJwt).GetAllText;
//end;

procedure _GetJwtSplitter(); cdecl; export;
begin
  (GetNppPluginInstance() as TNathanNppPluginJwt).GetJwtSplitter;
end;

procedure _About(); cdecl; export;
begin
  (GetNppPluginInstance() as TNathanNppPluginJwt).About;
end;

{ **************************************************************************** }

{ THelloWorldPlugin }

constructor TNathanNppPluginJwt.Create();
begin
  inherited;

  FSecurityCode := '';

  PluginName := 'Nathan JWT (JSON Web Tokens) Decoder';

  AddFunction('Enter the security code', _InputSecurityCode);
  AddFunction('JWT splitter', _GetJwtSplitter);
  AddFunction('About', _About);
  //  AddFunction('Get all text', _GetAllText);

  //  Id from function of the command to be executed when clicking. Here "About"....
  NppBindingToolbarCommndId := 2;
end;

destructor TNathanNppPluginJwt.Destroy();
begin
  //...
  inherited Destroy;
end;

procedure TNathanNppPluginJwt.SetToolbarIcon(out ToolbarIcon: TToolbarIcons);
begin
  inherited;
  ToolbarIcon.ToolbarBmp := LoadImage(Hinstance, 'ME', IMAGE_BITMAP, 0, 0, (LR_DEFAULTSIZE or LR_LOADMAP3DCOLORS));
end;

procedure TNathanNppPluginJwt.InputSecurityCode();
begin
  FSecurityCode := InputBox('Security Code', 'Key', FSecurityCode);
  //  ShowMessage('Key: ' + FSecurityCode);
end;

//procedure TNathanNppPluginJwt.GetAllText();
//begin
//  ShowMessage(GetAllTextFromCurrentTab());
//end;

procedure TNathanNppPluginJwt.GetJwtSplitter();
var
  JsonWebTokens: string;
  SplittedJWT: TArray<string>;
  ToReplaceAnsi: AnsiString;
  Wrapper: INathanJwtWrapper;
begin
  JsonWebTokens := GetSelectedTextFromCurrentTab();
  SplittedJWT := JsonWebTokens.Split(['.']);
  if (Length(SplittedJWT) <> 3) then
    Exit;

  if FSecurityCode.IsEmpty then
    InputSecurityCode();

  Wrapper := TNathanJwtWrapperBuilder
    .CreateInstance
    .WithSecretKey(FSecurityCode)
    .Build;

  if (not Wrapper.UnpackAndVerifyAToken(JsonWebTokens)) then
    Exit;

  //  ToDo: Here comes the implementation of JWT Wrapper...
  ToReplaceAnsi := AnsiString(sLineBreak + SplittedJWT[0]
    + sLineBreak + SplittedJWT[1]
    + sLineBreak + SplittedJWT[2]
    + sLineBreak
    + sLineBreak + 'Json Header: ' + Wrapper.JsonTokenHeader
    + sLineBreak + 'Json Claims: ' + Wrapper.JsonTokenClaims
    + sLineBreak + 'Payload: ' + Wrapper.Payload
    + sLineBreak);

  ReplaceSelectedTextFromCurrentTab(ToReplaceAnsi);
end;

procedure TNathanNppPluginJwt.About();
begin
  ShowMessage('Nathan JWT (JSON Web Tokens) Npp Plugin.'
    + sLineBreak
    + 'Version : 1.3.6');
end;

end.
