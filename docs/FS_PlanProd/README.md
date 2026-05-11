# FS_PlanProd – Planificador de Producción (VCL Delphi 10.4)

Aplicación VCL multiformulario con un motor de scoring para asignar operarios
a operaciones de órdenes de trabajo en el sector químico.

## Estructura

```
FS_PlanProd/
├── FS_PlanProd.dpr            ← project file
├── FS_PlanProd.dproj          ← Delphi 10.4 project XML
├── src/                       ← lógica pura, sin VCL
│   ├── FS.PlanProd.Types.pas
│   ├── FS.PlanProd.Catalogo.pas
│   ├── FS.PlanProd.Engine.pas
│   └── FS.PlanProd.SessionData.pas
└── forms/                     ← formularios (todos diseñados en DFM)
    ├── Form.Main.pas/.dfm
    ├── Form.Pesos.pas/.dfm
    ├── Form.Operarios.pas/.dfm
    ├── Form.Ordenes.pas/.dfm
    └── Form.Asignaciones.pas/.dfm
```

## Novedades respecto a la versión anterior

### 1. Operaciones multi-operario

`TOperacionOrden` tiene dos nuevos atributos:

- `NumOperariosMin`: cuántos operarios distintos como mínimo se necesitan
  para arrancar la operación.
- `NumOperariosMax`: cuántos operarios pueden trabajar simultáneamente
  como máximo (más no aporta).

El motor `TMotorPlanificacion.PlanificarBatch` considera operaciones ya
iniciadas como elegibles si todavía tienen sitio (`TieneSitioParaMas`),
y nunca asigna dos veces al mismo operario en la misma operación.

### 2. Coste de mano de obra

`TOperario` tiene:

- `SueldoEurHora` – sueldo base por hora.
- `RecargoTurnoNoche` – multiplicador (ej. 1.25 = +25%) si trabaja en
  turno de noche.
- `RecargoFestivo` – multiplicador (ej. 1.75) si trabaja en festivo.

El método `CosteEfectivoEurHora(Fecha, EsFestivo)` aplica los recargos.

`TPesosPlanificacion.PesoCosteManoObra` permite penalizar en el score
a los operarios caros, siguiendo la fórmula:

```
score = w1·prioridad
      + w2·factor_compromiso
      + w3 / (1 + sobrenivel)
      − w4·carga_jornada_h
      + w5·continuidad
      + w6·minutos_espera
      − w7·(coste_eur_h / 10)
```

`TAsignacion.CosteEstimado` lleva ya el coste de la asignación en €.

### 3. UI multiformulario en VCL

Toda la interfaz está en DFM (cero creación de componentes en runtime).

- **Form.Main**: menú principal y arranque.
- **Form.Pesos**: edición de los 7 pesos del scoring + fórmula visible.
- **Form.Operarios**: master-detail con grid de operarios y panel de
  edición de polivalencia (habilidades, niveles, centros habilitados,
  turno, sueldo y recargos).
- **Form.Ordenes**: visualización jerárquica de órdenes con sus operaciones
  (incluyendo las nuevas columnas OpMin / OpMax).
- **Form.Asignaciones**: tabla de resultados con score y coste, con
  exportación a CSV.

### 4. Datos demo precargados

`FS.PlanProd.SessionData.pas` arranca con:

- 8 operaciones (MEZCLA, FILTRADO, ENVASADO, QC_LIQUIDOS, QC_FINAL, CIP,
  CARGA_MP, PALETIZADO).
- 5 centros (REACT-01, REACT-02, LIN-ENV-A, LIN-ENV-B, LAB-QC).
- 12 operarios con turnos variados (mañana, tarde, noche, central),
  sueldos de 14 a 28 €/h, y un operario de vacaciones para probar el
  filtro de ausencias.
- 6 órdenes de trabajo, varias con operaciones que requieren 2-3
  operarios simultáneos (ENVASADO, PALETIZADO, CARGA_MP).

## Cómo compilar

1. Abre `FS_PlanProd.dproj` en Delphi 10.4.
2. Compila para Win32.
3. Ejecuta. Se abrirá la ventana principal con la fecha simulada
   por defecto (lunes 11 de mayo de 2026, 08:00).

## Flujo de uso típico

1. Pulsa **Operarios y Polivalencia** para revisar/editar habilidades.
2. Pulsa **Órdenes de Trabajo** para ver las operaciones pendientes.
3. Pulsa **Parámetros y Pesos** y ajusta los pesos del scoring.
4. Pulsa **Ejecutar Planificación** para calcular asignaciones.
5. Pulsa **Ver Asignaciones** para revisar el resultado y exportarlo.

Cambia la fecha simulada en la pantalla principal para probar
distintos turnos (operarios de noche solo trabajan después de las 22h).
