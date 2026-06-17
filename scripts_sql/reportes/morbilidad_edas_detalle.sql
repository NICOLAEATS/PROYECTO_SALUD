-- REPORTE DETALLADO DE EDAs
SELECT 
    h.fecha_atencion,
    h.mes,
    h.nombre_completo_paciente,
    h.dni_paciente,
    h.codigo_item as cie10,
    h.valor_lab
FROM es_ivan.hisminsa_consolidado_full h
WHERE (h.codigo_item LIKE 'A0%' 
    OR h.codigo_item LIKE 'A01%' 
    OR h.codigo_item LIKE 'A09%')
  AND h.anio = '2024'
ORDER BY h.fecha_atencion DESC;