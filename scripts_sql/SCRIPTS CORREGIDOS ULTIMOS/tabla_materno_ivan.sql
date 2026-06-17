CREATE INDEX IF NOT EXISTS idx_hisminsa24_full
ON es_ivan.hisminsa24 (anio, codigo_item, id_paciente);


DROP TABLE IF EXISTS tmp_codigos_materno;

CREATE TEMP TABLE tmp_codigos_materno (
  codigo varchar PRIMARY KEY
);
INSERT INTO tmp_codigos_materno (codigo)
VALUES 
('Z3591'),('Z3592'),('Z3593'),('Z3491'),('Z3492'),('Z3493'),
('U1692'),('59025'),('Z3182'),('59514'),('76805'),('76830'),
('76827'),('80055.01'),('81002'),('82044'),('76816'),
('76817'),('59401.06'),('59813'),('59812'),('99412'),
('90715'),('99199.18'),('Z359'),('59430');

--select  * from tmp_codigos_materno

INSERT INTO tmp_codigos_materno (codigo)
SELECT DISTINCT codigo_item
FROM es_ivan.his_proceso
WHERE codigo_item LIKE 'O%';


-- Configuración de sesión
SET work_mem = '512MB';
SET maintenance_work_mem = '2047MB';
--SET maintenance_work_mem = '2GB';
SET max_parallel_workers_per_gather = 8;
SET synchronous_commit = off;


-- ============================================
-- CITAS VÁLIDAS
-- ============================================

DROP TABLE IF EXISTS tmp_citas_validas;

CREATE TEMP TABLE tmp_citas_validas AS
SELECT DISTINCT id_cita
FROM es_ivan.his_proceso
WHERE anio = 2026
AND codigo_item IN (
    SELECT codigo
    FROM tmp_codigos_materno
);

-- ============================================
-- ÍNDICE
-- ============================================

CREATE INDEX idx_tmp_citas_validas
ON tmp_citas_validas(id_cita);

-- ============================================
-- ELIMINAR AÑO
-- ============================================

DELETE FROM es_ivan.tabla_materno
WHERE anio = 2026;

-- ============================================
-- INSERT FINAL
-- ============================================

INSERT INTO es_ivan.tabla_materno
SELECT nt.*
FROM es_ivan.his_proceso nt
INNER JOIN tmp_citas_validas v
    ON nt.id_cita = v.id_cita
WHERE nt.anio = 2026;