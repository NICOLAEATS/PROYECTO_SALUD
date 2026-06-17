-- Plantilla editable del proceso HIS.
-- Mantén los nombres de las secciones @SECTION para que el proceso siga funcionando.
-- Puedes editar libremente el SQL dentro de cada bloque.

-- @SECTION: estructura
CREATE TABLE IF NOT EXISTS {ESQUEMA}.his_proceso (
    id_cita int NOT NULL,
    lote varchar(3),
    fg_tipo varchar(2),
    dni_paciente varchar(50),
    apellido_paterno_paciente text,
    apellido_materno_paciente text,
    nombres_paciente text,
    fecha_nacimiento date,
    fecha_ultima_regla date,
    id_tipo_documento int,
    genero varchar(1),
    id_etnia int,
    anio int NOT NULL,
    mes int,
    dia int,
    id_establecimiento int,
    fecha_atencion date,
    edad int,
    tip_edad varchar(1),
    fi varchar(2),
    establec varchar(1),
    servicio varchar(1),
    condicion_gestante varchar(20),
    peso_pregestacional numeric(7,2),
    tipo_diagnostico varchar(5),
    codigo_item varchar(15),
    valor_lab varchar(10),
    id_correlativo int,
    id_correlativo_lab int,
    cod_2000 varchar(10),
    codigo_red varchar(10),
    red text,
    desc_ue text,
    codigo_microred varchar(10),
    microred text,
    departamento text,
    provincia text,
    distrito text,
    nombre_establecimiento text,
    dni_personal varchar(50),
    dni_registrador varchar(50),
    id_colegio varchar(10),
    descripcion_colegio text,
    id_ups int,
    descripcion_etnia text,
    fecha_registro timestamp,
    fecha_modificacion timestamp
) PARTITION BY RANGE (anio);

-- @SECTION: particion
CREATE TABLE {ESQUEMA}.{NOMBRE_PARTICION}
PARTITION OF {ESQUEMA}.his_proceso
FOR VALUES FROM ({ANIO}) TO ({ANIO_SIGUIENTE});

-- @SECTION: limpiar_periodo_todos
DELETE FROM {ESQUEMA}.his_proceso
WHERE anio = {ANIO};

-- @SECTION: limpiar_periodo_mes
DELETE FROM {ESQUEMA}.his_proceso
WHERE anio = {ANIO}
  AND mes = {MES};

-- @SECTION: crear_staging
DROP TABLE IF EXISTS {ESQUEMA}.{STAGING_TABLA};

