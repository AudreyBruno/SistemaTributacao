unit DataModule.Produtos;

interface

uses
  System.SysUtils, System.Classes, DataModule.Principal, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.FMXUI.Wait, FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.Phys.SQLiteDef, FireDAC.Phys.SQLite, Data.DB, FireDAC.Comp.Client,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet, UniProvider, MySQLUniProvider, DBAccess, Uni, MemDS, System.JSON,
  DataSet.Serialize, RESTRequest4D, uSession, DataSet.Serialize.Adapter.RESTRequest4D, superobject;

type
  TDMProdutos = class(TDMPrincipal)
    UniQryProdutos: TUniQuery;
    FDQryProdutos: TFDQuery;
    TabProdutos: TFDMemTable;
    FDQryBuscaProdutos: TFDQuery;
  private
    FLOTEID: string;
    FENTRADA: Boolean;
    FSAIDA: Boolean;
    procedure UpdateTributacao;
    procedure BaixarDadosTributacaoTributacao(codBarra, ncm, cest, codigocf, basecalculo, aliquotaIcms, cst_pis,
                                                      cst_cofins, aliq_pis, aliq_cofins, cst_compra, entrada_cst_pis,
                                                      entrada_cst_cofins: string);
    procedure ConverteDadosJson(jsonObj: ISuperObject);
    procedure VerificaProdutos(revisado: string);
    procedure ConfirmaLote;
    procedure MudaStatus(codBarra: string);
    function GerarArrayProdutos: TJSONObject;
    procedure AtualizaRegistro(qry: TUniQuery; const sourceDataSet: TDataSet);
    procedure ConsultarLote(entrada, saida: string);

    { Private declarations }
  public
    { Public declarations }
    procedure BuscaProdutos(filtro: Boolean; tipoBusca, valueBusca: string);
    procedure InserirProdutos(codigo: integer; codigoBarras, nome, ncm: string);

    procedure AtualizarTributacao;

    procedure BuscaProdutosCadastrados(codigo: integer);
    procedure CadastrarLote;
    procedure ReimplantarLote;

    property LOTEID: string read FLOTEID write FLOTEID;
    property PSAIDA: Boolean read FSAIDA write FSAIDA;
    property PENTRADA: Boolean read FENTRADA write FENTRADA;
  end;

var
  DMProdutos: TDMProdutos;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

//MySQL
procedure TDMProdutos.BuscaProdutos(filtro: Boolean; tipoBusca, valueBusca: string);
begin
  try
    UniQryProdutos.Active := False;
    UniQryProdutos.SQL.Clear;
    UniQryProdutos.SQL.Add('SELECT Codigo, CodigoBarras, Descricao, NCM FROM produtos');
    UniQryProdutos.SQL.Add('WHERE CodigoBarras IS NOT NULL AND Descricao IS NOT NULL AND ncm IS NOT NULL ');

    if (filtro) and (tipoBusca <> 'GRUPO') then
      UniQryProdutos.SQL.Add('AND ' + tipoBusca + ' LIKE ''%' + valueBusca + '%''')
    else if (filtro) and (tipoBusca = 'GRUPO') then
      UniQryProdutos.SQL.Add('AND ' + tipoBusca + ' = ' + valueBusca);

    UniQryProdutos.Active := True;
  except on ex:Exception do
    begin
      raise Exception.Create(ex.Message);
    end;
  end;
end;

//SQLite
procedure TDMProdutos.BuscaProdutosCadastrados(codigo: integer);
begin
  try
    FDQryProdutos.Active := False;
    FDQryProdutos.SQL.Clear;
    FDQryProdutos.SQL.Add('SELECT * FROM TAB_PRODUTOS');
    FDQryProdutos.SQL.Add('WHERE CODPRODUTO = :CODPRODUTO');
    FDQryProdutos.SQL.Add('ORDER BY ID DESC');
    FDQryProdutos.ParamByName('CODPRODUTO').Value := codigo;
    FDQryProdutos.Active := True;
  except on ex:Exception do
    begin
      raise Exception.Create(ex.Message);
    end;
  end;
end;

procedure TDMProdutos.VerificaProdutos(revisado: string);
begin
  try
    FDQryProdutos.Active := False;
    FDQryProdutos.SQL.Clear;
    FDQryProdutos.SQL.Add('SELECT * FROM TAB_PRODUTOS WHERE REVISADO = :REVISADO');
    FDQryProdutos.ParamByName('REVISADO').Value := revisado;
    FDQryProdutos.Active := True;
  except on ex:Exception do
    begin
      raise Exception.Create(ex.Message);
    end;
  end;
