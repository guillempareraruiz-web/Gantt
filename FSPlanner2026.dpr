program FSPlanner2026;

uses
  Vcl.Forms,
  Main in 'Main.pas' {Form1},
  uGanttTypes in 'uGanttTypes.pas',
  uGanttControl in 'uGanttControl.pas',
  uCentreCalendar in 'uCentreCalendar.pas',
  uGanttHelpers in 'uGanttHelpers.pas',
  uGanttTimeline in 'uGanttTimeline.pas',
  uGanttCentres in 'uGanttCentres.pas',
  uNodeHelpers in 'uNodeHelpers.pas',
  uNodeDataRepo in 'uNodeDataRepo.pas',
  uGanttBuilder in 'uGanttBuilder.pas',
  uErpSampleBuilder in 'uErpSampleBuilder.pas',
  uGanttNodeHint in 'uGanttNodeHint.pas',
  uErpTypes in 'uErpTypes.pas',
  uColorPalette64LayeredPopup in 'uColorPalette64LayeredPopup.pas',
  uGanttHistory in 'uGanttHistory.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
