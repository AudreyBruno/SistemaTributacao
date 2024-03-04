inherited DMProdutos: TDMProdutos
  OldCreateOrder = True
  inherited FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink
    Left = 144
    Top = 48
  end
  object UniQryProdutos: TUniQuery
    Connection = UNIConn
    Left = 424
    Top = 208
  end
  object FDQryProdutos: TFDQuery
    Connection = FDConn
    Left = 88
    Top = 184
  end
  object TabProdutos: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 112
    Top = 264
  end
  object FDQryBuscaProdutos: TFDQuery
    Connection = FDConn
    Left = 208
    Top = 224
  end
end
