unit uErpReader;

// ============================================================================
// Contracte neutre de lectura d'un ERP (Sage 200, SAP, Dynamics...).
//
// Les pantalles de detall (Pedido, Formula, etc.) NOMES depenen d'aquesta
// interfície. Cada implementacio concreta tradueix del dialecte propi de
// l'ERP als tipus neutres definits a uErpTypes.pas.
//
// Per obtenir el reader actiu segons la configuracio:
//   uses uErpReaderFactory;
//   var Reader := GetActiveErpReader;
//   if Reader = nil then ...   // ERP no configurat
// ============================================================================

interface

uses
  System.SysUtils, System.Classes,
  uErpTypes;

type
  IErpReader = interface
    ['{D8C2C1A0-7B6E-4F3C-9A21-1F0E3A55E901}']

    // Nom human-readable del sistema ('Sage 200', 'SAP B1', ...) per a logs/UI
    function GetSistemaNombre: string;

    // Asegura connexio amb l'ERP. Llanca Exception si no es pot connectar.
    procedure EnsureConnected;

    // -- PEDIDOS DE CLIENTE ------------------------------------------------
    // Retorna la cabecera del pedido. Si no existeix, Result.Encontrado = False.
    function ReadPedidoCabecera(const ASerie: string; ANumero: Integer;
      AEjercicio: SmallInt): TPedidoCabecera;

    // Retorna les linies del pedido en ordre. Array buit si no n'hi ha.
    function ReadPedidoLineas(const ASerie: string; ANumero: Integer;
      AEjercicio: SmallInt): TArray<TPedidoLinea>;

    // -- FORMULA / ESCANDALL -----------------------------------------------
    // Retorna totes les versions de formula disponibles per l'article,
    // ordenades de menor a major. Array buit si no en te cap.
    function ReadFormulaVersiones(const ACodigoArticulo: string): TArray<SmallInt>;

    // Retorna la primera versio de formula disponible per l'article.
    // Si no n'hi ha cap, Result.Encontrada = False (Version = 0).
    function ReadFormulaCabecera(const ACodigoArticulo: string): TFormulaCabecera;

    // Components (Mat_Formula en Sage) per a la versio indicada.
    function ReadFormulaComponentes(const ACodigoArticulo: string;
      AVersion: SmallInt): TArray<TFormulaComponente>;

    // Operacions/fases (Oper_Formula en Sage) per a la versio indicada.
    function ReadFormulaOperaciones(const ACodigoArticulo: string;
      AVersion: SmallInt): TArray<TFormulaOperacion>;
  end;

implementation

end.
