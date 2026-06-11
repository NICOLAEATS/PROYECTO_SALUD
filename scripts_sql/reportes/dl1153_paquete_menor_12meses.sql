-- INDICADOR DL 1153: PAQUETE INTEGRADO NIÑOS < 12 MESES
WITH base AS (
    SELECT
        h.id_paciente,
        h.anio,
        h.mes,
        MAX(CASE WHEN h.codigo_item = 'Z001' THEN 1 ELSE 0 END) AS tiene_cred,
        MAX(CASE WHEN h.codigo_item = '90681' AND h.valor_lab = '2' THEN 1 ELSE 0 END) AS tiene_rotavirus,
        MAX(CASE WHEN h.codigo_item = '90670' AND h.valor_lab = '3' THEN 1 ELSE 0 END) AS tiene_neumococo,
        MAX(CASE WHEN h.codigo_item = '85018' THEN 1 ELSE 0 END) AS tiene_hemoglobina
    FROM es_ivan.hisminsa_consolidado_full h
    WHERE h.anio = '2024'
    GROUP BY h.id_paciente, h.anio, h.mes
)
SELECT 
    anio, 
    mes, 
    COUNT(DISTINCT id_paciente) as total_ninos,
    SUM(tiene_cred) as con_cred,
    SUM(CASE WHEN tiene_cred=1 AND tiene_rotavirus=1 AND tiene_neumococo=1 AND tiene_hemoglobina=1 THEN 1 ELSE 0 END) as paquete_completo
FROM base
GROUP BY anio, mes
ORDER BY mes;