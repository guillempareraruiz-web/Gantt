/* ============================================================================
   ANONIMIZACION DE DATOS SENSIBLES  -  Sage200 / LogicClass
   ----------------------------------------------------------------------------
   Sustituye nombres, razones sociales, CIF/DNI, domicilios, telefonos, emails,
   logins y credenciales reales por valores genericos DETERMINISTAS (derivados
   de la clave de cada fila), para trabajar/mostrar la copia sin divulgar datos
   del cliente.

   Reutilizable en cualquier BD de cliente. NO toca claves (CodigoCliente,
   CodigoProveedor, Operario, IdEmpleado...), solo valores de texto: las
   relaciones del ERP quedan intactas.

   ENTIDADES:
     - Clientes        -> RazonSocial, Nombre, Domicilio, CIF, tel/fax, emails, IBAN.
     - Proveedores     -> idem.
     - Operarios (ERP) -> NombreOperario, domicilio, tel, emails.
     - lsysUsuarios    -> login, nick, host, emails, y VACIA password + tokens
                          OAuth (credenciales).
     - EmpleadoNomina  -> Dni / DNIExtranjero / Nif (datos personales de nomina).
     - DOCUMENTOS      -> cabeceras de albaranes/pedidos/ofertas de cliente y
                          proveedor: propagan (copian) el nombre/CIF/domicilio/
                          IBAN del cliente, asi que se REESCRIBEN con el valor ya
                          anonimizado, para que el documento no muestre el real.
     - BANCARIO        -> IBAN/CCC/banco/oficina/tarjeta/titular en fichas, cartera
                          (CarteraEfectos, HistoricoCartera), resumenes y BancosConta.
     - PERSONAS/RRHH   -> Personas, ClientesProveedores, RHH_Personas,
                          RHH_Candidatos, LcClienteContactos: nombres, apellidos,
                          DNI/CIF, padres, representante, tel, emails.
     - Empresas        -> ficha de empresa(s) del ERP: nombre, anagrama, CIF (por
                          CodigoEmpresa) + EmpresasDomicilios (direccion/tel/email);
                          datos bancarios de Empresas se vacian en el bloque 7.

   NO TOCA:
     - Tablas FS_PL_* (Planner): fuera de alcance por decision.
     - OrdenesFabricacion: no guarda nombre de cliente (solo codigo).

   NOTAS APRENDIDAS (por que el script es asi):
     - TRIGGERS: se desactivan al principio y se reactivan al final (bloque 0/9).
       Sin esto, CarteraEfectos (160k filas) tarda >20 min y algunos UPDATE fallan.
     - CLAVES CON DNI/CIF: en Personas y ClientesProveedores el DNI/CIF forma parte
       de un indice unico -> se asigna UNICO por fila con ROW_NUMBER (un valor fijo
       daria PK duplicada).
     - COLUMNAS text NOT NULL (tokens OAuth): se vacian con '' (NULL falla).

   USO:
     1. Trabajar sobre copia local (o backup previo). Es IRREVERSIBLE.
     2. Ajustar el USE de abajo al nombre de la BD del ERP en cada cliente.
     3. Ejecutar entero.

   Todo por SQL dinamico con guardas OBJECT_ID/COL_LENGTH: los campos/tablas que
   no existan en una BD concreta se saltan, no rompen el script.
   ============================================================================ */

SET NOCOUNT ON;
USE Reisopack;   -- <<< AJUSTAR al nombre de la BD del ERP en cada cliente
GO
SET NOCOUNT ON;
DECLARE @sql nvarchar(max);

/* ==========================================================================
   0) DESACTIVAR TRIGGERS de las tablas a modificar.
      IMPRESCINDIBLE: estas tablas tienen triggers _SyncIU/_SyncDelete (sincro
      LogicClass) y de negocio (AcumRiesgo*, control de cartera...) que en un
      UPDATE masivo (a) son inutiles en una copia local y (b) hacen que un
      UPDATE de 160k filas tarde >20 min disparandose fila a fila, o fallen por
      PK duplicada. Se desactivan aqui y se REACTIVAN en el bloque 9 (final).
   ========================================================================== */
DECLARE @tabsTrig TABLE (Orden int IDENTITY, Tabla sysname);
INSERT INTO @tabsTrig (Tabla) VALUES
  ('Clientes'),('Proveedores'),('Operarios'),('lsysUsuarios'),('EmpleadoNomina'),
  ('CabeceraAlbaranCliente'),('CabeceraPedidoCliente'),('CabeceraOfertaCliente'),
  ('CabeceraAlbaranProveedor'),('CabeceraPedidoProveedor'),
  ('ResumenCliente'),('ResumenProveedor'),('CarteraEfectos'),('HistoricoCartera'),
  ('BancosConta'),('Personas'),('ClientesProveedores'),('RHH_Personas'),
  ('RHH_Candidatos'),('LcClienteContactos'),('Empresas'),('EmpresasDomicilios');

DECLARE @tt int = 1, @ttn int = (SELECT MAX(Orden) FROM @tabsTrig);
DECLARE @ttTab sysname;
PRINT '=== Desactivando triggers ===';
WHILE @tt <= @ttn
BEGIN
    SELECT @ttTab=Tabla FROM @tabsTrig WHERE Orden=@tt;
    IF OBJECT_ID('dbo.'+@ttTab) IS NOT NULL
    BEGIN
        SET @sql = N'DISABLE TRIGGER ALL ON dbo.' + QUOTENAME(@ttTab) + N';';
        EXEC sp_executesql @sql;
    END
    SET @tt += 1;
