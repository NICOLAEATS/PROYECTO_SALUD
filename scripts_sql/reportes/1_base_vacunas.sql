-- CREAR ÍNDICES EN HIS_PROCESO PARA ACELERAR EL REPORTE DE VACUNAS
CREATE INDEX IF NOT EXISTS idx_his_base_vacunas 
ON es_ivan.his_proceso (anio, id_cita, codigo_item);

CREATE INDEX IF NOT EXISTS idx_his_edad_vacunas 
ON es_ivan.his_proceso (tip_edad, edad);