CREATE OR REPLACE PROCEDURE es_ivan.sp_generar_cred_2026()
LANGUAGE plpgsql
AS $$
begin
	
	 -- 1️⃣ Eliminar tabla final si existe
    DROP TABLE IF EXISTS es_ivan.cred2026;

    -- 2️⃣ Eliminar tabla temporal si existe


CREATE TABLE es_ivan.cred2026 AS

-- ============================================
-- 🔥 BASE MINIMA (SOLO LO NECESARIO)
-- ============================================
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

    (
        EXTRACT(YEAR FROM age(fecha_atencion, fecha_nacimiento)) * 12 +
        EXTRACT(MONTH FROM age(fecha_atencion, fecha_nacimiento))
    )::int AS edad_meses

    FROM es_ivan.tabla_vacunas
    WHERE anio >= 2025
      AND codigo_item IN ('99199.26','99403','99403.01','99436','99381.01','99401.03','99411.01','99431','J00X','P599','J029','99381','99382','99383','C8002','Z001',
      						'99401.05','99401.07','99401.08','99401.09','99401.12','99401.16','99401.24','99401.25','99403.01','99401.03','P929','99211','99211','99199.17','R620','R628','E440',
      						'E669','E6690','E45X','E43X','E344','87177.01','B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664','87178',
      						'B80X','99199.28','C0011','85018.01','P070','P071','P0711','P0712','P0713','P072','P073','U1692','59430','U140','R456','Z720','Z721','Z722','Z133',
      						'H351','H351','H579','H579','Z010','PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527'
							'67228','67229','92390','99499.08','99499.09','99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10')

),




-- ============================================
-- 🔥 SOLO FLAG NECESARIO (GESTANTE)
-- ============================================
cita_flags_2026 AS (
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

/* ===================== FLAGS CLÍNICOS ===================== */

MAX((codigo_item LIKE 'P07%')::int) AS bpn_P07,
MAX((codigo_item = 'P0712')::int)   AS prematuro_P0712, 
MAX((codigo_item = 'Z001')::int)    AS rutina_Z001,
MAX((codigo_item LIKE 'D50%')::int) AS anemia_D50,
MAX((codigo_item = '99199.17' AND valor_lab = 'TA')::int) AS suple_TA_99199_17,
MAX((codigo_item = 'C0011')::int)   AS visit_domic_C0011,

MAX((codigo_item = 'C8002' AND valor_lab = '1')::int) AS planAIS_c8002_1,
MAX((codigo_item = 'C8002' AND valor_lab = 'TA')::int) AS planAIS_TA_c8002,

MAX((codigo_item = 'R620' AND valor_lab = 'PR')::int) AS eval_des_rec_R620,
MAX((codigo_item = 'R628' AND valor_lab = 'PR')::int) AS eval_rec_r628,
MAX((codigo_item = 'R628' AND valor_lab = 'PE')::int) AS eval_PE_R628,
MAX((codigo_item = 'R628' AND valor_lab = 'TE')::int) AS eval_TE_R628,

MAX((codigo_item = 'E440' AND valor_lab = 'TP')::int) AS desn_aguda_TP_E440,
MAX((codigo_item = 'E440' AND valor_lab = 'PR')::int) AS desn_aguda_PR_E440,
MAX((codigo_item = 'E440' AND valor_lab = 'PE')::int) AS desn_global_PE_E440,
MAX((codigo_item = 'E440' AND valor_lab = 'PR')::int) AS desn_global_PR_E440,

MAX((codigo_item = 'E45X' AND valor_lab = 'TE')::int) AS desn_cronica_TE_E45X,
MAX((codigo_item = 'E45X' AND valor_lab = 'PR')::int) AS desn_cronica_rec_E45X,
MAX((codigo_item = 'E45X' AND valor_lab = 'TP')::int) AS desn_severa_TP_E43X,
MAX((codigo_item = 'E45X' AND valor_lab = 'PR')::int) AS desn_severa_rec_E43X,

MAX((codigo_item = 'E6690' AND valor_lab ='TP')::int) AS sobre_peso_TP_E6690,
MAX((codigo_item = 'E6690' AND valor_lab ='PR')::int) AS sobre_peso_rec_E6690,
MAX((codigo_item = 'E669' AND valor_lab = 'TP')::int) AS obeso_TP_E669,
MAX((codigo_item = 'E669' AND valor_lab = 'PR')::int) AS obeso_rec_E669,

MAX((codigo_item = 'E344' AND valor_lab = 'TE')::int) AS talla_Edad_TE_E344,
MAX((codigo_item = 'E344' AND valor_lab = 'PR')::int) AS talla_Edad_TE_rec_E344,

/* ===================== VIF ===================== */

MAX((codigo_item = 'U140')::int) AS VIF_U140,
MAX((codigo_item = 'R456')::int) AS VIF_post_R456,
MAX((codigo_item = 'Z720')::int) AS AD_tabaco_post_Z720,
MAX((codigo_item = 'Z721')::int) AS AD_alcohol_post_Z721,
MAX((codigo_item = 'Z722')::int) AS AD_drogas_post_Z722,
MAX((codigo_item = 'Z133')::int) AS TD_post_Z133,

/* ===================== OCULARES ===================== */

MAX((codigo_item = 'H351' AND valor_lab='1')::int)  AS retino_premat_H351,
MAX((codigo_item = 'H351' AND valor_lab='RF')::int) AS retino_premat_RF_H351,

MAX((codigo_item = 'H579' AND tipo_diagnostico='P')::int) AS trast_ojo_anexos_H579,
MAX((codigo_item = 'H579' AND tipo_diagnostico='P' AND valor_lab='RF')::int) AS trast_ojo_anexos_RF_H579,

MAX((codigo_item = 'Z010' AND valor_lab='N' AND tipo_diagnostico='D')::int) AS ex_ojo_vision_N_Z010,
MAX((codigo_item = 'Z010' AND valor_lab='A' AND tipo_diagnostico='D')::int) AS ex_ojo_vision_A_Z010,
MAX((codigo_item = 'Z010' AND tipo_diagnostico='D')::int) AS ex_ojo_vision_Z010,

MAX((codigo_item IN ('PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527') AND tipo_diagnostico='P')::int) AS deter_agude_visual_PH,

MAX((codigo_item = '67228' AND tipo_diagnostico='D')::int) AS tto_retinopatia_67228,
MAX((codigo_item = '67229' AND tipo_diagnostico='D')::int) AS destruc_retinopatia_67229,
MAX((codigo_item = '92390' AND tipo_diagnostico='D')::int) AS provision_lentes_92390,

/* ===================== TELEMEDICINA ===================== */

MAX((codigo_item = '99499.08')::int) AS teleori_sincro_99499_08,
MAX((codigo_item = '99499.09')::int) AS teleori_asincr_99499_09,
MAX((codigo_item IN ('99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10'))::int) AS telemedicina_99499__,

/* ===================== CONDICIONES ===================== */

MAX((fg_tipo = 'CX')::int) AS flg_comorbilidad,

MAX((valor_lab = 'ST')::int) AS flg_st,
MAX((valor_lab = 'OM')::int) AS flg_OM,
MAX((valor_lab = 'VIH')::int) AS flg_vih,
MAX((valor_lab = 'VPH')::int) AS flg_VPH,
MAX((valor_lab = 'AER')::int) AS flg_AER,
MAX((valor_lab = 'TER')::int) AS flg_TER,
MAX((valor_lab = 'FRON')::int) AS flg_FRO,
MAX((valor_lab = 'RSA')::int) AS flg_RSA,

MAX((valor_lab = 'END')::int) AS flg_END,
MAX((valor_lab = 'FNI')::int) AS flg_FNI,
MAX((valor_lab = 'PNP')::int) AS flg_PNP,
MAX((valor_lab = 'M')::int) AS flg_M,
MAX((valor_lab = 'EF')::int) AS flg_EF,
MAX((valor_lab = 'BOM')::int) AS flg_BOM,
MAX((valor_lab = 'DCI')::int) AS flg_DCI,
MAX((valor_lab = 'EST')::int) AS flg_EST,
MAX((valor_lab = 'CR')::int) AS flg_CR,

MAX((valor_lab IN ('IN','PPL'))::int) AS flg_INPE_PPL,
MAX((valor_lab = 'REH')::int) AS flg_REH,
MAX((valor_lab IN ('RS','RSA','RMA'))::int) AS flg_HF,
MAX((valor_lab = 'SR')::int) AS flg_SR,
MAX((valor_lab = 'DIS')::int) AS flg_DIS,

MAX((valor_lab IN ('TS','HSH','HTS','TTS','PNP','M','BOM','DCI','EST','TRA','PPL','G','P','OTR','VIH','OM'))::int) AS flg_OTR,

MAX((valor_lab IN ('E1','DE1','E2','DE2','E3','DE3','E4','DE4'))::int) AS flg_ENF,
MAX((id_etnia IN ('56','57','58','59','60'))::int) AS flg_etnia,

MAX((valor_lab = 'AD')::int) AS flg_AD,
MAX((valor_lab = 'TD')::int) AS flg_TD

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

    -- 🔹 SUPLEMENTACIÓN
    SUM((ci.es_gestante = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = '1' AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 59)::int) AS suplem_gest1,
    SUM((ci.es_gestante = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = '2' AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 59)::int) AS suplem_gest2,
    SUM((ci.es_gestante = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = '3' AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 59)::int) AS suplem_gest3,
    SUM((ci.es_gestante = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = '4' AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 59)::int) AS suplem_gest4,
    SUM((ci.es_gestante = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = '5' AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 59)::int) AS suplem_gest5,
    SUM((ci.es_gestante = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = '6' AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 59)::int) AS suplem_gest6,
    SUM((ci.es_gestante = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = 'TA' AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 59)::int) AS suplem_gest_ta,

    -- 🔹 CONSEJERÍA
    SUM((ci.es_gestante = 1 AND h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '1')::int) AS cons_nutric1_gest,
    SUM((ci.es_gestante = 1 AND h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '2')::int) AS cons_nutric2_gest,
    SUM((ci.es_gestante = 1 AND h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '3')::int) AS cons_nutric3_gest,
    SUM((ci.es_gestante = 1 AND h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '4')::int) AS cons_nutric4_gest,
    SUM((ci.es_gestante = 1 AND h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '5')::int) AS cons_nutric5_gest,
    SUM((ci.es_gestante = 1 AND h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '6')::int) AS cons_nutric6_gest,
    
     /* ================= CONSULTA NUTRICIONAL GESTANTE ================= */

	SUM((ci.es_gestante = 1 AND h.codigo_item = '99209' AND h.valor_lab = '1' AND h.tip_edad = 'A' AND h.edad = 1)::int) AS consulta_nutric1_gest,
	SUM((ci.es_gestante = 1 AND h.codigo_item = '99209' AND h.valor_lab = '2' AND h.tip_edad = 'A' AND h.edad = 1)::int) AS consulta_nutric2_gest,
	SUM((ci.es_gestante = 1 AND h.codigo_item = '99209' AND h.valor_lab = '3' AND h.tip_edad = 'A' AND h.edad = 1)::int) AS consulta_nutric3_gest,

	/* ================= SUPLEMENTACIÓN PUÉRPERA ================= */

	SUM((ci.es_puerpera = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = '1')::int) AS suplem_puer1,
	SUM((ci.es_puerpera = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = '2')::int) AS suplem_puer2,
	SUM((ci.es_puerpera = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = '3')::int) AS suplem_puer3,
	SUM((ci.es_puerpera = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = '4')::int) AS suplem_puer4,
	SUM((ci.es_puerpera = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = '5')::int) AS suplem_puer5,
	SUM((ci.es_puerpera = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = '6')::int) AS suplem_puer6,
	SUM((ci.es_puerpera = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = '7')::int) AS suplem_puer7,
	SUM((ci.es_puerpera = 1 AND h.codigo_item = '99199.26' AND h.valor_lab = 'TA')::int) AS suple_puer_ta,
    
 
 /* MUJERES EN EDAD FÉRTIL */

SUM(CASE WHEN ci.es_gestante = 0 AND ci.es_puerpera = 0 AND h.codigo_item = '99199.26' AND h.valor_lab = '1' THEN 1 ELSE 0 END) AS suplem_mef1,
SUM(CASE WHEN ci.es_gestante = 0 AND ci.es_puerpera = 0 AND h.codigo_item = '99199.26' AND h.valor_lab = '2' THEN 1 ELSE 0 END) AS suplem_mef2,
SUM(CASE WHEN ci.es_gestante = 0 AND ci.es_puerpera = 0 AND h.codigo_item = '99199.26' AND h.valor_lab = '3' THEN 1 ELSE 0 END) AS suplem_mef3,
SUM(CASE WHEN ci.es_gestante = 0 AND ci.es_puerpera = 0 AND h.codigo_item = '99199.26' AND h.valor_lab = 'TA' THEN 1 ELSE 0 END) AS suplem_mef_ta,

SUM(CASE WHEN ci.es_gestante = 0 AND ci.es_puerpera = 0 AND h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '1' THEN 1 ELSE 0 END) AS cons_mef1,
SUM(CASE WHEN ci.es_gestante = 0 AND ci.es_puerpera = 0 AND h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '2' THEN 1 ELSE 0 END) AS cons_mef2,
SUM(CASE WHEN ci.es_gestante = 0 AND ci.es_puerpera = 0 AND h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '3' THEN 1 ELSE 0 END) AS cons_mef3,
SUM(CASE WHEN ci.es_gestante = 0 AND ci.es_puerpera = 0 AND h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '4' THEN 1 ELSE 0 END) AS cons_mef4,

SUM(CASE WHEN ci.es_gestante = 0 AND ci.es_puerpera = 0 AND h.codigo_item = '99209' AND h.valor_lab = '1' AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS consulta_nutric1_mef,
SUM(CASE WHEN ci.es_gestante = 0 AND ci.es_puerpera = 0 AND h.codigo_item = '99209' AND h.valor_lab = '2' AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS consulta_nutric2_mef,
SUM(CASE WHEN ci.es_gestante = 0 AND ci.es_puerpera = 0 AND h.codigo_item = '99209' AND h.valor_lab = '3' AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS consulta_nutric3_mef,

/* ADOLESCENTES / GENERAL 12-17 */

SUM(CASE WHEN h.codigo_item = '99199.26' AND h.valor_lab = '1' THEN 1 ELSE 0 END) AS suplem1_12_17,
SUM(CASE WHEN h.codigo_item = '99199.26' AND h.valor_lab = '2' THEN 1 ELSE 0 END) AS suplem2_12_17,
SUM(CASE WHEN h.codigo_item = '99199.26' AND h.valor_lab = '3' THEN 1 ELSE 0 END) AS suplem3_12_17,
SUM(CASE WHEN h.codigo_item = '99199.26' AND h.valor_lab = 'TA' THEN 1 ELSE 0 END) AS suplem4_12_17ta,

SUM(CASE WHEN h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '1' THEN 1 ELSE 0 END) AS cons_nutri1_12_17,
SUM(CASE WHEN h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '2' THEN 1 ELSE 0 END) AS cons_nutri2_12_17,
SUM(CASE WHEN h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '3' THEN 1 ELSE 0 END) AS cons_nutri3_12_17,
SUM(CASE WHEN h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '4' THEN 1 ELSE 0 END) AS cons_nutri4_12_17,

SUM(CASE WHEN h.codigo_item = '99209' AND h.valor_lab = '1' AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS consulta_nutric1_12_17a,
SUM(CASE WHEN h.codigo_item = '99209' AND h.valor_lab = '2' AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS consulta_nutric2_12_17a,
SUM(CASE WHEN h.codigo_item = '99209' AND h.valor_lab = '3' AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS consulta_nutric3_12_17a,

/* ===================== NEONATOS ===================== */

SUM(CASE WHEN h.codigo_item = '99436' AND f.prematuro_P0712 = 0 AND f.bpn_P07 = 0 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS atenc_inmediata_RN_sano,
SUM(CASE WHEN h.codigo_item = '99436' AND f.prematuro_P0712 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS atenc_inmediata_RN_premat,
SUM(CASE WHEN h.codigo_item = '99436' AND f.bpn_P07 = 1 AND f.prematuro_P0712 = 0 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS atencion_inmediata_BPN,
SUM(CASE WHEN h.codigo_item = '99381.01' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS plan_ais_ini_rn,
SUM(CASE WHEN h.codigo_item = '99381.01' AND f.rutina_Z001 = 1 AND f.planAIS_TA_c8002 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS plan_ais_ta_rn,
SUM(CASE WHEN h.codigo_item = '99401.03' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS lme_1ra_hora,

/* BPN */

SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '1' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 0 AND f.bpn_P07 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS cred1_rn_bpn,
SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '2' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 0 AND f.bpn_P07 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS cred2_rn_bpn,
SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '3' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 0 AND f.bpn_P07 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS cred3_rn_bpn,
SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '4' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 0 AND f.bpn_P07 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS cred4_rn_bpn,

/* PREMATUROS */

SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '1' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 1 AND f.bpn_P07 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS cred1_rn_premat,
SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '2' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 1 AND f.bpn_P07 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS cred2_rn_premat,
SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '3' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 1 AND f.bpn_P07 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS cred3_rn_premat,
SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '4' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 1 AND f.bpn_P07 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS cred4_rn_premat,

/* RN NORMAL */

SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '1' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 0 AND f.bpn_P07 = 0 AND h.edad_dias BETWEEN 2 AND 7 THEN 1 ELSE 0 END) AS cred1_rn_3_6d,
SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '1' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 0 AND f.bpn_P07 = 0 AND h.edad_dias BETWEEN 7 AND 14 THEN 1 ELSE 0 END) AS cred1_rn_7_13d,
SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '2' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 0 AND f.bpn_P07 = 0 AND h.edad_dias BETWEEN 7 AND 14 THEN 1 ELSE 0 END) AS cred2_rn_7_13d,
SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '1' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 0 AND f.bpn_P07 = 0 AND h.edad_dias BETWEEN 14 AND 21 THEN 1 ELSE 0 END) AS cred1_rn_14_21d,
SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '2' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 0 AND f.bpn_P07 = 0 AND h.edad_dias BETWEEN 14 AND 21 THEN 1 ELSE 0 END) AS cred2_rn_14_21d,
SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '3' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 0 AND f.bpn_P07 = 0 AND h.edad_dias BETWEEN 14 AND 21 THEN 1 ELSE 0 END) AS cred3_rn_14_21d,
SUM(CASE WHEN h.codigo_item = '99381.01' AND h.valor_lab = '4' AND f.rutina_Z001 = 1 AND f.prematuro_P0712 = 0 AND f.bpn_P07 = 0 AND h.edad_dias>=22 THEN 1 ELSE 0 END) AS cred4_rn_22_a_mas_dias,

/* ESTIMULACIÓN TEMPRANA */

SUM(CASE WHEN h.codigo_item = '99411.01' AND h.valor_lab = '1' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS sesion_est_temprana_RN_1,
SUM(CASE WHEN h.codigo_item = '99411.01' AND h.valor_lab = '2' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS sesion_est_temprana_RN_2,
SUM(CASE WHEN h.codigo_item = '99411.01' AND h.valor_lab = '3' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS sesion_est_temprana_RN_3,
SUM(CASE WHEN h.codigo_item = '99411.01' AND h.valor_lab = '4' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS sesion_est_temprana_RN_4,

/* OTROS */

SUM(CASE WHEN h.codigo_item = '99431' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS examen_fisico_rn_normal,
SUM(CASE WHEN h.codigo_item = 'J00X' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS rinofaringitis_aguda_rinitis_aguda,
SUM(CASE WHEN h.codigo_item = 'P599' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS ictericia_neonatal_no_especificada,
SUM(CASE WHEN h.codigo_item = 'J029' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS faringitis_aguda_no_especificada_neonatal,
SUM(CASE WHEN h.codigo_item = 'P0712' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS rn_BPN_menor_2500gr,



/* ===================== CONTROLES RESTANTES ===================== */

/* MENORES DE 1 AÑO */

SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '1' AND h.edad_dias BETWEEN 29 AND 59 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred1_29_59d_men1a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '2' AND h.edad_dias BETWEEN 60 AND 89 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred2_60_89d_men1a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '3' AND h.edad_dias BETWEEN 90 AND 119 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred3_90_119d_men1a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '4' AND h.edad_dias BETWEEN 120 AND 149 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred4_120_149d_men1a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '5' AND h.edad_dias BETWEEN 180 AND 209 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred5_180_209d_men1a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '6' AND h.edad_dias BETWEEN 210 AND 239 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred6_210_239d_men1a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '7' AND h.edad_dias BETWEEN 270 AND 299 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred7_270_299d_men1a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '8' AND h.tip_edad='M' AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred8_men1a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '9' AND h.tip_edad='M' AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred9_men1a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '10' AND h.tip_edad='M' AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred10_men1a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '11' AND h.tip_edad='M' AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred11_men1a,

/* 1 AÑO */

SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '1' AND h.edad_dias BETWEEN 360 AND 389 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred1_360_389d_1a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '2' AND h.edad_dias BETWEEN 450 AND 479 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred2_450_479d_1a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '3' AND h.edad_dias BETWEEN 540 AND 569 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred3_540_569d_1a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '4' AND h.edad_dias BETWEEN 630 AND 659 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred4_630_659d_1a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '5' AND h.tip_edad='A' AND edad=1 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred5_1a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '6' AND h.tip_edad='A' AND edad=1 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred6_1a,

/* 2 AÑOS */

SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '1' AND h.edad_meses = 24 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred1_2a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '2' AND h.edad_meses = 30 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred2_2a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '3' AND h.tip_edad='A' AND edad=2 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred3_2a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '4' AND h.tip_edad='A' AND edad=2 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred4_2a,

/* 3 AÑOS */

SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '1' AND h.edad_meses = 36 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred1_3a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '2' AND h.edad_meses = 42 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred2_3a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '3' AND h.tip_edad='A' AND edad=3 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred3_3a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '4' AND h.tip_edad='A' AND edad=3 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred4_3a,

/* 4 AÑOS */

SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '1' AND h.edad_meses = 48 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred1_4a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '2' AND h.edad_meses = 54 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred2_4a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '3' AND h.tip_edad='A' AND edad=4 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred3_4a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '4' AND h.tip_edad='A' AND edad=4 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred4_4a,


/* 5 A 11 AÑOS */

SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad_meses BETWEEN 60 AND 71 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred1_5a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad_meses BETWEEN 72 AND 83 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred1_6a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad_meses BETWEEN 84 AND 95 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred1_7a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad_meses BETWEEN 96 AND 107 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred1_8a,

SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad_meses BETWEEN 108 AND 119 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred1_9a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad_meses BETWEEN 120 AND 131 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred1_10a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad_meses BETWEEN 132 AND 143 AND f.rutina_Z001 = 1 THEN 1 ELSE 0 END) AS cred1_11a,

--- PLAN AIS  MENOR DE 1 AÑO

SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '1' AND h.edad_dias BETWEEN 29 AND 59 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_1m,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = 'TA' AND h.edad_dias BETWEEN 270 AND 299 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_termino_7m,


-- PLAN AIS INICIO TERMINO 1 AÑO

SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '1' AND h.edad_dias BETWEEN 360 AND 389 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_1a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = 'TA' AND h.edad_dias BETWEEN 630 AND 659 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_termino_1a,

-- PLAN AIS INICIO TERMINO 2 AÑOS

SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '1' AND h.edad_meses = 24 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_2a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = 'TA' AND h.edad_meses = 30 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_termino_2a,

-- PLAN AIS INICIO TERMINO 3 AÑOS

SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '1' AND h.edad_meses = 36 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_3a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = 'TA' AND h.edad_meses = 42 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_termino_3a,

-- PLAN AIS INICIO TERMINO 4 AÑOS

SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = '1' AND h.edad_meses = 48 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_4a,
SUM(CASE WHEN h.codigo_item = '99381' AND h.valor_lab = 'TA' AND h.edad_meses = 54 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_termino_4a,


-- LACTANCIA
SUM(CASE WHEN h.codigo_item='P929' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS suspencion_lme_6m,
-- EVALUACIÓN NUTRICIONAL
--RN 1–7 días
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='1' AND h.tip_edad='D' AND h.edad BETWEEN 1 AND 7 THEN 1 ELSE 0 END) AS eval_nutric_1_rn_1_7d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='2' AND h.tip_edad='D' AND h.edad BETWEEN 1 AND 7 THEN 1 ELSE 0 END) AS eval_nutric_2_rn_1_7d,
---RN 8–14 días
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='1' AND h.tip_edad='D' AND h.edad BETWEEN 7 AND 14 THEN 1 ELSE 0 END) AS eval_nutric_1_rn_8_14d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='2' AND h.tip_edad='D' AND h.edad BETWEEN 7 AND 14 THEN 1 ELSE 0 END) AS eval_nutric_2_rn_8_14d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='3' AND h.tip_edad='D' AND h.edad BETWEEN 7 AND 14 THEN 1 ELSE 0 END) AS eval_nutric_3_rn_8_14d,
--RN 15–21 días
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='1' AND h.tip_edad='D' AND h.edad BETWEEN 15 AND 21 THEN 1 ELSE 0 END) AS eval_nutric_1_rn_15_21d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='2' AND h.tip_edad='D' AND h.edad BETWEEN 15 AND 21 THEN 1 ELSE 0 END) AS eval_nutric_2_rn_15_21d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='3' AND h.tip_edad='D' AND h.edad BETWEEN 15 AND 21 THEN 1 ELSE 0 END) AS eval_nutric_3_rn_15_21d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='4' AND h.tip_edad='D' AND h.edad BETWEEN 15 AND 21 THEN 1 ELSE 0 END) AS eval_nutric_4_rn_15_21d,
--RN ≥22 días
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='1' AND h.tip_edad='D' AND h.edad >= 22 THEN 1 ELSE 0 END) AS eval_nutric_1_rn_may22d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='2' AND h.tip_edad='D' AND h.edad >= 22 THEN 1 ELSE 0 END) AS eval_nutric_2_rn_may22d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='3' AND h.tip_edad='D' AND h.edad >= 22 THEN 1 ELSE 0 END) AS eval_nutric_3_rn_may22d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='4' AND h.tip_edad='D' AND h.edad >= 22 THEN 1 ELSE 0 END) AS eval_nutric_4_rn_may22d,

--- Menores de 1 año (tip_edad='M')
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='1' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS eval_nutric_1_men1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='2' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS eval_nutric_2_men1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='3' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS eval_nutric_3_men1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='4' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS eval_nutric_4_men1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='5' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS eval_nutric_5_men1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='6' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS eval_nutric_6_men1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='7' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS eval_nutric_7_men1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='8' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS eval_nutric_8_men1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='9' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS eval_nutric_9_men1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='10' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS eval_nutric_10_men1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='11' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS eval_nutric_11_men1a,

-- Edad 1 año
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS eval_nutric_1_1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS eval_nutric_2_1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS eval_nutric_3_1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS eval_nutric_4_1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='5' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS eval_nutric_5_1a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='6' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS eval_nutric_6_1a,

-- Edad 2 años
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS eval_nutric_1_2a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS eval_nutric_2_2a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS eval_nutric_3_2a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS eval_nutric_4_2a,

-- Edad 3 años
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS eval_nutric_1_3a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS eval_nutric_2_3a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS eval_nutric_3_3a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS eval_nutric_4_3a,

-- Edad 4 años (⚠️ CORREGIDO: antes tenías todo valor_lab='1')
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS eval_nutric_1_4a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS eval_nutric_2_4a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS eval_nutric_3_4a,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS eval_nutric_4_4a,

-- Consejería nutricional BPN
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='1' AND f.bpn_P07=1 AND h.tip_edad='D' THEN 1 ELSE 0 END) AS cons_nutric_BPN,

-- Menores 4-5 meses
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='2' AND h.tip_edad='M' AND h.edad BETWEEN 4 AND 5 THEN 1 ELSE 0 END) AS cons_nutric_4_5m,

-- Menores 6-11 meses
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='1' AND h.tip_edad='M' AND h.edad BETWEEN 6 AND 11 THEN 1 ELSE 0 END) AS cons_nutric_1_6_11m,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='2' AND h.tip_edad='M' AND h.edad BETWEEN 6 AND 11 THEN 1 ELSE 0 END) AS cons_nutric_2_6_11m,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='3' AND h.tip_edad='M' AND h.edad BETWEEN 6 AND 11 THEN 1 ELSE 0 END) AS cons_nutric_3_6_11m,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='4' AND h.tip_edad='M' AND h.edad BETWEEN 6 AND 11 THEN 1 ELSE 0 END) AS cons_nutric_4_6_11m,

