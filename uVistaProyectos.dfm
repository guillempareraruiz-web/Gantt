object frmVistaProyectos: TfrmVistaProyectos
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'M'#243'dulo de Proyectos'
  ClientHeight = 640
  ClientWidth = 1180
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDesigned
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1180
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 6313290
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 24
      Top = 10
      Width = 130
      Height = 32
      Caption = 'M'#243'dulo de Proyectos'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 24
      Top = 44
      Width = 260
      Height = 15
      Caption = 'Planificaci'#243'n de proyectos (tareas y dependencias)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14869218
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 44
    Width = 560
    Height = 596
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object tlWbs: TcxTreeList
      Left = 0
      Top = 0
      Width = 560
      Height = 596
      Align = alClient
      Bands = <
        item
        end>
      LookAndFeel.NativeStyle = False
      LookAndFeel.ScrollbarMode = sbmClassic
      LookAndFeel.SkinName = 'Office2019Colorful'
      Navigator.Buttons.CustomButtons = <>
      OptionsBehavior.CellHints = True
      OptionsData.Editing = False
      OptionsSelection.CellSelect = False
      OptionsView.ColumnAutoWidth = False
      OptionsView.GridLines = tlglBoth
      OptionsView.Indicator = True
      ScrollbarAnnotations.CustomAnnotations = <>
      TabOrder = 0
      object colNombre: TcxTreeListColumn
        Caption.Text = 'Nombre'
        MinWidth = 220
        Width = 300
        Options.Editing = False
        Position.ColIndex = 0
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
      object colDuracion: TcxTreeListColumn
        Caption.Text = 'Duraci'#243'n'
        MinWidth = 70
        Width = 80
        Options.Editing = False
        Position.ColIndex = 1
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
      object colInicio: TcxTreeListColumn
        Caption.Text = 'Inicio'
        MinWidth = 85
        Width = 90
        Options.Editing = False
        Position.ColIndex = 2
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
      object colFin: TcxTreeListColumn
        Caption.Text = 'Fin'
        MinWidth = 85
        Width = 90
        Options.Editing = False
        Position.ColIndex = 3
        Position.RowIndex = 0
        Position.BandIndex = 0
        Summary.FooterSummaryItems = <>
        Summary.GroupFooterSummaryItems = <>
      end
    end
  end
  object splMain: TSplitter
    Left = 560
    Top = 44
    Width = 6
    Height = 596
    ExplicitLeft = 560
    ExplicitTop = 44
    ExplicitHeight = 596
  end
  object pnlRight: TPanel
    Left = 566
    Top = 44
    Width = 614
    Height = 596
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
  end
end
