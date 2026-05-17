/* ============================================================================
   SageX3_Demo.sql
   ----------------------------------------------------------------------------
   Base de dades de prova que replica l'estructura del mòdul de PRODUCCIÓ
   de Sage X3 (v12) sobre SQL Server.

   Taules incloses:
     - FACILITY     : Centres (master)
     - ITMMASTER    : Articles (master)
     - ITMFACILIT   : Articles per centre (master)
     - STOCK        : Estocs (master/trans)
     - MFGHEAD      : Capçalera ordre fabricació    [doc verificada v12]
     - MFGITM       : Productes a fabricar          [doc verificada v12]
     - MFGMAT       : Materials/components          [doc verificada v12]
     - MFGOPE       : Operacions de ruta            [esquema X3 estàndard]

   Convencions X3 aplicades:
     - Sufix _0 a tots els camps escalars
     - Boolean: 1 = Sí, 2 = No  (atenció: és l'oposat del Sage 50/200)
     - Local menus referenciats amb comentari
     - NVARCHAR + COLLATE Latin1_General_BIN2 (CS, AS - com X3 real)
     - Camps NOT NULL amb DEFAULT segons convenció X3
     - Columnes d'auditoria: AUUID, CRE*, UPD*, EXPNUM_0
     - Índexs MFG0/MFG1/MFG2... segons claus de la documentació

   Executar amb Navicat:
     1. Connectar al SQL Server destí
     2. Obrir aquest fitxer amb Ctrl+O
     3. Executar amb F9 o el botó Run
     4. Refrescar el panell de connexions per veure la nova BD
   ============================================================================ */

SET NOCOUNT ON;
GO

/* ----------------------------------------------------------------------------
   1. CREACIÓ DE LA BASE DE DADES
   ---------------------------------------------------------------------------- */
IF DB_ID('SageX3_Demo') IS NOT NULL
BEGIN
    PRINT 'La BD SageX3_Demo ja existeix. Eliminant...';
    ALTER DATABASE SageX3_Demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SageX3_Demo;
END
GO

CREATE DATABASE SageX3_Demo
    COLLATE Latin1_General_BIN2;  -- Col·lació nativa de Sage X3 (binari, CS+AS)
GO

ALTER DATABASE SageX3_Demo SET RECOVERY SIMPLE;
GO

USE SageX3_Demo;
GO

PRINT '>>> BD SageX3_Demo creada amb col·lació Latin1_General_BIN2';
GO

/* ============================================================================
   2. TAULA FACILITY  -  Centres / Llocs
   ============================================================================ */
CREATE TABLE dbo.FACILITY (
    FCY_0          NVARCHAR(5)    NOT NULL DEFAULT '',  -- Codi centre
    FCYNAM_0       NVARCHAR(35)   NOT NULL DEFAULT '',  -- Descripció
    FCYSHO_0       NVARCHAR(10)   NOT NULL DEFAULT '',  -- Descripció curta
    CPY_0          NVARCHAR(5)    NOT NULL DEFAULT '',  -- Societat
    LEGCPY_0       SMALLINT       NOT NULL DEFAULT 2,   -- Centre legal: 1=Sí, 2=No
    MFGFLG_0       SMALLINT       NOT NULL DEFAULT 2,   -- Centre productor: 1=Sí, 2=No
    STOFLG_0       SMALLINT       NOT NULL DEFAULT 2,   -- Centre amb estoc: 1=Sí, 2=No
    SALFLG_0       SMALLINT       NOT NULL DEFAULT 2,   -- Centre de vendes
    PURFLG_0       SMALLINT       NOT NULL DEFAULT 2,   -- Centre de compres
    FCYCRY_0       NVARCHAR(3)    NOT NULL DEFAULT '',  -- País
    CRY_0          NVARCHAR(35)   NOT NULL DEFAULT '',  -- Nom país
    ADDLIG_0       NVARCHAR(50)   NOT NULL DEFAULT '',  -- Adreça línia 1
    ADDLIG_1       NVARCHAR(50)   NOT NULL DEFAULT '',  -- Adreça línia 2
    ZIP_0          NVARCHAR(10)   NOT NULL DEFAULT '',  -- CP
    CTY_0          NVARCHAR(40)   NOT NULL DEFAULT '',  -- Població
    TEL_0          NVARCHAR(40)   NOT NULL DEFAULT '',  -- Telèfon
    -- Auditoria
    AUUID_0        UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    CREDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    UPDDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    EXPNUM_0       INT            NOT NULL DEFAULT 0,
    ROWID          INT            IDENTITY(1,1) NOT NULL
);
GO

-- Índexs estàndard X3
ALTER TABLE dbo.FACILITY ADD CONSTRAINT FACILITY_FCY0 PRIMARY KEY CLUSTERED (FCY_0);
CREATE UNIQUE INDEX FACILITY_FCY1 ON dbo.FACILITY (CPY_0, FCY_0);
GO

/* ============================================================================
   3. TAULA ITMMASTER  -  Articles
   ============================================================================ */
CREATE TABLE dbo.ITMMASTER (
    ITMREF_0       NVARCHAR(30)   NOT NULL DEFAULT '',  -- Codi article (PK)
    ITMDES1_0      NVARCHAR(40)   NOT NULL DEFAULT '',  -- Descripció 1
    ITMDES2_0      NVARCHAR(40)   NOT NULL DEFAULT '',  -- Descripció 2
    ITMDES3_0      NVARCHAR(40)   NOT NULL DEFAULT '',  -- Descripció 3
    DES1AXX_0      NVARCHAR(40)   NOT NULL DEFAULT '',  -- Desc. curta
    TCLCOD_0       NVARCHAR(10)   NOT NULL DEFAULT '',  -- Categoria
    ITMSTA_0       SMALLINT       NOT NULL DEFAULT 1,   -- Estat: 1=Actiu, 2=No actiu, 3=Aturat
    ITMKND_0       SMALLINT       NOT NULL DEFAULT 1,   -- Tipus: 1=Estàndard, 2=Servei, 3=Genèric, 4=Variant
    STOMGTCOD_0    SMALLINT       NOT NULL DEFAULT 1,   -- Gestionat en estoc: 1=Sí, 2=No
    LOTMGTCOD_0    SMALLINT       NOT NULL DEFAULT 1,   -- Gestió lot: 1=No, 2=Opcional, 3=Obligatori
    SERMGTCOD_0    SMALLINT       NOT NULL DEFAULT 1,   -- Gestió sèrie
    STU_0          NVARCHAR(3)    NOT NULL DEFAULT 'UN', -- Unitat estoc
    EUU_0          NVARCHAR(3)    NOT NULL DEFAULT 'UN', -- Unitat venda
    PUU_0          NVARCHAR(3)    NOT NULL DEFAULT 'UN', -- Unitat compra
    ITMWEI_0       DECIMAL(15,4)  NOT NULL DEFAULT 0,    -- Pes brut (kg)
    ITMWEIU_0      NVARCHAR(3)    NOT NULL DEFAULT 'KG', -- Unitat pes
    ITMVOU_0       NVARCHAR(3)    NOT NULL DEFAULT 'M3', -- Unitat volum
    ITMVOL_0       DECIMAL(15,4)  NOT NULL DEFAULT 0,    -- Volum
    BUY_0          SMALLINT       NOT NULL DEFAULT 2,   -- Article comprat
    SAL_0          SMALLINT       NOT NULL DEFAULT 2,   -- Article venut
    MFG_0          SMALLINT       NOT NULL DEFAULT 2,   -- Article fabricat
    PURBASPRI_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Preu base compra
    BASPRI_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Preu base venda
    STOCUR_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Cost estoc actual
    ACCCOD_0       NVARCHAR(10)   NOT NULL DEFAULT '',   -- Codi comptable
    VACITM_0       NVARCHAR(5)    NOT NULL DEFAULT '',   -- Tipus IVA
    PLNFCY_0       NVARCHAR(5)    NOT NULL DEFAULT '',   -- Centre planificació
    BOMNUM_0       NVARCHAR(20)   NOT NULL DEFAULT '',   -- Codi BOM principal
    ROUNUM_0       NVARCHAR(20)   NOT NULL DEFAULT '',   -- Codi ruta principal
    PLNMOD_0       SMALLINT       NOT NULL DEFAULT 1,   -- Mode planificació: 1=Sense, 2=Punt comanda, 3=MRP
    PLNZON_0       NVARCHAR(15)   NOT NULL DEFAULT '',   -- Zona planificació
    LTI_0          INT            NOT NULL DEFAULT 0,    -- Lead time (dies)
    -- Auditoria
    AUUID_0        UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    CREDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    UPDDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    EXPNUM_0       INT            NOT NULL DEFAULT 0,
    ROWID          INT            IDENTITY(1,1) NOT NULL
);
GO