-- Edad 1 año
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS cons_nutric_1_1a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS cons_nutric_2_1a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS cons_nutric_3_1a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS cons_nutric_4_1a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='5' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS cons_nutric_5_1a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='6' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS cons_nutric_6_1a,

-- Edad 2 años
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS cons_nutric_1_2a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS cons_nutric_2_2a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS cons_nutric_3_2a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS cons_nutric_4_2a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='5' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS cons_nutric_5_2a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='6' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS cons_nutric_6_2a,

-- Edad 3 años
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS cons_nutric_1_3a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS cons_nutric_2_3a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS cons_nutric_3_3a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS cons_nutric_4_3a,

-- Edad 4 años
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS cons_nutric_1_4a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS cons_nutric_2_4a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS cons_nutric_3_4a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS cons_nutric_4_4a,

-- Edad 5 a 11 años
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS cons_nutric_1_5_11a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS cons_nutric_2_5_11a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS cons_nutric_3_5_11a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS cons_nutric_4_5_11a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='5' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS cons_nutric_5_5_11a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.valor_lab='6' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS cons_nutric_6_5_11a, 


-- Consulta nutricional BPN
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND f.bpn_P07=1 AND h.tip_edad='D' THEN 1 ELSE 0 END) AS consulta_nutric_BPN,

-- Menores 4-5 meses
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='M' AND h.edad BETWEEN 4 AND 5 THEN 1 ELSE 0 END) AS consulta_nutric1_4_5m,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='M' AND h.edad BETWEEN 4 AND 5 THEN 1 ELSE 0 END) AS consulta_nutric2_4_5m,

-- Menores 6-11 meses
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='M' AND h.edad BETWEEN 6 AND 11 THEN 1 ELSE 0 END) AS consulta_nutric_1_6_11m,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='M' AND h.edad BETWEEN 6 AND 11 THEN 1 ELSE 0 END) AS consulta_nutric_2_6_11m,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='3' AND h.tip_edad='M' AND h.edad BETWEEN 6 AND 11 THEN 1 ELSE 0 END) AS consulta_nutric_3_6_11m,

-- Edad 1 año
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS consulta_nutric_1_1a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS consulta_nutric_2_1a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS consulta_nutric_3_1a,

-- Edad 2 años
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS consulta_nutric_1_2a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS consulta_nutric_2_2a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS consulta_nutric_3_2a,

-- Edad 3 años
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS consulta_nutric_1_3a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS consulta_nutric_2_3a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS consulta_nutric_3_3a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS consulta_nutric_4_3a,

-- Edad 4 años
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS consulta_nutric_1_4a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS consulta_nutric_2_4a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS consulta_nutric_3_4a,

-- Edad 5 a 11 años
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS consulta_nutric_1_5_11a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS consulta_nutric_2_5_11a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS consulta_nutric_3_5_11a,

-- Suplementación BPN y saludable

SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='TA' AND h.tip_edad='M' AND h.edad=6 AND f.bpn_P07=1 THEN 1 ELSE 0 END) AS ta_suplem_bpn,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='1' AND f.bpn_P07=0 AND h.tip_edad='M' AND h.edad=4 THEN 1 ELSE 0 END) AS suplem_4m_sano,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='2' AND f.bpn_P07=0 AND h.tip_edad='M' AND h.edad=5 THEN 1 ELSE 0 END) AS suplem_5m_sano,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='TA' AND f.bpn_P07=0 AND h.tip_edad='M' AND h.edad=6 THEN 1 ELSE 0 END) AS ta_suplem_5_6m_sano,


-- Menores 6-11 meses

SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='1' AND f.bpn_P07=0 AND h.tip_edad='M' AND h.edad>=6 THEN 1 ELSE 0 END) AS suplem_1ra_6_11m,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='2' AND f.bpn_P07=0 AND h.tip_edad='M' AND h.edad>=6 THEN 1 ELSE 0 END) AS suplem_2da_6_11m,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='3' AND f.bpn_P07=0 AND h.tip_edad='M' AND h.edad>=6 THEN 1 ELSE 0 END) AS suplem_3ra_6_11m,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='4' AND f.bpn_P07=0 AND h.tip_edad='M' AND h.edad>=6 THEN 1 ELSE 0 END) AS suplem_4ta_6_11m,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='5' AND f.bpn_P07=0 AND h.tip_edad='M' AND h.edad>=6 THEN 1 ELSE 0 END) AS suplem_5ta_6_11m,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='6' AND f.bpn_P07=0 AND h.tip_edad='M' AND h.edad>=6 THEN 1 ELSE 0 END) AS suplem_6ta_6_11m,


-- Edad 1 año

SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='1' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS suplem_1ra_1a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='2' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS suplem_2da_1a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='3' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS suplem_3ra_1a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='4' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS suplem_4ta_1a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='5' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS suplem_5ta_1a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='6' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS suplem_6ta_1a,

-- Edad 2 años (con limpieza de espacios)

SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='1' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS suplem_1ra_2a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='2' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS suplem_2da_2a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='3' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS suplem_3ra_2a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='4' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS suplem_4ta_2a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='5' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS suplem_5ta_2a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='6' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS suplem_6ta_2a,


-- Edad 3 años

SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='1' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS suplem_1ra_3a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='2' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS suplem_2da_3a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='3' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS suplem_3ra_3a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='4' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS suplem_4ta_3a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='5' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS suplem_5ta_3a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='6' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS suplem_6ta_3a,


-- Edad 4 años

SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='1' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS suplem_1ra_4a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='2' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS suplem_2da_4a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='3' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS suplem_3ra_4a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='4' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS suplem_4ta_4a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='5' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS suplem_5ta_4a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='6' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS suplem_6ta_4a, 

-- Edad 5 a 11 años, suplementación 1 a 3

SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='1' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS suplem_1ra_5_11a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='2' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS suplem_2da_5_11a,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='3' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS suplem_3ra_5_11a,


-- TA suplementación 1 a 11 años

SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='TA' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS ta_suplem_1A,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='TA' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS ta_suplem_2A,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='TA' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS ta_suplem_3A,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='TA' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS ta_suplem_4A,
SUM(CASE WHEN h.codigo_item='99199.17' AND h.valor_lab='TA' AND f.bpn_P07=0 AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS ta_suplem_5_11A,


-- Vitamina A

SUM(CASE WHEN h.codigo_item='99199.27' AND h.valor_lab='VA1' AND h.edad_meses BETWEEN 6 AND 11 THEN 1 ELSE 0 END) AS va1_6_11m,
SUM(CASE WHEN h.codigo_item='99199.27' AND h.valor_lab='VA1' AND h.edad_meses BETWEEN 12 AND 23 THEN 1 ELSE 0 END) AS va1_1a,
SUM(CASE WHEN h.codigo_item='99199.27' AND h.valor_lab='VA2' AND h.edad_meses BETWEEN 12 AND 23 THEN 1 ELSE 0 END) AS va2_1a,
SUM(CASE WHEN h.codigo_item='99199.27' AND h.valor_lab='VA1' AND h.edad_meses BETWEEN 24 AND 35 THEN 1 ELSE 0 END) AS va1_2a,
SUM(CASE WHEN h.codigo_item='99199.27' AND h.valor_lab='VA2' AND h.edad_meses BETWEEN 24 AND 35 THEN 1 ELSE 0 END) AS va2_2a,
SUM(CASE WHEN h.codigo_item='99199.27' AND h.valor_lab='VA1' AND h.edad_meses BETWEEN 36 AND 47 THEN 1 ELSE 0 END) AS va1_3a,
SUM(CASE WHEN h.codigo_item='99199.27' AND h.valor_lab='VA2' AND h.edad_meses BETWEEN 36 AND 47 THEN 1 ELSE 0 END) AS va2_3a,
SUM(CASE WHEN h.codigo_item='99199.27' AND h.valor_lab='VA1' AND h.edad_meses BETWEEN 48 AND 59 THEN 1 ELSE 0 END) AS va1_4a,
SUM(CASE WHEN h.codigo_item='99199.27' AND h.valor_lab='VA2' AND h.edad_meses BETWEEN 48 AND 59 THEN 1 ELSE 0 END) AS va2_4a


FROM base h
LEFT JOIN cita_flags_2026 ci ON h.id_cita = ci.id_cita
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

    -- 🔹 Indicadores por cita
        /* SUPLEMENTACIÓN GESTANTE */
m.suplem_gest1,
m.suplem_gest2,
m.suplem_gest3,
m.suplem_gest4,
m.suplem_gest5,
m.suplem_gest6,
m.suplem_gest_ta,
m.cons_nutric1_gest,
m.cons_nutric2_gest,
m.cons_nutric3_gest,
m.cons_nutric4_gest,
m.cons_nutric5_gest,
m.cons_nutric6_gest,
m.consulta_nutric1_gest,
m.consulta_nutric2_gest,
m.consulta_nutric3_gest,
m.suplem_puer1,
m.suplem_puer2,
m.suplem_puer3,
m.suplem_puer4,
m.suplem_puer5,
m.suplem_puer6,
m.suplem_puer7,
m.suple_puer_ta,
m.suplem_mef1,
m.suplem_mef2,
m.suplem_mef3,
m.suplem_mef_ta,
m.cons_mef1,
m.cons_mef2,
m.cons_mef3,
m.cons_mef4,
m.consulta_nutric1_mef,
m.consulta_nutric2_mef,
m.consulta_nutric3_mef,
m.suplem1_12_17,
m.suplem2_12_17,
m.suplem3_12_17,
m.suplem4_12_17ta,
m.cons_nutri1_12_17,
m.cons_nutri2_12_17,
m.cons_nutri3_12_17,
m.consulta_nutric1_12_17a,
m.consulta_nutric2_12_17a,
m.consulta_nutric3_12_17a,

--NEONATOS --
m.atenc_inmediata_RN_sano,
m.atenc_inmediata_RN_premat,
m.atencion_inmediata_BPN,
m.plan_ais_ini_rn,
m.plan_ais_ta_rn,
m.lme_1ra_hora,
    
    --CONTROLES RECIEN NACIDOS BPN 

m.cred1_rn_bpn,
m.cred2_rn_bpn,
m.cred3_rn_bpn,
m.cred4_rn_bpn,
    
    --CONTROLES RECIEN NACIDOS PREMATURO 
m.cred1_rn_premat,
m.cred2_rn_premat,
m.cred3_rn_premat,
m.cred4_rn_premat,
    
m.cred1_rn_3_6d,
m.cred1_rn_7_13d,
m.cred2_rn_7_13d,
m.cred1_rn_14_21d,
m.cred2_rn_14_21d,
m.cred3_rn_14_21d,
m.cred4_rn_22_a_mas_dias,
m.sesion_est_temprana_RN_1,
m.sesion_est_temprana_RN_2,
m.sesion_est_temprana_RN_3,
m.sesion_est_temprana_RN_4,
m.examen_fisico_rn_normal,
m.rinofaringitis_aguda_rinitis_aguda,
m.ictericia_neonatal_no_especificada,
m.faringitis_aguda_no_especificada_neonatal, 
m.rn_BPN_menor_2500gr,
  
m.cred1_29_59d_men1a,
m.cred2_60_89d_men1a,
m.cred3_90_119d_men1a,
m.cred4_120_149d_men1a,
m.cred5_180_209d_men1a,
m.cred6_210_239d_men1a,
m.cred7_270_299d_men1a,
m.cred8_men1a,
m.cred9_men1a,
m.cred10_men1a,
m.cred11_men1a,


-- CONTROLES DE 1 AÑO:
m.cred1_360_389d_1a,
m.cred2_450_479d_1a,
m.cred3_540_569d_1a,
m.cred4_630_659d_1a,
m.cred5_1a,
m.cred6_1a,
  
  m.cred1_2a,
  m.cred2_2a,
  m.cred3_2a,
  m.cred4_2a,

  m.cred1_3a,
  m.cred2_3a,
  m.cred3_3a,
  m.cred4_3a,

  m.cred1_4a,
  m.cred2_4a,
  m.cred3_4a,
  m.cred4_4a,
  m.cred1_5a,
  m.cred1_6a,
  m.cred1_7a,
  m.cred1_8a,
  m.cred1_9a,
  m.cred1_10a,
  m.cred1_11a,
  m.suspencion_lme_6m,

	m.plan_ais_ini_1m,
	m.plan_ais_termino_7m,
	
	
	-- PLAN AIS INICIO TERMINO 1 AÑO
	
	m.plan_ais_ini_1a,
	m.plan_ais_termino_1a,
	
	-- PLAN AIS INICIO TERMINO 2 AÑOS
	
	m.plan_ais_ini_2a,
	m.plan_ais_termino_2a,
	
	-- PLAN AIS INICIO TERMINO 3 AÑOS
	
	m.plan_ais_ini_3a,
	m.plan_ais_termino_3a,
	
	-- PLAN AIS INICIO TERMINO 4 AÑOS
	
	m.plan_ais_ini_4a,
	m.plan_ais_termino_4a,

  
  m. eval_nutric_1_men1a,
  m. eval_nutric_2_men1a,
  m. eval_nutric_3_men1a,
  m. eval_nutric_4_men1a,
  m. eval_nutric_5_men1a,
  m. eval_nutric_6_men1a,
  m. eval_nutric_7_men1a,
  m. eval_nutric_8_men1a,
  m. eval_nutric_9_men1a,
  m. eval_nutric_10_men1a,
  m. eval_nutric_11_men1a,
  m.eval_nutric_1_1a,
  m.eval_nutric_2_1a,
  m.eval_nutric_3_1a,
  m.eval_nutric_4_1a,
  m.eval_nutric_5_1a,
  m.eval_nutric_6_1a,
  m.eval_nutric_1_2a,
  m.eval_nutric_2_2a,
  m.eval_nutric_3_2a,
  m.eval_nutric_4_2a,
  m.eval_nutric_1_3a,
  m.eval_nutric_2_3a,
  m.eval_nutric_3_3a,
  m.eval_nutric_4_3a,
  m.eval_nutric_1_4a,
  m.eval_nutric_2_4a,
  m.eval_nutric_3_4a,
  m.eval_nutric_4_4a,
  m.cons_nutric_BPN,
  m.cons_nutric_4_5m,
  m.cons_nutric_1_6_11m,
  m.cons_nutric_2_6_11m,
  m.cons_nutric_3_6_11m,
  m.cons_nutric_4_6_11m,
  m.cons_nutric_1_1a,
  m.cons_nutric_2_1a,
  m.cons_nutric_3_1a,
  m.cons_nutric_4_1a,
  m.cons_nutric_5_1a,
  m.cons_nutric_6_1a,
  m.cons_nutric_1_2a,
  m.cons_nutric_2_2a,
  m.cons_nutric_3_2a,
  m.cons_nutric_4_2a,
  m.cons_nutric_5_2a,
  m.cons_nutric_6_2a,
  m.cons_nutric_1_3a,
  m.cons_nutric_2_3a,
  m.cons_nutric_3_3a,
  m.cons_nutric_4_3a,
  m.cons_nutric_1_4a,
  m.cons_nutric_2_4a,
  m.cons_nutric_3_4a,
  m.cons_nutric_4_4a,
  m.cons_nutric_1_5_11a,
  m.cons_nutric_2_5_11a,
  m.cons_nutric_3_5_11a,
  m.cons_nutric_4_5_11a,
  m.cons_nutric_5_5_11a,
  m.cons_nutric_6_5_11a,
  
  m.ta_suplem_bpn,
  m.suplem_4m_sano,
  m.suplem_5m_sano,
  m.ta_suplem_5_6m_sano,
  m.suplem_1ra_6_11m,
  m.suplem_2da_6_11m,
  m.suplem_3ra_6_11m,
  m.suplem_4ta_6_11m,
  m.suplem_5ta_6_11m,
  m.suplem_6ta_6_11m,
  m.suplem_1ra_1a,
  m.suplem_2da_1a,
  m.suplem_3ra_1a,
  m.suplem_4ta_1a,
  m.suplem_5ta_1a,
  m.suplem_6ta_1a,
  m.suplem_1ra_2a,
  m.suplem_2da_2a,
  m.suplem_3ra_2a,
  m.suplem_4ta_2a,
  m.suplem_5ta_2a,
  m.suplem_6ta_2a,
  m.suplem_1ra_3a,
  m.suplem_2da_3a,
  m.suplem_3ra_3a,
  m.suplem_4ta_3a,
  m.suplem_5ta_3a,
  m.suplem_6ta_3a,
  m.suplem_1ra_4a,
  m.suplem_2da_4a,
  m.suplem_3ra_4a,
  m.suplem_4ta_4a,
  m.suplem_5ta_4a,
  m.suplem_6ta_4a,
  m.suplem_1ra_5_11a,
  m.suplem_2da_5_11a,
  m.suplem_3ra_5_11a,
  m.ta_suplem_1A,
  m.ta_suplem_2A,
  m.ta_suplem_3A,
  m.ta_suplem_4A,
  m.ta_suplem_5_11A,
  m.va1_6_11m,
  m.va1_1a,
  m.va2_1a,
  m.va1_2a,
  m.va2_2a,
  m.va1_3a,
  m.va2_3a,
  m.va1_4a,
  m.va2_4a


FROM monitoreo_general m
ORDER BY m.cod_2000, m.anio, m.mes;

----generar tabla cred 2026 1
    DROP TABLE IF EXISTS es_ivan.cred2026_1;
	CREATE TABLE es_ivan.cred2026_1 AS

-- ============================================
-- 🔥 BASE MINIMA (SOLO LO NECESARIO)
-- ============================================
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

    (
        EXTRACT(YEAR FROM age(fecha_atencion, fecha_nacimiento)) * 12 +
        EXTRACT(MONTH FROM age(fecha_atencion, fecha_nacimiento))
    )::int AS edad_meses

    FROM es_ivan.tabla_vacunas
    WHERE anio >= 2025
      AND codigo_item IN ('99199.26','99403','99403.01','99436','99381.01','99401.03','99411.01','99431','J00X','P599','J029','99381','99382','99383','C8002','Z001',
      						'99401.05','99401.07','99401.08','99401.09','99401.12','99401.16','99401.24','99401.25','99403.01','99401.03','P929','99211','99211','99199.17','R620','R628','E440',
      						'E669','E6690','E45X','E43X','E344','87177.01','B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664','87178',
      						'B80X','99199.28','C0011','85018.01','P070','P071','P0711','P0712','P0713','P072','P073','U1692','59430','U140','R456','Z720','Z721','Z722','Z133',
      						'H351','H351','H579','H579','Z010','PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527'
							'67228','67229','92390','99499.08','99499.09','99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10')

),




