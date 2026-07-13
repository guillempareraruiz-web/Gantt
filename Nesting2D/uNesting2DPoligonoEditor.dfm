object frmPoligonoEditor: TfrmPoligonoEditor
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Editor de pol'#237'gono'
  ClientHeight = 420
  ClientWidth = 620
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 620
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 14
      Top = 9
      Width = 267
      Height = 21
      Caption = 'V'#233'rtices del pol'#237'gono (mm)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 40
    Width = 260
    Height = 340
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object gridPuntos: TcxGrid
      Left = 8
      Top = 8
      Width = 244
      Height = 292
      TabOrder = 0
      object tvPuntos: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        DataController.OnAfterPost = tvPuntosDataControllerAfterPost
        OptionsView.GroupByBox = False
        OptionsView.Indicator = True
        object colX: TcxGridColumn
          Caption = 'X'
          Width = 110
        end
        object colY: TcxGridColumn
          Caption = 'Y'
          Width = 110
        end
      end
      object lvPuntos: TcxGridLevel
        GridView = tvPuntos
      end
    end
    object btnAddPunto: TcxButton
      Left = 8
      Top = 306
      Width = 118
      Height = 26
      Caption = 'A'#241'adir v'#233'rtice'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 1
      OnClick = btnAddPuntoClick
    end
    object btnDelPunto: TcxButton
      Left = 132
      Top = 306
      Width = 118
      Height = 26
      Caption = 'Quitar v'#233'rtice'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 2
      OnClick = btnDelPuntoClick
    end
  end
  object pnlPreview: TPanel
    Left = 260
    Top = 40
    Width = 360
    Height = 340
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object pbPreview: TPaintBox
      Left = 0
      Top = 0
      Width = 360
      Height = 340
      Align = alClient
      OnPaint = pbPreviewPaint
      ExplicitLeft = 120
      ExplicitTop = 128
    end
  end
  object pnlFooter: TPanel
    Left = 0
    Top = 380
    Width = 620
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object btnAceptar: TcxButton
      Left = 408
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Aceptar'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 0
      OnClick = btnAceptarClick
    end
    object btnCancelar: TcxButton
      Left = 512
      Top = 6
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      LookAndFeel.Kind = lfOffice11
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2010Silver'
      ModalResult = 2
      SpeedButtonOptions.CanBeFocused = False
      SpeedButtonOptions.Flat = True
      TabOrder = 1
    end
  end
end
