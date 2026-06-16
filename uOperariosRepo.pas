unit uOperariosRepo;

interface

uses
  System.SysUtils, System.Generics.Collections, uOperariosTypes;

type
  // Callbacks per a persistencia. El repo nomes guarda en memoria; quan
  // canvia una asignacio, dispara el callback corresponent perque el codi
  // cridador (Main) escrigui a FS_PL_OperatorAssignment.
  TAsignacionPersistEvent = procedure(const A: TAsignacionOperario) of object;
  TAsignacionRemovePersistEvent = procedure(OperarioId, DataId: Integer) of object;
  TAsignacionNodeClearPersistEvent = procedure(DataId: Integer) of object;

  TOperariosRepo = class
  private
    FOperarios: TList<TOperario>;
    FDepartamentos: TList<TDepartamento>;
    FOperarioDepts: TList<TOperarioDepartamento>;
    FCapacitacions: TList<TCapacitacion>;
    FAsignacions: TList<TAsignacionOperario>;
    FNextOperarioId: Integer;
    FNextDeptId: Integer;
    FBulkLoadMode: Boolean;
    FOnAsignacionAdded: TAsignacionPersistEvent;
    FOnAsignacionUpdated: TAsignacionPersistEvent;
    FOnAsignacionRemoved: TAsignacionRemovePersistEvent;
    FOnAsignacionsNodeCleared: TAsignacionNodeClearPersistEvent;
  public
    constructor Create;
    destructor Destroy; override;

    // True durant la carrega inicial des de SQL: cap callback de persist
    // s'ha de disparar (evitem inserts en bucle).
    property BulkLoadMode: Boolean read FBulkLoadMode write FBulkLoadMode;
    property OnAsignacionAdded: TAsignacionPersistEvent
      read FOnAsignacionAdded write FOnAsignacionAdded;
    property OnAsignacionUpdated: TAsignacionPersistEvent
      read FOnAsignacionUpdated write FOnAsignacionUpdated;
    property OnAsignacionRemoved: TAsignacionRemovePersistEvent
      read FOnAsignacionRemoved write FOnAsignacionRemoved;
    property OnAsignacionsNodeCleared: TAsignacionNodeClearPersistEvent
      read FOnAsignacionsNodeCleared write FOnAsignacionsNodeCleared;

    // --- Operaris ---
    procedure AddOperario(const A: TOperario);
    procedure UpdateOperario(const A: TOperario);
    procedure RemoveOperario(Id: Integer);
    function GetOperarios: TArray<TOperario>;
    function GetOperarioById(Id: Integer; out Op: TOperario): Boolean;
    function NextOperarioId: Integer;

    // --- Departaments ---
    function AddDepartamento(const A: TDepartamento): Integer;
    procedure UpdateDepartamento(const A: TDepartamento);
    procedure RemoveDepartamento(Id: Integer);
    function GetDepartamentos: TArray<TDepartamento>;
    function GetDepartamentoById(Id: Integer; out D: TDepartamento): Boolean;
    function NextDeptId: Integer;

    // --- Relació Operari-Departament ---
    procedure AssignOperariToDept(OperarioId, DeptId: Integer);
    procedure UnassignOperariFromDept(OperarioId, DeptId: Integer);
    function GetDeptsByOperario(OperarioId: Integer): TArray<TDepartamento>;
    function GetOperarisByDept(DeptId: Integer): TArray<TOperario>;
    function IsOperariInDept(OperarioId, DeptId: Integer): Boolean;

    // --- Capacitacions ---
    procedure AddCapacitacion(const A: TCapacitacion);
    procedure RemoveCapacitacion(OperarioId: Integer; const Operacion: string);
    procedure ClearCapacitacionsByOperario(OperarioId: Integer);
    function GetCapacitacionsByOperario(OperarioId: Integer): TArray<string>;
    function OperarioPotFerOperacio(OperarioId: Integer; const Operacion: string): Boolean;
    function GetAllOperacions: TArray<string>;

    // --- Assignacions ---
    procedure AddAsignacion(const A: TAsignacionOperario);
    procedure RemoveAsignacion(OperarioId, DataId: Integer);
    procedure UpdateAsignacionHoras(OperarioId, DataId: Integer; Horas: Double);
    function GetAsignacionsByNode(DataId: Integer): TArray<TAsignacionOperario>;
    function GetAsignacionsByOperario(OperarioId: Integer): TArray<TAsignacionOperario>;
    function GetAllAsignacions: TArray<TAsignacionOperario>;
    procedure ClearAsignacionsByNode(DataId: Integer);

    // --- Consultes ---
    function GetOperarisDisponiblesPerNode(DataId: Integer; const Operacion: string): TArray<TOperario>;
    function GetOperarisAssignatsAlNode(DataId: Integer): TArray<TOperario>;
    function GetHoresOperariEnNode(OperarioId, DataId: Integer): Double;
    function CountAssignatsAlNode(DataId: Integer): Integer;

    // --- Lock de asignaciones ---
    procedure SetAsignacionLock(OperarioId, DataId: Integer;
      const ALocked: Boolean; const ALockedBy: string = '');
    function IsAsignacionLocked(OperarioId, DataId: Integer): Boolean;
    function GetCapacitacioInfo(OperarioId: Integer; const Operacion: string;
      out Cap: TCapacitacion): Boolean;

    // --- Dades de mostra ---
    procedure LoadSampleData;
  end;

