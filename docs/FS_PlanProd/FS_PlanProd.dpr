program FS_PlanProd;

uses
  Vcl.Forms,
  FS.PlanProd.Types in 'src\FS.PlanProd.Types.pas',
  FS.PlanProd.Catalogo in 'src\FS.PlanProd.Catalogo.pas',
  FS.PlanProd.Engine in 'src\FS.PlanProd.Engine.pas',
  FS.PlanProd.SessionData in 'src\FS.PlanProd.SessionData.pas',
  Form.Main in 'forms\Form.Main.pas' {frmMain},
  Form.Pesos in 'forms\Form.Pesos.pas' {frmPesos},
  Form.Operarios in 'forms\Form.Operarios.pas' {frmOperarios},
  Form.Ordenes in 'forms\Form.Ordenes.pas' {frmOrdenes},
  Form.Asignaciones in 'forms\Form.Asignaciones.pas' {frmAsignaciones};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'FS - Planificador de Producción';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
