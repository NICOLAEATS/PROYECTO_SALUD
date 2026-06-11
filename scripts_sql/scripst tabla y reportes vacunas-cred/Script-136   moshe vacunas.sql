--generar tabla pai
DROP TABLE IF EXISTS es_ivan.pai_{ANIO};

CREATE TABLE es_ivan.pai_{ANIO} AS
WITH base AS (
    SELECT 
        id_cita,
        anio,
        mes,
        codigo_item,
        valor_lab,
        tip_edad,
        edad,
        cod_2000,
        red,
        desc_ue,
        microred,
        provincia,
        distrito,
        dni_paciente,
        fecha_atencion,
        fecha_nacimiento,
        nombre_establecimiento,
        tipo_diagnostico,
        fg_tipo,
        id_etnia,
        genero,
        (fecha_atencion::date - fecha_nacimiento::date) AS edad_dias,
        (EXTRACT(YEAR FROM age(fecha_atencion, fecha_nacimiento)) * 12 +
        EXTRACT(MONTH FROM age(fecha_atencion, fecha_nacimiento)))::int AS edad_meses

    FROM es_ivan.tabla_vacunas
    WHERE anio >= {ANIO}
      AND codigo_item IN ('90585','90633.01','90648','90649','90657','90658','90669','90670',
   							 '90681','90687','90688','90701','90702','90707','90712','90713','90714',
   							 '90715','90716','90717','90722','90723','90744','90746','Z238','Z2511','99199.26','99403','99403.01','99436','99381.01','99401.03','99411.01','99431','J00X','P599','J029','99381','99382','99383','C8002','Z001',
      						'99401.05','99401.07','99401.08','99401.09','99401.12','99401.16','99401.24','99401.25','99403.01','99401.03','P929','99211','99211','99199.17','R620','R628','E440',
      						'E669','E6690','E45X','E43X','E344','87177.01','B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664','87178',
'B80X','99199.28','C0011','85018.01','P070','P071','P0711','P0712','P0713','P072','P073','U1692','59430','U140','R456','Z720','Z721','Z722','Z133',
    						'H351','H351','H579','H579','Z010','PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527',
'67228','67229','92390','99499.08','99499.09','99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10'
),

-- ============================================
-- 🔥 SOLO FLAG NECESARIO (GESTANTE)
-- ============================================
cita_flags_{ANIO} AS (
   SELECT 
    id_cita,

    /* 🔹 PRIMERO detectar puérpera */
    MAX( CASE WHEN b.genero = 'F' AND (b.codigo_item = '59430' OR b.valor_lab = 'P' OR (b.codigo_item = 'U1692' AND b.valor_lab = 'TA'))THEN 1 ELSE 0 end ) AS es_puerpera,

    /* 🔹 GESTANTE SOLO SI NO ES PUÉRPERA */
    CASE WHEN MAX(CASE WHEN b.genero = 'F' AND (b.codigo_item = '59430' OR b.valor_lab = 'P' OR (b.codigo_item = 'U1692' AND b.valor_lab = 'TA')) THEN 1 ELSE 0 END ) = 1  THEN 0  ELSE 
    MAX( CASE WHEN b.genero = 'F' THEN 1 ELSE 0 END) END AS es_gestante

FROM es_ivan.tabla_materno b
GROUP BY b.id_cita
),

flags_cita AS (
    SELECT
        id_cita,

        MAX((fg_tipo = 'CX')::int) AS flg_comorbilidad,
        MAX((valor_lab = 'ST')::int) AS flg_st,
        MAX((valor_lab = 'OM')::int) AS flg_om,
        MAX((valor_lab = 'VIH')::int) AS flg_vih,
        MAX((valor_lab = 'VPH')::int) AS flg_vph,
        MAX((valor_lab = 'AER')::int) AS flg_aer,
        MAX((valor_lab = 'TER')::int) AS flg_ter,
        MAX((valor_lab = 'FRON')::int) AS flg_fro,
        MAX((valor_lab = 'RSA')::int) AS flg_rsa,
        MAX((valor_lab = 'END')::int) AS flg_end,  -- ZONAS ENDEMICAS
        MAX((valor_lab = 'FNI')::int) AS flg_fni,  -- FENÓMENO DEL NIÑO
        MAX((valor_lab = 'PNP')::int) AS flg_pnp,
        MAX((valor_lab = 'M')::int) AS flg_m,
        MAX((valor_lab = 'EF')::int) AS flg_ef,
        MAX((valor_lab = 'BOM')::int) AS flg_bom,
        MAX((valor_lab = 'DCI')::int) AS flg_dci,
        MAX((valor_lab = 'EST')::int) AS flg_est,
        MAX((valor_lab = 'CR')::int) AS flg_cr,

        MAX((valor_lab IN ('IN','PPL'))::int) AS flg_inpe_ppl,
        MAX((valor_lab = 'REH')::int) AS flg_reh,
        MAX((valor_lab IN ('RS','RSA','RMA'))::int) AS flg_hf,
        MAX((valor_lab = 'SR')::int) AS flg_sr,
        MAX((valor_lab = 'DIS')::int) AS flg_dis,

        MAX((valor_lab IN ('TS','HSH','HTS','TTS','PNP','M','BOM','DCI','EST','TRA','PPL','G','P','OTR','VIH','OM'))::int) AS flg_otr,

        MAX((valor_lab IN ('E1','DE1','E2','DE2','E3','DE3','E4','DE4'))::int) AS flg_enf,

        MAX((id_etnia IN ('56','57','58','59','60'))::int) AS flg_etnia

    FROM base
    GROUP BY id_cita
),
-- ============================================
-- 🔥 AGREGACIÓN FINAL (SIN EXCESOS)
-- ============================================
monitoreo_general AS (
SELECT
  	h.anio,
	h.mes,
	h.cod_2000,
	h.red,
	h.desc_ue,
	h.microred,
	h.provincia,
	h.distrito,
	h.nombre_establecimiento,



     
 --   DT – GESTANTES (código 90714)
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS gestantes_dt1_10_11,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS gestantes_dt2_10_11,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS gestantes_dt3_10_11,

SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS gestantes_dt1_12_17,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS gestantes_dt2_12_17,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS gestantes_dt3_12_17,

SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS gestantes_dt1_18_29,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS gestantes_dt2_18_29,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS gestantes_dt3_18_29,

SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS gestantes_dt1_30_49,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS gestantes_dt2_30_49,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS gestantes_dt3_30_49,

SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab = '1' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS gestante_Tdap1_10_11a,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab = '1' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS gestante_Tdap1_12_17a,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab = '1' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS gestante_Tdap1_18_29a,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab = '1' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS gestante_Tdap1_30_49a,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab = '1' AND h.edad BETWEEN 50 AND 60 THEN 1 ELSE 0 END) AS gestante_Tdap1_50_60a,

   
 SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS no_gestantes_dt1_10_11,
SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS no_gestantes_dt2_10_11,
SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS no_gestantes_dt3_10_11,

SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS no_gestantes_dt1_12_17,
SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS no_gestantes_dt2_12_17,
SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS no_gestantes_dt3_12_17,

SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS no_gestantes_dt1_18_29,
SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS no_gestantes_dt2_18_29,
SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS no_gestantes_dt3_18_29,

SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS no_gestantes_dt1_30_49,
SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS no_gestantes_dt2_30_49,
SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS no_gestantes_dt3_30_49,

SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 50 AND 59 THEN 1 ELSE 0 END) AS no_gestantes_dt1_50_59,
SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 50 AND 59 THEN 1 ELSE 0 END) AS no_gestantes_dt2_50_59,
SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 50 AND 59 THEN 1 ELSE 0 END) AS no_gestantes_dt3_50_59,

SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad >= 60 THEN 1 ELSE 0 END) AS no_gestantes_dt1_may_60a,
SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad >= 60 THEN 1 ELSE 0 END) AS no_gestantes_dt2_may_60a,
SUM(CASE WHEN ci.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad >= 60 THEN 1 ELSE 0 END) AS no_gestantes_dt3_may_60a,

SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('1','D1') AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS varones_dt1_10_11,
SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('2','D2') AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS varones_dt2_10_11,
SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('3','D3') AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS varones_dt3_10_11,

SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('1','D1') AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS varones_dt1_12_17,
SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('2','D2') AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS varones_dt2_12_17,
SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('3','D3') AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS varones_dt3_12_17,

SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('1','D1') AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS varones_dt1_18_29,
SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('2','D2') AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS varones_dt2_18_29,
SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('3','D3') AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS varones_dt3_18_29,
-- 30–49 años

SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('1','D1') AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS varones_dt1_30_49,
SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('2','D2') AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS varones_dt2_30_49,
SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('3','D3') AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS varones_dt3_30_49,

SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('1','D1') AND h.edad >= 60 THEN 1 ELSE 0 END) AS varones_dt1_60a_mas,
SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('2','D2') AND h.edad >= 60 THEN 1 ELSE 0 END) AS varones_dt2_60a_mas,
SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('3','D3') AND h.edad >= 60 THEN 1 ELSE 0 END) AS varones_dt3_60a_mas,

