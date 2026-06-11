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
('99199.28'),('C0011'),('Z001'),('C8002'),('R628'),
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

--solo  se habilita para carga total  por años--
---DROP TABLE IF EXISTS es_ivan.tabla_vacunas;

---CREATE TABLE es_ivan.tabla_vacunas
---AS SELECT * FROM es_ivan.his_proceso WHERE 1=0;


SET work_mem = '512MB';
SET maintenance_work_mem = '2GB';
SET max_parallel_workers_per_gather = 8;
SET synchronous_commit = off;


CREATE TEMP TABLE tmp_citas_validas AS
SELECT DISTINCT id_cita
FROM es_ivan.his_proceso
WHERE anio = 2025
AND codigo_item IN (SELECT codigo FROM tmp_codigos_vacunas);

-- 🔥 2. Índice clave
CREATE INDEX idx_tmp_citas_validas
ON tmp_citas_validas(id_cita);

-- 🔥 3. Limpieza rápida
DELETE FROM es_ivan.tabla_vacunas
WHERE anio = 2025;

-- 🔥 4. Insert rápido (JOIN eficiente)
INSERT INTO es_ivan.tabla_vacunas
SELECT nt.*
FROM es_ivan.his_proceso nt
JOIN tmp_citas_validas v
    ON nt.id_cita = v.id_cita
WHERE nt.anio = 2025;





























































DELETE FROM es_ivan.tabla_vacunas
WHERE anio = 2025;


INSERT INTO es_ivan.tabla_vacunas
SELECT nt.*
FROM es_ivan.his_proceso nt
WHERE nt.anio = 2025
AND nt.id_cita IN (
    SELECT x.id_cita
    FROM es_ivan.his_proceso x
    WHERE x.anio = 2025
    AND x.codigo_item IN (SELECT codigo FROM tmp_codigos_vacunas)
);









---original

/*

-- 🚀 insertar datos
INSERT INTO es_ivan.tabla_vacunas

SELECT nt.*
FROM es_ivan.his_proceso nt
WHERE nt.anio = 2024
AND EXISTS (
    SELECT 1
    FROM es_ivan.his_proceso x
    INNER JOIN tmp_codigos_vacunas tc
        ON x.codigo_item = tc.codigo
    WHERE x.id_cita = nt.id_cita
    AND x.anio = 2024
);


*/
/*
---duplicados
SELECT 
    id_cita,
    COUNT(*) AS cantidad
FROM es_ivan.hisminsa24
where anio=2023 and codigo_item ='90707' and valor_lab  in('1', 'D1') and tipo_edad ='A' and edad_reg =1
GROUP BY id_cita
HAVING COUNT(*) > 1;   */