ALTER TABLE dbo.ITMMASTER ADD CONSTRAINT ITMMASTER_ITM0 PRIMARY KEY CLUSTERED (ITMREF_0);
CREATE INDEX ITMMASTER_ITM1 ON dbo.ITMMASTER (TCLCOD_0, ITMREF_0);
CREATE INDEX ITMMASTER_ITM2 ON dbo.ITMMASTER (ITMSTA_0, ITMREF_0);
GO

/* ============================================================================
   4. TAULA ITMFACILIT  -  Articles per centre
   ============================================================================ */
CREATE TABLE dbo.ITMFACILIT (
    ITMREF_0       NVARCHAR(30)   NOT NULL DEFAULT '',
    STOFCY_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    PLNFCY_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    REOMGTCOD_0    SMALLINT       NOT NULL DEFAULT 1,   -- Mètode reaprovisionament
    REOTSD_0       DECIMAL(15,4)  NOT NULL DEFAULT 0,    -- Punt comanda
    REOMINQTY_0    DECIMAL(15,4)  NOT NULL DEFAULT 0,    -- Estoc mínim
    REOMAXQTY_0    DECIMAL(15,4)  NOT NULL DEFAULT 0,    -- Estoc màxim
    REOLOT_0       DECIMAL(15,4)  NOT NULL DEFAULT 0,    -- Lot tècnic
    LTI_0          INT            NOT NULL DEFAULT 0,    -- Lead time (dies)
    BUY_0          SMALLINT       NOT NULL DEFAULT 2,
    SAL_0          SMALLINT       NOT NULL DEFAULT 2,
    MFG_0          SMALLINT       NOT NULL DEFAULT 2,
    AUUID_0        UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    CREDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    UPDDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    EXPNUM_0       INT            NOT NULL DEFAULT 0,
    ROWID          INT            IDENTITY(1,1) NOT NULL
);
GO

ALTER TABLE dbo.ITMFACILIT ADD CONSTRAINT ITMFACILIT_ITF0 PRIMARY KEY CLUSTERED (ITMREF_0, STOFCY_0);
GO

/* ============================================================================
   5. TAULA STOCK  -  Estocs
   ============================================================================ */
CREATE TABLE dbo.STOCK (
    STOFCY_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    ITMREF_0       NVARCHAR(30)   NOT NULL DEFAULT '',
    PCU_0          NVARCHAR(3)    NOT NULL DEFAULT 'UN',
    LOC_0          NVARCHAR(10)   NOT NULL DEFAULT '',  -- Ubicació
    LOT_0          NVARCHAR(20)   NOT NULL DEFAULT '',  -- Lot
    SLO_0          NVARCHAR(20)   NOT NULL DEFAULT '',  -- Sublot
    STA_0          NVARCHAR(12)   NOT NULL DEFAULT 'A',  -- Estat: A=Acceptat, R=Rebutjat, Q=Quarantena
    QTYSTU_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat física
    QTYPCU_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat unitat embalatge
    PALNUM_0       NVARCHAR(20)   NOT NULL DEFAULT '',   -- Núm palet
    AUUID_0        UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    CREDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    UPDDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    EXPNUM_0       INT            NOT NULL DEFAULT 0,
    STOCOU_0       INT            IDENTITY(1,1) NOT NULL  -- Comptador estoc (PK)
);
GO

ALTER TABLE dbo.STOCK ADD CONSTRAINT STOCK_STK0 PRIMARY KEY CLUSTERED (STOCOU_0);
CREATE INDEX STOCK_STK1 ON dbo.STOCK (ITMREF_0, STOFCY_0, LOC_0, LOT_0);
CREATE INDEX STOCK_STK2 ON dbo.STOCK (STOFCY_0, LOC_0, ITMREF_0);
CREATE INDEX STOCK_STK3 ON dbo.STOCK (ITMREF_0, LOT_0);
GO

/* ============================================================================
   6. TAULA MFGHEAD  -  Capçalera ordre de fabricació (Work order header)
       [Estructura verificada amb online-help.sagex3.com/erp/12]
       Claus: MFG0=MFGNUM | MFG1=MFGFCY+MFGTRKFLG | MFG2=MTOREF
   ============================================================================ */
CREATE TABLE dbo.MFGHEAD (
    MFGNUM_0       NVARCHAR(20)   NOT NULL DEFAULT '',  -- Núm ordre (PK)
    MFGFCY_0       NVARCHAR(5)    NOT NULL DEFAULT '',  -- Centre producció
    PLNFCY_0       NVARCHAR(5)    NOT NULL DEFAULT '',  -- Centre planificació
    MFGSTA_0       SMALLINT       NOT NULL DEFAULT 1,   -- Estat ordre [menu 317]
                                                         --   1=Ferm, 2=Planificat, 3=Tancat, 4=Tancat amb cost
    MFGTRKFLG_0    SMALLINT       NOT NULL DEFAULT 1,   -- Flag seguiment [menu 339]
                                                         --   1=Pendent, 2=Imprès, 3=En curs, 4=Acabat
    MFGMOD_0       SMALLINT       NOT NULL DEFAULT 1,   -- Mode llançament [menu 333]
    MFGPIO_0       SMALLINT       NOT NULL DEFAULT 2,   -- Prioritat [menu 365] 1=Alta, 2=Normal, 3=Baixa
    MFGTEX_0       NVARCHAR(255)  NOT NULL DEFAULT '',  -- Text producció
    MTOREF_0       NVARCHAR(20)   NOT NULL DEFAULT '',  -- Xarxa MTO
    NPIPRO_0       SMALLINT       NOT NULL DEFAULT 2,   -- Prototip
    SUSFLG_0       SMALLINT       NOT NULL DEFAULT 2,   -- OF suspesa
    CFMFLG_0       SMALLINT       NOT NULL DEFAULT 2,   -- Validat
    OPTFLG_0       SMALLINT       NOT NULL DEFAULT 2,   -- Optimitzat
    OPTUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    SCDFLG_0       SMALLINT       NOT NULL DEFAULT 1,   -- Estat planificació [menu 335]
    SCDMOD_0       SMALLINT       NOT NULL DEFAULT 1,   -- Mode planificació [menu 334]
    -- Quantitats
    EXTQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat planificada
    CPLQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat completada
    QUACPLQTY_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat QC real
    REJCPLQTY_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat rebutjada real
    RMNEXTQTY_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat romanent
    AVAMFGQTY_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat producible
    STU_0          NVARCHAR(3)    NOT NULL DEFAULT 'UN', -- Unitat estoc
    -- Ruta
    ROUNUM_0       NVARCHAR(20)   NOT NULL DEFAULT '',
    ROUALT_0       NVARCHAR(20)   NOT NULL DEFAULT '',
    ROUECCMAJ_0    SMALLINT       NOT NULL DEFAULT 0,
    ROUECCMIN_0    SMALLINT       NOT NULL DEFAULT 0,
    -- Dates planificació
    STRDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',  -- Data inici
    ENDDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',  -- Data fi
    EARSTRDAT_0    DATETIME       NOT NULL DEFAULT '1753-01-01',  -- Inici més aviat
    LATENDDAT_0    DATETIME       NOT NULL DEFAULT '1753-01-01',  -- Fi més tard
    FITCAPSTR_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    FITCAPEND_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    INFCAPSTR_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    INFCAPEND_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    OBJDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',  -- Objectiu inicial
    CLODAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',  -- Data tancament
    TRKFIRST_0     DATETIME       NOT NULL DEFAULT '1753-01-01',  -- Primer seguiment
    TRKFIRSTC_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    TRKLAST_0      DATETIME       NOT NULL DEFAULT '1753-01-01',  -- Últim seguiment
    TRKLASTC_0     DATETIME       NOT NULL DEFAULT '1753-01-01',
    GFSPUBTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    -- Estats secundaris
    ALLSTA_0       SMALLINT       NOT NULL DEFAULT 1,   -- Estat assignació [menu 336]
    PRPSTA_0       SMALLINT       NOT NULL DEFAULT 1,   -- Estat preparació [menu 338]
    -- Comptadors
    ITMLINNBR_0    INT            NOT NULL DEFAULT 0,    -- Núm productes
    ITMCLENBR_0    INT            NOT NULL DEFAULT 0,    -- Núm productes tancats
    MATLINNBR_0    INT            NOT NULL DEFAULT 0,    -- Núm materials
    MATCLENBR_0    INT            NOT NULL DEFAULT 0,    -- Núm materials tancats
    OPELINNBR_0    INT            NOT NULL DEFAULT 0,    -- Núm operacions
    OPECLENBR_0    INT            NOT NULL DEFAULT 0,    -- Núm operacions tancades
    PRPMATNBR_0    INT            NOT NULL DEFAULT 0,
    SHTMATNBR_0    INT            NOT NULL DEFAULT 0,
    OVRALLNBR_0    INT            NOT NULL DEFAULT 0,
    DETALLNBR_0    INT            NOT NULL DEFAULT 0,
    -- Tipus i altres
    TYPMOD_0       SMALLINT       NOT NULL DEFAULT 1,   -- Tipus mode [menu 371]
    LTIREDCOE_0    DECIMAL(9,2)   NOT NULL DEFAULT 0,    -- Coef. reducció LT
    CLCSCDLTI_0    DECIMAL(9,2)   NOT NULL DEFAULT 0,
    SINUM_0        NVARCHAR(1)    NOT NULL DEFAULT '',
    -- Auditoria
    AUUID_0        UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    CREDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    UPDDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    EXPNUM_0       INT            NOT NULL DEFAULT 0,
    ROWID          INT            IDENTITY(1,1) NOT NULL
);
GO

