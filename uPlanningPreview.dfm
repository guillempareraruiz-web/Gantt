object frmPlanningPreview: TfrmPlanningPreview
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Preview de Planificaci'#243'n'
  ClientHeight = 520
  ClientWidth = 700
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 700
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3750201
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 20
      Top = 8
      Width = 250
      Height = 22
      Caption = 'Simulaci'#243'n de Planificaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -17
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblProfile: TLabel
      Left = 20
      Top = 34
      Width = 50
      Height = 15
      Caption = 'Perfil: ---'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14540253
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 480
    Width = 700
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      700
      40)
    object btnApply: TButton
      Left = 500
      Top = 6
      Width = 100
      Height = 28
      Anchors = [akTop, akRight]
      Caption = #9989' Aplicar'
      Default = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = btnApplyClick
    end
    object btnCancel: TButton
      Left = 610
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object pnlContent: TPanel
    Left = 0
    Top = 60
    Width = 700
    Height = 420
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object pnlKPIs: TPanel
      Left = 0
      Top = 0
      Width = 700
      Height = 100
      Align = alTop
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object lblTotal: TLabel
        Left = 20
        Top = 12
        Width = 50
        Height = 15
        Caption = 'Total OTs:'
      end
      object lblAssigned: TLabel
        Left = 20
        Top = 34
        Width = 60
        Height = 15
        Caption = 'Asignadas:'
      end
      object lblUnassigned: TLabel
        Left = 20
        Top = 56
        Width = 70
        Height = 15
        Caption = 'Sin asignar:'
      end
      object lblGroups: TLabel
        Left = 20
        Top = 78
        Width = 50
        Height = 15
        Caption = 'Grupos:'
      end
      object lblTotalVal: TLabel
        Left = 120
        Top = 12
        Width = 10
        Height = 17
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblAssignedVal: TLabel
        Left = 120
        Top = 34
        Width = 10
        Height = 17
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 32768
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblUnassignedVal: TLabel
        Left = 120
        Top = 56
        Width = 10
        Height = 17
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblGroupsVal: TLabel
        Left = 120
        Top = 78
        Width = 10
        Height = 17
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 11141375
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblOccupation: TLabel
        Left = 300
        Top = 12
        Width = 100
        Height = 15
        Caption = 'Ocupaci'#243'n media:'
      end
      object lblOccupationVal: TLabel
        Left = 420
        Top = 12
        Width = 20
        Height = 17
        Caption = '0%'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblFiltered: TLabel
        Left = 300
        Top = 34
        Width = 60
        Height = 15
        Caption = 'Excluidas:'
      end
      object lblFilteredVal: TLabel
        Left = 420
        Top = 34
        Width = 10
        Height = 17
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 8421504
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
    end
    object mmoDetail: TMemo
      Left = 0
      Top = 100
      Width = 700
      Height = 320
      Align = alClient
      BorderStyle = bsNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 1
    end
  end
end