-- BCG
SUM(CASE WHEN h.codigo_item = '90585' AND h.valor_lab IN ('', 'DU', '1', 'D1') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS bcg_12horas,
SUM(CASE WHEN h.codigo_item = '90585' AND h.valor_lab IN ('1', 'D1') AND h.tip_edad = 'D' AND h.edad BETWEEN 2 AND 29 THEN 1 ELSE 0 END) AS bcg_12_24h,
SUM(CASE WHEN h.codigo_item = '90585' AND h.valor_lab IN ('1', 'D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS bcg_1_11m,

-- HVB
SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('', 'DU') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS hvb_12_24h,
SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('1', 'D1') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS hvb_24h,

-- PENTA
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna Penta1 men_1a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna Penta2 men_1a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna Penta3 men_1a",

-- IPV
SUM(CASE WHEN h.codigo_item = '90713' AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna Ipv1 men_1a",
SUM(CASE WHEN h.codigo_item = '90713' AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna Ipv2 men_1a",
SUM(CASE WHEN h.codigo_item = '90713' AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna Ipv3 men_1a",

-- Neumococo
SUM(CASE WHEN h.codigo_item = '90670' AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna neumo1 men_1a",
SUM(CASE WHEN h.codigo_item = '90670' AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna neumo2 men_1a",

-- Rotavirus
SUM(CASE WHEN h.codigo_item = '90681' AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna rotav1 men_1a",
SUM(CASE WHEN h.codigo_item = '90681' AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna rotav2 men_1a",

-- Influenza
SUM(CASE WHEN h.codigo_item = '90657' AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna influenza1 men_1a",
SUM(CASE WHEN h.codigo_item = '90657' AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna influenza2 men_1a",

-- DT pediátrico
SUM(CASE WHEN h.codigo_item = '90702' AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico2 men_1a",
SUM(CASE WHEN h.codigo_item = '90702' AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico3 men_1a",

-- HIB
SUM(CASE WHEN h.codigo_item = '90648' AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna hib2 men_1a",
SUM(CASE WHEN h.codigo_item = '90648' AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna hib3 men_1a",

-- Hepatitis B
SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna HVB2 men_1a",
SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna HVB3 men_1a",

-- VACUNACIÓN 1 AÑO
SUM(CASE WHEN h.codigo_item IN ('90717') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna AMA1 1a",
SUM(CASE WHEN h.codigo_item IN ('90633.01') AND h.valor_lab IN ('1','D1','DU') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna Hepatitis1 A 1a",
SUM(CASE WHEN h.codigo_item IN ('90670') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "NEUMO1 1a",

SUM(CASE WHEN h.codigo_item IN ('90707') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna SPR1 1a",
SUM(CASE WHEN h.codigo_item IN ('90707') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna SPR2 1a",

SUM(CASE WHEN h.codigo_item IN ('90716') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna VARICELA1 1a",

SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90687') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna influenza1 1a",
SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90687') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna influenza2 1a",
SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90687') AND h.valor_lab IN ('DU','DA','DDA') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna influenza DU 1a",

SUM(CASE WHEN h.codigo_item IN ('90701') AND h.valor_lab IN ('DA','DDA') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna DPT1 1a",

SUM(CASE WHEN h.codigo_item IN ('90712','90713') AND h.valor_lab IN ('DA','DDA') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna APO_IPV 1a",

SUM(CASE WHEN h.codigo_item IN ('90713') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna IPV1 1a",
SUM(CASE WHEN h.codigo_item IN ('90713') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna IPV2 1a",

SUM(CASE WHEN h.codigo_item IN ('90712','90713') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna APO3 1a",

SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna Penta1 1a",

SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna Penta2 1a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna Penta3 1a",

SUM(CASE WHEN h.codigo_item IN ('90702') AND h.valor_lab IN ('2','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico2 1a",
SUM(CASE WHEN h.codigo_item IN ('90702') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico3 1a",

SUM(CASE WHEN h.codigo_item IN ('90648') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna hib2 1a",
SUM(CASE WHEN h.codigo_item IN ('90648') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna hib3 1a",

SUM(CASE WHEN h.codigo_item IN ('90744') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna HVB2 1a",
SUM(CASE WHEN h.codigo_item IN ('90744') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna HVB3 1a",

SUM(CASE WHEN h.codigo_item IN ('90585') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "BCG Contacto de TB P 1a",

---VACUNACION  DE 2 AÑO

SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_comorbilidad = 1 AND h.edad = 2 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS "influenza1_con_morbi 2a",
SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_comorbilidad = 0 AND h.edad = 2 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS "influenza1 sin morbi 2a",

SUM(CASE WHEN h.codigo_item IN ('90669','90670','Z238') AND h.valor_lab IN ('DU','DA','DAA') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Neumococo con Comorbilidad 2a",

SUM(CASE WHEN h.codigo_item IN ('90717') AND h.valor_lab IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna AMA 2a",

-- trazador
SUM(CASE WHEN h.codigo_item IN ('90657') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "3325405 Vacuna influenza1 2a",
SUM(CASE WHEN h.codigo_item IN ('90713') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna IPV1 2a",
SUM(CASE WHEN h.codigo_item IN ('90713') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna IPV2 2a",

SUM(CASE WHEN h.codigo_item IN ('90712','90713') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna APO3 2a",

SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna Penta1 2a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna Penta2 2a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna Penta3 2a",

SUM(CASE WHEN h.codigo_item IN ('90702') AND h.valor_lab IN ('2','D3') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico2 2a",
SUM(CASE WHEN h.codigo_item IN ('90702') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico3 2a",

SUM(CASE WHEN h.codigo_item IN ('90648') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna hib2 2a",
SUM(CASE WHEN h.codigo_item IN ('90648') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna hib3 2a",

SUM(CASE WHEN h.codigo_item IN ('90744') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna HVB2 2a",
SUM(CASE WHEN h.codigo_item IN ('90744') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna HVB3 2a",

SUM(CASE WHEN h.codigo_item IN ('90585') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "BCG (Contacto de TB P) 2a",

SUM(CASE WHEN h.codigo_item IN ('90716') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna VARICELA1 2a",
  
SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna influenza1 con morbi 3a",
SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna influenza1 sin morbi 3a",

SUM(CASE WHEN h.codigo_item IN ('90669','90670','Z238') AND h.valor_lab IN ('DU','DA','DAA') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Neumococo con Comorbilidad 3a",

SUM(CASE WHEN h.codigo_item IN ('90717') AND h.valor_lab IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna AMA 3a",

-- trazador
SUM(CASE WHEN h.codigo_item IN ('90657') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna influenza1 3a",

SUM(CASE WHEN h.codigo_item IN ('90713') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna IPV1 3a",
SUM(CASE WHEN h.codigo_item IN ('90713') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna IPV2 3a",

SUM(CASE WHEN h.codigo_item IN ('90712','90713') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna APO3 3a",

SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna Penta1 3a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna Penta2 3a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna Penta3 3a",

SUM(CASE WHEN h.codigo_item IN ('90702') AND h.valor_lab IN ('2','D3') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico2 3a",
SUM(CASE WHEN h.codigo_item IN ('90702') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico3 3a",

SUM(CASE WHEN h.codigo_item IN ('90648') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna hib2 3a",
SUM(CASE WHEN h.codigo_item IN ('90648') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna hib3 3a",

SUM(CASE WHEN h.codigo_item IN ('90744') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna HVB2 3a",
SUM(CASE WHEN h.codigo_item IN ('90744') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna HVB3 3a",

SUM(CASE WHEN h.codigo_item IN ('90585') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "BCG Contacto de TB P 3a",

SUM(CASE WHEN h.codigo_item IN ('90716') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna VARICELA1 3a",


SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna influenza1 con morbi 4a",
SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna influenza1 sin morbi 4a",

SUM(CASE WHEN h.codigo_item IN ('90669','90670','Z238') AND h.valor_lab IN ('DU','DA','DAA') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Neumococo con Comorbilidad 4a",

SUM(CASE WHEN h.codigo_item IN ('90717') AND h.valor_lab IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna AMA 4a",

-- trazador
SUM(CASE WHEN h.codigo_item IN ('90657') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna influenza1 4a",

SUM(CASE WHEN h.codigo_item IN ('90713') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna IPV1 4a",
SUM(CASE WHEN h.codigo_item IN ('90713') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna IPV2 4a",

SUM(CASE WHEN h.codigo_item IN ('90712','90713') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna APO3 4a",

SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna Penta1 4a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna Penta2 4a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna Penta3 4a",

SUM(CASE WHEN h.codigo_item IN ('90702') AND h.valor_lab IN ('2','D3') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico2 4a",
SUM(CASE WHEN h.codigo_item IN ('90702') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico3 4a",

SUM(CASE WHEN h.codigo_item IN ('90648') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna hib2 4a",
SUM(CASE WHEN h.codigo_item IN ('90648') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna hib3 4a",

SUM(CASE WHEN h.codigo_item IN ('90744') AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna HVB2 4a",
SUM(CASE WHEN h.codigo_item IN ('90744') AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna HVB3 4a",

SUM(CASE WHEN h.codigo_item IN ('90585') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "BCG Contacto de TB P 4a",

SUM(CASE WHEN h.codigo_item IN ('90701') AND h.valor_lab IN ('DA','DDA') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna DPT1 4a",

SUM(CASE WHEN h.codigo_item IN ('90712','90713') AND h.valor_lab IN ('DA','DDA') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna APO_IPV 4a",

SUM(CASE WHEN h.codigo_item IN ('90716') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna VARICELA1 4a",

-- VACUNACIÓN NEONATO
SUM(CASE WHEN h.codigo_item = '90585' AND h.valor_lab IN ('DU','1','D1') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna BCG RN 24H",
SUM(CASE WHEN h.codigo_item = '90585' AND h.valor_lab IN ('DU','1','D1') AND h.tip_edad = 'D' AND h.edad > 1 THEN 1 ELSE 0 END) AS "Vacuna BCG RN 2-28DIAS",
SUM(CASE WHEN h.codigo_item = '90585' AND h.valor_lab IN ('DU','1','D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna BCG MEN1A",

SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('','DU') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna HVB RN 12H",
SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna HVB RN 24H",

-- REACCIONES ADVERSAS
SUM(CASE WHEN h.codigo_item = 'T881' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS "Reacciones Adversas por vacuna",

SUM(CASE WHEN h.codigo_item = '90670' AND h.tipo_diagnostico = 'D' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS "Vacuna Neum madres VIH",

-- SARAMPIÓN – RUBÉOLA
SUM(CASE WHEN h.codigo_item = '90707' AND h.valor_lab IN ('1','D1','DU','DDA','BD','BU') AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS "Vacuna SPR 5-11a",
SUM(CASE WHEN h.codigo_item = '90707' AND h.valor_lab IN ('1','D1','DU','DDA','BD','BU') AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS "Vacuna SPR 12-17a",
SUM(CASE WHEN h.codigo_item = '90707' AND h.valor_lab IN ('1','D1','DU','DDA','BD','BU') AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS "Vacuna SPR 18-29a",
SUM(CASE WHEN h.codigo_item = '90707' AND h.valor_lab IN ('1','D1','DU','DDA','BD','BU') AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS "Vacuna SPR 30-49a",
SUM(CASE WHEN h.codigo_item = '90707' AND h.valor_lab IN ('1','D1','DU','DDA','BD','BU') AND h.tip_edad = 'A' AND h.edad >= 50 THEN 1 ELSE 0 END) AS "Vacuna SPR 50AMAS",

-- SPR con banderas
SUM(CASE WHEN h.codigo_item = '90707' AND h.valor_lab IN ('DU','') AND f.flg_ST = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY18a_ST,
SUM(CASE WHEN h.codigo_item = '90707' AND h.valor_lab IN ('DU','') AND f.flg_AER = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY18a_AER,
SUM(CASE WHEN h.codigo_item = '90707' AND h.valor_lab IN ('DU','') AND f.flg_TER = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY18a_TER,

SUM(CASE WHEN h.codigo_item = '90707' AND h.valor_lab IN ('FRO','') AND f.flg_AER = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY18a_FRON,

SUM(CASE WHEN h.codigo_item = '90707' AND h.valor_lab IN ('DU','') AND f.flg_RSA = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY18a_RSA,
SUM(CASE WHEN h.codigo_item = '90707' AND h.valor_lab IN ('DU','') AND f.flg_END = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY18a_END,

SUM(CASE WHEN h.codigo_item = '90707' AND h.valor_lab IN ('DU','') AND f.flg_etnia = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY5a_ETNIA,

 
SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS "Vacuna HVB1 5-11a",

SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS "Vacuna HVB1 12-17a",

SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS "Vacuna HVB1 18-29a",

SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 59 THEN 1 ELSE 0 END) AS "Vacuna HVB1 30-59a",

SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('1','D1') AND h.tip_edad = 'A' AND h.edad >= 60 THEN 1 ELSE 0 END) AS "Vacuna HVB1 60AMAS",


SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS "Vacuna HVB2 5-11a",

SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS "Vacuna HVB2 12-17a",

SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS "Vacuna HVB2 18-29a",

SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 59 THEN 1 ELSE 0 END) AS "Vacuna HVB2 30-59a",

SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('2','D2') AND h.tip_edad = 'A' AND h.edad >= 60 THEN 1 ELSE 0 END) AS "Vacuna HVB2 60AMAS",


SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS "Vacuna HVB3 5-11a",

SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS "Vacuna HVB3 12-17a",

SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS "Vacuna HVB3 18-29a",

SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 59 THEN 1 ELSE 0 END) AS "Vacuna HVB3 30-59a",

SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('3','D3') AND h.tip_edad = 'A' AND h.edad >= 60 THEN 1 ELSE 0 END) AS "Vacuna HVB3 60AMAS",


SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('1','D1') AND f.flg_ST = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS HVB1_MAY5_ST,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('2','D2') AND f.flg_ST = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS HVB2_MAY5_ST,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('3','D3') AND f.flg_ST = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS HVB3_MAY5_ST,


SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('1','D1') AND f.flg_VIH = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS HVB1_MAY5_VIH,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('2','D2') AND f.flg_VIH = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS HVB2_MAY5_VIH,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('3','D3') AND f.flg_VIH = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS HVB3_MAY5_VIH,


SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('1','D1') AND f.flg_OM = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS HVB1_MAY5_OM,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('2','D2') AND f.flg_OM = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS HVB2_MAY5_OM,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('3','D3') AND f.flg_OM = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS HVB3_MAY5_OM,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('1','D1') AND f.flg_OTR = 1 AND h.edad >= 18 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS HVB1_MAY5_OTR,
SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('2','D2') AND f.flg_OTR = 1 AND h.edad >= 5 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS HVB2_MAY5_OTR,
SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('3','D3') AND f.flg_OTR = 1 AND h.edad >= 5 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS HVB3_MAY5_OTR,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('1','D1') AND f.flg_ENF = 1 AND h.edad >= 18 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS HVB1_MAY5_ENF,
SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('2','D2') AND f.flg_ENF = 1 AND h.edad >= 5 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS HVB2_MAY5_ENF,
SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND h.valor_lab IN ('3','D3') AND f.flg_ENF = 1 AND h.edad >= 5 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS HVB3_MAY5_ENF,

SUM(CASE WHEN h.codigo_item = '90717' AND h.valor_lab IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS "Vacuna AMA 5_11a",
SUM(CASE WHEN h.codigo_item = '90717' AND h.valor_lab IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS "Vacuna AMA 12_17a",
SUM(CASE WHEN h.codigo_item = '90717' AND h.valor_lab IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS "Vacuna AMA 18_29a",
SUM(CASE WHEN h.codigo_item = '90717' AND h.valor_lab IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 59 THEN 1 ELSE 0 END) AS "Vacuna AMA 30_59a",
SUM(CASE WHEN h.codigo_item = '90717' AND h.valor_lab IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad >= 60 THEN 1 ELSE 0 END) AS "Vacuna AMA 60A_MASa",

SUM(CASE WHEN h.codigo_item = '90716' AND h.valor_lab IN ('1','D1','DU','BU','DA','DDA','') AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS "Vacuna varicela 5_11a",
SUM(CASE WHEN h.codigo_item = '90716' AND h.valor_lab IN ('1','D1','DU','BU','DA','DDA','') AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS "Vacuna varicela 12_17a",
SUM(CASE WHEN h.codigo_item = '90716' AND h.valor_lab IN ('1','D1','DU','BU','DA','DDA','') AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS "Vacuna varicela 18_29a",
SUM(CASE WHEN h.codigo_item = '90716' AND h.valor_lab IN ('1','D1','DU','BU','DA','DDA','') AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 59 THEN 1 ELSE 0 END) AS "Vacuna varicela 30_59a",
SUM(CASE WHEN h.codigo_item = '90716' AND h.valor_lab IN ('1','D1','DU','BU','DA','DDA','') AND h.tip_edad = 'A' AND h.edad >= 60 THEN 1 ELSE 0 END) AS "Vacuna varicela 60A_MASa",

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS neumo1_5_11a_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS neumo1_12_17a_mas_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS neumo1_18_29a_mas_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS neumo1_30_49a_mas_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 50 AND 59 THEN 1 ELSE 0 END) AS neumo1_50_59a_mas_comorb,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS neumo_5_11a_sin_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS neumo_12_17a_sin_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS neumo_18_29a_sin_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS neumo_30_49a_sin_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 50 AND 59 THEN 1 ELSE 0 END) AS neumo_50_59a_sin_comorb,-- ================================

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND h.edad >= 60 THEN 1 ELSE 0 END) AS neumo_60a_mas,

SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') THEN 1 ELSE 0 END) AS neumo_gest,

SUM(CASE WHEN ci.es_puerpera = 1 AND h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') THEN 1 ELSE 0 END) AS neumo_puerpera,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_ST = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_st,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_FNI = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_fni,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_PNP = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_pnp,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_M = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_m,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_BOM = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_bom,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_DCI = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_dci,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_EST = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_est,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_CR = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_cr,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_INPE_PPL = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_inpe_ppl,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_REH = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_reh,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_EF = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_ef,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_SR = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_sr,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_DIS = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_dis,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_OTR = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_otr,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_VIH = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_vih,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_OM = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_om,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_etnia = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS neum_may5_etnias,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_OM = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS neumo_viviendo_con_vih_mas5a,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_vih = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS esplenicos_oncohematologicos_mas5a,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND h.valor_lab IN ('1','D1','DU','DA','DAA','') AND f.flg_ST = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS neumo_personal_salud_mas5a,

SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('1','D1') AND f.flg_VPH = 1 AND h.genero = 'F' AND h.edad < 9 THEN 1 ELSE 0 END) AS vph1_fem_men9a,

SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('2','D2') AND f.flg_VPH = 1 AND h.genero = 'F' AND h.edad < 9 THEN 1 ELSE 0 END) AS vph2_fem_men9a,

SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('DU','') AND f.flg_VPH = 1 AND h.genero = 'M' AND h.edad < 9 THEN 1 ELSE 0 END) AS vph3_mas_men9a,

SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('1','D1') AND f.flg_VPH = 1 AND h.genero = 'F' AND h.edad BETWEEN 9 AND 13 THEN 1 ELSE 0 END) AS vph1_fem_9_13a,

SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('2','D2') AND f.flg_VPH = 1 AND h.genero = 'F' AND h.edad BETWEEN 9 AND 13 THEN 1 ELSE 0 END) AS vph2_fem_9_13a,

SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('DU','') AND f.flg_VPH = 1 AND h.genero = 'M' AND h.edad BETWEEN 9 AND 13 THEN 1 ELSE 0 END) AS vph3_mas_9_13a,

SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('1','D1') AND f.flg_VPH = 1 AND h.genero = 'F' AND h.edad >= 14 THEN 1 ELSE 0 END) AS vph1_fem_may_14a,

SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('2','D2') AND f.flg_VPH = 1 AND h.genero = 'F' AND h.edad >= 14 THEN 1 ELSE 0 END) AS vph2_fem_may_14a,

SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('DU','') AND f.flg_VPH = 1 AND h.genero = 'M' AND h.edad >= 14 THEN 1 ELSE 0 END) AS vph3_mas_may_14a



FROM base h
LEFT JOIN cita_flags_{ANIO} ci ON h.id_cita = ci.id_cita
LEFT JOIN flags_cita f ON h.id_cita = f.id_cita

GROUP BY 
    h.anio,
    h.mes,
    h.cod_2000,
    h.red,
	h.desc_ue,
	h.microred,
	h.provincia,
	h.distrito,
    h.nombre_establecimiento

ORDER BY cod_2000, anio, mes

)

SELECT
    m.anio,
    m.mes,
    m.cod_2000,
    m.red,
	m.desc_ue,
	m.microred,
	m.provincia,
	m.distrito,
    m.nombre_establecimiento,

    m.gestantes_dt3_18_29,
	m.gestantes_dt1_30_49,
	m.gestantes_dt2_30_49,
	m.gestantes_dt3_30_49,
	m.gestante_Tdap1_10_11a,
	m.gestante_Tdap1_12_17a,
	m.gestante_Tdap1_18_29a,
	m.gestante_Tdap1_30_49a,
	m.gestante_Tdap1_50_60a,
	m.no_gestantes_dt1_10_11,
	m.no_gestantes_dt2_10_11,
	m.no_gestantes_dt3_10_11,
	m.no_gestantes_dt1_12_17,
	m.no_gestantes_dt2_12_17,
	m.no_gestantes_dt3_12_17,
	m.no_gestantes_dt1_18_29,
	m.no_gestantes_dt2_18_29,
	m.no_gestantes_dt3_18_29,
	m.no_gestantes_dt1_30_49,
	m.no_gestantes_dt2_30_49,
	m.no_gestantes_dt3_30_49,
	m.no_gestantes_dt1_50_59,
	m.no_gestantes_dt2_50_59,
	m.no_gestantes_dt3_50_59,
	m.no_gestantes_dt1_may_60a,
	m.no_gestantes_dt2_may_60a,
	m.no_gestantes_dt3_may_60a,
	m.varones_dt1_10_11,
	m.varones_dt2_10_11,
	m.varones_dt3_10_11,
	m.varones_dt1_12_17,
	m.varones_dt2_12_17,
	m.varones_dt3_12_17,
	m.varones_dt1_18_29,
	m.varones_dt2_18_29,
	m.varones_dt3_18_29,
	m.varones_dt1_30_49,
	m.varones_dt2_30_49,
	m.varones_dt3_30_49,
	m.varones_dt1_60a_mas,
	m.varones_dt2_60a_mas,
	m.varones_dt3_60a_mas,
	m.bcg_12horas,
	m.bcg_12_24h,
	m.bcg_1_11m,
	m.hvb_12_24h,
	m.hvb_24h,
	m."Vacuna Penta1 men_1a",
	m."Vacuna Penta2 men_1a",
	m."Vacuna Penta3 men_1a",
	m."Vacuna Ipv1 men_1a",
	m."Vacuna Ipv2 men_1a",
	m."Vacuna Ipv3 men_1a",
	m."Vacuna neumo1 men_1a",
	m."Vacuna neumo2 men_1a",
	m."Vacuna rotav1 men_1a",
	m."Vacuna rotav2 men_1a",
	m."Vacuna influenza1 men_1a",
	m."Vacuna influenza2 men_1a",
	m."Vacuna DT pediatrico2 men_1a",
	m."Vacuna DT pediatrico3 men_1a",
	m."Vacuna hib2 men_1a",
	m."Vacuna hib3 men_1a",
	m."Vacuna HVB2 men_1a",
	m."Vacuna HVB3 men_1a",
	m."Vacuna AMA1 1a",
	m."Vacuna Hepatitis1 A 1a",
	m."NEUMO1 1a",
	m."Vacuna SPR1 1a",
	m."Vacuna SPR2 1a",
	m."Vacuna VARICELA1 1a",
	m."Vacuna influenza1 1a",
	m."Vacuna influenza2 1a",
	m."Vacuna influenza DU 1a",
	m."Vacuna DPT1 1a",
	m."Vacuna APO_IPV 1a",
	m."Vacuna IPV1 1a",
	m."Vacuna IPV2 1a",
	m."Vacuna APO3 1a",
	m."Vacuna Penta1 1a",
	m."Vacuna Penta2 1a",
	m."Vacuna Penta3 1a",
	m."Vacuna DT pediatrico2 1a",
	m."Vacuna DT pediatrico3 1a",
	m."Vacuna hib2 1a",
	m."Vacuna hib3 1a",
	m."Vacuna HVB2 1a",
	m."Vacuna HVB3 1a",
	m."BCG Contacto de TB P 1a",
	m."influenza1_con_morbi 2a",
	m."influenza1 sin morbi 2a",
	m."Neumococo con Comorbilidad 2a",
	m."Vacuna AMA 2a",
	m."3325405 Vacuna influenza1 2a",
	m."Vacuna IPV1 2a",
	m."Vacuna IPV2 2a",
	m."Vacuna APO3 2a",
	m."Vacuna Penta1 2a",
	m."Vacuna Penta2 2a",
	m."Vacuna Penta3 2a",
	m."Vacuna DT pediatrico2 2a",
	m."Vacuna DT pediatrico3 2a",
	m."Vacuna hib2 2a",
	m."Vacuna hib3 2a",
	m."Vacuna HVB2 2a",
	m."Vacuna HVB3 2a",
	m."BCG (Contacto de TB P) 2a",
	m."Vacuna VARICELA1 2a",
	m."Vacuna influenza1 con morbi 3a",
	m."Vacuna influenza1 sin morbi 3a",
	m."Neumococo con Comorbilidad 3a",
	m."Vacuna AMA 3a",
	m."Vacuna influenza1 3a",
	m."Vacuna IPV1 3a",
	m."Vacuna IPV2 3a",
	m."Vacuna APO3 3a",
	m."Vacuna Penta1 3a",
	m."Vacuna Penta2 3a",
	m."Vacuna Penta3 3a",
	m."Vacuna DT pediatrico2 3a",
	m."Vacuna DT pediatrico3 3a",
	m."Vacuna hib2 3a",
	m."Vacuna hib3 3a",
	m."Vacuna HVB2 3a",
	m."Vacuna HVB3 3a",
	m."BCG Contacto de TB P 3a",
	m."Vacuna VARICELA1 3a",
	m."Vacuna influenza1 con morbi 4a",
	m."Vacuna influenza1 sin morbi 4a",
	m."Neumococo con Comorbilidad 4a",
	m."Vacuna AMA 4a",
	m."Vacuna influenza1 4a",
	m."Vacuna IPV1 4a",
	m."Vacuna IPV2 4a",
	m."Vacuna APO3 4a",
	m."Vacuna Penta1 4a",
	m."Vacuna Penta2 4a",
	m."Vacuna Penta3 4a",
	m."Vacuna DT pediatrico2 4a",
	m."Vacuna DT pediatrico3 4a",
	m."Vacuna hib2 4a",
	m."Vacuna hib3 4a",
	m."Vacuna HVB2 4a",
	m."Vacuna HVB3 4a",
	m."BCG Contacto de TB P 4a",
	m."Vacuna DPT1 4a",
	m."Vacuna APO_IPV 4a",

	
	m."Vacuna VARICELA1 4a",
	m."Vacuna BCG RN 24H",
	m."Vacuna BCG RN 2-28DIAS",
	m."Vacuna BCG MEN1A",
	m."Vacuna HVB RN 12H",
	m."Vacuna HVB RN 24H",
	m."Reacciones Adversas por vacuna",
	m."Vacuna Neum madres VIH",
	m."Vacuna SPR 5-11a",
	m."Vacuna SPR 12-17a",
	m."Vacuna SPR 18-29a",
	m."Vacuna SPR 30-49a",
	m."Vacuna SPR 50AMAS",
	m.SARAM_RUEBOLA_MAY18a_ST,
	m.SARAM_RUEBOLA_MAY18a_AER,
	m.SARAM_RUEBOLA_MAY18a_TER,
	m.SARAM_RUEBOLA_MAY18a_FRON,
	m.SARAM_RUEBOLA_MAY18a_RSA,
	m.SARAM_RUEBOLA_MAY18a_END,
	m.SARAM_RUEBOLA_MAY5a_ETNIA,
	m."Vacuna HVB1 5-11a",
	m."Vacuna HVB1 12-17a",
	m."Vacuna HVB1 18-29a",
	m."Vacuna HVB1 30-59a",
	m."Vacuna HVB1 60AMAS",
	m."Vacuna HVB2 5-11a",
	m."Vacuna HVB2 12-17a",
	m."Vacuna HVB2 18-29a",
	m."Vacuna HVB2 30-59a",
	m."Vacuna HVB2 60AMAS",
	m."Vacuna HVB3 5-11a",
m."Vacuna HVB3 12-17a",
m."Vacuna HVB3 18-29a",
m."Vacuna HVB3 30-59a",
m."Vacuna HVB3 60AMAS",
m.HVB1_MAY5_ST,
m.HVB2_MAY5_ST,
m.HVB3_MAY5_ST,
m.HVB1_MAY5_VIH,
m.HVB2_MAY5_VIH,
m.HVB3_MAY5_VIH,
m.HVB1_MAY5_OM,
m.HVB2_MAY5_OM,
m.HVB3_MAY5_OM,
m.HVB1_MAY5_OTR,
m.HVB2_MAY5_OTR,
m.HVB3_MAY5_OTR,
m.HVB1_MAY5_ENF,
m.HVB2_MAY5_ENF,
m.HVB3_MAY5_ENF,
m."Vacuna AMA 5_11a",
m."Vacuna AMA 12_17a",
m."Vacuna AMA 18_29a",
m."Vacuna AMA 30_59a",
m."Vacuna AMA 60A_MASa",
m."Vacuna varicela 5_11a",
m."Vacuna varicela 12_17a",
m."Vacuna varicela 18_29a",
m."Vacuna varicela 30_59a",
m."Vacuna varicela 60A_MASa",
m.neumo1_5_11a_comorb,
m.neumo1_12_17a_mas_comorb,
m.neumo1_18_29a_mas_comorb,
m.neumo1_30_49a_mas_comorb,
m.neumo1_50_59a_mas_comorb,
m.neumo_5_11a_sin_comorb,
m.neumo_12_17a_sin_comorb,
m.neumo_18_29a_sin_comorb,
m.neumo_30_49a_sin_comorb,
m.neumo_50_59a_sin_comorb,
m.neumo_60a_mas,
m.neumo_gest,
m.neumo_puerpera,
m.neum_may5_st,
m.neum_may5_fni,
m.neum_may5_pnp,
m.neum_may5_m,
m.neum_may5_bom,
m.neum_may5_dci,
m.neum_may5_est,
m.neum_may5_cr,
m.neum_may5_inpe_ppl,
m.neum_may5_reh,
m.neum_may5_ef,
m.neum_may5_sr,
m.neum_may5_dis,
m.neum_may5_otr,
m.neum_may5_vih,
m.neum_may5_om,
m.neum_may5_etnias,
m.neumo_viviendo_con_vih_mas5a,
m.esplenicos_oncohematologicos_mas5a,
m.neumo_personal_salud_mas5a,
m.vph1_fem_men9a,
m.vph2_fem_men9a,
m.vph3_mas_men9a,
m.vph1_fem_9_13a,
m.vph2_fem_9_13a,
m.vph3_mas_9_13a,
m.vph1_fem_may_14a,
m.vph2_fem_may_14a,
m.vph3_mas_may_14a
	
    
FROM monitoreo_general m
ORDER BY m.cod_2000, m.anio, m.mes;
