-- 1. CREAR TABLA TEMPORAL CON CÓDIGOS DE EDAS Y IRAS
DROP TABLE IF EXISTS tmp_codigos_iras_edas;
CREATE TEMP TABLE tmp_codigos_iras_edas (codigo varchar PRIMARY KEY);

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
('J46X');

-- 2. CREAR LA TABLA PRINCIPAL DE EDAS E IRAS DESDE HIS_PROCESO
DROP TABLE IF EXISTS es_ivan.tabla_iras_edas;

CREATE TABLE es_ivan.tabla_iras_edas AS
SELECT
    a.anio, a.mes, a.cod_2000, a.red, a.provincia, a.distrito, a.microred,
    a.nombre_establecimiento, a.id_cita, a.tipo_diagnostico, a.codigo_item,
    a.tip_edad, a.edad
FROM es_ivan.his_proceso a
WHERE a.codigo_item IN (SELECT codigo FROM tmp_codigos_iras_edas)
   OR a.codigo_item LIKE 'E86%' 
   OR a.codigo_item LIKE 'R57%' 
   OR a.codigo_item LIKE 'K56%' 
   OR a.codigo_item LIKE 'E87%';

-- 3. CREAR ÍNDICES PARA QUE LOS REPORTES SEAN RÁPIDOS
CREATE INDEX IF NOT EXISTS idx_iras_edas_anio ON es_ivan.tabla_iras_edas(anio);
CREATE INDEX IF NOT EXISTS idx_iras_edas_cita ON es_ivan.tabla_iras_edas(id_cita);
CREATE INDEX IF NOT EXISTS idx_iras_edas_codigo ON es_ivan.tabla_iras_edas(codigo_item);