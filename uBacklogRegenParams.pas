unit uBacklogRegenParams;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxTextEdit, cxMaskEdit, cxSpinEdit, cxContainer;

type
  TfrmBacklogRegenParams = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnAceptar: TButton;
    btnCancel: TButton;
    pnlContent: TPanel;
    lblNumOFs: TLabel;
    spNumOFs: TcxSpinEdit;
    lblNumCom: TLabel;
    spNumCom: TcxSpinEdit;
    lblNumPrj: TLabel;
    spNumPrj: TcxSpinEdit;
    lblAviso: TLabel;
    chkVaciarPlan: TCheckBox;
  public
    class function Execute(out ANumOFs, ANumCom, ANumPrj: Integer;
      out AVaciarPlan: Boolean): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmBacklogRegenParams.Execute(out ANumOFs, ANumCom, ANumPrj: Integer;
  out AVaciarPlan: Boolean): Boolean;
var
  F: TfrmBacklogRegenParams;
begin
  F := TfrmBacklogRegenParams.Create(Application);
  try
    Result := F.ShowModal = mrOk;
    if Result then
    begin
      ANumOFs := F.spNumOFs.Value;
      ANumCom := F.spNumCom.Value;
      ANumPrj := F.spNumPrj.Value;
      AVaciarPlan := F.chkVaciarPlan.Checked;
    end;
  finally
    F.Free;
  end;
end;

end.