implementation

constructor TOperariosRepo.Create;
begin
  inherited;
  FOperarios := TList<TOperario>.Create;
  FDepartamentos := TList<TDepartamento>.Create;
  FOperarioDepts := TList<TOperarioDepartamento>.Create;
  FCapacitacions := TList<TCapacitacion>.Create;
  FAsignacions := TList<TAsignacionOperario>.Create;
  FNextOperarioId := 1;
  FNextDeptId := 1;
  FBulkLoadMode := False;
end;

destructor TOperariosRepo.Destroy;
begin
  FAsignacions.Free;
  FCapacitacions.Free;
  FOperarioDepts.Free;
  FDepartamentos.Free;
  FOperarios.Free;
  inherited;
end;

{ --- Operaris --- }

procedure TOperariosRepo.AddOperario(const A: TOperario);
begin
  FOperarios.Add(A);
  if A.Id >= FNextOperarioId then
    FNextOperarioId := A.Id + 1;
end;

procedure TOperariosRepo.UpdateOperario(const A: TOperario);
var
  I: Integer;
begin
  for I := 0 to FOperarios.Count - 1 do
    if FOperarios[I].Id = A.Id then
    begin
      FOperarios[I] := A;
      Exit;
    end;
end;

procedure TOperariosRepo.RemoveOperario(Id: Integer);
var
  I: Integer;
begin
  for I := FOperarios.Count - 1 downto 0 do
    if FOperarios[I].Id = Id then
    begin
      FOperarios.Delete(I);
      Break;
    end;
  // Netejar relacions
  for I := FOperarioDepts.Count - 1 downto 0 do
    if FOperarioDepts[I].OperarioId = Id then
      FOperarioDepts.Delete(I);
  ClearCapacitacionsByOperario(Id);
  for I := FAsignacions.Count - 1 downto 0 do
    if FAsignacions[I].OperarioId = Id then
      FAsignacions.Delete(I);
end;

function TOperariosRepo.GetOperarios: TArray<TOperario>;
begin
  Result := FOperarios.ToArray;
end;

function TOperariosRepo.GetOperarioById(Id: Integer; out Op: TOperario): Boolean;
var
  I: Integer;
begin
  for I := 0 to FOperarios.Count - 1 do
    if FOperarios[I].Id = Id then
    begin
      Op := FOperarios[I];
      Exit(True);
    end;
  Result := False;
end;

function TOperariosRepo.NextOperarioId: Integer;
begin
  Result := FNextOperarioId;
  Inc(FNextOperarioId);
end;

{ --- Departaments --- }

function TOperariosRepo.AddDepartamento(const A: TDepartamento): Integer;
var
  D: TDepartamento;
begin
  D := A;
  if D.Id = 0 then
    D.Id := NextDeptId;
  FDepartamentos.Add(D);
  if D.Id >= FNextDeptId then
    FNextDeptId := D.Id + 1;
  Result := D.Id;
end;

procedure TOperariosRepo.UpdateDepartamento(const A: TDepartamento);
var
  I: Integer;
begin
  for I := 0 to FDepartamentos.Count - 1 do
    if FDepartamentos[I].Id = A.Id then
    begin
      FDepartamentos[I] := A;
      Exit;
    end;
