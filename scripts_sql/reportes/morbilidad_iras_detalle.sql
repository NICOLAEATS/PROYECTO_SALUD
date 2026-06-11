-- REPORTE DETALLADO DE IRAs
SELECT 
    h.fecha_atencion,
    h.mes,
    h.nombre_completo_paciente,
    h.edad_reg || ' ' || h.tipo_edad as edad_formateada,
    h.codigo_item as cie10,
    h.valor_lab,
    h.nombre_completo_personal as atendido_por
FROM es_ivan.hisminsa_consolidado_full h
WHERE (h.codigo_item LIKE 'J00%' 
    OR h.codigo_item LIKE 'J01%' 
    OR h.codigo_item LIKE 'J02%' 
    OR h.codigo_item LIKE 'J03%' 
    OR h.codigo_item LIKE 'J04%' 
    OR h.codigo_item LIKE 'J06%')
  AND h.anio = '2024'
ORDER BY h.fecha_atencion DESC;