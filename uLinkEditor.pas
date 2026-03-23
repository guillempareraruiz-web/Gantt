unit uLinkEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxSpinEdit,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxScrollbarAnnotations,
  // Project
  uErpTypes, uGanttTypes, uNodeDataRepo;

type
  TLinkEditItem = record
    LinkIndex: Integer;        // index dins FLinks del GanttControl (-1 = nou)
    FromNodeId: Integer;
    ToNodeId: Integer;
    FromCaption: string;
    ToCaption: string;
    LinkType: TLinkType;
    PorcentajeDependencia: Double;
    Deleted: Boolean;
  end;

  TLinkEditorResult = record
    Modified: Boolean;
    Items: TArray<TLinkEditItem>;
  end;

  TfrmLinkEditor = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    shpHeaderLine: TShape;
    pnlBottom: TPanel;
    btnDel: TButton;
    btnOK: TButton;
    btnCancel: TButton;
    Grid: TcxGrid;
    View: TcxGridTableView;
    colDir: TcxGridColumn;
    colOtherNode: TcxGridColumn;
    colFromId: TcxGridColumn;
    colToId: TcxGridColumn;
    colLinkType: TcxGridColumn;
    colPct: TcxGridColumn;
    Level: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure DoOK(Sender: TObject);
    procedure DoCancel(Sender: TObject);
    procedure DoDelete(Sender: TObject);
    procedure DoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FNodeId: Integer;
    FItems: TArray<TLinkEditItem>;
    FResult: TLinkEditorResult;

    procedure LoadGrid;
    procedure DoPctChanged(Sender: TObject);
    function LinkTypeToStr(LT: TLinkType): string;
    function FindItemByFromTo(FromId, ToId: Integer): Integer;
  public
    class function Execute(
      const ANodeId: Integer;
      const ANodeCaption: string;
      const AItems: TArray<TLinkEditItem>;
      out AResult: TLinkEditorResult): Boolean;
  end;

var
  frmLinkEditor: TfrmLinkEditor;

implementation

{$R *.dfm}

{ TfrmLinkEditor }

class function TfrmLinkEditor.Execute(
  const ANodeId: Integer;
  const ANodeCaption: string;
  const AItems: TArray<TLinkEditItem>;
  out AResult: TLinkEditorResult): Boolean;
var
  F: TfrmLinkEditor;
begin
  F := TfrmLinkEditor.Create(Application);
  try
    F.FNodeId := ANodeId;
    F.FItems := Copy(AItems);
    F.FResult.Modified := False;

    F.lblTitle.Caption := 'Links del nodo: ' + ANodeCaption;

    F.LoadGrid;

    Result := F.ShowModal = mrOk;
    if Result then
      AResult := F.FResult;
  finally
    F.Free;
  end;
end;

procedure TfrmLinkEditor.FormCreate(Sender: TObject);
var
  Props: TcxSpinEditProperties;
begin
  Props := colPct.Properties as TcxSpinEditProperties;
  Props.MinValue := 0;
  Props.MaxValue := 100;
  Props.Increment := 5;
  Props.ValueType := vtFloat;
  Props.OnEditValueChanged := DoPctChanged;
end;

procedure TfrmLinkEditor.LoadGrid;
var
  I, Row: Integer;
  IsIncoming: Boolean;
begin
  View.BeginUpdate;
  try
    View.DataController.RecordCount := 0;
    Row := 0;
    for I := 0 to High(FItems) do
    begin
      if FItems[I].Deleted then Continue;

      View.DataController.RecordCount := Row + 1;

      IsIncoming := (FItems[I].ToNodeId = FNodeId);

      if IsIncoming then
      begin
        View.DataController.Values[Row, colDir.Index] := 'Entrada';
        View.DataController.Values[Row, colOtherNode.Index] := FItems[I].FromCaption;
      end
      else
      begin
        View.DataController.Values[Row, colDir.Index] := 'Salida';
        View.DataController.Values[Row, colOtherNode.Index] := FItems[I].ToCaption;
      end;

      View.DataController.Values[Row, colFromId.Index] := FItems[I].FromNodeId;
      View.DataController.Values[Row, colToId.Index] := FItems[I].ToNodeId;
      View.DataController.Values[Row, colLinkType.Index] := LinkTypeToStr(FItems[I].LinkType);
      View.DataController.Values[Row, colPct.Index] := FItems[I].PorcentajeDependencia;

      Inc(Row);
    end;
  finally
    View.EndUpdate;
  end;
end;

function TfrmLinkEditor.FindItemByFromTo(FromId, ToId: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FItems) do
    if (not FItems[I].Deleted) and
       (FItems[I].FromNodeId = FromId) and (FItems[I].ToNodeId = ToId) then
      Exit(I);
  Result := -1;
end;

function TfrmLinkEditor.LinkTypeToStr(LT: TLinkType): string;
begin
  case LT of
    ltFinishStart:  Result := 'Fin-Inicio (FS)';
    ltStartStart:   Result := 'Inicio-Inicio (SS)';
    ltFinishFinish: Result := 'Fin-Fin (FF)';
    ltStartFinish:  Result := 'Inicio-Fin (SF)';
  else
    Result := 'FS';
  end;
end;

procedure TfrmLinkEditor.DoPctChanged(Sender: TObject);
var
  RecIdx, ItemIdx: Integer;
  FromId, ToId: Integer;
  NewVal: Double;
begin
  RecIdx := View.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  // Obtenir valor directament des de l'editor actiu
  if (Sender is TcxCustomSpinEdit) then
    NewVal := TcxCustomSpinEdit(Sender).EditValue
  else
    Exit;

  FromId := View.DataController.Values[RecIdx, colFromId.Index];
  ToId := View.DataController.Values[RecIdx, colToId.Index];

  ItemIdx := FindItemByFromTo(FromId, ToId);
  if ItemIdx >= 0 then
    FItems[ItemIdx].PorcentajeDependencia := NewVal;
end;

procedure TfrmLinkEditor.DoDelete(Sender: TObject);
var
  RecIdx, ItemIdx: Integer;
  FromId, ToId: Integer;
begin
  RecIdx := View.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  FromId := View.DataController.Values[RecIdx, colFromId.Index];
  ToId := View.DataController.Values[RecIdx, colToId.Index];

  if MessageDlg('#191Eliminar este link?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  ItemIdx := FindItemByFromTo(FromId, ToId);
  if ItemIdx >= 0 then
    FItems[ItemIdx].Deleted := True;

  LoadGrid;
end;

procedure TfrmLinkEditor.DoOK(Sender: TObject);
var
  I, ItemIdx: Integer;
  FromId, ToId: Integer;
  V: Variant;
begin
  // Forçar confirmació de l'editor actiu
  View.DataController.Post;

  // Rellegir TOTS els valors del grid per si OnEditValueChanged no s'ha disparat
  for I := 0 to View.DataController.RecordCount - 1 do
  begin
    V := View.DataController.Values[I, colPct.Index];
    if VarIsNull(V) then Continue;
    FromId := View.DataController.Values[I, colFromId.Index];
    ToId := View.DataController.Values[I, colToId.Index];
    ItemIdx := FindItemByFromTo(FromId, ToId);
    if ItemIdx >= 0 then
      FItems[ItemIdx].PorcentajeDependencia := Double(V);
  end;

  FResult.Modified := True;
  FResult.Items := Copy(FItems);
  ModalResult := mrOk;
end;

procedure TfrmLinkEditor.DoCancel(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmLinkEditor.DoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

end.