-- ============================================
-- 🔥 SOLO FLAG NECESARIO (GESTANTE)
-- ============================================ 
cita_flags_2026 AS (
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

/* ===================== FLAGS CLÍNICOS ===================== */

MAX((codigo_item LIKE 'P07%')::int) AS bpn_P07,
MAX((codigo_item = 'P0712')::int)   AS prematuro_P0712, 
MAX((codigo_item = 'Z001')::int)    AS rutina_Z001,
MAX((codigo_item LIKE 'D50%')::int) AS anemia_D50,
MAX((codigo_item = '99199.17' AND valor_lab = 'TA')::int) AS suple_TA_99199_17,
MAX((codigo_item = 'C0011')::int)   AS visit_domic_C0011,

MAX((codigo_item = 'C8002' AND valor_lab = '1')::int) AS planAIS_c8002_1,
MAX((codigo_item = 'C8002' AND valor_lab = 'TA')::int) AS planAIS_TA_c8002,

MAX((codigo_item = 'R620' AND valor_lab = 'PR')::int) AS eval_des_rec_R620,
MAX((codigo_item = 'R628' AND valor_lab = 'PR')::int) AS eval_rec_r628,
MAX((codigo_item = 'R628' AND valor_lab = 'PE')::int) AS eval_PE_R628,
MAX((codigo_item = 'R628' AND valor_lab = 'TE')::int) AS eval_TE_R628,

MAX((codigo_item = 'E440' AND valor_lab = 'TP')::int) AS desn_aguda_TP_E440,
MAX((codigo_item = 'E440' AND valor_lab = 'PR')::int) AS desn_aguda_PR_E440,
MAX((codigo_item = 'E440' AND valor_lab = 'PE')::int) AS desn_global_PE_E440,
MAX((codigo_item = 'E440' AND valor_lab = 'PR')::int) AS desn_global_PR_E440,

MAX((codigo_item = 'E45X' AND valor_lab = 'TE')::int) AS desn_cronica_TE_E45X,
MAX((codigo_item = 'E45X' AND valor_lab = 'PR')::int) AS desn_cronica_rec_E45X,
MAX((codigo_item = 'E45X' AND valor_lab = 'TP')::int) AS desn_severa_TP_E43X,
MAX((codigo_item = 'E45X' AND valor_lab = 'PR')::int) AS desn_severa_rec_E43X,

MAX((codigo_item = 'E6690' AND valor_lab ='TP')::int) AS sobre_peso_TP_E6690,
MAX((codigo_item = 'E6690' AND valor_lab ='PR')::int) AS sobre_peso_rec_E6690,
MAX((codigo_item = 'E669' AND valor_lab = 'TP')::int) AS obeso_TP_E669,
MAX((codigo_item = 'E669' AND valor_lab = 'PR')::int) AS obeso_rec_E669,

MAX((codigo_item = 'E344' AND valor_lab = 'TE')::int) AS talla_Edad_TE_E344,
MAX((codigo_item = 'E344' AND valor_lab = 'PR')::int) AS talla_Edad_TE_rec_E344,
MAX((codigo_item = '99199.11' AND valor_lab = 'ZN')::int) AS tratamiento_edas_99199_11,


/* ===================== VIF ===================== */

MAX((codigo_item = 'U140')::int) AS VIF_U140,
MAX((codigo_item = 'R456')::int) AS VIF_post_R456,
MAX((codigo_item = 'Z720')::int) AS AD_tabaco_post_Z720,
MAX((codigo_item = 'Z721')::int) AS AD_alcohol_post_Z721,
MAX((codigo_item = 'Z722')::int) AS AD_drogas_post_Z722,
MAX((codigo_item = 'Z133')::int) AS TD_post_Z133,

/* ===================== OCULARES ===================== */

MAX((codigo_item = 'H351' AND valor_lab='1')::int)  AS retino_premat_H351,
MAX((codigo_item = 'H351' AND valor_lab='RF')::int) AS retino_premat_RF_H351,

MAX((codigo_item = 'H579' AND tipo_diagnostico='P')::int) AS trast_ojo_anexos_H579,
MAX((codigo_item = 'H579' AND tipo_diagnostico='P' AND valor_lab='RF')::int) AS trast_ojo_anexos_RF_H579,

MAX((codigo_item = 'Z010' AND valor_lab='N' AND tipo_diagnostico='D')::int) AS ex_ojo_vision_N_Z010,
MAX((codigo_item = 'Z010' AND valor_lab='A' AND tipo_diagnostico='D')::int) AS ex_ojo_vision_A_Z010,
MAX((codigo_item = 'Z010' AND tipo_diagnostico='D')::int) AS ex_ojo_vision_Z010,

MAX((codigo_item IN ('PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527') AND tipo_diagnostico='P')::int) AS deter_agude_visual_PH,

MAX((codigo_item = '67228' AND tipo_diagnostico='D')::int) AS tto_retinopatia_67228,
MAX((codigo_item = '67229' AND tipo_diagnostico='D')::int) AS destruc_retinopatia_67229,
MAX((codigo_item = '92390' AND tipo_diagnostico='D')::int) AS provision_lentes_92390,

/* ===================== TELEMEDICINA ===================== */

MAX((codigo_item = '99499.08')::int) AS teleori_sincro_99499_08,
MAX((codigo_item = '99499.09')::int) AS teleori_asincr_99499_09,
MAX((codigo_item IN ('99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10'))::int) AS telemedicina_99499__,

/* ===================== CONDICIONES ===================== */

MAX((fg_tipo = 'CX')::int) AS flg_comorbilidad,

MAX((valor_lab = 'ST')::int) AS flg_st,
MAX((valor_lab = 'OM')::int) AS flg_OM,
MAX((valor_lab = 'VIH')::int) AS flg_vih,
MAX((valor_lab = 'VPH')::int) AS flg_VPH,
MAX((valor_lab = 'AER')::int) AS flg_AER,
MAX((valor_lab = 'TER')::int) AS flg_TER,
MAX((valor_lab = 'FRON')::int) AS flg_FRO,
MAX((valor_lab = 'RSA')::int) AS flg_RSA,

MAX((valor_lab = 'END')::int) AS flg_END,
MAX((valor_lab = 'FNI')::int) AS flg_FNI,
MAX((valor_lab = 'PNP')::int) AS flg_PNP,
MAX((valor_lab = 'M')::int) AS flg_M,
MAX((valor_lab = 'EF')::int) AS flg_EF,
MAX((valor_lab = 'BOM')::int) AS flg_BOM,
MAX((valor_lab = 'DCI')::int) AS flg_DCI,
MAX((valor_lab = 'EST')::int) AS flg_EST,
MAX((valor_lab = 'CR')::int) AS flg_CR,

MAX((valor_lab IN ('IN','PPL'))::int) AS flg_INPE_PPL,
MAX((valor_lab = 'REH')::int) AS flg_REH,
MAX((valor_lab IN ('RS','RSA','RMA'))::int) AS flg_HF,
MAX((valor_lab = 'SR')::int) AS flg_SR,
MAX((valor_lab = 'DIS')::int) AS flg_DIS,

MAX((valor_lab IN ('TS','HSH','HTS','TTS','PNP','M','BOM','DCI','EST','TRA','PPL','G','P','OTR','VIH','OM'))::int) AS flg_OTR,

MAX((valor_lab IN ('E1','DE1','E2','DE2','E3','DE3','E4','DE4'))::int) AS flg_ENF,
MAX((id_etnia IN ('56','57','58','59','60'))::int) AS flg_etnia,

MAX((valor_lab = 'AD')::int) AS flg_AD,
MAX((valor_lab = 'TD')::int) AS flg_TD

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

    -- SESION DE ESTIMULACION TEMPRANA

SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='1' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS sesion_est_temprana_menor_1A_1,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='2' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS sesion_est_temprana_menor_1A_2,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='3' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS sesion_est_temprana_menor_1A_3,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='4' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS sesion_est_temprana_menor_1A_4,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='5' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS sesion_est_temprana_menor_1A_5,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='6' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS sesion_est_temprana_menor_1A_6,

SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='7' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS sesion_est_temprana_menor_1A_7,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='8' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS sesion_est_temprana_menor_1A_8,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='9' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS sesion_est_temprana_menor_1A_9,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='10' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS sesion_est_temprana_menor_1A_10,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='11' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS sesion_est_temprana_menor_1A_11,


-- Edad 1 año

SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS sesion_est_temprana_1A_1,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS sesion_est_temprana_1A_2,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS sesion_est_temprana_1A_3,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS sesion_est_temprana_1A_4,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='5' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS sesion_est_temprana_1A_5,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='6' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS sesion_est_temprana_1A_6,


-- Edad 2 años

SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS sesion_est_temprana_2A_1,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS sesion_est_temprana_2A_2,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS sesion_est_temprana_2A_3,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS sesion_est_temprana_2A_4,


-- Edad 3 años

SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS sesion_est_temprana_3A_1,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS sesion_est_temprana_3A_2,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS sesion_est_temprana_3A_3,
SUM(CASE WHEN h.codigo_item='99411.01' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS sesion_est_temprana_3A_4,


-- EVALUACION POR AREAS DE DESARROLLO IDENTIFICADOS

SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='LEN' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS Retardo_desarrollo_len_m1a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='MOT' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS Retardo_desarrollo_mot_m1a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='SOC' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS Retardo_desarrollo_soc_m1a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='COO' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS Retardo_desarrollo_coo_m1a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='COG' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS Retardo_desarrollo_cog_m1a,

-- Edad 1
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='LEN' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS Retardo_desarrollo_len_1a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='MOT' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS Retardo_desarrollo_mot_1a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='SOC' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS Retardo_desarrollo_soc_1a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='COO' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS Retardo_desarrollo_coo_1a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='COG' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS Retardo_desarrollo_cog_1a,

-- Edad 2
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='LEN' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS Retardo_desarrollo_len_2a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='MOT' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS Retardo_desarrollo_mot_2a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='SOC' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS Retardo_desarrollo_soc_2a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='COO' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS Retardo_desarrollo_coo_2a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='COG' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS Retardo_desarrollo_cog_2a,

-- Edad 3
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='LEN' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS Retardo_desarrollo_len_3a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='MOT' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS Retardo_desarrollo_mot_3a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='SOC' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS Retardo_desarrollo_soc_3a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='COO' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS Retardo_desarrollo_coo_3a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='COG' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS Retardo_desarrollo_cog_3a,

-- Edad 4
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='LEN' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS Retardo_desarrollo_len_4a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='MOT' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS Retardo_desarrollo_mot_4a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='SOC' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS Retardo_desarrollo_soc_4a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='COO' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS Retardo_desarrollo_coo_4a,
SUM(CASE WHEN h.codigo_item='R620' AND h.valor_lab='COG' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS Retardo_desarrollo_cog_4a,

-- EVALUACIÓN DESARROLLO RECUPERADOS

SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='LEN' AND h.tip_edad = 'M' AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_len_m1a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='MOT' AND h.tip_edad = 'M' AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_mot_m1a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='SOC' AND h.tip_edad = 'M' AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_soc_m1a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='COO' AND h.tip_edad = 'M' AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_coo_m1a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='COG' AND h.tip_edad = 'M' AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_cog_m1a,

SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='LEN' AND h.tip_edad = 'A' AND h.edad = 1 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_len_1a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='MOT' AND h.tip_edad = 'A' AND h.edad = 1 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_mot_1a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='SOC' AND h.tip_edad = 'A' AND h.edad = 1 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_soc_1a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='COO' AND h.tip_edad = 'A' AND h.edad = 1 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_coo_1a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='COG' AND h.tip_edad = 'A' AND h.edad = 1 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_cog_1a,

SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='LEN' AND h.tip_edad = 'A' AND h.edad = 2 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_len_2a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='MOT' AND h.tip_edad = 'A' AND h.edad = 2 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_mot_2a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='SOC' AND h.tip_edad = 'A' AND h.edad = 2 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_soc_2a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='COO' AND h.tip_edad = 'A' AND h.edad = 2 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_coo_2a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='COG' AND h.tip_edad = 'A' AND h.edad = 2 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_cog_2a,

SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='LEN' AND h.tip_edad = 'A' AND h.edad = 3 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_len_3a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='MOT' AND h.tip_edad = 'A' AND h.edad = 3 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_mot_3a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='SOC' AND h.tip_edad = 'A' AND h.edad = 3 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_soc_3a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='COO' AND h.tip_edad = 'A' AND h.edad = 3 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_coo_3a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='COG' AND h.tip_edad = 'A' AND h.edad = 3 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_cog_3a,

SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='LEN' AND h.tip_edad = 'A' AND h.edad = 4 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_len_4a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='MOT' AND h.tip_edad = 'A' AND h.edad = 4 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_mot_4a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='SOC' AND h.tip_edad = 'A' AND h.edad = 4 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_soc_4a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='COO' AND h.tip_edad = 'A' AND h.edad = 4 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_coo_4a,
SUM(CASE WHEN h.codigo_item = 'R620' AND h.valor_lab='COG' AND h.tip_edad = 'A' AND h.edad = 4 AND f.eval_des_rec_R620 = 1 THEN 1 ELSE 0 END) AS rec_retardo_desarrollo_cog_4a,



-- ==========================
-- EVALUACION DEL ESTADO NUTRICIONAL
-- ==========================

-- ---PESO / EDAD
SUM(CASE WHEN f.eval_PE_R628 = 1 AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS G_inadecuada_pe_men1a,
SUM(CASE WHEN f.eval_PE_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS G_inadecuada_pe_1a,
SUM(CASE WHEN f.eval_PE_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS G_inadecuada_pe_2a,
SUM(CASE WHEN f.eval_PE_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS G_inadecuada_pe_3a,
SUM(CASE WHEN f.eval_PE_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS G_inadecuada_pe_4a,

SUM(CASE WHEN f.eval_PE_R628 = 1 AND f.eval_rec_R628 = 1 AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS G_inadecuada_pe_PR_men1a,
SUM(CASE WHEN f.eval_PE_R628 = 1 AND f.eval_rec_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS G_inadecuada_pe_PR_1a,
SUM(CASE WHEN f.eval_PE_R628 = 1 AND f.eval_rec_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS G_inadecuada_pe_PR_2a,
SUM(CASE WHEN f.eval_PE_R628 = 1 AND f.eval_rec_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS G_inadecuada_pe_PR_3a,
SUM(CASE WHEN f.eval_PE_R628 = 1 AND f.eval_rec_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS G_inadecuada_pe_PR_4a,

-- ---TALLA / EDAD
SUM(CASE WHEN f.eval_TE_R628 = 1 AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS G_inadecuada_talla_men1a,
SUM(CASE WHEN f.eval_TE_R628 = 1 AND f.eval_PE_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS G_inadecuada_talla_1a,
SUM(CASE WHEN f.eval_TE_R628 = 1 AND f.eval_PE_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS G_inadecuada_talla_2a,
SUM(CASE WHEN f.eval_TE_R628 = 1 AND f.eval_PE_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS G_inadecuada_talla_3a,
SUM(CASE WHEN f.eval_TE_R628 = 1 AND f.eval_PE_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS G_inadecuada_talla_4a,

SUM(CASE WHEN f.eval_TE_R628 = 1 AND f.eval_rec_R628 = 1 AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS G_inadecuada_talla_PR_men1a,
SUM(CASE WHEN f.eval_TE_R628 = 1 AND f.eval_rec_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS G_inadecuada_talla_PR_1a,
SUM(CASE WHEN f.eval_TE_R628 = 1 AND f.eval_rec_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS G_inadecuada_talla_PR_2a,
SUM(CASE WHEN f.eval_TE_R628 = 1 AND f.eval_rec_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS G_inadecuada_talla_PR_3a,
SUM(CASE WHEN f.eval_TE_R628 = 1 AND f.eval_rec_R628 = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS G_inadecuada_talla_PR_4a,

-- ---DESNUTRICION AGUDA
SUM(CASE WHEN f.desn_aguda_TP_E440 = 1 AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS desnutric_Aguda_men1a,
SUM(CASE WHEN f.desn_aguda_TP_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS desnutric_Aguda_1a,
SUM(CASE WHEN f.desn_aguda_TP_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS desnutric_Aguda_2a,
SUM(CASE WHEN f.desn_aguda_TP_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS desnutric_Aguda_3a,
SUM(CASE WHEN f.desn_aguda_TP_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS desnutric_Aguda_4a,

SUM(CASE WHEN f.desn_aguda_TP_E440 = 1 AND f.desn_aguda_PR_E440 = 1 AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS desnutric_Aguda_PR_men1a,
SUM(CASE WHEN f.desn_aguda_TP_E440 = 1 AND f.desn_aguda_PR_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS desnutric_Aguda_PR_1a,
SUM(CASE WHEN f.desn_aguda_TP_E440 = 1 AND f.desn_aguda_PR_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS desnutric_Aguda_PR_2a,
SUM(CASE WHEN f.desn_aguda_TP_E440 = 1 AND f.desn_aguda_PR_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS desnutric_Aguda_PR_3a,
SUM(CASE WHEN f.desn_aguda_TP_E440 = 1 AND f.desn_aguda_PR_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS desnutric_Aguda_PR_4a,

-- ---DESNUTRICION GLOBAL
SUM(CASE WHEN f.desn_global_PE_E440 = 1 AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS desnutric_global_men1a,
SUM(CASE WHEN f.desn_global_PE_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS desnutric_global_1a,
SUM(CASE WHEN f.desn_global_PE_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS desnutric_global_2a,
SUM(CASE WHEN f.desn_global_PE_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS desnutric_global_3a,
SUM(CASE WHEN f.desn_global_PE_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS desnutric_global_4a,

SUM(CASE WHEN f.desn_global_PE_E440 = 1 AND f.desn_global_PR_E440 = 1 AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS desnutric_global_PR_men1a,
SUM(CASE WHEN f.desn_global_PE_E440 = 1 AND f.desn_global_PR_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS desnutric_global_PR_1a,
SUM(CASE WHEN f.desn_global_PE_E440 = 1 AND f.desn_global_PR_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS desnutric_global_PR_2a,
SUM(CASE WHEN f.desn_global_PE_E440 = 1 AND f.desn_global_PR_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS desnutric_global_PR_3a,
SUM(CASE WHEN f.desn_global_PE_E440 = 1 AND f.desn_global_PR_E440 = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS desnutric_global_PR_4a,

-- ==========================
-- DESNUTRICION CRONICA
-- ==========================

SUM(CASE WHEN f.desn_cronica_TE_E45X = 1 AND h.tip_edad = 'M' THEN 1 END) AS desnutric_cronica_men1a,
SUM(CASE WHEN f.desn_cronica_TE_E45X = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 END) AS desnutric_cronica_1a,
SUM(CASE WHEN f.desn_cronica_TE_E45X = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 END) AS desnutric_cronica_2a,
SUM(CASE WHEN f.desn_cronica_TE_E45X = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 END) AS desnutric_cronica_3a,
SUM(CASE WHEN f.desn_cronica_TE_E45X = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 END) AS desnutric_cronica_4a,

SUM(CASE WHEN f.desn_cronica_TE_E45X = 1 AND f.desn_cronica_rec_E45X = 1 AND h.tip_edad = 'M' THEN 1 END) AS desnutric_cronica_PR_men1a,
SUM(CASE WHEN f.desn_cronica_TE_E45X = 1 AND f.desn_cronica_rec_E45X = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 END) AS desnutric_cronica_PR_1a,
SUM(CASE WHEN f.desn_cronica_TE_E45X = 1 AND f.desn_cronica_rec_E45X = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 END) AS desnutric_cronica_PR_2a,
SUM(CASE WHEN f.desn_cronica_TE_E45X = 1 AND f.desn_cronica_rec_E45X = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 END) AS desnutric_cronica_PR_3a,
SUM(CASE WHEN f.desn_cronica_TE_E45X = 1 AND f.desn_cronica_rec_E45X = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 END) AS desnutric_cronica_PR_4a,

-- ==========================
-- DESNUTRICION SEVERA
-- ==========================

SUM(CASE WHEN f.desn_severa_TP_E43X = 1 AND h.tip_edad = 'M' THEN 1 END) AS desnutric_severa_men1a,
SUM(CASE WHEN f.desn_severa_TP_E43X = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 END) AS desnutric_severa_1a,
SUM(CASE WHEN f.desn_severa_TP_E43X = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 END) AS desnutric_severa_2a,
SUM(CASE WHEN f.desn_severa_TP_E43X = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 END) AS desnutric_severa_3a,
SUM(CASE WHEN f.desn_severa_TP_E43X = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 END) AS desnutric_severa_4a,

SUM(CASE WHEN f.desn_severa_TP_E43X = 1 AND f.desn_severa_rec_E43X = 1 AND h.tip_edad = 'M' THEN 1 END) AS desnutric_severa_PR_men1a,
SUM(CASE WHEN f.desn_severa_TP_E43X = 1 AND f.desn_severa_rec_E43X = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 END) AS desnutric_severa_PR_1a,
SUM(CASE WHEN f.desn_severa_TP_E43X = 1 AND f.desn_severa_rec_E43X = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 END) AS desnutric_severa_PR_2a,
SUM(CASE WHEN f.desn_severa_TP_E43X = 1 AND f.desn_severa_rec_E43X = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 END) AS desnutric_severa_PR_3a,
SUM(CASE WHEN f.desn_severa_TP_E43X = 1 AND f.desn_severa_rec_E43X = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 END) AS desnutric_severa_PR_4a,

-- ==========================
-- SOBRE PESO
-- ==========================

SUM(CASE WHEN f.sobre_peso_TP_E6690 = 1 AND h.tip_edad = 'M' THEN 1 END) AS sobre_peso_men1a,
SUM(CASE WHEN f.sobre_peso_TP_E6690 = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 END) AS sobre_peso_1a,
SUM(CASE WHEN f.sobre_peso_TP_E6690 = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 END) AS sobre_peso_2a,
SUM(CASE WHEN f.sobre_peso_TP_E6690 = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 END) AS sobre_peso_3a,
SUM(CASE WHEN f.sobre_peso_TP_E6690 = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 END) AS sobre_peso_4a,

SUM(CASE WHEN f.sobre_peso_TP_E6690 = 1 AND f.sobre_peso_rec_E6690 = 1 AND h.tip_edad = 'M' THEN 1 END) AS sobre_peso_PR_men1a,
SUM(CASE WHEN f.sobre_peso_TP_E6690 = 1 AND f.sobre_peso_rec_E6690 = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 END) AS sobre_peso_PR_1a,
SUM(CASE WHEN f.sobre_peso_TP_E6690 = 1 AND f.sobre_peso_rec_E6690 = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 END) AS sobre_peso_PR_2a,
SUM(CASE WHEN f.sobre_peso_TP_E6690 = 1 AND f.sobre_peso_rec_E6690 = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 END) AS sobre_peso_PR_3a,
SUM(CASE WHEN f.sobre_peso_TP_E6690 = 1 AND f.sobre_peso_rec_E6690 = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 END) AS sobre_peso_PR_4a,

-- ==========================
-- OBESIDAD
-- ==========================

SUM(CASE WHEN f.obeso_TP_E669 = 1 AND h.tip_edad = 'M' THEN 1 END) AS obeso_men1a,
SUM(CASE WHEN f.obeso_TP_E669 = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 END) AS obeso_1a,
SUM(CASE WHEN f.obeso_TP_E669 = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 END) AS obeso_2a,
SUM(CASE WHEN f.obeso_TP_E669 = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 END) AS obeso_3a,
SUM(CASE WHEN f.obeso_TP_E669 = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 END) AS obeso_4a,

SUM(CASE WHEN f.obeso_TP_E669 = 1 AND f.obeso_rec_E669 = 1 AND h.tip_edad = 'M' THEN 1 END) AS obeso_PR_men1a,
SUM(CASE WHEN f.obeso_TP_E669 = 1 AND f.obeso_rec_E669 = 1 AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 END) AS obeso_PR_1a,
SUM(CASE WHEN f.obeso_TP_E669 = 1 AND f.obeso_rec_E669 = 1 AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 END) AS obeso_PR_2a,
SUM(CASE WHEN f.obeso_TP_E669 = 1 AND f.obeso_rec_E669 = 1 AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 END) AS obeso_PR_3a,
SUM(CASE WHEN f.obeso_TP_E669 = 1 AND f.obeso_rec_E669 = 1 AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 END) AS obeso_PR_4a,

-- ==========================
-- IMC 5-11 AÑOS
-- ==========================

SUM(CASE WHEN f.obeso_TP_E669 = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 END) AS obeso_5_11a,
SUM(CASE WHEN f.obeso_TP_E669 = 1 AND h.valor_lab = 'DE669 PR' AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 END) AS obeso_rec_5_11a,

SUM(CASE WHEN f.obeso_TP_E669 = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 END) AS sobre_peso_5_11a,
SUM(CASE WHEN f.obeso_TP_E669 = 1 AND h.valor_lab = 'DE6690 PR' AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 END) AS sobre_peso_rec_5_11a,

-- ==========================
-- TALLA / EDAD 5-11
-- ==========================

SUM(CASE WHEN f.talla_Edad_TE_E344 = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 END) AS te_alto_5_11a,
SUM(CASE WHEN f.talla_Edad_TE_E344 = 1 AND f.talla_Edad_TE_rec_E344 = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 END) AS te_alto_rec_5_11a,

-- ==========================
-- EXAMEN SERIADO DE HECES
-- ==========================

SUM(CASE WHEN h.codigo_item = '87177.01' AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 END) AS seriado_heces_1a,
SUM(CASE WHEN h.codigo_item = '87177.01' AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 END) AS seriado_heces_2a,
SUM(CASE WHEN h.codigo_item = '87177.01' AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 END) AS seriado_heces_3a,
SUM(CASE WHEN h.codigo_item = '87177.01' AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 END) AS seriado_heces_4a,
SUM(CASE WHEN h.codigo_item = '87177.01' AND h.tip_edad = 'A' AND h.edad = 5 THEN 1 END) AS seriado_heces_5a,
SUM(CASE WHEN h.codigo_item = '87177.01' AND h.tip_edad = 'A' AND h.edad = 6 THEN 1 END) AS seriado_heces_6a,
SUM(CASE WHEN h.codigo_item = '87177.01' AND h.tip_edad = 'A' AND h.edad = 7 THEN 1 END) AS seriado_heces_7a,
SUM(CASE WHEN h.codigo_item = '87177.01' AND h.tip_edad = 'A' AND h.edad = 8 THEN 1 END) AS seriado_heces_8a,
SUM(CASE WHEN h.codigo_item = '87177.01' AND h.tip_edad = 'A' AND h.edad = 9 THEN 1 END) AS seriado_heces_9a,
SUM(CASE WHEN h.codigo_item = '87177.01' AND h.tip_edad = 'A' AND h.edad = 10 THEN 1 END) AS seriado_heces_10a,
SUM(CASE WHEN h.codigo_item = '87177.01' AND h.tip_edad = 'A' AND h.edad = 11 THEN 1 END) AS seriado_heces_11a,
SUM(CASE WHEN h.codigo_item = '87177.01' AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 END) AS seriado_heces_5_11a,

----posisitivo  para seriado  de heces

SUM(CASE WHEN h.tip_edad = 'A' AND h.edad = 1 AND h.codigo_item IN ('B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664') THEN 1 ELSE 0 END) AS seriado_heces_positivo_1a,
SUM(CASE WHEN h.tip_edad = 'A' AND h.edad = 2 AND h.codigo_item IN ('B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664') THEN 1 ELSE 0 END) AS seriado_heces_positivo_2a,
SUM(CASE WHEN h.tip_edad = 'A' AND h.edad = 3 AND h.codigo_item IN ('B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664') THEN 1 ELSE 0 END) AS seriado_heces_positivo_3a,
SUM(CASE WHEN h.tip_edad = 'A' AND h.edad = 4 AND h.codigo_item IN ('B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664') THEN 1 ELSE 0 END) AS seriado_heces_positivo_4a,
SUM(CASE WHEN h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 AND h.codigo_item IN ('B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664')THEN 1 ELSE 0 END) AS seriado_heces_positivo_5_11a,

---SERIADO DE HECES   POSITIVOS TRATADOS 
SUM(CASE WHEN h.tip_edad = 'A' AND h.edad = 1 AND h.codigo_item IN ('B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664') AND f.tratamiento_edas_99199_11 = 1  THEN 1 ELSE 0 END) AS SH_positivo_tto_1a,
SUM(CASE WHEN h.tip_edad = 'A' AND h.edad = 2 AND h.codigo_item IN ('B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664') AND f.tratamiento_edas_99199_11 = 1  THEN 1 ELSE 0 END) AS SH_positivo_tto_2a,
SUM(CASE WHEN h.tip_edad = 'A' AND h.edad = 3 AND h.codigo_item IN ('B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664') AND f.tratamiento_edas_99199_11 = 1  THEN 1 ELSE 0 END) AS SH_positivo_tto_3a,
SUM(CASE WHEN h.tip_edad = 'A' AND h.edad = 4 AND h.codigo_item IN ('B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664') AND f.tratamiento_edas_99199_11 = 1  THEN 1 ELSE 0 END) AS SH_positivo_tto_4a,
SUM(CASE WHEN h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 AND h.codigo_item IN ('B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664') AND f.tratamiento_edas_99199_11 = 1  THEN 1 ELSE 0 END) AS SH_positivo_tto_5_11a,

---
SUM(CASE WHEN h.codigo_item='87178' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS test_graham_1a,
SUM(CASE WHEN h.codigo_item='87178' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS test_graham_2a,
SUM(CASE WHEN h.codigo_item='87178' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS test_graham_3a,
SUM(CASE WHEN h.codigo_item='87178' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS test_graham_4a,
SUM(CASE WHEN h.codigo_item='87178' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS test_graham_5a,
SUM(CASE WHEN h.codigo_item='87178' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS test_graham_6a,
SUM(CASE WHEN h.codigo_item='87178' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS test_graham_7a,
SUM(CASE WHEN h.codigo_item='87178' AND h.tip_edad='A' AND h.edad=8 THEN 1 ELSE 0 END) AS test_graham_8a,
SUM(CASE WHEN h.codigo_item='87178' AND h.tip_edad='A' AND h.edad=9 THEN 1 ELSE 0 END) AS test_graham_9a,
SUM(CASE WHEN h.codigo_item='87178' AND h.tip_edad='A' AND h.edad=10 THEN 1 ELSE 0 END) AS test_graham_10a,
SUM(CASE WHEN h.codigo_item='87178' AND h.tip_edad='A' AND h.edad=11 THEN 1 ELSE 0 END) AS test_graham_11a,
SUM(CASE WHEN h.codigo_item='87178' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS test_graham_5_11a,

-- TEST DE GRAHAM POSITIVO

SUM(CASE WHEN h.codigo_item='B80X' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS test_graham_posit_1a,
SUM(CASE WHEN h.codigo_item='B80X' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS test_graham_posit_2a,
SUM(CASE WHEN h.codigo_item='B80X' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS test_graham_posit_3a,
SUM(CASE WHEN h.codigo_item='B80X' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS test_graham_posit_4a,
SUM(CASE WHEN h.codigo_item='B80X' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS test_graham_posit_5a,
SUM(CASE WHEN h.codigo_item='B80X' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS test_graham_posit_6a,
SUM(CASE WHEN h.codigo_item='B80X' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS test_graham_posit_7a,
SUM(CASE WHEN h.codigo_item='B80X' AND h.tip_edad='A' AND h.edad=8 THEN 1 ELSE 0 END) AS test_graham_posit_8a,
SUM(CASE WHEN h.codigo_item='B80X' AND h.tip_edad='A' AND h.edad=9 THEN 1 ELSE 0 END) AS test_graham_posit_9a,
SUM(CASE WHEN h.codigo_item='B80X' AND h.tip_edad='A' AND h.edad=10 THEN 1 ELSE 0 END) AS test_graham_posit_10a,
SUM(CASE WHEN h.codigo_item='B80X' AND h.tip_edad='A' AND h.edad=11 THEN 1 ELSE 0 END) AS test_graham_posit_11a,
SUM(CASE WHEN h.codigo_item='B80X' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS test_graham_posit_5_11a,

-- TEST DE GRAHAM POSITIVO TRATADO

SUM(CASE WHEN h.codigo_item='B80X' AND f.tratamiento_edas_99199_11 = 1 AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS test_graham_tto_1a,
SUM(CASE WHEN h.codigo_item='B80X' AND f.tratamiento_edas_99199_11 = 1 AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS test_graham_tto_2a,
SUM(CASE WHEN h.codigo_item='B80X' AND f.tratamiento_edas_99199_11 = 1 AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS test_graham_tto_3a,
SUM(CASE WHEN h.codigo_item='B80X' AND f.tratamiento_edas_99199_11 = 1 AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS test_graham_tto_4a,
SUM(CASE WHEN h.codigo_item='B80X' AND f.tratamiento_edas_99199_11 = 1 AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS test_graham_tto_5a,
SUM(CASE WHEN h.codigo_item='B80X' AND f.tratamiento_edas_99199_11 = 1 AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS test_graham_tto_6a,
SUM(CASE WHEN h.codigo_item='B80X' AND f.tratamiento_edas_99199_11 = 1 AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS test_graham_tto_7a,
SUM(CASE WHEN h.codigo_item='B80X' AND f.tratamiento_edas_99199_11 = 1 AND h.tip_edad='A' AND h.edad=8 THEN 1 ELSE 0 END) AS test_graham_tto_8a,
SUM(CASE WHEN h.codigo_item='B80X' AND f.tratamiento_edas_99199_11 = 1 AND h.tip_edad='A' AND h.edad=9 THEN 1 ELSE 0 END) AS test_graham_tto_9a,
SUM(CASE WHEN h.codigo_item='B80X' AND f.tratamiento_edas_99199_11 = 1 AND h.tip_edad='A' AND h.edad=10 THEN 1 ELSE 0 END) AS test_graham_tto_10a,
SUM(CASE WHEN h.codigo_item='B80X' AND f.tratamiento_edas_99199_11 = 1 AND h.tip_edad='A' AND h.edad=11 THEN 1 ELSE 0 END) AS test_graham_tto_11a,
SUM(CASE WHEN h.codigo_item='B80X' AND f.tratamiento_edas_99199_11 = 1 AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS test_graham_tto_5_11a,


--- PARASITOSIS (ANTIPARASITARIOS)
SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS antiparasitaria_1_2a,
SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS antiparasitaria_2_2a,

SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS antiparasitaria_1_3a,
SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS antiparasitaria_2_3a,

SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS antiparasitaria_1_4a,
SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS antiparasitaria_2_4a,

SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS antiparasitaria_1_5a,
SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS antiparasitaria_2_5a,

SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS antiparasitaria_1_6a,
SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS antiparasitaria_2_6a,

SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS antiparasitaria_1_7a,
SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS antiparasitaria_2_7a,

SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=8 THEN 1 ELSE 0 END) AS antiparasitaria_1_8a,
SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=8 THEN 1 ELSE 0 END) AS antiparasitaria_2_8a,

SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=9 THEN 1 ELSE 0 END) AS antiparasitaria_1_9a,
SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=9 THEN 1 ELSE 0 END) AS antiparasitaria_2_9a,

SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=10 THEN 1 ELSE 0 END) AS antiparasitaria_1_10a,
SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=10 THEN 1 ELSE 0 END) AS antiparasitaria_2_10a,

SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=11 THEN 1 ELSE 0 END) AS antiparasitaria_1_11a,
SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=11 THEN 1 ELSE 0 END) AS antiparasitaria_2_11a,

SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS antiparasitaria_1_5_11a,
SUM(CASE WHEN h.codigo_item='99199.28' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS antiparasitaria_2_5_11a,

---- VISITA DOMICILIARIA

SUM(CASE WHEN h.codigo_item = 'C0011' AND h.valor_lab = '1' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS vis_domic_1_bpn,
SUM(CASE WHEN h.codigo_item = 'C0011' AND h.valor_lab = '2' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS vis_domic_2_bpn,
SUM(CASE WHEN h.codigo_item = 'C0011' AND h.valor_lab = '3' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS vis_domic_3_bpn,
SUM(CASE WHEN h.codigo_item = 'C0011' AND h.valor_lab = '1' AND h.tip_edad = 'M' AND h.edad <= 6 THEN 1 ELSE 0 END) AS vis_domic_1_men1a,
SUM(CASE WHEN h.codigo_item = 'C0011' AND h.valor_lab = '2' AND h.tip_edad = 'M' AND h.edad <= 6 THEN 1 ELSE 0 END) AS vis_domic_2_men1a,
SUM(CASE WHEN h.codigo_item = 'C0011' AND h.valor_lab = '1' AND h.tip_edad = 'A' AND h.edad_meses BETWEEN 6 AND 23 THEN 1 ELSE 0 END) AS vis_domic1_6_23m,
SUM(CASE WHEN h.codigo_item = 'C0011' AND h.valor_lab = '2' AND h.tip_edad = 'A' AND h.edad_meses BETWEEN 6 AND 23 THEN 1 ELSE 0 END) AS vis_domic2_6_23m,
SUM(CASE WHEN h.codigo_item = 'C0011' AND h.valor_lab = '3' AND h.tip_edad = 'A' AND h.edad_meses BETWEEN 6 AND 23 THEN 1 ELSE 0 END) AS vis_domic3_6_23m,
SUM(CASE WHEN h.codigo_item = 'C0011' AND h.valor_lab = '1' AND h.tip_edad = 'A' AND h.edad_meses BETWEEN 36 AND 59 THEN 1 ELSE 0 END) AS vis_domic1_36_59m

FROM base h
LEFT JOIN cita_flags_2026 ci ON h.id_cita = ci.id_cita
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

  m.sesion_est_temprana_menor_1A_1,	
  m.sesion_est_temprana_menor_1A_2,	
  m.sesion_est_temprana_menor_1A_3,	
  m.sesion_est_temprana_menor_1A_4,	
  m.sesion_est_temprana_menor_1A_5,	
  m.sesion_est_temprana_menor_1A_6,
  m.sesion_est_temprana_menor_1A_7,
  m.sesion_est_temprana_menor_1A_8,
  m.sesion_est_temprana_menor_1A_9,
  m.sesion_est_temprana_menor_1A_10,
  m.sesion_est_temprana_menor_1A_11,
  
  m.sesion_est_temprana_1A_1,	
  m.sesion_est_temprana_1A_2,	
  m.sesion_est_temprana_1A_3,	
  m.sesion_est_temprana_1A_4,	
  m.sesion_est_temprana_1A_5,	
  m.sesion_est_temprana_1A_6,
  m.sesion_est_temprana_2A_1,	
  m.sesion_est_temprana_2A_2,	
  m.sesion_est_temprana_2A_3,	
  m.sesion_est_temprana_2A_4,	
  m.sesion_est_temprana_3A_1,	
  m.sesion_est_temprana_3A_2,	
  m.sesion_est_temprana_3A_3,	
  m.sesion_est_temprana_3A_4,
  --retrdo en el desarrollo
  m.Retardo_desarrollo_len_m1a,
  m.Retardo_desarrollo_mot_m1a,
  m.Retardo_desarrollo_soc_m1a,
  m.Retardo_desarrollo_coo_m1a,
  m.Retardo_desarrollo_cog_m1a,
  m.Retardo_desarrollo_len_1a,
  m.Retardo_desarrollo_mot_1a,
  m.Retardo_desarrollo_soc_1a,
  m.Retardo_desarrollo_coo_1a,
  m.Retardo_desarrollo_cog_1a,
  m.Retardo_desarrollo_len_2a,
  m.Retardo_desarrollo_mot_2a,
  m.Retardo_desarrollo_soc_2a,
  m.Retardo_desarrollo_coo_2a,
  m.Retardo_desarrollo_cog_2a,
  --recuperado retardo  en el  dearrollo
  m.rec_retardo_desarrollo_len_m1a,
  m.rec_retardo_desarrollo_mot_m1a,
  m.rec_retardo_desarrollo_soc_m1a,
  m.rec_retardo_desarrollo_coo_m1a,
  m.rec_retardo_desarrollo_cog_m1a,
  m.rec_retardo_desarrollo_len_1a,
  m.rec_retardo_desarrollo_mot_1a,
  m.rec_retardo_desarrollo_soc_1a,
  m.rec_Retardo_desarrollo_coo_1a,
  m.rec_Retardo_desarrollo_cog_1a,
  m.rec_Retardo_desarrollo_len_2a,
  m.rec_Retardo_desarrollo_mot_2a,
  m.rec_Retardo_desarrollo_soc_2a,
  m.rec_Retardo_desarrollo_coo_2a,
  m.rec_Retardo_desarrollo_cog_2a,
  ---EVALUACION DEL  ESTADO NUTRICIONAL 
  ---PESO / EDAD
  m.G_inadecuada_pe_men1a,
  m.G_inadecuada_pe_1a,
  m.G_inadecuada_pe_2a,
  m.G_inadecuada_pe_3a,
  m.G_inadecuada_pe_4a,

  m.G_inadecuada_pe_PR_men1a,
  m.G_inadecuada_pe_PR_1a,
  m.G_inadecuada_pe_PR_2a,
  m.G_inadecuada_pe_PR_3a,
  m.G_inadecuada_pe_PR_4a,
  
  ---TALLA / EDAD
  m.G_inadecuada_talla_men1a,
  m.G_inadecuada_talla_1a,
  m.G_inadecuada_talla_2a,
  m.G_inadecuada_talla_3a,
  m.G_inadecuada_talla_4a,
  
  m.G_inadecuada_talla_PR_men1a,
  m.G_inadecuada_talla_PR_1a,
  m.G_inadecuada_talla_PR_2a,
  m.G_inadecuada_talla_PR_3a,
  m.G_inadecuada_talla_PR_4a,
  
  ---DESNUTIRCION AGUDA
  m.desnutric_Aguda_men1a,
  m.desnutric_Aguda_1a,
  m.desnutric_Aguda_2a,
  m.desnutric_Aguda_3a,
  m.desnutric_Aguda_4a,
  
  m.desnutric_Aguda_PR_men1a,
  m.desnutric_Aguda_PR_1a,
  m.desnutric_Aguda_PR_2a,
  m.desnutric_Aguda_PR_3a,
  m.desnutric_Aguda_PR_4a,
  
    ---DESNUTIRCION CRONICA
  m.desnutric_cronica_men1a,
  m.desnutric_cronica_1a,
  m.desnutric_cronica_2a,
  m.desnutric_cronica_3a,
  m.desnutric_cronica_4a,
  
  m.desnutric_cronica_PR_men1a,
  m.desnutric_cronica_PR_1a,
  m.desnutric_cronica_PR_2a,
  m.desnutric_cronica_PR_3a,
  m.desnutric_cronica_PR_4a,
  
     ---DESNUTIRCION SEVERA
  m.desnutric_severa_men1a,
  m.desnutric_severa_1a,
  m.desnutric_severa_2a,
  m.desnutric_severa_3a,
  m.desnutric_severa_4a,
  
  m.desnutric_severa_PR_men1a,
  m.desnutric_severa_PR_1a,
  m.desnutric_severa_PR_2a,
  m.desnutric_severa_PR_3a,
  m.desnutric_severa_PR_4a,
  
  m.desnutric_global_men1a,
  m.desnutric_global_1a,
  m.desnutric_global_2a,
  m.desnutric_global_3a,
  m.desnutric_global_4a,
  
  m.desnutric_global_PR_men1a,
  m.desnutric_global_PR_1a,
  m.desnutric_global_PR_2a,
  m.desnutric_global_PR_3a,
  m.desnutric_global_PR_4a,
  
  
  ----sobre peso
  m.sobre_peso_men1a,
  m.sobre_peso_1a,
  m.sobre_peso_2a,
  m.sobre_peso_3a,
  m.sobre_peso_4a,
  
  m.sobre_peso_PR_men1a,
  m.sobre_peso_PR_1a,
  m.sobre_peso_PR_2a,
  m.sobre_peso_PR_3a,
  m.sobre_peso_PR_4a,
  
  ----OBESO
  m.obeso_men1a,
  m.obeso_1a,
  m.obeso_2a,
  m.obeso_3a,
  m.obeso_4a,
  
  m.obeso_PR_men1a,
  m.obeso_PR_1a,
  m.obeso_PR_2a,
  m.obeso_PR_3a,
  m.obeso_PR_4a,
  
  ---IMC
m.obeso_5_11a,
m.obeso_rec_5_11a,
m.sobre_peso_5_11a,
m.sobre_peso_rec_5_11a,
m.te_alto_5_11a,
m.te_alto_rec_5_11a,



--SERIADO DE HECES

 m.Seriado_heces_1a,
 m.Seriado_heces_2a,
 m.Seriado_heces_3a,
 m.Seriado_heces_4a,
 m.Seriado_heces_5a,
 m.Seriado_heces_6a,
 m.Seriado_heces_7a,
 m.Seriado_heces_8a,
 m.Seriado_heces_9a,
 m.Seriado_heces_10a,
 m.Seriado_heces_11a,
 m.seriado_heces_5_11a,
   		  
  --posisitivo  para seriado  de heces
   		  
 m.seriado_heces_positivo_1a,
 m.seriado_heces_positivo_2a,
 m.seriado_heces_positivo_3a,
 m.seriado_heces_positivo_4a,
 m.seriado_heces_positivo_5_11a,

----positivos examen  seriado  de heces tratados
---SERIADO DE HECES   POSITIVOS TRATADOS 
m.SH_positivo_tto_1a,
m.SH_positivo_tto_2a,
m.SH_positivo_tto_3a,
m.SH_positivo_tto_4a,
m.SH_positivo_tto_5_11a,

--test de grahama  		  
 m.test_graham_1a,
 m.test_graham_2a,
 m.test_graham_3a,
 m.test_graham_4a,
 m.test_graham_5a,
 m.test_graham_6a,
 m.test_graham_7a,
 m.test_graham_8a,
 m.test_graham_9a,
 m.test_graham_10a,
 m.test_graham_11a,
 m.test_graham_5_11a,
   		  
   		  ---positivo para tst de grraham
   		  
 m.test_graham_posit_1a,
 m.test_graham_posit_2a,
 m.test_graham_posit_3a,
 m.test_graham_posit_4a,
 m.test_graham_posit_5a,
 m.test_graham_posit_6a,
 m.test_graham_posit_7a,
 m.test_graham_posit_8a,
 m.test_graham_posit_9a,
 m.test_graham_posit_10a,
 m.test_graham_posit_11a,
 m.test_graham_posit_5_11a,

-- TEST DE GRAHAM POSITIVO TRATADO

m.test_graham_tto_1a,
m.test_graham_tto_2a,
m.test_graham_tto_3a,
m.test_graham_tto_4a,
m.test_graham_tto_5a,
m.test_graham_tto_6a,
m.test_graham_tto_7a,
m.test_graham_tto_8a,
m.test_graham_tto_9a,
m.test_graham_tto_10a,
m.test_graham_tto_11a,
m.test_graham_tto_5_11a,

   		  
   		 --posisitivo  para seriado  de heces
       
   m.antiparasitaria_1_2a,
   m.antiparasitaria_2_2a,
   m.antiparasitaria_1_3a,
   m.antiparasitaria_2_3a,
   m.antiparasitaria_1_4a,
   m.antiparasitaria_2_4a,
   m.antiparasitaria_1_5a,
   m.antiparasitaria_2_5a,
   m.antiparasitaria_1_6a,
   m.antiparasitaria_2_6a,
   m.antiparasitaria_1_7a,
   m.antiparasitaria_2_7a,
   m.antiparasitaria_1_8a,
   m.antiparasitaria_2_8a,
   m.antiparasitaria_1_9a,
   m.antiparasitaria_2_9a,
   m.antiparasitaria_1_10a,
   m.antiparasitaria_2_10a,
   m.antiparasitaria_1_11a,
   m.antiparasitaria_2_11a,
   m.antiparasitaria_1_5_11a,
   m.antiparasitaria_2_5_11a,
    
  ---visita domiciliaria o  teleorientacion
  
  m.vis_domic_1_bpn,
  m.vis_domic_2_bpn,
  m.vis_domic_3_bpn,
  m.vis_domic_1_men1a,
  m.vis_domic_2_men1a,
  m.vis_domic1_6_23m,
  m.vis_domic2_6_23m,
  m.vis_domic3_6_23m,
  m.vis_domic1_36_59m
  
    
FROM monitoreo_general m
ORDER BY m.cod_2000, m.anio, m.mes;


---table hemoglobina 
   DROP TABLE IF EXISTS es_ivan.cred2026_2;

    -- 2️⃣ Eliminar tabla temporal si existe


CREATE TABLE es_ivan.cred2026_2 AS

-- ============================================
-- 🔥 BASE MINIMA (SOLO LO NECESARIO)
-- ============================================
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

    (
        EXTRACT(YEAR FROM age(fecha_atencion, fecha_nacimiento)) * 12 +
        EXTRACT(MONTH FROM age(fecha_atencion, fecha_nacimiento))
    )::int AS edad_meses

    FROM es_ivan.tabla_vacunas
    WHERE anio >= 2025
      AND codigo_item IN ('99199.26','99403','99403.01','99436','99381.01','99401.03','99411.01','99431','J00X','P599','J029','99381','99382','99383','C8002','Z001',
      						'99401.05','99401.07','99401.08','99401.09','99401.12','99401.16','99401.24','99401.25','99403.01','99401.03','P929','99211','99211','99199.17','R620','R628','E440',
      						'E669','E6690','E45X','E43X','E344','87177.01','B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664','87178',
      						'B80X','99199.28','C0011','85018.01','P070','P071','P0711','P0712','P0713','P072','P073','U1692','59430','U140','R456','Z720','Z721','Z722','Z133',
      						'H351','H351','H579','H579','Z010','PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527'
							'67228','67229','92390','99499.08','99499.09','99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10')

),

-- ============================================
-- 🔥 SOLO FLAG NECESARIO (GESTANTE)
-- ============================================
cita_flags_2026 AS (
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

/* ===================== FLAGS CLÍNICOS ===================== */

MAX((codigo_item LIKE 'P07%')::int) AS bpn_P07,
MAX((codigo_item = 'P0712')::int)   AS prematuro_P0712, 
MAX((codigo_item LIKE 'D50%')::int) AS anemia_D50,
MAX((codigo_item = '99199.17' AND valor_lab = 'TA')::int) AS suple_TA_99199_17,
MAX((codigo_item = 'C0011')::int)   AS visit_domic_C0011

FROM base
GROUP BY id_cita
),

monitoreo_general AS (
    SELECT 
        anio,
        mes,
        cod_2000,
        red,
		desc_ue,
        microred,
        provincia,
        distrito,
        nombre_establecimiento
    FROM base
    GROUP BY anio, mes, cod_2000, red,desc_ue,microred,provincia,distrito,nombre_establecimiento
),


diagnostico_bpn_prema AS (
  SELECT 
    dni_paciente, fecha_atencion, fecha_nacimiento,
    fecha_atencion - fecha_nacimiento AS dias_vida,nombre_establecimiento,red,desc_ue,microred,provincia,distrito,cod_2000  ----falta  desc_ue,
  FROM base
---menores_0_11a
  WHERE codigo_item ~ '^P07'
),  --select  * from diagnostico_bpn_prema ,

bpn_entre_30_y_59_dias AS (
  SELECT 
    dni_paciente, fecha_nacimiento,
    EXTRACT(YEAR FROM fecha_atencion) AS anio,
    EXTRACT(MONTH FROM fecha_atencion) AS mes,nombre_establecimiento,red,desc_ue,microred,provincia,distrito,cod_2000,   ----falta desc_ue,
    MIN(fecha_atencion) AS minima_fecha_atencion
  FROM diagnostico_bpn_prema
  WHERE dias_vida BETWEEN 30 AND 59
  GROUP BY dni_paciente, fecha_nacimiento, anio, mes,nombre_establecimiento,red,desc_ue,microred,provincia,distrito,cod_2000   --- falta desc_ue,
), ---select * from bpn_entre_30_y_59_dias ,


suplementacion_hierro AS (
SELECT 
    s.dni_paciente,
    s.fecha_atencion,
    s.nombre_establecimiento,
    s.desc_ue,
    s.red,
	s.desc_ue,
    s.microred,
    s.provincia,
    s.distrito,
    s.cod_2000,
    ROW_NUMBER() OVER (
        PARTITION BY s.dni_paciente 
        ORDER BY s.fecha_atencion
    ) AS nro_entrega
FROM base s
LEFT JOIN flags_cita p
       ON s.id_cita = p.id_cita
WHERE s.codigo_item = '99199.17'
  AND s.valor_lab IN ('1','2','3','4','5','6')
  AND COALESCE(p.visit_domic_C0011, 0) = 0
  AND COALESCE(p.suple_TA_99199_17, 0) = 0
),



-- select * from suplementacion_hierro,

suplementacion_may30_dias AS (
  SELECT s.*
  FROM suplementacion_hierro s
  JOIN bpn_entre_30_y_59_dias b ON s.dni_paciente = b.dni_paciente
  WHERE s.fecha_atencion >= b.fecha_nacimiento + INTERVAL '30 days' 
),

hemoglobina_dosajes AS (
  SELECT 
    dni_paciente, fecha_atencion,nombre_establecimiento,red,desc_ue,microred,provincia,distrito,cod_2000,   ---desc_ue,
    ROW_NUMBER() OVER (PARTITION BY dni_paciente ORDER BY fecha_atencion) AS nro_dosaje
  FROM base
  WHERE codigo_item='85018.01'
),

hemoglobina_bpn AS (
  SELECT h.*
  FROM hemoglobina_dosajes h
  JOIN bpn_entre_30_y_59_dias b ON h.dni_paciente = b.dni_paciente
  WHERE h.fecha_atencion >= b.fecha_nacimiento + INTERVAL '6 months'
),

bpn_resumen AS (
    SELECT
        b.anio, b.mes, b.cod_2000,
        COUNT(DISTINCT b.dni_paciente) AS total_bpn_30_59_dias,
        COUNT(DISTINCT s1.dni_paciente) AS sup_1ra_entrega_bpn,
        COUNT(DISTINCT s2.dni_paciente) AS sup_2da_entrega_bpn,
        COUNT(DISTINCT s3.dni_paciente) AS sup_3ra_entrega_bpn,
        COUNT(DISTINCT h1.dni_paciente) AS con_1er_dosaje_hemoglobina_bpn,
        COUNT(DISTINCT h2.dni_paciente) AS con_2do_dosaje_hemoglobina_bpn,
        COUNT(DISTINCT h3.dni_paciente) AS con_3er_dosaje_hemoglobina_bpn
    FROM bpn_entre_30_y_59_dias b
    LEFT JOIN suplementacion_may30_dias s1 ON s1.dni_paciente=b.dni_paciente AND s1.nro_entrega=1
    LEFT JOIN suplementacion_may30_dias s2 ON s2.dni_paciente=b.dni_paciente AND s2.nro_entrega=2
    LEFT JOIN suplementacion_may30_dias s3 ON s3.dni_paciente=b.dni_paciente AND s3.nro_entrega=3
    LEFT JOIN hemoglobina_bpn h1 ON h1.dni_paciente=b.dni_paciente AND h1.nro_dosaje=1
    LEFT JOIN hemoglobina_bpn h2 ON h2.dni_paciente=b.dni_paciente AND h2.nro_dosaje=2
    LEFT JOIN hemoglobina_bpn h3 ON h3.dni_paciente=b.dni_paciente AND h3.nro_dosaje=3
    GROUP BY b.anio, b.mes, b.cod_2000
),

/* 🔹 TODO tu bloque de hemoglobina */
-- Dosajes para todos los grupos etarios
nino_sano AS (
  SELECT
    h.id_cita,
    h.dni_paciente,
    h.codigo_item,
    h.valor_lab,
    h.genero,
    h.tip_edad,
    h.edad,
    h.edad_meses,
    h.fecha_atencion,
    h.fecha_nacimiento,
    h.nombre_establecimiento,
    h.desc_ue,
    h.red,
    h.microred,
    h.provincia,
    h.distrito,
    h.cod_2000
  FROM base h
  LEFT JOIN flags_cita p
         ON h.id_cita = p.id_cita
  WHERE h.codigo_item !~ '^P07'
    AND COALESCE(p.anemia_D50, 0) = 0
),

base_hemoglobina AS (
  SELECT
    id_cita,
    dni_paciente,
    valor_lab,
    CAST(fecha_atencion AS DATE) AS fecha_atencion,
    codigo_item,
    genero,
    tip_edad,
    edad,
    edad_meses,
    CAST(fecha_nacimiento AS DATE) AS fecha_nacimiento,
    nombre_establecimiento,
   --- desc_ue,
    red,
	desc_ue,
    microred,
    provincia,
    distrito,
    cod_2000,
    ROW_NUMBER() OVER (
        PARTITION BY dni_paciente 
        ORDER BY CAST(fecha_atencion AS DATE)
    ) AS nro_dosaje
  FROM nino_sano
  WHERE codigo_item = '85018.01'
), -- select  * from base_hemoglobina ,

dosajes_grupo AS (
  SELECT *,
        CASE
      /* -------------------------
         NIÑOS Y ADOLESCENTES
         ------------------------- */
      WHEN b.tip_edad = 'M' AND b.edad_meses BETWEEN 6 AND 11 THEN '6_11m'
      WHEN b.tip_edad = 'A' AND b.edad_meses BETWEEN 12 AND 23 THEN '12_23m'
      WHEN b.tip_edad = 'A' AND b.edad_meses BETWEEN 24 AND 35 THEN '24_35m'
      WHEN b.tip_edad = 'A' AND b.edad_meses BETWEEN 36 AND 59 THEN '36_59m'
      WHEN b.tip_edad = 'A' AND b.edad BETWEEN 5 AND 11 THEN '5_11a'
      WHEN b.tip_edad = 'A' AND b.edad BETWEEN 12 AND 17 AND b.genero = 'F' THEN '12_17a_f'

      /* -------------------------
         CONDICIÓN DE LA MUJER (por flags)
         ------------------------- */
      WHEN g.es_gestante = 1 THEN 'gestantes'

      WHEN g.es_puerpera = 1 THEN 'puerperas'

      WHEN 
           COALESCE(g.es_gestante,0) = 0
       AND COALESCE(g.es_puerpera,0) = 0
       AND b.tip_edad = 'A'
       AND b.edad BETWEEN 12 AND 59
       AND b.genero = 'F'
      THEN 'mujeres_fertiles'

    END AS grupo

  FROM base_hemoglobina b
  LEFT JOIN cita_flags_2026 g 
         ON b.id_cita = g.id_cita
  
),

pivot_dosajes AS (
  SELECT 
    dni_paciente, grupo,nombre_establecimiento,red,desc_ue,microred,provincia,distrito,cod_2000,  ---  falta desc_ue,
    MIN(CASE WHEN nro_dosaje = 1 THEN fecha_atencion END) AS dosaje_1,
    MIN(CASE WHEN nro_dosaje = 2 THEN fecha_atencion END) AS dosaje_2,
    MIN(CASE WHEN nro_dosaje = 3 THEN fecha_atencion END) AS dosaje_3
  FROM dosajes_grupo
  WHERE grupo IS NOT NULL
  GROUP BY dni_paciente, grupo,nombre_establecimiento,red,desc_ue,microred,provincia,distrito,cod_2000  ---falta desc_ue,
),

valida_dosajes AS (
  SELECT *, 
    CASE WHEN dosaje_2 IS NOT NULL AND dosaje_2 >= dosaje_1 + INTERVAL '30 days' THEN 1 ELSE 0 END AS segunda_dosaje_valida,
    CASE WHEN dosaje_3 IS NOT NULL AND dosaje_3 >= dosaje_2 + INTERVAL '30 days' THEN 1 ELSE 0 END AS tercera_dosaje_valida
  FROM pivot_dosajes
),

base_mensual AS (
  SELECT
    grupo,
    EXTRACT(YEAR FROM dosaje_1) AS anio,
    EXTRACT(MONTH FROM dosaje_1) AS mes,nombre_establecimiento,red,desc_ue,microred,provincia,distrito,cod_2000,   ---falta desc_ue,
    COUNT(DISTINCT dni_paciente) FILTER (WHERE dosaje_1 IS NOT NULL) AS hb_1er_dosaje,
    COUNT(DISTINCT dni_paciente) FILTER (WHERE segunda_dosaje_valida = 1) AS hb_2do_dosaje,
    COUNT(DISTINCT dni_paciente) FILTER (WHERE tercera_dosaje_valida = 1) AS hb_3er_dosaje
  FROM valida_dosajes
  GROUP BY grupo, anio, mes,nombre_establecimiento,red,desc_ue,microred,provincia,distrito,cod_2000   ----falta desc_ue,
),

hemoglobina_grupos AS (
  SELECT
    anio, mes,nombre_establecimiento,red,desc_ue,microred,provincia,distrito,cod_2000,   ---falta desc_ue,
    -- ejemplo para 6–11m, puedes completar los demás
   -- 6 a 11 meses
  SUM(CASE WHEN grupo = '6_11m' THEN hb_1er_dosaje ELSE 0 END) AS hb_1er_dosaje_6_11m,
  SUM(CASE WHEN grupo = '6_11m' THEN hb_2do_dosaje ELSE 0 END) AS hb_2do_dosaje_6_11m,
  SUM(CASE WHEN grupo = '6_11m' THEN hb_3er_dosaje ELSE 0 END) AS hb_3er_dosaje_6_11m,

  -- 12 a 23 meses
  SUM(CASE WHEN grupo = '12_23m' THEN hb_1er_dosaje ELSE 0 END) AS hb_1er_dosaje_12_23m,
  SUM(CASE WHEN grupo = '12_23m' THEN hb_2do_dosaje ELSE 0 END) AS hb_2do_dosaje_12_23m,
  SUM(CASE WHEN grupo = '12_23m' THEN hb_3er_dosaje ELSE 0 END) AS hb_3er_dosaje_12_23m,

  -- 24 a 35 meses
  SUM(CASE WHEN grupo = '24_35m' THEN hb_1er_dosaje ELSE 0 END) AS hb_1er_dosaje_24_35m,
  SUM(CASE WHEN grupo = '24_35m' THEN hb_2do_dosaje ELSE 0 END) AS hb_2do_dosaje_24_35m,
  SUM(CASE WHEN grupo = '24_35m' THEN hb_3er_dosaje ELSE 0 END) AS hb_3er_dosaje_24_35m,

  -- 36 a 59 meses
  SUM(CASE WHEN grupo = '36_59m' THEN hb_1er_dosaje ELSE 0 END) AS hb_1er_dosaje_36_59m,
  SUM(CASE WHEN grupo = '36_59m' THEN hb_2do_dosaje ELSE 0 END) AS hb_2do_dosaje_36_59m,
  SUM(CASE WHEN grupo = '36_59m' THEN hb_3er_dosaje ELSE 0 END) AS hb_3er_dosaje_36_59m,

  -- 5 a 11 años
  SUM(CASE WHEN grupo = '5_11a' THEN hb_1er_dosaje ELSE 0 END) AS hb_1er_dosaje_5_11a,
  SUM(CASE WHEN grupo = '5_11a' THEN hb_2do_dosaje ELSE 0 END) AS hb_2do_dosaje_5_11a,
  SUM(CASE WHEN grupo = '5_11a' THEN hb_3er_dosaje ELSE 0 END) AS hb_3er_dosaje_5_11a,

  -- 12 a 17 años (femenino)
  SUM(CASE WHEN grupo = '12_17a_f' THEN hb_1er_dosaje ELSE 0 END) AS hb_1er_dosaje_12_17a_f,
  SUM(CASE WHEN grupo = '12_17a_f' THEN hb_2do_dosaje ELSE 0 END) AS hb_2do_dosaje_12_17a_f,
  SUM(CASE WHEN grupo = '12_17a_f' THEN hb_3er_dosaje ELSE 0 END) AS hb_3er_dosaje_12_17a_f,

  -- Gestantes
  SUM(CASE WHEN grupo = 'gestantes' THEN hb_1er_dosaje ELSE 0 END) AS hb_1er_dosaje_gestantes,
  SUM(CASE WHEN grupo = 'gestantes' THEN hb_2do_dosaje ELSE 0 END) AS hb_2do_dosaje_gestantes,
  SUM(CASE WHEN grupo = 'gestantes' THEN hb_3er_dosaje ELSE 0 END) AS hb_3er_dosaje_gestantes,

  -- Puérperas
  SUM(CASE WHEN grupo = 'puerperas' THEN hb_1er_dosaje ELSE 0 END) AS hb_1er_dosaje_puerperas,
  SUM(CASE WHEN grupo = 'puerperas' THEN hb_2do_dosaje ELSE 0 END) AS hb_2do_dosaje_puerperas,
  SUM(CASE WHEN grupo = 'puerperas' THEN hb_3er_dosaje ELSE 0 END) AS hb_3er_dosaje_puerperas,

  -- Mujeres en edad fértil
  SUM(CASE WHEN grupo = 'mujeres_fertiles' THEN hb_1er_dosaje ELSE 0 END) AS hb_1er_dosaje_mujeres_fertiles,
  SUM(CASE WHEN grupo = 'mujeres_fertiles' THEN hb_2do_dosaje ELSE 0 END) AS hb_2do_dosaje_mujeres_fertiles,
  SUM(CASE WHEN grupo = 'mujeres_fertiles' THEN hb_3er_dosaje ELSE 0 END) AS hb_3er_dosaje_mujeres_fertiles

  FROM base_mensual
  GROUP BY anio, mes,nombre_establecimiento,red,desc_ue,microred,provincia,distrito,cod_2000   ---falta desc_ue,
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

    -- 🔹 BPN
    b.total_bpn_30_59_dias,
    b.sup_1ra_entrega_bpn,
    b.sup_2da_entrega_bpn,
    b.sup_3ra_entrega_bpn,
    b.con_1er_dosaje_hemoglobina_bpn,
    b.con_2do_dosaje_hemoglobina_bpn,
    b.con_3er_dosaje_hemoglobina_bpn,

    -- 🔹 Hemoglobina por grupos
    hbg.hb_1er_dosaje_6_11m,
    hbg.hb_2do_dosaje_6_11m,
    hbg.hb_3er_dosaje_6_11m,
    
    hbg.hb_1er_dosaje_12_23m,
    hbg.hb_2do_dosaje_12_23m,
    hbg.hb_3er_dosaje_12_23m,

    hbg.hb_1er_dosaje_24_35m,
  	hbg.hb_2do_dosaje_24_35m,
  	hbg.hb_3er_dosaje_24_35m,

    hbg.hb_1er_dosaje_36_59m,
  	hbg.hb_2do_dosaje_36_59m,
  	hbg.hb_3er_dosaje_36_59m,
  	
    hbg.hb_1er_dosaje_5_11a,
  	hbg.hb_2do_dosaje_5_11a,
  	hbg.hb_3er_dosaje_5_11a,
  	
  	hbg.hb_1er_dosaje_12_17a_f,
  	hbg.hb_2do_dosaje_12_17a_f,
  	hbg.hb_3er_dosaje_12_17a_f,

    hbg.hb_1er_dosaje_gestantes,
    hbg.hb_2do_dosaje_gestantes,
    hbg.hb_3er_dosaje_gestantes,
    
	hbg.hb_1er_dosaje_puerperas,
 	hbg.hb_2do_dosaje_puerperas,
 	hbg.hb_3er_dosaje_puerperas,

 	hbg.hb_1er_dosaje_mujeres_fertiles,
 	hbg.hb_2do_dosaje_mujeres_fertiles,
  	hbg.hb_3er_dosaje_mujeres_fertiles

  

FROM monitoreo_general m
LEFT JOIN bpn_resumen b ON m.anio=b.anio AND m.mes=b.mes AND m.cod_2000=b.cod_2000
LEFT JOIN hemoglobina_grupos hbg  ON m.anio=hbg.anio AND m.mes=hbg.mes AND m.cod_2000=hbg.cod_2000

ORDER BY m.cod_2000, m.anio, m.mes;


--- GENEREAR REPORTES PARA OCULAR MENTAL  

 
   DROP TABLE IF EXISTS es_ivan.cred2026_3;

    -- 2️⃣ Eliminar tabla temporal si existe


CREATE TABLE es_ivan.cred2026_3 AS

-- ============================================
-- 🔥 BASE MINIMA (SOLO LO NECESARIO)
-- ============================================
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

    (
        EXTRACT(YEAR FROM age(fecha_atencion, fecha_nacimiento)) * 12 +
        EXTRACT(MONTH FROM age(fecha_atencion, fecha_nacimiento))
    )::int AS edad_meses

    FROM es_ivan.tabla_vacunas
    WHERE anio >= 2025
      AND codigo_item IN ('99199.26','99403','99403.01','99436','99381.01','99401.03','99411.01','99431','J00X','P599','J029','99381','99382','99383','C8002','Z001',
      						'99401.05','99401.07','99401.08','99401.09','99401.12','99401.16','99401.24','99401.25','99403.01','99401.03','P929','99211','99211','99199.17','R620','R628','E440',
      						'E669','E6690','E45X','E43X','E344','87177.01','B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664','87178',
      						'B80X','99199.28','C0011','85018.01','P070','P071','P0711','P0712','P0713','P072','P073','U1692','59430','U140','R456','Z720','Z721','Z722','Z133',
      						'H351','H351','H579','H579','Z010','PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527'
							'67228','67229','92390','99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10',
                            '96150.02','67043','99173','D1330','D1286','D1110','D1351')

),

 

		flags_cita AS (
		SELECT
		    id_cita,
		
		/* ===================== FLAGS CLÍNICOS ===================== */
		
		MAX((codigo_item LIKE 'P07%')::int) AS bpn_P07,
		MAX((codigo_item = 'P0712')::int)   AS prematuro_P0712, 
		MAX((codigo_item = 'Z001')::int)    AS rutina_Z001,
		MAX((codigo_item LIKE 'D50%')::int) AS anemia_D50,
		MAX((codigo_item = '99199.17' AND valor_lab = 'TA')::int) AS suple_TA_99199_17,
		MAX((codigo_item = 'C0011')::int)   AS visit_domic_C0011,
		
		MAX((codigo_item = 'C8002' AND valor_lab = '1')::int) AS planAIS_c8002_1,
		MAX((codigo_item = 'C8002' AND valor_lab = 'TA')::int) AS planAIS_TA_c8002,
		
		MAX((codigo_item = 'R620' AND valor_lab = 'PR')::int) AS eval_des_rec_R620,
		MAX((codigo_item = 'R628' AND valor_lab = 'PR')::int) AS eval_rec_r628,
		MAX((codigo_item = 'R628' AND valor_lab = 'PE')::int) AS eval_PE_R628,
		MAX((codigo_item = 'R628' AND valor_lab = 'TE')::int) AS eval_TE_R628,
		
		MAX((codigo_item = 'E440' AND valor_lab = 'TP')::int) AS desn_aguda_TP_E440,
		MAX((codigo_item = 'E440' AND valor_lab = 'PR')::int) AS desn_aguda_PR_E440,
		MAX((codigo_item = 'E440' AND valor_lab = 'PE')::int) AS desn_global_PE_E440,
		MAX((codigo_item = 'E440' AND valor_lab = 'PR')::int) AS desn_global_PR_E440,
		
		MAX((codigo_item = 'E45X' AND valor_lab = 'TE')::int) AS desn_cronica_TE_E45X,
		MAX((codigo_item = 'E45X' AND valor_lab = 'PR')::int) AS desn_cronica_rec_E45X,
		MAX((codigo_item = 'E45X' AND valor_lab = 'TP')::int) AS desn_severa_TP_E43X,
		MAX((codigo_item = 'E45X' AND valor_lab = 'PR')::int) AS desn_severa_rec_E43X,
		
		MAX((codigo_item = 'E6690' AND valor_lab ='TP')::int) AS sobre_peso_TP_E6690,
		MAX((codigo_item = 'E6690' AND valor_lab ='PR')::int) AS sobre_peso_rec_E6690,
		MAX((codigo_item = 'E669' AND valor_lab = 'TP')::int) AS obeso_TP_E669,
		MAX((codigo_item = 'E669' AND valor_lab = 'PR')::int) AS obeso_rec_E669,
		
		MAX((codigo_item = 'E344' AND valor_lab = 'TE')::int) AS talla_Edad_TE_E344,
		MAX((codigo_item = 'E344' AND valor_lab = 'PR')::int) AS talla_Edad_TE_rec_E344,
		
		/* ===================== VIF ===================== */
		
		MAX((codigo_item = 'U140')::int) AS VIF_U140,
		MAX((codigo_item = 'R456')::int) AS VIF_post_R456,
		MAX((codigo_item = 'Z720')::int) AS AD_tabaco_post_Z720,
		MAX((codigo_item = 'Z721')::int) AS AD_alcohol_post_Z721,
		MAX((codigo_item = 'Z722')::int) AS AD_drogas_post_Z722,
		MAX((codigo_item = 'Z133')::int) AS TD_post_Z133,
		
		/* ===================== OCULARES ===================== */
		
		MAX((codigo_item = 'H351' AND valor_lab='1')::int)  AS retino_premat_H351,
		MAX((codigo_item = 'H351' AND valor_lab='RF')::int) AS retino_premat_RF_H351,
		
		MAX((codigo_item = 'H579' AND tipo_diagnostico='P')::int) AS trast_ojo_anexos_H579,
		MAX((codigo_item = 'H579' AND tipo_diagnostico='P' AND valor_lab='RF')::int) AS trast_ojo_anexos_RF_H579,
		
		MAX((codigo_item = 'Z010' AND valor_lab='N' AND tipo_diagnostico='D')::int) AS ex_ojo_vision_N_Z010,
		MAX((codigo_item = 'Z010' AND valor_lab='A' AND tipo_diagnostico='D')::int) AS ex_ojo_vision_A_Z010,
		MAX((codigo_item = 'Z010' AND tipo_diagnostico='D')::int) AS ex_ojo_vision_Z010,
		
		MAX((codigo_item IN ('PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527') AND tipo_diagnostico='P')::int) AS deter_agude_visual_PH,
		
		MAX((codigo_item = '67228' AND tipo_diagnostico='D')::int) AS tto_retinopatia_67228,
		MAX((codigo_item = '67229' AND tipo_diagnostico='D')::int) AS destruc_retinopatia_67229,
		MAX((codigo_item = '92390' AND tipo_diagnostico='D')::int) AS provision_lentes_92390,
		
		/* ===================== TELEMEDICINA ===================== */
		
		MAX((codigo_item = '99499.08')::int) AS teleori_sincro_99499_08,
		MAX((codigo_item = '99499.09')::int) AS teleori_asincr_99499_09,
		MAX((codigo_item IN ('99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10'))::int) AS telemedicina_99499__,
		
		/* ===================== CONDICIONES ===================== */
		
		MAX((fg_tipo = 'CX')::int) AS flg_comorbilidad,
		
		MAX((valor_lab = 'ST')::int) AS flg_st,
		MAX((valor_lab = 'OM')::int) AS flg_OM,
		MAX((valor_lab = 'VIH')::int) AS flg_vih,
		MAX((valor_lab = 'VPH')::int) AS flg_VPH,
		MAX((valor_lab = 'AER')::int) AS flg_AER,
		MAX((valor_lab = 'TER')::int) AS flg_TER,
		MAX((valor_lab = 'FRON')::int) AS flg_FRO,
		MAX((valor_lab = 'RSA')::int) AS flg_RSA,
		
		MAX((valor_lab = 'END')::int) AS flg_END,
		MAX((valor_lab = 'FNI')::int) AS flg_FNI,
		MAX((valor_lab = 'PNP')::int) AS flg_PNP,
		MAX((valor_lab = 'M')::int) AS flg_M,
		MAX((valor_lab = 'EF')::int) AS flg_EF,
		MAX((valor_lab = 'BOM')::int) AS flg_BOM,
		MAX((valor_lab = 'DCI')::int) AS flg_DCI,
		MAX((valor_lab = 'EST')::int) AS flg_EST,
		MAX((valor_lab = 'CR')::int) AS flg_CR,
		
		MAX((valor_lab IN ('IN','PPL'))::int) AS flg_INPE_PPL,
		MAX((valor_lab = 'REH')::int) AS flg_REH,
		MAX((valor_lab IN ('RS','RSA','RMA'))::int) AS flg_HF,
		MAX((valor_lab = 'SR')::int) AS flg_SR,
		MAX((valor_lab = 'DIS')::int) AS flg_DIS,
		
		MAX((valor_lab IN ('TS','HSH','HTS','TTS','PNP','M','BOM','DCI','EST','TRA','PPL','G','P','OTR','VIH','OM'))::int) AS flg_OTR,
		
		MAX((valor_lab IN ('E1','DE1','E2','DE2','E3','DE3','E4','DE4'))::int) AS flg_ENF,
		MAX((id_etnia IN ('56','57','58','59','60'))::int) AS flg_etnia,
		
		MAX((valor_lab = 'AD')::int) AS flg_AD,
		MAX((valor_lab = 'TD')::int) AS flg_TD
		
		FROM base
		GROUP BY id_cita
		),

monitoreo_general AS (
    SELECT 
        anio,
        mes,
        cod_2000,
        red,
		desc_ue,
        microred,
        provincia,
        distrito,
        nombre_establecimiento,
        ---SALUD MENTAL
  ---tamizajes de salud mental
        SUM(CASE WHEN h.codigo_item IN ('96150.02','U140') AND h.tip_edad='A' AND h.edad BETWEEN 1 AND 2 THEN 1 ELSE 0 END) AS tamizaje_viol_1_2a,
		SUM(CASE WHEN h.codigo_item IN ('96150.02','U140') AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 5 THEN 1 ELSE 0 END) AS tamizaje_viol_3_5a,
		SUM(CASE WHEN h.codigo_item IN ('96150.02','U140') AND h.tip_edad='A' AND h.edad BETWEEN 6 AND 9 THEN 1 ELSE 0 END) AS tamizaje_viol_6_9a,
		SUM(CASE WHEN h.codigo_item IN ('96150.02','U140') AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS tamizaje_viol_10_11a,

		SUM(CASE WHEN h.codigo_item='96150.02' AND h.valor_lab='AD' AND h.tip_edad='A' AND h.edad BETWEEN 6 AND 9 THEN 1 ELSE 0 END) AS tamizaje_ad_6_9a,
		SUM(CASE WHEN h.codigo_item='96150.02' AND h.valor_lab='AD' AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS tamizaje_ad_10_11a,
		SUM(CASE WHEN h.codigo_item='96150.03' AND h.valor_lab='TD' AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS tamizaje_td_10_11a,
		SUM(CASE WHEN h.codigo_item='96150.06' AND h.tip_edad='A' AND h.edad = 2 THEN 1 ELSE 0 END) AS tamizaje_nd_2a,
		SUM(CASE WHEN h.codigo_item='96150.08' AND h.tip_edad='A' AND h.edad BETWEEN 6 AND 9 THEN 1 ELSE 0 END) AS tamizaje_tm_6_9a,
		SUM(CASE WHEN h.codigo_item='96150.08' AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS tamizaje_tm_10_11a,

		---tamizajes de salud mental positivos
		
		SUM(CASE WHEN h.codigo_item='96150.02' AND f.VIF_post_R456 = 1 AND h.tip_edad='A' AND h.edad BETWEEN 1 AND 2 THEN 1 ELSE 0 END) AS tamizaje_viol_posit_1_2a,
		SUM(CASE WHEN h.codigo_item='96150.02' AND f.VIF_post_R456 = 1 AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 5 THEN 1 ELSE 0 END) AS tamizaje_viol_posit_3_5a,
		SUM(CASE WHEN h.codigo_item='96150.02' AND f.VIF_post_R456 = 1 AND h.tip_edad='A' AND h.edad BETWEEN 6 AND 9 THEN 1 ELSE 0 END) AS tamizaje_viol_posit_6_9a,
		SUM(CASE WHEN h.codigo_item='96150.02' AND f.VIF_post_R456 = 1 AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS tamizaje_viol_posit_10_11a,
		
		SUM(CASE WHEN h.codigo_item='96150.02' AND f.AD_tabaco_post_Z720 = 1 AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS tamizaje_ad_tabaco_posit_10_11a,
		SUM(CASE WHEN h.codigo_item='96150.02' AND f.AD_alcohol_post_Z721 = 1 AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS tamizaje_ad_alcohol_posit_10_11a,
		SUM(CASE WHEN h.codigo_item='96150.02' AND f.AD_drogas_post_Z722 = 1 AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS tamizaje_ad_drogas_posit_10_11a,
		SUM(CASE WHEN h.codigo_item='96150.02' AND f.TD_post_Z133 = 1 AND h.tip_edad='A' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS tamizaje_td_posit_10_11a,
		
		----*********************
		-- SALUD OCULAR
		--*********************
		--Tamizaje de recien nacidos con factores de riesgo
		
		SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item IN ('92226','92250') AND h.valor_lab='1' AND tipo_diagnostico='P' AND h.tip_edad='D' THEN 1 ELSE 0 END) AS o_tamrn_fr_n_0_29d,
		SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item IN ('92226','92250') AND h.valor_lab='1' AND tipo_diagnostico='P' AND h.tip_edad='M' AND h.edad<=6 THEN 1 ELSE 0 END) AS o_tamrn_fr_n_6m,
		SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item IN ('92226','92250') AND h.valor_lab='1' AND tipo_diagnostico='P' AND h.edad_meses BETWEEN 7 AND 11 THEN 1 ELSE 0 END) AS o_tamrn_fr_n_7m11m,
		SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item IN ('92226','92250') AND h.valor_lab='1' AND tipo_diagnostico='P' AND h.tip_edad='A' AND h.edad BETWEEN 1 AND 3 THEN 1 ELSE 0 END) AS o_tamrn_fr_n_1_3a,
		SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item IN ('92226','92250') AND h.valor_lab='1' AND tipo_diagnostico='P' AND (h.tip_edad='D' OR h.edad_meses BETWEEN 0 AND 11 OR (h.tip_edad='A' AND h.edad<=3)) THEN 1 ELSE 0 END) AS o_tamrn_fr_n_total,
		
		--SEGUIMIENTO de recien nacidos con factores de riesgo
		
		SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item IN ('92226','92250') AND tipo_diagnostico='P' AND h.tip_edad='D' THEN 1 ELSE 0 END) AS o_tamrn_fr_s_0_29d,
		SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item IN ('92226','92250') AND tipo_diagnostico='P' AND h.tip_edad='M' AND h.edad<=6 THEN 1 ELSE 0 END) AS o_tamrn_fr_s_6m,
		SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item IN ('92226','92250') AND tipo_diagnostico='P' AND h.edad_meses BETWEEN 7 AND 11 THEN 1 ELSE 0 END) AS o_tamrn_fr_s_7m11m,
		SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item IN ('92226','92250') AND tipo_diagnostico='P' AND h.tip_edad='A' AND h.edad BETWEEN 1 AND 3 THEN 1 ELSE 0 END) AS o_tamrn_fr_s_1_3a,
		SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item IN ('92226','92250') AND tipo_diagnostico='P' AND (h.tip_edad='D' OR h.edad_meses BETWEEN 7 AND 11 OR (h.tip_edad='A' AND h.edad<=3)) THEN 1 ELSE 0 END) AS o_tamrn_fr_s_total,
		
		--Referencia de RN con factores de riesgo de ROP
		
		SUM(CASE WHEN f.retino_premat_RF_H351=1 AND tipo_diagnostico='P' AND h.tip_edad='D' THEN 1 ELSE 0 END) AS O_TamRN_FR_R_0_29d,
		SUM(CASE WHEN f.retino_premat_RF_H351=1 AND tipo_diagnostico='P' AND h.tip_edad='M' AND h.edad<=6 THEN 1 ELSE 0 END) AS O_TamRN_FR_R_6m,
		SUM(CASE WHEN f.retino_premat_RF_H351=1 AND tipo_diagnostico='P' AND h.edad_meses BETWEEN 7 AND 11 THEN 1 ELSE 0 END) AS O_TamRN_FR_R_7m11m,
		SUM(CASE WHEN f.retino_premat_RF_H351=1 AND tipo_diagnostico='P' AND h.tip_edad='A' AND h.edad BETWEEN 1 AND 3 THEN 1 ELSE 0 END) AS O_TamRN_FR_R_1_3a,
		SUM(CASE WHEN f.retino_premat_RF_H351=1 AND tipo_diagnostico='P' AND (h.tip_edad='D' OR h.edad_meses BETWEEN 7 AND 11 OR (h.tip_edad='A' AND h.edad<=3)) THEN 1 ELSE 0 END) AS O_TamRN_FR_R_Total,
		
		--Diagnóstico de retinopatía (DISTINCT se mantiene)
		SUM(CASE WHEN f.retino_premat_RF_H351=1 AND tipo_diagnostico='D' AND h.tip_edad='D' THEN 1 ELSE 0 END) AS O_Dx_retinoPrema_C_0_29d,
		SUM(CASE  WHEN f.retino_premat_RF_H351=1 AND tipo_diagnostico='D' AND h.tip_edad='M' AND h.edad<=6 THEN 1 ELSE 0 END) AS O_Dx_retinoPrema_C_6m,
		SUM(CASE WHEN f.retino_premat_RF_H351=1 AND tipo_diagnostico='D' AND h.edad_meses BETWEEN 7 AND 11 THEN 1 ELSE 0 END) AS O_Dx_retinoPrema_C_7m11m,
		SUM(CASE WHEN f.retino_premat_RF_H351=1 AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 1 AND 3 THEN 1 ELSE 0 END) AS O_Dx_retinoPrema_C_1_3a,
		SUM(CASE WHEN f.retino_premat_RF_H351=1 AND tipo_diagnostico='D' AND (h.tip_edad='D' OR h.edad_meses BETWEEN 0 AND 11 OR (h.tip_edad='A' AND h.edad<=3)) THEN 1 ELSE 0 END) AS O_Dx_retinoPrema_C_Total,
		
		--- Tratamiento con antiangiogénico
		
		SUM(CASE  WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND h.tip_edad='D' THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_A_0_29d,
		SUM(CASE WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND h.tip_edad='M' AND h.edad<=6  THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_A_6m,
		
		SUM(CASE WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND h.edad_meses BETWEEN 7 AND 11  THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_A_7m11m,
		SUM(CASE  WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND h.tip_edad='A' AND h.edad BETWEEN 1 AND 3 THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_A_1_3a,
		SUM(CASE WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND (h.tip_edad='D' OR h.edad_meses BETWEEN 0 AND 11 OR (h.tip_edad='A' AND h.edad<=3))  THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_A_Total,
		
		--- Tratamiento con laser    PARA REVISAR URGENTE
		  
		  SUM(CASE WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND f.destruc_retinopatia_67229=1 AND h.tip_edad='D' THEN 1 ELSE 0 END) as O_tto_retinoPrema_CT_l_0_29d,
		  SUM(CASE  WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND f.destruc_retinopatia_67229=1 AND h.tip_edad='M' AND h.edad<=6 THEN 1 ELSE 0 END) as O_tto_retinoPrema_CT_l_6m,
		  SUM(CASE WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND f.destruc_retinopatia_67229=1 AND h.edad_meses BETWEEN 7 AND 11 THEN 1 ELSE 0 END)  as O_tto_retinoPrema_CT_l_7m11m,
		  SUM(CASE WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND f.destruc_retinopatia_67229=1 AND h.tip_edad='A' AND h.edad BETWEEN 1 AND 3  THEN 1 ELSE 0 END) as O_tto_retinoPrema_CT_l_1_3a,
		  SUM(CASE WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND f.destruc_retinopatia_67229=1 AND (h.tip_edad='D' OR h.edad_meses BETWEEN 0 AND 11 OR (h.tip_edad='A' AND h.edad<=3)) THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_l_Total,
  

		---🔹 Tratamiento combinado (láser + antiangiogénico)
		
		SUM(CASE WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND f.destruc_retinopatia_67229=1 AND h.tip_edad='D' THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_LM_0_29d,
		SUM(CASE  WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND f.destruc_retinopatia_67229=1 AND h.tip_edad='M' AND h.edad<=6 THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_LM_6m,
		SUM(CASE WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND f.destruc_retinopatia_67229=1 AND h.edad_meses BETWEEN 7 AND 11 THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_LM_7m11m,
		SUM(CASE WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND f.destruc_retinopatia_67229=1 AND h.tip_edad='A' AND h.edad BETWEEN 1 AND 3  THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_LM_1_3a,
		SUM(CASE WHEN f.retino_premat_H351=1 AND tipo_diagnostico='D' AND f.tto_retinopatia_67228=1 AND f.destruc_retinopatia_67229=1 AND (h.tip_edad='D' OR h.edad_meses BETWEEN 0 AND 11 OR (h.tip_edad='A' AND h.edad<=3)) THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_LM_Total,

		
		
		
		
		--EXAMEN DEL OJO Y VISIÓN – ANORMAL
		SUM(CASE 
		    WHEN f.ex_ojo_vision_A_Z010=1 AND h.tip_edad='M'
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_A_0_11m,
		
		SUM(CASE 
		    WHEN f.ex_ojo_vision_A_Z010=1 AND h.tip_edad='A' AND h.edad=1
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_A_1a,
		
		SUM(CASE 
		    WHEN f.ex_ojo_vision_A_Z010=1 AND h.tip_edad='A' AND h.edad=2
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_A_2a,
		
		SUM(CASE 
		    WHEN f.ex_ojo_vision_A_Z010=1 AND h.tip_edad='A' AND h.edad=3
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_A_3a,
		
		SUM(CASE 
		    WHEN f.ex_ojo_vision_A_Z010=1 AND h.tip_edad='A' AND h.edad=4
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_A_4a,
		
		SUM(CASE 
		    WHEN f.ex_ojo_vision_A_Z010=1 AND h.tip_edad='A' AND h.edad=5
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_A_5a,
		
		SUM(CASE 
		    WHEN f.ex_ojo_vision_A_Z010=1 
		     AND (h.tip_edad='M' OR (h.tip_edad='A' AND h.edad<=5))
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_A_0_5a_Total,
		
		---🔹 EVALUACIÓN DE SOSPECHA DE ALTERACIONES OCULARES
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_H579=1 AND f.ex_ojo_vision_Z010=1 AND h.tip_edad='M'
		    THEN 1 ELSE 0 END) AS O_eva_Ojo_Vis_N_0_11m,
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_H579=1 AND f.ex_ojo_vision_Z010=1 AND h.tip_edad='A' AND h.edad=1
		    THEN 1 ELSE 0 END) AS O_eva_Ojo_Vis_N_1a,
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_H579=1 AND f.ex_ojo_vision_Z010=1 AND h.tip_edad='A' AND h.edad=2
		    THEN 1 ELSE 0 END) AS O_eva_Ojo_Vis_N_2a,
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_H579=1 AND f.ex_ojo_vision_Z010=1 AND h.tip_edad='A' AND h.edad=3
		    THEN 1 ELSE 0 END) AS O_eva_Ojo_Vis_N_3a,
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_H579=1 AND f.ex_ojo_vision_Z010=1 AND h.tip_edad='A' AND h.edad=4
		    THEN 1 ELSE 0 END) AS O_eva_Ojo_Vis_N_4a,
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_H579=1 AND f.ex_ojo_vision_Z010=1 AND h.tip_edad='A' AND h.edad=5
		    THEN 1 ELSE 0 END) AS O_eva_Ojo_Vis_N_5a,
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_H579=1 AND f.ex_ojo_vision_Z010=1 
		     AND (h.tip_edad='M' OR (h.tip_edad='A' AND h.edad<=5))
		    THEN 1 ELSE 0 END) AS O_eva_Ojo_Vis_N_0_5a_Total,
		
		---🔹 REFERENCIA POR TRASTORNO DEL OJO
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_RF_H579=1 AND h.tip_edad='M'
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_RF_0_11m,
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_RF_H579=1 AND h.tip_edad='A' AND h.edad=1
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_RF_1a,
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_RF_H579=1 AND h.tip_edad='A' AND h.edad=2
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_RF_2a,
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_RF_H579=1 AND h.tip_edad='A' AND h.edad=3
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_RF_3a,
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_RF_H579=1 AND h.tip_edad='A' AND h.edad=4
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_RF_4a,
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_RF_H579=1 AND h.tip_edad='A' AND h.edad=5
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_RF_5a,
		
		SUM(CASE 
		    WHEN f.trast_ojo_anexos_RF_H579=1 
		     AND (h.tip_edad='M' OR (h.tip_edad='A' AND h.edad<=5))
		    THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_RF_0_5a_Total,

			--TRATAMIENTO INTRAVÍTREO
			SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item='67043' AND tipo_diagnostico='D' AND h.tip_edad='D' THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_I_0_29d,
			SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item='67043' AND tipo_diagnostico='D' AND h.tip_edad='M' AND h.edad<=6 THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_I_6m,
			SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item='67043' AND tipo_diagnostico='D' AND h.edad_meses BETWEEN 7 AND 11 THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_I_7m11m,
			SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item='67043' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 1 AND 3 THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_I_1_3a,
			SUM(CASE WHEN f.retino_premat_H351=1 AND h.codigo_item='67043' AND tipo_diagnostico='D' AND (h.tip_edad='D' OR h.edad_meses BETWEEN 0 AND 11 OR (h.tip_edad='A' AND h.edad<=3)) THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_I_Total,
			

           

			--🔹 REFERENCIA CON ROP
			SUM(CASE WHEN f.retino_premat_RF_H351=1 AND h.tip_edad='D' THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_R_0_29d,
			SUM(CASE WHEN f.retino_premat_RF_H351=1 AND h.tip_edad='M' AND h.edad<=6 THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_R_6m,
			SUM(CASE WHEN f.retino_premat_RF_H351=1 AND h.edad_meses BETWEEN 7 AND 11 THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_R_7m11m,
			SUM(CASE WHEN f.retino_premat_RF_H351=1 AND h.tip_edad='A' AND h.edad BETWEEN 1 AND 3 THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_R_1_3a,
			SUM(CASE WHEN f.retino_premat_RF_H351=1 AND (h.tip_edad='D' OR h.edad_meses BETWEEN 0 AND 11 OR (h.tip_edad='A' AND h.edad<=3)) THEN 1 ELSE 0 END) AS O_tto_retinoPrema_CT_R_Total,
			
			---🔹 EXAMEN OJO Y VISIÓN NORMAL
			
			SUM(CASE WHEN f.ex_ojo_vision_N_Z010=1 AND h.tip_edad='M' THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_N_0_11m,
			SUM(CASE WHEN f.ex_ojo_vision_N_Z010=1 AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_N_1a,
			SUM(CASE WHEN f.ex_ojo_vision_N_Z010=1 AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_N_2a,
			SUM(CASE WHEN f.ex_ojo_vision_N_Z010=1 AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_N_3a,
			SUM(CASE WHEN f.ex_ojo_vision_N_Z010=1 AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_N_4a,
			SUM(CASE WHEN f.ex_ojo_vision_N_Z010=1 AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_N_5a,
			SUM(CASE WHEN f.ex_ojo_vision_N_Z010=1 AND (h.tip_edad='M' OR (h.tip_edad='A' AND h.edad<=5)) THEN 1 ELSE 0 END) AS O_Ex_Ojo_Vis_N_0_5a_Total,
			
			---🔹 TAMIZAJE AGUDEZA VISUAL
			
			SUM(CASE WHEN h.codigo_item='99173' AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 4 THEN 1 ELSE 0 END) AS O_Determ_Agudeza_Visual_3_4a,
			SUM(CASE WHEN h.codigo_item='99173' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 7 THEN 1 ELSE 0 END) AS O_Determ_Agudeza_Visual_5_7a,
			SUM(CASE WHEN h.codigo_item='99173' AND h.tip_edad='A' AND h.edad BETWEEN 8 AND 11 THEN 1 ELSE 0 END) AS O_Determ_Agudeza_Visual_8_11a,
			SUM(CASE WHEN h.codigo_item='99173' AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 11 THEN 1 ELSE 0 END) AS O_Determ_Agudeza_Visual_Total,
			
             

			---🔹 EVALUACIÓN ERRORES REFRACTIVOS
			
			SUM(CASE WHEN f.deter_agude_visual_PH=1 AND h.codigo_item IN ('H538','H509','H530','H559','H179','H029','H028','H527') AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 4 THEN 1 ELSE 0 END) AS O_Determ_Agudeza_Visual_eva_3_4a,
			SUM(CASE WHEN f.deter_agude_visual_PH=1 AND h.codigo_item IN ('H538','H509','H530','H559','H179','H029','H028','H527') AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 7 THEN 1 ELSE 0 END) AS O_Determ_Agudeza_Visual_eva_5_7a,
			SUM(CASE WHEN f.deter_agude_visual_PH=1 AND h.codigo_item IN ('H538','H509','H530','H559','H179','H029','H028','H527') AND h.tip_edad='A' AND h.edad BETWEEN 8 AND 11 THEN 1 ELSE 0 END) AS O_Determ_Agudeza_Visual_eva_8_11a,
			SUM(CASE WHEN f.deter_agude_visual_PH=1 AND h.codigo_item IN ('H538','H509','H530','H559','H179','H029','H028','H527') AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 11 THEN 1 ELSE 0 END) AS O_Determ_Agudeza_Visual_eva_Total,
			
			---🔹 REFERENCIAS ERRORES REFRACTIVOS
				
			SUM(CASE WHEN h.codigo_item='H527' AND h.valor_lab='RF' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 4 THEN 1 ELSE 0 END) AS O_Determ_Agudeza_Visual_ref_3_4a,
			SUM(CASE WHEN h.codigo_item='H527' AND h.valor_lab='RF' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 7 THEN 1 ELSE 0 END) AS O_Determ_Agudeza_Visual_ref_5_7a,
			SUM(CASE WHEN h.codigo_item='H527' AND h.valor_lab='RF' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 8 AND 11 THEN 1 ELSE 0 END) AS O_Determ_Agudeza_Visual_ref_8_11a,
			SUM(CASE WHEN h.codigo_item='H527' AND h.valor_lab='RF' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 11 THEN 1 ELSE 0 END) AS O_Determ_Agudeza_Visual_ref_Total,
			
			---🔹 DIAGNÓSTICO HIPERMETROPÍA
				
			SUM(CASE WHEN h.codigo_item='H520' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 4 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Hip_3_4a,
			SUM(CASE WHEN h.codigo_item='H520' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 7 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Hip_5_7a,
			SUM(CASE WHEN h.codigo_item='H520' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 8 AND 11 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Hip_8_11a,
			SUM(CASE WHEN h.codigo_item='H520' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 11 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Hip_Total,

			--🔹 DIAGNÓSTICO MIOPÍA (H521)
			SUM(CASE WHEN h.codigo_item='H521' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 4 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Mio_3_4a,
			SUM(CASE WHEN h.codigo_item='H521' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 7 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Mio_5_7a,
			SUM(CASE WHEN h.codigo_item='H521' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 8 AND 11 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Mio_8_11a,
			SUM(CASE WHEN h.codigo_item='H521' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 11 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Mio_Total,
			
			--🔹 DIAGNÓSTICO ASTIGMATISMO (H522)
			
			SUM(CASE WHEN h.codigo_item='H522' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 4 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Ast_3_4a,
			SUM(CASE WHEN h.codigo_item='H522' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 7 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Ast_5_7a,
			SUM(CASE WHEN h.codigo_item='H522' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 8 AND 11 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Ast_8_11a,
			SUM(CASE WHEN h.codigo_item='H522' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 11 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Ast_Total,
			
			--🔹 DIAGNÓSTICO ANISOMETROPÍA (H523)
			
			SUM(CASE WHEN h.codigo_item='H523' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 4 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Ani_3_4a,
			SUM(CASE WHEN h.codigo_item='H523' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 7 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Ani_5_7a,
			SUM(CASE WHEN h.codigo_item='H523' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 8 AND 11 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Ani_8_11a,
			SUM(CASE WHEN h.codigo_item='H523' AND tipo_diagnostico='D' AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 11 THEN 1 ELSE 0 END) AS O_Dx_ErrR_Ani_Total,
			
			---🔹 TRATAMIENTO – PROVISIÓN DE ANTEOJOS
			
			SUM(CASE WHEN h.codigo_item IN ('H520','H521','H522','H523') 
			         AND f.provision_lentes_92390=1 
			         AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 4 
                     AND tipo_diagnostico='R'
			    THEN 1 ELSE 0 END) AS O_tto_Prov_anteo_3_4a,
			
			SUM(CASE WHEN h.codigo_item IN ('H520','H521','H522','H523') 
			         AND f.provision_lentes_92390=1 
			         AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 7 
                     AND tipo_diagnostico='R'
			    THEN 1 ELSE 0 END) AS O_tto_Prov_anteo_5_7a,
			
			SUM(CASE WHEN h.codigo_item IN ('H520','H521','H522','H523') 
			         AND f.provision_lentes_92390=1 
			         AND h.tip_edad='A' AND h.edad BETWEEN 8 AND 11 
                     AND tipo_diagnostico='R'
			    THEN 1 ELSE 0 END) AS O_tto_Prov_anteo_8_11a,

			
			SUM(CASE WHEN h.codigo_item IN ('H520','H521','H522','H523')
			         AND f.provision_lentes_92390=1 
			         AND h.tip_edad='A' AND h.edad BETWEEN 3 AND 11 
                     AND tipo_diagnostico='R'
			    THEN 1 ELSE 0 END) AS O_tto_Prov_anteo_Total,

			
			---SALUD BUCAL – IHO INICIAL
			

			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='D' AND h.edad BETWEEN 0 AND 28 
			    THEN 1 ELSE 0 END) AS B_IHO_I_0_28d,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='M' AND h.edad BETWEEN 1 AND 5 
			    THEN 1 ELSE 0 END) AS B_IHO_I_29_5m,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='M' AND h.edad BETWEEN 6 AND 11 
			    THEN 1 ELSE 0 END) AS B_IHO_I_6_11m,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='A' AND h.edad=1 
			    THEN 1 ELSE 0 END) AS B_IHO_I_1a,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='A' AND h.edad=2 
			    THEN 1 ELSE 0 END) AS B_IHO_I_2a,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='A' AND h.edad=3 
			    THEN 1 ELSE 0 END) AS B_IHO_I_3a,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='A' AND h.edad=4 
			    THEN 1 ELSE 0 END) AS B_IHO_I_4a,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 
			    THEN 1 ELSE 0 END) AS B_IHO_5_11a,
			
			---🔹 ASESORÍA NUTRICIONAL (ANCED)
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='D' AND h.edad BETWEEN 0 AND 28 
			    THEN 1 ELSE 0 END) AS B_ANCED_I_0_28d,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='M' AND h.edad BETWEEN 1 AND 5 
			    THEN 1 ELSE 0 END) AS B_ANCED_I_29_5m,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='M' AND h.edad BETWEEN 6 AND 11 
			    THEN 1 ELSE 0 END) AS B_ANCED_I_6_11m,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='A' AND h.edad=1 
			    THEN 1 ELSE 0 END) AS B_ANCED_I_1a,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='A' AND h.edad=2 
			    THEN 1 ELSE 0 END) AS B_ANCED_I_2a,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='A' AND h.edad=3 
			    THEN 1 ELSE 0 END) AS B_ANCED_I_3a,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='A' AND h.edad=4 
			    THEN 1 ELSE 0 END) AS B_ANCED_I_4a,
			
			SUM(CASE WHEN h.codigo_item='D1330' AND h.valor_lab='1' AND tipo_diagnostico='D'
			         AND f.teleori_sincro_99499_08=0 AND f.teleori_asincr_99499_09=0
			         AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 
			    THEN 1 ELSE 0 END) AS B_ANCED_I_5_11a,



			---APLICACIÓN DE BARNIZ FLUORADO – INICIAN TTO
			SUM(CASE WHEN h.codigo_item = 'D1286' 
			         AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'D' 
			         AND h.edad BETWEEN 0 AND 28
			    THEN 1 ELSE 0 END) AS B_ABF_I_0_28d,
			
			SUM(CASE WHEN h.codigo_item = 'D1286' 
			         AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'M' 
			         AND h.edad BETWEEN 1 AND 5
			    THEN 1 ELSE 0 END) AS B_ABF_I_29_5m,
			
			SUM(CASE WHEN h.codigo_item = 'D1286' 
			         AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'M' 
			         AND h.edad BETWEEN 6 AND 11
			    THEN 1 ELSE 0 END) AS B_ABF_I_6_11m,
			
			SUM(CASE WHEN h.codigo_item = 'D1286' 
			         AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' 
			         AND h.edad = 1
			    THEN 1 ELSE 0 END) AS B_ABF_I_1a,
			
			SUM(CASE WHEN h.codigo_item = 'D1286' 
			         AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' 
			         AND h.edad = 2
			    THEN 1 ELSE 0 END) AS B_ABF_I_2a,
			
			SUM(CASE WHEN h.codigo_item = 'D1286' 
			         AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' 
			         AND h.edad = 3
			    THEN 1 ELSE 0 END) AS B_ABF_I_3a,
			
			SUM(CASE WHEN h.codigo_item = 'D1286' 
			         AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' 
			         AND h.edad = 4
			    THEN 1 ELSE 0 END) AS B_ABF_I_4a,
			
			SUM(CASE WHEN h.codigo_item = 'D1286' 
			         AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' 
			         AND h.edad BETWEEN 5 AND 11
			    THEN 1 ELSE 0 END) AS B_ABF_I_5_11a,


			
				
			--PROFILAXIS DENTAL – INICIAN TTO
			SUM(CASE WHEN h.codigo_item = 'D1110' AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'D' AND h.edad BETWEEN 0 AND 28 
			    THEN 1 ELSE 0 END) AS B_PD_I_0_28d,
			
			SUM(CASE WHEN h.codigo_item = 'D1110' AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'M' AND h.edad BETWEEN 1 AND 5 
			    THEN 1 ELSE 0 END) AS B_PD_I_29_5m,
		
			SUM(CASE WHEN h.codigo_item = 'D1110' AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'M' AND h.edad BETWEEN 6 AND 11 
			    THEN 1 ELSE 0 END) AS B_PD_I_6_11m,
			
			SUM(CASE WHEN h.codigo_item = 'D1110' AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' AND h.edad = 1 
			    THEN 1 ELSE 0 END) AS B_PD_I_1a,
			
			SUM(CASE WHEN h.codigo_item = 'D1110' AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' AND h.edad = 2 
			    THEN 1 ELSE 0 END) AS B_PD_I_2a,
			
			SUM(CASE WHEN h.codigo_item = 'D1110' AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' AND h.edad = 3 
			    THEN 1 ELSE 0 END) AS B_PD_I_3a,
			
			SUM(CASE WHEN h.codigo_item = 'D1110' AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' AND h.edad = 4 
			    THEN 1 ELSE 0 END) AS B_PD_I_4a,
			
			SUM(CASE WHEN h.codigo_item = 'D1110' AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 
			    THEN 1 ELSE 0 END) AS B_PD_I_5_11a,

       
			---🔹 APLICACIÓN DE SELLANTES
			
			SUM(CASE WHEN h.codigo_item = 'D1351' AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' AND h.edad = 2 
			    THEN 1 ELSE 0 END) AS B_ASELN_CT_2a,
			
			SUM(CASE WHEN h.codigo_item = 'D1351' AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' AND h.edad = 3 
			    THEN 1 ELSE 0 END) AS B_ASELN_CT_3a,
			
			SUM(CASE WHEN h.codigo_item = 'D1351' AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' AND h.edad = 4 
			    THEN 1 ELSE 0 END) AS B_ASELN_CT_4a,
			
			SUM(CASE WHEN h.codigo_item = 'D1351' AND h.valor_lab = '1' 
			         AND f.telemedicina_99499__ = 0 
			         AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 
			    THEN 1 ELSE 0 END) AS B_ASELN_CT_5_11a



			FROM base h
			LEFT JOIN flags_cita f ON h.id_cita = f.id_cita
			
			GROUP BY 
			    h.anio, h.mes, h.cod_2000, h.red,h.desc_ue,h.microred,h.provincia,h.distrito, h.nombre_establecimiento
			
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

			---tamizajes de salud mental
			  	m.Tamizaje_viol_1_2a,
			  	m.Tamizaje_viol_3_5a,
			  	m.Tamizaje_viol_6_9a,
			   	m.Tamizaje_viol_10_11a, 
			 	m.Tamizaje_ad_6_9a,
			 	m.Tamizaje_ad_10_11a,
			 	m.Tamizaje_td_10_11a,
			 	m.Tamizaje_ND_2a,
			 	m.Tamizaje_tm_6_9a,
			 	m.Tamizaje_tm_10_11a,
			  
			  ---tamizajes de salud mental positivos
			  
			  	m.Tamizaje_viol_posit_1_2a,
			 	m.Tamizaje_viol_posit_3_5a,
			 	m.Tamizaje_viol_posit_6_9a,
			 	m.Tamizaje_viol_posit_10_11a, 
				m.Tamizaje_ad_tabaco_posit_10_11a,
			  	m.Tamizaje_ad_alcohol_posit_10_11a,
			  	m.Tamizaje_ad_drogas_posit_10_11a,
			  	m.Tamizaje_td_posit_10_11a,
			 -- sum(case when codigo like '%D96150.06%' and tip_edad='A' and (edad=2 ) then 1 else 0 end) as Tamizaje_ND_+_2a
			 -- sum(case when codigo like '%D96150.08%' and tip_edad='A' and (edad>=6 and edad_<=9) then 1 else 0 end) as Tamizaje_tm_+_6_9a,
			 --sum(case when codigo like '%D96150.08%'  and tip_edad='A' and (edad>=10 and edad<=11) then 1 else 0 end) as Tamizaje_tm_+_10_11a,
			  
			----*********************
			-- SALUD OCULAR
			--*********************
			--Tamizaje de recien nacidos con factores de riesgo
			  
				m.O_TamRN_FR_N_0_29d,
				m.O_TamRN_FR_N_6m,
				m.O_TamRN_FR_N_7m11m,
				m.O_TamRN_FR_N_1_3a,
				m.O_TamRN_FR_N_Total,
			
			  --SEGUIMIENTO de recien nacidos con factores de riesgo
			  
			 	m.O_TamRN_FR_S_0_29d,
			 	m.O_TamRN_FR_S_6m,
			 	m.O_TamRN_FR_S_7m11m,
			 	m.O_TamRN_FR_S_1_3a,
			 	m.O_TamRN_FR_S_Total,
			  
			 ---- Referencia de RN con factores de riesgo de ROP
			  
				m.O_TamRN_FR_R_0_29d,
				m.O_TamRN_FR_R_6m,
				m.O_TamRN_FR_R_7m11m,
				m.O_TamRN_FR_R_1_3a,
				m.O_TamRN_FR_R_Total,
			  
			  ---Diagnostico de casos de retinopatía de la prematuridad
			--CASOS
			  
			 	m.O_Dx_retinoPrema_C_0_29d,
			 	m.O_Dx_retinoPrema_C_6m,
			 	m.O_Dx_retinoPrema_C_7m11m,
			 	m.O_Dx_retinoPrema_C_1_3a,
			 	m.O_Dx_retinoPrema_C_Total,
			  
			--- Tratamiento con laser
			  
				m.O_tto_retinoPrema_CT_l_0_29d,
				m.O_tto_retinoPrema_CT_l_6m,
				m.O_tto_retinoPrema_CT_l_7m11m,
				m.O_tto_retinoPrema_CT_l_1_3a,
				m.O_tto_retinoPrema_CT_l_Total,
			  
			  ---Tratamiento con antiangiogenico
				m.O_tto_retinoPrema_CT_A_0_29d,
				m.O_tto_retinoPrema_CT_A_6m,
				m.O_tto_retinoPrema_CT_A_7m11m,
				m.O_tto_retinoPrema_CT_A_1_3a,
				m.O_tto_retinoPrema_CT_A_Total,
			
			
			 
			    ---Tratamiento con laser masantiangiogenico
				m.O_tto_retinoPrema_CT_LM_0_29d, 
				m.O_tto_retinoPrema_CT_LM_6m,
				m.O_tto_retinoPrema_CT_LM_7m11m,
				m.O_tto_retinoPrema_CT_LM_1_3a,
				m.O_tto_retinoPrema_CT_LM_Total,
			  
			  
			  ---Tratamiento con INTRAVITREO
			  
				m.O_tto_retinoPrema_CT_I_0_29d,
				m.O_tto_retinoPrema_CT_I_6m,
				m.O_tto_retinoPrema_CT_I_7m11m,
				m.O_tto_retinoPrema_CT_I_1_3a,
				m.O_tto_retinoPrema_CT_I_Total,
			
			  
			   ---Examen del  ojo y la vision
			  --normal
				m.O_Ex_Ojo_Vis_N_0_11m,
				m.O_Ex_Ojo_Vis_N_1a,
				m.O_Ex_Ojo_Vis_N_2a,
				m.O_Ex_Ojo_Vis_N_3a,
				m.O_Ex_Ojo_Vis_N_4a,
				m.O_Ex_Ojo_Vis_N_5a,
				m.O_Ex_Ojo_Vis_N_0_5a_Total,
			  ---ANORMAL
				m.O_Ex_Ojo_Vis_A_0_11m,
				m.O_Ex_Ojo_Vis_A_1a,
				m.O_Ex_Ojo_Vis_A_2a,
				m.O_Ex_Ojo_Vis_A_3a,
				m.O_Ex_Ojo_Vis_A_4a,
				m.O_Ex_Ojo_Vis_A_5a,
				m.O_Ex_Ojo_Vis_A_0_5a_Total,
			
			--Evaluación de sospecha de alteraciones oculares
			  
				m.O_eva_Ojo_Vis_N_0_11m,
				m.O_eva_Ojo_Vis_N_1a,
				m.O_eva_Ojo_Vis_N_2a,
				m.O_eva_Ojo_Vis_N_3a,
				m.O_eva_Ojo_Vis_N_4a,
				m.O_eva_Ojo_Vis_N_5a,
				m.O_eva_Ojo_Vis_N_0_5a_Total,
			  
			  
			  --Referncia por Medicos por Transtono del Ojo en menores de 3 años
			  
			 	m.O_Ex_Ojo_Vis_RF_0_11m,
			 	m.O_Ex_Ojo_Vis_RF_1a,
			 	m.O_Ex_Ojo_Vis_RF_2a,
			    m.O_Ex_Ojo_Vis_RF_3a,
			 	m.O_Ex_Ojo_Vis_RF_4a,
				m.O_Ex_Ojo_Vis_RF_5a,
			 	m.O_Ex_Ojo_Vis_RF_0_5a_Total,
			
			
			--TAMIZAJE Y DETECCIÓN DE ERRORES REFRACTIVOS EN NIÑOS
			--Tamizaje y Detección de Errores Refractivos en Niños de 3 a 11 años
			--Tamizaje de la Agudeza Visual en Niños de 3 a 11 años
			  
				m.O_Determ_Agudeza_Visual_3_4a,
				m.O_Determ_Agudeza_Visual_5_7a,
				m.O_Determ_Agudeza_Visual_8_11a,
				m.O_Determ_Agudeza_Visual_Total,
			
			
			
			   --Evaluacion de Errores Refractivos en Niños de 3 a 11 años
				m.O_Determ_Agudeza_Visual_eva_3_4a,
				m.O_Determ_Agudeza_Visual_eva_5_7a,
				m.O_Determ_Agudeza_Visual_eva_8_11a,
				m.O_Determ_Agudeza_Visual_eva_Total,
			  
				--Referencias de Errores Refractivos en Niños de 3 a 11 años
			  
				m.O_Determ_Agudeza_Visual_ref_3_4a,
				m.O_Determ_Agudeza_Visual_ref_5_7a,
				m.O_Determ_Agudeza_Visual_ref_8_11a,
				m.O_Determ_Agudeza_Visual_ref_Total,
			
			  --Diagnostico de Errores Refractivos en Niños de 3 a 11 años
			--Hipermetropía CASOS
			  
				m.O_Dx_ErrR_Hip_3_4a,
				m.O_Dx_ErrR_Hip_5_7a,
				m.O_Dx_ErrR_Hip_8_11a,
				m.O_Dx_ErrR_Hip_Total,
					
			   ----Miopía CASOS
			  
				m.O_Dx_ErrR_Mio_3_4a,
				m.O_Dx_ErrR_Mio_5_7a,
				m.O_Dx_ErrR_Mio_8_11a,
				m.O_Dx_ErrR_Mio_Total,
			  
			  --Astigmatismo CASOS
			  
				m.O_Dx_ErrR_Ast_3_4a,
				m.O_Dx_ErrR_Ast_5_7a,
				m.O_Dx_ErrR_Ast_8_11a,
				m.O_Dx_ErrR_Ast_Total,
			
				--Anisometropía CASOS
				m.O_Dx_ErrR_Ani_3_4a,
				m.O_Dx_ErrR_Ani_5_7a,
				m.O_Dx_ErrR_Ani_8_11a,
				m.O_Dx_ErrR_Ani_Total,
			
			 --Tratamiento de Errores Refractivos 
			 --Provisión de anteojos
				
				m.O_tto_Prov_anteo_3_4a,
				m.O_tto_Prov_anteo_5_7a,
				m.O_tto_Prov_anteo_8_11a,
				m.O_tto_Prov_anteo_Total,
			
			
			---SALUD BUCAL
			
			m.B_IHO_I_0_28d,
			m.B_IHO_I_29_5m,
			m.B_IHO_I_6_11m,
			m.B_IHO_I_1a,
			m.B_IHO_I_2a,
			m.B_IHO_I_3a,
			m.B_IHO_I_4a,
			m.B_IHO_5_11a,
			
			-----ASESORIA NUTRICIONAL PARA EL CONTROL DE ENFERMEDADES DENTALES
			--INICIAN TTO
			
			m.B_ANCED_I_0_28d,
			m.B_ANCED_I_29_5m,
			m.B_ANCED_I_6_11m,
			m.B_ANCED_I_1a,
			m.B_ANCED_I_2a,
			m.B_ANCED_I_3a,
			m.B_ANCED_I_4a,
			m.B_ANCED_I_5_11a,
			
			
			--APLICACION DE BARNIZ FLUORADO
			--INICIAN TTO
			
			m.B_ABF_I_0_28d,
			m.B_ABF_I_29_5m,
			m.B_ABF_I_6_11m,
			m.B_ABF_I_1a,
			m.B_ABF_I_2a,
			m.B_ABF_I_3a,
			m.B_ABF_I_4a,
			m.B_ABF_I_5_11a,
			
			
			
			--PROFILAXIS DENTAL
			--INICIAN TTO
			
			m.B_PD_I_0_28d,
			m.B_PD_I_29_5m,
			m.B_PD_I_6_11m,
			m.B_PD_I_1a,
			m.B_PD_I_2a,
			m.B_PD_I_3a,
			m.B_PD_I_4a,
			m.B_PD_I_5_11a,
			
			
			--SUB PRODUCTO: APLICACIÓN DE SELLANTES 
			--CODIGO: 5000601
			
			m.B_ASELN_CT_2a,
			m.B_ASELN_CT_3a,
			m.B_ASELN_CT_4a,
			m.B_ASELN_CT_5_11a
		
	
		FROM monitoreo_general m
		ORDER BY m.cod_2000, m.anio, m.mes;


---consejerias  niños 

	 -- 1️⃣ Eliminar tabla final si existe
    DROP TABLE IF EXISTS es_ivan.cred2026_4;

    -- 2️⃣ Eliminar tabla temporal si existe


CREATE TABLE es_ivan.cred2026_4 AS

-- ============================================
-- 🔥 BASE MINIMA (SOLO LO NECESARIO)
-- ============================================
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

    (
        EXTRACT(YEAR FROM age(fecha_atencion, fecha_nacimiento)) * 12 +
        EXTRACT(MONTH FROM age(fecha_atencion, fecha_nacimiento))
    )::int AS edad_meses

    FROM es_ivan.tabla_vacunas
    WHERE anio >= 2025
      AND codigo_item IN ('99199.26','99403','99403.01','99436','99381.01','99401.03','99411.01','99431','J00X','P599','J029','99381','99382','99383','C8002','Z001',
      						'99401.05','99401.07','99401.08','99401.09','99401.12','99401.16','99401.24','99401.25','99403.01','99401.03','P929','99211','99211','99199.17','R620','R628','E440',
      						'E669','E6690','E45X','E43X','E344','87177.01','B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664','87178',
      						'B80X','99199.28','C0011','85018.01','P070','P071','P0711','P0712','P0713','P072','P073','U1692','59430','U140','R456','Z720','Z721','Z722','Z133',
      						'H351','H351','H579','H579','Z010','PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527'
							'67228','67229','92390','99499.08','99499.09','99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10')

),

flags_cita AS (
SELECT
    id_cita,

/* ===================== FLAGS CLÍNICOS ===================== */

MAX((codigo_item LIKE 'P07%')::int) AS bpn_P07,
MAX((codigo_item = 'P0712')::int)   AS prematuro_P0712, 
MAX((codigo_item = 'Z001')::int)    AS rutina_Z001,
MAX((codigo_item LIKE 'D50%')::int) AS anemia_D50,
MAX((codigo_item = '99199.17' AND valor_lab = 'TA')::int) AS suple_TA_99199_17,
MAX((codigo_item = 'C0011')::int)   AS visit_domic_C0011,

MAX((codigo_item = 'C8002' AND valor_lab = '1')::int) AS planAIS_c8002_1,
MAX((codigo_item = 'C8002' AND valor_lab = 'TA')::int) AS planAIS_TA_c8002,

MAX((codigo_item = 'R620' AND valor_lab = 'PR')::int) AS eval_des_rec_R620,
MAX((codigo_item = 'R628' AND valor_lab = 'PR')::int) AS eval_rec_r628,
MAX((codigo_item = 'R628' AND valor_lab = 'PE')::int) AS eval_PE_R628,
MAX((codigo_item = 'R628' AND valor_lab = 'TE')::int) AS eval_TE_R628,

MAX((codigo_item = 'E440' AND valor_lab = 'TP')::int) AS desn_aguda_TP_E440,
MAX((codigo_item = 'E440' AND valor_lab = 'PR')::int) AS desn_aguda_PR_E440,
MAX((codigo_item = 'E440' AND valor_lab = 'PE')::int) AS desn_global_PE_E440,
MAX((codigo_item = 'E440' AND valor_lab = 'PR')::int) AS desn_global_PR_E440,

MAX((codigo_item = 'E45X' AND valor_lab = 'TE')::int) AS desn_cronica_TE_E45X,
MAX((codigo_item = 'E45X' AND valor_lab = 'PR')::int) AS desn_cronica_rec_E45X,
MAX((codigo_item = 'E45X' AND valor_lab = 'TP')::int) AS desn_severa_TP_E43X,
MAX((codigo_item = 'E45X' AND valor_lab = 'PR')::int) AS desn_severa_rec_E43X,

MAX((codigo_item = 'E6690' AND valor_lab ='TP')::int) AS sobre_peso_TP_E6690,
MAX((codigo_item = 'E6690' AND valor_lab ='PR')::int) AS sobre_peso_rec_E6690,
MAX((codigo_item = 'E669' AND valor_lab = 'TP')::int) AS obeso_TP_E669,
MAX((codigo_item = 'E669' AND valor_lab = 'PR')::int) AS obeso_rec_E669,

MAX((codigo_item = 'E344' AND valor_lab = 'TE')::int) AS talla_Edad_TE_E344,
MAX((codigo_item = 'E344' AND valor_lab = 'PR')::int) AS talla_Edad_TE_rec_E344,

/* ===================== VIF ===================== */

MAX((codigo_item = 'U140')::int) AS VIF_U140,
MAX((codigo_item = 'R456')::int) AS VIF_post_R456,
MAX((codigo_item = 'Z720')::int) AS AD_tabaco_post_Z720,
MAX((codigo_item = 'Z721')::int) AS AD_alcohol_post_Z721,
MAX((codigo_item = 'Z722')::int) AS AD_drogas_post_Z722,
MAX((codigo_item = 'Z133')::int) AS TD_post_Z133,

/* ===================== OCULARES ===================== */

MAX((codigo_item = 'H351' AND valor_lab='1')::int)  AS retino_premat_H351,
MAX((codigo_item = 'H351' AND valor_lab='RF')::int) AS retino_premat_RF_H351,

MAX((codigo_item = 'H579' AND tipo_diagnostico='P')::int) AS trast_ojo_anexos_H579,
MAX((codigo_item = 'H579' AND tipo_diagnostico='P' AND valor_lab='RF')::int) AS trast_ojo_anexos_RF_H579,

MAX((codigo_item = 'Z010' AND valor_lab='N' AND tipo_diagnostico='D')::int) AS ex_ojo_vision_N_Z010,
MAX((codigo_item = 'Z010' AND valor_lab='A' AND tipo_diagnostico='D')::int) AS ex_ojo_vision_A_Z010,
MAX((codigo_item = 'Z010' AND tipo_diagnostico='D')::int) AS ex_ojo_vision_Z010,

MAX((codigo_item IN ('PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527') AND tipo_diagnostico='P')::int) AS deter_agude_visual_PH,

MAX((codigo_item = '67228' AND tipo_diagnostico='D')::int) AS tto_retinopatia_67228,
MAX((codigo_item = '67229' AND tipo_diagnostico='D')::int) AS destruc_retinopatia_67229,
MAX((codigo_item = '92390' AND tipo_diagnostico='D')::int) AS provision_lentes_92390,

/* ===================== TELEMEDICINA ===================== */

MAX((codigo_item = '99499.08')::int) AS teleori_sincro_99499_08,
MAX((codigo_item = '99499.09')::int) AS teleori_asincr_99499_09,
MAX((codigo_item IN ('99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10'))::int) AS telemedicina_99499__,

/* ===================== CONDICIONES ===================== */

MAX((fg_tipo = 'CX')::int) AS flg_comorbilidad,

MAX((valor_lab = 'ST')::int) AS flg_st,
MAX((valor_lab = 'OM')::int) AS flg_OM,
MAX((valor_lab = 'VIH')::int) AS flg_vih,
MAX((valor_lab = 'VPH')::int) AS flg_VPH,
MAX((valor_lab = 'AER')::int) AS flg_AER,
MAX((valor_lab = 'TER')::int) AS flg_TER,
MAX((valor_lab = 'FRON')::int) AS flg_FRO,
MAX((valor_lab = 'RSA')::int) AS flg_RSA,

MAX((valor_lab = 'END')::int) AS flg_END,
MAX((valor_lab = 'FNI')::int) AS flg_FNI,
MAX((valor_lab = 'PNP')::int) AS flg_PNP,
MAX((valor_lab = 'M')::int) AS flg_M,
MAX((valor_lab = 'EF')::int) AS flg_EF,
MAX((valor_lab = 'BOM')::int) AS flg_BOM,
MAX((valor_lab = 'DCI')::int) AS flg_DCI,
MAX((valor_lab = 'EST')::int) AS flg_EST,
MAX((valor_lab = 'CR')::int) AS flg_CR,

MAX((valor_lab IN ('IN','PPL'))::int) AS flg_INPE_PPL,
MAX((valor_lab = 'REH')::int) AS flg_REH,
MAX((valor_lab IN ('RS','RSA','RMA'))::int) AS flg_HF,
MAX((valor_lab = 'SR')::int) AS flg_SR,
MAX((valor_lab = 'DIS')::int) AS flg_DIS,

MAX((valor_lab IN ('TS','HSH','HTS','TTS','PNP','M','BOM','DCI','EST','TRA','PPL','G','P','OTR','VIH','OM'))::int) AS flg_OTR,

MAX((valor_lab IN ('E1','DE1','E2','DE2','E3','DE3','E4','DE4'))::int) AS flg_ENF,
MAX((id_etnia IN ('56','57','58','59','60'))::int) AS flg_etnia,

MAX((valor_lab = 'AD')::int) AS flg_AD,
MAX((valor_lab = 'TD')::int) AS flg_TD

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


---CONSEJERIA RN 

----REVISAR URGENTE
-- A) Atención Inmediata
SUM(CASE WHEN h.codigo_item IN ('99436') AND h.tip_edad='D' AND h.codigo_item NOT IN ('P07') THEN 1 ELSE 0 END) AS atenc_inmed_nino_sano,
SUM(CASE WHEN h.codigo_item IN ('99436.02') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS contacto_piel_piel,
SUM(CASE WHEN h.codigo_item IN ('99431') AND h.tip_edad='D' AND h.codigo_item NOT IN ('P07') THEN 1 ELSE 0 END) AS ex_fisico_rn_normal,

-- B) Condición al nacimiento
SUM(CASE WHEN h.codigo_item IN ('P070') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS peso_extremadamente_bajo,
SUM(CASE WHEN h.codigo_item IN ('P0711') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS muy_bajo_peso,
SUM(CASE WHEN h.codigo_item IN ('P0712') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS bajo_peso,
SUM(CASE WHEN h.codigo_item IN ('P080') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS macrosomico,
SUM(CASE WHEN h.codigo_item IN ('Q02X') AND h.tip_edad='D'  THEN 1 ELSE 0 END) AS microcefalia,
SUM(CASE WHEN h.codigo_item IN ('P072') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS prematuro_extremo,
SUM(CASE WHEN h.codigo_item IN ('P073') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS prematuro,
SUM(CASE WHEN h.codigo_item IN ('P082') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS post_termino,

-- C) Atención en Alojamiento Conjunto
SUM(CASE WHEN h.codigo_item IN ('99460') AND h.tip_edad='D' AND h.edad <= 3 THEN 1 ELSE 0 END) AS atencion_alojamiento_conjunto,
SUM(CASE WHEN h.codigo_item IN ('99433') AND h.tip_edad='D' AND h.edad <= 3 THEN 1 ELSE 0 END) AS evaluacion_medica_rn,
SUM(CASE WHEN h.codigo_item IN ('36416') AND h.tip_edad='D' AND h.edad <= 15 THEN 1 ELSE 0 END) AS tamizaje_toma_muestra,
SUM(CASE WHEN h.codigo_item IN ('99431.01') AND h.tip_edad='D' AND h.edad <= 2 THEN 1 ELSE 0 END) AS tamizaje_hipoacusia,
SUM(CASE WHEN h.codigo_item IN ('99431.02') AND h.tip_edad='D' AND h.edad <= 2 THEN 1 ELSE 0 END) AS tamizaje_catarata_congenita,
SUM(CASE WHEN h.codigo_item IN ('94760') AND h.tip_edad='D' AND h.edad <= 3 THEN 1 ELSE 0 END) AS tamizaje_cardiopatia,
SUM(CASE WHEN h.codigo_item IN ('99401.04') AND h.tip_edad='D' AND h.edad <= 7 THEN 1 ELSE 0 END) AS conse_corte_cordon_umbilical,
SUM(CASE WHEN h.codigo_item IN ('99401.03') AND h.tip_edad='D' AND h.edad <= 29 THEN 1 ELSE 0 END) AS conse_lactancia_materna,
SUM(CASE WHEN h.codigo_item IN ('99401.06') AND h.tip_edad='D' AND h.edad <= 29 THEN 1 ELSE 0 END) AS conse_cred_4_controles,
SUM(CASE WHEN h.codigo_item IN ('99401.08') AND h.tip_edad='D' AND h.edad <= 29 THEN 1 ELSE 0 END) AS conse_signos_alarma,
SUM(CASE WHEN h.codigo_item IN ('99401.1') AND h.tip_edad='D' AND h.edad <= 29 THEN 1 ELSE 0 END) AS conse_higiene_rn,
SUM(CASE WHEN h.codigo_item IN ('99401.17') AND h.tip_edad='D' AND h.edad <= 29 THEN 1 ELSE 0 END) AS conse_lm_neonatos_vih,

-- D) Resultados del Tamizaje Neonatal
SUM(CASE WHEN h.codigo_item IN ('E031') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS hipotiroidismo_congenito_sin_bocio,
SUM(CASE WHEN h.codigo_item IN ('E700') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS fenilcetonuria_clasica,
SUM(CASE WHEN h.codigo_item IN ('E250') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS hiperplasia_suprarrenal_congenita,
SUM(CASE WHEN h.codigo_item IN ('E849') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS fibrosis_quistica_sin_otra_especificacion,
SUM(CASE WHEN h.codigo_item IN ('Q120') AND ((h.tip_edad = 'D') OR (h.tip_edad = 'M' AND h.edad <= 2)) THEN 1 ELSE 0 END) AS catarata_congenita,
SUM(CASE WHEN h.codigo_item IN ('H902') AND ((h.tip_edad = 'D') OR (h.tip_edad = 'M' AND h.edad <= 2)) THEN 1 ELSE 0 END) AS hipoacusia_conductiva,
SUM(CASE WHEN h.codigo_item IN ('99431.021') AND h.edad <= 3 THEN 1 ELSE 0 END) AS cardiopatia_congenita_tipo1,
SUM(CASE WHEN h.codigo_item IN ('99431.022') AND h.edad <= 3 THEN 1 ELSE 0 END) AS cardiopatia_congenita_tipo2,

-- E) Visita Domiciliaria
SUM(CASE WHEN h.codigo_item IN ('99502','C0011') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS vd_cuidado_y_evaluacion_neonatal,
SUM(CASE WHEN h.codigo_item IN ('99431','C0011') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS anamnesis_y_ex_fisico_rn_normal,
SUM(CASE WHEN h.codigo_item IN ('99401.1','C0011') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS conse_higiene_rn_y_cuidado_en_el_hogar,
SUM(CASE WHEN h.codigo_item IN ('99401.04','C0011') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS conse_cuidado_cordon_umbilical,
SUM(CASE WHEN h.codigo_item IN ('99401.06','C0011') AND ((h.tip_edad = 'D') OR (h.tip_edad = 'M' AND h.edad <= 2)) THEN 1 ELSE 0 END) AS conse_cred_4_controles_vd,
SUM(CASE WHEN h.codigo_item IN ('99401.03','C0011') AND ((h.tip_edad = 'D') OR (h.tip_edad = 'M' AND h.edad <= 2)) THEN 1 ELSE 0 END) AS conse_lme_vd,
SUM(CASE WHEN h.codigo_item IN ('99401.08','C0011') AND h.edad <= 3 THEN 1 ELSE 0 END) AS conse_identificacion_signos_alarma,
SUM(CASE WHEN h.codigo_item IN ('99401.24','C0011') AND h.edad <= 3 THEN 1 ELSE 0 END) AS conse_higiene_de_manos,

-- Consejerías RN
SUM(CASE WHEN h.codigo_item IN ('99401.05') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS consej_atc_tempra_desarrollo_rn,
SUM(CASE WHEN h.codigo_item IN ('99401.07') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS consej_inmunizaciones_rn,
SUM(CASE WHEN h.codigo_item IN ('99401.08') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS conse_signos_alarma_rn,
SUM(CASE WHEN h.codigo_item IN ('99401.09') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS conse_prev_muerte_subita_lactant_rn,
SUM(CASE WHEN h.codigo_item IN ('99401.12') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS conse_prev_enf_prevalentes_IRA_EDA_rn,
SUM(CASE WHEN h.codigo_item IN ('99401.16') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS conse_salud_ocular_rn,
SUM(CASE WHEN h.codigo_item IN ('99401.24') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS conse_higiene_manos_rn,
SUM(CASE WHEN h.codigo_item IN ('99401.25') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS conse_pautas_crianza_rn,
SUM(CASE WHEN h.codigo_item IN ('99403.01') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS conse_aliment_saludable_rn,
SUM(CASE WHEN h.codigo_item IN ('99401.03') AND h.tip_edad='D' AND h.edad=1 THEN 1 ELSE 0 END) AS conse_lme_rn,
   
--CONSEJERÍAS (MENOR DE 1 AÑO)
SUM(CASE WHEN h.codigo_item='99401.05' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS consej_atc_tempra_desarrollo_men_1a,
SUM(CASE WHEN h.codigo_item='99401.07' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS consej_inmunizaciones_men_1a,
SUM(CASE WHEN h.codigo_item='99401.08' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS conse_signos_alarma_men_1a,
SUM(CASE WHEN h.codigo_item='99401.09' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS conse_prev_muerte_subita_lactant_men_1a,
SUM(CASE WHEN h.codigo_item='99401.12' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS conse_prev_enf_prevalentes_IRA_EDA_men_1a,
SUM(CASE WHEN h.codigo_item='99401.16' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS conse_salud_ocular_men_1a,
SUM(CASE WHEN h.codigo_item='99401.24' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS conse_higiene_manos_men_1a,
SUM(CASE WHEN h.codigo_item='99401.25' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS conse_pautas_crianza_men_1a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS conse_aliment_saludable_men_1a,
SUM(CASE WHEN h.codigo_item='99401.03' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS conse_lme_6m_men_1a,

---🔥 EDADES 1 A 7 AÑOS (PATRÓN REPETIDO OPTIMIZADO)

-- 1 AÑO
SUM(CASE WHEN h.codigo_item='99401.05' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS consej_atc_tempra_desarrollo_1a,
SUM(CASE WHEN h.codigo_item='99401.07' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS consej_inmunizaciones_1a,
SUM(CASE WHEN h.codigo_item='99401.08' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS conse_signos_alarma_1a,
SUM(CASE WHEN h.codigo_item='99401.09' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS conse_prev_muerte_subita_lactant_1a,
SUM(CASE WHEN h.codigo_item='99401.12' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS conse_prev_enf_prevalentes_IRA_EDA_1a,
SUM(CASE WHEN h.codigo_item='99401.16' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS conse_salud_ocular_1a,
SUM(CASE WHEN h.codigo_item='99401.24' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS conse_higiene_manos_1a,
SUM(CASE WHEN h.codigo_item='99401.25' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS conse_pautas_crianza_1a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS conse_aliment_saludable_1a,
SUM(CASE WHEN h.codigo_item='99401.03' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS conse_lme_1a,

SUM(CASE WHEN h.codigo_item='99401.05' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS consej_atc_tempra_desarrollo_2a,
SUM(CASE WHEN h.codigo_item='99401.07' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS consej_inmunizaciones_2a,
SUM(CASE WHEN h.codigo_item='99401.08' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS conse_signos_alarma_2a,
SUM(CASE WHEN h.codigo_item='99401.09' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS conse_prev_muerte_subita_lactant_2a,
SUM(CASE WHEN h.codigo_item='99401.12' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS conse_prev_enf_prevalentes_IRA_EDA_2a,
SUM(CASE WHEN h.codigo_item='99401.16' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS conse_salud_ocular_2a,
SUM(CASE WHEN h.codigo_item='99401.24' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS conse_higiene_manos_2a,
SUM(CASE WHEN h.codigo_item='99401.25' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS conse_pautas_crianza_2a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS conse_aliment_saludable_2a,
SUM(CASE WHEN h.codigo_item='99401.03' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS conse_lme_2a,

SUM(CASE WHEN h.codigo_item='99401.05' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS consej_atc_tempra_desarrollo_3a,
SUM(CASE WHEN h.codigo_item='99401.07' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS consej_inmunizaciones_3a,
SUM(CASE WHEN h.codigo_item='99401.08' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS conse_signos_alarma_3a,
SUM(CASE WHEN h.codigo_item='99401.09' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS conse_prev_muerte_subita_lactant_3a,
SUM(CASE WHEN h.codigo_item='99401.12' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS conse_prev_enf_prevalentes_IRA_EDA_3a,
SUM(CASE WHEN h.codigo_item='99401.16' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS conse_salud_ocular_3a,
SUM(CASE WHEN h.codigo_item='99401.24' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS conse_higiene_manos_3a,
SUM(CASE WHEN h.codigo_item='99401.25' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS conse_pautas_crianza_3a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS conse_aliment_saludable_3a,
SUM(CASE WHEN h.codigo_item='99401.03' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS conse_lme_3a,

SUM(CASE WHEN h.codigo_item='99401.05' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS consej_atc_tempra_desarrollo_4a,
SUM(CASE WHEN h.codigo_item='99401.07' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS consej_inmunizaciones_4a,
SUM(CASE WHEN h.codigo_item='99401.08' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS conse_signos_alarma_4a,
SUM(CASE WHEN h.codigo_item='99401.09' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS conse_prev_muerte_subita_lactant_4a,
SUM(CASE WHEN h.codigo_item='99401.12' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS conse_prev_enf_prevalentes_IRA_EDA_4a,
SUM(CASE WHEN h.codigo_item='99401.16' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS conse_salud_ocular_4a,
SUM(CASE WHEN h.codigo_item='99401.24' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS conse_higiene_manos_4a,
SUM(CASE WHEN h.codigo_item='99401.25' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS conse_pautas_crianza_4a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS conse_aliment_saludable_4a,
SUM(CASE WHEN h.codigo_item='99401.03' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS conse_lme_4a,

SUM(CASE WHEN h.codigo_item='99401.05' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS consej_atc_tempra_desarrollo_5a,
SUM(CASE WHEN h.codigo_item='99401.07' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS consej_inmunizaciones_5a,
SUM(CASE WHEN h.codigo_item='99401.08' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS conse_signos_alarma_5a,
SUM(CASE WHEN h.codigo_item='99401.09' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS conse_prev_muerte_subita_lactant_5a,
SUM(CASE WHEN h.codigo_item='99401.12' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS conse_prev_enf_prevalentes_IRA_EDA_5a,
SUM(CASE WHEN h.codigo_item='99401.16' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS conse_salud_ocular_5a,
SUM(CASE WHEN h.codigo_item='99401.24' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS conse_higiene_manos_5a,
SUM(CASE WHEN h.codigo_item='99401.25' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS conse_pautas_crianza_5a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS conse_aliment_saludable_5a,
SUM(CASE WHEN h.codigo_item='99401.03' AND h.tip_edad='A' AND h.edad=5 THEN 1 ELSE 0 END) AS conse_lme_5a,

SUM(CASE WHEN h.codigo_item='99401.05' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS consej_atc_tempra_desarrollo_6a,
SUM(CASE WHEN h.codigo_item='99401.07' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS consej_inmunizaciones_6a,
SUM(CASE WHEN h.codigo_item='99401.08' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS conse_signos_alarma_6a,
SUM(CASE WHEN h.codigo_item='99401.09' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS conse_prev_muerte_subita_lactant_6a,
SUM(CASE WHEN h.codigo_item='99401.12' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS conse_prev_enf_prevalentes_IRA_EDA_6a,
SUM(CASE WHEN h.codigo_item='99401.16' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS conse_salud_ocular_6a,
SUM(CASE WHEN h.codigo_item='99401.24' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS conse_higiene_manos_6a,
SUM(CASE WHEN h.codigo_item='99401.25' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS conse_pautas_crianza_6a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS conse_aliment_saludable_6a,
SUM(CASE WHEN h.codigo_item='99401.03' AND h.tip_edad='A' AND h.edad=6 THEN 1 ELSE 0 END) AS conse_lme_6a,

SUM(CASE WHEN h.codigo_item='99401.05' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS consej_atc_tempra_desarrollo_7a,
SUM(CASE WHEN h.codigo_item='99401.07' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS consej_inmunizaciones_7a,
SUM(CASE WHEN h.codigo_item='99401.08' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS conse_signos_alarma_7a,
SUM(CASE WHEN h.codigo_item='99401.09' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS conse_prev_muerte_subita_lactant_7a,
SUM(CASE WHEN h.codigo_item='99401.12' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS conse_prev_enf_prevalentes_IRA_EDA_7a,
SUM(CASE WHEN h.codigo_item='99401.16' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS conse_salud_ocular_7a,
SUM(CASE WHEN h.codigo_item='99401.24' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS conse_higiene_manos_7a,
SUM(CASE WHEN h.codigo_item='99401.25' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS conse_pautas_crianza_7a,
SUM(CASE WHEN h.codigo_item='99403.01' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS conse_aliment_saludable_7a,
SUM(CASE WHEN h.codigo_item='99401.03' AND h.tip_edad='A' AND h.edad=7 THEN 1 ELSE 0 END) AS conse_lme_7a,

-- LACTANCIA
SUM(CASE WHEN h.codigo_item='P929' AND h.tip_edad='M' THEN 1 ELSE 0 END) AS suspencion_lme_6m,
-- EVALUACIÓN NUTRICIONAL
--RN 1–7 días
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='1' AND h.tip_edad='D' AND h.edad BETWEEN 1 AND 7 THEN 1 ELSE 0 END) AS eval_nutric_1_rn_1_7d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='2' AND h.tip_edad='D' AND h.edad BETWEEN 1 AND 7 THEN 1 ELSE 0 END) AS eval_nutric_2_rn_1_7d,
---RN 8–14 días
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='1' AND h.tip_edad='D' AND h.edad BETWEEN 7 AND 14 THEN 1 ELSE 0 END) AS eval_nutric_1_rn_8_14d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='2' AND h.tip_edad='D' AND h.edad BETWEEN 7 AND 14 THEN 1 ELSE 0 END) AS eval_nutric_2_rn_8_14d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='3' AND h.tip_edad='D' AND h.edad BETWEEN 7 AND 14 THEN 1 ELSE 0 END) AS eval_nutric_3_rn_8_14d,
--RN 15–21 días
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='1' AND h.tip_edad='D' AND h.edad BETWEEN 15 AND 21 THEN 1 ELSE 0 END) AS eval_nutric_1_rn_15_21d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='2' AND h.tip_edad='D' AND h.edad BETWEEN 15 AND 21 THEN 1 ELSE 0 END) AS eval_nutric_2_rn_15_21d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='3' AND h.tip_edad='D' AND h.edad BETWEEN 15 AND 21 THEN 1 ELSE 0 END) AS eval_nutric_3_rn_15_21d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='4' AND h.tip_edad='D' AND h.edad BETWEEN 15 AND 21 THEN 1 ELSE 0 END) AS eval_nutric_4_rn_15_21d,
--RN ≥22 días
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='1' AND h.tip_edad='D' AND h.edad >= 22 THEN 1 ELSE 0 END) AS eval_nutric_1_rn_may22d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='2' AND h.tip_edad='D' AND h.edad >= 22 THEN 1 ELSE 0 END) AS eval_nutric_2_rn_may22d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='3' AND h.tip_edad='D' AND h.edad >= 22 THEN 1 ELSE 0 END) AS eval_nutric_3_rn_may22d,
SUM(CASE WHEN h.codigo_item='99211' AND h.valor_lab='4' AND h.tip_edad='D' AND h.edad >= 22 THEN 1 ELSE 0 END) AS eval_nutric_4_rn_may22d,



-- Consulta nutricional BPN
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND f.bpn_P07=1 AND h.tip_edad='D' THEN 1 ELSE 0 END) AS consulta_nutric_BPN,

-- Menores 4-5 meses
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='M' AND h.edad BETWEEN 4 AND 5 THEN 1 ELSE 0 END) AS consulta_nutric1_4_5m,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='M' AND h.edad BETWEEN 4 AND 5 THEN 1 ELSE 0 END) AS consulta_nutric2_4_5m,

-- Menores 6-11 meses
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='M' AND h.edad BETWEEN 6 AND 11 THEN 1 ELSE 0 END) AS consulta_nutric_1_6_11m,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='M' AND h.edad BETWEEN 6 AND 11 THEN 1 ELSE 0 END) AS consulta_nutric_2_6_11m,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='3' AND h.tip_edad='M' AND h.edad BETWEEN 6 AND 11 THEN 1 ELSE 0 END) AS consulta_nutric_3_6_11m,

-- Edad 1 año
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS consulta_nutric_1_1a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS consulta_nutric_2_1a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=1 THEN 1 ELSE 0 END) AS consulta_nutric_3_1a,

-- Edad 2 años
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS consulta_nutric_1_2a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS consulta_nutric_2_2a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=2 THEN 1 ELSE 0 END) AS consulta_nutric_3_2a,

-- Edad 3 años
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS consulta_nutric_1_3a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS consulta_nutric_2_3a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS consulta_nutric_3_3a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='4' AND h.tip_edad='A' AND h.edad=3 THEN 1 ELSE 0 END) AS consulta_nutric_4_3a,

-- Edad 4 años
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS consulta_nutric_1_4a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS consulta_nutric_2_4a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad=4 THEN 1 ELSE 0 END) AS consulta_nutric_3_4a,

-- Edad 5 a 11 años
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='1' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS consulta_nutric_1_5_11a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='2' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS consulta_nutric_2_5_11a,
SUM(CASE WHEN h.codigo_item='99209' AND h.valor_lab='3' AND h.tip_edad='A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS consulta_nutric_3_5_11a





FROM base h
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

    -- 🔹 Indicadores por cita
        /* SUPLEMENTACIÓN GESTANTE */

   
m.consej_atc_tempra_desarrollo_men_1a,
m.consej_inmunizaciones_men_1a,
m.conse_signos_alarma_men_1a,
m.conse_prev_muerte_subita_lactant_men_1a,
m.conse_prev_enf_prevalentes_IRA_EDA_men_1a,
m.conse_salud_ocular_men_1a,
m.conse_higiene_manos_men_1a,
m.conse_pautas_crianza_men_1a,
m.conse_aliment_saludable_men_1a,
m.conse_lme_6m_men_1a,

m.consej_atc_tempra_desarrollo_1a,
m.consej_inmunizaciones_1a,
m.conse_signos_alarma_1a,
m.conse_prev_muerte_subita_lactant_1a,
m.conse_prev_enf_prevalentes_IRA_EDA_1a,
m.conse_salud_ocular_1a,
m.conse_higiene_manos_1a,
m.conse_pautas_crianza_1a,
m.conse_aliment_saludable_1a,
m.conse_lme_1a,

m.consej_atc_tempra_desarrollo_2a,
m.consej_inmunizaciones_2a,
m.conse_signos_alarma_2a,
m.conse_prev_muerte_subita_lactant_2a,
m.conse_prev_enf_prevalentes_IRA_EDA_2a,
m.conse_salud_ocular_2a,
m.conse_higiene_manos_2a,
m.conse_pautas_crianza_2a,
m.conse_aliment_saludable_2a,
m.conse_lme_2a,

m.consej_atc_tempra_desarrollo_3a,
m.consej_inmunizaciones_3a,
m.conse_signos_alarma_3a,
m.conse_prev_muerte_subita_lactant_3a,
m.conse_prev_enf_prevalentes_IRA_EDA_3a,
m.conse_salud_ocular_3a,
m.conse_higiene_manos_3a,
m.conse_pautas_crianza_3a,
m.conse_aliment_saludable_3a,
m.conse_lme_3a,

m.consej_atc_tempra_desarrollo_4a,
m.consej_inmunizaciones_4a,
m.conse_signos_alarma_4a,
m.conse_prev_muerte_subita_lactant_4a,
m.conse_prev_enf_prevalentes_IRA_EDA_4a,
m.conse_salud_ocular_4a,
m.conse_higiene_manos_4a,
m.conse_pautas_crianza_4a,
m.conse_aliment_saludable_4a,
m.conse_lme_4a,

m.consej_atc_tempra_desarrollo_5a,
m.consej_inmunizaciones_5a,
m.conse_signos_alarma_5a,
m.conse_prev_muerte_subita_lactant_5a,
m.conse_prev_enf_prevalentes_IRA_EDA_5a,
m.conse_salud_ocular_5a,
m.conse_higiene_manos_5a,
m.conse_pautas_crianza_5a,
m.conse_aliment_saludable_5a,
m.conse_lme_5a,

m.consej_atc_tempra_desarrollo_6a,
m.consej_inmunizaciones_6a,
m.conse_signos_alarma_6a,
m.conse_prev_muerte_subita_lactant_6a,
m.conse_prev_enf_prevalentes_IRA_EDA_6a,
m.conse_salud_ocular_6a,
m.conse_higiene_manos_6a,
m.conse_pautas_crianza_6a,
m.conse_aliment_saludable_6a,
m.conse_lme_6a,

m.consej_atc_tempra_desarrollo_7a,
m.consej_inmunizaciones_7a,
m.conse_signos_alarma_7a,
m.conse_prev_muerte_subita_lactant_7a,
m.conse_prev_enf_prevalentes_IRA_EDA_7a,
m.conse_salud_ocular_7a,
m.conse_higiene_manos_7a,
m.conse_pautas_crianza_7a,
m.conse_aliment_saludable_7a,
m.conse_lme_7a,

m.suspencion_lme_6m,
m.eval_nutric_1_rn_1_7d,
m.eval_nutric_2_rn_1_7d,
m.eval_nutric_1_rn_8_14d,
m.eval_nutric_2_rn_8_14d,
m.eval_nutric_3_rn_8_14d,
m.eval_nutric_1_rn_15_21d,
m.eval_nutric_2_rn_15_21d,
m.eval_nutric_3_rn_15_21d,
m.eval_nutric_4_rn_15_21d,
m.eval_nutric_1_rn_may22d,
m.eval_nutric_2_rn_may22d,
m.eval_nutric_3_rn_may22d,
m.eval_nutric_4_rn_may22d,

m.consulta_nutric_BPN,
m.consulta_nutric1_4_5m,
m.consulta_nutric2_4_5m,
m.consulta_nutric_1_6_11m,
m.consulta_nutric_2_6_11m,
m.consulta_nutric_3_6_11m,
m.consulta_nutric_1_1a,
m.consulta_nutric_2_1a,
m.consulta_nutric_3_1a,
m.consulta_nutric_1_2a,
m.consulta_nutric_2_2a,
m.consulta_nutric_3_2a,
m.consulta_nutric_1_3a,
m.consulta_nutric_2_3a,
m.consulta_nutric_3_3a,
m.consulta_nutric_4_3a,
m.consulta_nutric_1_4a,
m.consulta_nutric_2_4a,
m.consulta_nutric_3_4a,
m.consulta_nutric_1_5_11a,
m.consulta_nutric_2_5_11a,
m.consulta_nutric_3_5_11a,

m.atenc_inmed_nino_sano,
m.contacto_piel_piel,
m.ex_fisico_rn_normal,

m.peso_extremadamente_bajo,
m.muy_bajo_peso,
m.bajo_peso,
m.macrosomico,
m.microcefalia,
m.prematuro_extremo,
m.prematuro,
m.post_termino,

m.atencion_alojamiento_conjunto,
m.evaluacion_medica_rn,
m.tamizaje_toma_muestra,
m.tamizaje_hipoacusia,
m.tamizaje_catarata_congenita,
m.tamizaje_cardiopatia,
m.conse_corte_cordon_umbilical,
m.conse_lactancia_materna,
m.conse_cred_4_controles,
m.conse_signos_alarma,
m.conse_higiene_rn,
m.conse_lm_neonatos_vih,

m.hipotiroidismo_congenito_sin_bocio,
m.fenilcetonuria_clasica,
m.hiperplasia_suprarrenal_congenita,
m.fibrosis_quistica_sin_otra_especificacion,
m.catarata_congenita,
m.hipoacusia_conductiva,
m.cardiopatia_congenita_tipo1,
m.cardiopatia_congenita_tipo2,

m.vd_cuidado_y_evaluacion_neonatal,
m.anamnesis_y_ex_fisico_rn_normal,
m.conse_higiene_rn_y_cuidado_en_el_hogar,
m.conse_cuidado_cordon_umbilical,
m.conse_cred_4_controles_vd,
m.conse_lme_vd,
m.conse_identificacion_signos_alarma,
m.conse_higiene_de_manos,

m.consej_atc_tempra_desarrollo_rn,
m.consej_inmunizaciones_rn,
m.conse_signos_alarma_rn,
m.conse_prev_muerte_subita_lactant_rn,
m.conse_prev_enf_prevalentes_IRA_EDA_rn,
m.conse_salud_ocular_rn,
m.conse_higiene_manos_rn,
m.conse_pautas_crianza_rn,
m.conse_aliment_saludable_rn,
m.conse_lme_rn

FROM monitoreo_general m
ORDER BY m.cod_2000, m.anio, m.mes;
 




END;
$$;

CALL es_ivan.sp_generar_cred_2026();
*/*/