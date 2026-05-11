object frmOperariosCustomCols: TfrmOperariosCustomCols
  Left = 0
  Top = 0
  Caption = 'Configurar columnas personalizadas - Operarios'
  ClientHeight = 480
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnShow = FormShow
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 760
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Color = 16444404
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 280
      Height = 19
      Caption = 'Columnas personalizadas de Operarios'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 28
      Width = 500
      Height = 15
      Caption =
        'Define los campos personalizados que apareceran como columnas en' +
        ' la pantalla Operarios.'
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 430
    Width = 760
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnNueva: TButton
      Left = 12
      Top = 10
      Width = 120
      Height = 30
      Caption = 'Nueva...'
      TabOrder = 0
      OnClick = btnNuevaClick
    end
    object btnEditar: TButton
      Left = 138
      Top = 10
      Width = 120
      Height = 30
      Caption = 'Editar...'
      TabOrder = 1
      OnClick = btnEditarClick
    end
    object btnEliminar: TButton
      Left = 264
      Top = 10
      Width = 120
      Height = 30
      Caption = 'Eliminar'
      TabOrder = 2
      OnClick = btnEliminarClick
    end
    object btnCerrar: TButton
      Left = 638
      Top = 10
      Width = 110
      Height = 30
      Cancel = True
      Caption = 'Cerrar'
      ModalResult = 1
      TabOrder = 3
    end
  end
  object lvCols: TListView
    Left = 0
    Top = 50
    Width = 760
    Height = 380
    Align = alClient
    Columns = <
      item
        Caption = 'Codigo'
        Width = 180
      end
      item
        Caption = 'Etiqueta'
        Width = 280
      end
      item
        Caption = 'Tipo'
        Width = 100
      end
      item
        Alignment = taRightJustify
        Caption = 'Orden'
        Width = 80
      end
      item
        Alignment = taRightJustify
        Caption = 'Ancho'
        Width = 80
      end>
    GridLines = True
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    TabOrder = 2
    ViewStyle = vsReport
    OnDblClick = lvColsDblClick
  end
end
