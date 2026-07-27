object frmWbsPanelEsfuerzo: TfrmWbsPanelEsfuerzo
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Resumen del proyecto'
  ClientHeight = 660
  ClientWidth = 1120
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  Constraints.MinWidth = 1120
  Constraints.MinHeight = 600
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1120
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3553567
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 16
      Top = 8
      Width = 197
      Height = 25
      Caption = 'Resumen del proyecto'
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
  object pnlBottom: TPanel
    Left = 0
    Top = 620
    Width = 1120
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnCerrar: TcxButton
      Left = 1012
      Top = 6
      Width = 96
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
  end
  object pc: TcxPageControl
    Left = 0
    Top = 60
    Width = 1120
    Height = 560
    Align = alClient
    TabOrder = 1
    Properties.ActivePage = tsGeneral
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 556
    ClientRectLeft = 4
    ClientRectRight = 1116
    ClientRectTop = 26
    object tsGeneral: TcxTabSheet
      Caption = 'General'
      ImageIndex = 0
      object pnlCalendario: TPanel
        Left = 0
        Top = 0
        Width = 1112
        Height = 108
        Align = alTop
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object lblCalendario: TLabel
          Left = 16
          Top = 8
          Width = 63
          Height = 15
          Caption = 'Calendario'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
      object pnlEsfuerzoKpi: TPanel
        Left = 0
        Top = 108
        Width = 1112
        Height = 108
        Align = alTop
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 1
        object lblEsfuerzoKpi: TLabel
          Left = 16
          Top = 8
          Width = 48
          Height = 15
          Caption = 'Esfuerzo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
      object pnlCosteKpi: TPanel
        Left = 0
        Top = 216
        Width = 1112
        Height = 108
        Align = alTop
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 2
        object lblCosteKpi: TLabel
          Left = 16
          Top = 8
          Width = 35
          Height = 15
          Caption = 'Coste'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
      object pnlProgreso: TPanel
        Left = 0
        Top = 324
        Width = 1112
        Height = 206
        Align = alClient
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 3
        object lblProgreso: TLabel
          Left = 16
          Top = 8
          Width = 90
          Height = 15
          Caption = 'Estado del plan'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
    end
    object tsEsfuerzo: TcxTabSheet
      Caption = 'Esfuerzo'
      ImageIndex = 1
      object pnlPersonas: TPanel
        Left = 0
        Top = 0
        Width = 1112
        Height = 265
        Align = alTop
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object lblPersonas: TLabel
          Left = 16
          Top = 8
          Width = 108
          Height = 15
          Caption = 'Carga por persona'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object gridPersonas: TcxGrid
          Left = 16
          Top = 28
          Width = 1080
          Height = 228
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvPersonas: TcxGridTableView
            Navigator.Buttons.CustomButtons = <>
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsSelection.CellSelect = False
            OptionsView.GroupByBox = False
            object colPersona: TcxGridColumn
              Caption = 'Operario'
              Width = 230
            end
            object colPlan: TcxGridColumn
              Caption = 'Trabajo asignado'
              Width = 130
            end
            object colInvertido: TcxGridColumn
              Caption = 'Invertido'
              Width = 110
            end
            object colCostePersona: TcxGridColumn
              Caption = 'Coste previsto'
              Width = 120
            end
            object colPico: TcxGridColumn
              Caption = 'Pico de carga'
              Width = 120
            end
          end
          object lvlPersonas: TcxGridLevel
            GridView = tvPersonas
          end
        end
      end
      object pnlTareas: TPanel
        Left = 0
        Top = 265
        Width = 1112
        Height = 265
        Align = alClient
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 1
        object lblTareas: TLabel
          Left = 16
          Top = 8
          Width = 165
          Height = 15
          Caption = 'Tareas con mayor desviaci'#243'n'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object gridTareas: TcxGrid
          Left = 16
          Top = 28
          Width = 1080
          Height = 228
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvTareas: TcxGridTableView
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
              Width = 320
            end
            object colTrabajo: TcxGridColumn
              Caption = 'Trabajo'
              Width = 100
            end
            object colInv: TcxGridColumn
              Caption = 'Invertido'
              Width = 100
            end
            object colDesv: TcxGridColumn
              Caption = 'Desviaci'#243'n'
              Width = 140
            end
          end
          object lvlTareas: TcxGridLevel
            GridView = tvTareas
          end
        end
      end
    end
    object tsCostes: TcxTabSheet
      Caption = 'Costes'
      ImageIndex = 2
      object lblCostes: TLabel
        Left = 16
        Top = 12
        Width = 108
        Height = 15
        Caption = 'Coste por persona'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblAvisoTarifas: TLabel
        Left = 16
        Top = 508
        Width = 1080
        Height = 15
        Anchors = [akLeft, akRight, akBottom]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object gridCostes: TcxGrid
        Left = 16
        Top = 32
        Width = 1080
        Height = 468
        Anchors = [akLeft, akTop, akRight, akBottom]
        TabOrder = 0
        object tvCostes: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsSelection.CellSelect = False
          OptionsView.GroupByBox = False
          object colCostePersonaNom: TcxGridColumn
            Caption = 'Operario'
            Width = 230
          end
          object colTarifa: TcxGridColumn
            Caption = 'Tarifa'
            Width = 100
          end
          object colHorasPlan: TcxGridColumn
            Caption = 'Horas previstas'
            Width = 120
          end
          object colCostePlan: TcxGridColumn
            Caption = 'Coste previsto'
            Width = 120
          end
          object colHorasReal: TcxGridColumn
            Caption = 'Horas reales'
            Width = 110
          end
          object colCosteReal: TcxGridColumn
            Caption = 'Coste incurrido'
            Width = 120
          end
        end
        object lvlCostes: TcxGridLevel
          GridView = tvCostes
        end
      end
    end
    object tsCurva: TcxTabSheet
      Caption = 'Avance'
      ImageIndex = 3
      object pnlCurvaTop: TPanel
        Left = 0
        Top = 0
        Width = 1112
        Height = 48
        Align = alTop
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object lblCurva: TLabel
          Left = 16
          Top = 6
          Width = 200
          Height = 15
          Caption = 'Avance del trabajo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblCurvaNota: TLabel
          Left = 16
          Top = 26
          Width = 1080
          Height = 15
          Anchors = [akLeft, akTop, akRight]
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object pnlCurva: TPanel
        Left = 0
        Top = 48
        Width = 1112
        Height = 482
        Align = alClient
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 1
      end
    end
    object tsRiesgos: TcxTabSheet
      Caption = 'Riesgos'
      ImageIndex = 4
      object lblRiesgos: TLabel
        Left = 16
        Top = 12
        Width = 200
        Height = 15
        Caption = 'Lo que conviene mirar hoy'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object gridRiesgos: TcxGrid
        Left = 16
        Top = 32
        Width = 1080
        Height = 490
        Anchors = [akLeft, akTop, akRight, akBottom]
        TabOrder = 0
        object tvRiesgos: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsSelection.CellSelect = False
          OptionsView.GroupByBox = False
          object colRiesgoTipo: TcxGridColumn
            Caption = 'Tipo'
            Width = 140
          end
          object colRiesgoTarea: TcxGridColumn
            Caption = 'Tarea'
            Width = 380
          end
          object colRiesgoFecha: TcxGridColumn
            Caption = 'Fecha'
            Width = 110
          end
          object colRiesgoDetalle: TcxGridColumn
            Caption = 'Detalle'
            Width = 250
          end
        end
        object lvlRiesgos: TcxGridLevel
          GridView = tvRiesgos
        end
      end
    end
  end
end
