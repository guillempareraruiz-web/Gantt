unit uErpTypes;

interface

uses
  System.SysUtils, System.DateUtils,
  Winapi.Windows, Winapi.Messages,
  System.Classes, System.Types, uCentreCalendar, uGAnttTypes,
  Vcl.Graphics;

type
  TErpSistema = (
    esSage200,
    esSageX3,
    esDynamics365BC,
    esOdoo,
    esSAPB1,
    esCegidEkon,
    esInforCS
  );

  TErpSistemaInfo = record
    Sistema: TErpSistema;
    Codigo: string;        // clave persistencia ("Sage200", "SageX3", ...)
    Nombre: string;        // nombre mostrado UI
    Iniciales: string;     // 2 letras para logo placeholder
    Descripcion: string;   // descripción corta
    Disponible: Boolean;   // false = "Próximamente"
  end;

const
  ERP_SISTEMAS: array[TErpSistema] of TErpSistemaInfo = (
    (Sistema: esSage200;        Codigo: 'Sage200';        Nombre: 'Sage 200';                                Iniciales: 'S2'; Descripcion: 'ERP Sage 200 (Espa'#241'a)';                       Disponible: True),
    (Sistema: esSageX3;         Codigo: 'SageX3';         Nombre: 'Sage X3';                                 Iniciales: 'SX'; Descripcion: 'ERP Sage X3';                                    Disponible: False),
    (Sistema: esDynamics365BC;  Codigo: 'Dynamics365BC';  Nombre: 'Microsoft Dynamics 365 Business Central'; Iniciales: 'BC'; Descripcion: 'ERP Microsoft Dynamics 365 Business Central';    Disponible: False),
    (Sistema: esOdoo;           Codigo: 'Odoo';           Nombre: 'Odoo';                                    Iniciales: 'OD'; Descripcion: 'ERP Odoo';                                       Disponible: False),
    (Sistema: esSAPB1;          Codigo: 'SAPB1';          Nombre: 'SAP Business One';                        Iniciales: 'SP'; Descripcion: 'ERP SAP Business One';                           Disponible: False),
    (Sistema: esCegidEkon;      Codigo: 'CegidEkon';      Nombre: 'Cegid XRP Enterprise / Ekon';             Iniciales: 'CE'; Descripcion: 'ERP Cegid XRP Enterprise (Ekon)';                Disponible: False),
    (Sistema: esInforCS;        Codigo: 'InforCS';        Nombre: 'Infor CloudSuite';                        Iniciales: 'IF'; Descripcion: 'ERP Infor CloudSuite';                           Disponible: False)
  );

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
    CodigoColor: string;
    CodigoTalla: string;

    StartTime: TDateTime;
    EndTime: TDateTime;

    NumeroOF: Integer;
    SerieOF: string;

    CodigoProyecto: String;

    NumeroOT: Integer;
    NumeroTrabajo: String;

    EjercicioPedido: SmallInt;
    NumeroPedido: Integer;
    SeriePedido: string;

    CodigoCliente: string;

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
    Estado: TNodoEstado;
    Tipo: TNodoTipo;

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