end;

procedure TOperariosRepo.RemoveDepartamento(Id: Integer);
var
  I: Integer;
begin
  for I := FDepartamentos.Count - 1 downto 0 do
    if FDepartamentos[I].Id = Id then
    begin
      FDepartamentos.Delete(I);
      Break;
    end;
  // Netejar relacions operari-dept
  for I := FOperarioDepts.Count - 1 downto 0 do
    if FOperarioDepts[I].DepartamentoId = Id then
      FOperarioDepts.Delete(I);
end;

function TOperariosRepo.GetDepartamentos: TArray<TDepartamento>;
begin
  Result := FDepartamentos.ToArray;
end;

function TOperariosRepo.GetDepartamentoById(Id: Integer; out D: TDepartamento): Boolean;
var
  I: Integer;
begin
  for I := 0 to FDepartamentos.Count - 1 do
    if FDepartamentos[I].Id = Id then
    begin
      D := FDepartamentos[I];
      Exit(True);
    end;
  Result := False;
end;

function TOperariosRepo.NextDeptId: Integer;
begin
  Result := FNextDeptId;
  Inc(FNextDeptId);
end;

{ --- Relació Operari-Departament --- }

procedure TOperariosRepo.AssignOperariToDept(OperarioId, DeptId: Integer);
var
  R: TOperarioDepartamento;
begin
  if IsOperariInDept(OperarioId, DeptId) then Exit;
  R.OperarioId := OperarioId;
  R.DepartamentoId := DeptId;
  FOperarioDepts.Add(R);
end;

procedure TOperariosRepo.UnassignOperariFromDept(OperarioId, DeptId: Integer);
var
  I: Integer;
begin
  for I := FOperarioDepts.Count - 1 downto 0 do
    if (FOperarioDepts[I].OperarioId = OperarioId) and
       (FOperarioDepts[I].DepartamentoId = DeptId) then
    begin
      FOperarioDepts.Delete(I);
      Exit;
    end;
end;

function TOperariosRepo.GetDeptsByOperario(OperarioId: Integer): TArray<TDepartamento>;
var
  I: Integer;
  List: TList<TDepartamento>;
  D: TDepartamento;
begin
  List := TList<TDepartamento>.Create;
  try
    for I := 0 to FOperarioDepts.Count - 1 do
      if FOperarioDepts[I].OperarioId = OperarioId then
        if GetDepartamentoById(FOperarioDepts[I].DepartamentoId, D) then
          List.Add(D);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TOperariosRepo.GetOperarisByDept(DeptId: Integer): TArray<TOperario>;
var
  I: Integer;
  List: TList<TOperario>;
  Op: TOperario;
begin
  List := TList<TOperario>.Create;
  try
    for I := 0 to FOperarioDepts.Count - 1 do
      if FOperarioDepts[I].DepartamentoId = DeptId then
        if GetOperarioById(FOperarioDepts[I].OperarioId, Op) then
          List.Add(Op);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TOperariosRepo.IsOperariInDept(OperarioId, DeptId: Integer): Boolean;
var
  I: Integer;
begin
  for I := 0 to FOperarioDepts.Count - 1 do
    if (FOperarioDepts[I].OperarioId = OperarioId) and
       (FOperarioDepts[I].DepartamentoId = DeptId) then
      Exit(True);
  Result := False;
end;

{ --- Capacitacions --- }

procedure TOperariosRepo.AddCapacitacion(const A: TCapacitacion);
begin
  if not OperarioPotFerOperacio(A.OperarioId, A.Operacion) then
    FCapacitacions.Add(A);
end;

procedure TOperariosRepo.RemoveCapacitacion(OperarioId: Integer; const Operacion: string);
var
  I: Integer;
begin
  for I := FCapacitacions.Count - 1 downto 0 do
    if (FCapacitacions[I].OperarioId = OperarioId) and
       SameText(FCapacitacions[I].Operacion, Operacion) then
    begin
      FCapacitacions.Delete(I);
      Exit;
    end;
end;

procedure TOperariosRepo.ClearCapacitacionsByOperario(OperarioId: Integer);
var
  I: Integer;
begin
  for I := FCapacitacions.Count - 1 downto 0 do
    if FCapacitacions[I].OperarioId = OperarioId then
      FCapacitacions.Delete(I);
end;

