CREATE OR REPLACE PROCEDURE es_ivan.sp_generar_cred_{ANIO}()
LANGUAGE plpgsql
AS $$
begin
	
	 -- 1️⃣ Eliminar tabla final si existe
    DROP TABLE IF EXISTS es_ivan.cred{ANIO};

    -- 2️⃣ Eliminar tabla temporal si existe


CREATE TABLE es_ivan.cred{ANIO} AS

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
    WHERE anio >= {ANIO_MENOS_1}
      
),
----CNV----- 
cnv AS (
    SELECT
        EXTRACT(YEAR FROM TO_DATE(periodo::text,'YYYYMM')) AS anio,
        EXTRACT(MONTH FROM TO_DATE(periodo::text,'YYYYMM')) AS mes,
        ipress,

        COUNT(DISTINCT nu_cnv) FILTER (WHERE ligadura_corte IS NOT NULL) 
            AS corte_cordon_umbilical,

        COUNT(DISTINCT nu_cnv) FILTER (WHERE lactancia_precoz IS NOT NULL) 
            AS lactancia_primera_hora

    FROM es_ivan.cnv
    WHERE nu_cnv IS NOT NULL
    GROUP BY periodo, ipress
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
),  --select  * from cita_flags_{ANIO}

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
MAX((codigo_item = 'E43X' AND valor_lab = 'TP')::int) AS desn_severa_TP_E43X,
MAX((codigo_item = 'E43X' AND valor_lab = 'PR')::int) AS desn_severa_rec_E43X,

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
), --- select  * from flags_cita

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