CREATE UNLOGGED TABLE {ESQUEMA}.{STAGING_TABLA} AS
SELECT
    CASE WHEN nt.id_cita::text ~ '^[0-9]+$' THEN nt.id_cita::int ELSE 0 END AS id_cita,
    COALESCE(TRIM(nt.lote::text), '')::varchar(3) AS lote,
    COALESCE(TRIM(cie.fg_tipo::text), '')::varchar(2) AS fg_tipo,
    COALESCE(TRIM(mp.numero_documento::text), '')::varchar(50) AS dni_paciente,
    COALESCE(TRIM(mp.apellido_paterno_paciente::text), '')::text AS apellido_paterno_paciente,
    COALESCE(TRIM(mp.apellido_materno_paciente::text), '')::text AS apellido_materno_paciente,
    COALESCE(TRIM(mp.nombres_paciente::text), '')::text AS nombres_paciente,
    NULLIF(TRIM(mp.fecha_nacimiento::text), '')::date AS fecha_nacimiento,
    NULLIF(TRIM(nt.fecha_ultima_regla::text), '')::date AS fecha_ultima_regla,
    CASE
        WHEN mp.id_tipo_documento::text ~ '^[0-9]+$' THEN mp.id_tipo_documento::int
        ELSE 0
    END AS id_tipo_documento,
    COALESCE(TRIM(mp.genero::text), '')::varchar(1) AS genero,
    CASE
        WHEN mp.id_etnia::text ~ '^[0-9]+$' THEN mp.id_etnia::int
        ELSE 0
    END AS id_etnia,
    nt.anio::int AS anio,
    CASE WHEN nt.mes::text ~ '^[0-9]+$' THEN nt.mes::int ELSE 0 END AS mes,
    CASE WHEN nt.dia::text ~ '^[0-9]+$' THEN nt.dia::int ELSE 0 END AS dia,
    NULLIF(TRIM(nt.fecha_atencion::text), '')::date AS fecha_atencion,
    CASE WHEN nt.edad_reg::text ~ '^[0-9]+$' THEN nt.edad_reg::int ELSE 0 END AS edad,
    COALESCE(TRIM(nt.tipo_edad::text), '')::varchar(1) AS tip_edad,
    COALESCE(TRIM(nt.id_financiador::text), '')::varchar(2) AS fi,
    COALESCE(TRIM(nt.id_condicion_establecimiento::text), '')::varchar(1) AS establec,
    COALESCE(TRIM(nt.id_condicion_servicio::text), '')::varchar(1) AS servicio,
    COALESCE(TRIM(nt.condicion_gestante::text), '')::varchar(20) AS condicion_gestante,
    CASE
        WHEN nt.peso_pregestacional::text ~ '^[0-9]+(\.[0-9]+)?$'
        THEN nt.peso_pregestacional::numeric(7,2)
        ELSE 0
    END AS peso_pregestacional,
    COALESCE(TRIM(nt.tipo_diagnostico::text), '')::varchar(5) AS tipo_diagnostico,
    COALESCE(TRIM(nt.codigo_item::text), '')::varchar(15) AS codigo_item,
    COALESCE(TRIM(nt.valor_lab::text), '')::varchar(10) AS valor_lab,
    CASE WHEN nt.id_correlativo::text ~ '^[0-9]+$' THEN nt.id_correlativo::int ELSE 0 END AS id_correlativo,
    CASE WHEN nt.id_correlativo_lab::text ~ '^[0-9]+$' THEN nt.id_correlativo_lab::int ELSE 0 END AS id_correlativo_lab,
    {EESS_COD_2000} AS cod_2000,
    {EESS_CODIGO_RED} AS codigo_red,
    {EESS_RED} AS red,
    {EESS_DESC_UE} AS desc_ue,
    {EESS_CODIGO_MICRORED} AS codigo_microred,
    {EESS_MICRORED} AS microred,
    {EESS_DEPARTAMENTO} AS departamento,
    {EESS_PROVINCIA} AS provincia,
    {EESS_DISTRITO} AS distrito,
    {EESS_NOMBRE_ESTABLECIMIENTO} AS nombre_establecimiento,
    COALESCE(TRIM(mp2.numero_documento::text), '')::varchar(50) AS dni_personal,
    COALESCE(TRIM(nt.id_registrador::text), '')::varchar(50) AS dni_registrador,
    COALESCE(TRIM(mp2.id_colegio::text), '')::varchar(10) AS id_colegio,
    COALESCE(TRIM(mhc.descripcion_colegio::text), '')::text AS descripcion_colegio,
    CASE WHEN mhu.id_ups::text ~ '^[0-9]+$' THEN mhu.id_ups::int ELSE 0 END AS id_ups,
    COALESCE(TRIM(et.descripcion_etnia::text), '')::text AS descripcion_etnia,
    NULLIF(TRIM(nt.fecha_registro::text), '')::timestamp AS fecha_registro,
    NULLIF(TRIM(nt.fecha_modificacion::text), '')::timestamp AS fecha_modificacion,
    CASE WHEN nt.id_establecimiento::text ~ '^[0-9]+$' THEN nt.id_establecimiento::int ELSE 0 END AS id_establecimiento
FROM {TABLA_HISMINSA24} nt
LEFT JOIN {TABLA_MAESTRO_HIS_CIE_CPMS} cie
       ON nt.codigo_item::text = cie.codigo_item::text
LEFT JOIN {TABLA_MAESTRO_PACIENTE} mp
       ON nt.id_paciente::text = mp.id_paciente::text
LEFT JOIN {TABLA_MAESTRO_HIS_ETNIA} et
       ON mp.id_etnia::text = et.id_etnia::text
LEFT JOIN {TABLA_MAESTRO_PERSONAL} mp2
       ON nt.id_personal::text = mp2.id_personal::text
LEFT JOIN {TABLA_MAESTRO_HIS_UPS} mhu
       ON nt.id_ups::text = mhu.id_ups::text
LEFT JOIN {TABLA_MAESTRO_HIS_COLEGIO} mhc
       ON mp2.id_colegio::text = mhc.id_colegio::text
{JOIN_EESS}
WHERE nt.anio = '{ANIO}'
  AND nt.id_cita::text ~ '^[0-9]+$'
  {FILTRO_MES};

-- @SECTION: cargar_particion_final
INSERT INTO {ESQUEMA}.his_proceso_{ANIO} ({COLUMNAS_SQL})
SELECT {COLUMNAS_SQL}
FROM {ESQUEMA}.{STAGING_TABLA};

-- @SECTION: eliminar_staging
DROP TABLE IF EXISTS {ESQUEMA}.{STAGING_TABLA};
