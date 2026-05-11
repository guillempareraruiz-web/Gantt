unit uPlanProdTypes;

{
  Tipos para el motor de planificacion automatica (scoring).

  Adaptado del prototipo FS_PlanProd al modelo del GANTT:
  - Habilidades como catalogo independiente.
  - Operario tiene N habilidades (cada una con nivel 0-3).
  - Operacion-maestro exige N habilidades (cada una con nivel minimo).
  - Sueldo y recargos por operario.
  - Pesos de scoring configurables (7 pesos).
  - Resultado de planificacion como TPlanProdAsignacion (lleva NodeId,
    OperarioId, Score y CosteEstimado).
}

interface

uses
  System.SysUtils, System.Classes,
  uOperariosTypes;  // reutiliza TNivelSkill (0=Aprendiz..3=Experto)

type
  // ============================================================
  // CATALOGO HABILIDADES
  // ============================================================

  THabilidad = record
    Codigo: string;       // ej. 'MEZCLA', 'QC_LIQUIDOS', 'SOLDAR_TIG'
    Descripcion: string;
  end;

  // Habilidad asignada a un operario con su nivel
  TOperarioHabilidad = record
    OperarioId: Integer;
    CodHabilidad: string;
    Nivel: TNivelSkill;       // 0=Aprendiz..3=Experto (reutiliza enum existente)
    FactorEficiencia: Double; // 1.0 default; <1 mas rapido; >1 mas lento
  end;

  // Habilidad requerida por una operacion-maestro
  TOperacionHabilidad = record
    Operacion: string;        // codigo de operacion (FK a FS_PL_OperationType)
    CodHabilidad: string;
    NivelMinimo: TNivelSkill;
  end;

  // ============================================================
  // PESOS DE SCORING
  // ============================================================

  TPesosPlanificacion = record
    PesoPrioridadOrden: Double;
    PesoCompromiso: Double;
    PesoNivelCompetencia: Double;
    PesoCargaOperario: Double;
    PesoContinuidad: Double;
    PesoEspera: Double;
    PesoCosteManoObra: Double;
    class function Default: TPesosPlanificacion; static;
  end;

  // ============================================================
  // RESULTADO ASIGNACION
  // ============================================================

  TPlanProdAsignacion = record
    OperarioId: Integer;
    NodeDataId: Integer;
    CodigoCentro: string;
    Operacion: string;
    HoraInicioPrevista: TDateTime;
    HoraFinPrevista: TDateTime;
    Score: Double;
    CosteEstimado: Double;     // euros
    Elegible: Boolean;
    MotivoNoElegible: string;
    class function Vacio: TPlanProdAsignacion; static;
  end;

  // Helper para resultados batch
  TPlanProdResultado = record
    Asignaciones: TArray<TPlanProdAsignacion>;
    NodosNoAsignados: TArray<Integer>;  // DataIds que han quedado sin operario
    CosteTotal: Double;
    ScoreTotal: Double;
  end;

  // Desglose del score para una asignacion (para UI de justificacion).
  // Cada campo es la APORTACION en puntos al score total (positivo o
  // negativo). Total = suma.
  TScoreBreakdown = record
    OperarioId: Integer;
    OperarioNombre: string;
    NodeDataId: Integer;
    Operacion: string;
    AportPrioridad: Double;
    AportCompromiso: Double;
    AportNivelCompetencia: Double;
    AportCarga: Double;            // suele ser negativo (resta)
    AportContinuidad: Double;
    AportEspera: Double;
    AportCoste: Double;            // suele ser negativo (resta)
    Total: Double;
    // Datos auxiliares para mostrar al usuario:
    PrioridadNode: Integer;
    DiasACompromiso: Double;
    Sobrenivel: Integer;
    CargaActualOp: Double;
    HasContinuidadOF: Boolean;
    DiasEspera: Double;
    CosteEurHora: Double;
  end;

implementation

{ TPesosPlanificacion }

class function TPesosPlanificacion.Default: TPesosPlanificacion;
begin
  Result.PesoPrioridadOrden := 10.0;
  Result.PesoCompromiso := 8.0;
  Result.PesoNivelCompetencia := 3.0;
  Result.PesoCargaOperario := 0.5;
  Result.PesoContinuidad := 4.0;
  Result.PesoEspera := 0.05;
  Result.PesoCosteManoObra := 2.0;
end;

{ TPlanProdAsignacion }

class function TPlanProdAsignacion.Vacio: TPlanProdAsignacion;
begin
  Result.OperarioId := 0;
  Result.NodeDataId := 0;
  Result.CodigoCentro := '';
  Result.Operacion := '';
  Result.HoraInicioPrevista := 0;
  Result.HoraFinPrevista := 0;
  Result.Score := 0;
  Result.CosteEstimado := 0;
  Result.Elegible := False;
  Result.MotivoNoElegible := '';
end;

end.
