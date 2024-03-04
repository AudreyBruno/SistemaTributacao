unit uSession;

interface

type
  TSession = class
  private
    class var FTOKEN: string;
    class var FURL: string;

  public
    class property TOKEN: string read FTOKEN write FTOKEN;
    class property URL: string read FURL write FURL;
  end;

implementation

end.
