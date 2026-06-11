-- 1. ASEGURAR QUE EXISTE LA TABLA DESTINO Y SUS PARTICIONES
CREATE TABLE IF NOT EXISTS es_ivan.his_proceso (
    id_cita int NOT NULL,
    lote varchar(3),
    fg_tipo varchar(2),
    dni_paciente varchar(50),
    apellido_paterno_paciente text,
    apellido_materno_paciente text,
    nombres_paciente text,
    fecha_nacimiento date,
    id_tipo_documento int,
    genero varchar(1),
    id_etnia int,
    anio int NOT NULL,
    mes int,
    dia int,
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
    id_colegio varchar(10),
    descripcion_colegio text,
    id_ups int,
    descripcion_etnia text,
    fecha_registro timestamp,
    fecha_modificacion timestamp
) PARTITION BY RANGE (anio);

-- Crear particiones si no existen
CREATE TABLE IF NOT EXISTS es_ivan.his_proceso_2021 PARTITION OF es_ivan.his_proceso FOR VALUES FROM (2021) TO (2022);
CREATE TABLE IF NOT EXISTS es_ivan.his_proceso_2022 PARTITION OF es_ivan.his_proceso FOR VALUES FROM (2022) TO (2023);
CREATE TABLE IF NOT EXISTS es_ivan.his_proceso_2023 PARTITION OF es_ivan.his_proceso FOR VALUES FROM (2023) TO (2024);
CREATE TABLE IF NOT EXISTS es_ivan.his_proceso_2024 PARTITION OF es_ivan.his_proceso FOR VALUES FROM (2024) TO (2025);
CREATE TABLE IF NOT EXISTS es_ivan.his_proceso_2025 PARTITION OF es_ivan.his_proceso FOR VALUES FROM (2025) TO (2026);
CREATE TABLE IF NOT EXISTS es_ivan.his_proceso_2026 PARTITION OF es_ivan.his_proceso FOR VALUES FROM (2026) TO (2027);

-- 2. LIMPIEZA DEL PERIODO SELECCIONADO (Evita duplicados en la tabla de proceso)
DELETE FROM es_ivan.his_proceso 
WHERE anio = '{ANIO}' 
  AND mes {FILTRO_MES};

-- 3. CARGA DE DATOS DESDE TABLA FULL CON PROTECCIÓN DE TIPOS
INSERT INTO es_ivan.his_proceso (
    id_cita, lote, fg_tipo, dni_paciente, nombres_paciente, 
    anio, mes, dia, fecha_atencion, edad, tip_edad, 
    fi, establec, servicio, condicion_gestante, 
    peso_pregestacional, tipo_diagnostico, codigo_item, valor_lab, 
    id_correlativo, id_correlativo_lab, id_ups, 
    fecha_registro, fecha_modificacion, id_etnia
)
SELECT 
    CASE WHEN id_cita::text ~ '^[0-9]+$' THEN id_cita::int ELSE 0 END, 
    lote, 
    NULL::varchar(2), 
    dni_paciente, 
    nombre_completo_paciente, 
    anio::int, 
    mes::int, 
    dia::int, 
    fecha_atencion::date, 
    CASE WHEN edad_reg::text ~ '^[0-9]+$' THEN edad_reg::int ELSE 0 END, 
    tipo_edad, 
    id_financiador, 
    id_condicion_establecimiento, 
    id_condicion_servicio, 
    condicion_gestante, 
    CASE WHEN peso_pregestacional::text ~ '^[0-9.]+$' THEN peso_pregestacional::numeric ELSE 0 END,
    tipo_diagnostico, 
    codigo_item, 
    valor_lab, 
    CASE WHEN id_correlativo::text ~ '^[0-9]+$' THEN id_correlativo::int ELSE 0 END, 
    CASE WHEN id_correlativo_lab::text ~ '^[0-9]+$' THEN id_correlativo_lab::int ELSE 0 END, 
    CASE WHEN id_ups::text ~ '^[0-9]+$' THEN id_ups::int ELSE 0 END, 
    fecha_registro::timestamp, 
    fecha_modificacion::timestamp,
    CASE WHEN id_etnia::text ~ '^[0-9]+$' THEN id_etnia::int ELSE 0 END
FROM es_ivan.hisminsa_consolidado_full 
WHERE anio = '{ANIO}' 
  AND mes {FILTRO_MES};