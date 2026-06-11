-- INDICADOR: SUPLEMENTACIÓN PREVENTIVA CON HIERRO
SELECT 
    h.mes,
    h.dni_paciente,
    h.nombre_completo_paciente,
    h.edad_reg as edad_meses,
    h.codigo_item,
    h.valor_lab as dosis,
    h.fecha_atencion
FROM es_ivan.hisminsa_consolidado_full h
WHERE h.codigo_item IN ('99199.17', '99199.19') 
  AND h.tipo_edad = 'M' 
  AND h.edad_reg IN (4, 5)
  AND h.anio = '2024'
ORDER BY h.mes, h.nombre_completo_paciente;