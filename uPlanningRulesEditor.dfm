object frmPlanningRulesEditor: TfrmPlanningRulesEditor
  Left = 0
  Top = 0
  BorderStyle = bsDialog
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
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 1280
    Height = 680
    Align = alClient
    BevelOuter = bvNone
    Color = 15395562
    ParentBackground = False
    TabOrder = 0
    object pnlProfiles: TPanel
      Left = 0
      Top = 0
      Width = 1280
      Height = 80
      Align = alTop
      BevelOuter = bvNone
      Color = 16382457
      ParentBackground = False
      TabOrder = 0
      DesignSize = (
        1280
        80)
      object lblProfile: TLabel
        Left = 16
        Top = 12
        Width = 34
        Height = 15
        Caption = 'Perfil:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3750201
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object lblDescription: TLabel
        Left = 16
        Top = 48
        Width = 68
        Height = 15
        Caption = 'Descripci'#243'n:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 7107965
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
      object btnGuardar: TButton
        Left = 1140
        Top = 22
        Width = 124
        Height = 34
        Anchors = [akTop, akRight]
        Caption = 'Guardar reglas'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3750201
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
        TabOrder = 5
        OnClick = btnGuardarReglasClick
      end
    end
    object pnlRules: TPanel
      Left = 0
      Top = 80
      Width = 1280
      Height = 600
      Align = alClient
      BevelOuter = bvNone
      Color = 15395562
      ParentBackground = False
      TabOrder = 1
      ExplicitHeight = 560
      object pnlSortRules: TPanel
        Left = 0
        Top = 0
        Width = 420
        Height = 560
        Align = alLeft
        BevelOuter = bvNone
        Color = 15395562
        Padding.Left = 8
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
            Height = 60
            Align = alTop
            BevelOuter = bvNone
            Color = 15132390
            ParentBackground = False
            TabOrder = 0
            object lblSortTitle: TLabel
              Left = 14
              Top = 10
              Width = 137
              Height = 17
              Caption = #9650#9660' Criterios de Orden'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 3750201
              Font.Height = -13
              Font.Name = 'Segoe UI Semibold'
              Font.Style = []
              ParentFont = False
            end
            object lblSortSub: TLabel
              Left = 14
              Top = 33
              Width = 300
              Height = 14
              Caption = 'En qu'#233' orden entra la carga al planificar'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 8947848
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = []
              ParentFont = False
            end
            object lblSortCount: TLabel
              Left = 306
              Top = 12
              Width = 6
              Height = 15
              Caption = '0'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clGray
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
            Height = 60
            Align = alTop
            BevelOuter = bvNone
            Color = 15132390
            ParentBackground = False
            TabOrder = 0
            object lblFilterTitle: TLabel
              Left = 14
              Top = 10
              Width = 115
              Height = 17
              Caption = #9881' Reglas de Filtro'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 3750201
              Font.Height = -13
              Font.Name = 'Segoe UI Semibold'
              Font.Style = []
              ParentFont = False
            end
            object lblFilterSub: TLabel
              Left = 14
              Top = 33
              Width = 300
              Height = 14
              Caption = 'Qu'#233' trabajos incluir, excluir o forzar a un centro'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 8947848
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = []
              ParentFont = False
            end
            object lblFilterCount: TLabel
              Left = 306
              Top = 12
              Width = 6
              Height = 15
              Caption = '0'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clGray
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
            Height = 60
            Align = alTop
            BevelOuter = bvNone
            Color = 15132390
            ParentBackground = False
            TabOrder = 0
            object lblGroupTitle: TLabel
              Left = 14
              Top = 10
              Width = 151
              Height = 17
              Caption = #9776' Agrupaci'#243'n (Batching)'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 3750201
              Font.Height = -13
              Font.Name = 'Segoe UI Semibold'
              Font.Style = []
              ParentFont = False
            end
            object lblGroupSub: TLabel
              Left = 14
              Top = 33
              Width = 320
              Height = 14
              Caption = 'Qu'#233' trabajos juntar (mismo valor) para reducir cambios'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 8947848
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = []
              ParentFont = False
            end
            object lblGroupCount: TLabel
              Left = 326
              Top = 12
              Width = 6
              Height = 15
              Caption = '0'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clGray
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
            ParentColor = False
            TabOrder = 1
          end
        end
      end
    end
  end
end