function TOperariosRepo.GetAllOperacions: TArray<string>;
var
  I: Integer;
  Set_: TDictionary<string, Boolean>;
  List: TList<string>;
begin
  Set_ := TDictionary<string, Boolean>.Create;
  List := TList<string>.Create;
  try
    for I := 0 to FCapacitacions.Count - 1 do
      if not Set_.ContainsKey(UpperCase(FCapacitacions[I].Operacion)) then
      begin
        Set_.Add(UpperCase(FCapacitacions[I].Operacion), True);
        List.Add(FCapacitacions[I].Operacion);
      end;
    List.Sort;
    Result := List.ToArray;
  finally
    List.Free;
    Set_.Free;
  end;
end;

function TOperariosRepo.GetCapacitacionsByOperario(OperarioId: Integer): TArray<string>;
var
  I: Integer;
  List: TList<string>;
begin
  List := TList<string>.Create;
  try
    for I := 0 to FCapacitacions.Count - 1 do
      if FCapacitacions[I].OperarioId = OperarioId then
        List.Add(FCapacitacions[I].Operacion);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TOperariosRepo.OperarioPotFerOperacio(OperarioId: Integer; const Operacion: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to FCapacitacions.Count - 1 do
    if (FCapacitacions[I].OperarioId = OperarioId) and
       SameText(FCapacitacions[I].Operacion, Operacion) then
      Exit(True);
  Result := False;
end;

{ --- Assignacions --- }

procedure TOperariosRepo.AddAsignacion(const A: TAsignacionOperario);
begin
  FAsignacions.Add(A);
  if (not FBulkLoadMode) and Assigned(FOnAsignacionAdded) then
    FOnAsignacionAdded(A);
end;

procedure TOperariosRepo.RemoveAsignacion(OperarioId, DataId: Integer);
var
  I: Integer;
begin
  for I := FAsignacions.Count - 1 downto 0 do
    if (FAsignacions[I].OperarioId = OperarioId) and
       (FAsignacions[I].DataId = DataId) then
    begin
      FAsignacions.Delete(I);
      if (not FBulkLoadMode) and Assigned(FOnAsignacionRemoved) then
        FOnAsignacionRemoved(OperarioId, DataId);
      Exit;
    end;
end;

procedure TOperariosRepo.UpdateAsignacionHoras(OperarioId, DataId: Integer; Horas: Double);
var
  I: Integer;
  A: TAsignacionOperario;
begin
  for I := 0 to FAsignacions.Count - 1 do
    if (FAsignacions[I].OperarioId = OperarioId) and
       (FAsignacions[I].DataId = DataId) then
    begin
      A := FAsignacions[I];
      A.Horas := Horas;
      FAsignacions[I] := A;
      if (not FBulkLoadMode) and Assigned(FOnAsignacionUpdated) then
        FOnAsignacionUpdated(A);
      Exit;
    end;
end;

function TOperariosRepo.GetAsignacionsByNode(DataId: Integer): TArray<TAsignacionOperario>;
var
  I: Integer;
  List: TList<TAsignacionOperario>;
begin
  List := TList<TAsignacionOperario>.Create;
  try
    for I := 0 to FAsignacions.Count - 1 do
      if FAsignacions[I].DataId = DataId then
        List.Add(FAsignacions[I]);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TOperariosRepo.GetAllAsignacions: TArray<TAsignacionOperario>;
begin
  Result := FAsignacions.ToArray;
end;

function TOperariosRepo.GetAsignacionsByOperario(OperarioId: Integer): TArray<TAsignacionOperario>;
var
  I: Integer;
  List: TList<TAsignacionOperario>;
begin
  List := TList<TAsignacionOperario>.Create;
  try
    for I := 0 to FAsignacions.Count - 1 do
      if FAsignacions[I].OperarioId = OperarioId then
        List.Add(FAsignacions[I]);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

procedure TOperariosRepo.ClearAsignacionsByNode(DataId: Integer);
var
  I: Integer;
begin
  for I := FAsignacions.Count - 1 downto 0 do
    if FAsignacions[I].DataId = DataId then
      FAsignacions.Delete(I);
  if (not FBulkLoadMode) and Assigned(FOnAsignacionsNodeCleared) then
    FOnAsignacionsNodeCleared(DataId);
end;

{ --- Consultes --- }

function TOperariosRepo.GetOperarisDisponiblesPerNode(DataId: Integer; const Operacion: string): TArray<TOperario>;
var
  I: Integer;
  List: TList<TOperario>;
  Assigned: TDictionary<Integer, Boolean>;
  Asigs: TArray<TAsignacionOperario>;
begin
  List := TList<TOperario>.Create;
  Assigned := TDictionary<Integer, Boolean>.Create;
  try
    // Recollir qui ja està assignat a aquest node
    Asigs := GetAsignacionsByNode(DataId);
    for I := 0 to High(Asigs) do
      Assigned.AddOrSetValue(Asigs[I].OperarioId, True);

    // Filtrar: capacitat per l'operació i no assignat
    for I := 0 to FOperarios.Count - 1 do
      if not Assigned.ContainsKey(FOperarios[I].Id) and
         OperarioPotFerOperacio(FOperarios[I].Id, Operacion) then
        List.Add(FOperarios[I]);

    Result := List.ToArray;
  finally
    Assigned.Free;
    List.Free;
  end;
end;

function TOperariosRepo.GetOperarisAssignatsAlNode(DataId: Integer): TArray<TOperario>;
var
  I: Integer;
  List: TList<TOperario>;
  Asigs: TArray<TAsignacionOperario>;
  Op: TOperario;
begin
  List := TList<TOperario>.Create;
  try
    Asigs := GetAsignacionsByNode(DataId);
    for I := 0 to High(Asigs) do
      if GetOperarioById(Asigs[I].OperarioId, Op) then
        List.Add(Op);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TOperariosRepo.GetHoresOperariEnNode(OperarioId, DataId: Integer): Double;
var
  I: Integer;
begin
  for I := 0 to FAsignacions.Count - 1 do
    if (FAsignacions[I].OperarioId = OperarioId) and
       (FAsignacions[I].DataId = DataId) then
      Exit(FAsignacions[I].Horas);
  Result := 0;
end;

function TOperariosRepo.CountAssignatsAlNode(DataId: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FAsignacions.Count - 1 do
    if FAsignacions[I].DataId = DataId then
      Inc(Result);
end;

{ --- Lock de asignaciones --- }

procedure TOperariosRepo.SetAsignacionLock(OperarioId, DataId: Integer;
  const ALocked: Boolean; const ALockedBy: string);
var
  I: Integer;
  A: TAsignacionOperario;
begin
  for I := 0 to FAsignacions.Count - 1 do
    if (FAsignacions[I].OperarioId = OperarioId) and
       (FAsignacions[I].DataId = DataId) then
    begin
      A := FAsignacions[I];
      A.IsLocked := ALocked;
      if ALocked then
      begin
        A.LockedBy := ALockedBy;
        A.LockedAt := Now;
      end
      else
      begin
        A.LockedBy := '';
        A.LockedAt := 0;
      end;
      FAsignacions[I] := A;
      Exit;
    end;
end;

function TOperariosRepo.IsAsignacionLocked(OperarioId, DataId: Integer): Boolean;
var
  I: Integer;
begin
  for I := 0 to FAsignacions.Count - 1 do
    if (FAsignacions[I].OperarioId = OperarioId) and
       (FAsignacions[I].DataId = DataId) then
      Exit(FAsignacions[I].IsLocked);
  Result := False;
end;

function TOperariosRepo.GetCapacitacioInfo(OperarioId: Integer;
  const Operacion: string; out Cap: TCapacitacion): Boolean;
var
  I: Integer;
begin
  for I := 0 to FCapacitacions.Count - 1 do
    if (FCapacitacions[I].OperarioId = OperarioId) and
       SameText(FCapacitacions[I].Operacion, Operacion) then
    begin
      Cap := FCapacitacions[I];
      Exit(True);
    end;
  Result := False;
end;

{ --- Dades de mostra --- }

procedure TOperariosRepo.LoadSampleData;
var
  Op: TOperario;
  Cap: TCapacitacion;
  I, J, NCaps: Integer;
const
  // Noms (pool de 30 per cobrir fins a 50 amb sufixos)
  Cognoms: array[0..29] of string = (
    'Garcia', 'Lopez', 'Martinez', 'Ferrer', 'Puig', 'Roca',
    'Serra', 'Font', 'Vila', 'Soler', 'Mas', 'Torres',
    'Vidal', 'Costa', 'Pons', 'Marin', 'Ruiz', 'Navarro',
    'Gimenez', 'Romero', 'Diaz', 'Moreno', 'Alonso', 'Molina',
    'Rubio', 'Ortega', 'Delgado', 'Castro', 'Herrero', 'Campos'
  );
  Noms: array[0..9] of string = (
    'Joan', 'Maria', 'Pere', 'Anna', 'Marc',
    'Laura', 'David', 'Carla', 'Jordi', 'Marta'
  );
  // Operacions coherents amb OP_NAMES de uErpSampleBuilder
  Ops: array[0..11] of string = (
    'PINTAR', 'BRONCEAR', 'LACAR', 'PULIR', 'CORTAR', 'EMBALAR',
    'SOLDAR', 'FRESAR', 'TORNEAR', 'TALADRAR', 'RECTIFICAR', 'MONTAR'
  );
  Calendaris: array[0..2] of string = ('STD', 'TORN-A', 'TORN-B');
var
  NOperaris: Integer;
  Used: array of Boolean;
  Dept: TDepartamento;
  DeptIds: array of Integer;
  K: Integer;
const
  DeptNoms: array[0..5] of string = (
    'Mecanizado', 'Pintura', 'Montaje', 'Acabados', 'Expediciones', 'Calidad'
  );
  DeptDescs: array[0..5] of string = (
    'Torno, fresa, rectificadora', 'Cabinas de pintura y lacado',
    'L'#237'neas de montaje', 'Pulido y acabados finales',
    'Embalaje y expedici'#243'n', 'Control de calidad'
  );
begin
  // Departaments
  SetLength(DeptIds, Length(DeptNoms));
  for K := 0 to High(DeptNoms) do
  begin
    Dept.Id := 0;
    Dept.Nombre := DeptNoms[K];
    Dept.Descripcion := DeptDescs[K];
    DeptIds[K] := AddDepartamento(Dept);
  end;

  // Generar entre 15 i 30 operaris
  NOperaris := 15 + Random(16);

  for I := 0 to NOperaris - 1 do
  begin
    Op.Id := I + 1;
    Op.Nombre := Noms[I mod Length(Noms)] + ' ' + Cognoms[I mod Length(Cognoms)];
    if I >= Length(Cognoms) then
      Op.Nombre := Op.Nombre + ' ' + IntToStr(I div Length(Cognoms) + 1);
    Op.Calendario := Calendaris[Random(Length(Calendaris))];
    // Coste laboral sample: rango 14-26 eur/h, recargos est'andar
    Op.SueldoEurHora := 14 + Random(13);
    Op.RecargoTurnoNoche := 1.25;
    Op.RecargoFestivo := 1.75;
    AddOperario(Op);
  end;

  // Capacitacions: cada operari pot fer entre 2 i 5 operacions aleatories
  for I := 0 to NOperaris - 1 do
  begin
    NCaps := 2 + Random(4); // 2..5
    SetLength(Used, Length(Ops));
    for J := 0 to High(Used) do
      Used[J] := False;

    Cap.OperarioId := I + 1;
    while NCaps > 0 do
    begin
      J := Random(Length(Ops));
      if not Used[J] then
      begin
        Used[J] := True;
        Cap.Operacion := Ops[J];
        // Distribucion realista de niveles: 15% Aprendiz, 25% Junior, 45% Senior, 15% Experto
        case Random(100) of
           0..14: begin Cap.Nivel := nsAprendiz; Cap.FactorEficiencia := 1.30; end;
          15..39: begin Cap.Nivel := nsJunior;   Cap.FactorEficiencia := 1.10; end;
          40..84: begin Cap.Nivel := nsSenior;   Cap.FactorEficiencia := 1.00; end;
        else      begin Cap.Nivel := nsExperto;  Cap.FactorEficiencia := 0.85; end;
        end;
        AddCapacitacion(Cap);
        Dec(NCaps);
      end;
    end;
  end;

  // Assignar operaris a 1-2 departaments aleatoris
  for I := 0 to NOperaris - 1 do
  begin
    AssignOperariToDept(I + 1, DeptIds[Random(Length(DeptIds))]);
    if Random(3) = 0 then // 33% prob segon dept
      AssignOperariToDept(I + 1, DeptIds[Random(Length(DeptIds))]);
  end;
end;

end.