END

/* ==========================================================================
   1) CLIENTES  (PK: CodigoEmpresa + CodigoCliente)
   ========================================================================== */
IF OBJECT_ID('dbo.Clientes') IS NOT NULL
BEGIN
    PRINT '-> Clientes ...';
    SET @sql = N'
    UPDATE dbo.Clientes SET
        RazonSocial = LEFT(''CLIENTE '' + RIGHT(''000000''+CAST(CodigoCliente AS varchar(10)),6), 40),
        Nombre      = LEFT(''Cliente '' + CAST(CodigoCliente AS varchar(10)), 35),
        Domicilio   = ''CALLE GENERICA, 1'',
        CifDni      = LEFT(''C''+RIGHT(''00000000''+CAST(CodigoCliente AS varchar(10)),8), 13),
        Telefono    = ''900000000'',
        Telefono2   = '''',
        Fax         = '''',
        EMail1      = ''cliente'' + CAST(CodigoCliente AS varchar(10)) + ''@ejemplo.com'',
        EMail2      = ''''';
    IF COL_LENGTH('dbo.Clientes','CifEuropeo') IS NOT NULL
        SET @sql += N', CifEuropeo = LEFT(''ESC''+RIGHT(''00000000''+CAST(CodigoCliente AS varchar(10)),8), 15)';
    SET @sql += N';';
    EXEC sp_executesql @sql;
    PRINT '   ok';
END

/* ==========================================================================
   2) PROVEEDORES  (PK: CodigoEmpresa + CodigoProveedor)
      Emails aqui son Email1/Email2 (no EMail1).
   ========================================================================== */
IF OBJECT_ID('dbo.Proveedores') IS NOT NULL
BEGIN
    PRINT '-> Proveedores ...';
    SET @sql = N'
    UPDATE dbo.Proveedores SET
        RazonSocial = LEFT(''PROVEEDOR '' + RIGHT(''000000''+CAST(CodigoProveedor AS varchar(10)),6), 40),
        Nombre      = LEFT(''Proveedor '' + CAST(CodigoProveedor AS varchar(10)), 35),
        Domicilio   = ''CALLE GENERICA, 1'',
        CifDni      = LEFT(''P''+RIGHT(''00000000''+CAST(CodigoProveedor AS varchar(10)),8), 13),
        Telefono    = ''900000000'',
        Telefono2   = '''',
        Fax         = ''''';
    IF COL_LENGTH('dbo.Proveedores','CifEuropeo') IS NOT NULL
        SET @sql += N', CifEuropeo = LEFT(''ESP''+RIGHT(''00000000''+CAST(CodigoProveedor AS varchar(10)),8), 15)';
    IF COL_LENGTH('dbo.Proveedores','Email1') IS NOT NULL
        SET @sql += N', Email1 = ''proveedor'' + CAST(CodigoProveedor AS varchar(10)) + ''@ejemplo.com'', Email2 = ''''';
    SET @sql += N';';
    EXEC sp_executesql @sql;
    PRINT '   ok';
END

/* ==========================================================================
   3) OPERARIOS (ERP)  (PK: CodigoEmpresa + Operario)
   ========================================================================== */