ALTER TABLE dbo.MFGHEAD ADD CONSTRAINT MFGHEAD_MFG0 PRIMARY KEY CLUSTERED (MFGNUM_0);
CREATE INDEX MFGHEAD_MFG1 ON dbo.MFGHEAD (MFGFCY_0, MFGTRKFLG_0);
CREATE INDEX MFGHEAD_MFG2 ON dbo.MFGHEAD (MTOREF_0);
GO

/* ============================================================================
   7. TAULA MFGITM  -  Productes a fabricar (Work order items)
       [Estructura verificada amb online-help.sagex3.com/erp/12]
       Claus: MFI0=MFGNUM+MFGLIN | MFI1=MFGFCY+STRDAT | MFI2=MFGNUM
   ============================================================================ */
CREATE TABLE dbo.MFGITM (
    MFGNUM_0       NVARCHAR(20)   NOT NULL DEFAULT '',  -- Núm ordre (FK MFGHEAD)
    MFGLIN_0       INT            NOT NULL DEFAULT 0,   -- Núm línia
    ITMLIN_0       INT            NOT NULL DEFAULT 0,   -- Línia WO
    MFGFCY_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    PLNFCY_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    ITMREF_0       NVARCHAR(30)   NOT NULL DEFAULT '',  -- Article (FK ITMMASTER)
    MFGDES_0       NVARCHAR(40)   NOT NULL DEFAULT '',  -- Descripció WO
    ITMTYP_0       SMALLINT       NOT NULL DEFAULT 1,   -- Tipus producte [menu 2301]
    ITMSTA_0       SMALLINT       NOT NULL DEFAULT 1,   -- Estat línia [menu 363]
    MFGSTA_0       SMALLINT       NOT NULL DEFAULT 1,   -- Estat ordre [menu 317]
    MFITRKFLG_0    SMALLINT       NOT NULL DEFAULT 1,   -- Flag seguiment [menu 339]
    MFGPIO_0       SMALLINT       NOT NULL DEFAULT 2,   -- Prioritat
    FMI_0          SMALLINT       NOT NULL DEFAULT 1,   -- Origen producte [menu 445]
    -- BOM
    BOMALT_0       NVARCHAR(20)   NOT NULL DEFAULT '',  -- Codi BOM alternatiu
    BOMOPE_0       SMALLINT       NOT NULL DEFAULT 0,   -- Núm operació BOM
    BOMOFS_0       SMALLINT       NOT NULL DEFAULT 0,
    ECCVALMAJ_0    SMALLINT       NOT NULL DEFAULT 0,
    ECCVALMIN_0    SMALLINT       NOT NULL DEFAULT 0,
    -- Quantitats
    EXTQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat planificada
    CPLQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat completada
    QUACPLQTY_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat QC real
    REJCPLQTY_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat rebutjada
    RMNEXTQTY_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat romanent
    BASQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 1,    -- Quantitat base
    UOMEXTQTY_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Qt en unitat llançament
    UOMSTUCOE_0    DECIMAL(15,6)  NOT NULL DEFAULT 1,    -- Coef UOM-STU
    LIKQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,
    LIKQTYCOD_0    SMALLINT       NOT NULL DEFAULT 1,
    -- Unitats
    STU_0          NVARCHAR(3)    NOT NULL DEFAULT 'UN',
    UOM_0          NVARCHAR(3)    NOT NULL DEFAULT 'UN',
    -- Dates
    STRDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    ENDDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    CLODAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    TRKFIRST_0     DATETIME       NOT NULL DEFAULT '1753-01-01',
    TRKFIRSTC_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    TRKLAST_0      DATETIME       NOT NULL DEFAULT '1753-01-01',
    TRKLASTC_0     DATETIME       NOT NULL DEFAULT '1753-01-01',
    -- Trazabilitat
    LOT_0          NVARCHAR(20)   NOT NULL DEFAULT '',
    -- Cost / valoració
    CSTFLG_0       SMALLINT       NOT NULL DEFAULT 2,
    QTYRND_0       SMALLINT       NOT NULL DEFAULT 1,
    -- Categoria, planner, projecte
    TCLCOD_0       NVARCHAR(10)   NOT NULL DEFAULT '',
    PLANNER_0      NVARCHAR(5)    NOT NULL DEFAULT '',
    PJT_0          NVARCHAR(20)   NOT NULL DEFAULT '',
    -- Origen
    VCRNUMORI_0    NVARCHAR(20)   NOT NULL DEFAULT '',
    VCRLINORI_0    INT            NOT NULL DEFAULT 0,
    VCRSEQORI_0    INT            NOT NULL DEFAULT 0,
    VCRTYPORI_0    SMALLINT       NOT NULL DEFAULT 0,
    WIPNUM_0       NVARCHAR(20)   NOT NULL DEFAULT '',
    -- Destinació
    BPCNUM_0       NVARCHAR(15)   NOT NULL DEFAULT '',
    BPCTYPDEN_0    SMALLINT       NOT NULL DEFAULT 0,
    -- Altres
    ABCCLS_0       SMALLINT       NOT NULL DEFAULT 0,
    TSICOD_0       NVARCHAR(20)   NOT NULL DEFAULT '',
    -- Auditoria
    AUUID_0        UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    CREDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    UPDDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    EXPNUM_0       INT            NOT NULL DEFAULT 0,
    ROWID          INT            IDENTITY(1,1) NOT NULL
);
GO

