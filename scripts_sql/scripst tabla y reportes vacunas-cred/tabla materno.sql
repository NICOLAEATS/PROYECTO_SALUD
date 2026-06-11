-- Tabla temporal de codigos
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

DROP TABLE IF EXISTS es_ivan.tabla_materno;

-- Agregar codigos que empiezan con O
INSERT INTO tmp_codigos_materno (codigo)
SELECT DISTINCT codigo_item
FROM es_ivan.his_proceso
WHERE codigo_item LIKE 'O%';

-- Crear o reemplazar tabla
CREATE TABLE es_ivan.tabla_materno AS
SELECT 
    id_cita, anio, mes, codigo_item, valor_lab, tip_edad, edad, cod_2000,
    COALESCE(red::text, '') as red,
    COALESCE(desc_ue::text, '') as desc_ue,
    COALESCE(microred::text, '') as microred,
    COALESCE(provincia::text, '') as provincia,
    COALESCE(distrito::text, '') as distrito,
    COALESCE(dni_paciente::text, '') as dni_paciente,
    fecha_atencion, fecha_nacimiento,
    COALESCE(nombre_establecimiento::text, '') as nombre_establecimiento,
    COALESCE(tipo_diagnostico::text, '') as tipo_diagnostico,
    COALESCE(fg_tipo::text, '') as fg_tipo,
    COALESCE(id_etnia::text, '') as id_etnia,
    COALESCE(genero::text, '') as genero,
    COALESCE(id_establecimiento::text, '') as id_establecimiento
FROM es_ivan.his_proceso nt
WHERE nt.anio = {ANIO}
AND EXISTS (
    SELECT 1
    FROM es_ivan.his_proceso x
    INNER JOIN tmp_codigos_materno tc
        ON x.codigo_item = tc.codigo
    WHERE x.id_cita = nt.id_cita
    AND x.anio = {ANIO}
);

-- Crear indice
CREATE INDEX IF NOT EXISTS idx_tabla_materno_id_cita
ON es_ivan.tabla_materno (id_cita);
