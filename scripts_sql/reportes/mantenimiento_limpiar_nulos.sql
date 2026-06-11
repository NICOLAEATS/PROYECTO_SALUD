-- LIMPIEZA DE REGISTROS INVÁLIDOS EN LA TABLA FULL
DELETE FROM es_ivan.hisminsa_consolidado_full
WHERE id_paciente IS NULL 
   OR codigo_item IS NULL 
   OR fecha_atencion IS NULL;

-- Estandarizar etnia vacía a '0'
UPDATE es_ivan.hisminsa_consolidado_full
SET id_etnia = '0'
WHERE id_etnia IS NULL OR id_etnia = '';