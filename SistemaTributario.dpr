program SistemaTributario;

uses
  System.StartUpCopy,
  FMX.Forms,
  untLogin in 'untLogin.pas' {frmLogin},
  uLoading in 'Units\uLoading.pas',
  uSession in 'Units\uSession.pas',
  untPrincipal in 'untPrincipal.pas' {frmPrincipal},
  uListView in 'Units\uListView.pas',
  DataModule.Principal in 'DataModule\DataModule.Principal.pas' {DMPrincipal: TDataModule},
  DataModule.Login in 'DataModule\DataModule.Login.pas' {DMLogin: TDataModule},
  DataModule.Produtos in 'DataModule\DataModule.Produtos.pas' {DMProdutos: TDataModule},
  superdate in 'modules\superObject\superdate.pas',
  superdbg in 'modules\superObject\superdbg.pas',
  superobject in 'modules\superObject\superobject.pas',
  supertimezone in 'modules\superObject\supertimezone.pas',
  supertypes in 'modules\superObject\supertypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDMPrincipal, DMPrincipal);
  Application.CreateForm(TDMLogin, DMLogin);
  Application.CreateForm(TDMProdutos, DMProdutos);
  Application.CreateForm(TfrmLogin, frmLogin);
  Application.Run;
end.