SUM(CASE WHEN h.codigo_item = '99199.26' AND h.valor_lab = '1' AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS suplem1_12_17,
SUM(CASE WHEN h.codigo_item = '99199.26' AND h.valor_lab = '2' AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS suplem2_12_17,
SUM(CASE WHEN h.codigo_item = '99199.26' AND h.valor_lab = '3' AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS suplem3_12_17,
SUM(CASE WHEN h.codigo_item = '99199.26' AND h.valor_lab = 'TA' AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS suplem4_12_17ta,

SUM(CASE WHEN h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '1' AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS cons_nutri1_12_17,
SUM(CASE WHEN h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '2' AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS cons_nutri2_12_17,
SUM(CASE WHEN h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '3' AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS cons_nutri3_12_17,
SUM(CASE WHEN h.codigo_item IN ('99403','99403.01') AND h.valor_lab = '4' AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS cons_nutri4_12_17,

SUM(CASE WHEN h.codigo_item = '99209' AND h.valor_lab = '1' AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS consulta_nutric1_12_17a,
SUM(CASE WHEN h.codigo_item = '99209' AND h.valor_lab = '2' AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS consulta_nutric2_12_17a,
SUM(CASE WHEN h.codigo_item = '99209' AND h.valor_lab = '3' AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS consulta_nutric3_12_17a,

/* ===================== NEONATOS ===================== */

SUM(CASE WHEN h.codigo_item = '99436' AND f.prematuro_P0712 = 0 AND f.bpn_P07 = 0 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS atenc_inmediata_RN_sano,
SUM(CASE WHEN h.codigo_item = '99436' AND f.prematuro_P0712 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS atenc_inmediata_RN_premat,
SUM(CASE WHEN h.codigo_item = '99436' AND f.bpn_P07 = 1 AND f.prematuro_P0712 = 0 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS atencion_inmediata_BPN,
SUM(CASE WHEN h.codigo_item = '99381.01' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS plan_ais_ini_rn,
SUM(CASE WHEN h.codigo_item = '99381.01' AND f.rutina_Z001 = 1 AND f.planAIS_TA_c8002 = 1 AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS plan_ais_ta_rn,
SUM(CASE WHEN h.codigo_item = '99401.03' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS lme_1ra_hora,
SUM(CASE WHEN h.codigo_item IN ('99436.02') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS contacto_piel_piel,        
SUM(CASE WHEN h.codigo_item IN ('99502') AND h.tip_edad='D' THEN 1 ELSE 0 END) AS vd_cuidado_y_evaluacion_neonatal,
SUM(CASE WHEN h.codigo_item IN ('36416') AND h.tip_edad='D' AND h.edad <= 15 THEN 1 ELSE 0 END) AS tamizaje_toma_muestra,
SUM(CASE WHEN h.codigo_item IN ('99431.01') AND h.tip_edad='D' AND h.edad <= 2 THEN 1 ELSE 0 END) AS tamizaje_hipoacusia,
SUM(CASE WHEN h.codigo_item IN ('99431.02') AND h.tip_edad='D' AND h.edad <= 2 THEN 1 ELSE 0 END) AS tamizaje_catarata_congenita,
SUM(CASE WHEN h.codigo_item IN ('94760') AND h.tip_edad='D' AND h.edad <= 3 THEN 1 ELSE 0 END) AS tamizaje_cardiopatia,
-- BCG
SUM(CASE WHEN h.codigo_item = '90585' AND h.valor_lab IN ('', 'DU', '1', 'D1') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS bcg_12horas,
SUM(CASE WHEN h.codigo_item = '90585' AND h.valor_lab IN ('1', 'D1') AND h.tip_edad = 'D' AND h.edad BETWEEN 2 AND 29 THEN 1 ELSE 0 END) AS bcg_12_24h,
SUM(CASE WHEN h.codigo_item = '90585' AND h.valor_lab IN ('1', 'D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS bcg_1_11m,

-- HVB
SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('', 'DU') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS hvb_12_24h,
SUM(CASE WHEN h.codigo_item = '90744' AND h.valor_lab IN ('1', 'D1') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS hvb_24h,


----CNV---
MAX(cnv.corte_cordon_umbilical) AS corte_cordon_umbilical_cnv,
MAX(cnv.lactancia_primera_hora) AS lactancia_1ra_hora_cnv,
        
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

SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '1' AND h.edad_dias BETWEEN 360 AND 389 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_1a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = 'TA' AND h.edad_dias BETWEEN 630 AND 659 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_termino_1a,

-- PLAN AIS INICIO TERMINO 2 AÑOS

SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '1' AND h.edad_meses = 24 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_2a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = 'TA' AND h.edad_meses = 30 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_termino_2a,

-- PLAN AIS INICIO TERMINO 3 AÑOS

SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '1' AND h.edad_meses = 36 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_3a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = 'TA' AND h.edad_meses = 42 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_termino_3a,

-- PLAN AIS INICIO TERMINO 4 AÑOS

SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = '1' AND h.edad_meses = 48 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_4a,
SUM(CASE WHEN h.codigo_item = '99382' AND h.valor_lab = 'TA' AND h.edad_meses = 54 AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_termino_4a,

-- PLAN AIS INICIO TERMINO 5-11 AÑOS

SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad=5 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_5a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad=6 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_6a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad=7 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_7a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad=8 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_8a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad=9 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_9a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad=10 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_10a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = '1' AND h.edad=11 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ini_11a,

SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = 'TA' AND h.edad=5 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ta_5a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = 'TA' AND h.edad=6 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ta_6a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = 'TA' AND h.edad=7 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ta_7a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = 'TA' AND h.edad=8 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ta_8a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = 'TA' AND h.edad=9 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ta_9a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = 'TA' AND h.edad=10 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ta_10a,
SUM(CASE WHEN h.codigo_item = '99383' AND h.valor_lab = 'TA' AND h.edad=11 AND tip_edad='A' AND f.rutina_Z001 = 1 AND f.planAIS_c8002_1 = 1 THEN 1 ELSE 0 END) AS plan_ais_ta_11a,


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
LEFT JOIN cita_flags_{ANIO} ci ON h.id_cita = ci.id_cita
LEFT JOIN flags_cita f ON h.id_cita = f.id_cita
LEFT JOIN cnv 
ON (
    CASE 
        WHEN h.cod_2000 ~ '^[0-9]+$' 
        THEN h.cod_2000::int
        ELSE NULL
    END
) = cnv.ipress
AND h.anio = cnv.anio
AND h.mes  = cnv.mes

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
) -- select * from monitoreo_general 

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

	m.plan_ais_ini_5a,
	m.plan_ais_ini_6a,
	m.plan_ais_ini_7a,
	m.plan_ais_ini_8a,
	m.plan_ais_ini_9a,
	m.plan_ais_ini_10a,
	m.plan_ais_ini_11a,
	
	m.plan_ais_ta_5a,
	m.plan_ais_ta_6a,
	m.plan_ais_ta_7a,
	m.plan_ais_ta_8a,
	m.plan_ais_ta_9a,
	m.plan_ais_ta_10a,
	m.plan_ais_ta_11a,

  
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
  m.va2_4a,
  m.corte_cordon_umbilical_cnv,
  m.lactancia_1ra_hora_cnv,
  m.contacto_piel_piel,
  m.vd_cuidado_y_evaluacion_neonatal,
  m.tamizaje_toma_muestra,
  m.tamizaje_hipoacusia,
  m.tamizaje_catarata_congenita,
  m.tamizaje_cardiopatia,
  -- BCG
  m.bcg_12horas,
  m.bcg_12_24h,
  m.bcg_1_11m,

-- HVB
m.hvb_12_24h,
m.hvb_24h

FROM monitoreo_general m
ORDER BY m.cod_2000, m.anio, m.mes;


----generar tabla cred {ANIO} 1
    DROP TABLE IF EXISTS es_ivan.cred{ANIO}_1;
	CREATE TABLE es_ivan.cred{ANIO}_1 AS

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
    WHERE anio >= {ANIO_MENOS_1}
      /*AND codigo_item IN ('99199.26','99403','99403.01','99436','99381.01','99401.03','99411.01','99431','J00X','P599','J029','99381','99382','99383','C8002','Z001',
      						'99401.05','99401.07','99401.08','99401.09','99401.12','99401.16','99401.24','99401.25','99403.01','99401.03','P929','99211','99211','99199.17','R620','R628','E440',
      						'E669','E6690','E45X','E43X','E344','87177.01','B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664','87178',
      						'B80X','99199.28','C0011','85018.01','P070','P071','P0711','P0712','P0713','P072','P073','U1692','59430','U140','R456','Z720','Z721','Z722','Z133',
      						'H351','H351','H579','H579','Z010','H538','H509','H530','H559','H179','H029','H028','H527',
							'67228','67229','92390','99499.08','99499.09','99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10')  */

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

/* ===================== FLAGS CLÍNICOS ===================== */

MAX((codigo_item LIKE 'P07%')::int) AS bpn_P07,
MAX((codigo_item ='P0713')::int)   AS prematuro_P0712, 
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
SUM(CASE WHEN h.codigo_item = 'C0011' AND h.valor_lab = '1' AND h.tip_edad = 'A' AND h.edad_meses BETWEEN 36 AND 59 THEN 1 ELSE 0 END) AS vis_domic1_36_59m,

SUM(CASE WHEN h.codigo_item in ('E660', 'E440', 'E669') and f.visit_domic_C0011=1  AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS seguim_problemas_nutric_rn,
SUM(CASE WHEN h.codigo_item in ('E660', 'E440', 'E669') and f.visit_domic_C0011=1  AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS seguim_problemas_nutric_men_1a,
SUM(CASE WHEN h.codigo_item in ('E660', 'E440', 'E669') and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=1 THEN 1 ELSE 0 END) AS seguim_problemas_nutric_1a,
SUM(CASE WHEN h.codigo_item in ('E660', 'E440', 'E669') and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=2 THEN 1 ELSE 0 END) AS seguim_problemas_nutric_2a,
SUM(CASE WHEN h.codigo_item in ('E660', 'E440', 'E669') and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=3 THEN 1 ELSE 0 END) AS seguim_problemas_nutric_3a,
SUM(CASE WHEN h.codigo_item in ('E660', 'E440', 'E669') and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=4 THEN 1 ELSE 0 END) AS seguim_problemas_nutric_4a,
SUM(CASE WHEN h.codigo_item in ('E660', 'E440', 'E669') and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS seguim_problemas_nutric_5_11a,


SUM(CASE WHEN h.codigo_item='R628' and f.visit_domic_C0011=1  AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS seguim_problemas_desarr_rn,
SUM(CASE WHEN h.codigo_item='R628' and f.visit_domic_C0011=1  AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS seguim_problemas_desarr_men_1a,
SUM(CASE WHEN h.codigo_item='R628' and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=1 THEN 1 ELSE 0 END) AS seguim_problemas_desarr_1a,
SUM(CASE WHEN h.codigo_item='R628' and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=2 THEN 1 ELSE 0 END) AS seguim_problemas_desarr_2a,
SUM(CASE WHEN h.codigo_item='R628' and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=3 THEN 1 ELSE 0 END) AS seguim_problemas_desarr_3a,
SUM(CASE WHEN h.codigo_item='R628' and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=4 THEN 1 ELSE 0 END) AS seguim_problemas_desarr_4a,
SUM(CASE WHEN h.codigo_item='R628' and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS seguim_problemas_desarr_5_11a,

SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab in ('1','2','3','4','5','6','7','8','9','11','12','TA','SF1','SF2','SF3','SF4','SF5','SF6','SF7','SF8','SF9','P01','P02','P03','P04','P05','P06','P07','P08','P09') and f.visit_domic_C0011=1  AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS entrega_suplem_rn,
SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab in ('1','2','3','4','5','6','7','8','9','11','12','TA','SF1','SF2','SF3','SF4','SF5','SF6','SF7','SF8','SF9','P01','P02','P03','P04','P05','P06','P07','P08','P09') and f.visit_domic_C0011=1  AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS entrega_suplem_men_1a,
SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab in ('1','2','3','4','5','6','7','8','9','11','12','TA','SF1','SF2','SF3','SF4','SF5','SF6','SF7','SF8','SF9','P01','P02','P03','P04','P05','P06','P07','P08','P09') and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=1 THEN 1 ELSE 0 END) AS entrega_suplem_1a,
SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab in ('1','2','3','4','5','6','7','8','9','11','12','TA','SF1','SF2','SF3','SF4','SF5','SF6','SF7','SF8','SF9','P01','P02','P03','P04','P05','P06','P07','P08','P09') and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=2 THEN 1 ELSE 0 END) AS entrega_suplem_2a,
SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab in ('1','2','3','4','5','6','7','8','9','11','12','TA','SF1','SF2','SF3','SF4','SF5','SF6','SF7','SF8','SF9','P01','P02','P03','P04','P05','P06','P07','P08','P09') and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=3 THEN 1 ELSE 0 END) AS entrega_suplem_3a,
SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab in ('1','2','3','4','5','6','7','8','9','11','12','TA','SF1','SF2','SF3','SF4','SF5','SF6','SF7','SF8','SF9','P01','P02','P03','P04','P05','P06','P07','P08','P09') and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=4 THEN 1 ELSE 0 END) AS entrega_suplem_4a,
SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab in ('1','2','3','4','5','6','7','8','9','11','12','TA','SF1','SF2','SF3','SF4','SF5','SF6','SF7','SF8','SF9','P01','P02','P03','P04','P05','P06','P07','P08','P09') and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS entrega_suplem_5_11a,

SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab='' and f.visit_domic_C0011=1  AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS verif_cons_suple_rn,
SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab='' and f.visit_domic_C0011=1  AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS verif_cons_suple_men_1a,
SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab='' and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=1 THEN 1 ELSE 0 END) AS verif_cons_suple_1a,
SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab='' and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=2 THEN 1 ELSE 0 END) AS verif_cons_suple_2a,
SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab='' and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=3 THEN 1 ELSE 0 END) AS verif_cons_suple_3a,
SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab='' and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad=4 THEN 1 ELSE 0 END) AS verif_cons_suple_4a,
SUM(CASE WHEN h.codigo_item='Z298' AND h.valor_lab='' and f.visit_domic_C0011=1  AND h.tip_edad = 'A' and h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS verif_cons_suple_5_11a


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
  m.vis_domic1_36_59m,
  
m.seguim_problemas_nutric_rn,
m.seguim_problemas_nutric_men_1a,
m.seguim_problemas_nutric_1a,
m.seguim_problemas_nutric_2a,
m.seguim_problemas_nutric_3a,
m.seguim_problemas_nutric_4a,
m.seguim_problemas_nutric_5_11a,


m.seguim_problemas_desarr_rn,
m.seguim_problemas_desarr_men_1a,
m.seguim_problemas_desarr_1a,
m.seguim_problemas_desarr_2a,
m.seguim_problemas_desarr_3a,
m.seguim_problemas_desarr_4a,
m.seguim_problemas_desarr_5_11a,

m.entrega_suplem_rn,
m.entrega_suplem_men_1a,
m.entrega_suplem_1a,
m.entrega_suplem_2a,
m.entrega_suplem_3a,
m.entrega_suplem_4a,
m.entrega_suplem_5_11a,

m.verif_cons_suple_rn,
m.verif_cons_suple_men_1a,
m.verif_cons_suple_1a,
m.verif_cons_suple_2a,
m.verif_cons_suple_3a,
m.verif_cons_suple_4a,
m.verif_cons_suple_5_11a


    
FROM monitoreo_general m
ORDER BY m.cod_2000, m.anio, m.mes;

--HABILITAR PARA COMLETAR REPORTE

---table hemoglobina 
   DROP TABLE IF EXISTS es_ivan.cred{ANIO}_2;

    -- 2️⃣ Eliminar tabla temporal si existe


CREATE TABLE es_ivan.cred{ANIO}_2 AS

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
        id_correlativo_lab,

       /* EDAD EN DÍAS */
        (fecha_atencion::date - fecha_nacimiento::date) AS edad_dias,

        /* EDAD EN MESES */
        (
            EXTRACT(YEAR FROM age(fecha_atencion, fecha_nacimiento)) * 12 +
            EXTRACT(MONTH FROM age(fecha_atencion, fecha_nacimiento))
        )::int AS edad_meses,
        
        /* EDAD EN AÑOS */
        EXTRACT(YEAR FROM age(fecha_atencion, fecha_nacimiento))::int AS edad_anios
        
        /* SEMANAS */
----        ((fecha_atencion::date - fecha_ultima_regla::date) / 7)::int AS semana_gest

    FROM es_ivan.tabla_vacunas

    WHERE anio >= {ANIO_MENOS_1}
    
   ),

-- ============================================
-- 🔥 SOLO FLAG NECESARIO (GESTANTE)
-- ============================================
/* cita_flags_{ANIO} AS (
   SELECT 
    id_cita,dni_paciente,

    /* 🔹 PRIMERO detectar puérpera */
    MAX( CASE WHEN b.genero = 'F' AND (b.codigo_item = '59430' OR b.valor_lab = 'P' OR (b.codigo_item = 'U1692' AND b.valor_lab = 'TA'))THEN 1 ELSE 0 end ) AS es_puerpera,
    MAX( CASE WHEN b.genero = 'F' AND (b.codigo_item in('85018','85018.01') OR b.valor_lab = 'P' OR (b.codigo_item = 'U1692' AND b.valor_lab = 'TA'))THEN 1 ELSE 0 end ) AS hb_puerpera,

    /* 🔹 GESTANTE SOLO SI NO ES PUÉRPERA */
    CASE WHEN MAX(CASE WHEN b.genero = 'F' AND (b.codigo_item = '59430' OR b.valor_lab = 'P' OR (b.codigo_item = 'U1692' AND b.valor_lab = 'TA')) THEN 1 ELSE 0 END ) = 1  THEN 0  ELSE 
    MAX( CASE WHEN b.genero = 'F' THEN 1 ELSE 0 END) END AS es_gestante,
    MAX( CASE WHEN b.genero = 'F' AND (b.codigo_item in('85018','85018.01') OR b.valor_lab = 'P' OR (b.codigo_item = 'U1692' AND b.valor_lab = 'TA'))THEN 1 ELSE 0 end ) AS hb_puerpera
    
    /* SEMANAS */
   ---fecha_atencion::date - fecha_ultima_regla::date) / 7)::int AS semana_gest  por  activar
  */  
    
   
   cita_flags_{ANIO} AS (

    SELECT 
    	b.anio,
		b.dni_paciente,
        b.condicion_gestante,

        /* 🔹 IDENTIFICA PUÉRPERA */
        MAX(CASE WHEN b.genero = 'F'  AND (b.codigo_item = '59430' OR b.valor_lab = 'P' OR (b.codigo_item = 'U1692' AND b.valor_lab = 'TA')) THEN 1   ELSE 0 END ) AS es_puerpera,

        /* 🔹 HEMOGLOBINA EN PUÉRPERA */
        MAX(CASE WHEN b.genero = 'F' AND b.codigo_item IN ('85018','85018.01') AND 
        EXISTS 
        (SELECT 1 FROM es_ivan.tabla_materno x WHERE x.dni_paciente = b.dni_paciente AND (x.codigo_item = '59430' OR x.valor_lab = 'P' OR (x.codigo_item = 'U1692' AND x.valor_lab = 'TA'))) THEN 1 ELSE 0 END) AS hb_puerpera,

        /* 🔹 GESTANTE */
        CASE  WHEN MAX( CASE  WHEN b.genero = 'F' AND (b.codigo_item = '59430' OR b.valor_lab = 'P' OR ( b.codigo_item = 'U1692' AND b.valor_lab = 'TA')) THEN 1 ELSE 0 END) = 1 THEN 0  ELSE MAX(CASE WHEN b.genero = 'F' THEN 1 ELSE 0 END) END AS es_gestante,

        /* 🔹 HEMOGLOBINA EN GESTANTE */
        MAX(CASE WHEN b.genero = 'F' AND b.codigo_item IN ('85018','85018.01') /* NO DEBE SER PUÉRPERA */
                 AND NOT EXISTS 
                 (SELECT 1
                        FROM es_ivan.tabla_materno x
                        WHERE x.dni_paciente = b.dni_paciente 
                          AND (x.codigo_item = '59430' OR x.valor_lab = 'P' OR (x.codigo_item = 'U1692'AND x.valor_lab = 'TA' ))) THEN 1   ELSE 0 END ) AS hb_gestante

                               
                          
    FROM es_ivan.tabla_materno b

    GROUP BY 
    	b.anio,
        b.dni_paciente,
        b.condicion_gestante
), --select  * from cita_flags_{ANIO}

    
/*FROM es_ivan.tabla_materno b
left join es_ivan.cnv c on b.dni_paciente=c.fe_nacido  
GROUP BY b.id_cita,b.dni_paciente

),--select  * from cita_flags_{ANIO},*/

/* =========================================
   FLAGS CLÍNICOS
========================================= */

flags_cita AS (

    SELECT

        dni_paciente,
        anio,
            MAX((codigo_item LIKE 'P07%')::int) AS bpn_P07,
			MAX((codigo_item = 'P0712')::int)   AS prematuro_P0712, 
			MAX((codigo_item LIKE 'D50%')::int) AS anemia_D50,
			MAX((codigo_item = '99199.17' AND valor_lab = 'TA')::int) AS suple_TA_99199_17,
			MAX((codigo_item = 'C0011')::int)   AS visit_domic_C0011
            
    FROM base

    GROUP BY dni_paciente,anio
        
),

/* =========================================
   POBLACIÓN ELEGIBLE
========================================= */

poblacion AS (

    SELECT DISTINCT

        b.dni_paciente,
        b.fecha_nacimiento,
        b.genero,
        b.anio,
        b.mes,
        b.red,
        b.desc_ue,
        b.microred,
        b.provincia,
        b.distrito,
        b.cod_2000,
        b.nombre_establecimiento

    FROM base b

    LEFT JOIN flags_cita f
           ON b.dni_paciente = f.dni_paciente

    WHERE COALESCE(f.anemia_D50,0)=0
    --and b.codigo_item !~ '^P07'
),

/* =========================================
   NIÑOS CON DIAGNÓSTICO BPN / PREMATURO
========================================= */

diagnostico_bpn_prema AS (

    SELECT distinct
    	s.anio,
    	s.dni_paciente,
        s.fecha_nacimiento

    FROM base s
    WHERE codigo_item ~ '^P07'
), --select  * from diagnostico_bpn_prema,



/* =========================================
   INICIO SUPLEMENTACIÓN
========================================= */

inicio_suplementacion AS (

    SELECT *

    FROM (

        SELECT

            b.dni_paciente,
            b.fecha_atencion::date  AS fecha_inicio_suplementacion,
            b.edad_dias,
            b.edad_meses,
            b.edad_anios,
            b.anio,
            b.mes,
            b.red,
            b.desc_ue,
            b.microred,
            b.provincia,
            b.distrito,
            b.cod_2000,
            b.nombre_establecimiento,

            ROW_NUMBER() OVER (
                PARTITION BY b.dni_paciente
                ORDER BY b.fecha_atencion
            ) AS rn

        FROM base b
        
        WHERE b.codigo_item = '99199.17'
          AND b.valor_lab IN (
                '1','2','3','4','5','6',
                'SF1','P01','SF2','P02',
                'SF3','P03','SF4','P04',
                'SF5','P05','SF6','P06'
          )
          
    ) t

    WHERE rn = 1
),

/* =========================================
   SUPLEMENTACIÓN HIERRO BAJO PESO  AL  NACER
========================================= */

suplem_hierro_BPN AS (

    SELECT *

    FROM (

        SELECT 
            s.dni_paciente,
            s.fecha_nacimiento,
            s.fecha_atencion::date AS fecha_suplementacion,
            s.anio,
            s.mes,
--            EXTRACT(MONTH FROM s.fecha_atencion)AS mes,
            (s.fecha_atencion::date -  s.fecha_nacimiento::date ) AS edad_dias,
            s.nombre_establecimiento,
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
        INNER JOIN diagnostico_bpn_prema b ON s.dni_paciente = b.dni_paciente and s.anio=b.anio
        LEFT JOIN flags_cita p  ON s.dni_paciente = p.dni_paciente and s.anio=p.anio
        WHERE s.codigo_item = '99199.17'

          AND s.valor_lab IN (
                '1','2','3','4','5','6',
                'SF1','P01','SF2','P02',
                'SF3','P03','SF4','P04',
                'SF5','P05','SF6','P06'
          )

          AND COALESCE(p.visit_domic_C0011,0) = 0
          AND COALESCE(p.suple_TA_99199_17,0) = 0

    ) t
), --select  * from suplem_hierro_BPN,


totales_bpn AS (

    SELECT

        dni_paciente,
        anio,
        mes,
        cod_2000,
        red,
        desc_ue,
        microred,
        provincia,
        distrito,
      	nombre_establecimiento,

        /* IDENTIFICA NIÑO BPN */
        1 AS total_ninos_bpn,

        /* IDENTIFICA NIÑO BPN 30-59 DIAS */
        CASE WHEN nro_entrega = 1  AND edad_dias BETWEEN 30 AND 59 THEN 1 ELSE 0  END AS total_ninos_bpn_30_59_dias

    FROM suplem_hierro_BPN s

    GROUP BY
        dni_paciente,
        anio,
        mes,
        cod_2000,
        red,
        desc_ue,
        microred,
        provincia,
        distrito,
        nombre_establecimiento,
        nro_entrega,
        edad_dias
), --select  * from totales_bpn

/* =========================================
   1RA ENTREGA
========================================= */

primera_entrega_bpn AS (

    SELECT *  FROM suplem_hierro_BPN
    WHERE nro_entrega = 1
      AND edad_dias BETWEEN 30 AND 59
), --select  * from  primera_entrega_bpn 


/* =========================================
   2DA ENTREGA
========================================= */

segunda_entrega_bpn AS (

    SELECT

        s2.*,
        s1.fecha_suplementacion AS fecha_primera_entrega,
        (s2.fecha_suplementacion - s1.fecha_suplementacion) AS dias_1ra_2da,
        1 AS cumple_segunda_entrega_bpn
	    FROM suplem_hierro_BPN s2
	    INNER JOIN primera_entrega_bpn s1 ON s1.dni_paciente = s2.dni_paciente  AND s1.anio = s2.anio

    WHERE s2.nro_entrega = 2
     AND s2.fecha_suplementacion between s1.fecha_suplementacion + INTERVAL '30 days'  AND s1.fecha_suplementacion + INTERVAL '35 days'
    
---    AND s2.fecha_suplementacion >= s1.fecha_suplementacion + INTERVAL '30 days'
), --select  * FROM segunda_entrega_bpn

/* =========================================
   3RA ENTREGA
========================================= */

tercera_entrega_bpn AS (

    SELECT

        s3.*,
        s2.fecha_suplementacion AS fecha_segunda_entrega,
        (s3.fecha_suplementacion - s2.fecha_suplementacion) AS dias_2da_3ra,
        1 AS cumple_tercera_entrega_bpn
    FROM suplem_hierro_BPN s3
    INNER JOIN segunda_entrega_bpn s2  ON s2.dni_paciente = s3.dni_paciente  AND s3.anio = s2.anio
    WHERE s3.nro_entrega = 3  AND s3.fecha_suplementacion BETWEEN  s2.fecha_suplementacion + INTERVAL '30 days' AND s2.fecha_suplementacion + INTERVAL '35 days'

), --Select * from tercera_entrega_bpn

/* =========================================
   DOSAJES DE HEMOGLOBINA BAJO PERO  AL  NACER
========================================= */

hemoglobina_bpn AS (

    SELECT

        s.id_cita,
        s.dni_paciente,
        s.fecha_nacimiento,
        s.fecha_atencion::date AS fecha_dosaje_hb,
        s.valor_lab  AS valor_hb,
        s.anio,
        s.mes,
        --EXTRACT(MONTH FROM s.fecha_atencion) AS mes,
        (s.fecha_atencion::date - s.fecha_nacimiento::date ) AS edad_dias,
        s.nombre_establecimiento,
        s.red,
        s.desc_ue,
        s.microred,
        s.provincia,
        s.distrito,
        s.cod_2000

    FROM base s
    INNER JOIN diagnostico_bpn_prema b  ON s.dni_paciente = b.dni_paciente and s.anio=b.anio
    WHERE s.codigo_item IN ('85018','85018.01')
), ---select  * from hemoglobina_bpn ,

/* =========================================
   1ER DOSAJE HB bajo peso
========================================= */

primer_dosaje_hb_bpn AS (

    SELECT *

    FROM (

        SELECT

            h.anio,
            h.mes,
            h.nombre_establecimiento,
            h.red,
            h.desc_ue,
            h.microred,
            h.provincia,
            h.distrito,
            h.cod_2000,
            h.dni_paciente,
            h.fecha_nacimiento,
            h.fecha_dosaje_hb,
            h.valor_hb,
            h.edad_dias AS edad_dias_hb,
            p1.fecha_suplementacion,

            /* DÍAS DESDE NACIMIENTO HASTA HB */
            (h.fecha_dosaje_hb::date - h.fecha_nacimiento::date) AS dias_nac_a_fecha_hb,

            /* CUMPLE DOSAJE 30-35 DÍAS */
            CASE  WHEN h.fecha_dosaje_hb::date BETWEEN h.fecha_nacimiento::date + INTERVAL '30 days'  AND h.fecha_nacimiento::date + INTERVAL '35 days' THEN 1  ELSE 0  END AS cumple_primer_dosaje_hb_bpn,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_dosaje_hb
            ) AS rn

        FROM hemoglobina_bpn h

        INNER JOIN primera_entrega_bpn p1 ON h.dni_paciente = p1.dni_paciente AND h.anio = p1.anio WHERE h.fecha_dosaje_hb::date BETWEEN h.fecha_nacimiento::date + INTERVAL '30 days' AND h.fecha_nacimiento::date + INTERVAL '35 days'

    ) t

    WHERE rn = 1
),  --SELECT * FROM primer_dosaje_hb_bpn

/* =========================================
   2DO DOSAJE HB
   >= 90 DÍAS DESDE INICIO SUPLEMENTACIÓN
========================================= */

segundo_dosaje_hb_bpn AS (

    SELECT *

    FROM (

        SELECT

            h.anio,
            h.mes,
            h.nombre_establecimiento,
            h.red,
            h.desc_ue,
            h.microred,
            h.provincia,
            h.distrito,
            h.cod_2000,
            h.dni_paciente,
            h.fecha_dosaje_hb,
            h.valor_hb,
            p1.fecha_suplementacion,
            (h.fecha_dosaje_hb - p1.fecha_suplementacion) AS dias_desde_inicio_suplementacion,

            /* CUMPLE SEGUNDO DOSAJE */
            CASE
                WHEN h.fecha_dosaje_hb BETWEEN  p1.fecha_suplementacion + INTERVAL '90 days' AND p1.fecha_suplementacion + INTERVAL '95 days' THEN 1  ELSE 0  END AS cumple_segundo_dosaje_hb_bpn,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_dosaje_hb
            ) AS rn

        FROM hemoglobina_bpn h

        INNER JOIN primera_entrega_bpn p1 ON h.dni_paciente = p1.dni_paciente  AND h.anio = p1.anio
        WHERE h.fecha_dosaje_hb BETWEEN  p1.fecha_suplementacion + INTERVAL '90 days'  AND p1.fecha_suplementacion + INTERVAL '95 days'

    ) t

    WHERE rn = 1
), --SELECT * FROM segundo_dosaje_hb_bpn



/* =========================================
   DOSAJES DE HEMOGLOBINA niño  sano
========================================= */

hemoglobina AS (

    SELECT

        b.dni_paciente,
        b.fecha_nacimiento,
        b.fecha_atencion::date AS fecha_hb,
        b.valor_lab AS resultado_hb,
        b.edad_dias,
        b.edad_meses,
        b.edad_anios,
        b.anio,
        b.mes,
        b.red,
        b.desc_ue,
        b.microred,
        b.provincia,
        b.distrito,
        b.cod_2000,
        b.nombre_establecimiento,
        b.genero,
        m.es_gestante,
        m.es_puerpera

    FROM base b

    LEFT JOIN cita_flags_{ANIO} m
           on b.dni_paciente = m.dni_paciente

    WHERE b.codigo_item IN ('85018','85018.01')
), -- SELECT * FROM hemoglobina

/* =========================================
   6-11 MESES
   1ER DOSAJE A LOS 6 MESES
========================================= */

hb_6_11m_primer AS (

    SELECT *

    FROM (

        SELECT
            h.*,
            CASE WHEN h.fecha_hb BETWEEN h.fecha_nacimiento + INTERVAL '180 days'  AND h.fecha_nacimiento + INTERVAL '209 days'   THEN 1 ELSE 0  END AS cumple_1er_hb,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb
            ) AS rn

        FROM hemoglobina h
        WHERE h.edad_meses BETWEEN 6 AND 11

    ) t

    WHERE rn = 1
), --select  * from hb_6_11m_primer

/* =========================================
   6-11 MESES
   2DO DOSAJE AL 3ER MES DE SUPLEMENTACIÓN
========================================= */

hb_6_11m_segundo AS (

    SELECT *

    FROM (

        SELECT
			h.anio,
			h.mes,
            h.dni_paciente,
            h.fecha_hb,
            h.resultado_hb,
            i.fecha_inicio_suplementacion,
            (h.fecha_hb - i.fecha_inicio_suplementacion ) AS dias_desde_inicio,

            CASE WHEN h.fecha_hb BETWEEN i.fecha_inicio_suplementacion + INTERVAL '90 days' AND i.fecha_inicio_suplementacion + INTERVAL '120 days'  THEN 1 ELSE 0   END AS cumple_2da_hb,
            h.red,
            h.desc_ue,
            h.microred,
            h.provincia,
            h.distrito,
            h.cod_2000,
            h.nombre_establecimiento,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb
            ) AS rn

        FROM hemoglobina h

        INNER JOIN inicio_suplementacion i ON h.dni_paciente = i.dni_paciente and h.anio=i.anio
        WHERE h.edad_meses BETWEEN 6 AND 11

          AND h.fecha_hb BETWEEN
                i.fecha_inicio_suplementacion + INTERVAL '90 days'
            AND i.fecha_inicio_suplementacion + INTERVAL '120 days'

    ) t

    WHERE rn = 1
), --select  * from hb_6_11m_segundo

/* =========================================
   12-23 MESES
   1ER DOSAJE ANTES DE SUPLEMENTACIÓN
========================================= */

hb_12_23m_primer AS (

    SELECT *

    FROM (

        SELECT
			h.anio,
			h.mes,
            h.dni_paciente,
            h.fecha_hb,
            h.resultado_hb,
            i.fecha_inicio_suplementacion,
            (i.fecha_inicio_suplementacion - h.fecha_hb ) AS dias_desde_inicio_suple,
            h.red,
            h.desc_ue,
            h.microred,
            h.provincia,
            h.distrito,
            h.cod_2000,
            h.nombre_establecimiento,
            CASE  WHEN h.fecha_hb <= i.fecha_inicio_suplementacion  THEN 1 ELSE 0 END AS cumple_1ra_hb_12_23m,
            
            
            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb DESC
            ) AS rn

        FROM hemoglobina h

        INNER JOIN inicio_suplementacion i ON h.dni_paciente = i.dni_paciente and h.anio=i.anio

        WHERE h.edad_meses BETWEEN 12 AND 23
          AND h.fecha_hb  <= i.fecha_inicio_suplementacion

    ) t

    WHERE rn = 1
), --select * from hb_12_23m_primer

/* =========================================
   12-23 MESES
   2DO DOSAJE 90 DÍAS
========================================= */

hb_12_23m_segundo AS (

    SELECT *

    FROM (

        SELECT
			h.anio,
			h.mes,
            h.dni_paciente,
            h.fecha_hb,
            h.resultado_hb,
            i.fecha_inicio_suplementacion,
            h.red,
            h.desc_ue,
            h.microred,
            h.provincia,
            h.distrito,
            h.cod_2000,
            h.nombre_establecimiento,
            --- revisar 
            (h.fecha_hb - i.fecha_inicio_suplementacion) AS dias_desde_inicio_suple,
            CASE  WHEN h.fecha_hb BETWEEN i.fecha_inicio_suplementacion + INTERVAL '90 days'  AND i.fecha_inicio_suplementacion + INTERVAL '120 days'  THEN 1  ELSE 0    END AS cumple_2da_hb_12_23m,
            
            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb
            ) AS rn

        FROM hemoglobina h
        left JOIN inicio_suplementacion i ON h.dni_paciente = i.dni_paciente and h.anio=i.anio
        WHERE h.edad_meses BETWEEN 12 AND 23
          AND h.fecha_hb >= i.fecha_inicio_suplementacion + INTERVAL '90 days'

    ) t

    WHERE rn = 1
), ---select * from hb_12_23m_segundo
/* =========================================
   12-23 MESES
   3ER DOSAJE FINAL SUPLEMENTACIÓN
========================================= */

hb_12_23m_tercer_dh AS (

    SELECT *

    FROM (

        SELECT
			h.anio,
			h.mes,
            h.dni_paciente,
            h.fecha_hb,
            h.resultado_hb,

            i.fecha_inicio_suplementacion,
            (h.fecha_hb - i.fecha_inicio_suplementacion) AS dias_desde_inicio_suple,
			case WHEN h.fecha_hb >= i.fecha_inicio_suplementacion + INTERVAL '180 days' THEN 1  ELSE 0 END AS cumple_2da_hb_12_23m,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb DESC
            ) AS rn

        FROM hemoglobina h
        INNER JOIN inicio_suplementacion i ON h.dni_paciente = i.dni_paciente and h.anio=i.anio
        WHERE h.edad_meses BETWEEN 12 AND 23  AND h.fecha_hb >= i.fecha_inicio_suplementacion + INTERVAL '180 days'

    ) t

    WHERE rn = 1
    
), --select  * from hb_12_23m_tercer_dh


/* =========================================
   24-35 MESES
   1ER DOSAJE ANTES DE SUPLEMENTACIÓN
========================================= */

hb_24_35m_primer AS (

    SELECT *

    FROM (

        SELECT
			h.anio,
			h.mes,
            h.dni_paciente,
            h.fecha_hb,
            h.resultado_hb,
            i.fecha_inicio_suplementacion,
            (h.fecha_hb - i.fecha_inicio_suplementacion) AS dias_desde_inicio_suple,
            CASE  WHEN h.fecha_hb <= i.fecha_inicio_suplementacion  THEN 1 ELSE 0 END AS cumple_1ra_hb_24_35m,
            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb DESC
            ) AS rn

        FROM hemoglobina h

        INNER JOIN inicio_suplementacion i ON h.dni_paciente = i.dni_paciente and h.anio=i.anio

        WHERE h.edad_meses BETWEEN 24 AND 35
          AND h.fecha_hb  <= i.fecha_inicio_suplementacion

    ) t

    WHERE rn = 1
), --select  * from hb_12_23m_primer


/* =========================================
   24-35 MESES
   2do DOSAJE FINAL SUPLEMENTACIÓN
========================================= */

hb_24_35m_segundo_dh AS (

    SELECT *

    FROM (

        SELECT
			h.anio,
			h.mes,
            h.dni_paciente,
            h.fecha_hb,
            h.resultado_hb,

            i.fecha_inicio_suplementacion,
            (h.fecha_hb - i.fecha_inicio_suplementacion) AS dias_desde_inicio_suple,
			case WHEN h.fecha_hb >= i.fecha_inicio_suplementacion + INTERVAL '180 days' THEN 1  ELSE 0 END AS cumple_2da_hb_12_23m,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb DESC
            ) AS rn

        FROM hemoglobina h
        INNER JOIN inicio_suplementacion i ON h.dni_paciente = i.dni_paciente and h.anio=i.anio
        WHERE h.edad_meses BETWEEN 25 AND 35  AND h.fecha_hb >= i.fecha_inicio_suplementacion + INTERVAL '180 days'

    ) t

    WHERE rn = 1
    
),  ---select  * from hb_24_35m_segundo_dh



/* =========================================
   36-59 MESES
   1ER DOSAJE ANTES DE SUPLEMENTACIÓN
========================================= */

hb_36_59m_primer AS (

    SELECT *

    FROM (

        SELECT
			h.anio,
			h.mes,
            h.dni_paciente,
            h.fecha_hb,
            h.resultado_hb,
            i.fecha_inicio_suplementacion,
            (i.fecha_inicio_suplementacion - h.fecha_hb ) AS dias_desde_inicio_suple,
            CASE  WHEN h.fecha_hb <= i.fecha_inicio_suplementacion  THEN 1 ELSE 0 END AS cumple_1ra_hb_36_59m,
            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb DESC
            ) AS rn

        FROM hemoglobina h

        INNER JOIN inicio_suplementacion i ON h.dni_paciente = i.dni_paciente and h.anio=i.anio

        WHERE h.edad_meses BETWEEN 36 AND 59
          AND h.fecha_hb  <= i.fecha_inicio_suplementacion

    ) t

    WHERE rn = 1
), -- select  * from hb_36_59m_primer


/* =========================================
   36-59 MESES
   2do DOSAJE FINAL SUPLEMENTACIÓN
========================================= */

hb_36_59m_segundo_dh AS (

    SELECT *

    FROM (

        SELECT
			h.anio,
			h.mes,
            h.dni_paciente,
            h.fecha_hb,
            h.resultado_hb,

            i.fecha_inicio_suplementacion,
            (h.fecha_hb - i.fecha_inicio_suplementacion) AS dias_desde_inicio_suple,
			case WHEN h.fecha_hb >= i.fecha_inicio_suplementacion + INTERVAL '180 days' THEN 1  ELSE 0 END AS cumple_2da_hb_36_59m,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb DESC
            ) AS rn

        FROM hemoglobina h
        INNER JOIN inicio_suplementacion i ON h.dni_paciente = i.dni_paciente and h.anio=i.anio
        WHERE h.edad_meses BETWEEN 36 AND 59  AND h.fecha_hb >= i.fecha_inicio_suplementacion + INTERVAL '180 days'

    ) t

    WHERE rn = 1
    
), --select  * from hb_36_59m_segundo_dh

/* =========================================
   5-11 AÑOS
   1 MEDICIÓN AL AÑO
========================================= */

hb_5_11a AS (

    SELECT *

    FROM (

        SELECT
			h.anio,
			h.mes,
            h.dni_paciente,
            h.fecha_hb,
            h.resultado_hb,
            h.edad_anios,

            CASE WHEN h.edad_anios BETWEEN 5 AND 11 THEN 1  ELSE 0 END AS cumple_hb_5_11a,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb
            ) AS rn

        FROM hemoglobina h

        WHERE h.edad_anios BETWEEN 5 AND 11

    ) t

    WHERE rn = 1
), --select  * from hb_5_11a

/* =========================================
   ADOLESCENTE MUJER 12-17 AÑOS
   1ER DOSAJE ANTES DE SUPLEMENTACIÓN
========================================= */

hb_adolescente_primer AS (

    SELECT *

    FROM (

        SELECT
			h.anio,
			h.mes,
            h.dni_paciente,
            h.fecha_hb,
            h.resultado_hb,
            i.fecha_inicio_suplementacion,
            (i.fecha_inicio_suplementacion - h.fecha_hb)  AS dias_antes_suple,
            CASE  WHEN h.fecha_hb <= i.fecha_inicio_suplementacion   THEN 1   ELSE 0   END AS cumple_1ra_hb_adolescente,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb DESC
            ) AS rn

        FROM hemoglobina h

        INNER JOIN inicio_suplementacion i ON h.dni_paciente = i.dni_paciente  and h.anio=i.anio

        WHERE h.genero = 'F'
          AND h.edad_anios BETWEEN 12 AND 17
          AND h.fecha_hb <= i.fecha_inicio_suplementacion

    ) t

    WHERE rn = 1
), --select  * from hb_adolescente_primer

/* =========================================
   ADOLESCENTE MUJER 12-17 AÑOS
   2DO DOSAJE AL FINAL SUPLEMENTACIÓN
========================================= */

hb_adolescente_segundo AS (

    SELECT *

    FROM (

        SELECT
			h.anio,
			h.mes,
            h.dni_paciente,
            h.fecha_hb,
            h.resultado_hb,
            i.fecha_inicio_suplementacion,
            (h.fecha_hb - i.fecha_inicio_suplementacion)  AS dias_desde_inicio,

            CASE
                WHEN h.fecha_hb >= i.fecha_inicio_suplementacion + INTERVAL '180 days' THEN 1 ELSE 0 END AS cumple_2da_hb_adolescente,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb DESC
            ) AS rn

        FROM hemoglobina h

        INNER JOIN inicio_suplementacion i ON h.dni_paciente = i.dni_paciente and h.anio=i.anio

        WHERE h.genero = 'F'
          AND h.edad_anios BETWEEN 12 AND 17
          AND h.fecha_hb >=i.fecha_inicio_suplementacion + INTERVAL '180 days'

    ) t

    WHERE rn = 1
),  -- select  * from hb_adolescente_segundo


/* =========================================
   GESTANTES
   1ER DOSAJE EN PRIMER CONTROL
========================================= */

hb_gestante_primer AS (

    SELECT *

    FROM (

        SELECT
			h.anio,
			h.mes,
            h.dni_paciente,
            h.fecha_hb,
            h.resultado_hb,

            case WHEN cf.es_gestante = 1 THEN 1 ELSE 0  END AS cumple_hb_prenatal,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb
            ) AS rn

        FROM hemoglobina h

        INNER JOIN cita_flags_{ANIO} cf  ON h.dni_paciente = cf.dni_paciente and h.anio=cf.anio

        WHERE cf.es_gestante = 1

    ) t

    WHERE rn = 1
), -- select  * from hb_gestante_primer

/* =========================================
   GESTANTES
   2DO DOSAJE SEMANA 25-28
========================================= */

hb_gestante_segundo AS (

    SELECT *

    FROM (

        SELECT

            h.anio,
            h.mes,
            h.dni_paciente,
            h.fecha_hb,
            mat.fecha_ultima_regla,
            h.resultado_hb,
            
            /* =========================================
               SEMANA GESTACIONAL
               FUR -> FECHA HB
            ========================================= */

            (
                (h.fecha_hb::date - mat.fecha_ultima_regla::date) / 7 )::int AS semana_gest,
                (h.fecha_hb::date - mat.fecha_ultima_regla::date)::int AS dias_fech_ult_regla_a_dosaje_hb,

            /* =========================================
               HB ENTRE 25-28 SEMANAS
            ========================================= */

            CASE
                WHEN (
                    (h.fecha_hb::date - mat.fecha_ultima_regla::date) / 7
                )::int BETWEEN 25 AND 28
                THEN 1
                ELSE 0
            END AS cumple_hb_25_28_sem_gest,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb
            ) AS rn

        FROM hemoglobina h

        INNER JOIN cita_flags_{ANIO} cf ON h.dni_paciente = cf.dni_paciente  AND h.anio = cf.anio
        INNER JOIN es_ivan.tabla_materno mat  ON h.dni_paciente = mat.dni_paciente and h.anio = mat.anio

        WHERE cf.es_gestante = 1

          /* SOLO HB ENTRE 25-28 SEMANAS */
          AND (
                (h.fecha_hb::date - mat.fecha_ultima_regla::date) / 7
              )::int BETWEEN 25 AND 28

    ) t

    WHERE rn = 1
), ---SELECT * FROM hb_gestante_segundo


/* =========================================
   GESTANTES
   3ER DOSAJE SEMANA 37-40
========================================= */

hb_gestante_tercero AS (

       SELECT *

    FROM (

        SELECT

            h.anio,
            h.mes,
            h.dni_paciente,
            h.fecha_hb,
            mat.fecha_ultima_regla,
            h.resultado_hb,
            
            /* =========================================
               SEMANA GESTACIONAL
               FUR -> FECHA HB
            ========================================= */

            (
                (h.fecha_hb::date - mat.fecha_ultima_regla::date) / 7 )::int AS semana_gest,
                (h.fecha_hb::date - mat.fecha_ultima_regla::date)::int AS dias_fech_ult_regla_a_dosaje_hb,

            /* =========================================
               HB ENTRE 37-40 SEMANAS
            ========================================= */

            CASE
                WHEN ((h.fecha_hb::date - mat.fecha_ultima_regla::date) / 7)::int BETWEEN 37 AND 40  THEN 1 ELSE 0  END AS cumple_hb_37_40_sem_gest,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb
            ) AS rn

        FROM hemoglobina h

        INNER JOIN cita_flags_{ANIO} cf ON h.dni_paciente = cf.dni_paciente  AND h.anio = cf.anio
        INNER JOIN es_ivan.tabla_materno mat  ON h.dni_paciente = mat.dni_paciente and h.anio = mat.anio

        WHERE cf.es_gestante = 1

          /* SOLO HB ENTRE 37-40 SEMANAS */
          AND (
                (h.fecha_hb::date - mat.fecha_ultima_regla::date) / 7
              )::int BETWEEN 37 AND 40

    ) t

    WHERE rn = 1
), -- select  * from hb_gestante_tercero 

/* =========================================
   PUÉRPERA
   DOSAJE A LOS 30 DÍAS POST PARTO
========================================= */

hb_puerpera AS (

    SELECT
       *
    FROM (

        SELECT

            /* 🔹 AÑO HB */
            h.anio,
            h.mes,
            /* 🔹 DNI MADRE DESDE CNV */
            c.nu_doc_madre AS dni_madre,
            h.dni_paciente,
            h.fecha_hb,
            c.fe_nacido,
            h.resultado_hb,

            /* 🔹 DÍAS POST PARTO */
            (h.fecha_hb::date - c.fe_nacido::date)
                AS dias_post_parto,

            /* 🔹 DOSAJE HB PUÉRPERA 30-35 DÍAS */
            CASE
                WHEN (h.fecha_hb::date - c.fe_nacido::date)
                     BETWEEN 30 AND 35
                THEN 1
                ELSE 0
            END AS cumple_hb_puerpera,

            ROW_NUMBER() OVER (
                PARTITION BY c.nu_doc_madre
                ORDER BY h.fecha_hb
            ) AS rn

        FROM es_ivan.cnv c

        /* 🔹 HEMOGLOBINA DE LA MADRE */
        LEFT JOIN hemoglobina h
               ON c.nu_doc_madre = h.dni_paciente
              AND LEFT(c.periodo::text, 4)::int = h.anio
              AND h.fecha_hb::date > c.fe_nacido::date

        LEFT JOIN cita_flags_{ANIO} cf
               ON h.dni_paciente = cf.dni_paciente
              AND h.anio = cf.anio

        WHERE COALESCE(cf.hb_puerpera,0) = 1

    ) t

    WHERE t.rn = 1
),  --SELECT * FROM hb_puerpera

/* =========================================
   MUJER EN EDAD FÉRTIL
   1 DOSAJE AL AÑO
========================================= */

hb_mef AS (

    SELECT *

    FROM (

        SELECT
			h.anio,
			h.mes,
            h.dni_paciente,
            h.fecha_hb,
            h.resultado_hb,
            h.edad_anios,
            case WHEN h.genero = 'F'  AND h.edad_anios BETWEEN 18 AND 49   THEN 1  ELSE 0  END AS cumple_hb_mef,

            ROW_NUMBER() OVER (
                PARTITION BY h.dni_paciente
                ORDER BY h.fecha_hb
            ) AS rn

        FROM hemoglobina h
        left join cita_flags_{ANIO} g on h.dni_paciente=g.dni_paciente

        WHERE h.genero = 'F' and g.condicion_gestante=''
          AND h.edad_anios BETWEEN 18 AND 49

    ) t

    WHERE rn = 1
)  -- select  * from hb_mef
/* =========================================
   RESULTADO FINAL MONITOREO
========================================= */

SELECT

    p.anio,
    p.mes,

    p.red,
    p.desc_ue,
    p.microred,
    p.provincia,
    p.distrito,
    p.cod_2000,
    p.nombre_establecimiento,

    /* =====================================
       PADRÓN
       
    ===================================== */

    COUNT(DISTINCT p.dni_paciente) AS padron_total,

    
    /* =====================================
   BPN / PREMATUROS
===================================== */

COUNT(DISTINCT tb.dni_paciente) AS total_ninos_bpn,
COUNT(DISTINCT CASE 
        WHEN tb.total_ninos_bpn_30_59_dias = 1 
        THEN tb.dni_paciente 
    END) AS total_ninos_bpn_30_59_dias,

COUNT(DISTINCT p1.dni_paciente) AS primera_entrega_bpn,

COUNT(DISTINCT CASE
        WHEN s2.cumple_segunda_entrega_bpn = 1
        THEN s2.dni_paciente
    END) AS segunda_entrega_bpn,

COUNT(DISTINCT CASE
        WHEN t3.cumple_tercera_entrega_bpn = 1
        THEN t3.dni_paciente
    END) AS tercera_entrega_bpn,

COUNT(DISTINCT CASE
        WHEN dh1.cumple_primer_dosaje_hb_bpn = 1
        THEN dh1.dni_paciente
    END) AS primer_dosaje_hb_bpn,

COUNT(DISTINCT CASE
        WHEN dh2.cumple_segundo_dosaje_hb_bpn = 1
        THEN dh2.dni_paciente
    END) AS segundo_dosaje_hb_bpn,
    
    
    /* =====================================
       6-11 MESES HEMOGLOBINA
    ===================================== */

    COUNT(DISTINCT hb_6_11_1.dni_paciente) AS hb_6_11m_primer,
    COUNT(DISTINCT hb_6_11_2.dni_paciente) AS hb_6_11m_segundo,

    /* =====================================
       12-23 MESES HEMOGLOBINA
    ===================================== */

    COUNT(DISTINCT hb_12_23_1.dni_paciente) AS hb_12_23m_primer,
    COUNT(DISTINCT hb_12_23_2.dni_paciente) AS hb_12_23m_segundo,
    COUNT(DISTINCT hb_12_23_3.dni_paciente) AS hb_12_23m_tercer,

    /* =====================================
       24-35 MESES HEMOGLOBINA
    ===================================== */

    COUNT(DISTINCT hb_24_35_1.dni_paciente) AS hb_24_35m_primer,
    COUNT(DISTINCT hb_24_35_2.dni_paciente) AS hb_24_35m_segundo,

    /* =====================================
       36-59 MESES HEMOGLOBINA
    ===================================== */

    COUNT(DISTINCT hb_36_59_1.dni_paciente) AS hb_36_59m_primer,
    COUNT(DISTINCT hb_36_59_2.dni_paciente) AS hb_36_59m_segundo,

    /* =====================================
       5-11 AÑOS HEMOGLOBINA
    ================== =================== */

    COUNT(DISTINCT hb_5_11.dni_paciente) AS hb_5_11a,

    /* =====================================
       ADOLESCENTE MUJER HEMOGLOBINA
    ===================================== */

    COUNT(DISTINCT hb_adol_1.dni_paciente) AS hb_adolescente_primer,
    COUNT(DISTINCT hb_adol_2.dni_paciente) AS hb_adolescente_segundo,

    /* =============== ======================
       GESTANTES HEMOGLOBINA
    ===================================== */

    COUNT(DISTINCT hb_gest_1.dni_paciente) AS hb_gestante_primer,
    COUNT(DISTINCT hb_gest_2.dni_paciente) AS hb_gestante_segundo,
    COUNT(DISTINCT hb_gest_3.dni_paciente) AS hb_gestante_tercero,

    /* =====================================
       PUÉRPERAS HEMOGLOBINA
    ===================================== */

    COUNT(DISTINCT hb_p.dni_madre) AS hb_puerpera,

    /* =====================================
       MUJER EN EDAD FÉRTIL HEMOGLOBINA
    ===================================== */

    COUNT(DISTINCT hb_mef.dni_paciente) AS hb_mef

FROM poblacion p

/* =====================================
   BPN / PREMATUROS
===================================== */

LEFT JOIN totales_bpn tb
       ON p.dni_paciente = tb.dni_paciente
      AND p.anio = tb.anio

LEFT JOIN primera_entrega_bpn p1
       ON p.dni_paciente = p1.dni_paciente
      AND p.anio = p1.anio

LEFT JOIN segunda_entrega_bpn s2
       ON p.dni_paciente = s2.dni_paciente
      AND p.anio = s2.anio

LEFT JOIN tercera_entrega_bpn t3
       ON p.dni_paciente = t3.dni_paciente
      AND p.anio = t3.anio

LEFT JOIN primer_dosaje_hb_bpn dh1
       ON p.dni_paciente = dh1.dni_paciente
      AND p.anio = dh1.anio

LEFT JOIN segundo_dosaje_hb_bpn dh2
       ON p.dni_paciente = dh2.dni_paciente
      AND p.anio = dh2.anio

/* =====================================
   6-11M
===================================== */

left join hb_6_11m_primer hb_6_11_1
       ON p.dni_paciente = hb_6_11_1.dni_paciente
      AND p.anio = hb_6_11_1.anio
      AND p.mes  = hb_6_11_1.mes
      AND hb_6_11_1.cumple_1er_hb = 1

LEFT JOIN hb_6_11m_segundo hb_6_11_2
       ON p.dni_paciente = hb_6_11_2.dni_paciente
       AND p.anio = hb_6_11_2.anio
      AND p.mes  = hb_6_11_2.mes
      AND hb_6_11_2.cumple_2da_hb = 1

/* =====================================
   12-23M
===================================== */

LEFT JOIN hb_12_23m_primer hb_12_23_1
       ON p.dni_paciente = hb_12_23_1.dni_paciente 
      AND p.anio = hb_12_23_1.anio
      AND p.mes  =hb_12_23_1.mes
      AND hb_12_23_1.cumple_1ra_hb_12_23m = 1  

LEFT JOIN hb_12_23m_segundo hb_12_23_2
       ON p.dni_paciente = hb_12_23_2.dni_paciente
       AND p.anio = hb_12_23_2.anio
      AND p.mes  =hb_12_23_2.mes
      AND hb_12_23_2.cumple_2da_hb_12_23m = 1

LEFT JOIN hb_12_23m_tercer_dh hb_12_23_3
       ON p.dni_paciente = hb_12_23_3.dni_paciente
        AND p.anio = hb_12_23_3.anio
      AND p.mes  =hb_12_23_3.mes
      AND hb_12_23_3.cumple_2da_hb_12_23m = 1

/* =====================================
   24-35M
===================================== */

LEFT JOIN hb_24_35m_primer hb_24_35_1
       ON p.dni_paciente = hb_24_35_1.dni_paciente
       AND p.anio = hb_24_35_1.anio
      AND p.mes  =hb_24_35_1.mes
      AND hb_24_35_1.cumple_1ra_hb_24_35m = 1

LEFT JOIN hb_24_35m_segundo_dh hb_24_35_2
       ON p.dni_paciente = hb_24_35_2.dni_paciente
        AND p.anio = hb_24_35_2.anio
      AND p.mes  =hb_24_35_2.mes
      AND hb_24_35_2.cumple_2da_hb_12_23m = 1

/* =====================================
   36-59M
===================================== */

LEFT JOIN hb_36_59m_primer hb_36_59_1
       ON p.dni_paciente = hb_36_59_1.dni_paciente
      AND p.anio = hb_36_59_1.anio
      AND p.mes  =hb_36_59_1.mes
      AND hb_36_59_1.cumple_1ra_hb_36_59m = 1

LEFT JOIN hb_36_59m_segundo_dh hb_36_59_2
       ON p.dni_paciente = hb_36_59_2.dni_paciente
       AND p.anio = hb_36_59_2.anio
      AND p.mes  =hb_36_59_2.mes
      AND hb_36_59_2.cumple_2da_hb_36_59m = 1

/* =====================================
   5-11 AÑOS
===================================== */

LEFT JOIN hb_5_11a hb_5_11
       ON p.dni_paciente = hb_5_11.dni_paciente
         AND p.anio = hb_5_11.anio
      AND p.mes  =hb_5_11.mes
      AND hb_5_11.cumple_hb_5_11a = 1

/* =====================================
   ADOLESCENTES
===================================== */

LEFT JOIN hb_adolescente_primer hb_adol_1
       ON p.dni_paciente = hb_adol_1.dni_paciente
      AND p.anio = hb_adol_1.anio
      AND p.mes  =hb_adol_1.mes
      AND hb_adol_1.cumple_1ra_hb_adolescente = 1

LEFT JOIN hb_adolescente_segundo hb_adol_2
       ON p.dni_paciente = hb_adol_2.dni_paciente
       AND p.anio = hb_adol_2.anio
      AND p.mes  =hb_adol_2.mes
      AND hb_adol_2.cumple_2da_hb_adolescente = 1

/* =====================================
   GESTANTES
===================================== */

LEFT JOIN hb_gestante_primer hb_gest_1
       ON p.dni_paciente = hb_gest_1.dni_paciente
      AND p.anio = hb_gest_1.anio
      AND p.mes  = hb_gest_1.mes
      AND hb_gest_1.cumple_hb_prenatal = 1

LEFT JOIN hb_gestante_segundo hb_gest_2
       ON p.dni_paciente = hb_gest_2.dni_paciente
      AND p.anio = hb_gest_2.anio
      AND p.mes  = hb_gest_2.mes
      AND hb_gest_2.cumple_hb_25_28_sem_gest = 1

LEFT JOIN hb_gestante_tercero hb_gest_3
       ON p.dni_paciente = hb_gest_3.dni_paciente
      AND p.anio = hb_gest_3.anio
      AND p.mes  = hb_gest_3.mes
      AND hb_gest_3.cumple_hb_37_40_sem_gest = 1

/* =====================================
   PUÉRPERAS
===================================== */

LEFT JOIN hb_puerpera hb_p
       ON p.dni_paciente = hb_p.dni_paciente
      AND p.anio = hb_p.anio
      AND p.mes  = hb_p.mes
      AND hb_p.cumple_hb_puerpera = 1

/* =====================================
   MUJERES EN EDAD FÉRTIL
===================================== */

LEFT JOIN hb_mef hb_mef
       ON p.dni_paciente = hb_mef.dni_paciente
        AND p.anio =hb_mef.anio
      AND p.mes  =hb_mef.mes
      AND hb_mef.cumple_hb_mef = 1

GROUP BY

    p.anio,
    p.mes,
    p.red,
    p.desc_ue,
    p.microred,
    p.provincia,
    p.distrito,
    p.cod_2000,
    p.nombre_establecimiento

ORDER BY

    p.anio,
    p.mes,
    p.red,
    p.microred,
    p.nombre_establecimiento;



--- GENEREAR REPORTES PARA OCULAR MENTAL  

 
   DROP TABLE IF EXISTS es_ivan.cred{ANIO}_3;

    -- 2️⃣ Eliminar tabla temporal si existe


CREATE TABLE es_ivan.cred{ANIO}_3 AS

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
    WHERE anio >= {ANIO_MENOS_1}
      /*AND codigo_item IN ('99199.26','99403','99403.01','99436','99381.01','99401.03','99411.01','99431','J00X','P599','J029','99381','99382','99383','C8002','Z001',
      						'99401.05','99401.07','99401.08','99401.09','99401.12','99401.16','99401.24','99401.25','99403.01','99401.03','P929','99211','99211','99199.17','R620','R628','E440',
      						'E669','E6690','E45X','E43X','E344','87177.01','B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664','87178',
      						'B80X','99199.28','C0011','85018.01','P070','P071','P0711','P0712','P0713','P072','P073','U1692','59430','U140','R456','Z720','Z721','Z722','Z133',
      						'H351','H351','H579','H579','Z010','PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527'
							'67228','67229','92390','99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10',
                            '96150.02','67043','99173','D1330','D1286','D1110','D1351')  */

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
    DROP TABLE IF EXISTS es_ivan.cred{ANIO}_4;

    -- 2️⃣ Eliminar tabla temporal si existe


CREATE TABLE es_ivan.cred{ANIO}_4 AS

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
    WHERE anio >= {ANIO_MENOS_1}
     /*AND codigo_item IN ('99199.26','99403','99403.01','99436','99381.01','99401.03','99411.01','99431','J00X','P599','J029','99381','99382','99383','C8002','Z001',
      						'99401.05','99401.07','99401.08','99401.09','99401.12','99401.16','99401.24','99401.25','99403.01','99401.03','P929','99211','99211','99199.17','R620','R628','E440',
      						'E669','E6690','E45X','E43X','E344','87177.01','B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664','87178',
      						'B80X','99199.28','C0011','85018.01','P070','P071','P0711','P0712','P0713','P072','P073','U1692','59430','U140','R456','Z720','Z721','Z722','Z133',
      						'H351','H351','H579','H579','Z010','PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527'
							'67228','67229','92390','99499.08','99499.09','99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10') */

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
 
-----REPORTE DE VACUNACION {ANIO} 

----
--generar tabla pai
    DROP TABLE IF EXISTS es_ivan.pai_{ANIO};
	CREATE TABLE es_ivan.pai_{ANIO} AS
-- ============================================
-- 🔥 BASE MINIMA (SOLO LO NECESARIO)
-- ============================================
WITH base AS (
    SELECT 
        id_cita,
        id_establecimiento,
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
    WHERE anio >= {ANIO_MENOS_1}
      /* AND codigo_item IN ('90585','90633.01','90648','90649','90657','90658','90669','90670',
   							 '90681','90687','90688','90701','90702','90707','90712','90713','90714',
   							 '90715','90716','90717','90722','90723','90744','90746','Z238','Z2511','99199.26','99403','99403.01','99436','99381.01','99401.03','99411.01','99431','J00X','P599','J029','99381','99382','99383','C8002','Z001',
      						'99401.05','99401.07','99401.08','99401.09','99401.12','99401.16','99401.24','99401.25','99403.01','99401.03','P929','99211','99211','99199.17','R620','R628','E440',
      						'E669','E6690','E45X','E43X','E344','87177.01','B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664','87178',
      						'B80X','99199.28','C0011','85018.01','P070','P071','P0711','P0712','P0713','P072','P073','U1692','59430','U140','R456','Z720','Z721','Z722','Z133',
      						'H351','H351','H579','H579','Z010','PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527'
							'67228','67229','92390','99499.08','99499.09','99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10') */

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
	h.id_establecimiento,
	h.cod_2000,
	h.red,
	h.desc_ue,
	h.microred,
	h.provincia,
	h.distrito,
	h.nombre_establecimiento,



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

----vacunacion  VPH
SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('1','D1') AND  h.genero = 'F' AND h.edad < 9 THEN 1 ELSE 0 END) AS vph1_fem_men9a,
SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('2','D2') AND  h.genero = 'F' AND h.edad < 9 THEN 1 ELSE 0 END) AS vph2_fem_men9a,
SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('DU','')  AND   h.genero = 'M' AND h.edad < 9 THEN 1 ELSE 0 END) AS vph3_mas_men9a,
SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('1','D1') AND  h.genero = 'F' AND h.edad BETWEEN 9 AND 13 THEN 1 ELSE 0 END) AS vph1_fem_9_13a,
SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('2','D2') AND  h.genero = 'F' AND h.edad BETWEEN 9 AND 13 THEN 1 ELSE 0 END) AS vph2_fem_9_13a,
SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('DU','')  AND   h.genero = 'M' AND h.edad BETWEEN 9 AND 13 THEN 1 ELSE 0 END) AS vph3_mas_9_13a,
SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('1','D1') AND  h.genero = 'F' AND h.edad >= 14 THEN 1 ELSE 0 END) AS vph1_fem_may_14a,
SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('2','D2') AND  h.genero = 'F' AND h.edad >= 14 THEN 1 ELSE 0 END) AS vph2_fem_may_14a,
SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('DU','')  AND   h.genero = 'M' AND h.edad >= 14 THEN 1 ELSE 0 END) AS vph3_mas_may_14a,
SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('DU','')  AND   h.edad BETWEEN 9 AND 18 THEN 1 ELSE 0 END) AS vph1_mas_9_18a,
SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('DU','')  AND   h.edad BETWEEN 9 AND 18 THEN 1 ELSE 0 END) AS vph2_mas_9_18a,
SUM(CASE WHEN h.codigo_item = '90649' AND h.valor_lab IN ('DU','')  AND   h.edad BETWEEN 9 AND 18 THEN 1 ELSE 0 END) AS vph3_mas_9_18a,

