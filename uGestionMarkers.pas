unit uGestionMarkers;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxSpinEdit,
  cxCheckBox, cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019DarkGray, dxSkinOffice2019White,
  dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus,
  dxSkinSilver, dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008,
  dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, dxSkinWXI,
  dxSkinXmas2008Blue, dxScrollbarAnnotations,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges,
  // Project
  uGanttTypes, uMarkerEditor;

type
  TGoToDateProc = reference to procedure(const ADate: TDateTime);
  TMarkerChangedProc = reference to procedure;

  TfrmGestionMarkers = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    shpHeaderLine: TShape;
    pnlBottom: TPanel;
    btnClose: TButton;
    lblCount: TLabel;
    pnlToolbar: TPanel;
    btnEdit: TButton;
    btnDelete: TButton;
    btnGoTo: TButton;
    grid: TcxGrid;
    tv: TcxGridTableView;
    colId: TcxGridColumn;
    colCaption: TcxGridColumn;
    colDateTime: TcxGridColumn;
    colStyle: TcxGridColumn;
    colColor: TcxGridColumn;
    colMoveable: TcxGridColumn;
    colVisible: TcxGridColumn;
    lv: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCloseClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnGoToClick(Sender: TObject);
  private
    FMarkers: TArray<TGanttMarker>;
    FGoToDate: TGoToDateProc;
    FOnMarkerChanged: TMarkerChangedProc;
    FChanged: Boolean;

    procedure GridDblClick(Sender: TObject);
    procedure RefreshGrid;
    procedure UpdateCount;
    function GetFocusedMarkerId: Integer;
    function GetSelectedMarkerIds: TArray<Integer>;
    function StyleToStr(S: TMarkerStyle): string;
    function FindMarkerIndex(AId: Integer): Integer;
    procedure DoGoToFocused;
  public
    class procedure Execute(
      var AMarkers: TArray<TGanttMarker>;
      const AGoToDate: TGoToDateProc;
      const AOnChanged: TMarkerChangedProc);
  end;

var
  frmGestionMarkers: TfrmGestionMarkers;

implementation

{$R *.dfm}

{ ============================================= }
{             Execute                           }
{ ============================================= }

class procedure TfrmGestionMarkers.Execute(
  var AMarkers: TArray<TGanttMarker>;
  const AGoToDate: TGoToDateProc;
  const AOnChanged: TMarkerChangedProc);
var
  F: TfrmGestionMarkers;
begin
  F := TfrmGestionMarkers.Create(Application);
  try
    F.FMarkers := Copy(AMarkers);
    F.FGoToDate := AGoToDate;
    F.FOnMarkerChanged := AOnChanged;
    F.FChanged := False;
    F.RefreshGrid;
    F.ShowModal;
    if F.FChanged then
      AMarkers := Copy(F.FMarkers);
  finally
    F.Free;
  end;
end;

{ ============================================= }
{             Form events                       }
{ ============================================= }

procedure TfrmGestionMarkers.FormCreate(Sender: TObject);
begin
  tv.OnDblClick := GridDblClick;
end;

procedure TfrmGestionMarkers.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

procedure TfrmGestionMarkers.btnCloseClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

{ ============================================= }
{             Refresh                           }
{ ============================================= }

procedure TfrmGestionMarkers.GridDblClick(Sender: TObject);
begin
  DoGoToFocused;
end;

procedure TfrmGestionMarkers.RefreshGrid;
var
  i: Integer;
  rec: Integer;
begin
  tv.BeginUpdate;
  try
    tv.DataController.RecordCount := Length(FMarkers);
    for i := 0 to High(FMarkers) do
    begin
      rec := i;
      tv.DataController.Values[rec, colId.Index] := FMarkers[i].Id;
      tv.DataController.Values[rec, colCaption.Index] := FMarkers[i].Caption;
      tv.DataController.Values[rec, colDateTime.Index] :=
        FormatDateTime('dd/mm/yyyy hh:nn', FMarkers[i].DateTime);
      tv.DataController.Values[rec, colStyle.Index] := StyleToStr(FMarkers[i].Style);
      tv.DataController.Values[rec, colColor.Index] :=
        '$' + IntToHex(FMarkers[i].Color, 6);
      tv.DataController.Values[rec, colMoveable.Index] := FMarkers[i].Moveable;
      tv.DataController.Values[rec, colVisible.Index] := FMarkers[i].Visible;
    end;
  finally
    tv.EndUpdate;
  end;
  UpdateCount;
