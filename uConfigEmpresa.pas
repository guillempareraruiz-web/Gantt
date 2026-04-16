unit uConfigEmpresa;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls;

type
  TfrmConfigEmpresa = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    pnlContent: TPanel;
    lblSeccionRecursos: TLabel;
    chkPlanificaOperarios: TCheckBox;
    lblHelpOperarios: TLabel;
    chkPlanificaMoldes: TCheckBox;
    lblHelpMoldes: TLabel;
    lblSeccionEstructura: TLabel;
    rbSimple: TRadioButton;
    lblHelpSimple: TLabel;
    rbCompleja: TRadioButton;
    lblHelpCompleja: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  public
    class function Execute: Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

class function TfrmConfigEmpresa.Execute: Boolean;
var
  F: TfrmConfigEmpresa;
begin
  F := TfrmConfigEmpresa.Create(Application);
  try
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmConfigEmpresa.FormCreate(Sender: TObject);
begin
  if DMPlanner.CurrentEmpresaNombre <> '' then
    lblSubtitle.Caption := 'Preferencias de planificación — ' +
      DMPlanner.CurrentEmpresaNombre;

  chkPlanificaOperarios.Checked := DMPlanner.PlanificaOperarios;
  chkPlanificaMoldes.Checked := DMPlanner.PlanificaMoldes;
  rbSimple.Checked := DMPlanner.EstructuraNodos = enSimple;
  rbCompleja.Checked := DMPlanner.EstructuraNodos = enCompleja;
end;

procedure TfrmConfigEmpresa.btnOKClick(Sender: TObject);
var
  Estructura: TEstructuraNodos;
begin
  if rbSimple.Checked then
    Estructura := enSimple
  else
    Estructura := enCompleja;

  try
    DMPlanner.SaveEmpresaPreferencias(
      chkPlanificaOperarios.Checked,
      chkPlanificaMoldes.Checked,
      Estructura);
    ModalResult := mrOk;
  except
    on E: Exception do
    begin
      ShowMessage('Error guardando configuración: ' + E.Message);
      ModalResult := mrNone;
    end;
  end;
end;

end.
