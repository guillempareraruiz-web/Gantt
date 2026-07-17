unit uRowFilterDialog;

{
  Dialogo de FILTRO por entidad del RowMode activo (Centros / Ordenes /
  Utillajes / Clientes).

  Recibe una lista de items (clave interna + etiqueta visible) y devuelve el
  subconjunto que el usuario marca, mas el modo de efecto (atenuar u ocultar).
  No sabe NADA de nodos ni de DataIds: la resolucion clave->DataIds y la
  aplicacion del filtro (SetOperarioFilter) las hace uVistaGantt. Asi el dialogo
  es reutilizable para cualquier RowMode.

  Lleva un BUSCADOR arriba (TcxTextEdit) que filtra la lista en vivo. El estado
  de marcado se guarda por CLAVE (no por indice visible), de modo que
  buscar/ocultar filas no pierde los checks de las que se esconden.

  Controles DevExpress (coherencia con el resto de la app): TcxTextEdit,
  TcxCheckListBox, TcxButton, TcxCheckBox.

  Uso:
    if TfrmRowFilterDialog.Execute('Filtrar por cliente', Items,
         SelClaves, HideMode) then
      ... aplicar filtro con SelClaves y HideMode ...
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  cxTextEdit, cxCheckListBox, cxButtons, cxCheckBox, cxContainer, cxEdit;

type
  // Un item filtrable: Clave = valor interno (codigo cliente, id utillaje...),
  // Caption = texto que ve el usuario, Count = nº de trabajos (informativo).
  TRowFilterItem = record
    Clave: string;
    Caption: string;
    Count: Integer;
  end;
  TRowFilterItems = TArray<TRowFilterItem>;

  TfrmRowFilterDialog = class(TForm)
  private
    FEdBuscar: TcxTextEdit;
    FLblBuscar: TLabel;
    FList: TcxCheckListBox;
    FChkOcultar: TcxCheckBox;   // marcado = ocultar el resto; si no, atenuar
    FBtnTodos: TcxButton;
    FBtnNinguno: TcxButton;
    FBtnOK: TcxButton;
    FBtnCancel: TcxButton;
    FBtnLimpiar: TcxButton;
    FItems: TRowFilterItems;
    // Estado de marcado por CLAVE (sobrevive al filtrado del buscador).
    FChecked: TDictionary<string, Boolean>;
    // Claves actualmente visibles en FList, en su mismo orden (indice -> clave).
    FVisibleClaves: TArray<string>;
    procedure BuildUI;
    procedure RepoblarLista;
    procedure GuardarChecksVisibles;
    procedure DoBuscarChange(Sender: TObject);
    procedure DoTodos(Sender: TObject);
    procedure DoNinguno(Sender: TObject);
    procedure DoLimpiar(Sender: TObject);
  public
    destructor Destroy; override;
    // Muestra el dialogo. Devuelve True si el usuario acepto (OK). En AClaves
    // deja las claves marcadas; en AHideMode, True = ocultar, False = atenuar.
    // Si el usuario pulsa "Quitar filtro", devuelve True con AClaves vacio.
    class function Execute(const ATitulo: string; const AItems: TRowFilterItems;
      out AClaves: TArray<string>; out AHideMode: Boolean): Boolean;
  end;

implementation

// Sin .dfm: el form se construye por codigo con CreateNew + BuildUI.

destructor TfrmRowFilterDialog.Destroy;
begin
  FChecked.Free;
  inherited;
end;

procedure TfrmRowFilterDialog.BuildUI;
begin
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  ClientWidth := 320;
  ClientHeight := 430;
  Caption := 'Filtro';

  FChecked := TDictionary<string, Boolean>.Create;

  FLblBuscar := TLabel.Create(Self);
  FLblBuscar.Parent := Self;
  FLblBuscar.SetBounds(12, 12, 60, 16);
  FLblBuscar.Caption := 'Buscar:';

  FEdBuscar := TcxTextEdit.Create(Self);
  FEdBuscar.Parent := Self;
  FEdBuscar.SetBounds(12, 30, ClientWidth - 24, 24);
  FEdBuscar.Anchors := [akLeft, akTop, akRight];
  FEdBuscar.Properties.OnChange := DoBuscarChange;

  FList := TcxCheckListBox.Create(Self);
  FList.Parent := Self;
  FList.SetBounds(12, 62, ClientWidth - 24, 250);
  FList.Anchors := [akLeft, akTop, akRight, akBottom];

  FBtnTodos := TcxButton.Create(Self);
  FBtnTodos.Parent := Self;
  FBtnTodos.SetBounds(12, 320, 90, 25);
  FBtnTodos.Caption := 'Todos';
  FBtnTodos.Anchors := [akLeft, akBottom];
  FBtnTodos.OnClick := DoTodos;

  FBtnNinguno := TcxButton.Create(Self);
  FBtnNinguno.Parent := Self;
  FBtnNinguno.SetBounds(108, 320, 90, 25);
  FBtnNinguno.Caption := 'Ninguno';
  FBtnNinguno.Anchors := [akLeft, akBottom];
  FBtnNinguno.OnClick := DoNinguno;

  // Efecto: por defecto atenuar; si se marca, ocultar el resto.
  FChkOcultar := TcxCheckBox.Create(Self);
  FChkOcultar.Parent := Self;
  FChkOcultar.SetBounds(12, 352, 260, 20);
  FChkOcultar.Caption := 'Ocultar el resto (si no, se aten'#250'a)';
  FChkOcultar.Anchors := [akLeft, akBottom];

  FBtnLimpiar := TcxButton.Create(Self);
  FBtnLimpiar.Parent := Self;
  FBtnLimpiar.SetBounds(12, 382, 90, 30);
  FBtnLimpiar.Caption := 'Quitar filtro';
  FBtnLimpiar.Anchors := [akLeft, akBottom];
  FBtnLimpiar.OnClick := DoLimpiar;

  FBtnOK := TcxButton.Create(Self);
  FBtnOK.Parent := Self;
  FBtnOK.SetBounds(ClientWidth - 194, 382, 90, 30);
  FBtnOK.Caption := 'Aplicar';
  FBtnOK.Default := True;
  FBtnOK.ModalResult := mrOk;
  FBtnOK.Anchors := [akRight, akBottom];

  FBtnCancel := TcxButton.Create(Self);
  FBtnCancel.Parent := Self;
  FBtnCancel.SetBounds(ClientWidth - 100, 382, 90, 30);
  FBtnCancel.Caption := 'Cancelar';
  FBtnCancel.Cancel := True;
  FBtnCancel.ModalResult := mrCancel;
  FBtnCancel.Anchors := [akRight, akBottom];
end;

// Vuelca a FChecked el estado de las filas ahora visibles (antes de repintar).
procedure TfrmRowFilterDialog.GuardarChecksVisibles;
var
  I: Integer;
begin
  for I := 0 to High(FVisibleClaves) do
    if I < FList.Items.Count then
      FChecked.AddOrSetValue(FVisibleClaves[I], FList.Items[I].Checked);
end;

// Repinta FList con los items cuyo caption/clave contiene el texto del buscador
// (case-insensitive). Restaura el check de cada fila desde FChecked.
procedure TfrmRowFilterDialog.RepoblarLista;
var
  Filtro: string;
  I, Vis: Integer;
  Chk: Boolean;
  Coincide: Boolean;
  it: TcxCheckListBoxItem;
begin
  Filtro := LowerCase(Trim(FEdBuscar.Text));

  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    SetLength(FVisibleClaves, 0);
    Vis := 0;
    for I := 0 to High(FItems) do
    begin
      if Filtro = '' then
        Coincide := True
      else
        Coincide := (Pos(Filtro, LowerCase(FItems[I].Caption)) > 0) or
                    (Pos(Filtro, LowerCase(FItems[I].Clave)) > 0);
      if not Coincide then Continue;

      it := FList.Items.Add;
      if FItems[I].Count > 0 then
        it.Text := Format('%s  (%d)', [FItems[I].Caption, FItems[I].Count])
      else
        it.Text := FItems[I].Caption;

      if FChecked.TryGetValue(FItems[I].Clave, Chk) then
        it.Checked := Chk;

      SetLength(FVisibleClaves, Vis + 1);
      FVisibleClaves[Vis] := FItems[I].Clave;
      Inc(Vis);
    end;
  finally
    FList.Items.EndUpdate;
  end;
end;

procedure TfrmRowFilterDialog.DoBuscarChange(Sender: TObject);
begin
  // Guardar lo marcado antes de reconstruir la lista, si no se perderian los
  // checks de las filas que el nuevo filtro deje fuera.
  GuardarChecksVisibles;
  RepoblarLista;
end;

procedure TfrmRowFilterDialog.DoTodos(Sender: TObject);
var
  I: Integer;
begin
  // Marca TODOS los items (visibles o no), no solo los que se ven ahora.
  for I := 0 to High(FItems) do
    FChecked.AddOrSetValue(FItems[I].Clave, True);
  RepoblarLista;
end;

procedure TfrmRowFilterDialog.DoNinguno(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to High(FItems) do
    FChecked.AddOrSetValue(FItems[I].Clave, False);
  RepoblarLista;
end;

procedure TfrmRowFilterDialog.DoLimpiar(Sender: TObject);
begin
  // "Quitar filtro" = aceptar con seleccion vacia.
  DoNinguno(nil);
  ModalResult := mrOk;
end;

class function TfrmRowFilterDialog.Execute(const ATitulo: string;
  const AItems: TRowFilterItems; out AClaves: TArray<string>;
  out AHideMode: Boolean): Boolean;
var
  Dlg: TfrmRowFilterDialog;
  I: Integer;
  L: TStringList;
  Chk: Boolean;
begin
  SetLength(AClaves, 0);
  AHideMode := False;
  Dlg := TfrmRowFilterDialog.CreateNew(nil);
  try
    Dlg.BuildUI;
    Dlg.Caption := ATitulo;
    Dlg.FItems := AItems;
    Dlg.RepoblarLista;   // primer pintado (sin filtro)

    Result := Dlg.ShowModal = mrOk;
    if Result then
    begin
      AHideMode := Dlg.FChkOcultar.Checked;
      // Volcar lo visible por si el usuario marco algo sin tocar el buscador.
      Dlg.GuardarChecksVisibles;
      L := TStringList.Create;
      try
        for I := 0 to High(AItems) do
          if Dlg.FChecked.TryGetValue(AItems[I].Clave, Chk) and Chk then
            L.Add(AItems[I].Clave);
        AClaves := L.ToStringArray;
      finally
        L.Free;
      end;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
