unit uGanttTypes;

interface

uses
  System.Types, System.SysUtils, System.UITypes, System.DateUtils;

type
  TCentreTreball = record
    Id: Integer;
    CodiCentre: string;  // codi del centre ERP (agrupa múltiples màquines, p.ex. 'CENTRO1')
    Nom: string;
    Maquina: string;
    IsSequencial: Boolean; // si False -> m�ltiples lanes
    BaseHeight: Single;    // al�ada base fila
    Order: Integer;
    Visible: Boolean;
    Enabled: Boolean;
    BkColor: TColor;
  end;

  TNode = record
    Id: Integer;
    CentreId: Integer;                  // centre actual on està planificat
    StartTime: TDateTime;
    EndTime: TDateTime;
    DurationMin: Double;

    Caption: string;

    FillColor: TColor;
    BorderColor: TColor;
    HoverColor: TColor;
    Visible: Boolean;
    Enabled: Boolean;

    DataId: Integer; // clau cap a les dades de domini
  end;

  TEstadoOF = (eoPendiente, eoEnCurso, eoFinalizado, eoBloqueado);

  TNodeData = record
    DataId: Integer;
    Operacion: String;
    CentresTrabajo: TArray<string>;    // noms ERP dels centres permesos; buit = tots
    CentresPermesos: TArray<Integer>;  // ids Gantt dels centres permesos; buit = tots
    NumeroPedido: Integer;
    SeriePedido: string;
    NumeroOrdenFabricacion: Integer;
    SerieFabricacion: string;
    NumeroTrabajo: string;
    FechaEntrega: TDateTime;
    FechaNecesaria: TDateTime;
    Stock: Double;
    CodigoArticulo: string;
    CodigoCliente: String;
    CodigoColor: String;
    CodigoTalla: String;
    DescripcionArticulo: string;
    PorcentajeDependencia: Double;
    UnidadesFabricadas: Double;
    UnidadesAFabricar: Double;
    TiempoUnidadFabSecs: Double; //...tiempo en segundos para fabricar una unidad
    DurationMin: Double;
    DurationMinOriginal: Double;
    OperariosNecesarios: Integer;
    OperariosAsignados: Integer;
    Estado: TEstadoOF;
    Prioridad: Integer;  // 1 = alta, 2 = mitja, 3 = baixa (exemple)
    Modified: Boolean;
    LibreMoviment: Boolean;  // True = es pot moure a qualsevol centre; False = només CentresPermesos
  end;

  TRowLayout = record
    CentreId: Integer;
    TopY: Single;
    Height: Single;
    LaneCount: Integer;
    NameRect: TRectF;   // part esquerra
    GanttRect: TRectF;  // part dreta (fila)
    FirstNodeLayout: Integer; // index dins FNodeLayouts
    LastNodeLayout: Integer;  // inclusive
    Order: Integer;
    Visible: Boolean;
    Enabled: Boolean;
    bkColor: TColor;
  end;

  TNodeLayout = record
    NodeIndex: Integer;
    CentreId: Integer;
    LaneIndex: Integer;
    Rect: TRectF;
  end;


function DayStart(const D: TDateTime): TDateTime;
function DayEnd(const D: TDateTime): TDateTime;



const
  {
  GanttColorPalette: array[0..63] of TColor = (
    $00F2F2FF, $00FFEFD5, $00E6E6FA, $00FFF0F5, $00F0FFF0, $00F5FFFA, $00F0FFFF, $00FFFACD,
    $00E0FFFF, $00FFF5EE, $00F8F8FF, $00FAFAD2, $00F5F5DC, $00F0F8FF, $00FFF8DC, $00FFE4E1,
    $00FFDAB9, $00EEDD82, $00D8BFD8, $00E6E6FA, $00B0E0E6, $00AFEEEE, $0098FB98, $00FFB6C1,
    $00FFA07A, $00F08080, $00ADD8E6, $0087CEFA, $00B0C4DE, $00DDA0DD, $00EE82EE, $00FFDEAD,
    $00FFE4B5, $00FFFACD, $00E0EEE0, $00F5DEB3, $00FFEBCD, $00FFD1DC, $00E0BBE4, $00C1E1C1,
    $00FFDFD3, $00D4F1F4, $00FFF5BA, $00E2F0CB, $00F8E8EE, $00D0F0C0, $00FDE2E4, $00CDE7BE,
    $00E4F9F5, $00FADADD, $00F6DFEB, $00E3F6F5, $00FFF1E6, $00E8F0FE, $00EAF4FC, $00FFF9C4,
    $00F1F8E9, $00E8EAF6, $00FCE4EC, $00F3E5F5, $00E1F5FE, $00F9FBE7, $00FFF3E0, $00E0F7FA
  );
  }
GanttColorPalette: array[0..63] of TColor = (
    $00D9D9FF, $00FFD9B3, $00D4D4F7, $00FFDCE6, $00D9F7D9, $00D9FFF0, $00D9FFFF, $00FFE4A3,
    $00C2FFFF, $00FFE0CC, $00E6E6FF, $00F2F2A8, $00E6E6C2, $00D6EBFF, $00FFE0B8, $00FFC2C2,
    $00FFC299, $00E6CC66, $00CC99CC, $00D4D4F7, $0099D9E6, $0099E6E6, $007FD97F, $00FF99B3,
    $00FF8C66, $00E67373, $008CC6E6, $006FB7F2, $0099B3D9, $00CC85CC, $00D966D9, $00FFC299,
    $00FFD699, $00FFE4A3, $00C2E0C2, $00E6C28F, $00FFD9B3, $00FFB3C6, $00CC99E6, $00A8D5A8,
    $00FFC2B3, $00B8E6E6, $00FFE066, $00C2E6A3, $00F2CCE0, $00B3D9B3, $00FFCCD5, $00A8D5A8,
    $00B3F0E6, $00F2B6C6, $00E6B3D9, $00B3E6E6, $00FFD9C2, $00C2D9FF, $00C2E0F2, $00FFE066,
    $00D9F2C2, $00C2C6F2, $00FFCCE6, $00E0B3F2, $00B3E0FF, $00E6F2C2, $00FFD9B3, $00B3F0F2
  );

implementation

function DayStart(const D: TDateTime): TDateTime;
begin
  Result := DateOf(D); // 00:00:00.000
end;
function DayEnd(const D: TDateTime): TDateTime;
begin
  // 23:59:59.999
  Result := DateOf(D) + EncodeTime(23,59,59,999);
end;



end.

