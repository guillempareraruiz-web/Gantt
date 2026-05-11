unit uOperariosTypes;

interface

uses
  Vcl.Graphics;

type
  TOperario = record
    Id: Integer;
    Nombre: string;
    Calendario: string;
    // Coste laboral (para motor de planificacion automatica con scoring)
    SueldoEurHora: Double;       // sueldo base por hora; 0 = no definido
    RecargoTurnoNoche: Double;   // multiplicador, ej 1.25 = +25%; 0/1 = sin recargo
    RecargoFestivo: Double;      // multiplicador, ej 1.75; 0/1 = sin recargo
  end;

  TDepartamento = record
    Id: Integer;
    Nombre: string;
    Descripcion: string;
  end;

  TOperarioDepartamento = record
    OperarioId: Integer;
    DepartamentoId: Integer;
  end;

  // Nivel de capacitacion (v1: solo visual; v1.1 aplicara FactorEficiencia)
  TNivelSkill = (nsAprendiz, nsJunior, nsSenior, nsExperto);

  TCapacitacion = record
    OperarioId: Integer;
    Operacion: string;
    Nivel: TNivelSkill;
    FactorEficiencia: Double;  // 1.0 default; <1 mas rapido; >1 mas lento
  end;

  TAsignacionOperario = record
    OperarioId: Integer;
    DataId: Integer;
    Horas: Double;
    IsLocked: Boolean;
    LockedBy: string;
    LockedAt: TDateTime;
  end;

  // Ausencias
  TTipoAusencia = (taVacaciones, taBaja, taFormacion, taPermiso, taOtros);

  TAusencia = record
    Id: Integer;
    OperarioId: Integer;
    FechaInicio: TDateTime;
    FechaFin: TDateTime;
    Tipo: TTipoAusencia;
    Descripcion: string;
    EsHoraria: Boolean;  // false = d'ia(s) completo(s); true = tramo horario en un solo d'ia
  end;

  // Tipo de operacion: paralelismo (modelo PRO C)
  TTipoOperacion = record
    Operacion: string;
    MaxOperariosParalelos: Integer;  // 1 = no paralelizable
    FactorParalelismo: Double;       // 0..1
    Descripcion: string;
  end;

// Helpers de conversion
function NivelSkillToStr(N: TNivelSkill): string;
function NivelSkillToTinyInt(N: TNivelSkill): Byte;
function TinyIntToNivelSkill(V: Byte): TNivelSkill;
function TipoAusenciaToStr(T: TTipoAusencia): string;
function TipoAusenciaToTinyInt(T: TTipoAusencia): Byte;
function TinyIntToTipoAusencia(V: Byte): TTipoAusencia;
function TipoAusenciaColor(T: TTipoAusencia): TColor;

implementation

function NivelSkillToStr(N: TNivelSkill): string;
begin
  case N of
    nsAprendiz: Result := 'Aprendiz';
    nsJunior:   Result := 'Junior';
    nsSenior:   Result := 'Senior';
    nsExperto:  Result := 'Experto';
  else
    Result := '';
  end;
end;

function NivelSkillToTinyInt(N: TNivelSkill): Byte;
begin
  Result := Byte(N);
end;

function TinyIntToNivelSkill(V: Byte): TNivelSkill;
begin
  if V > Byte(nsExperto) then
    Result := nsSenior
  else
    Result := TNivelSkill(V);
end;

function TipoAusenciaToStr(T: TTipoAusencia): string;
begin
  case T of
    taVacaciones: Result := 'Vacaciones';
    taBaja:       Result := 'Baja';
    taFormacion:  Result := 'Formaci'#243'n';
    taPermiso:    Result := 'Permiso';
    taOtros:      Result := 'Otros';
  else
    Result := '';
  end;
end;

function TipoAusenciaToTinyInt(T: TTipoAusencia): Byte;
begin
  Result := Byte(T);
end;

function TinyIntToTipoAusencia(V: Byte): TTipoAusencia;
begin
  if V > Byte(taOtros) then
    Result := taOtros
  else
    Result := TTipoAusencia(V);
end;

function TipoAusenciaColor(T: TTipoAusencia): TColor;
begin
  case T of
    taVacaciones: Result := $00C0C0C0;
    taBaja:       Result := $008080E0;
    taFormacion:  Result := $00C0A040;
    taPermiso:    Result := $00B0B0B0;
  else            Result := $00A0A0A0;
  end;
end;

end.