end;

procedure TDMProdutos.InserirProdutos(codigo: integer; codigoBarras, nome, ncm: string);
var
  qry: TFDQuery;
  interno: string;
begin
  qry := TFDQuery.Create(Nil);

  try
    if Length(codigoBarras) > 6 then
      interno := 'N'
    else
      interno := 'S';

    qry.Connection := FDConn;

    qry.SQL.Clear;
    qry.SQL.Add('INSERT INTO TAB_PRODUTOS(CODPRODUTO, CODBARRAS, NOME, NCM, INTERNO, REVISADO)');
    qry.SQL.Add('VALUES(:CODPRODUTO, :CODBARRAS, :NOME, :NCM, :INTERNO, :REVISADO)');
    qry.ParamByName('CODPRODUTO').Value := codigo;
    qry.ParamByName('CODBARRAS').Value := codigoBarras;
    qry.ParamByName('NOME').Value := nome;
    qry.ParamByName('NCM').Value := ncm;
    qry.ParamByName('INTERNO').Value := interno;
    qry.ParamByName('REVISADO').Value := 'N';
    qry.ExecSQL;
  except on ex:Exception do
    begin
      raise Exception.Create(ex.Message);
    end;
  end;

  qry.Free;
end;

function TDMProdutos.GerarArrayProdutos: TJSONObject;
var
  arrayProdutos: TJSONArray;
  jsonCadastro, jsonProduto, teste: TJSONObject;
  i: integer;
begin
  VerificaProdutos('N');

  arrayProdutos := TJSONArray.Create;
  jsonCadastro := TJSONObject.Create;

  FDQryProdutos.First;
  for i := 0 to FDQryProdutos.RecordCount - 1 do
    begin
      jsonProduto := TJSONObject.Create;

      jsonProduto.AddPair('nome', TJSONString.Create(FDQryProdutos.FieldByName('NOME').AsString));
      jsonProduto.AddPair('codigo', TJSONString.Create(FDQryProdutos.FieldByName('CODBARRAS').AsString));

      if FDQryProdutos.FieldByName('INTERNO').Value = 'N' then
        jsonProduto.AddPair('interno', TJSONBool.Create(False))
      else
        jsonProduto.AddPair('interno', TJSONBool.Create(True));

      jsonProduto.AddPair('ncm', TJSONString.Create(FDQryProdutos.FieldByName('NCM').AsString));

      arrayProdutos.AddElement(jsonProduto);

      FDQryProdutos.Next;
    end;

  jsonCadastro.AddPair('cadastros', arrayProdutos);

  teste := jsonCadastro;

  Result := jsonCadastro;
end;

//API
procedure TDMProdutos.CadastrarLote;
var
  resp: IResponse;
  body: TJSONObject;
begin
  body := GerarArrayProdutos;

  try
    resp := TRequest.New.BaseURL(TSession.URL)
                        .Resource('Cadastro')
                        .AddBody(body.ToJSON)
                        .Accept('application/json')
                        .TokenBearer(TSession.TOKEN)
                        .Post;

    if (resp.StatusCode <> 200) then
      raise Exception.Create(resp.Content);
  finally
    body.Free;
  end;
end;

procedure TDMProdutos.AtualizarTributacao;
var
  entrada, saida: string;
begin
  if PENTRADA then
    entrada := 'true'
  else
    entrada := 'false';

  if PSAIDA then
    saida := 'true'
  else
    saida := 'false';

  ConsultarLote(entrada, saida);

  if LOTEID <> '00000000-0000-0000-0000-000000000000' then
    begin
      UpdateTributacao;
    end;
end;

procedure TDMProdutos.ReimplantarLote;
var
  resp: IResponse;
begin
  resp := TRequest.New.BaseURL(TSession.URL)
                      .Resource('Cadastro/reimplantar')
                      .TokenBearer(TSession.TOKEN)
                      .Post;

  if (resp.StatusCode <> 200) then
    raise Exception.Create(resp.Content);
end;

procedure TDMProdutos.ConsultarLote(entrada, saida: string);
var
  resp: IResponse;
  json: string;
