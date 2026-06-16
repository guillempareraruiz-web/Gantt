object frmRestorePoints: TfrmRestorePoints
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Puntos de restauraci'#243'n del plan'
  ClientHeight = 520
  ClientWidth = 907
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poOwnerFormCenter
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 17
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 907
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 8776698
    ParentBackground = False
    TabOrder = 0
    ExplicitWidth = 760
    object lblTitulo: TLabel
      Left = 12
      Top = 8
      Width = 500
      Height = 40
      AutoSize = False
      Caption = 
        'Puntos de restauraci'#243'n del plan'#13#10'Cada d'#237'a se guarda autom'#225'ticame' +
        'nte un punto al primer cambio. Puedes crear puntos manuales.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
    end
  end
  object lvPuntos: TListView
    Left = 0
    Top = 56
    Width = 907
    Height = 405
    Align = alClient
    Columns = <
      item
        Caption = 'Fecha y hora'
        Width = 140
      end
      item
        Caption = 'Tipo'
        Width = 90
      end
      item
        Alignment = taRightJustify
        Caption = 'Nodos'
        Width = 70
      end
      item
        Caption = 'Descripci'#243'n'
        Width = 460
      end
      item
        Caption = 'Usuario'
        Width = 120
      end>
    ColumnClick = False
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    OnDblClick = btnRestaurarClick
    ExplicitWidth = 760
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 461
    Width = 907
    Height = 59
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    ExplicitWidth = 760
    object btnCrearManual: TButton
      AlignWithMargins = True
      Left = 12
      Top = 14
      Width = 180
      Height = 33
      Margins.Left = 12
      Margins.Top = 14
      Margins.Bottom = 12
      Align = alLeft
      Caption = 'Crear punto manual...'
      TabOrder = 0
      OnClick = btnCrearManualClick
    end
    object btnEliminar: TButton
      AlignWithMargins = True
      Left = 579
      Top = 14
      Width = 100
      Height = 33
      Margins.Left = 4
      Margins.Top = 14
      Margins.Right = 4
      Margins.Bottom = 12
      Align = alRight
      Caption = 'Eliminar'
      TabOrder = 1
      OnClick = btnEliminarClick
      ExplicitLeft = 432
    end
    object btnRestaurar: TButton
      AlignWithMargins = True
      Left = 687
      Top = 14
      Width = 130
      Height = 33
      Margins.Left = 4
      Margins.Top = 14
      Margins.Right = 4
      Margins.Bottom = 12
      Align = alRight
      Caption = 'Restaurar'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = btnRestaurarClick
      ExplicitLeft = 540
    end
    object btnCerrar: TButton
      AlignWithMargins = True
      Left = 825
      Top = 14
      Width = 70
      Height = 33
      Margins.Left = 4
      Margins.Top = 14
      Margins.Right = 12
      Margins.Bottom = 12
      Align = alRight
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 3
      OnClick = btnCerrarClick
      ExplicitLeft = 678
    end
  end
end
