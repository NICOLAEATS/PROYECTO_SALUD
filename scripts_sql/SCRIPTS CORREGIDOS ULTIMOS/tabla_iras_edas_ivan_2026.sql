-- Índice (ejecutar una sola vez)

CREATE INDEX IF NOT EXISTS idx_his_proceso_anio_codigo
ON es_ivan.his_proceso (anio, codigo_item);

CREATE INDEX IF NOT EXISTS idx_his_proceso_id_cita
ON es_ivan.his_proceso (id_cita);

CREATE INDEX IF NOT EXISTS idx_his_proceso_anio_id_cita
ON es_ivan.his_proceso (anio, id_cita);

-- Tabla temporal de códigos

DROP TABLE IF EXISTS tmp_codigos_iras_edas;

CREATE TEMP TABLE tmp_codigos_iras_edas (
    codigo VARCHAR(20)
);

INSERT INTO tmp_codigos_iras_edas VALUES
('A009'),('A011'),('A012'),('A013'),('A014'),
('A020'),('A040'),('A041'),('A049'),('A059'),
('A062'),('A072'),('A080'),('A082'),('A083'),
('A084'),('A090'),('A099'),('A000'),
('A001'),('A030'),('A039'),('A042'),('A043'),
('A045'),('A060'),('A09X'),('J00X'),('J040'),
('J041'),('J042'),('J060'),('J068'),('J069'),
('J209'),('H650'),('H651'),('H660'),('H669'),
('J010'),('J011'),('J012'),('J013'),('J0145'),
('J019'),('J129'),('J189'),('A369'),('A370'),
('A371'),('A378'),('A379'),('J120'),('J121'),
('J122'),('J123'),('J128'),('J13X'),('J14X'),
('J150'),('J151'),('J152'),('J153'),('J154'),
('J157'),('J158'),('J159'),('J160'),('J168'),
('J050'),('J051'),('J851'),('J860'),('J869'),
('J100'),('J111'),('J155'),('J156'),('J18'),
('J181'),('J182'),('J188'),('A031'),('A032'),
('A033'),('A038'),('J210'),('J211'),('J218'),
('J219'),('J440'),('J441'),('J448'),('J449'),
('J450'),('J451'),('J458'),('J459'),('J4591'),
('J46X'),('99199.11'),('99401.08'),
('99401.12'),('99401.24');

-- ============================================
-- CONFIGURACIÓN DE RENDIMIENTO
-- ============================================

SET work_mem = '512MB';
--SET maintenance_work_mem = '2GB';
SET maintenance_work_mem = '2047MB';
SET max_parallel_workers_per_gather = 8;
SET synchronous_commit = off;


-- ============================================
-- CITAS VÁLIDAS
-- ============================================

DROP TABLE IF EXISTS tmp_citas_validas;

CREATE TEMP TABLE tmp_citas_validas AS
SELECT DISTINCT id_cita
FROM es_ivan.his_proceso
WHERE anio = {ANIO}
AND codigo_item IN (
    SELECT codigo
    FROM tmp_codigos_iras_edas
);



-- ============================================
-- ÍNDICES
-- ============================================

CREATE INDEX idx_tmp_citas_validas
ON tmp_citas_validas(id_cita);

ANALYZE tmp_citas_validas;

-- ============================================
-- CREAR TABLA (si no existe)
-- ============================================

DROP TABLE IF EXISTS es_ivan.tabla_iras_edas;
CREATE TABLE es_ivan.tabla_iras_edas AS
SELECT *
FROM es_ivan.his_proceso
WHERE 1=0;

-- ============================================
-- ELIMINAR INFORMACIÓN DEL AÑO
-- ============================================

DELETE FROM es_ivan.tabla_iras_edas
WHERE anio = {ANIO};

-- ============================================
-- INSERT FINAL
-- ============================================

INSERT INTO es_ivan.tabla_iras_edas
SELECT nt.*
FROM es_ivan.his_proceso nt
INNER JOIN tmp_citas_validas v
    ON nt.id_cita = v.id_cita
WHERE nt.anio = {ANIO};

-- ============================================
-- ESTADÍSTICAS
-- ============================================

--ANALYZE es_ivan.tabla_iras_edas;