--SELECT * from es_ivan.tabla_vacunas h
--where h.codigo_item = '90649' AND h.valor_lab IN ('1','D1')  AND h.genero = 'F' AND h.edad >= 14

----INFLUENZA POR GRUPO  ETAREOS 

SUM(CASE WHEN h.codigo_item IN ('90657','90658','Z2511','90687','90688') AND h.valor_lab IN ('1','D1','D2','DU','DA','DAA','') AND f.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS influ1_5_11a_comorb,
SUM(CASE WHEN h.codigo_item IN ('90657','90658','Z2511','90687','90688') AND h.valor_lab IN ('1','D1','D2','DU','DA','DAA','') AND f.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS influ1_12_17a_mas_comorb,
SUM(CASE WHEN h.codigo_item IN ('90657','90658','Z2511','90687','90688') AND h.valor_lab IN ('1','D1','D2','DU','DA','DAA','') AND f.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS influ1_18_29a_mas_comorb,
SUM(CASE WHEN h.codigo_item IN ('90657','90658','Z2511','90687','90688') AND h.valor_lab IN ('1','D1','D2','DU','DA','DAA','') AND f.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS influ1_30_49a_mas_comorb,
SUM(CASE WHEN h.codigo_item IN ('90657','90658','Z2511','90687','90688') AND h.valor_lab IN ('1','D1','D2','DU','DA','DAA','') AND f.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 50 AND 59 THEN 1 ELSE 0 END) AS influ1_50_59a_mas_comorb,

SUM(CASE WHEN h.codigo_item IN ('90657','90658','Z2511','90687','90688') AND h.valor_lab IN ('1','D1','D2','DU','DA','DAA','') AND f.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS influ1_5_11a_sin_comorb,
SUM(CASE WHEN h.codigo_item IN ('90657','90658','Z2511','90687','90688') AND h.valor_lab IN ('1','D1','D2','DU','DA','DAA','') AND f.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS influ1_12_17a_sin_comorb,
SUM(CASE WHEN h.codigo_item IN ('90657','90658','Z2511','90687','90688') AND h.valor_lab IN ('1','D1','D2','DU','DA','DAA','') AND f.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS influ1_18_29a_sin_comorb,
SUM(CASE WHEN h.codigo_item IN ('90657','90658','Z2511','90687','90688') AND h.valor_lab IN ('1','D1','D2','DU','DA','DAA','') AND f.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS influ1_30_49a_sin_comorb,
SUM(CASE WHEN h.codigo_item IN ('90657','90658','Z2511','90687','90688') AND h.valor_lab IN ('1','D1','D2','DU','DA','DAA','') AND f.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 50 AND 59 THEN 1 ELSE 0 END) AS influ1_50_59a_sin_comorb,

SUM(CASE WHEN h.codigo_item IN ('90657','90658','Z2511','90687','90688') AND h.valor_lab IN ('1','D1','D2','DU','DA','DAA','') AND h.edad >= 60 THEN 1 ELSE 0 END) AS influ1_60a_mas,

SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab in('1','D1','DU','') AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS gestante_Tdap1_10_11a,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab in('1','D1','DU','') AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS gestante_Tdap1_12_17a,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab in('1','D1','DU','') AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS gestante_Tdap1_18_29a,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab in('1','D1','DU','') AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS gestante_Tdap1_30_49a,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab in('1','D1','DU','') AND h.edad BETWEEN 50 AND 60 THEN 1 ELSE 0 END) AS gestante_Tdap1_50_60a,
SUM(CASE WHEN ci.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab in('1','D1','DU','') AND h.edad>=10 THEN 1 ELSE 0 END) AS gestante_total_Tdap1


FROM base h
LEFT JOIN cita_flags_{ANIO} ci ON h.id_cita = ci.id_cita
LEFT JOIN flags_cita f ON h.id_cita = f.id_cita

GROUP BY 

    h.anio,
    h.mes,
	h.id_establecimiento,
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
    m.id_establecimiento,
    m.cod_2000,
    m.red,
	m.desc_ue,
	m.microred,
	m.provincia,
	m.distrito,
    m.nombre_establecimiento,

    
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
m.vph3_mas_may_14a,
m.vph1_mas_9_18a,
m.vph2_mas_9_18a,
m.vph3_mas_9_18a,
----INFLUENZA POR GRUPO  ETAREOS 

m.influ1_5_11a_comorb,
m.influ1_12_17a_mas_comorb,
m.influ1_18_29a_mas_comorb,
m.influ1_30_49a_mas_comorb,
m.influ1_50_59a_mas_comorb,

m.influ1_5_11a_sin_comorb,
m.influ1_12_17a_sin_comorb,
m.influ1_18_29a_sin_comorb,
m.influ1_30_49a_sin_comorb,
m.influ1_50_59a_sin_comorb,
m.influ1_60a_mas,
m.gestante_Tdap1_10_11a,
m.gestante_Tdap1_12_17a,
m.gestante_Tdap1_18_29a,
m.gestante_Tdap1_30_49a,
m.gestante_Tdap1_50_60a,
m.gestante_total_Tdap1


	
    
FROM monitoreo_general m
ORDER BY m.cod_2000, m.anio, m.mes;


----GENERAR TABLA PAI_{ANIO}_2 
--generar tabla pai
    DROP TABLE IF EXISTS es_ivan.pai_{ANIO}_1;
	CREATE TABLE es_ivan.pai_{ANIO}_1 AS
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
        id_establecimiento,
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
    WHERE anio >= {ANIO_MENOS_1}
      /*AND codigo_item IN ('90585','90633.01','90648','90649','90657','90658','90669','90670',
   							 '90681','90687','90688','90701','90702','90707','90712','90713','90714',
   							 '90715','90716','90717','90722','90723','90744','90746','Z238','Z2511','99199.26','99403','99403.01','99436','99381.01','99401.03','99411.01','99431','J00X','P599','J029','99381','99382','99383','C8002','Z001',
      						'99401.05','99401.07','99401.08','99401.09','99401.12','99401.16','99401.24','99401.25','99403.01','99401.03','P929','99211','99211','99199.17','R620','R628','E440',
      						'E669','E6690','E45X','E43X','E344','87177.01','B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829','A070','A071','A06','B663','B664','87178',
      						'B80X','99199.28','C0011','85018.01','P070','P071','P0711','P0712','P0713','P072','P073','U1692','59430','U140','R456','Z720','Z721','Z722','Z133',
      						'H351','H351','H579','H579','Z010','PH538','PH509','PH530','PH559','PH179','PH029','PH028','PH527'
							'67228','67229','92390','99499.08','99499.09','99499.01','99499.02','99499.03','99499.04','99499.05','99499.06','99499.07','99499.08','99499.09','99499.10') */

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
SUM(CASE WHEN h.genero = 'M' AND h.codigo_item = '90714' AND h.valor_lab IN ('3','D3') AND h.edad >= 60 THEN 1 ELSE 0 END) AS varones_dt3_60a_mas



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
	m.varones_dt3_60a_mas
	    
FROM monitoreo_general m
ORDER BY m.cod_2000, m.anio, m.mes;




END;
$$;

CALL es_ivan.sp_generar_cred_{ANIO}();