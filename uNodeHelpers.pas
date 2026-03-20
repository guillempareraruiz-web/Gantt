unit uNodeHelpers;

interface

function MakeOFKey(const NumeroOF: Integer; const Serie: string): string;
function MakeTrabajoKey(const NumeroTrabajo: string): string;

implementation

uses System.SysUtils;

function MakeOFKey(const NumeroOF: Integer; const Serie: string): string;
begin
  Result := IntToStr(NumeroOF) + '|' + UpperCase(Trim(Serie));
end;

function MakeTrabajoKey(const NumeroTrabajo: string): string;
begin
  Result := UpperCase(Trim(NumeroTrabajo));
end;

end.
