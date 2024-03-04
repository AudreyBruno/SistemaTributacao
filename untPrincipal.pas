unit untPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ListBox,
  FMX.Edit, FMX.StdCtrls, FMX.Layouts, FMX.Controls.Presentation, FMX.Objects,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, uListView, uLoading, uSession, DataModule.Produtos,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, System.Rtti, FMX.Grid.Style,
  System.Bindings.Outputs, Data.Bind.EngExt, Fmx.Bind.DBEngExt, FMX.Grid,
  Data.Bind.Components, Data.Bind.Grid, Fmx.Bind.Grid, Fmx.Bind.Editors,
  Data.Bind.DBScope, System.JSON, FMX.TabControl;

type
  TfrmPrincipal = class(TForm)
    rectHeader: TRectangle;
    lblTitle: TLabel;
    Layout1: TLayout;
    rectTipoBusca: TRectangle;
    btnLocalizar: TButton;
    btnAtualizar: TButton;
    rectBusca: TRectangle;
    edtBusca: TEdit;
    cbTipoBusca: TComboBox;
    StyleBookPrincipal: TStyleBook;
    Layout3: TLayout;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    lvProdutos: TListView;
    imgChecked: TImage;
    imgUnchecked: TImage;
    Layout2: TLayout;
    checkSaida: TCheckBox;
    checkEntrada: TCheckBox;
    BindingsList1: TBindingsList;
    Label5: TLabel;
    btnAguardandoRevisao: TButton;
    procedure cbTipoBuscaClosePopup(Sender: TObject);
    procedure lvProdutosItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure btnLocalizarClick(Sender: TObject);
    procedure btnAtualizarClick(Sender: TObject);
    procedure btnAguardandoRevisaoClick(Sender: TObject);
  private
    FLIMIT: INTEGER;
    procedure AddRegistrosLv(listView: TListView; codigo: integer; codigoBarras, nome, ncm, consulta: string);
    procedure VerificaItems(listView: TListView);
    procedure ThreadBuscarTerminate(Sender: TObject);
    procedure AtualizaDados;
    procedure ThreadAtualizarTerminate(Sender: TObject);
    property LIMIT: INTEGER read FLIMIT write FLIMIT;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.fmx}

procedure TfrmPrincipal.ThreadBuscarTerminate(Sender: TObject);
begin
  TLoading.Hide;

  if Sender is TThread then
    begin
      if Assigned(TThread(Sender).FatalException) then
        begin
          ShowMessage(Exception(TThread(Sender).FatalException).Message);
          Exit;
        end;
    end;

  btnAtualizar.Enabled := True;
end;

procedure TfrmPrincipal.ThreadAtualizarTerminate(Sender: TObject);
begin
  TLoading.Hide;

  if Sender is TThread then
    begin
      if Assigned(TThread(Sender).FatalException) then
        begin
          ShowMessage(Exception(TThread(Sender).FatalException).Message);
          Exit;
        end;
    end;

  btnAtualizar.Enabled := False;
  ShowMessage('Produtos Atualizados com Sucesso!!!');
  btnAguardandoRevisaoClick(Sender);
end;

procedure TfrmPrincipal.btnAtualizarClick(Sender: TObject);
begin
  if (checkSaida.IsChecked) or (checkEntrada.IsChecked) then
    AtualizaDados
  else
    ShowMessage('Deve ser selecionado se deseja saida ou entrada');
end;

procedure TfrmPrincipal.btnLocalizarClick(Sender: TObject);
var
  t: TThread;
  tipoBusca, valueBusca, consulta: string;
  filtro, exibir: Boolean;
begin
  TLoading.Show(frmPrincipal, 'Aguarde!!!');

  lvProdutos.Items.Clear;

  case cbTipoBusca.ItemIndex of
    0: tipoBusca := 'CodigoBarras';
    1: tipoBusca := 'Descricao';
    2: tipoBusca := 'NCM';
    3: tipoBusca := 'GRUPO';
  end;

  filtro := edtBusca.Text <> '';
  if filtro then
    valueBusca := edtBusca.Text;

  t := TThread.CreateAnonymousThread(procedure
    begin
      DMProdutos.BuscaProdutos(filtro, tipoBusca, valueBusca);

      TThread.Synchronize(nil, procedure
      var
        i: integer;
      begin
        DMProdutos.UniQryProdutos.First;
        for i := 0 to DMProdutos.UniQryProdutos.RecordCount - 1 do
          begin
            DMProdutos.BuscaProdutosCadastrados(DMProdutos.UniQryProdutos.FieldByName('Codigo').Value);

            if DMProdutos.FDQryProdutos.RecordCount > 0 then
              begin
                if not DMProdutos.FDQryProdutos.FieldByName('DATACONSULTA').IsNull then
                  begin
                    exibir := True;
                    consulta := 'Revisado em ' + DateToStr(DMProdutos.FDQryProdutos.FieldByName('DATACONSULTA').Value);
                  end
                else
                  begin
                    consulta := 'Aguardando Revisão';
                    exibir := False;
                  end;
              end
            else
              begin
                exibir := True;
                consulta := 'Não Revisado';
              end;

            if exibir then
              begin
                AddRegistrosLv(lvProdutos,
                               DMProdutos.UniQryProdutos.FieldByName('Codigo').Value,
                               DMProdutos.UniQryProdutos.FieldByName('CodigoBarras').Value,
                               DMProdutos.UniQryProdutos.FieldByName('Descricao').Value,
                               DMProdutos.UniQryProdutos.FieldByName('NCM').Value,
                               consulta);
              end;

            DMProdutos.UniQryProdutos.Next;
          end;
      end);
    end);

  t.OnTerminate := ThreadBuscarTerminate;
  t.Start;