IF OBJECT_ID('dbo.Operarios') IS NOT NULL
BEGIN
    PRINT '-> Operarios (ERP) ...';
    SET @sql = N'UPDATE dbo.Operarios SET NombreOperario = LEFT(''Operario '' + CAST(Operario AS varchar(10)), 30)';
    IF COL_LENGTH('dbo.Operarios','Domicilio')  IS NOT NULL SET @sql += N', Domicilio = ''CALLE GENERICA, 1''';
    IF COL_LENGTH('dbo.Operarios','ViaPublica') IS NOT NULL SET @sql += N', ViaPublica = ''CALLE GENERICA''';
    IF COL_LENGTH('dbo.Operarios','Telefono')   IS NOT NULL SET @sql += N', Telefono = ''900000000''';
    IF COL_LENGTH('dbo.Operarios','Telefono2')  IS NOT NULL SET @sql += N', Telefono2 = ''''';
    IF COL_LENGTH('dbo.Operarios','EMail1')     IS NOT NULL SET @sql += N', EMail1 = ''operario'' + CAST(Operario AS varchar(10)) + ''@ejemplo.com''';
    IF COL_LENGTH('dbo.Operarios','EMail2')     IS NOT NULL SET @sql += N', EMail2 = ''''';
    SET @sql += N';';
    EXEC sp_executesql @sql;
    PRINT '   ok';
END

/* ==========================================================================
   4) USUARIOS (lsysUsuarios)  (PK: sysUsuario)
      Anonimiza login/nick/host/emails y VACIA password + tokens OAuth.
   ========================================================================== */
IF OBJECT_ID('dbo.lsysUsuarios') IS NOT NULL
BEGIN
    PRINT '-> lsysUsuarios ...';
    SET @sql = N'UPDATE dbo.lsysUsuarios SET sysUserName = LEFT(''usuario'' + CAST(sysUsuario AS varchar(10)), 30)';
    IF COL_LENGTH('dbo.lsysUsuarios','sysNickName')            IS NOT NULL SET @sql += N', sysNickName = LEFT(''Usuario '' + CAST(sysUsuario AS varchar(10)), 50)';
    IF COL_LENGTH('dbo.lsysUsuarios','sysHostName')            IS NOT NULL SET @sql += N', sysHostName = ''HOST''';
    IF COL_LENGTH('dbo.lsysUsuarios','sysPassword')            IS NOT NULL SET @sql += N', sysPassword = ''''';
    IF COL_LENGTH('dbo.lsysUsuarios','sysPowerBIEmail')        IS NOT NULL SET @sql += N', sysPowerBIEmail = ''''';
    IF COL_LENGTH('dbo.lsysUsuarios','SageIdEmail')            IS NOT NULL SET @sql += N', SageIdEmail = ''''';
    -- Los tokens OAuth son text/varchar NOT NULL: vaciar con '' (NULL falla).
    IF COL_LENGTH('dbo.lsysUsuarios','SageIdOAuthToken')       IS NOT NULL SET @sql += N', SageIdOAuthToken = ''''';
    IF COL_LENGTH('dbo.lsysUsuarios','SageIdOAuthRefreshToken') IS NOT NULL SET @sql += N', SageIdOAuthRefreshToken = ''''';
    SET @sql += N';';
    EXEC sp_executesql @sql;
    PRINT '   ok';
END

/* ==========================================================================
   5) EMPLEADOS - datos de nomina (EmpleadoNomina)  (PK: CodigoEmpresa+IdEmpleado)
      El nombre del empleado no vive aqui; los datos personales son el DNI/NIF.
   ========================================================================== */
IF OBJECT_ID('dbo.EmpleadoNomina') IS NOT NULL
BEGIN
    PRINT '-> EmpleadoNomina ...';
    SET @sql = N'UPDATE dbo.EmpleadoNomina SET ';
    DECLARE @sep nvarchar(2) = N'';
    IF COL_LENGTH('dbo.EmpleadoNomina','Dni')              IS NOT NULL BEGIN SET @sql += @sep + N'Dni = LEFT(''00000000X'', 14)'; SET @sep=N', '; END
    IF COL_LENGTH('dbo.EmpleadoNomina','DNIExtranjero')    IS NOT NULL BEGIN SET @sql += @sep + N'DNIExtranjero = ''''';        SET @sep=N', '; END
    IF COL_LENGTH('dbo.EmpleadoNomina','NifBenefMinusv345') IS NOT NULL BEGIN SET @sql += @sep + N'NifBenefMinusv345 = ''''';    SET @sep=N', '; END
    IF @sep = N', '   -- solo si hubo al menos una columna
    BEGIN
        SET @sql += N';';
        EXEC sp_executesql @sql;
        PRINT '   ok';
    END
    ELSE PRINT '   (sin columnas sensibles conocidas)';
END

/* ==========================================================================
   5b) EMPRESAS  (PK: CodigoEmpresa)
      Ficha de la(s) empresa(s) del ERP. Generico por CodigoEmpresa (funciona
      con cualquier numero de empresas). Nombre/anagrama/CIF anonimizados; los
      datos bancarios se vacian en el bloque 7. Domicilios de empresa aparte.
   ========================================================================== */
IF OBJECT_ID('dbo.Empresas') IS NOT NULL
BEGIN
    PRINT '-> Empresas ...';
    SET @sql = N'UPDATE dbo.Empresas SET ';
    DECLARE @se2 nvarchar(2) = N'';
    IF COL_LENGTH('dbo.Empresas','Empresa')    IS NOT NULL BEGIN SET @sql+=@se2+N'Empresa = LEFT(''EMPRESA ''+CAST(CodigoEmpresa AS varchar(10)),45)';   SET @se2=N', '; END
    IF COL_LENGTH('dbo.Empresas','Anagrama')   IS NOT NULL BEGIN SET @sql+=@se2+N'Anagrama = LEFT(''Empresa''+CAST(CodigoEmpresa AS varchar(10)),45)';   SET @se2=N', '; END
    IF COL_LENGTH('dbo.Empresas','CifDni')     IS NOT NULL BEGIN SET @sql+=@se2+N'CifDni = LEFT(''E''+RIGHT(''00000000''+CAST(CodigoEmpresa AS varchar(10)),8),13)';     SET @se2=N', '; END
    IF COL_LENGTH('dbo.Empresas','CifEuropeo') IS NOT NULL BEGIN SET @sql+=@se2+N'CifEuropeo = LEFT(''ESE''+RIGHT(''00000000''+CAST(CodigoEmpresa AS varchar(10)),8),15)'; SET @se2=N', '; END
    IF COL_LENGTH('dbo.Empresas','CifEspanol') IS NOT NULL BEGIN SET @sql+=@se2+N'CifEspanol = LEFT(''E''+RIGHT(''00000000''+CAST(CodigoEmpresa AS varchar(10)),8),9)';    SET @se2=N', '; END
    IF @se2=N', ' BEGIN SET @sql+=N';'; EXEC sp_executesql @sql; PRINT '   ok'; END
END

-- EmpresasDomicilios: direcciones, telefonos y emails de la(s) empresa(s).
IF OBJECT_ID('dbo.EmpresasDomicilios') IS NOT NULL
BEGIN
    PRINT '-> EmpresasDomicilios ...';
    SET @sql = N'UPDATE dbo.EmpresasDomicilios SET ';
    DECLARE @se3 nvarchar(2) = N'';
    IF COL_LENGTH('dbo.EmpresasDomicilios','ViaPublica') IS NOT NULL BEGIN SET @sql+=@se3+N'ViaPublica = ''CALLE GENERICA, 1'''; SET @se3=N', '; END
    IF COL_LENGTH('dbo.EmpresasDomicilios','Telefono')   IS NOT NULL BEGIN SET @sql+=@se3+N'Telefono = ''900000000'''; SET @se3=N', '; END
    IF COL_LENGTH('dbo.EmpresasDomicilios','Telefono2')  IS NOT NULL BEGIN SET @sql+=@se3+N'Telefono2 = ''''';         SET @se3=N', '; END
    IF COL_LENGTH('dbo.EmpresasDomicilios','Telefono3')  IS NOT NULL BEGIN SET @sql+=@se3+N'Telefono3 = ''''';         SET @se3=N', '; END
    IF COL_LENGTH('dbo.EmpresasDomicilios','Fax')        IS NOT NULL BEGIN SET @sql+=@se3+N'Fax = ''''';               SET @se3=N', '; END
    IF COL_LENGTH('dbo.EmpresasDomicilios','EMail1')     IS NOT NULL BEGIN SET @sql+=@se3+N'EMail1 = ''empresa''+CAST(CodigoEmpresa AS varchar(10))+''@ejemplo.com'''; SET @se3=N', '; END
    IF COL_LENGTH('dbo.EmpresasDomicilios','EMail2')     IS NOT NULL BEGIN SET @sql+=@se3+N'EMail2 = ''''';            SET @se3=N', '; END
    IF @se3=N', ' BEGIN SET @sql+=N';'; EXEC sp_executesql @sql; PRINT '   ok'; END
END

/* ==========================================================================
   6) PROPAGAR A DOCUMENTOS (cabeceras de cliente/proveedor)
      Las cabeceras COPIAN el nombre/CIF/domicilio del cliente al emitir el
      documento. Se reescriben con el valor YA anonimizado (join por codigo),
      para que albaranes/pedidos/ofertas no muestren el dato real.
      Nota: OrdenesFabricacion no guarda nombre de cliente -> no requiere update.
   ========================================================================== */
DECLARE @cabs TABLE (Orden int IDENTITY, Cabecera sysname, ColCod sysname, Maestro sysname, ColCodM sysname);
INSERT INTO @cabs (Cabecera, ColCod, Maestro, ColCodM) VALUES
  ('CabeceraAlbaranCliente',   'CodigoCliente',   'Clientes',    'CodigoCliente'),
  ('CabeceraPedidoCliente',    'CodigoCliente',   'Clientes',    'CodigoCliente'),
  ('CabeceraOfertaCliente',    'CodigoCliente',   'Clientes',    'CodigoCliente'),
  ('CabeceraAlbaranProveedor', 'CodigoProveedor', 'Proveedores', 'CodigoProveedor'),
  ('CabeceraPedidoProveedor',  'CodigoProveedor', 'Proveedores', 'CodigoProveedor');

DECLARE @c int = 1, @cn int = (SELECT MAX(Orden) FROM @cabs);
DECLARE @HCab sysname, @HCod sysname, @HMae sysname, @HCodM sysname;
DECLARE @setcols nvarchar(max), @spc nvarchar(2);

PRINT '';
PRINT '=== Propagar a cabeceras de documentos ===';
WHILE @c <= @cn
BEGIN
    SELECT @HCab=Cabecera, @HCod=ColCod, @HMae=Maestro, @HCodM=ColCodM FROM @cabs WHERE Orden=@c;

    IF OBJECT_ID('dbo.'+@HCab) IS NOT NULL AND OBJECT_ID('dbo.'+@HMae) IS NOT NULL
    BEGIN
        -- Construir el SET solo con las columnas que existan en la cabecera,
        -- tomando el valor ya anonimizado del maestro (M).
        SET @setcols = N'';
        SET @spc = N'';
        IF COL_LENGTH('dbo.'+@HCab,'RazonSocial')  IS NOT NULL BEGIN SET @setcols += @spc+N'RazonSocial = M.RazonSocial';  SET @spc=N', '; END
        IF COL_LENGTH('dbo.'+@HCab,'RazonSocial2') IS NOT NULL BEGIN SET @setcols += @spc+N'RazonSocial2 = M.RazonSocial'; SET @spc=N', '; END
        IF COL_LENGTH('dbo.'+@HCab,'RazonSocialEnvios')  IS NOT NULL BEGIN SET @setcols += @spc+N'RazonSocialEnvios = M.RazonSocial';  SET @spc=N', '; END
        IF COL_LENGTH('dbo.'+@HCab,'RazonSocial2Envios') IS NOT NULL BEGIN SET @setcols += @spc+N'RazonSocial2Envios = M.RazonSocial'; SET @spc=N', '; END
        IF COL_LENGTH('dbo.'+@HCab,'Nombre')       IS NOT NULL BEGIN SET @setcols += @spc+N'Nombre = M.Nombre';           SET @spc=N', '; END
        IF COL_LENGTH('dbo.'+@HCab,'NombreEnvios') IS NOT NULL BEGIN SET @setcols += @spc+N'NombreEnvios = M.Nombre';     SET @spc=N', '; END
        IF COL_LENGTH('dbo.'+@HCab,'CifDni')       IS NOT NULL BEGIN SET @setcols += @spc+N'CifDni = M.CifDni';           SET @spc=N', '; END
        IF COL_LENGTH('dbo.'+@HCab,'Domicilio')       IS NOT NULL BEGIN SET @setcols += @spc+N'Domicilio = M.Domicilio';       SET @spc=N', '; END
        IF COL_LENGTH('dbo.'+@HCab,'Domicilio2')      IS NOT NULL BEGIN SET @setcols += @spc+N'Domicilio2 = M.Domicilio';      SET @spc=N', '; END
        IF COL_LENGTH('dbo.'+@HCab,'DomicilioEnvios') IS NOT NULL BEGIN SET @setcols += @spc+N'DomicilioEnvios = M.Domicilio'; SET @spc=N', '; END
        IF COL_LENGTH('dbo.'+@HCab,'Domicilio2Envios') IS NOT NULL BEGIN SET @setcols += @spc+N'Domicilio2Envios = M.Domicilio'; SET @spc=N', '; END

        IF @spc = N', '   -- hubo al menos una columna a propagar
        BEGIN
            PRINT '-> ' + @HCab + ' ...';
            SET @sql = N'
                UPDATE H SET ' + @setcols + N'
                FROM dbo.' + QUOTENAME(@HCab) + N' H
                JOIN dbo.' + QUOTENAME(@HMae) + N' M
                  ON  M.CodigoEmpresa = H.CodigoEmpresa
                  AND M.' + QUOTENAME(@HCodM) + N' = H.' + QUOTENAME(@HCod) + N';';
            EXEC sp_executesql @sql;
            PRINT '   ok';
        END
    END
    SET @c += 1;
END

/* ==========================================================================
   7) DATOS BANCARIOS  -> VACIAR (IBAN, CCC, banco/oficina, tarjeta, titular).
      Se vacian (no se falsean) porque no aportan nada anonimizados y son
      especialmente sensibles. Cubre fichas maestras + cartera + resumenes +
      cabeceras de documentos (que replican el IBAN del cliente).
      Metadatos: una fila por (tabla, columna). Se salta la que no exista.
   ========================================================================== */
DECLARE @banco TABLE (Orden int IDENTITY, Tabla sysname, Col sysname, Tipo char(1)); -- 'T'=texto '' / 'N'=NULL
INSERT INTO @banco (Tabla, Col, Tipo) VALUES
  ('Clientes','IBAN','T'),      ('Clientes','CCC','T'),      ('Clientes','CodigoBanco','T'),      ('Clientes','CodigoOficina','T'),
  ('Proveedores','IBAN','T'),   ('Proveedores','CCC','T'),   ('Proveedores','CodigoBanco','T'),   ('Proveedores','CodigoOficina','T'),
  ('Empresas','IBAN','T'),      ('Empresas','CCC','T'),      ('Empresas','CodigoBanco','T'),      ('Empresas','CodigoOficina','T'),
  ('ResumenCliente','IBAN','T'),('ResumenCliente','CCC','T'),('ResumenCliente','CodigoBanco','T'),
  ('ResumenProveedor','IBAN','T'),('ResumenProveedor','CCC','T'),('ResumenProveedor','CodigoBanco','T'),
  ('CarteraEfectos','IBAN','T'),('CarteraEfectos','CCC','T'),('CarteraEfectos','CodigoBanco','T'),
  ('HistoricoCartera','IBAN','T'),('HistoricoCartera','CCC','T'),('HistoricoCartera','CodigoBanco','T'),
  ('BancosConta','IBAN','T'),   ('BancosConta','TitularCuenta','T'), ('BancosConta','NumeroTarjeta','T'),
  ('CabeceraAlbaranCliente','IBAN','T'), ('CabeceraPedidoCliente','IBAN','T'), ('CabeceraOfertaCliente','IBAN','T'),
  ('CabeceraAlbaranProveedor','IBAN','T'),('CabeceraPedidoProveedor','IBAN','T');

DECLARE @b int = 1, @bn int = (SELECT MAX(Orden) FROM @banco);
DECLARE @bTab sysname, @bCol sysname, @bTipo char(1);

PRINT '';
PRINT '=== Datos bancarios (vaciar) ===';
WHILE @b <= @bn
BEGIN
    SELECT @bTab=Tabla, @bCol=Col, @bTipo=Tipo FROM @banco WHERE Orden=@b;
    IF OBJECT_ID('dbo.'+@bTab) IS NOT NULL AND COL_LENGTH('dbo.'+@bTab, @bCol) IS NOT NULL
    BEGIN
        SET @sql = N'UPDATE dbo.' + QUOTENAME(@bTab) + N' SET ' + QUOTENAME(@bCol)
                 + CASE WHEN @bTipo='N' THEN N' = NULL' ELSE N' = ''''' END + N';';
        EXEC sp_executesql @sql;
    END
    SET @b += 1;