end;

procedure TfrmGestionMarkers.UpdateCount;
begin
  lblCount.Caption := IntToStr(Length(FMarkers)) + ' marcadores';
end;

{ ============================================= }
{             Helpers                           }
{ ============================================= }

function TfrmGestionMarkers.StyleToStr(S: TMarkerStyle): string;
begin
  case S of
    msLine:   Result := 'L'#237'nea';
    msDashed: Result := 'Discontinua';
    msDotted: Result := 'Punteada';
  else
    Result := 'L'#237'nea';
  end;
end;

function TfrmGestionMarkers.GetFocusedMarkerId: Integer;
var
  rec: Integer;
begin
  Result := -1;
  if tv.Controller.FocusedRecord = nil then Exit;
  rec := tv.Controller.FocusedRecord.RecordIndex;
  if (rec >= 0) and (rec <= High(FMarkers)) then
    Result := FMarkers[rec].Id;
end;

function TfrmGestionMarkers.GetSelectedMarkerIds: TArray<Integer>;
var
  i, rec: Integer;
begin
  SetLength(Result, 0);
  for i := 0 to tv.Controller.SelectedRecordCount - 1 do
  begin
    rec := tv.Controller.SelectedRecords[i].RecordIndex;
    if (rec >= 0) and (rec <= High(FMarkers)) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := FMarkers[rec].Id;
    end;
  end;
end;

function TfrmGestionMarkers.FindMarkerIndex(AId: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(FMarkers) do
    if FMarkers[i].Id = AId then
      Exit(i);
end;

{ ============================================= }
{             Actions                           }
{ ============================================= }

procedure TfrmGestionMarkers.btnEditClick(Sender: TObject);
var
  mId, idx: Integer;
  M: TGanttMarker;
  res: TMarkerEditorResult;
begin
  mId := GetFocusedMarkerId;
  if mId < 0 then Exit;
  idx := FindMarkerIndex(mId);
  if idx < 0 then Exit;

  M := FMarkers[idx];
  res := TfrmMarkerEditor.Execute(M);

  case res of
    merOK:
    begin
      FMarkers[idx] := M;
      FChanged := True;
      RefreshGrid;
    end;
    merDelete:
    begin
      // Eliminar
      if idx < High(FMarkers) then
        FMarkers[idx] := FMarkers[High(FMarkers)];
      SetLength(FMarkers, Length(FMarkers) - 1);
      FChanged := True;
      RefreshGrid;
    end;
  end;
end;

procedure TfrmGestionMarkers.btnDeleteClick(Sender: TObject);
var
  ids: TArray<Integer>;
  i, j, last: Integer;
  found: Boolean;
begin
  ids := GetSelectedMarkerIds;
  if Length(ids) = 0 then
  begin
    // Si no hi ha selecció múltiple, agafar el focused
    var focId: Integer := GetFocusedMarkerId;
    if focId < 0 then Exit;
    SetLength(ids, 1);
    ids[0] := focId;
  end;

  if MessageDlg('Eliminar ' + IntToStr(Length(ids)) + ' marcador(es)?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  // Eliminar de darrere cap endavant
  for i := 0 to High(ids) do
  begin
    for j := 0 to High(FMarkers) do
    begin
      if FMarkers[j].Id = ids[i] then
      begin
        last := High(FMarkers);
        if j <> last then
          FMarkers[j] := FMarkers[last];
        SetLength(FMarkers, last);
        Break;
      end;
    end;
  end;

  FChanged := True;
  RefreshGrid;
end;

procedure TfrmGestionMarkers.btnGoToClick(Sender: TObject);
begin
  DoGoToFocused;
end;

procedure TfrmGestionMarkers.DoGoToFocused;
var
  mId, idx: Integer;
begin
  mId := GetFocusedMarkerId;
  if mId < 0 then Exit;
  idx := FindMarkerIndex(mId);
  if idx < 0 then Exit;

  if Assigned(FGoToDate) then
    FGoToDate(FMarkers[idx].DateTime);
end;

end.
