unit uPesosScoringRepo;

{
  Helpers de persistencia para TPesosPlanificacion.

  Politica simple: existe siempre un perfil con EsActivo=1 (creado por la
  semilla del V020). Las funciones LoadActivo y SaveActivo trabajan sobre
  ese perfil.

  Si en el futuro hay multiples perfiles, ampliar con un nombre.
}

interface

uses
  System.SysUtils, System.Variants, Data.Win.ADODB,
  uPlanProdTypes;

function LoadPesosActivo(AConn: TADOConnection; ACodigoEmpresa: SmallInt;
  out APesos: TPesosPlanificacion): Boolean;

function SavePesosActivo(AConn: TADOConnection; ACodigoEmpresa: SmallInt;
  const APesos: TPesosPlanificacion): Boolean;

implementation

function HasDB(AConn: TADOConnection): Boolean;
begin
  Result := Assigned(AConn) and AConn.Connected;
end;

function FStr(D: Double): string;
begin
  Result := FloatToStr(D, TFormatSettings.Invariant);
end;

function LoadPesosActivo(AConn: TADOConnection; ACodigoEmpresa: SmallInt;
  out APesos: TPesosPlanificacion): Boolean;
var
  Q: TADOQuery;
begin
  Result := False;
  APesos := TPesosPlanificacion.Default;
  if not HasDB(AConn) then Exit;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT TOP 1 ' +
      '  PesoPrioridadOrden, PesoCompromiso, PesoNivelCompetencia, ' +
      '  PesoCargaOperario, PesoContinuidad, PesoEspera, PesoCosteManoObra ' +
      'FROM FS_PL_PesosScoring ' +
      'WHERE CodigoEmpresa = ' + IntToStr(ACodigoEmpresa) +
      '  AND EsActivo = 1 ' +
      'ORDER BY PerfilId';
    try
      Q.Open;
      if not Q.Eof then
      begin
        APesos.PesoPrioridadOrden := Q.FieldByName('PesoPrioridadOrden').AsFloat;
        APesos.PesoCompromiso := Q.FieldByName('PesoCompromiso').AsFloat;
        APesos.PesoNivelCompetencia := Q.FieldByName('PesoNivelCompetencia').AsFloat;
        APesos.PesoCargaOperario := Q.FieldByName('PesoCargaOperario').AsFloat;
        APesos.PesoContinuidad := Q.FieldByName('PesoContinuidad').AsFloat;
        APesos.PesoEspera := Q.FieldByName('PesoEspera').AsFloat;
        APesos.PesoCosteManoObra := Q.FieldByName('PesoCosteManoObra').AsFloat;
        Result := True;
      end;
    except
      // Tabla no existe (V020 sin aplicar) o error: usa default
    end;
  finally
    Q.Free;
  end;
end;

function SavePesosActivo(AConn: TADOConnection; ACodigoEmpresa: SmallInt;
  const APesos: TPesosPlanificacion): Boolean;
var
  Cmd: TADOCommand;
  Affected: Integer;
begin
  Result := False;
  if not HasDB(AConn) then Exit;
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := AConn;
    Cmd.CommandText := Format(
      'IF EXISTS (SELECT 1 FROM FS_PL_PesosScoring WHERE CodigoEmpresa = %d AND EsActivo = 1) ' +
      '  UPDATE FS_PL_PesosScoring SET ' +
      '    PesoPrioridadOrden = %s, PesoCompromiso = %s, PesoNivelCompetencia = %s, ' +
      '    PesoCargaOperario = %s, PesoContinuidad = %s, PesoEspera = %s, PesoCosteManoObra = %s ' +
      '  WHERE CodigoEmpresa = %d AND EsActivo = 1 ' +
      'ELSE ' +
      '  INSERT INTO FS_PL_PesosScoring (CodigoEmpresa, Nombre, EsActivo, ' +
      '    PesoPrioridadOrden, PesoCompromiso, PesoNivelCompetencia, ' +
      '    PesoCargaOperario, PesoContinuidad, PesoEspera, PesoCosteManoObra) ' +
      '  VALUES (%d, ''Default'', 1, %s, %s, %s, %s, %s, %s, %s)',
      [ACodigoEmpresa,
       FStr(APesos.PesoPrioridadOrden), FStr(APesos.PesoCompromiso),
       FStr(APesos.PesoNivelCompetencia), FStr(APesos.PesoCargaOperario),
       FStr(APesos.PesoContinuidad), FStr(APesos.PesoEspera),
       FStr(APesos.PesoCosteManoObra),
       ACodigoEmpresa,
       ACodigoEmpresa,
       FStr(APesos.PesoPrioridadOrden), FStr(APesos.PesoCompromiso),
       FStr(APesos.PesoNivelCompetencia), FStr(APesos.PesoCargaOperario),
       FStr(APesos.PesoContinuidad), FStr(APesos.PesoEspera),
       FStr(APesos.PesoCosteManoObra)]);
    try
      Cmd.Execute(Affected, EmptyParam);
      Result := True;
    except
      // ignore
    end;
  finally
    Cmd.Free;
  end;
end;

end.
