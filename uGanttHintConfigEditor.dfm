object frmGanttHintConfigEditor: TfrmGanttHintConfigEditor
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Configurar informaci'#243'n emergente (hint)'
  ClientHeight = 520
  ClientWidth = 720
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 720
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 16448250
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 12
      Width = 281
      Height = 21
      Caption = 'Informaci'#243'n emergente de los nodos'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210752
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 38
      Width = 379
      Height = 15
      Caption = 
        'Elija qu'#233' campos se muestran al pasar el rat'#243'n y en qu'#233' orden, p' +
        'or Vista.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblVista: TLabel
      Left = 480
      Top = 14
      Width = 28
      Height = 15
      Caption = 'Vista:'
    end
    object cmbVista: TComboBox
      Left = 480
      Top = 34
      Width = 220
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnChange = cmbVistaChange
    end
  end
  object pnlFooter: TPanel
    Left = 0
    Top = 470
    Width = 720
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnAceptar: TButton
      Left = 520
      Top = 10
      Width = 90
      Height = 30
      Caption = 'Aceptar'
      Default = True
      ModalResult = 1
      TabOrder = 0
      OnClick = btnAceptarClick
    end
    object btnCancelar: TButton
      Left = 616
      Top = 10
      Width = 90
      Height = 30
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 70
    Width = 720
    Height = 400
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object pnlLeft: TPanel
      Left = 0
      Top = 0
      Width = 380
      Height = 400
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      object lblCampos: TLabel
        Left = 12
        Top = 10
        Width = 158
        Height = 15
        Caption = 'Campos (marque los visibles):'
      end
      object clbCampos: TcxCheckListBox
        Left = 12
        Top = 32
        Width = 300
        Height = 352
        Items = <>
        TabOrder = 0
        OnClickCheck = clbCamposClickCheck
      end
      object pnlOrderBtns: TPanel
        Left = 320
        Top = 32
        Width = 56
        Height = 352
        BevelOuter = bvNone
        TabOrder = 1
        object btnSubir: TButton
          Left = 8
          Top = 8
          Width = 44
          Height = 30
          Caption = #9650
          TabOrder = 0
          OnClick = btnSubirClick
        end
        object btnBajar: TButton
          Left = 8
          Top = 44
          Width = 44
          Height = 30
          Caption = #9660
          TabOrder = 1
          OnClick = btnBajarClick
        end
      end
    end
    object pnlRight: TPanel
      Left = 380
      Top = 0
      Width = 340
      Height = 400
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object lblPreview: TLabel
        Left = 12
        Top = 10
        Width = 63
        Height = 15
        Caption = 'Vista previa:'
      end
      object memPreview: TMemo
        Left = 12
        Top = 32
        Width = 316
        Height = 352
        Color = 16448250
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4210752
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
  end
end
