unit DataModule.Login;

interface

uses
  System.SysUtils, System.Classes, DataModule.Principal, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.FMXUI.Wait, FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.Phys.SQLiteDef, FireDAC.Phys.SQLite, Data.DB, FireDAC.Comp.Client,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.Comp.DataSet,
  RESTRequest4D, System.JSON, uSession, DataSet.Serialize, DataSet.Serialize.Config,
  DataSet.Serialize.Adapter.RESTRequest4D, UniProvider, MySQLUniProvider,
  DBAccess, Uni, System.Net.HttpClient, System.Net.URLClient, System.Net.HttpClientComponent;

type
  TDMLogin = class(TDMPrincipal)
    TabLogin: TFDMemTable;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Login(username, password: string);
  end;

var
  DMLogin: TDMLogin;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TDMLogin.Login(username, password: string);
var
  LResponse: IHTTPResponse;
  LFormUrlencoded: TStringList;
  LRequest: THTTPClient;
  ResponseContent: string;
  JSONValue: TJSONValue;
  AccessToken: string;
begin
  LRequest := THTTPClient.Create;
  LFormUrlencoded := TStringList.Create;
  try
    LFormUrlencoded.Add('username='+username);
    LFormUrlencoded.Add('password='+password);
    LResponse := LRequest.Post(TSession.URL+'/connect/token', LFormUrlencoded);

    if (LResponse.StatusCode <> 200) then
      raise Exception.Create(LResponse.ContentAsString);

    if LResponse.StatusCode = 200 then
      begin
        ResponseContent := LResponse.ContentAsString;

        JSONValue := TJSONObject.ParseJSONValue(ResponseContent);

        try
          if Assigned(JSONValue) and (JSONValue is TJSONObject) then
            begin
              TSession.TOKEN := (JSONValue as TJSONObject).GetValue('acess_token').Value;
            end;
        finally
          JSONValue.Free;
        end;
      end;
  finally
    LFormUrlencoded.Free;
    LRequest.Free;
  end;
end;

end.
