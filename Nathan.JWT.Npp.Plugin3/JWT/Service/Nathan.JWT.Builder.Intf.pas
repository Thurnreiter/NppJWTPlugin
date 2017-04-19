unit Nathan.JWT.Builder.Intf;

interface

uses
  Nathan.JWT.Service;

{$M+}

type
  INathanJwtWrapperBuilder = interface
    ['{A0799C96-6673-4F76-B072-A5CBBE3CCD4F}']
    function WithSecretKey(const Value: string): INathanJwtWrapperBuilder;
    function WithPayload(const Value: string): INathanJwtWrapperBuilder;
    function Build(): INathanJwtWrapper;
  end;

{$M-}

implementation

end.
