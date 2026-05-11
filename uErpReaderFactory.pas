unit uErpReaderFactory;

// ============================================================================
// Factory que instancia el reader concret segons l'ERP actiu (INI).
//
// L'unic punt del projecte que coneix totes les implementacions concretes.
// Si demanem afegir un ERP nou, nomes cal:
//   1. Crear uXyzReader.pas amb la classe TXyzReader: TInterfacedObject, IErpReader
//   2. Afegir un branch al case d'aqui sota
//
// Cada crida a GetActiveErpReader retorna UNA NOVA instancia. Es responsabilitat
// del cridant alliberar-la (en el cas d'una interfície, l'allibera el refcount).
// ============================================================================

interface

uses
  System.SysUtils,
  uErpReader;

// Retorna el reader actiu segons LoadErpActivo (INI [Erp]/Activo).
// Si no hi ha ERP configurat o el codi no es reconeix, retorna nil.
function GetActiveErpReader: IErpReader;

// Igual que GetActiveErpReader peró llanca Exception en lloc de retornar nil.
function GetActiveErpReaderOrRaise: IErpReader;

implementation

uses
  uAppConfig, uSage200Reader;

function GetActiveErpReader: IErpReader;
var
  Codigo: string;
begin
  Result := nil;
  Codigo := LoadErpActivo;

  if SameText(Codigo, 'Sage200') then
    Result := TSage200Reader.Create;

  // Futurs ERPs:
  //   if SameText(Codigo, 'SAPB1')        then Result := TSAPB1Reader.Create;
  //   if SameText(Codigo, 'Dynamics365BC') then Result := TDynamicsReader.Create;
end;

function GetActiveErpReaderOrRaise: IErpReader;
begin
  Result := GetActiveErpReader;
  if Result = nil then
    raise Exception.Create('No hay ning'#250'n ERP activo o reconocido en la ' +
      'configuraci'#243'n.');
end;

end.
