object frmGestionMoldes: TfrmGestionMoldes
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Gesti'#243'n de Moldes'
  ClientHeight = 660
  ClientWidth = 1020
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
    Width = 1020
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      1020
      60)
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 700
      Height = 22
      AutoSize = False
      Caption = 'Gesti'#243'n de Moldes'
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
      Caption = 'Moldes, relaciones con centros, operaciones, art'#237'culos y utillajes'
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
      Width = 1020
      Height = 2
      Align = alBottom
      Brush.Color = 15061727
      Pen.Style = psClear
    end
    object chkDarkMode: TCheckBox
      Left = 930
      Top = 8
      Width = 80
      Height = 17
      Anchors = [akTop, akRight]
      Caption = 'Oscuro'
      TabOrder = 0
      OnClick = chkDarkModeClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 620
    Width = 1020
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      1020
      40)
    object btnCerrar: TButton
      Left = 930
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
  object pc: TcxPageControl
    Left = 0
    Top = 60
    Width = 1020
    Height = 560
    Align = alClient
    TabOrder = 1
    Properties.ActivePage = tabMoldes
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 558
    ClientRectLeft = 2
    ClientRectRight = 1018
    ClientRectTop = 25
    object tabMoldes: TcxTabSheet
      Caption = 'Moldes'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object pnlMoldeToolbar: TPanel
        Left = 0
        Top = 0
        Width = 1012
        Height = 32
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object btnMoldeAdd: TButton
          Left = 4
          Top = 2
          Width = 80
          Height = 26
          Caption = 'A'#241'adir'
          TabOrder = 0
          OnClick = btnMoldeAddClick
        end
        object btnMoldeEdit: TButton
          Left = 90
          Top = 2
          Width = 80
          Height = 26
          Caption = 'Editar'
          TabOrder = 1
          OnClick = btnMoldeEditClick
        end
        object btnMoldeDel: TButton
          Left = 176
          Top = 2
          Width = 80
          Height = 26
          Caption = 'Eliminar'
          TabOrder = 2
          OnClick = btnMoldeDelClick
        end
      end
      object gridMoldes: TcxGrid
        Left = 0
        Top = 32
        Width = 1012
        Height = 496
        Align = alClient
        TabOrder = 1
        object tvMoldes: TcxGridTableView
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
          object colMoldeId: TcxGridColumn
            Caption = 'ID'
            Width = 40
          end
          object colMoldeCodigo: TcxGridColumn
            Caption = 'C'#243'digo'
            Width = 100
          end
          object colMoldeDesc: TcxGridColumn
            Caption = 'Descripci'#243'n'
            Width = 180
          end
          object colMoldeTipo: TcxGridColumn
            Caption = 'Tipo'
            Width = 80
          end
          object colMoldeEstado: TcxGridColumn
            Caption = 'Estado'
            Width = 90
          end
          object colMoldeCavidades: TcxGridColumn
            Caption = 'Cavidades'
            Width = 65
          end
          object colMoldeUbicacion: TcxGridColumn
            Caption = 'Ubicaci'#243'n'
            Width = 100
          end
          object colMoldeCentroActual: TcxGridColumn
            Caption = 'Centro Actual'
            Width = 100
          end
          object colMoldeCentros: TcxGridColumn
            Caption = 'Centros Permitidos'
            Width = 140
          end
          object colMoldeOperaciones: TcxGridColumn
            Caption = 'Operaciones'
            Width = 130
          end
        end
        object lvMoldes: TcxGridLevel
          GridView = tvMoldes
        end
      end
    end
    object tabCentros: TcxTabSheet
      Caption = 'Centros de Trabajo'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object splCentros: TSplitter
        Left = 280
        Top = 0
        Width = 6
        Height = 528
      end
      object pnlCentrosLeft: TPanel
        Left = 0
        Top = 0
        Width = 280
        Height = 528
        Align = alLeft
        BevelOuter = bvNone
        TabOrder = 0
        object lblSelMoldeCentro: TLabel
          Left = 8
          Top = 4
          Width = 120
          Height = 17
          Caption = 'Seleccionar Molde'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object gridCentroMoldes: TcxGrid
          Left = 0
          Top = 26
          Width = 280
          Height = 502
          Align = alBottom
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvCentroMoldes: TcxGridTableView
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
            object colCentroMoldeId: TcxGridColumn
              Caption = 'ID'
              Width = 40
            end
            object colCentroMoldeCodigo: TcxGridColumn
              Caption = 'Molde'
              Width = 200
            end
          end
          object lvCentroMoldes: TcxGridLevel
            GridView = tvCentroMoldes
          end
        end
      end
      object pnlCentrosRight: TPanel
        Left = 286
        Top = 0
        Width = 726
        Height = 528
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object lblCentrosAsig: TLabel
          Left = 8
          Top = 4
          Width = 260
          Height = 17
          Caption = 'Centros de Trabajo (marcar los permitidos)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object gridCentrosAsig: TcxGrid
          Left = 0
          Top = 26
          Width = 726
          Height = 502
          Align = alBottom
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvCentrosAsig: TcxGridTableView
            Navigator.Buttons.CustomButtons = <>
            ScrollbarAnnotations.CustomAnnotations = <>
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            object colCentrosAsigNom: TcxGridColumn
              Caption = 'Centro de Trabajo'
              Options.Editing = False
              Width = 250
            end
            object colCentrosAsigCheck: TcxGridColumn
              Caption = 'Asignado'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Width = 80
            end
            object colCentrosAsigPreferente: TcxGridColumn
              Caption = 'Preferente'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Width = 80
            end
          end
          object lvCentrosAsig: TcxGridLevel
            GridView = tvCentrosAsig
          end
        end
      end
    end
    object tabOperaciones: TcxTabSheet
      Caption = 'Operaciones'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object splOperaciones: TSplitter
        Left = 280
        Top = 0
        Width = 6
        Height = 528
      end
      object pnlOpsLeft: TPanel
        Left = 0
        Top = 0
        Width = 280
        Height = 528
        Align = alLeft
        BevelOuter = bvNone
        TabOrder = 0
        object lblSelMoldeOp: TLabel
          Left = 8
          Top = 4
          Width = 120
          Height = 17
          Caption = 'Seleccionar Molde'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object gridOpMoldes: TcxGrid
          Left = 0
          Top = 26
          Width = 280
          Height = 502
          Align = alBottom
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvOpMoldes: TcxGridTableView
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
            object colOpMoldeId: TcxGridColumn
              Caption = 'ID'
              Width = 40
            end
            object colOpMoldeCodigo: TcxGridColumn
              Caption = 'Molde'
              Width = 200
            end
          end
          object lvOpMoldes: TcxGridLevel
            GridView = tvOpMoldes
          end
        end
      end
      object pnlOpsRight: TPanel
        Left = 286
        Top = 0
        Width = 726
        Height = 528
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object lblOpsAsig: TLabel
          Left = 8
          Top = 4
          Width = 260
          Height = 17
          Caption = 'Operaciones (marcar las compatibles)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object gridOpsAsig: TcxGrid
          Left = 0
          Top = 26
          Width = 726
          Height = 502
          Align = alBottom
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvOpsAsig: TcxGridTableView
            Navigator.Buttons.CustomButtons = <>
            ScrollbarAnnotations.CustomAnnotations = <>
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            object colOpsAsigNom: TcxGridColumn
              Caption = 'Operaci'#243'n'
              Options.Editing = False
              Width = 250
            end
            object colOpsAsigCheck: TcxGridColumn
              Caption = 'Asignada'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Width = 80
            end
          end
          object lvOpsAsig: TcxGridLevel
            GridView = tvOpsAsig
          end
        end
      end
    end
    object tabArticulos: TcxTabSheet
      Caption = 'Art'#237'culos'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object splArticulos: TSplitter
        Left = 280
        Top = 0
        Width = 6
        Height = 528
      end
      object pnlArtLeft: TPanel
        Left = 0
        Top = 0
        Width = 280
        Height = 528
        Align = alLeft
        BevelOuter = bvNone
        TabOrder = 0
        object lblSelMoldeArt: TLabel
          Left = 8
          Top = 4
          Width = 120
          Height = 17
          Caption = 'Seleccionar Molde'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object gridArtMoldes: TcxGrid
          Left = 0
          Top = 26
          Width = 280
          Height = 502
          Align = alBottom
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvArtMoldes: TcxGridTableView
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
            object colArtMoldeId: TcxGridColumn
              Caption = 'ID'
              Width = 40
            end
            object colArtMoldeCodigo: TcxGridColumn
              Caption = 'Molde'
              Width = 200
            end
          end
          object lvArtMoldes: TcxGridLevel
            GridView = tvArtMoldes
          end
        end
      end
      object pnlArtRight: TPanel
        Left = 286
        Top = 0
        Width = 726
        Height = 528
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object lblArtAsig: TLabel
          Left = 8
          Top = 4
          Width = 260
          Height = 17
          Caption = 'Art'#237'culos (marcar los asociados)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object gridArtAsig: TcxGrid
          Left = 0
          Top = 26
          Width = 726
          Height = 502
          Align = alBottom
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvArtAsig: TcxGridTableView
            Navigator.Buttons.CustomButtons = <>
            ScrollbarAnnotations.CustomAnnotations = <>
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            object colArtAsigNom: TcxGridColumn
              Caption = 'Art'#237'culo'
              Options.Editing = False
              Width = 250
            end
            object colArtAsigCheck: TcxGridColumn
              Caption = 'Asociado'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Width = 80
            end
          end
          object lvArtAsig: TcxGridLevel
            GridView = tvArtAsig
          end
        end
      end
    end
    object tabUtillajes: TcxTabSheet
      Caption = 'Utillajes'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object splUtillajes: TSplitter
        Left = 280
        Top = 0
        Width = 6
        Height = 528
      end
      object pnlUtLeft: TPanel
        Left = 0
        Top = 0
        Width = 280
        Height = 528
        Align = alLeft
        BevelOuter = bvNone
        TabOrder = 0
        object lblSelMoldeUt: TLabel
          Left = 8
          Top = 4
          Width = 120
          Height = 17
          Caption = 'Seleccionar Molde'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object gridUtMoldes: TcxGrid
          Left = 0
          Top = 26
          Width = 280
          Height = 502
          Align = alBottom
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvUtMoldes: TcxGridTableView
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
            object colUtMoldeId: TcxGridColumn
              Caption = 'ID'
              Width = 40
            end
            object colUtMoldeCodigo: TcxGridColumn
              Caption = 'Molde'
              Width = 200
            end
          end
          object lvUtMoldes: TcxGridLevel
            GridView = tvUtMoldes
          end
        end
      end
      object pnlUtRight: TPanel
        Left = 286
        Top = 0
        Width = 726
        Height = 528
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object lblUtAsig: TLabel
          Left = 8
          Top = 4
          Width = 260
          Height = 17
          Caption = 'Utillajes (marcar los necesarios)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object gridUtAsig: TcxGrid
          Left = 0
          Top = 26
          Width = 726
          Height = 502
          Align = alBottom
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvUtAsig: TcxGridTableView
            Navigator.Buttons.CustomButtons = <>
            ScrollbarAnnotations.CustomAnnotations = <>
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            object colUtAsigNom: TcxGridColumn
              Caption = 'Utillaje'
              Options.Editing = False
              Width = 250
            end
            object colUtAsigCheck: TcxGridColumn
              Caption = 'Asignado'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Width = 80
            end
            object colUtAsigObligatorio: TcxGridColumn
              Caption = 'Obligatorio'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Width = 80
            end
          end
          object lvUtAsig: TcxGridLevel
            GridView = tvUtAsig
          end
        end
      end
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 500
    Top = 320
  end
end
