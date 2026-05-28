unit uHelpAutoInstall;

// ============================================================================
// Hook global que instala el boton '?' del caption (biHelp) en TODOS los
// forms modales del proyecto, sin necesidad de tocar cada FormCreate.
//
// Como funciona:
//   - Al cargar la unidad (initialization) nos enganchamos a
//     Screen.OnActiveFormChange.
//   - Cada vez que aparece un form activo, miramos si es un form modal con
//     BorderStyle = bsDialog o bsSingle. Si lo es y no tiene ya ayuda
//     instalada, llamamos THelpViewer.InstallHelp con:
//        ATopicKey = ClassName del form (sin la 'T' inicial)
//        ATitulo   = Caption del form
//   - Si el MD correspondiente no existe en Help/<lang>/, el HelpViewer ya
//     muestra un mensaje generico "Ayuda no disponible".
//
// Para excluir un form de este hook, basta poner su clase en
// FExcludedClasses (ver mas abajo) o llamar a THelpViewer.InstallHelp
// manualmente desde su FormCreate (la deteccion es idempotente: si ya
// existe THelpHook como componente del form, no se instala dos veces).
// ============================================================================

interface

uses
  System.Classes, Vcl.Forms;

procedure InstallGlobalCaptionHelpHook;
procedure UninstallGlobalCaptionHelpHook;
procedure ExcludeFormClass(const AClassName: string);

implementation

uses
  System.SysUtils, System.StrUtils, System.Generics.Collections,
  Vcl.Controls,
  uHelpViewer;

type
  // El handler de Screen.OnActiveFormChange es un TNotifyEvent (method
  // pointer), no acepta procedures sueltas. Usamos un objeto contenedor.
  THelpHookDispatcher = class
    procedure HandleActiveFormChange(Sender: TObject);
  end;

var
  FOriginalHandler: TNotifyEvent;
  FInstalled: Boolean;
  FExcludedClasses: TList<string>;
  FDispatcher: THelpHookDispatcher;

function ClassNameToTopicKey(const AClassName: string): string;
var
  S: string;
begin
  // 'TfrmFoo' -> 'uFoo' por coherencia con los MDs ya existentes en Help/es/
  // que estan nombrados como la unidad fuente (uFoo.md).
  S := AClassName;
  if (Length(S) >= 2) and (S[1] = 'T') then
    S := Copy(S, 2, MaxInt);              // quita la 'T'
  if StartsText('frm', S) then
    S := 'u' + Copy(S, 4, MaxInt);        // 'frmFoo' -> 'uFoo'
  Result := S;
end;

function IsExcluded(const AClassName: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  if FExcludedClasses = nil then Exit;
  for I := 0 to FExcludedClasses.Count - 1 do
    if SameText(FExcludedClasses[I], AClassName) then
      Exit(True);
end;

function HasHelpAlreadyInstalled(AForm: TForm): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to AForm.ComponentCount - 1 do
    if AForm.Components[I].ClassName = 'THelpHook' then
      Exit(True);
end;

procedure THelpHookDispatcher.HandleActiveFormChange(Sender: TObject);
var
  F: TForm;
  TopicKey, Titulo: string;
begin
  // Encadenar al handler anterior (por si alguien ya tenia uno).
  if Assigned(FOriginalHandler) then
    FOriginalHandler(Sender);

  F := Screen.ActiveForm;
  if F = nil then Exit;

  // Solo nos interesan forms modales con caption "normal" donde Windows
  // pinta el boton biHelp.
  if not (F.FormStyle = fsNormal) then Exit;
  if not (F.BorderStyle in [bsDialog, bsSingle]) then Exit;

  // bsDialog ya excluye Min/Max por definicion; en bsSingle filtramos para
  // asegurar que el '?' se pintara (Windows solo lo muestra si NO hay
  // biMinimize ni biMaximize).
  if F.BorderStyle = bsSingle then
    if (biMinimize in F.BorderIcons) or (biMaximize in F.BorderIcons) then
      Exit;

  if IsExcluded(F.ClassName) then Exit;
  if HasHelpAlreadyInstalled(F) then Exit;

  TopicKey := ClassNameToTopicKey(F.ClassName);
  Titulo := F.Caption;
  THelpViewer.InstallHelp(F, TopicKey, Titulo);
end;

procedure InstallGlobalCaptionHelpHook;
begin
  if FInstalled then Exit;
  if FDispatcher = nil then
    FDispatcher := THelpHookDispatcher.Create;
  FOriginalHandler := Screen.OnActiveFormChange;
  Screen.OnActiveFormChange := FDispatcher.HandleActiveFormChange;
  FInstalled := True;
end;

procedure UninstallGlobalCaptionHelpHook;
begin
  if not FInstalled then Exit;
  Screen.OnActiveFormChange := FOriginalHandler;
  FOriginalHandler := nil;
  FInstalled := False;
end;

procedure ExcludeFormClass(const AClassName: string);
begin
  if FExcludedClasses = nil then
    FExcludedClasses := TList<string>.Create;
  if not IsExcluded(AClassName) then
    FExcludedClasses.Add(AClassName);
end;

initialization
  FExcludedClasses := TList<string>.Create;
  // Forms que NO han de tenir el boto '?' al caption:
  //   - Login: no te ajuda contextual; el boto distrau l'usuari.
  //   - InstallWizard: es un assistent linear, l'ajuda no aplica.
  //   - BusyDialog: no es un dialeg interactiu.
  //   - DBConfig: configuracio tecnica; no te MD pensat per client.
  //   - HelpViewer: seria recursiu.
  ExcludeFormClass('TfrmLogin');
  ExcludeFormClass('TfrmInstallWizard');
  ExcludeFormClass('TfrmBusyDialog');
  ExcludeFormClass('TfrmDBConfig');
  ExcludeFormClass('TfrmHelpViewer');
  InstallGlobalCaptionHelpHook;

finalization
  UninstallGlobalCaptionHelpHook;
  FreeAndNil(FDispatcher);
  FreeAndNil(FExcludedClasses);

end.