ALTER TABLE dbo.MFGITM ADD CONSTRAINT MFGITM_MFI0 PRIMARY KEY CLUSTERED (MFGNUM_0, MFGLIN_0);
CREATE INDEX MFGITM_MFI1 ON dbo.MFGITM (MFGFCY_0, STRDAT_0);
CREATE INDEX MFGITM_MFI2 ON dbo.MFGITM (MFGNUM_0);
CREATE INDEX MFGITM_ITM ON dbo.MFGITM (ITMREF_0);
GO

/* ============================================================================
   8. TAULA MFGMAT  -  Materials / Components (Work order materials)
       [Estructura verificada amb online-help.sagex3.com/erp/12]
       Claus: MFM0=MFGNUM+MFGLIN+BOMSEQ+ITMREF
              MFM1=MFGFCY+RETDAT
              MFM2=MFGFCY+MFGPIO+RETDAT
              MFM3=MFGNUM+BOMOPE+ITMREF
   ============================================================================ */
CREATE TABLE dbo.MFGMAT (
    MFGNUM_0       NVARCHAR(20)   NOT NULL DEFAULT '',
    MFGLIN_0       INT            NOT NULL DEFAULT 0,
    BOMSEQ_0       SMALLINT       NOT NULL DEFAULT 0,   -- Seqüència BOM
    ITMREF_0       NVARCHAR(30)   NOT NULL DEFAULT '',  -- Article material (FK ITMMASTER)
    MFGFCY_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    PLNFCY_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    BOMSEQORI_0    SMALLINT       NOT NULL DEFAULT 0,
    BOMSHO_0       NVARCHAR(40)   NOT NULL DEFAULT '',  -- Descripció link
    BOMOPE_0       SMALLINT       NOT NULL DEFAULT 0,   -- Núm operació BOM
    BOMOFS_0       SMALLINT       NOT NULL DEFAULT 0,
    -- Estat
    MATSTA_0       SMALLINT       NOT NULL DEFAULT 1,   -- Estat material [menu 363]
    MFGSTA_0       SMALLINT       NOT NULL DEFAULT 1,   -- Estat ordre [menu 317]
    MFMTRKFLG_0    SMALLINT       NOT NULL DEFAULT 1,   -- Flag seguiment [menu 339]
    ALLSTA_0       SMALLINT       NOT NULL DEFAULT 1,   -- Estat allocació [menu 340]
    PRPSTA_0       SMALLINT       NOT NULL DEFAULT 1,   -- Estat preparació [menu 338]
    MFGPIO_0       SMALLINT       NOT NULL DEFAULT 2,
    -- Quantitats
    BASQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 1,    -- Quantitat base
    RETQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat necessitat
    RETQTYORI_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat origen
    USEQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat consumida
    ALLQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat allocada
    SHTQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat ruptura
    STDQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat estàndard
    LIKQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,
    LIKQTYCOD_0    SMALLINT       NOT NULL DEFAULT 1,
    BOMQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,
    BOMSTUCOE_0    DECIMAL(15,6)  NOT NULL DEFAULT 1,
    CUMFLG_0       SMALLINT       NOT NULL DEFAULT 2,
    CUMFXDQTY_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,
    SCA_0          DECIMAL(6,3)   NOT NULL DEFAULT 0,    -- % rebuig
    DEFPOT_0       DECIMAL(9,4)   NOT NULL DEFAULT 100,  -- Títol per defecte (%)
    -- Unitats
    STU_0          NVARCHAR(3)    NOT NULL DEFAULT 'UN',
    BOMUOM_0       NVARCHAR(3)    NOT NULL DEFAULT 'UN',
    QTYCOD_0       SMALLINT       NOT NULL DEFAULT 1,
    QTYRND_0       SMALLINT       NOT NULL DEFAULT 1,
    -- Tipus / mode
    CPNTYP_0       SMALLINT       NOT NULL DEFAULT 1,   -- Tipus component [menu 438]
    ISSMGTCOD_0    SMALLINT       NOT NULL DEFAULT 1,   -- Mode destocatge [menu 724]
    SCOFLG_0       SMALLINT       NOT NULL DEFAULT 1,   -- Tipus aprovisionament [menu 2225]
    STOMGTCOD_0    SMALLINT       NOT NULL DEFAULT 1,
    -- Ubicació / lot preferent
    LOC_0          NVARCHAR(10)   NOT NULL DEFAULT '',
    LOT_0          NVARCHAR(20)   NOT NULL DEFAULT '',
    STA_0          NVARCHAR(12)   NOT NULL DEFAULT '',
    -- Dates
    RETDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',  -- Data necessitat
    TRKFIRST_0     DATETIME       NOT NULL DEFAULT '1753-01-01',
    TRKFIRSTC_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    TRKLAST_0      DATETIME       NOT NULL DEFAULT '1753-01-01',
    TRKLASTC_0     DATETIME       NOT NULL DEFAULT '1753-01-01',
    -- Altres
    PICPRN_0       SMALLINT       NOT NULL DEFAULT 1,
    RELSCATIA_0    SMALLINT       NOT NULL DEFAULT 2,
    PLANNER_0      NVARCHAR(5)    NOT NULL DEFAULT '',
    MFMTEX_0       NVARCHAR(255)  NOT NULL DEFAULT '',
    ECCVALMAJ_0    SMALLINT       NOT NULL DEFAULT 0,
    ECCVALMIN_0    SMALLINT       NOT NULL DEFAULT 0,
    WIPNUM_0       NVARCHAR(20)   NOT NULL DEFAULT '',
    -- Auditoria
    AUUID_0        UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    CREDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    UPDDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    EXPNUM_0       INT            NOT NULL DEFAULT 0,
    ROWID          INT            IDENTITY(1,1) NOT NULL
);
GO

ALTER TABLE dbo.MFGMAT ADD CONSTRAINT MFGMAT_MFM0 PRIMARY KEY CLUSTERED (MFGNUM_0, MFGLIN_0, BOMSEQ_0, ITMREF_0);
CREATE INDEX MFGMAT_MFM1 ON dbo.MFGMAT (MFGFCY_0, RETDAT_0);
CREATE INDEX MFGMAT_MFM2 ON dbo.MFGMAT (MFGFCY_0, MFGPIO_0, RETDAT_0);
CREATE INDEX MFGMAT_MFM3 ON dbo.MFGMAT (MFGNUM_0, BOMOPE_0, ITMREF_0);
CREATE INDEX MFGMAT_ITM ON dbo.MFGMAT (ITMREF_0);
GO

/* ============================================================================
   9. TAULA MFGOPE  -  Operacions ordre fabricació (Work order operations)
       [Esquema basat en convencions X3, no verificat verbatim per documentació]
       Claus: MFO0=MFGNUM+OPENUM | MFO1=MFGFCY+STRDAT | MFO2=MFGNUM+WST
   ============================================================================ */
