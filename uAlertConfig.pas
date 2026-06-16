unit uAlertConfig;
// Form CRUD de configuracion de alertas (FS_PL_AlertRule). Lista TODOS los tipos
// del catalogo (implementados + roadmap) y permite por cada uno: activar/desactivar
// y ajustar el peso (1-100). Al guardar persiste via TAlertRulesRepo.Save.
//
// El grid es cxGrid no-bound: se puebla desde el repo y se relee al guardar.
interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxGridLevel,
  cxGridCustomTableView, cxGridTableView, cxGridCustomView, cxGrid,
  cxCheckBox, cxSpinEdit, cxClasses,
  uGanttAlertas, uAlertRulesRepo;

type
  TfrmAlertConfig = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    Grid: TcxGrid;
    tv: TcxGridTableView;
    colCodigo: TcxGridColumn;
    colAlerta: TcxGridColumn;
    colActiva: TcxGridColumn;
    colPeso: TcxGridColumn;
    colEstado: TcxGridColumn;
    lv: TcxGridLevel;
    pnlBottom: TPanel;
    btnGuardar: TButton;
    btnCancelar: TButton;
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FRepo: TAlertRulesRepo;
    FTipos: TArray<TAlertaTipo>;   // fila i del grid -> tipo
    procedure Poblar;
    procedure Guardar;
  public
    // Abre el dialogo de configuracion sobre el repo dado. Devuelve True si el
    // usuario guardo cambios (el caller deberia refrescar las alertas).
    class function Ejecutar(AOwner: TComponent;
      ARepo: TAlertRulesRepo): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmAlertConfig.Ejecutar(AOwner: TComponent;
  ARepo: TAlertRulesRepo): Boolean;
var
  F: TfrmAlertConfig;
begin
  F := TfrmAlertConfig.Create(AOwner);
  try
    F.FRepo := ARepo;
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmAlertConfig.Poblar;
var
  T: TAlertaTipo;
  rule: TAlertRuleRec;
  row, peso: Integer;
  activa: Boolean;
  estado: string;
begin
  // Una fila por cada tipo del catalogo, en orden de codigo.
  SetLength(FTipos, 0);
  for T := Low(TAlertaTipo) to High(TAlertaTipo) do
    if CodigoDe(T) <> '' then
    begin
      SetLength(FTipos, Length(FTipos) + 1);
      FTipos[High(FTipos)] := T;
    end;

  tv.BeginUpdate;
  try
    tv.DataController.RecordCount := Length(FTipos);
    for row := 0 to High(FTipos) do
    begin
      T := FTipos[row];
      // Config actual (o defecto si el repo no la conoce todavia).
      activa := True;
      peso := PesoDefectoDe(T);
      if Assigned(FRepo) and FRepo.TryGet(CodigoDe(T), rule) then
      begin
        activa := rule.Activa;
        peso := rule.Peso;
      end;
      if EsPendiente(T) then
        estado := 'Pr'#243'ximamente'
      else
        estado := 'Disponible';

      tv.DataController.Values[row, colCodigo.Index] := CodigoDe(T);
      tv.DataController.Values[row, colAlerta.Index] := TituloDe(T);
      tv.DataController.Values[row, colActiva.Index] := activa;
      tv.DataController.Values[row, colPeso.Index]   := peso;
      tv.DataController.Values[row, colEstado.Index] := estado;
    end;
  finally
    tv.EndUpdate;
  end;
end;

procedure TfrmAlertConfig.Guardar;
var
  row: Integer;
  rule: TAlertRuleRec;
begin
  if not Assigned(FRepo) then Exit;
  for row := 0 to tv.DataController.RecordCount - 1 do
  begin
    if (row < 0) or (row > High(FTipos)) then Continue;
    rule.Codigo := CodigoDe(FTipos[row]);
    rule.Activa := tv.DataController.Values[row, colActiva.Index] = True;
    rule.Peso   := tv.DataController.Values[row, colPeso.Index];
    if rule.Peso < 1 then rule.Peso := 1;
    if rule.Peso > 100 then rule.Peso := 100;
    rule.Umbral := -1;             // de momento no se edita el umbral aqui
    rule.Orden  := Ord(FTipos[row]);
    FRepo.Save(rule);
  end;
end;

procedure TfrmAlertConfig.FormShow(Sender: TObject);
begin
  Poblar;
end;

procedure TfrmAlertConfig.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    ModalResult := mrCancel;
    Key := 0;
  end;
end;

procedure TfrmAlertConfig.btnGuardarClick(Sender: TObject);
begin
  // Confirmar la edicion en curso del grid antes de leer valores.
  if tv.DataController.EditingRecordIndex >= 0 then
    tv.DataController.PostEditingData;
  Guardar;
  ModalResult := mrOk;
end;

procedure TfrmAlertConfig.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
