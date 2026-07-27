object frmWbsNivelacionDlg: TfrmWbsNivelacionDlg
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  Caption = 'Nivelar recursos'
  ClientHeight = 640
  ClientWidth = 900
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  Constraints.MinWidth = 780
  Constraints.MinHeight = 560
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 8
      Width = 140
      Height = 25
      Caption = 'Nivelar recursos'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 16
      Top = 36
      Width = 3
      Height = 15
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlKPI: TPanel
    Left = 0
    Top = 60
    Width = 900
    Height = 76
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
  end
  object pnlOpciones: TPanel
    Left = 0
    Top = 136
    Width = 900
    Height = 54
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object lblAviso: TLabel
      Left = 16
      Top = 32
      Width = 868
      Height = 15
      Anchors = [akLeft, akTop, akRight]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object chkSoloHolgura: TcxCheckBox
      Left = 16
      Top = 6
      Width = 350
      Height = 21
      Caption =
        'Nivelar s'#243'lo dentro de la holgura (no retrasar el proyecto)'
      TabOrder = 0
      Properties.OnChange = OpcionesChanged
      Transparent = True
    end
    object chkMoverIniciadas: TcxCheckBox
      Left = 386
      Top = 6
      Width = 300
      Height = 21
      Caption = 'Mover tambi'#233'n las tareas ya iniciadas'
      TabOrder = 1
      Properties.OnChange = OpcionesChanged
      Transparent = True
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 600
    Width = 900
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 5
    object btnAplicar: TcxButton
      Left = 688
      Top = 6
      Width = 96
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Aplicar'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 792
      Top = 6
      Width = 96
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object pnlConflictos: TPanel
    Left = 0
    Top = 490
    Width = 900
    Height = 110
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 4
    object lblConflictos: TLabel
      Left = 16
      Top = 4
      Width = 868
      Height = 15
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Sin resolver'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object memoConflictos: TcxMemo
      Left = 16
      Top = 24
      Anchors = [akLeft, akTop, akRight, akBottom]
      Properties.ReadOnly = True
      Properties.ScrollBars = ssVertical
      Style.BorderStyle = ebsNone
      Style.Color = 16053492
      TabOrder = 0
      Height = 80
      Width = 868
    end
  end
  object grid: TcxGrid
    Left = 0
    Top = 190
    Width = 900
    Height = 300
    Align = alClient
    TabOrder = 3
    object tv: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
      object colTarea: TcxGridColumn
        Caption = 'Tarea'
        Width = 260
      end
      object colActual: TcxGridColumn
        Caption = 'Inicio actual'
        Width = 110
      end
      object colNuevo: TcxGridColumn
        Caption = 'Inicio propuesto'
        Width = 120
      end
      object colRetraso: TcxGridColumn
        Caption = 'Retraso'
        Width = 100
      end
      object colMotivo: TcxGridColumn
        Caption = 'Espera por'
        Width = 240
      end
    end
    object lvl: TcxGridLevel
      GridView = tv
    end
  end
end
