unit uCustomColsManager;

// ============================================================================
// Punto unico para gestionar las columnas/campos personalizados de todas las
// entidades. Es un LANZADOR: selector de entidad + boton que abre el CRUD ya
// existente de esa entidad (Backlog/Centros/Operarios/Maquinas), todos sobre
// FS_PL_Cfg_GridColumns.
//
// Nota: los campos custom de NODOS (motor de reglas / CardLayout) viven todavia
// en custom_fields.json y se gestionan aparte; su migracion a BD esta pendiente
// (ver memoria project_gantt_custom_fields_json_to_db).
// ============================================================================

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmCustomColsManager = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlContent: TPanel;
    lblEntidad: TLabel;
    cmbEntidad: TComboBox;
    lblHelp: TLabel;
    pnlBottom: TPanel;
    btnGestionar: TButton;
    btnMapeoErp: TButton;
    btnCerrar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnGestionarClick(Sender: TObject);
    procedure btnMapeoErpClick(Sender: TObject);
    procedure cmbEntidadChange(Sender: TObject);
  private
    procedure UpdateHelp;
    procedure UpdateMapeoBtn;
  public
    class procedure Execute;
  end;

implementation

{$R *.dfm}

uses
  uHelpViewer,
  uBacklogCustomCols, uCentresCustomCols, uOperariosCustomCols,
  uMaquinasCustomCols, uErpFieldMapping;

const
  ENT_BACKLOG   = 0;
  ENT_CENTROS   = 1;
  ENT_OPERARIOS = 2;
  ENT_MAQUINAS  = 3;

class procedure TfrmCustomColsManager.Execute;
var
  F: TfrmCustomColsManager;
begin
  F := TfrmCustomColsManager.Create(Application);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmCustomColsManager.FormCreate(Sender: TObject);
begin
  cmbEntidad.Style := csDropDownList;
  cmbEntidad.Items.Clear;
  cmbEntidad.Items.Add('Backlog (pendientes)');   // ENT_BACKLOG
  cmbEntidad.Items.Add('Centros de trabajo');     // ENT_CENTROS
  cmbEntidad.Items.Add('Operarios');              // ENT_OPERARIOS
  cmbEntidad.Items.Add('M'#225'quinas');               // ENT_MAQUINAS
  cmbEntidad.ItemIndex := ENT_BACKLOG;
  UpdateHelp;
  UpdateMapeoBtn;
  THelpViewer.InstallHelp(Self, 'uCustomColsManager', 'Campos personalizados');
end;

procedure TfrmCustomColsManager.cmbEntidadChange(Sender: TObject);
begin
  UpdateHelp;
  UpdateMapeoBtn;
end;

procedure TfrmCustomColsManager.UpdateMapeoBtn;
begin
  // El mapeo ERP de momento solo aplica al Backlog (Raw_Item).
  btnMapeoErp.Enabled := cmbEntidad.ItemIndex = ENT_BACKLOG;
end;

procedure TfrmCustomColsManager.UpdateHelp;
begin
  case cmbEntidad.ItemIndex of
    ENT_BACKLOG:
      lblHelp.Caption :=
        'Columnas del grid de pendientes. Permiten asociar el campo al origen ' +
        '(OF/Pedido/Proyecto) y al nivel (OF/OT/OP).';
    ENT_CENTROS:
      lblHelp.Caption := 'Columnas personalizadas de la lista de centros de trabajo.';
    ENT_OPERARIOS:
      lblHelp.Caption := 'Columnas personalizadas de la lista de operarios.';
    ENT_MAQUINAS:
      lblHelp.Caption := 'Columnas personalizadas de la lista de m'#225'quinas.';
  else
    lblHelp.Caption := '';
  end;
end;

procedure TfrmCustomColsManager.btnGestionarClick(Sender: TObject);
begin
  // Abre el CRUD existente de la entidad seleccionada. Cada uno escribe en
  // FS_PL_Cfg_GridColumns con su GridId.
  case cmbEntidad.ItemIndex of
    ENT_BACKLOG:   TfrmBacklogCustomCols.Execute;
    ENT_CENTROS:   TfrmCentresCustomCols.Execute;
    ENT_OPERARIOS: TfrmOperariosCustomCols.Execute;
    ENT_MAQUINAS:  TfrmMaquinasCustomCols.Execute;
  end;
end;

procedure TfrmCustomColsManager.btnMapeoErpClick(Sender: TObject);
begin
  // Mapeo de columnas del Backlog a expresiones SQL del ERP (perfil integrador).
  TfrmErpFieldMapping.Execute;
end;

end.