CREATE TABLE dbo.MFGOPE (
    MFGNUM_0       NVARCHAR(20)   NOT NULL DEFAULT '',
    OPENUM_0       SMALLINT       NOT NULL DEFAULT 0,   -- Núm operació (PK comp.)
    MFGFCY_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    PLNFCY_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    -- Centre de treball
    WST_0          NVARCHAR(10)   NOT NULL DEFAULT '',  -- Centre de treball
    WSTREP_0       NVARCHAR(10)   NOT NULL DEFAULT '',  -- Centre treball reemplaç
    LAB_0          NVARCHAR(10)   NOT NULL DEFAULT '',  -- Mà d'obra
    LABREP_0       NVARCHAR(10)   NOT NULL DEFAULT '',
    -- Descripció / tipus
    OPEDES_0       NVARCHAR(40)   NOT NULL DEFAULT '',  -- Descripció operació
    OPETYP_0       SMALLINT       NOT NULL DEFAULT 1,   -- Tipus operació
    OPESTA_0       SMALLINT       NOT NULL DEFAULT 1,   -- Estat
    MFGSTA_0       SMALLINT       NOT NULL DEFAULT 1,
    MFOTRKFLG_0    SMALLINT       NOT NULL DEFAULT 1,
    MFGPIO_0       SMALLINT       NOT NULL DEFAULT 2,
    -- Quantitats / temps
    EXTQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat planificada
    EXTSTUQTY_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat planificada (STU)
    CPLQTY_0       DECIMAL(19,4)  NOT NULL DEFAULT 0,    -- Quantitat completada
    REJCPLQTY_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,
    QUACPLQTY_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,
    RMNEXTQTY_0    DECIMAL(19,4)  NOT NULL DEFAULT 0,
    EXTOPETIM_0    DECIMAL(15,4)  NOT NULL DEFAULT 0,    -- Temps operació planificat
    EXTSETTIM_0    DECIMAL(15,4)  NOT NULL DEFAULT 0,    -- Temps preparació planificat
    CPLOPETIM_0    DECIMAL(15,4)  NOT NULL DEFAULT 0,    -- Temps operació real
    CPLSETTIM_0    DECIMAL(15,4)  NOT NULL DEFAULT 0,    -- Temps preparació real
    OPEFOCRD_0     SMALLINT       NOT NULL DEFAULT 0,    -- Solapament
    OPENXT_0       SMALLINT       NOT NULL DEFAULT 0,    -- Operació següent
    -- Dates
    STRDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    ENDDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    STRTIM_0       DECIMAL(15,4)  NOT NULL DEFAULT 0,    -- Hora inici
    ENDTIM_0       DECIMAL(15,4)  NOT NULL DEFAULT 0,    -- Hora fi
    EARSTRDAT_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    LATENDDAT_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    CLODAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    TRKFIRST_0     DATETIME       NOT NULL DEFAULT '1753-01-01',
    TRKFIRSTC_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    TRKLAST_0      DATETIME       NOT NULL DEFAULT '1753-01-01',
    TRKLASTC_0     DATETIME       NOT NULL DEFAULT '1753-01-01',
    -- Unitat / capacitat
    STU_0          NVARCHAR(3)    NOT NULL DEFAULT 'UN',
    TIMU_0         NVARCHAR(3)    NOT NULL DEFAULT 'H',  -- Unitat temps
    EFFCAP_0       DECIMAL(15,4)  NOT NULL DEFAULT 0,
    -- Auditoria
    AUUID_0        UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    CREDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    CREUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    UPDDAT_0       DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDDATTIM_0    DATETIME       NOT NULL DEFAULT '1753-01-01',
    UPDUSR_0       NVARCHAR(5)    NOT NULL DEFAULT '',
    EXPNUM_0       INT            NOT NULL DEFAULT 0,
    ROWID          INT            IDENTITY(1,1) NOT NULL
);
GO

ALTER TABLE dbo.MFGOPE ADD CONSTRAINT MFGOPE_MFO0 PRIMARY KEY CLUSTERED (MFGNUM_0, OPENUM_0);
CREATE INDEX MFGOPE_MFO1 ON dbo.MFGOPE (MFGFCY_0, STRDAT_0);
CREATE INDEX MFGOPE_MFO2 ON dbo.MFGOPE (MFGNUM_0, WST_0);
GO

PRINT '>>> Totes les taules creades correctament';
GO

/* ============================================================================
   10. DADES DE PROVA  -  Escenari coherent
   ----------------------------------------------------------------------------
   Centre: FCY01 (Factoria Vilafranca)
   Articles:
     - PFA001 (producte acabat: Cervesa Artesana 33cl)
     - SF001  (semielaborat: Most fermentat)
     - SF002  (semielaborat: Etiqueta+Tap muntat)
     - MP001  (matèria primera: Malta)
     - MP002  (matèria primera: Llúpol)
     - MP003  (matèria primera: Aigua tractada)
     - MP004  (matèria primera: Ampolla buida 33cl)
     - MP005  (matèria primera: Tap corona)
     - MP006  (matèria primera: Etiqueta)

   Ordres de fabricació:
     - WO000001: PFA001 x 1000 unitats, ESTAT FERM PENDENT
     - WO000002: PFA001 x  500 unitats, EN CURS al 60%
     - WO000003: SF001  x 2000 litres,  TANCADA AMB COST
   ============================================================================ */

DECLARE @now DATETIME = GETDATE();
DECLARE @today DATETIME = CAST(GETDATE() AS DATE);

-- ---------------------------------------------------------------------------
-- FACILITY
-- ---------------------------------------------------------------------------
INSERT INTO dbo.FACILITY
    (FCY_0, FCYNAM_0, FCYSHO_0, CPY_0, LEGCPY_0, MFGFLG_0, STOFLG_0, SALFLG_0, PURFLG_0,
     FCYCRY_0, CRY_0, ADDLIG_0, ZIP_0, CTY_0, TEL_0,
     CREDAT_0, CREDATTIM_0, CREUSR_0, UPDDAT_0, UPDDATTIM_0, UPDUSR_0)
