object frmOperarios: TfrmOperarios
  Left = 0
  Top = 0
  Caption = 'Operarios y Polivalencia'
  ClientHeight = 600
  ClientWidth = 1100
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Color = clHighlight
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 12
      Width = 230
      Height = 25
      Caption = 'Operarios y Polivalencia'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHighlightText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlClient: TPanel
    Left = 0
    Top = 50
    Width = 1100
    Height = 497
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object Splitter1: TSplitter
      Left = 540
      Top = 0
      Width = 5
      Height = 497
      ExplicitLeft = 280
      ExplicitTop = 24
    end
    object sgOperarios: TStringGrid
      Left = 0
      Top = 0
      Width = 540
      Height = 497
      Align = alLeft
      ColCount = 7
      DefaultRowHeight = 22
      FixedCols = 0
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
      TabOrder = 0
      OnClick = sgOperariosClick
    end
    object pnlDetalle: TPanel
      Left = 545
      Top = 0
      Width = 555
      Height = 497
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object gbDatos: TGroupBox
        Left = 8
        Top = 4
        Width = 540
        Height = 200
        Caption = 'Datos del operario'
        TabOrder = 0
        object lblCodigo: TLabel
          Left = 16
          Top = 24
          Width = 41
          Height = 15
          Caption = 'C'#243'digo:'
        end
        object lblNombre: TLabel
          Left = 200
          Top = 24
          Width = 49
          Height = 15
          Caption = 'Nombre:'
        end
        object lblSueldo: TLabel
          Left = 16
          Top = 64
          Width = 79
          Height = 15
          Caption = 'Sueldo (€/h):'
        end
        object lblRecargoNoche: TLabel
          Left = 200
          Top = 64
          Width = 96
          Height = 15
          Caption = 'Recargo Noche x:'
        end
        object lblRecargoFestivo: TLabel
          Left = 380
          Top = 64
          Width = 96
          Height = 15
          Caption = 'Recargo Festivo x:'
        end
        object lblTurno: TLabel
          Left = 16
          Top = 112
          Width = 35
          Height = 15
          Caption = 'Turno:'
        end
        object lblHoraIni: TLabel
          Left = 200
          Top = 112
          Width = 64
          Height = 15
          Caption = 'Hora inicio:'
        end
        object lblHoraFin: TLabel
          Left = 320
          Top = 112
          Width = 50
          Height = 15
          Caption = 'Hora fin:'
        end
        object edtCodigo: TEdit
          Left = 16
          Top = 40
          Width = 170
          Height = 23
          ReadOnly = True
          TabOrder = 0
        end
        object edtNombre: TEdit
          Left = 200
          Top = 40
          Width = 320
          Height = 23
          TabOrder = 1
        end
        object edtSueldo: TEdit
          Left = 16
          Top = 80
          Width = 100
          Height = 23
          Alignment = taRightJustify
          TabOrder = 2
        end
        object edtRecargoNoche: TEdit
          Left = 200
          Top = 80
          Width = 100
          Height = 23
          Alignment = taRightJustify
          TabOrder = 3
          Text = '1.25'
        end
        object edtRecargoFestivo: TEdit
          Left = 380
          Top = 80
          Width = 100
          Height = 23
          Alignment = taRightJustify
          TabOrder = 4
          Text = '1.75'
        end
        object cbTurno: TComboBox
          Left = 16
          Top = 128
          Width = 170
          Height = 23
          Style = csDropDownList
          TabOrder = 5
        end
        object seHoraIni: TEdit
          Left = 200
          Top = 128
          Width = 100
          Height = 23
          Alignment = taRightJustify
          TabOrder = 6
          Text = '6'
        end
        object seHoraFin: TEdit
          Left = 320
          Top = 128
          Width = 100
          Height = 23
          Alignment = taRightJustify
          TabOrder = 7
          Text = '14'
        end
        object btnGuardar: TButton
          Left = 320
          Top = 165
          Width = 100
          Height = 25
          Caption = 'Guardar'
          TabOrder = 8
          OnClick = btnGuardarClick
        end
        object btnCancelar: TButton
          Left = 425
          Top = 165
          Width = 100
          Height = 25
          Caption = 'Cancelar'
          TabOrder = 9
          OnClick = btnCancelarClick
        end
      end
      object gbHabilidades: TGroupBox
        Left = 8
        Top = 210
        Width = 290
        Height = 280
        Caption = 'Habilidades / Polivalencia'
        TabOrder = 1
        object sgHabilidades: TStringGrid
          Left = 8
          Top = 24
          Width = 273
          Height = 215
          ColCount = 2
          DefaultRowHeight = 22
          Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goAlwaysShowEditor]
          TabOrder = 0
        end
        object btnAddHab: TButton
          Left = 8
          Top = 246
          Width = 130
          Height = 25
          Caption = 'A'#241'adir habilidad'
          TabOrder = 1
          OnClick = btnAddHabClick
        end
        object btnDelHab: TButton
          Left = 144
          Top = 246
          Width = 130
          Height = 25
          Caption = 'Borrar habilidad'
          TabOrder = 2
          OnClick = btnDelHabClick
        end
      end
      object gbCentros: TGroupBox
        Left = 305
        Top = 210
        Width = 240
        Height = 280
        Caption = 'Centros habilitados'
        TabOrder = 2
        object clbCentros: TCheckListBox
          Left = 8
          Top = 24
          Width = 224
          Height = 245
          TabOrder = 0
        end
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 547
    Width = 1100
    Height = 53
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnCerrar: TButton
      Left = 990
      Top = 12
      Width = 90
      Height = 30
      Caption = 'Cerrar'
      Default = True
      ModalResult = 1
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
end
