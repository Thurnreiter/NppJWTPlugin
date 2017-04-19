unit Nathan.JWT.Builder.Impl;

interface

uses
  Nathan.JWT.Service,
  Nathan.JWT.Builder.Intf;

{$M+}

type
  TNathanJwtWrapperBuilder = class(TInterfacedObject, INathanJwtWrapperBuilder)
  strict private
    class var FInstance: INathanJwtWrapperBuilder;

    FSecretKey: string;
    FPayload: string;
  public
    class function CreateInstance(): INathanJwtWrapperBuilder;

    function WithSecretKey(const Value: string): INathanJwtWrapperBuilder;
    function WithPayload(const Value: string): INathanJwtWrapperBuilder;

    function Build(): INathanJwtWrapper;
  end;

{$M-}

implementation

uses
  System.SysUtils;

class function TNathanJwtWrapperBuilder.CreateInstance: INathanJwtWrapperBuilder;
begin
  if (not Assigned(FInstance)) then
    FInstance := TNathanJwtWrapperBuilder.Create();

  Result := FInstance;
end;

function TNathanJwtWrapperBuilder.WithSecretKey(const Value: string): INathanJwtWrapperBuilder;
begin
  FSecretKey := Value;
  Result := Self;
end;

function TNathanJwtWrapperBuilder.WithPayload(const Value: string): INathanJwtWrapperBuilder;
begin
  FPayload := Value;
  Result := Self;
end;

function TNathanJwtWrapperBuilder.Build(): INathanJwtWrapper;
begin
  Result := TNathanJwtWrapper.Create();

  if (not FSecretKey.IsEmpty) then
    Result.Key := FSecretKey;

  if (not FPayload.IsEmpty) then
    Result.Payload := FPayload;
end;

end.
