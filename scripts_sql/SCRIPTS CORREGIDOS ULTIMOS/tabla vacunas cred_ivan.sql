-- Índice (ejecutar una sola vez)
CREATE INDEX IF NOT EXISTS idx_hisminsa_anio_codigo
ON es_ivan.hisminsa24 (anio, codigo_item);

-- Índice principal (CRÍTICO)
CREATE INDEX IF NOT EXISTS idx_his_proceso_anio_cita
ON es_ivan.his_proceso (anio, id_cita);

-- Índice para filtro de vacunas
CREATE INDEX IF NOT EXISTS idx_his_proceso_codigo
ON es_ivan.his_proceso (codigo_item);



-- Tabla temporal de códigos
/*DROP TABLE IF EXISTS tmp_codigos_vacunas;

CREATE TEMP TABLE tmp_codigos_vacunas (
  codigo varchar PRIMARY KEY
);
*/
-- ============================================
-- TABLA TEMPORAL DE CÓDIGOS
-- ============================================

DROP TABLE IF EXISTS tmp_codigos_vacunas;

CREATE TEMP TABLE tmp_codigos_vacunas (
    codigo VARCHAR(20)
);

INSERT INTO tmp_codigos_vacunas (codigo) VALUES
('A060'),('A061'),('A062'),('A063'),('A064'),('A065'),('A066'),('A067'),('A068'),('A069'),
('A070'),('A071'),('B663'),('B664'),('B680'),('B681'),('B689'),('B700'),('B701'),('B760'),
('B761'),('B779'),('B780'),('B79X'),('B80X'),('B820'),('B829'),('B8769'),('C0011'),('C8002'),
('D500'),('D501'),('D508'),('D509'),('D1110'),('D1286'),('D1330'),('D1351'),('E031'),('E250'),
('E344'),('E43X'),('E440'),('E45X'),('E660'),('E669'),('E6690'),('E700'),('E849'),('H028'),
('H029'),('H179'),('H351'),('H509'),('H520'),('H521'),('H522'),('H523'),('H527'),('H530'),
('H538'),('H559'),('H579'),('H902'),('J00X'),('J029'),('P07'),('P070'),('P071'),('P0711'),
('P0712'),('P0713'),('P072'),('P073'),('P080'),('P082'),('P599'),('P929'),('PH028'),('PH029'),
('PH179'),('PH509'),('PH527'),('PH530'),('PH538'),('PH559'),('Q02X'),('Q120'),('R456'),('R620'),
('R628'),('U140'),('U1692'),('Z001'),('Z010'),('Z133'),('Z238'),('Z2511'),('Z298'),('Z720'),
('Z721'),('Z722'),('Z724'),('36416'),('59430'),('67043'),('67228'),('67229'),('85018'),('85018.01'),('87177.01'),('87178'),
('90585'),('90633.01'),('90648'),('90649'),('90657'),('90658'),('90669'),('90670'),('90681'),('90687'),
('90688'),('90701'),('90702'),('90707'),('90712'),('90713'),('90714'),('90715'),('90716'),('90717'),
('90722'),('90723'),('90744'),('90746'),('92226'),('92250'),('92390'),('94760'),('96150.02'),('96150.03'),
('96150.06'),('96150.08'),('99173'),('99199.17'),('99199.26'),('99199.27'),('99199.28'),('99209'),('99211'),('99381'),
('99381.01'),('99382'),('99383'),('99401'),('99401.01'),('99401.03'),('99401.04'),('99401.05'),('99401.06'),('99401.07'),('99401.08'),
('99401.09'),('99401.1'),('99401.12'),('99401.16'),('99401.17'),('99401.24'),('99401.25'),('99403'),('99403.01'),('99411.01'),('99411.02'),
('99431'),('99431.01'),('99431.02'),('99431.021'),('99431.022'),('99433'),('99436'),('99436.02'),('99460'),('99499.01'),
('99499.02'),('99499.03'),('99499.04'),('99499.05'),('99499.06'),('99499.07'),('99499.08'),('99499.09'),('99499.10'),('99502'),
---nuevos
('96110.01'),('96110.02'),('96110.03'),('99209.01'),('99209.02'),('99209.04'),('99384,02'),('96150.01'),('R621'),('R6221'),('R6222'),('R6223'),('R6251'),('Z001'),('99181'),
('C7001.01'),('99401.37'),('99402.09'),('C0009'),('C0010');



-- ============================================
-- SOLO PARA CARGA TOTAL POR AÑO
-- ============================================

DROP TABLE IF EXISTS es_ivan.tabla_vacunas;
CREATE TABLE es_ivan.tabla_vacunas AS
SELECT *
FROM es_ivan.his_proceso
WHERE 1=0;

-- ============================================
-- OPTIMIZACIÓN
-- ============================================

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
WHERE anio = 2025
AND codigo_item IN (
    SELECT codigo
    FROM tmp_codigos_vacunas
);

-- ============================================
-- ÍNDICE
-- ============================================
CREATE INDEX idx_tmp_citas_validas
ON tmp_citas_validas(id_cita);

ANALYZE tmp_citas_validas;

-- ============================================
-- ELIMINAR AÑO
-- ============================================

DELETE FROM es_ivan.tabla_vacunas
WHERE anio = 2025;

-- ============================================
-- INSERT FINAL
-- ============================================

INSERT INTO es_ivan.tabla_vacunas
SELECT nt.*
FROM es_ivan.his_proceso nt
INNER JOIN tmp_citas_validas v
    ON nt.id_cita = v.id_cita
WHERE nt.anio = 2025;