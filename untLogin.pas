unit untLogin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Effects, FMX.Filter.Effects, FMX.Objects, FMX.Edit, FMX.Layouts,
  FMX.Controls.Presentation, untPrincipal, uLoading, DataModule.Login, uSession;

type
  TfrmLogin = class(TForm)
    Label1: TLabel;
    Layout1: TLayout;
    rectUser: TRectangle;
    edtUser: TEdit;
    rectSenha: TRectangle;
    edtSenha: TEdit;
    imgOlho: TImage;
    FillRGBEffect1: TFillRGBEffect;
    btnLogin: TButton;
    StyleBookLogin: TStyleBook;
    procedure btnLoginClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure ThreadLoginTerminate(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmLogin: TfrmLogin;

implementation

{$R *.fmx}

procedure TfrmLogin.FormShow(Sender: TObject);
begin
  TSession.URL := 'https://comotributar.sistemasfocuscontabil.com/backend/api';
end;

procedure TfrmLogin.ThreadLoginTerminate(Sender: TObject);
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

  if not Assigned(frmPrincipal) then
    Application.CreateForm(TfrmPrincipal, frmPrincipal);

  Application.MainForm := frmPrincipal;
  frmPrincipal.Show;
  frmLogin.Close;
end;

procedure TfrmLogin.btnLoginClick(Sender: TObject);
var
  t: TThread;
begin
  TLoading.Show(frmLogin, '');

  t := TThread.CreateAnonymousThread(procedure
  begin
    DMLogin.Login(edtUser.Text, edtSenha.Text);
  end);

  t.OnTerminate := ThreadLoginTerminate;
  t.Start;
end;

end.
