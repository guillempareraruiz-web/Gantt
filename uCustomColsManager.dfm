object frmCustomColsManager: TfrmCustomColsManager
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Campos personalizados'
  ClientHeight = 280
  ClientWidth = 480
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
    Width = 480
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 300
      Height = 25
      Caption = 'Campos personalizados'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 33
      Width = 360
      Height = 15
      Caption = 'Columnas personalizadas por entidad'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlContent: TPanel
    Left = 0
    Top = 56
    Width = 480
    Height = 184
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblEntidad: TLabel
      Left = 24
      Top = 24
      Width = 44
      Height = 15
      Caption = 'Entidad'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblHelp: TLabel
      Left = 24
      Top = 84
      Width = 432
      Height = 60
      AutoSize = False
      Caption = ''
      WordWrap = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object cmbEntidad: TComboBox
      Left = 24
      Top = 44
      Width = 432
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnChange = cmbEntidadChange
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 240
    Width = 480
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnGestionar: TButton
      Left = 12
      Top = 6
      Width = 170
      Height = 28
      Caption = 'Gestionar columnas...'
      Default = True
      TabOrder = 0
      OnClick = btnGestionarClick
    end
    object btnMapeoErp: TButton
      Left = 188
      Top = 6
      Width = 150
      Height = 28
      Caption = 'Mapeo ERP...'
      TabOrder = 1
      OnClick = btnMapeoErpClick
    end
    object btnCerrar: TButton
      Left = 368
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Cerrar'
      Cancel = True
      ModalResult = 2
      TabOrder = 2
    end
  end
end