END
PRINT '   ok';

/* ==========================================================================
   8) PERSONAS / CONTACTOS / RRHH  -> nombres, apellidos, DNI, nacimiento,
      telefonos y emails. Determinista por su clave/rowid cuando aplica; si no
      hay clave simple, valor fijo generico.
      Cada tabla se trata a medida (columnas propias). Guardas por columna.
   ========================================================================== */
PRINT '';
PRINT '=== Personas / contactos / RRHH ===';

-- Personas (persona/empleado; PK con IdPersona/uniqueidentifier -> valor fijo)
IF OBJECT_ID('dbo.Personas') IS NOT NULL
BEGIN
    PRINT '-> Personas ...';
    SET @sql = N'UPDATE dbo.Personas SET ';
    DECLARE @s1 nvarchar(2) = N'';
    IF COL_LENGTH('dbo.Personas','NombreEmpleado')         IS NOT NULL BEGIN SET @sql+=@s1+N'NombreEmpleado = ''Nombre''';           SET @s1=N', '; END
    IF COL_LENGTH('dbo.Personas','PrimerApellidoEmpleado') IS NOT NULL BEGIN SET @sql+=@s1+N'PrimerApellidoEmpleado = ''Apellido1''';  SET @s1=N', '; END
    IF COL_LENGTH('dbo.Personas','SegundoApellidoEmpleado') IS NOT NULL BEGIN SET @sql+=@s1+N'SegundoApellidoEmpleado = ''Apellido2'''; SET @s1=N', '; END
    IF COL_LENGTH('dbo.Personas','RazonSocialEmpleado')    IS NOT NULL BEGIN SET @sql+=@s1+N'RazonSocialEmpleado = ''PERSONA''';       SET @s1=N', '; END
    -- OJO: el Dni forma parte de la PK (SiglaNacion+Dni). NO se pone aqui un valor
    -- fijo (daria PK duplicada); se asigna UNICO por fila mas abajo con ROW_NUMBER.
    IF COL_LENGTH('dbo.Personas','NombrePadre')            IS NOT NULL BEGIN SET @sql+=@s1+N'NombrePadre = ''''';                      SET @s1=N', '; END
    IF COL_LENGTH('dbo.Personas','NombreMadre')            IS NOT NULL BEGIN SET @sql+=@s1+N'NombreMadre = ''''';                      SET @s1=N', '; END
    IF COL_LENGTH('dbo.Personas','NombreRepresentante')    IS NOT NULL BEGIN SET @sql+=@s1+N'NombreRepresentante = ''''';              SET @s1=N', '; END
    IF COL_LENGTH('dbo.Personas','DNIRepresentante')       IS NOT NULL BEGIN SET @sql+=@s1+N'DNIRepresentante = ''''';                 SET @s1=N', '; END
    IF COL_LENGTH('dbo.Personas','EMail1')                 IS NOT NULL BEGIN SET @sql+=@s1+N'EMail1 = ''persona@ejemplo.com''';        SET @s1=N', '; END
    IF COL_LENGTH('dbo.Personas','EMail2')                 IS NOT NULL BEGIN SET @sql+=@s1+N'EMail2 = ''''';                           SET @s1=N', '; END
    IF @s1=N', ' BEGIN SET @sql+=N';'; EXEC sp_executesql @sql; END
    -- Dni UNICO por fila (forma parte de la PK): '00000001X', '00000002X', ...
    IF COL_LENGTH('dbo.Personas','Dni') IS NOT NULL
    BEGIN
        ;WITH C AS (SELECT Dni, rn = ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM dbo.Personas)
        UPDATE C SET Dni = RIGHT('00000000'+CAST(rn AS varchar(8)),8) + 'X';
        IF COL_LENGTH('dbo.Personas','DNIEspanol') IS NOT NULL
            UPDATE dbo.Personas SET DNIEspanol = Dni;
    END
    PRINT '   ok';
END

-- ClientesProveedores (persona ligada a cuenta)
IF OBJECT_ID('dbo.ClientesProveedores') IS NOT NULL
BEGIN
    PRINT '-> ClientesProveedores ...';
    SET @sql = N'UPDATE dbo.ClientesProveedores SET ';
    DECLARE @s2 nvarchar(2) = N'';
    IF COL_LENGTH('dbo.ClientesProveedores','NombreEmpleado')          IS NOT NULL BEGIN SET @sql+=@s2+N'NombreEmpleado = ''Nombre''';            SET @s2=N', '; END
    IF COL_LENGTH('dbo.ClientesProveedores','PrimerApellidoEmpleado')  IS NOT NULL BEGIN SET @sql+=@s2+N'PrimerApellidoEmpleado = ''Apellido1'''; SET @s2=N', '; END
    IF COL_LENGTH('dbo.ClientesProveedores','SegundoApellidoEmpleado') IS NOT NULL BEGIN SET @sql+=@s2+N'SegundoApellidoEmpleado = ''Apellido2'''; SET @s2=N', '; END
    -- OJO: CifDni esta en indice unico (SiglaNacion+CifDni). NO valor fijo aqui;
    -- se asigna UNICO por fila mas abajo con ROW_NUMBER.
    IF COL_LENGTH('dbo.ClientesProveedores','CifEuropeo')              IS NOT NULL BEGIN SET @sql+=@s2+N'CifEuropeo = ''''';                       SET @s2=N', '; END
    IF COL_LENGTH('dbo.ClientesProveedores','Telefono')               IS NOT NULL BEGIN SET @sql+=@s2+N'Telefono = ''900000000''';                SET @s2=N', '; END
    IF COL_LENGTH('dbo.ClientesProveedores','Telefono2')              IS NOT NULL BEGIN SET @sql+=@s2+N'Telefono2 = ''''';                         SET @s2=N', '; END
    IF COL_LENGTH('dbo.ClientesProveedores','Telefono3')              IS NOT NULL BEGIN SET @sql+=@s2+N'Telefono3 = ''''';                         SET @s2=N', '; END
    IF COL_LENGTH('dbo.ClientesProveedores','EMail1')                 IS NOT NULL BEGIN SET @sql+=@s2+N'EMail1 = ''persona@ejemplo.com''';         SET @s2=N', '; END
    IF COL_LENGTH('dbo.ClientesProveedores','EMail2')                 IS NOT NULL BEGIN SET @sql+=@s2+N'EMail2 = ''''';                            SET @s2=N', '; END
    IF @s2=N', ' BEGIN SET @sql+=N';'; EXEC sp_executesql @sql; END
    -- CifDni UNICO por fila (indice unico): '00000001X', '00000002X', ...
    IF COL_LENGTH('dbo.ClientesProveedores','CifDni') IS NOT NULL
    BEGIN
        ;WITH C AS (SELECT CifDni, rn = ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM dbo.ClientesProveedores)
        UPDATE C SET CifDni = RIGHT('00000000'+CAST(rn AS varchar(8)),8) + 'X';
        IF COL_LENGTH('dbo.ClientesProveedores','CifEspanol') IS NOT NULL
            UPDATE dbo.ClientesProveedores SET CifEspanol = CifDni;
    END
    PRINT '   ok';
END

-- RHH_Personas
IF OBJECT_ID('dbo.RHH_Personas') IS NOT NULL
BEGIN
    PRINT '-> RHH_Personas ...';
    SET @sql = N'UPDATE dbo.RHH_Personas SET ';
    DECLARE @s3 nvarchar(2) = N'';
    IF COL_LENGTH('dbo.RHH_Personas','NombrePersona')     IS NOT NULL BEGIN SET @sql+=@s3+N'NombrePersona = ''Nombre''';         SET @s3=N', '; END
    IF COL_LENGTH('dbo.RHH_Personas','PrimerApellido')    IS NOT NULL BEGIN SET @sql+=@s3+N'PrimerApellido = ''Apellido1''';     SET @s3=N', '; END
    IF COL_LENGTH('dbo.RHH_Personas','SegundoApellido')   IS NOT NULL BEGIN SET @sql+=@s3+N'SegundoApellido = ''Apellido2''';    SET @s3=N', '; END
    IF COL_LENGTH('dbo.RHH_Personas','NombreCompletoRhh') IS NOT NULL BEGIN SET @sql+=@s3+N'NombreCompletoRhh = ''Nombre Apellido1 Apellido2'''; SET @s3=N', '; END
    IF COL_LENGTH('dbo.RHH_Personas','Dni')               IS NOT NULL BEGIN SET @sql+=@s3+N'Dni = ''00000000X''';               SET @s3=N', '; END
    IF COL_LENGTH('dbo.RHH_Personas','Telefono')          IS NOT NULL BEGIN SET @sql+=@s3+N'Telefono = ''900000000''';          SET @s3=N', '; END
    IF COL_LENGTH('dbo.RHH_Personas','Telefono2')         IS NOT NULL BEGIN SET @sql+=@s3+N'Telefono2 = ''''';                  SET @s3=N', '; END
    IF COL_LENGTH('dbo.RHH_Personas','EMail1')            IS NOT NULL BEGIN SET @sql+=@s3+N'EMail1 = ''persona@ejemplo.com''';  SET @s3=N', '; END
    IF COL_LENGTH('dbo.RHH_Personas','EMail2')            IS NOT NULL BEGIN SET @sql+=@s3+N'EMail2 = ''''';                     SET @s3=N', '; END
    IF @s3=N', ' BEGIN SET @sql+=N';'; EXEC sp_executesql @sql; PRINT '   ok'; END
END

-- RHH_Candidatos
IF OBJECT_ID('dbo.RHH_Candidatos') IS NOT NULL
BEGIN
    PRINT '-> RHH_Candidatos ...';
    SET @sql = N'UPDATE dbo.RHH_Candidatos SET ';
    DECLARE @s4 nvarchar(2) = N'';
    IF COL_LENGTH('dbo.RHH_Candidatos','NombreEmpleado')          IS NOT NULL BEGIN SET @sql+=@s4+N'NombreEmpleado = ''Nombre''';            SET @s4=N', '; END
    IF COL_LENGTH('dbo.RHH_Candidatos','PrimerApellidoEmpleado')  IS NOT NULL BEGIN SET @sql+=@s4+N'PrimerApellidoEmpleado = ''Apellido1'''; SET @s4=N', '; END
    IF COL_LENGTH('dbo.RHH_Candidatos','SegundoApellidoEmpleado') IS NOT NULL BEGIN SET @sql+=@s4+N'SegundoApellidoEmpleado = ''Apellido2'''; SET @s4=N', '; END
    IF COL_LENGTH('dbo.RHH_Candidatos','RazonSocialEmpleado')     IS NOT NULL BEGIN SET @sql+=@s4+N'RazonSocialEmpleado = ''CANDIDATO''';     SET @s4=N', '; END
    IF COL_LENGTH('dbo.RHH_Candidatos','Dni')                     IS NOT NULL BEGIN SET @sql+=@s4+N'Dni = ''00000000X''';                    SET @s4=N', '; END
    IF COL_LENGTH('dbo.RHH_Candidatos','DNIEspanol')              IS NOT NULL BEGIN SET @sql+=@s4+N'DNIEspanol = ''00000000X''';             SET @s4=N', '; END
    IF COL_LENGTH('dbo.RHH_Candidatos','NombrePadre')             IS NOT NULL BEGIN SET @sql+=@s4+N'NombrePadre = ''''';                     SET @s4=N', '; END
    IF COL_LENGTH('dbo.RHH_Candidatos','NombreMadre')             IS NOT NULL BEGIN SET @sql+=@s4+N'NombreMadre = ''''';                     SET @s4=N', '; END
    IF COL_LENGTH('dbo.RHH_Candidatos','EMail1')                  IS NOT NULL BEGIN SET @sql+=@s4+N'EMail1 = ''persona@ejemplo.com''';       SET @s4=N', '; END
    IF COL_LENGTH('dbo.RHH_Candidatos','EMail2')                  IS NOT NULL BEGIN SET @sql+=@s4+N'EMail2 = ''''';                          SET @s4=N', '; END
    IF @s4=N', ' BEGIN SET @sql+=N';'; EXEC sp_executesql @sql; PRINT '   ok'; END
END

-- LcClienteContactos
IF OBJECT_ID('dbo.LcClienteContactos') IS NOT NULL
BEGIN
    PRINT '-> LcClienteContactos ...';
    SET @sql = N'UPDATE dbo.LcClienteContactos SET ';
    DECLARE @s5 nvarchar(2) = N'';
    IF COL_LENGTH('dbo.LcClienteContactos','NombreContactoLc') IS NOT NULL BEGIN SET @sql+=@s5+N'NombreContactoLc = ''Contacto''';      SET @s5=N', '; END
    IF COL_LENGTH('dbo.LcClienteContactos','Nombre')           IS NOT NULL BEGIN SET @sql+=@s5+N'Nombre = ''Nombre''';                  SET @s5=N', '; END
    IF COL_LENGTH('dbo.LcClienteContactos','Apellido1')        IS NOT NULL BEGIN SET @sql+=@s5+N'Apellido1 = ''Apellido1''';            SET @s5=N', '; END
    IF COL_LENGTH('dbo.LcClienteContactos','Apellido2')        IS NOT NULL BEGIN SET @sql+=@s5+N'Apellido2 = ''Apellido2''';            SET @s5=N', '; END
    IF COL_LENGTH('dbo.LcClienteContactos','TelefonoContactoLc') IS NOT NULL BEGIN SET @sql+=@s5+N'TelefonoContactoLc = ''900000000'''; SET @s5=N', '; END
    IF COL_LENGTH('dbo.LcClienteContactos','EMail1')           IS NOT NULL BEGIN SET @sql+=@s5+N'EMail1 = ''contacto@ejemplo.com''';    SET @s5=N', '; END
    IF COL_LENGTH('dbo.LcClienteContactos','Email2')           IS NOT NULL BEGIN SET @sql+=@s5+N'Email2 = ''''';                        SET @s5=N', '; END
    IF @s5=N', ' BEGIN SET @sql+=N';'; EXEC sp_executesql @sql; PRINT '   ok'; END
END

-- ResumenCliente / ResumenProveedor: propagan nombre/CIF/domicilio (vaciar por
-- codigo desde el maestro seria ideal, pero como resumen basta con generico).
IF OBJECT_ID('dbo.ResumenCliente') IS NOT NULL AND COL_LENGTH('dbo.ResumenCliente','RazonSocial') IS NOT NULL
BEGIN
    PRINT '-> ResumenCliente (nombre/CIF) ...';
    UPDATE dbo.ResumenCliente SET
        RazonSocial = LEFT('CLIENTE '+ISNULL(CAST(CodigoCliente AS varchar(20)),''),40),
        CifDni = '', Domicilio = 'CALLE GENERICA, 1';
    PRINT '   ok';
END
IF OBJECT_ID('dbo.ResumenProveedor') IS NOT NULL AND COL_LENGTH('dbo.ResumenProveedor','RazonSocial') IS NOT NULL
BEGIN
    PRINT '-> ResumenProveedor (nombre/CIF) ...';
    UPDATE dbo.ResumenProveedor SET
        RazonSocial = LEFT('PROVEEDOR '+ISNULL(CAST(CodigoProveedor AS varchar(20)),''),40),
        CifDni = '', Domicilio = 'CALLE GENERICA, 1';
    PRINT '   ok';
END

/* ==========================================================================
   9) REACTIVAR TRIGGERS desactivados en el bloque 0.
   ========================================================================== */
PRINT '';
PRINT '=== Reactivando triggers ===';
SET @tt = 1;
WHILE @tt <= @ttn
BEGIN
    SELECT @ttTab=Tabla FROM @tabsTrig WHERE Orden=@tt;
    IF OBJECT_ID('dbo.'+@ttTab) IS NOT NULL
    BEGIN
        SET @sql = N'ENABLE TRIGGER ALL ON dbo.' + QUOTENAME(@ttTab) + N';';
        EXEC sp_executesql @sql;
    END
    SET @tt += 1;
END

PRINT '';
PRINT '=== ANONIMIZACION COMPLETADA ===';
GO

/* ============================================================================
   COMPROBACION (ejecutar tras el script, en la BD del ERP):
     SELECT TOP 5 CodigoCliente, RazonSocial, CifDni, EMail1 FROM dbo.Clientes;
     SELECT TOP 5 CodigoProveedor, RazonSocial, CifDni, Email1 FROM dbo.Proveedores;
     SELECT TOP 5 Operario, NombreOperario, Telefono FROM dbo.Operarios;
     SELECT TOP 5 sysUsuario, sysUserName, sysNickName FROM dbo.lsysUsuarios;
     SELECT TOP 5 RazonSocial, CifDni FROM dbo.CabeceraAlbaranCliente;

   PENDIENTE / valorar aparte (otras tablas que replican datos personales):
     - *Domicilios de clientes/proveedores, contactos, familia Empleado* (RRHH),
       ClientesProveedores (personas), facturas.
     - Empresas: 'anonimizar_empresas.sql'.
   ============================================================================ */
