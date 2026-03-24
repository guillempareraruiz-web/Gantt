object frmGestionCentres: TfrmGestionCentres
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Gesti'#243'n de Centros y '#193'reas'
  ClientHeight = 620
  ClientWidth = 920
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 920
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 700
      Height = 22
      AutoSize = False
      Caption = 'Gesti'#243'n de Centros y '#193'reas'
      EllipsisPosition = epEndEllipsis
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4474440
      Font.Height = -16
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 33
      Width = 700
      Height = 18
      AutoSize = False
      Caption = #193'reas, centros de trabajo y asignaciones'
      EllipsisPosition = epEndEllipsis
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object shpHeaderLine: TShape
      Left = 0
      Top = 58
      Width = 920
      Height = 2
      Align = alBottom
      Brush.Color = 15061727
      Pen.Style = psClear
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 580
    Width = 920
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      920
      40)
    object btnClose: TButton
      Left = 830
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object pc: TcxPageControl
    Left = 0
    Top = 60
    Width = 920
    Height = 520
    Align = alClient
    TabOrder = 1
    Properties.ActivePage = tabAsignacion
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 518
    ClientRectLeft = 2
    ClientRectRight = 918
    ClientRectTop = 25
    object tabCentros: TcxTabSheet
      Caption = 'Centros'
      object pnlCentroToolbar: TPanel
        Left = 0
        Top = 0
        Width = 916
        Height = 32
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object btnCentroEdit: TButton
          Left = 4
          Top = 2
          Width = 100
          Height = 26
          Caption = 'Inspeccionar'
          TabOrder = 0
          OnClick = btnCentroEditClick
        end
      end
      object gridCentros: TcxGrid
        Left = 0
        Top = 32
        Width = 916
        Height = 461
        Align = alClient
        TabOrder = 1
        object tvCentros: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Inserting = False
          OptionsView.ColumnAutoWidth = True
          OptionsView.GroupByBox = False
          OptionsView.Indicator = True
          object colCentroId: TcxGridColumn
            Caption = 'ID'
            MinWidth = 50
            Options.Editing = False
            Options.HorzSizing = False
            Options.Moving = False
            Width = 50
          end
          object colCentroCodi: TcxGridColumn
            Caption = 'C'#243'digo'
            MinWidth = 100
            Options.Editing = False
            Options.HorzSizing = False
            Options.Moving = False
            Width = 100
          end
          object colCentroTitulo: TcxGridColumn
            Caption = 'T'#237'tulo'
            Options.Editing = False
            Options.Moving = False
            Width = 180
          end
          object colCentroSubtitulo: TcxGridColumn
            Caption = 'Subt'#237'tulo'
            MinWidth = 150
            Options.Editing = False
            Options.HorzSizing = False
            Options.Moving = False
            Width = 150
          end
          object colCentroArea: TcxGridColumn
            Caption = #193'rea'
            MinWidth = 150
            Options.Editing = False
            Options.HorzSizing = False
            Options.Moving = False
            Width = 150
          end
          object colCentroSeq: TcxGridColumn
            Caption = 'Secuencial'
            MinWidth = 70
            Options.Editing = False
            Options.HorzSizing = False
            Options.Moving = False
            Width = 70
          end
          object colCentroMaxLanes: TcxGridColumn
            Caption = 'M'#225'x Lanes'
            MinWidth = 70
            Options.Editing = False
            Options.HorzSizing = False
            Options.Moving = False
            Width = 70
          end
          object colCentroOrder: TcxGridColumn
            Caption = 'Orden'
            PropertiesClassName = 'TcxSpinEditProperties'
            MinWidth = 60
            Options.HorzSizing = False
            Options.Moving = False
            Width = 60
          end
          object colCentroVisible: TcxGridColumn
            Caption = 'Visible'
            PropertiesClassName = 'TcxCheckBoxProperties'
            MinWidth = 60
            Options.HorzSizing = False
            Options.Moving = False
            Width = 60
          end
          object colCentroEnabled: TcxGridColumn
            Caption = 'Habilitado'
            PropertiesClassName = 'TcxCheckBoxProperties'
            MinWidth = 70
            Options.HorzSizing = False
            Options.Moving = False
            Width = 70
          end
        end
        object lvCentros: TcxGridLevel
          GridView = tvCentros
        end
      end
    end
    object tabAreas: TcxTabSheet
      Caption = #193'reas'
      object pnlAreaToolbar: TPanel
        Left = 0
        Top = 0
        Width = 916
        Height = 32
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object btnAreaAdd: TButton
          Left = 4
          Top = 2
          Width = 80
          Height = 26
          Caption = 'A'#241'adir'
          TabOrder = 0
          OnClick = btnAreaAddClick
        end
        object btnAreaEdit: TButton
          Left = 90
          Top = 2
          Width = 80
          Height = 26
          Caption = 'Editar'
          TabOrder = 1
          OnClick = btnAreaEditClick
        end
        object btnAreaDel: TButton
          Left = 176
          Top = 2
          Width = 80
          Height = 26
          Caption = 'Eliminar'
          TabOrder = 2
          OnClick = btnAreaDelClick
        end
      end
      object gridAreas: TcxGrid
        Left = 0
        Top = 32
        Width = 916
        Height = 461
        Align = alClient
        TabOrder = 1
        object tvAreas: TcxGridTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.GroupByBox = False
          OptionsView.Indicator = True
          object colAreaNom: TcxGridColumn
            Caption = 'Nombre '#193'rea'
            Width = 250
          end
          object colAreaCentros: TcxGridColumn
            Caption = 'Centros asignados'
            Width = 600
          end
        end
        object lvAreas: TcxGridLevel
          GridView = tvAreas
        end
      end
    end
    object tabAsignacion: TcxTabSheet
      Caption = 'Asignaci'#243'n Centro '#8596' '#193'rea'
      object splAsig: TSplitter
        Left = 280
        Top = 0
        Width = 6
        Height = 493
        ExplicitHeight = 488
      end
      object pnlAsigLeft: TPanel
        Left = 0
        Top = 0
        Width = 280
        Height = 493
        Align = alLeft
        BevelOuter = bvNone
        TabOrder = 0
        object lblAsigCentro: TLabel
          Left = 8
          Top = 4
          Width = 112
          Height = 17
          Caption = 'Seleccionar Centro'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object gridAsigCentros: TcxGrid
          Left = 0
          Top = 26
          Width = 280
          Height = 467
          Align = alBottom
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvAsigCentros: TcxGridTableView
            Navigator.Buttons.CustomButtons = <>
            ScrollbarAnnotations.CustomAnnotations = <>
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            object colAsigCentroId: TcxGridColumn
              Caption = 'ID'
              Width = 40
            end
            object colAsigCentroTitulo: TcxGridColumn
              Caption = 'Centro'
              Width = 200
            end
          end
          object lvAsigCentros: TcxGridLevel
            GridView = tvAsigCentros
          end
        end
      end
      object pnlAsigRight: TPanel
        Left = 286
        Top = 0
        Width = 630
        Height = 493
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object lblAsigAreas: TLabel
          Left = 8
          Top = 4
          Width = 172
          Height = 17
          Caption = #193'reas (marcar las asignadas)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object gridAsigAreas: TcxGrid
          Left = 0
          Top = 26
          Width = 630
          Height = 467
          Align = alBottom
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvAsigAreas: TcxGridTableView
            Navigator.Buttons.CustomButtons = <>
            ScrollbarAnnotations.CustomAnnotations = <>
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            object colAsigAreaNom: TcxGridColumn
              Caption = #193'rea'
              Options.Editing = False
              Width = 250
            end
            object colAsigAreaCheck: TcxGridColumn
              Caption = 'Asignada'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Width = 80
            end
          end
          object lvAsigAreas: TcxGridLevel
            GridView = tvAsigAreas
          end
        end
      end
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 460
    Top = 300
  end
end
