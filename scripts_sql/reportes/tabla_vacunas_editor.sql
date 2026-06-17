CREATE TABLE {ESQUEMA}.tabla_vacunas AS
SELECT
    hp.id_cita,
    hp.anio,
    hp.mes,
    hp.codigo_item,
    hp.valor_lab,
    hp.tip_edad,
    hp.edad,
    hp.cod_2000,
    COALESCE(hp.red::text, '') AS red,
    COALESCE(hp.desc_ue::text, '') AS desc_ue,
    COALESCE(hp.microred::text, '') AS microred,
    COALESCE(hp.provincia::text, '') AS provincia,
    COALESCE(hp.distrito::text, '') AS distrito,
    COALESCE(hp.dni_paciente::text, '') AS dni_paciente,
    hp.fecha_atencion,
    hp.fecha_nacimiento,
    COALESCE(hp.nombre_establecimiento::text, '') AS nombre_establecimiento,
    COALESCE(hp.tipo_diagnostico::text, '') AS tipo_diagnostico,
    COALESCE(hp.fg_tipo::text, '') AS fg_tipo,
    COALESCE(hp.id_etnia::text, '') AS id_etnia,
    COALESCE(hp.genero::text, '') AS genero,
    COALESCE(hp.id_establecimiento::text, '') AS id_establecimiento
FROM {ESQUEMA}.his_proceso hp
WHERE {FILTRO_ANIO}
  AND hp.codigo_item = ANY(%s);
