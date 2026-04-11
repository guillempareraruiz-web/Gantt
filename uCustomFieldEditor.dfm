object frmCustomFieldEditor: TfrmCustomFieldEditor
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Editor de Campos Personalizados'
  ClientHeight = 620
  ClientWidth = 720
  Color = clBtnFace
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
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 720
    Height = 36
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object btnAdd: TButton
      Left = 8
      Top = 4
      Width = 80
      Height = 28
      Caption = 'A'#241'adir'
      TabOrder = 0
      OnClick = btnAddClick
    end
    object btnDelete: TButton
      Left = 96
      Top = 4
      Width = 80
      Height = 28
      Caption = 'Eliminar'
      TabOrder = 1
      OnClick = btnDeleteClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 580
    Width = 720
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      720
      40)
    object btnOK: TButton
      Left = 540
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Aceptar'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 630
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
  object pnlCenter: TPanel
    Left = 0
    Top = 36
    Width = 720
    Height = 544
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object splitter: TSplitter
      Left = 280
      Top = 0
      Width = 5
      Height = 544
      ExplicitHeight = 412
    end
    object tvFields: TTreeView
      Left = 0
      Top = 0
      Width = 280
      Height = 544
      Align = alLeft
      DragMode = dmAutomatic
      HideSelection = False
      Indent = 19
      ReadOnly = True
      TabOrder = 0
      OnChange = tvFieldsChange
      OnCustomDrawItem = tvFieldsCustomDrawItem
      OnDragDrop = tvFieldsDragDrop
      OnDragOver = tvFieldsDragOver
    end
    object pnlDetail: TPanel
      Left = 285
      Top = 0
      Width = 435
      Height = 544
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object lblFieldName: TLabel
        Left = 16
        Top = 16
        Width = 115
        Height = 15
        Caption = 'Nombre del campo:'
      end
      object lblCaption: TLabel
        Left = 16
        Top = 60
        Width = 100
        Height = 15
        Caption = 'Etiqueta visible:'
      end
      object lblType: TLabel
        Left = 16
        Top = 104
        Width = 27
        Height = 15
        Caption = 'Tipo:'
      end
      object lblDefault: TLabel
        Left = 16
        Top = 148
        Width = 103
        Height = 15
        Caption = 'Valor por defecto:'
      end
      object lblGrupo: TLabel
        Left = 16
        Top = 192
        Width = 39
        Height = 15
        Caption = 'Grupo:'
      end
      object lblTooltip: TLabel
        Left = 16
        Top = 236
        Width = 44
        Height = 15
        Caption = 'Tooltip:'
      end
      object lblMinValue: TLabel
        Left = 16
        Top = 280
        Width = 51
        Height = 15
        Caption = 'Val. min:'
      end
      object lblMaxValue: TLabel
        Left = 164
        Top = 280
        Width = 55
        Height = 15
        Caption = 'Val. max:'
      end
      object lblFormatMask: TLabel
        Left = 16
        Top = 324
        Width = 107
        Height = 15
        Caption = 'M'#225'scara formato:'
      end
      object lblListValues: TLabel
        Left = 16
        Top = 412
        Width = 193
        Height = 15
        Caption = 'Valores lista (uno por l'#237'nea):'
      end
      object edtFieldName: TEdit
        Left = 16
        Top = 34
        Width = 280
        Height = 23
        TabOrder = 0
        OnChange = edtFieldNameChange
      end
      object edtCaption: TEdit
        Left = 16
        Top = 78
        Width = 280
        Height = 23
        TabOrder = 1
        OnChange = edtCaptionChange
      end
      object cmbType: TComboBox
        Left = 16
        Top = 122
        Width = 180
        Height = 23
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 2
        Text = 'Texto'
        OnChange = cmbTypeChange
        Items.Strings = (
          'Texto'
          'Entero'
          'Decimal'
          'Fecha'
          'S'#237'/No'
          'Lista')
      end
      object edtDefault: TEdit
        Left = 16
        Top = 166
        Width = 280
        Height = 23
        TabOrder = 3
        OnChange = edtDefaultChange
      end
      object edtGrupo: TEdit
        Left = 16
        Top = 210
        Width = 280
        Height = 23
        TabOrder = 4
        OnChange = edtGrupoChange
      end
      object edtTooltip: TEdit
        Left = 16
        Top = 254
        Width = 280
        Height = 23
        TabOrder = 5
        OnChange = edtTooltipChange
      end
      object edtMinValue: TEdit
        Left = 16
        Top = 298
        Width = 130
        Height = 23
        TabOrder = 6
        OnChange = edtMinValueChange
      end
      object edtMaxValue: TEdit
        Left = 164
        Top = 298
        Width = 132
        Height = 23
        TabOrder = 7
        OnChange = edtMaxValueChange
      end
      object edtFormatMask: TEdit
        Left = 16
        Top = 342
        Width = 280
        Height = 23
        TabOrder = 8
        OnChange = edtFormatMaskChange
      end
      object chkRequired: TCheckBox
        Left = 16
        Top = 378
        Width = 100
        Height = 17
        Caption = 'Obligatorio'
        TabOrder = 9
        OnClick = chkRequiredClick
      end
      object chkReadOnly: TCheckBox
        Left = 120
        Top = 378
        Width = 100
        Height = 17
        Caption = 'Solo lectura'
        TabOrder = 10
        OnClick = chkReadOnlyClick
      end
      object chkVisible: TCheckBox
        Left = 230
        Top = 378
        Width = 80
        Height = 17
        Caption = 'Visible'
        TabOrder = 11
        OnClick = chkVisibleClick
      end
      object mmoListValues: TMemo
        Left = 16
        Top = 430
        Width = 280
        Height = 100
        ScrollBars = ssVertical
        TabOrder = 12
        OnChange = mmoListValuesChange
      end
    end
  end
end
