unit Form.Asignaciones;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids;

type
  TfrmAsignaciones = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    pnlBottom: TPanel;
    btnCerrar: TButton;
    btnExportarTxt: TButton;
    pnlClient: TPanel;
    sgAsignaciones: TStringGrid;
    pnlInfo: TPanel;
    lblTotalAsig: TLabel;
    lblCosteTotal: TLabel;
    lblScoreMedio: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnExportarTxtClick(Sender: TObject);
  private
    procedure RefrescarGrid;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils,
  System.Math,
  FS.PlanProd.Types,
  FS.PlanProd.SessionData;

procedure TfrmAsignaciones.FormCreate(Sender: TObject);
begin
  sgAsignaciones.ColCount := 8;
  sgAsignaciones.RowCount := 1;
  sgAsignaciones.Cells[0, 0] := '#';
  sgAsignaciones.Cells[1, 0] := 'Operario';
  sgAsignaciones.Cells[2, 0] := 'Orden';
  sgAsignaciones.Cells[3, 0] := 'Sec';
  sgAsignaciones.Cells[4, 0] := 'Operación';
  sgAsignaciones.Cells[5, 0] := 'Centro';
  sgAsignaciones.Cells[6, 0] := 'Score';
  sgAsignaciones.Cells[7, 0] := 'Coste €';
  sgAsignaciones.ColWidths[0] := 30;
  sgAsignaciones.ColWidths[1] := 80;
  sgAsignaciones.ColWidths[2] := 110;
  sgAsignaciones.ColWidths[3] := 40;
  sgAsignaciones.ColWidths[4] := 110;
  sgAsignaciones.ColWidths[5] := 80;
  sgAsignaciones.ColWidths[6] := 70;
  sgAsignaciones.ColWidths[7] := 80;

  RefrescarGrid;
end;

procedure TfrmAsignaciones.RefrescarGrid;
var
  I: Integer;
  LA: TAsignacion;
  LCosteTotal, LScoreSum: Double;
begin
  sgAsignaciones.RowCount := Max(2, Session.UltimasAsignaciones.Count + 1);
  LCosteTotal := 0;
  LScoreSum := 0;

  for I := 0 to Session.UltimasAsignaciones.Count - 1 do
  begin
    LA := Session.UltimasAsignaciones[I];
    sgAsignaciones.Cells[0, I + 1] := IntToStr(I + 1);
    sgAsignaciones.Cells[1, I + 1] := LA.CodOperario;
    sgAsignaciones.Cells[2, I + 1] := LA.CodOrden;
    sgAsignaciones.Cells[3, I + 1] := IntToStr(LA.NumSecuenciaOperacion);
    sgAsignaciones.Cells[4, I + 1] := LA.CodOperacion;
    sgAsignaciones.Cells[5, I + 1] := LA.CodCentro;
    sgAsignaciones.Cells[6, I + 1] := FormatFloat('0.00', LA.Score);
    sgAsignaciones.Cells[7, I + 1] := FormatFloat('0.00', LA.CosteEstimado);
    LCosteTotal := LCosteTotal + LA.CosteEstimado;
    LScoreSum := LScoreSum + LA.Score;
  end;

  if Session.UltimasAsignaciones.Count = 0 then
  begin
    sgAsignaciones.Cells[0, 1] := '';
    sgAsignaciones.Cells[1, 1] := '';
  end;

  lblTotalAsig.Caption := Format('Asignaciones: %d',
    [Session.UltimasAsignaciones.Count]);
  lblCosteTotal.Caption := Format('Coste total: %.2f €', [LCosteTotal]);
  if Session.UltimasAsignaciones.Count > 0 then
    lblScoreMedio.Caption := Format('Score medio: %.2f',
      [LScoreSum / Session.UltimasAsignaciones.Count])
  else
    lblScoreMedio.Caption := 'Score medio: -';
end;

procedure TfrmAsignaciones.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmAsignaciones.btnExportarTxtClick(Sender: TObject);
var
  LSL: TStringList;
  I: Integer;
  LA: TAsignacion;
  LSaveDlg: TSaveDialog;
begin
  if Session.UltimasAsignaciones.Count = 0 then
  begin
    ShowMessage('No hay asignaciones para exportar.');
    Exit;
  end;

  LSaveDlg := TSaveDialog.Create(Self);
  LSL := TStringList.Create;
  try
    LSaveDlg.Filter := 'CSV (*.csv)|*.csv|Todos (*.*)|*.*';
    LSaveDlg.DefaultExt := 'csv';
    LSaveDlg.FileName := 'asignaciones.csv';
    if not LSaveDlg.Execute then
      Exit;

    LSL.Add('Num;Operario;Orden;Sec;Operacion;Centro;Score;CosteEur');
    for I := 0 to Session.UltimasAsignaciones.Count - 1 do
    begin
      LA := Session.UltimasAsignaciones[I];
      LSL.Add(Format('%d;%s;%s;%d;%s;%s;%.2f;%.2f',
        [I + 1, LA.CodOperario, LA.CodOrden, LA.NumSecuenciaOperacion,
        LA.CodOperacion, LA.CodCentro, LA.Score, LA.CosteEstimado]));
    end;
    LSL.SaveToFile(LSaveDlg.FileName, TEncoding.UTF8);
    ShowMessage('Exportado a: ' + LSaveDlg.FileName);
  finally
    LSL.Free;
    LSaveDlg.Free;
  end;
end;

end.