VALUES
    ('FCY01', 'Factoria Vilafranca', 'VLF', 'CPY01', 1, 1, 1, 1, 1,
     'ESP', 'Espanya', 'Polígon Industrial Sant Pere, nau 12', '08720', 'Vilafranca del Penedès', '+34 938 900 000',
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('FCY02', 'Magatzem Central Barcelona', 'BCN', 'CPY01', 1, 2, 1, 1, 1,
     'ESP', 'Espanya', 'Carrer de la Marina 200', '08013', 'Barcelona', '+34 932 100 000',
     @today, @now, 'ADMIN', @today, @now, 'ADMIN');

-- ---------------------------------------------------------------------------
-- ITMMASTER
-- ---------------------------------------------------------------------------
INSERT INTO dbo.ITMMASTER
    (ITMREF_0, ITMDES1_0, DES1AXX_0, TCLCOD_0, ITMSTA_0, ITMKND_0,
     STOMGTCOD_0, LOTMGTCOD_0, STU_0, EUU_0, PUU_0,
     ITMWEI_0, ITMWEIU_0, BUY_0, SAL_0, MFG_0,
     PURBASPRI_0, BASPRI_0, STOCUR_0,
     PLNFCY_0, BOMNUM_0, ROUNUM_0, PLNMOD_0, LTI_0,
     CREDAT_0, CREDATTIM_0, CREUSR_0, UPDDAT_0, UPDDATTIM_0, UPDUSR_0)
VALUES
    -- Producte acabat
    ('PFA001', 'Cervesa Artesana 33cl', 'CERV 33CL', 'PFA', 1, 1,
     1, 2, 'UN', 'UN', 'UN', 0.350, 'KG', 2, 1, 1,
     0, 1.85, 0.72, 'FCY01', 'BOM_PFA001', 'ROU_PFA001', 3, 2,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    -- Semielaborats
    ('SF001',  'Most fermentat', 'MOST', 'SF', 1, 1,
     1, 3, 'L',  'L',  'L',  1.045, 'KG', 2, 2, 1,
     0, 0, 0.41, 'FCY01', 'BOM_SF001', 'ROU_SF001', 3, 5,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('SF002',  'Etiqueta+Tap muntat', 'ETIQ', 'SF', 1, 1,
     1, 2, 'UN', 'UN', 'UN', 0.005, 'KG', 2, 2, 1,
     0, 0, 0.03, 'FCY01', 'BOM_SF002', '', 3, 1,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    -- Matèries primeres
    ('MP001', 'Malta Pilsen', 'MALTA', 'MP', 1, 1,
     1, 2, 'KG', 'KG', 'KG', 1, 'KG', 1, 2, 2,
     1.20, 0, 1.25, 'FCY01', '', '', 2, 7,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('MP002', 'Llúpol Saaz', 'LLUPOL', 'MP', 1, 1,
     1, 2, 'KG', 'KG', 'KG', 1, 'KG', 1, 2, 2,
     18.00, 0, 19.50, 'FCY01', '', '', 2, 14,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('MP003', 'Aigua tractada', 'AIGUA', 'MP', 1, 1,
     1, 1, 'L',  'L',  'L',  1, 'KG', 1, 2, 2,
     0.001, 0, 0.001, 'FCY01', '', '', 2, 1,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('MP004', 'Ampolla vidre 33cl', 'AMP33', 'MP', 1, 1,
     1, 2, 'UN', 'UN', 'UN', 0.250, 'KG', 1, 2, 2,
     0.08, 0, 0.085, 'FCY01', '', '', 2, 10,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('MP005', 'Tap corona daurat', 'TAP', 'MP', 1, 1,
     1, 2, 'UN', 'UN', 'UN', 0.002, 'KG', 1, 2, 2,
     0.015, 0, 0.018, 'FCY01', '', '', 2, 5,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('MP006', 'Etiqueta paper kraft', 'ETIQ-K', 'MP', 1, 1,
     1, 2, 'UN', 'UN', 'UN', 0.001, 'KG', 1, 2, 2,
     0.025, 0, 0.027, 'FCY01', '', '', 2, 7,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN');

-- ---------------------------------------------------------------------------
-- ITMFACILIT (articles assignats al centre FCY01)
-- ---------------------------------------------------------------------------
INSERT INTO dbo.ITMFACILIT
    (ITMREF_0, STOFCY_0, PLNFCY_0, REOMGTCOD_0, REOTSD_0, REOMINQTY_0, REOMAXQTY_0, REOLOT_0, LTI_0, BUY_0, SAL_0, MFG_0,
     CREDAT_0, CREDATTIM_0, CREUSR_0, UPDDAT_0, UPDDATTIM_0, UPDUSR_0)
VALUES
    ('PFA001', 'FCY01', 'FCY01', 4, 200, 100, 5000, 500, 2, 2, 1, 1, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('SF001',  'FCY01', 'FCY01', 4, 500, 200, 3000, 1000, 5, 2, 2, 1, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('SF002',  'FCY01', 'FCY01', 4, 1000, 500, 10000, 2000, 1, 2, 2, 1, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('MP001',  'FCY01', 'FCY01', 2, 500, 200, 2000, 250, 7,  1, 2, 2, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('MP002',  'FCY01', 'FCY01', 2, 50,  20,  200,  25,  14, 1, 2, 2, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('MP003',  'FCY01', 'FCY01', 4, 1000, 500, 5000, 0,   1,  1, 2, 2, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('MP004',  'FCY01', 'FCY01', 2, 2000, 1000, 20000, 5000, 10, 1, 2, 2, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('MP005',  'FCY01', 'FCY01', 2, 2000, 1000, 20000, 5000, 5,  1, 2, 2, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('MP006',  'FCY01', 'FCY01', 2, 2000, 1000, 20000, 5000, 7,  1, 2, 2, @today, @now, 'ADMIN', @today, @now, 'ADMIN');

-- ---------------------------------------------------------------------------
-- STOCK (estoc inicial coherent per fabricar les OFs)
-- ---------------------------------------------------------------------------
INSERT INTO dbo.STOCK
    (STOFCY_0, ITMREF_0, PCU_0, LOC_0, LOT_0, STA_0, QTYSTU_0, QTYPCU_0,
     CREDAT_0, CREDATTIM_0, CREUSR_0, UPDDAT_0, UPDDATTIM_0, UPDUSR_0)
VALUES
    ('FCY01', 'MP001', 'KG', 'MP01', 'L2026MP001A', 'A', 1500.0000, 1500.0000, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('FCY01', 'MP002', 'KG', 'MP01', 'L2026MP002A', 'A', 80.0000,   80.0000,   @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('FCY01', 'MP003', 'L',  'MP02', '',            'A', 4500.0000, 4500.0000, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('FCY01', 'MP004', 'UN', 'MP03', 'L2026MP004A', 'A', 8000.0000, 8000.0000, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('FCY01', 'MP005', 'UN', 'MP03', 'L2026MP005A', 'A', 12000.0000, 12000.0000, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('FCY01', 'MP006', 'UN', 'MP03', 'L2026MP006A', 'A', 8500.0000, 8500.0000, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    -- Semielaborats (per OF en curs)
    ('FCY01', 'SF001', 'L',  'SF01', 'L2026SF001A', 'A', 350.0000, 350.0000, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('FCY01', 'SF002', 'UN', 'SF02', '',            'A', 1200.0000, 1200.0000, @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    -- Producte acabat (de la OF tancada)
    ('FCY01', 'PFA001','UN', 'PF01', 'L2026PFA01A', 'A', 250.0000, 250.0000, @today, @now, 'ADMIN', @today, @now, 'ADMIN');

-- ---------------------------------------------------------------------------
-- MFGHEAD - 3 ordres de fabricació
-- ---------------------------------------------------------------------------
INSERT INTO dbo.MFGHEAD
    (MFGNUM_0, MFGFCY_0, PLNFCY_0, MFGSTA_0, MFGTRKFLG_0, MFGMOD_0, MFGPIO_0,
     EXTQTY_0, CPLQTY_0, RMNEXTQTY_0, AVAMFGQTY_0, STU_0,
     ROUNUM_0, STRDAT_0, ENDDAT_0, OBJDAT_0,
     ITMLINNBR_0, MATLINNBR_0, OPELINNBR_0,
     CFMFLG_0, SCDFLG_0, SCDMOD_0, ALLSTA_0, PRPSTA_0,
     CREDAT_0, CREDATTIM_0, CREUSR_0, UPDDAT_0, UPDDATTIM_0, UPDUSR_0)
VALUES
    -- OF 1: en ferm, encara no iniciada
    ('WO000001', 'FCY01', 'FCY01', 1, 1, 1, 2,
     1000.0000, 0.0000, 1000.0000, 1000.0000, 'UN',
     'ROU_PFA001', DATEADD(DAY, 3, @today), DATEADD(DAY, 5, @today), DATEADD(DAY, 7, @today),
     1, 4, 3,
     1, 2, 1, 1, 1,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    -- OF 2: en curs (60% completada)
    ('WO000002', 'FCY01', 'FCY01', 1, 3, 1, 1,
     500.0000, 300.0000, 200.0000, 200.0000, 'UN',
     'ROU_PFA001', DATEADD(DAY, -2, @today), DATEADD(DAY, 1, @today), DATEADD(DAY, 1, @today),
     1, 4, 3,
     1, 2, 1, 3, 3,
     DATEADD(DAY, -5, @today), DATEADD(DAY, -5, @now), 'ADMIN', @today, @now, 'JORDI'),
    -- OF 3: tancada amb cost calculat
    ('WO000003', 'FCY01', 'FCY01', 4, 4, 1, 2,
     2000.0000, 1980.0000, 0.0000, 0.0000, 'L',
     'ROU_SF001', DATEADD(DAY, -15, @today), DATEADD(DAY, -10, @today), DATEADD(DAY, -10, @today),
     1, 3, 2,
     1, 3, 1, 4, 4,
     DATEADD(DAY, -20, @today), DATEADD(DAY, -20, @now), 'ADMIN', DATEADD(DAY, -8, @today), DATEADD(DAY, -8, @now), 'JORDI');

-- Actualitzo dates de tancament i seguiment per a la OF tancada i la OF en curs
UPDATE dbo.MFGHEAD SET
    CLODAT_0 = DATEADD(DAY, -8, @today),
    TRKFIRST_0 = DATEADD(DAY, -14, @today),
    TRKFIRSTC_0 = DATEADD(DAY, -14, @today),
    TRKLAST_0 = DATEADD(DAY, -10, @today),
    TRKLASTC_0 = DATEADD(DAY, -10, @today),
    MATCLENBR_0 = 3,
    OPECLENBR_0 = 2,
    ITMCLENBR_0 = 1
WHERE MFGNUM_0 = 'WO000003';

UPDATE dbo.MFGHEAD SET
    TRKFIRST_0 = DATEADD(DAY, -1, @today),
    TRKFIRSTC_0 = DATEADD(DAY, -1, @today),
    TRKLAST_0 = @today,
    TRKLASTC_0 = @today
WHERE MFGNUM_0 = 'WO000002';

-- ---------------------------------------------------------------------------
-- MFGITM - Productes a fabricar (un per OF)
-- ---------------------------------------------------------------------------
INSERT INTO dbo.MFGITM
    (MFGNUM_0, MFGLIN_0, ITMLIN_0, MFGFCY_0, PLNFCY_0, ITMREF_0, MFGDES_0,
     ITMTYP_0, ITMSTA_0, MFGSTA_0, MFITRKFLG_0,
     EXTQTY_0, CPLQTY_0, RMNEXTQTY_0, BASQTY_0, UOMEXTQTY_0, UOMSTUCOE_0,
     STU_0, UOM_0, STRDAT_0, ENDDAT_0, TCLCOD_0,
     FMI_0, BOMALT_0, BOMOPE_0,
     CREDAT_0, CREDATTIM_0, CREUSR_0, UPDDAT_0, UPDDATTIM_0, UPDUSR_0)
VALUES
    ('WO000001', 1000, 1, 'FCY01', 'FCY01', 'PFA001', 'Cervesa Artesana 33cl',
     1, 1, 1, 1,
     1000.0000, 0.0000, 1000.0000, 1.0000, 1000.0000, 1.000000,
     'UN', 'UN', DATEADD(DAY, 3, @today), DATEADD(DAY, 5, @today), 'PFA',
     1, '', 0,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('WO000002', 1000, 1, 'FCY01', 'FCY01', 'PFA001', 'Cervesa Artesana 33cl',
     1, 1, 1, 3,
     500.0000, 300.0000, 200.0000, 1.0000, 500.0000, 1.000000,
     'UN', 'UN', DATEADD(DAY, -2, @today), DATEADD(DAY, 1, @today), 'PFA',
     1, '', 0,
     DATEADD(DAY, -5, @today), DATEADD(DAY, -5, @now), 'ADMIN', @today, @now, 'JORDI'),
    ('WO000003', 1000, 1, 'FCY01', 'FCY01', 'SF001', 'Most fermentat',
     1, 4, 4, 4,
     2000.0000, 1980.0000, 0.0000, 1.0000, 2000.0000, 1.000000,
     'L',  'L', DATEADD(DAY, -15, @today), DATEADD(DAY, -10, @today), 'SF',
     1, '', 0,
     DATEADD(DAY, -20, @today), DATEADD(DAY, -20, @now), 'ADMIN', DATEADD(DAY, -8, @today), DATEADD(DAY, -8, @now), 'JORDI');

-- ---------------------------------------------------------------------------
-- MFGMAT - Components de cada OF
-- ---------------------------------------------------------------------------
-- WO000001: PFA001 x 1000 → 1000 SF001(L 0.33) + 1000 SF002 + 1000 MP004 + 1000 MP005
-- Fórmula simplificada: cada cervesa = 0.33L most + 1 etiq muntada + 1 ampolla + 1 tap
INSERT INTO dbo.MFGMAT
    (MFGNUM_0, MFGLIN_0, BOMSEQ_0, ITMREF_0, MFGFCY_0, PLNFCY_0,
     BOMSHO_0, BOMOPE_0, MATSTA_0, MFGSTA_0, MFMTRKFLG_0, ALLSTA_0, PRPSTA_0,
     BASQTY_0, RETQTY_0, USEQTY_0, ALLQTY_0, STDQTY_0,
     STU_0, BOMUOM_0, BOMSTUCOE_0, CPNTYP_0, ISSMGTCOD_0,
     RETDAT_0, SCA_0, DEFPOT_0,
     CREDAT_0, CREDATTIM_0, CREUSR_0, UPDDAT_0, UPDDATTIM_0, UPDUSR_0)
VALUES
    -- WO000001 components
    ('WO000001', 1000, 1, 'SF001', 'FCY01', 'FCY01', 'Most fermentat',     10, 1, 1, 1, 1, 1,
     1.0000, 330.0000, 0, 0, 330.0000, 'L', 'L', 1, 1, 1, DATEADD(DAY, 3, @today), 0, 100,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('WO000001', 1000, 2, 'SF002', 'FCY01', 'FCY01', 'Etiqueta+Tap muntat', 20, 1, 1, 1, 1, 1,
     1.0000, 1000.0000, 0, 0, 1000.0000, 'UN', 'UN', 1, 1, 1, DATEADD(DAY, 4, @today), 0, 100,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('WO000001', 1000, 3, 'MP004', 'FCY01', 'FCY01', 'Ampolla vidre 33cl', 30, 1, 1, 1, 1, 1,
     1.0000, 1010.0000, 0, 0, 1010.0000, 'UN', 'UN', 1, 1, 1, DATEADD(DAY, 4, @today), 1.0, 100,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('WO000001', 1000, 4, 'MP005', 'FCY01', 'FCY01', 'Tap corona daurat', 30, 1, 1, 1, 1, 1,
     1.0000, 1005.0000, 0, 0, 1005.0000, 'UN', 'UN', 1, 1, 1, DATEADD(DAY, 4, @today), 0.5, 100,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),

    -- WO000002 components (consumits parcialment, 60% del total previst)
    ('WO000002', 1000, 1, 'SF001', 'FCY01', 'FCY01', 'Most fermentat',     10, 1, 1, 3, 4, 3,
     1.0000, 165.0000, 100.0000, 65.0000, 165.0000, 'L', 'L', 1, 1, 1, DATEADD(DAY, -2, @today), 0, 100,
     DATEADD(DAY, -5, @today), DATEADD(DAY, -5, @now), 'ADMIN', @today, @now, 'JORDI'),
    ('WO000002', 1000, 2, 'SF002', 'FCY01', 'FCY01', 'Etiqueta+Tap muntat', 20, 1, 1, 3, 4, 3,
     1.0000, 500.0000, 300.0000, 200.0000, 500.0000, 'UN', 'UN', 1, 1, 1, DATEADD(DAY, -1, @today), 0, 100,
     DATEADD(DAY, -5, @today), DATEADD(DAY, -5, @now), 'ADMIN', @today, @now, 'JORDI'),
    ('WO000002', 1000, 3, 'MP004', 'FCY01', 'FCY01', 'Ampolla vidre 33cl', 30, 1, 1, 3, 4, 3,
     1.0000, 505.0000, 302.0000, 203.0000, 505.0000, 'UN', 'UN', 1, 1, 1, DATEADD(DAY, -1, @today), 1.0, 100,
     DATEADD(DAY, -5, @today), DATEADD(DAY, -5, @now), 'ADMIN', @today, @now, 'JORDI'),
    ('WO000002', 1000, 4, 'MP005', 'FCY01', 'FCY01', 'Tap corona daurat', 30, 1, 1, 3, 4, 3,
     1.0000, 502.0000, 301.0000, 201.0000, 502.0000, 'UN', 'UN', 1, 1, 1, DATEADD(DAY, -1, @today), 0.5, 100,
     DATEADD(DAY, -5, @today), DATEADD(DAY, -5, @now), 'ADMIN', @today, @now, 'JORDI'),

    -- WO000003 components (tancada, tot consumit)
    ('WO000003', 1000, 1, 'MP001', 'FCY01', 'FCY01', 'Malta Pilsen',  10, 4, 4, 4, 4, 4,
     1.0000, 400.0000, 405.0000, 0, 400.0000, 'KG', 'KG', 1, 1, 1, DATEADD(DAY, -14, @today), 1.0, 100,
     DATEADD(DAY, -20, @today), DATEADD(DAY, -20, @now), 'ADMIN', DATEADD(DAY, -10, @today), DATEADD(DAY, -10, @now), 'JORDI'),
    ('WO000003', 1000, 2, 'MP002', 'FCY01', 'FCY01', 'Llúpol Saaz',   10, 4, 4, 4, 4, 4,
     1.0000, 8.0000,   8.2000,   0, 8.0000,   'KG', 'KG', 1, 1, 1, DATEADD(DAY, -14, @today), 0.5, 100,
     DATEADD(DAY, -20, @today), DATEADD(DAY, -20, @now), 'ADMIN', DATEADD(DAY, -10, @today), DATEADD(DAY, -10, @now), 'JORDI'),
    ('WO000003', 1000, 3, 'MP003', 'FCY01', 'FCY01', 'Aigua tractada', 10, 4, 4, 4, 4, 4,
     1.0000, 2200.0000, 2185.0000, 0, 2200.0000, 'L', 'L', 1, 1, 1, DATEADD(DAY, -14, @today), 0.5, 100,
     DATEADD(DAY, -20, @today), DATEADD(DAY, -20, @now), 'ADMIN', DATEADD(DAY, -10, @today), DATEADD(DAY, -10, @now), 'JORDI');

-- ---------------------------------------------------------------------------
-- MFGOPE - Operacions de ruta per OF
-- ---------------------------------------------------------------------------
INSERT INTO dbo.MFGOPE
    (MFGNUM_0, OPENUM_0, MFGFCY_0, PLNFCY_0, WST_0, LAB_0, OPEDES_0,
     OPETYP_0, OPESTA_0, MFGSTA_0, MFOTRKFLG_0,
     EXTQTY_0, EXTSTUQTY_0, CPLQTY_0, RMNEXTQTY_0,
     EXTOPETIM_0, EXTSETTIM_0, CPLOPETIM_0, CPLSETTIM_0,
     STRDAT_0, ENDDAT_0, STU_0, TIMU_0, EFFCAP_0,
     CREDAT_0, CREDATTIM_0, CREUSR_0, UPDDAT_0, UPDDATTIM_0, UPDUSR_0)
VALUES
    -- WO000001
    ('WO000001', 10, 'FCY01', 'FCY01', 'WST-ELAB', 'OPER1', 'Maceració i fermentació',
     1, 1, 1, 1, 1000.0000, 1000.0000, 0.0000, 1000.0000,
     8.0000, 2.0000, 0.0000, 0.0000,
     DATEADD(DAY, 3, @today), DATEADD(DAY, 4, @today), 'UN', 'H', 1.0000,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('WO000001', 20, 'FCY01', 'FCY01', 'WST-EMB', 'OPER2', 'Embotellament',
     1, 1, 1, 1, 1000.0000, 1000.0000, 0.0000, 1000.0000,
     4.0000, 1.0000, 0.0000, 0.0000,
     DATEADD(DAY, 4, @today), DATEADD(DAY, 4, @today), 'UN', 'H', 1.0000,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),
    ('WO000001', 30, 'FCY01', 'FCY01', 'WST-EMB', 'OPER2', 'Etiquetatge',
     1, 1, 1, 1, 1000.0000, 1000.0000, 0.0000, 1000.0000,
     3.0000, 0.5000, 0.0000, 0.0000,
     DATEADD(DAY, 5, @today), DATEADD(DAY, 5, @today), 'UN', 'H', 1.0000,
     @today, @now, 'ADMIN', @today, @now, 'ADMIN'),

    -- WO000002
    ('WO000002', 10, 'FCY01', 'FCY01', 'WST-ELAB', 'OPER1', 'Maceració i fermentació',
     1, 3, 1, 3, 500.0000, 500.0000, 300.0000, 200.0000,
     4.0000, 2.0000, 2.4000, 2.0000,
     DATEADD(DAY, -2, @today), DATEADD(DAY, -1, @today), 'UN', 'H', 1.0000,
     DATEADD(DAY, -5, @today), DATEADD(DAY, -5, @now), 'ADMIN', @today, @now, 'JORDI'),
    ('WO000002', 20, 'FCY01', 'FCY01', 'WST-EMB', 'OPER2', 'Embotellament',
     1, 3, 1, 3, 500.0000, 500.0000, 300.0000, 200.0000,
     2.0000, 1.0000, 1.2000, 1.0000,
     DATEADD(DAY, -1, @today), @today, 'UN', 'H', 1.0000,
     DATEADD(DAY, -5, @today), DATEADD(DAY, -5, @now), 'ADMIN', @today, @now, 'JORDI'),
    ('WO000002', 30, 'FCY01', 'FCY01', 'WST-EMB', 'OPER2', 'Etiquetatge',
     1, 1, 1, 1, 500.0000, 500.0000, 0.0000, 500.0000,
     1.5000, 0.5000, 0.0000, 0.0000,
     @today, DATEADD(DAY, 1, @today), 'UN', 'H', 1.0000,
     DATEADD(DAY, -5, @today), DATEADD(DAY, -5, @now), 'ADMIN', @today, @now, 'JORDI'),

    -- WO000003 (tancada)
    ('WO000003', 10, 'FCY01', 'FCY01', 'WST-ELAB', 'OPER1', 'Maceració',
     1, 4, 4, 4, 2000.0000, 2000.0000, 1980.0000, 0.0000,
     12.0000, 2.0000, 11.8000, 2.1000,
     DATEADD(DAY, -15, @today), DATEADD(DAY, -13, @today), 'L', 'H', 1.0000,
     DATEADD(DAY, -20, @today), DATEADD(DAY, -20, @now), 'ADMIN', DATEADD(DAY, -10, @today), DATEADD(DAY, -10, @now), 'JORDI'),
    ('WO000003', 20, 'FCY01', 'FCY01', 'WST-ELAB', 'OPER1', 'Fermentació',
     1, 4, 4, 4, 2000.0000, 2000.0000, 1980.0000, 0.0000,
     72.0000, 0.5000, 70.0000, 0.5000,
     DATEADD(DAY, -13, @today), DATEADD(DAY, -10, @today), 'L', 'H', 1.0000,
     DATEADD(DAY, -20, @today), DATEADD(DAY, -20, @now), 'ADMIN', DATEADD(DAY, -10, @today), DATEADD(DAY, -10, @now), 'JORDI');

GO

/* ============================================================================
   11. VERIFICACIÓ FINAL
   ============================================================================ */
PRINT '';
PRINT '=============================================================';
PRINT '>>> RESUM DE DADES INSERIDES';
PRINT '=============================================================';

SELECT 'FACILITY'   AS Taula, COUNT(*) AS Files FROM dbo.FACILITY
UNION ALL SELECT 'ITMMASTER',  COUNT(*) FROM dbo.ITMMASTER
UNION ALL SELECT 'ITMFACILIT', COUNT(*) FROM dbo.ITMFACILIT
UNION ALL SELECT 'STOCK',      COUNT(*) FROM dbo.STOCK
UNION ALL SELECT 'MFGHEAD',    COUNT(*) FROM dbo.MFGHEAD
UNION ALL SELECT 'MFGITM',     COUNT(*) FROM dbo.MFGITM
UNION ALL SELECT 'MFGMAT',     COUNT(*) FROM dbo.MFGMAT
UNION ALL SELECT 'MFGOPE',     COUNT(*) FROM dbo.MFGOPE;

PRINT '';
PRINT '>>> OFs creades:';
SELECT
    H.MFGNUM_0      AS OF_Num,
    H.MFGFCY_0      AS Centre,
    I.ITMREF_0      AS Article,
    I.MFGDES_0      AS Descripcio,
    H.EXTQTY_0      AS Planificada,
    H.CPLQTY_0      AS Completada,
    H.STU_0         AS Unitat,
    CASE H.MFGSTA_0 WHEN 1 THEN 'Ferm' WHEN 2 THEN 'Planificat'
                    WHEN 3 THEN 'Tancat' WHEN 4 THEN 'Tancat+Cost' END AS Estat,
    CASE H.MFGTRKFLG_0 WHEN 1 THEN 'Pendent' WHEN 2 THEN 'Impres'
                       WHEN 3 THEN 'En curs' WHEN 4 THEN 'Acabat' END AS Seguiment
FROM dbo.MFGHEAD H
INNER JOIN dbo.MFGITM I ON I.MFGNUM_0 = H.MFGNUM_0;

PRINT '';
PRINT '>>> Script finalitzat correctament. BD SageX3_Demo llesta per usar.';
GO
