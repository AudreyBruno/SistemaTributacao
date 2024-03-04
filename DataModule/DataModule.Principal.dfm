object DMPrincipal: TDMPrincipal
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 374
  Width = 565
  object FDConn: TFDConnection
    AfterConnect = FDConnAfterConnect
    BeforeConnect = FDConnBeforeConnect
    Left = 56
    Top = 24
  end
  object FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink
    Left = 56
    Top = 80
  end
  object UNIConn: TUniConnection
    ProviderName = 'MySQL'
    LoginPrompt = False
    Left = 480
    Top = 24
  end
  object MySQLUniProvider1: TMySQLUniProvider
    Left = 480
    Top = 88
  end
end
