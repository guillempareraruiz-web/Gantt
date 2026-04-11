object frmPlanningRulesEditor: TfrmPlanningRulesEditor
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Reglas de Planificaci'#243'n'
  ClientHeight = 680
  ClientWidth = 1280
  Color = 15395562
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlBottom: TPanel
    Left = 0
    Top = 640
    Width = 920
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    Color = 15395562
    ParentBackground = False
    TabOrder = 1
    DesignSize = (
      920
      40)
    object btnOK: TButton
      Left = 740
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Aceptar'
      Default = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 830
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
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 920
    Height = 640
    Align = alClient
    BevelOuter = bvNone
    Color = 15395562
    ParentBackground = False
    TabOrder = 0
    object pnlProfiles: TPanel
      Left = 0
      Top = 0
      Width = 920
      Height = 80
      Align = alTop
      BevelOuter = bvNone
      Color = 15395562
      ParentBackground = False
      TabOrder = 0
      object lblProfile: TLabel
        Left = 16
        Top = 12
        Width = 33
        Height = 15
        Caption = 'Perfil:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblDescription: TLabel
        Left = 16
        Top = 48
        Width = 70
        Height = 15
        Caption = 'Descripci'#243'n:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 14540253
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object cmbProfiles: TComboBox
        Left = 60
        Top = 9
        Width = 240
        Height = 23
        Style = csDropDownList
        TabOrder = 0
        OnChange = cmbProfilesChange
      end
      object btnAddProfile: TButton
        Left = 310
        Top = 8
        Width = 70
        Height = 25
        Caption = '+ Nuevo'
        TabOrder = 1
        OnClick = btnAddProfileClick
      end
      object btnDeleteProfile: TButton
        Left = 386
        Top = 8
        Width = 65
        Height = 25
        Caption = 'Eliminar'
        TabOrder = 2
        OnClick = btnDeleteProfileClick
      end
      object btnRenameProfile: TButton
        Left = 457
        Top = 8
        Width = 80
        Height = 25
        Caption = 'Renombrar'
        TabOrder = 3
        OnClick = btnRenameProfileClick
      end
      object edtDescription: TEdit
        Left = 96
        Top = 45
        Width = 440
        Height = 23
        TabOrder = 4
        OnChange = edtDescriptionChange
      end
    end
    object pnlRules: TPanel
      Left = 0
      Top = 80
      Width = 1280
      Height = 560
      Align = alClient
      BevelOuter = bvNone
      Color = 15395562
      ParentBackground = False
      TabOrder = 1
      object pnlSortRules: TPanel
        Left = 0
        Top = 0
        Width = 420
        Height = 560
        Align = alLeft
        BevelOuter = bvNone
        Color = 15395562
        Padding.Left = 8
        Padding.Top = 0
        Padding.Right = 4
        Padding.Bottom = 8
        ParentBackground = False
        TabOrder = 0
        object pnlSortColumn: TPanel
          Left = 8
          Top = 0
          Width = 408
          Height = 552
          Align = alClient
          BevelOuter = bvNone
          Color = 15132390
          ParentBackground = False
          TabOrder = 0
          object pnlSortHeader: TPanel
            Left = 0
            Top = 0
            Width = 408
            Height = 44
            Align = alTop
            BevelOuter = bvNone
            Color = 15132390
            ParentBackground = False
            TabOrder = 0
            object lblSortTitle: TLabel
              Left = 14
              Top = 12
              Width = 136
              Height = 17
              Caption = #9650#9660' Criterios de Orden'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 3750201
              Font.Height = -13
              Font.Name = 'Segoe UI Semibold'
              Font.Style = []
              ParentFont = False
            end
            object lblSortCount: TLabel
              Left = 310
              Top = 14
              Width = 10
              Height = 15
              Caption = '0'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 8421504
              Font.Height = -12
              Font.Name = 'Segoe UI'
              Font.Style = []
              ParentFont = False
            end
            object btnAddSort: TButton
              Left = 330
              Top = 8
              Width = 68
              Height = 27
              Caption = '+ A'#241'adir'
              TabOrder = 0
              OnClick = btnAddSortClick
            end
          end
          object sbSort: TScrollBox
            Left = 0
            Top = 44
            Width = 408
            Height = 508
            Align = alClient
            BorderStyle = bsNone
            Color = 15132390
            ParentBackground = False
            ParentColor = False
            TabOrder = 1
          end
        end
      end
      object pnlFilterRules: TPanel
        Left = 420
        Top = 0
        Width = 420
        Height = 560
        Align = alLeft
        BevelOuter = bvNone
        Color = 15395562
        Padding.Left = 4
        Padding.Top = 0
        Padding.Right = 4
        Padding.Bottom = 8
        ParentBackground = False
        TabOrder = 1
        object pnlFilterColumn: TPanel
          Left = 4
          Top = 0
          Width = 412
          Height = 552
          Align = alClient
          BevelOuter = bvNone
          Color = 15132390
          ParentBackground = False
          TabOrder = 0
          object pnlFilterHeader: TPanel
            Left = 0
            Top = 0
            Width = 412
            Height = 44
            Align = alTop
            BevelOuter = bvNone
            Color = 15132390
            ParentBackground = False
            TabOrder = 0
            object lblFilterTitle: TLabel
              Left = 14
              Top = 12
              Width = 125
              Height = 17
              Caption = #9881' Reglas de Filtro'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 3750201
              Font.Height = -13
              Font.Name = 'Segoe UI Semibold'
              Font.Style = []
              ParentFont = False
            end
            object lblFilterCount: TLabel
              Left = 310
              Top = 14
              Width = 10
              Height = 15
              Caption = '0'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 8421504
              Font.Height = -12
              Font.Name = 'Segoe UI'
              Font.Style = []
              ParentFont = False
            end
            object btnAddFilter: TButton
              Left = 330
              Top = 8
              Width = 68
              Height = 27
              Caption = '+ A'#241'adir'
              TabOrder = 0
              OnClick = btnAddFilterClick
            end
          end
          object sbFilter: TScrollBox
            Left = 0
            Top = 44
            Width = 412
            Height = 508
            Align = alClient
            BorderStyle = bsNone
            Color = 15132390
            ParentBackground = False
            ParentColor = False
            TabOrder = 1
          end
        end
      end
      object pnlGroupRules: TPanel
        Left = 840
        Top = 0
        Width = 440
        Height = 560
        Align = alClient
        BevelOuter = bvNone
        Color = 15395562
        Padding.Left = 4
        Padding.Top = 0
        Padding.Right = 8
        Padding.Bottom = 8
        ParentBackground = False
        TabOrder = 2
        object pnlGroupColumn: TPanel
          Left = 4
          Top = 0
          Width = 428
          Height = 552
          Align = alClient
          BevelOuter = bvNone
          Color = 15132390
          ParentBackground = False
          TabOrder = 0
          object pnlGroupHeader: TPanel
            Left = 0
            Top = 0
            Width = 428
            Height = 44
            Align = alTop
            BevelOuter = bvNone
            Color = 15132390
            ParentBackground = False
            TabOrder = 0
            object lblGroupTitle: TLabel
              Left = 14
              Top = 12
              Width = 140
              Height = 17
              Caption = #9776' Agrupaci'#243'n (Batching)'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 3750201
              Font.Height = -13
              Font.Name = 'Segoe UI Semibold'
              Font.Style = []
              ParentFont = False
            end
            object lblGroupCount: TLabel
              Left = 330
              Top = 14
              Width = 10
              Height = 15
              Caption = '0'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 8421504
              Font.Height = -12
              Font.Name = 'Segoe UI'
              Font.Style = []
              ParentFont = False
            end
            object btnAddGroup: TButton
              Left = 350
              Top = 8
              Width = 68
              Height = 27
              Caption = '+ A'#241'adir'
              TabOrder = 0
              OnClick = btnAddGroupClick
            end
          end
          object sbGroup: TScrollBox
            Left = 0
            Top = 44
            Width = 428
            Height = 508
            Align = alClient
            BorderStyle = bsNone
            Color = 15132390
            ParentBackground = False
            ParentColor = False
            TabOrder = 1
          end
        end
      end
    end
  end
end
