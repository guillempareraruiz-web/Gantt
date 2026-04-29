object frmErpSelector: TfrmErpSelector
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Selector de ERP'
  ClientHeight = 580
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlIzq: TPanel
    Left = 0
    Top = 0
    Width = 320
    Height = 530
    Align = alLeft
    BevelOuter = bvNone
    Padding.Left = 12
    Padding.Top = 12
    Padding.Right = 6
    Padding.Bottom = 12
    TabOrder = 0
    object lblTituloLista: TLabel
      AlignWithMargins = True
      Left = 12
      Top = 12
      Width = 302
      Height = 20
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 6
      Align = alTop
      Caption = 'Sistemas ERP disponibles'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      ExplicitWidth = 167
    end
    object lstErps: TListBox
      Left = 12
      Top = 38
      Width = 302
      Height = 480
      Style = lbOwnerDrawFixed
      Align = alClient
      ItemHeight = 56
      TabOrder = 0
      OnClick = lstErpsClick
      OnDrawItem = lstErpsDrawItem
      ExplicitTop = 32
      ExplicitHeight = 366
    end
  end
  object pnlDer: TPanel
    Left = 320
    Top = 0
    Width = 440
    Height = 530
    Align = alClient
    BevelOuter = bvNone
    Padding.Left = 6
    Padding.Top = 12
    Padding.Right = 12
    Padding.Bottom = 12
    TabOrder = 1
    object pnlDetalle: TPanel
      Left = 6
      Top = 12
      Width = 422
      Height = 506
      Align = alClient
      BevelOuter = bvNone
      BorderStyle = bsSingle
      Color = clWindow
      ParentBackground = False
      TabOrder = 0
      object imgLogo: TImage
        Left = 16
        Top = 16
        Width = 96
        Height = 96
        Center = True
        Proportional = True
        Stretch = True
      end
      object lblNombre: TLabel
        Left = 128
        Top = 20
        Width = 100
        Height = 23
        Caption = 'Nombre ERP'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblEstado: TLabel
        Left = 128
        Top = 50
        Width = 50
        Height = 15
        Caption = 'Disponible'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGreen
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblDescripcion: TLabel
        Left = 128
        Top = 76
        Width = 270
        Height = 36
        AutoSize = False
        Caption = 'Descripci'#243'n del ERP seleccionado.'
        WordWrap = True
      end
      object btnPreferencias: TButton
        Left = 16
        Top = 140
        Width = 390
        Height = 38
        Caption = 'Preferencias de sincronizaci'#243'n...'
        TabOrder = 0
        OnClick = btnPreferenciasClick
      end
      object btnProbarConexion: TButton
        Left = 16
        Top = 188
        Width = 390
        Height = 38
        Caption = 'Probar conexi'#243'n'
        TabOrder = 1
        OnClick = btnProbarConexionClick
      end
      object lblResultado: TLabel
        Left = 16
        Top = 236
        Width = 390
        Height = 60
        AutoSize = False
        Caption = ''
        WordWrap = True
      end
    end
  end
  object pnlBotones: TPanel
    Left = 0
    Top = 530
    Width = 760
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    Padding.Left = 12
    Padding.Right = 12
    Padding.Bottom = 10
    TabOrder = 2
    object btnGuardar: TButton
      AlignWithMargins = True
      Left = 555
      Top = 5
      Width = 95
      Height = 32
      Margins.Top = 5
      Margins.Bottom = 3
      Align = alRight
      Caption = 'Guardar'
      Default = True
      ModalResult = 1
      TabOrder = 0
      OnClick = btnGuardarClick
    end
    object btnCancelar: TButton
      AlignWithMargins = True
      Left = 653
      Top = 5
      Width = 95
      Height = 32
      Margins.Top = 5
      Margins.Bottom = 3
      Align = alRight
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
