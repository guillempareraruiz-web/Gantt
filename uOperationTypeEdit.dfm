object frmOperationTypeEdit: TfrmOperationTypeEdit
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Tipo de operaci'#243'n'
  ClientHeight = 320
  ClientWidth = 480
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 17
  object pnlBody: TPanel
    Left = 0
    Top = 0
    Width = 480
    Height = 264
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object lblOperacion: TLabel
      Left = 16
      Top = 16
      Width = 113
      Height = 17
      Caption = 'C'#243'digo de operaci'#243'n'
    end
    object lblMax: TLabel
      Left = 16
      Top = 72
      Width = 195
      Height = 17
      Caption = 'M'#225'x. operarios en paralelo (>=1)'
    end
    object lblFactor: TLabel
      Left = 232
      Top = 72
      Width = 198
      Height = 17
      Caption = 'Factor paralelismo (0..1; 1=ideal)'
    end
    object lblDesc: TLabel
      Left = 16
      Top = 128
      Width = 73
      Height = 17
      Caption = 'Descripci'#243'n'
    end
    object lblHelp: TLabel
      Left = 16
      Top = 188
      Width = 448
      Height = 60
      AutoSize = False
      Caption =
        'Max=1 -> no paralelizable (soldar, fresar). Max>1 -> paralelizab' +
        'le.'#13#10'Factor 1.00 -> N operarios reducen tiempo a 1/N (ideal).'#13#10 +
        'Factor 0.85 -> rendimiento decrece 15% por cada operario adicio' +
        'nal.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6316128
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object edOperacion: TEdit
      Left = 16
      Top = 36
      Width = 200
      Height = 25
      CharCase = ecUpperCase
      TabOrder = 0
    end
    object edMax: TEdit
      Left = 16
      Top = 92
      Width = 200
      Height = 25
      Alignment = taRightJustify
      TabOrder = 1
      Text = '1'
    end
    object edFactor: TEdit
      Left = 232
      Top = 92
      Width = 200
      Height = 25
      Alignment = taRightJustify
      TabOrder = 2
      Text = '1.0000'
    end
    object edDesc: TEdit
      Left = 16
      Top = 148
      Width = 448
      Height = 25
      TabOrder = 3
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 264
    Width = 480
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOK: TButton
      Left = 288
      Top = 14
      Width = 80
      Height = 28
      Caption = 'Aceptar'
      Default = True
      ModalResult = 1
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 380
      Top = 14
      Width = 80
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