begin
  resp := TRequest.New.BaseURL(TSession.URL)
                      .Resource('Consulta/atualizados')
                      .AddParam('entrada', entrada)
                      .AddParam('saida', saida)
                      .TokenBearer(TSession.TOKEN)
                      .Accept('text/plain; charset=utf-8')
                      .Get;

  if (resp.StatusCode <> 200) then
    raise Exception.Create(resp.Content);

  ConverteDadosJson(SO(resp.Content));
end;

procedure TDMProdutos.ConverteDadosJson(jsonObj: ISuperObject);
var
  codBarra, ncm, cest, codigocf, basecalculo, aliquotaIcms, cst_pis, cst_cofins, aliq_pis, aliq_cofins, cst_compra,
  entrada_cst_pis, entrada_cst_cofins: string;
  atualizacao: ISuperObject;
  produtos: ISuperArray;
  produto: ISuperObject;
  i, j: Integer;
begin
  LOTEID := jsonObj['loteId'].AsString;

  if LOTEID <> '00000000-0000-0000-0000-000000000000' then
    begin
      for i := 0 to jsonObj.A['atualizacoes'].Length - 1 do
        begin
          atualizacao := jsonObj.A['atualizacoes'].O[i];

          ncm := atualizacao['tributacao']['segmento']['ncm'].AsString;

          try
            cest := atualizacao['tributacao']['segmento']['cest'].AsString;
          except
            cest := '';
          end;

          if atualizacao['tributacao']['saida'].AsString <> '' then
            begin
              codigocf := atualizacao['tributacao']['saida']['icms']['cst'].AsString;
              aliquotaIcms := atualizacao['tributacao']['saida']['icms']['aliquota'].AsString;

              cst_pis := atualizacao['tributacao']['saida']['pisCofinsNaoCumulativo']['cstPis'].AsString;
              cst_cofins := atualizacao['tributacao']['saida']['pisCofinsNaoCumulativo']['cstCofins'].AsString;
              aliq_pis := atualizacao['tributacao']['saida']['pisCofinsNaoCumulativo']['aliquotaPis'].AsString;
              aliq_cofins := atualizacao['tributacao']['saida']['pisCofinsNaoCumulativo']['aliquotaCofins'].AsString;
            end;

          if atualizacao['tributacao']['entrada'].AsString <> '' then
            begin
              cst_compra := atualizacao['tributacao']['entrada']['icms']['cst'].AsString;
              entrada_cst_pis := atualizacao['tributacao']['entrada']['pisCofinsNaoCumulativo']['cstPis'].AsString;
              entrada_cst_cofins := atualizacao['tributacao']['entrada']['pisCofinsNaoCumulativo']['cstCofins'].AsString;
            end;

          produtos := atualizacao.A['produtos'];
          for j := 0 to produtos.Length - 1 do
            begin
              produto := produtos.O[j];

              codBarra := produto.S['codigo'];

              BaixarDadosTributacaoTributacao(codBarra, ncm, cest, codigocf, basecalculo, aliquotaIcms, cst_pis, cst_cofins,
                                              aliq_pis, aliq_cofins, cst_compra, entrada_cst_pis, entrada_cst_cofins);
            end;
        end;
    end;
end;

procedure TDMProdutos.BaixarDadosTributacaoTributacao(codBarra, ncm, cest, codigocf, basecalculo, aliquotaIcms, cst_pis,
                                                      cst_cofins, aliq_pis, aliq_cofins, cst_compra, entrada_cst_pis,
                                                      entrada_cst_cofins: string);
var
  qry: TFDQuery;
  i: Integer;
