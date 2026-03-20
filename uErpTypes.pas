unit uErpTypes;

interface

uses
  System.SysUtils, System.DateUtils,
  Winapi.Windows, Winapi.Messages,
  System.Classes, System.Types, uCentreCalendar, uGAnttTypes,
  Vcl.Graphics;

type
  TGetCalendarFunc = reference to function(const CentreId: Integer): TCentreCalendar;

  //TLinkType = (ltFinishToStart);
  TLinkType = (
  ltFinishStart,
  ltStartStart,
  ltFinishFinish,
  ltStartFinish
);

  TErpOp = record
    OpId: Integer;

    Operacion: string;
    CentresTrabajo: TArray<string>;  // centres ERP permesos; buit = tots els centres
    CodigoCliente: string;
    CodigoColor: string;
    CodigoTalla: string;

    StartTime: TDateTime;
    EndTime: TDateTime;

    NumeroOF: Integer;
    SerieOF: string;

    NumeroOT: Integer;

    NumeroTrabajo: String;

    NumeroPedido: Integer;
    SeriePedido: string;
    FechaEntrega: TDateTime;
    FechaNecesaria: TDateTime;
    Stock: Double;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    PorcentajeDependencia: Double;

    UnidadesFabricadas: Double;
    UnidadesAFabricar: Double;
    TiempoUnidadFabSecs: Double; //...tiempo en segundos para fabricar una unidad
    DurationMin: Double; //...Segundos;
    DurationMinOriginal: Double; //...Segundos;
    OperariosNecesarios: Integer;
    OperariosAsignados: Integer;
    Estado: TEstadoOF;
    Prioridad: Integer;  // 1 = alta, 2 = mitja, 3 = baixa (exemple)

    bkColorOp: TColor;
    borderColorOp: TColor;
  end;

  TErpLink = record
    FromNodeId: Integer;
    ToNodeId: Integer;
    LinkType: TLinkType;
    PorcentajeDependencia: Double; // 0..100
  end;

  TErpRaw = record
    Ops: TArray<TErpOp>;
    Links: TArray<TErpLink>;
  end;

implementation

end.
