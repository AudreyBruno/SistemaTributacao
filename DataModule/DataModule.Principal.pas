unit DataModule.Principal;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.FMXUI.Wait,
  Data.DB, FireDAC.Comp.Client, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.Phys.SQLiteDef, FireDAC.Phys.SQLite,
  RESTRequest4D, System.JSON, DBAccess, Uni, UniProvider, MySQLUniProvider, System.IniFiles;

type
  TDMPrincipal = class(TDataModule)
    FDConn: TFDConnection;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    UNIConn: TUniConnection;
    MySQLUniProvider1: TMySQLUniProvider;
    procedure FDConnBeforeConnect(Sender: TObject);
    procedure DataModuleCreate(Sender: TObject);
    procedure FDConnAfterConnect(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DMPrincipal: TDMPrincipal;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TDMPrincipal.DataModuleCreate(Sender: TObject);
var
  arq_ini : string;
  ini : TIniFile;
begin
  try
    try
      arq_ini := GetCurrentDir + '\Config.ini';
      ini := TIniFile.Create(arq_ini);

      if NOT FileExists(arq_ini) then
        begin
          raise Exception.Create('Arquivo INI não encontrado: ' + arq_ini);
        end;


      UNIConn.Server := ini.ReadString('MySQL', 'Server', '');
      UNIConn.Port := StrToInt(ini.ReadString('MySQL', 'Port', ''));
      UNIConn.Username := ini.ReadString('MySQL', 'Username', '');
      UNIConn.Password := ini.ReadString('MySQL', 'Password', '');
      UNIConn.Database := ini.ReadString('MySQL', 'Database', '');
    except on ex:Exception do
      raise Exception.Create(ex.Message);
    end;
  finally
    if Assigned(ini) then
      ini.DisposeOf;
  end;

  FDConn.Connected := True;
end;

procedure TDMPrincipal.FDConnAfterConnect(Sender: TObject);
begin
  FDConn.ExecSQL('CREATE TABLE IF NOT EXISTS TAB_USER(' +
                 'ID INTEGER PRIMARY KEY AUTOINCREMENT,' +
                 'USER VARCHAR(100),' +
                 'SENHA VARCHAR(100))');

  FDConn.ExecSQL('CREATE TABLE IF NOT EXISTS TAB_PRODUTOS(' +
                 'ID INTEGER PRIMARY KEY AUTOINCREMENT,' +
                 'CODPRODUTO INTEGER,' +
                 'CODBARRAS VARCHAR(15),' +
                 'NOME VARCHAR(120),' +
                 'NCM VARCHAR(10),' +
                 'CEST VARCHAR(7),' +
                 'CODIGOCF VARCHAR(4),' +
                 'BASECALCULOICMS VARCHAR(10),' +
                 'ALIQUOTAICMS VARCHAR(10),' +
                 'CST_PIS VARCHAR(2),' +
                 'ALIQ_PIS VARCHAR(10),' +
                 'CST_COFINS VARCHAR(2),' +
                 'ALIQ_COFINS VARCHAR(10),' +
                 'CST_COMPRA VARCHAR(4),' +
                 'ENTRADA_CST_PIS VARCHAR(2),' +
                 'ENTRADA_CST_COFINS VARCHAR(2),' +
                 'DATACONSULTA DATETIME,' +
                 'INTERNO CHAR(1),' +
                 'REVISADO CHAR(1))');
end;

procedure TDMPrincipal.FDConnBeforeConnect(Sender: TObject);
begin
  FDConn.DriverName := 'SQLite';

  {$IFDEF MSWINDOWS}
    FDConn.Params.Values['Database'] := System.SysUtils.GetCurrentDir + '\DB.db';
  {$ELSE}
    FDConn.Params.Values['Database'] := TPath.Combine(TPath.GetDocumentsPath, 'DB.db');
  {$ENDIF}
end;

end.
