CREATE TABLE {ESQUEMA}.VACUNAS_{ANIO} AS
SELECT
    h.id_cita,
    h.anio,
    h.mes,
    h.cod_2000,
    h.red,
    h.nombre_establecimiento,
    h.codigo_item,
    h.valor_lab,
    h.tip_edad,
    h.edad,
    h.genero,
    h.fecha_atencion,
    h.dni_paciente,
    h.fecha_nacimiento
FROM {ESQUEMA}.tabla_vacunas h
WHERE h.anio IS NOT NULL;
