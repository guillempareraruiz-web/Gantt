unit uOperariosTypes;

interface

type
  TOperario = record
    Id: Integer;
    Nombre: string;
    Calendario: string;
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

  TCapacitacion = record
    OperarioId: Integer;
    Operacion: string;       // nom de l'operació que pot fer
  end;

  TAsignacionOperario = record
    OperarioId: Integer;
    DataId: Integer;         // node (operació) assignat
    Horas: Double;           // hores dins el node
  end;

implementation

end.

