-- Índice (ejecutar una sola vez)
CREATE INDEX IF NOT EXISTS idx_hisminsa_anio_codigo
ON es_ivan.hisminsa24 (anio, codigo_item);

-- Tabla temporal de códigos
DROP TABLE IF EXISTS tmp_codigos_vacunas;

CREATE TEMP TABLE tmp_codigos_vacunas (
  codigo varchar PRIMARY KEY
);

INSERT INTO tmp_codigos_vacunas VALUES
('90585'),('90633.01'),('90648'),('90649'),('90657'),('90658'),('90669'),('90670'),
('90681'),('90687'),('90688'),('90701'),('90702'),('90707'),('90712'),('90713'),('90714'),
('90715'),('90716'),('90717'),('90722'),('90723'),('90744'),('90746'),('Z238'),('Z2511'),

('P070'),('P071'),('P0711'),('P0712'),('P0713'),('P072'),('P073'),
('99436'),('99381.01'),('99401.03'),('99411.01'),('99431'),('P599'),
('99381'),('99382'),('99383'),('99401.05'),('99401.07'),('99401.08'),
('99401'),('99401.16'),('99401.24'),('99401.25'),('99403.01'),
('99401.09'),('99401.12'),
('P929'),('99211'),('99209'),('99199.17'),('99199.27'),
('R620'),('D500'),('D501'),('D508'),('D509'),
('B700'),('B701'),('B760'),('B761'),('B8769'),('B779'),('B780'),
('B680'),('B681'),('B689'),('B79X'),('B820'),('B829'),
('A070'),('A071'),('A06'),('B663'),('B664'),('87178'),('B80X'),
('D99199.28'),('DC0011'),('Z001'),('C8002'),('R628'),
('E440'),('E45X'),('E6690'),('E669'),('E344'),
('U140'),('R456'),('Z720'),('Z721'),('Z722'),('Z133'),
('H351'),('H579'),('Z010'),('H538'),('H509'),('H530'),('H559'),
('H179'),('H029'),('H028'),('H527'),('67228'),('67229'),('92390'),
('99499.01'),('99499.02'),('99499.03'),('99499.04'),('99499.05'),
('99499.06'),('99499.07'),('99499.08'),('99499.09'),('99499.10'),
('96150.02'),('96150.03'),('96150.06'),('96150.08'),
('92226'),('92250'),('67043'),('99173'),
('H520'),('H521'),('H522'),('H523'),
('1330'),('D1286'),('D1110'),('D1351');

--select  * from tmp_codigos_vacunas

---,'Z3591','Z3592','Z3593','Z3491','Z3492','Z3493','U1692','59025','Z3182',
---('59514'),('76805'),('76830'),('76827'),('80055.01'),('81002'),('82044'),('76816'),('76817'),
---('59401.06'),('59813'),('59812'),('99412'),('90715'),('99199.18'),('Z359'),('59430'),('U1692'),('59401.06')

-- Configuración de sesión
SET work_mem = '512MB';
SET maintenance_work_mem = '2GB';
SET max_parallel_workers_per_gather = 8;
SET synchronous_commit = off;

-- Crear tabla final
DROP TABLE IF EXISTS es_ivan.tabla_vacunas;

CREATE TABLE es_ivan.tabla_vacunas  AS

-- 1️⃣ Obtener todas las citas que contienen al menos un código IRAS/EDAS
WITH citas_vacunas AS (
    SELECT DISTINCT nt.id_cita
    FROM es_ivan.his_proceso nt
    INNER JOIN tmp_codigos_vacunas tc
        ON nt.codigo_item = tc.codigo
    WHERE nt.anio between 2022 and 2026
)

-- 2️⃣ Traer TODOS los códigos registrados en esas citas
SELECT nt.*
FROM es_ivan.his_proceso nt
INNER JOIN citas_vacunas ci
    ON nt.id_cita = ci.id_cita
WHERE nt.anio between 2022 and 2026;


