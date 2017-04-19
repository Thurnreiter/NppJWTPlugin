unit Nathan.JWT.Service;

interface

uses
  System.SysUtils,
  JOSE.Core.JWT,
  JOSE.Core.Builder,
  JOSE.Core.JWK;

{$M+}

type
  INathanJwtWrapper = interface
    ['{5F32B159-838B-470D-9B1B-4E30FE664F52}']
    function GetKey(): string;
    function GetPayload(): string;
    function GetJsonTokenHeader(): string;
    function GetJsonTokenClaims(): string;
    function GetVerified: Boolean;

    procedure SetKey(const Value: string);
    procedure SetPayload(const Value: string);

    function CreatingAToken(): string;
    function UnpackAndVerifyAToken(const MyToken: string): Boolean;

    property Key: string read GetKey write SetKey;
    property Payload: string read GetPayload write SetPayload;
    property JsonTokenHeader: string read GetJsonTokenHeader;
    property JsonTokenClaims: string read GetJsonTokenClaims;
    property Verified: Boolean read GetVerified;
  end;

  TNathanJwtWrapper = class(TInterfacedObject, INathanJwtWrapper)
  strict private
    FKey: string;
    FPayload: string;
    FJsonTokenHeader: string;
    FJsonTokenClaims: string;
    FVerified: Boolean;
  private
    function GetKey(): string;
    function GetPayload(): string;
    function GetJsonTokenHeader(): string;
    function GetJsonTokenClaims(): string;
    function GetVerified(): Boolean;

    procedure SetKey(const Value: string);
    procedure SetPayload(const Value: string);
  public
    function CreatingAToken(): string;
    function UnpackAndVerifyAToken(const MyToken: string): Boolean;
  end;

{$M-}

implementation

{ TNathanJwtWrapper }

function TNathanJwtWrapper.GetKey(): string;
begin
  Result := FKey;
end;

function TNathanJwtWrapper.GetPayload(): string;
begin
  Result := FPayload;
end;

function TNathanJwtWrapper.GetJsonTokenHeader(): string;
begin
  Result := FJsonTokenHeader;
end;

function TNathanJwtWrapper.GetJsonTokenClaims(): string;
begin
  Result := FJsonTokenClaims;
end;

function TNathanJwtWrapper.GetVerified(): Boolean;
begin
  Result := FVerified;
end;

procedure TNathanJwtWrapper.SetKey(const Value: string);
begin
  FKey := Value;
end;

procedure TNathanJwtWrapper.SetPayload(const Value: string);
begin
  FPayload := Value;
end;

function TNathanJwtWrapper.CreatingAToken(): string;
var
  LToken: TJWT;
begin
  LToken := TJWT.Create;
  try
    //  Token claims...
    LToken.Claims.IssuedAt := Now;
    LToken.Claims.Expiration := Now + 1;

    //    LToken.Claims.Issuer := 'WiRL REST Library';
    LToken.Claims.Issuer := FPayload;

    //  Signing and Compact format creation...
    Result := TJOSE.SHA256CompactToken('secret', LToken);

    //  Header and Claims JSON representation
    //  Result := Result + #13#10 + #13#10;
    //  Result := Result + LToken.Header.JSON.ToJSON + #13#10;
    //  Result := Result + LToken.Claims.JSON.ToJSON;
  finally
    LToken.Free;
  end;
end;

function TNathanJwtWrapper.UnpackAndVerifyAToken(const MyToken: string): Boolean;
var
  LKey: TJWK;
  LToken: TJWT;
begin
  FPayload := '';
  FJsonTokenHeader := '';
  FJsonTokenClaims := '';

  LKey := TJWK.Create(FKey);
  try
    // Unpack and verify the token
    LToken := TJOSE.Verify(LKey, MyToken);
    if Assigned(LToken) then
    begin
      try
        FVerified := LToken.Verified;
        Result := FVerified;

        if LToken.Claims.HasIssuer then
          FPayload := LToken.Claims.Issuer;

        FJsonTokenHeader := LToken.Header.JSON.ToJSON;
        FJsonTokenClaims := LToken.Claims.JSON.ToJSON;
      finally
        LToken.Free;
      end;
    end
    else
      Result := False;
  finally
    LKey.Free;
  end;
end;

end.