end;

procedure TfrmPrincipal.btnAguardandoRevisaoClick(Sender: TObject);
var
  t: TThread;
  tipoBusca, valueBusca, consulta: string;
  filtro: Boolean;
begin
  TLoading.Show(frmPrincipal, 'Aguarde!!!');

  lvProdutos.Items.Clear;

  case cbTipoBusca.ItemIndex of
    0: tipoBusca := 'CodigoBarras';
    1: tipoBusca := 'Descricao';
    2: tipoBusca := 'NCM';
  end;

  filtro := edtBusca.Text <> '';
  if filtro then
    valueBusca := edtBusca.Text;

  t := TThread.CreateAnonymousThread(procedure
    begin
      DMProdutos.BuscaProdutos(filtro, tipoBusca, valueBusca);

      TThread.Synchronize(nil, procedure
      var
        i: integer;
      begin
        DMProdutos.UniQryProdutos.First;
        for i := 0 to DMProdutos.UniQryProdutos.RecordCount - 1 do
          begin
            DMProdutos.BuscaProdutosCadastrados(DMProdutos.UniQryProdutos.FieldByName('Codigo').Value);

            if DMProdutos.FDQryProdutos.RecordCount > 0 then
              begin
                if DMProdutos.FDQryProdutos.FieldByName('DATACONSULTA').IsNull then
                  begin
                    consulta := 'Aguardando Revisão';

                    AddRegistrosLv(lvProdutos,
                                   DMProdutos.UniQryProdutos.FieldByName('Codigo').Value,
                                   DMProdutos.UniQryProdutos.FieldByName('CodigoBarras').Value,
                                   DMProdutos.UniQryProdutos.FieldByName('Descricao').Value,
                                   DMProdutos.UniQryProdutos.FieldByName('NCM').Value,
                                   consulta);
                  end;
              end;

            DMProdutos.UniQryProdutos.Next;
          end;
      end);
    end);

  t.OnTerminate := ThreadBuscarTerminate;
  t.Start;
end;

procedure TfrmPrincipal.cbTipoBuscaClosePopup(Sender: TObject);
begin
  case cbTipoBusca.ItemIndex of
    0: edtBusca.TextPrompt := 'Digite o CodBarras';
    1: edtBusca.TextPrompt := 'Digite a Descrição';
    2: edtBusca.TextPrompt := 'Digite o NCM';
  end;
end;

procedure TfrmPrincipal.lvProdutosItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  TMyListview.SelecionarItem(lvProdutos, AItem, imgUnchecked.Bitmap, imgChecked.Bitmap);
end;

procedure TfrmPrincipal.VerificaItems(listView: TListView);
var
  i: integer;
begin
  LIMIT := 0;
  for i := listView.ItemCount -1 downto 0 do
    begin
      if listView.Items[i].Checked then
        begin
          DMProdutos.BuscaProdutos(True, 'Codigo', IntToStr(listView.Items[i].Tag));
          DMProdutos.InserirProdutos(DMProdutos.UniQryProdutos.FieldByName('Codigo').Value,
                                     DMProdutos.UniQryProdutos.FieldByName('CodigoBarras').Value,
                                     DMProdutos.UniQryProdutos.FieldByName('Descricao').Value,
                                     DMProdutos.UniQryProdutos.FieldByName('NCM').Value);
          LIMIT := LIMIT + 1;
        end;
    end;
end;

procedure TfrmPrincipal.AddRegistrosLv(listView: TListView; codigo: integer; codigoBarras, nome, ncm, consulta: string);
var
  txt: TListItemText;
  img: TListItemImage;
begin
  with listView.Items.Add do
    begin
      Height := 45;
      Tag := codigo;

      img := TListItemImage(Objects.FindDrawable('imgCheck'));
      img.Bitmap := imgUnchecked.Bitmap;

      txt := TListItemText(Objects.FindDrawable('txtCodBarras'));
      txt.Text := codigoBarras;

      txt := TListItemText(Objects.FindDrawable('txtNome'));
      txt.Text := nome;

      txt := TListItemText(Objects.FindDrawable('txtNCM'));
      txt.Text := ncm;

      txt := TListItemText(Objects.FindDrawable('txtConsulta'));
      txt.Text := consulta;
    end;
end;

procedure TfrmPrincipal.AtualizaDados;
var
  t: TThread;
begin
  TLoading.Show(frmPrincipal, 'Aguarde!!!');

  t := TThread.CreateAnonymousThread(procedure
    begin
      DMProdutos.PSAIDA := checkSaida.IsChecked;
      DMProdutos.PENTRADA := checkEntrada.IsChecked;
      VerificaItems(lvProdutos);
      DMProdutos.ReimplantarLote;
      DMProdutos.CadastrarLote;
      DMProdutos.AtualizarTributacao;
    end);

  t.OnTerminate := ThreadAtualizarTerminate;
  t.Start;
end;

end.
