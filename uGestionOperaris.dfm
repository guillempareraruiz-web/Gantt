object frmGestionOperaris: TfrmGestionOperaris
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Gesti'#243'n de Operarios y Departamentos'
  ClientHeight = 620
  ClientWidth = 900
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
    Width = 900
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      900
      60)
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 700
      Height = 22
      AutoSize = False
      Caption = 'Gesti'#243'n de Operarios y Departamentos'
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
      Caption = 'Departamentos, operarios y capacitaciones'
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
      Width = 900
      Height = 2
      Align = alBottom
      Brush.Color = 15061727
      Pen.Style = psClear
    end
    object chkDarkMode: TCheckBox
      Left = 810
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
    Top = 580
    Width = 900
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      900
      40)
    object btnTancar: TButton
      Left = 810
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnTancarClick
    end
  end
  object pc: TcxPageControl
    Left = 0
    Top = 60
    Width = 900
    Height = 520
    Align = alClient
    TabOrder = 1
    Properties.ActivePage = tabOperaris
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 518
    ClientRectLeft = 2
    ClientRectRight = 898
    ClientRectTop = 25
    object tabDepartaments: TcxTabSheet
      Caption = 'Departamentos'
      object pnlDeptToolbar: TPanel
        Left = 0
        Top = 0
        Width = 896
        Height = 32
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object btnDeptAdd: TButton
          Left = 4
          Top = 2
          Width = 80
          Height = 26
          Caption = 'A'#241'adir'
          TabOrder = 0
          OnClick = btnDeptAddClick
        end
        object btnDeptEdit: TButton
          Left = 90
          Top = 2
          Width = 80
          Height = 26
          Caption = 'Editar'
          TabOrder = 1
          OnClick = btnDeptEditClick
        end
        object btnDeptDel: TButton
          Left = 176
          Top = 2
          Width = 80
          Height = 26
          Caption = 'Eliminar'
          TabOrder = 2
          OnClick = btnDeptDelClick
        end
      end
      object gridDepts: TcxGrid
        Left = 0
        Top = 32
        Width = 896
        Height = 461
        Align = alClient
        TabOrder = 1
        object tvDepts: TcxGridTableView
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
          object colDeptId: TcxGridColumn
            Caption = 'ID'
            Width = 50
          end
          object colDeptNom: TcxGridColumn
            Caption = 'Nombre'
            Width = 200
          end
          object colDeptDesc: TcxGridColumn
            Caption = 'Descripci'#243'n'
            Width = 300
          end
          object colDeptOperaris: TcxGridColumn
            Caption = 'Operarios'
            Width = 300
          end
        end
        object lvDepts: TcxGridLevel
          GridView = tvDepts
        end
      end
    end
    object tabOperaris: TcxTabSheet
      Caption = 'Operarios'
      object pnlOpToolbar: TPanel
        Left = 0
        Top = 0
        Width = 896
        Height = 32
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object btnOpAdd: TButton
          Left = 4
          Top = 2
          Width = 80
          Height = 26
          Caption = 'A'#241'adir'
          TabOrder = 0
          OnClick = btnOpAddClick
        end
        object btnOpEdit: TButton
          Left = 90
          Top = 2
          Width = 80
          Height = 26
          Caption = 'Editar'
          TabOrder = 1
          OnClick = btnOpEditClick
        end
        object btnOpDel: TButton
          Left = 176
          Top = 2
          Width = 80
          Height = 26
          Caption = 'Eliminar'
          TabOrder = 2
          OnClick = btnOpDelClick
        end
      end
      object gridOperaris: TcxGrid
        Left = 0
        Top = 32
        Width = 896
        Height = 461
        Align = alClient
        TabOrder = 1
        object tvOperaris: TcxGridTableView
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
          object colOpId: TcxGridColumn
            Caption = 'ID'
            Width = 50
          end
          object colOpNom: TcxGridColumn
            Caption = 'Nombre'
            Width = 180
          end
          object colOpCalendari: TcxGridColumn
            Caption = 'Calendario'
            Width = 80
          end
          object colOpDepts: TcxGridColumn
            Caption = 'Departamentos'
            Width = 200
          end
          object colOpCaps: TcxGridColumn
            Caption = 'Capacitaciones'
            Width = 300
          end
        end
        object lvOperaris: TcxGridLevel
          GridView = tvOperaris
        end
      end
    end
    object tabCapacitacions: TcxTabSheet
      Caption = 'Capacitaciones'
      object splCap: TSplitter
        Left = 250
        Top = 0
        Width = 6
        Height = 493
        ExplicitHeight = 488
      end
      object pnlCapLeft: TPanel
        Left = 0
        Top = 0
        Width = 250
        Height = 493
        Align = alLeft
        BevelOuter = bvNone
        TabOrder = 0
        object lblCapOperari: TLabel
          Left = 8
          Top = 4
          Width = 124
          Height = 17
          Caption = 'Seleccionar Operario'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object gridCapOperaris: TcxGrid
          Left = 0
          Top = 26
          Width = 250
          Height = 467
          Align = alBottom
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvCapOperaris: TcxGridTableView
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
            object colCapOpId: TcxGridColumn
              Caption = 'ID'
              Width = 40
            end
            object colCapOpNom: TcxGridColumn
              Caption = 'Operario'
              Width = 170
            end
          end
          object lvCapOperaris: TcxGridLevel
            GridView = tvCapOperaris
          end
        end
      end
      object pnlCapRight: TPanel
        Left = 256
        Top = 0
        Width = 640
        Height = 493
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object lblCapOps: TLabel
          Left = 8
          Top = 4
          Width = 223
          Height = 17
          Caption = 'Operaciones (marcar las capacitadas)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4474440
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object gridCapOps: TcxGrid
          Left = 0
          Top = 26
          Width = 640
          Height = 467
          Align = alBottom
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
          object tvCapOps: TcxGridTableView
            Navigator.Buttons.CustomButtons = <>
            ScrollbarAnnotations.CustomAnnotations = <>
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            object colCapOpsNom: TcxGridColumn
              Caption = 'Operaci'#243'n'
              Options.Editing = False
              Width = 200
            end
            object colCapOpsCheck: TcxGridColumn
              Caption = 'Capacitado'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Width = 80
            end
          end
          object lvCapOps: TcxGridLevel
            GridView = tvCapOps
          end
        end
      end
    end
  end
  object LookAndFeel: TcxLookAndFeelController
    NativeStyle = False
    SkinName = 'Office2019Colorful'
    Left = 456
    Top = 296
  end
end
