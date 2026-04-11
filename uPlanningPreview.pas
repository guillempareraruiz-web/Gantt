unit uPlanningPreview;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  uGanttTypes;

type
  TPreviewCentreStat = record
    CentreId: Integer;
    CentreName: string;
    AssignedCount: Integer;
    TotalMinutes: Double;
    CapacityMinutes: Double;
    OccupationPct: Double;
  end;

  TPreviewResult = record
    ProfileName: string;
    TotalOTs: Integer;
    AssignedOTs: Integer;
    UnassignedOTs: Integer;
    FilteredOTs: Integer;
    GroupCount: Integer;
    AvgOccupation: Double;
    CentreStats: TArray<TPreviewCentreStat>;
    UnassignedList: TArray<string>;   // descripcions de les OTs no assignades
  end;

  TfrmPlanningPreview = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblProfile: TLabel;
    pnlBottom: TPanel;
    btnApply: TButton;
    btnCancel: TButton;
    pnlContent: TPanel;
    pnlKPIs: TPanel;
    lblTotal: TLabel;
    lblAssigned: TLabel;
    lblUnassigned: TLabel;
    lblGroups: TLabel;
    lblTotalVal: TLabel;
    lblAssignedVal: TLabel;
    lblUnassignedVal: TLabel;
    lblGroupsVal: TLabel;
    lblOccupation: TLabel;
    lblOccupationVal: TLabel;
    lblFiltered: TLabel;
    lblFilteredVal: TLabel;
    mmoDetail: TMemo;
    procedure btnApplyClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    procedure ShowPreview(const AResult: TPreviewResult);
  public
    class function Execute(const AResult: TPreviewResult): Boolean;
  end;

var
  frmPlanningPreview: TfrmPlanningPreview;

implementation

{$R *.dfm}

class function TfrmPlanningPreview.Execute(const AResult: TPreviewResult): Boolean;
var
  F: TfrmPlanningPreview;
begin
  F := TfrmPlanningPreview.Create(Application);
  try
    F.ShowPreview(AResult);
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmPlanningPreview.ShowPreview(const AResult: TPreviewResult);
var
  I: Integer;
  S: TPreviewCentreStat;
  OccBar: string;
  BarLen: Integer;
begin
  lblProfile.Caption := 'Perfil: ' + AResult.ProfileName;
  lblTotalVal.Caption := IntToStr(AResult.TotalOTs);
  lblAssignedVal.Caption := IntToStr(AResult.AssignedOTs);
  lblUnassignedVal.Caption := IntToStr(AResult.UnassignedOTs);
  lblGroupsVal.Caption := IntToStr(AResult.GroupCount);
  lblOccupationVal.Caption := Format('%.1f%%', [AResult.AvgOccupation]);
  lblFilteredVal.Caption := IntToStr(AResult.FilteredOTs);

  mmoDetail.Lines.BeginUpdate;
  try
    mmoDetail.Lines.Clear;
    mmoDetail.Lines.Add('=== DETALLE POR CENTRO ===');
    mmoDetail.Lines.Add('');

    for I := 0 to High(AResult.CentreStats) do
    begin
      S := AResult.CentreStats[I];

      // Barra d'ocupació ASCII
      BarLen := Round(S.OccupationPct / 5);
      if BarLen > 20 then BarLen := 20;
      OccBar := StringOfChar(#$2588, BarLen) + StringOfChar(#$2591, 20 - BarLen);

      mmoDetail.Lines.Add(Format('  %-20s  %d OTs  %.0f/%.0f min  %s %.1f%%', [
        S.CentreName,
        S.AssignedCount,
        S.TotalMinutes,
        S.CapacityMinutes,
        OccBar,
        S.OccupationPct
      ]));
    end;

    if AResult.UnassignedOTs > 0 then
    begin
      mmoDetail.Lines.Add('');
      mmoDetail.Lines.Add('=== OTs SIN ASIGNAR (' + IntToStr(AResult.UnassignedOTs) + ') ===');
      mmoDetail.Lines.Add('');
      for I := 0 to High(AResult.UnassignedList) do
        mmoDetail.Lines.Add('  ' + #$26A0 + ' ' + AResult.UnassignedList[I]);
    end;

    if AResult.FilteredOTs > 0 then
    begin
      mmoDetail.Lines.Add('');
      mmoDetail.Lines.Add(Format('  (%d OTs excluidas por filtros)', [AResult.FilteredOTs]));
    end;
  finally
    mmoDetail.Lines.EndUpdate;
  end;
end;

procedure TfrmPlanningPreview.btnApplyClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmPlanningPreview.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmPlanningPreview.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

end.