begin
  qry := TFDQuery.Create(Nil);

  try
    qry.Connection := FDConn;

    qry.SQL.Clear;
    qry.SQL.Add('UPDATE TAB_PRODUTOS SET NCM = :NCM, CEST = :CEST, CODIGOCF = :CODIGOCF, BASECALCULOICMS = :BASECALCULOICMS,' +
    ' ALIQUOTAICMS = :ALIQUOTAICMS, CST_PIS = :CST_PIS, ALIQ_PIS = :ALIQ_PIS, CST_COFINS = :CST_COFINS,' +
    ' ALIQ_COFINS = :ALIQ_COFINS, CST_COMPRA = :CST_COMPRA, ENTRADA_CST_PIS = :ENTRADA_CST_PIS,' +
    ' ENTRADA_CST_COFINS = :ENTRADA_CST_COFINS, DATACONSULTA = :DATACONSULTA, REVISADO = :REVISADO');
    qry.SQL.Add('WHERE CODBARRAS = :CODBARRAS AND REVISADO = :NREVISADO');
    qry.ParamByName('CODBARRAS').Value := codBarra;
    qry.ParamByName('NREVISADO').Value := 'N';

    qry.ParamByName('NCM').Value := ncm;
    qry.ParamByName('CEST').Value := cest;

    qry.ParamByName('CODIGOCF').Value := codigocf;
    qry.ParamByName('BASECALCULOICMS').Value := basecalculo;
    qry.ParamByName('ALIQUOTAICMS').Value := aliquotaIcms;
    qry.ParamByName('CST_PIS').Value := cst_pis;
    qry.ParamByName('ALIQ_PIS').Value := aliq_pis;
    qry.ParamByName('CST_COFINS').Value := cst_cofins;
    qry.ParamByName('ALIQ_COFINS').Value := aliq_cofins;

    qry.ParamByName('CST_COMPRA').Value := cst_compra;
    qry.ParamByName('ENTRADA_CST_PIS').Value := entrada_cst_pis;
    qry.ParamByName('ENTRADA_CST_COFINS').Value := entrada_cst_cofins;

    qry.ParamByName('DATACONSULTA').AsDateTime := Date;
    qry.ParamByName('REVISADO').Value := 'B';
    qry.ExecSQL;
  except on ex:Exception do
    begin
      raise Exception.Create(ex.Message);
    end;
  end;

  qry.Free;
end;

procedure TDMProdutos.UpdateTributacao;
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := UNIConn;

    VerificaProdutos('B');

    FDQryProdutos.First;
    while not FDQryProdutos.Eof do
      begin
        AtualizaRegistro(qry, FDQryProdutos);
        MudaStatus(FDQryProdutos.FieldByName('CODBARRAS').Value);
        FDQryProdutos.Next;
      end;
  except on ex: Exception do
    begin
      raise Exception.Create(ex.Message);
    end;
  end;

  ConfirmaLote;
  qry.Free;
end;

procedure TDMProdutos.AtualizaRegistro(qry: TUniQuery; const sourceDataSet: TDataSet);
var
  fieldNames: TArray<string>;
  fieldName: string;
begin
  qry.SQL.Clear;
  qry.SQL.Add('UPDATE produtos SET');

  fieldNames := ['CODIGOCF', 'ALIQUOTAICMS', 'BASECALCULOICMS', 'CST_COMPRA', 'CST_PIS',
                 'ALIQ_PIS', 'CST_COFINS', 'ALIQ_COFINS', 'ENTRADA_CST_PIS',
                 'ENTRADA_CST_COFINS', 'CEST', 'NCM'];

  for fieldName in fieldNames do
    begin
      if sourceDataSet.FieldByName(fieldName).Value <> '' then
        begin
          qry.SQL.Add(Format('%s = :%s,', [FieldName, FieldName]));
          qry.ParamByName(FieldName).Value := sourceDataSet.FieldByName(fieldName).Value;
        end;
    end;

  qry.SQL.Add('CodigoBarras = :CodigoBarras WHERE CodigoBarras = :CodigoBarras;');
  qry.ParamByName('CodigoBarras').Value := sourceDataSet.FieldByName('CODBARRAS').Value;
  qry.ExecSQL;
end;

procedure TDMProdutos.MudaStatus(codBarra: string);
var
  qry: TFDQuery;
  i: Integer;
begin
  qry := TFDQuery.Create(Nil);

  try
    qry.Connection := FDConn;

    qry.SQL.Clear;
    qry.SQL.Add('UPDATE TAB_PRODUTOS SET REVISADO = :REVISADO');
    qry.SQL.Add('WHERE CODBARRAS = :CODBARRAS AND REVISADO = :NREVISADO');
    qry.ParamByName('CODBARRAS').Value := codBarra;
    qry.ParamByName('NREVISADO').Value := 'B';
    qry.ParamByName('REVISADO').Value := 'S';
    qry.ExecSQL;
  except on ex:Exception do
    begin
      raise Exception.Create(ex.Message);
    end;
  end;

  qry.Free;
end;

procedure TDMProdutos.ConfirmaLote;
var
  resp: IResponse;
begin
  resp := TRequest.New.BaseURL(TSession.URL)
                      .Resource('Cadastro/ConfirmaLote')
                      .AddParam('LoteId', LOTEID)
                      .TokenBearer(TSession.TOKEN)
                      .Post;

  if (resp.StatusCode <> 200) then
    raise Exception.Create(resp.Content);

  AtualizarTributacao;
end;

end.
