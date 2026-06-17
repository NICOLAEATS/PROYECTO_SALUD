/*CREATE INDEX idx_his_base
ON es_ivan.his_proceso2024 (anio, id_cita, codigo_item, valor_lab);

CREATE INDEX idx_his_edad
ON es_ivan.his_proceso2024 (tip_edad, edad);  */

DELETE FROM es_ivan.VACUNAS_2026
WHERE anio = 2026;

INSERT INTO es_ivan.VACUNAS_2026 

WITH base AS (
    select  
        h.id_cita,
        h.anio,
        h.mes,
        h.cod_2000,
        h.red,
        h.nombre_establecimiento,
        h.codigo_item,
        h.valor_lab,
        h.tipo_diagnostico,
        h.tip_edad,
        h.edad,
        h.genero,
        h.id_etnia,
        h.fg_tipo
    FROM es_ivan.his_proceso h
    WHERE h.anio=2026
      AND h.tipo_diagnostico = 'D'
),

-- 🔹 gestante POR CITA
gestante_flag AS (
    SELECT 
        b.id_cita,
        MAX(
            CASE 
                WHEN b.genero = 'F'
                     AND NOT (b.codigo_item = 'U1692' AND b.valor_lab = 'TA')
                THEN 1
                ELSE 0
            END
        ) AS es_gestante
    FROM es_ivan.tabla_materno b
    GROUP BY b.id_cita
),

---puerpera POR CITA
puerpera_flag AS (
    SELECT 
        b.id_cita,
        MAX(
            CASE 
                WHEN b.genero = 'F'
                     AND (b.codigo_item = '59430'
                          OR b.valor_lab = 'P')
                THEN 1 
                ELSE 0 
            END
        ) AS es_puerpera
    FROM es_ivan.tabla_materno b
    GROUP BY b.id_cita
),


-- 🔹 Bandera de condiciones por CITA
flags_cita AS (
    SELECT
        id_cita,
        MAX(CASE WHEN fg_tipo = 'CX' THEN 1 ELSE 0 END) AS flg_comorbilidad,
        MAX(CASE WHEN valor_lab = 'ST' THEN 1 ELSE 0 END) AS flg_st,
        MAX(CASE WHEN valor_lab = 'OM' THEN 1 ELSE 0 END) AS flg_OM,
        MAX(CASE WHEN valor_lab = 'VIH' THEN 1 ELSE 0 END) AS flg_vih,
        MAX(CASE WHEN valor_lab = 'VPH' THEN 1 ELSE 0 END) AS flg_VPH,
        MAX(CASE WHEN valor_lab = 'AER' THEN 1 ELSE 0 END) AS flg_AER,
        MAX(CASE WHEN valor_lab = 'TER' THEN 1 ELSE 0 END) AS flg_TER,
        MAX(CASE WHEN valor_lab = 'FRON' THEN 1 ELSE 0 END) AS flg_FRO,
        MAX(CASE WHEN valor_lab = 'RSA' THEN 1 ELSE 0 END) AS flg_RSA,
        MAX(CASE WHEN valor_lab = 'END' THEN 1 ELSE 0 END) AS flg_END,  --ZONAS ENDEMICAS
        MAX(CASE WHEN valor_lab = 'FNI' THEN 1 ELSE 0 END) AS flg_FNI,  --FNOMENO  DEL  NIÑO
        MAX(CASE WHEN valor_lab = 'PNP' THEN 1 ELSE 0 END) AS flg_PNP,
        MAX(CASE WHEN valor_lab = 'M' THEN 1 ELSE 0 END) AS flg_M,
        MAX(CASE WHEN valor_lab = 'EF' THEN 1 ELSE 0 END) AS flg_EF,
        MAX(CASE WHEN valor_lab = 'BOM' THEN 1 ELSE 0 END) AS flg_BOM,
        MAX(CASE WHEN valor_lab = 'DCI' THEN 1 ELSE 0 END) AS flg_DCI,
        MAX(CASE WHEN valor_lab = 'EST' THEN 1 ELSE 0 END) AS flg_EST,
        MAX(CASE WHEN valor_lab = 'CR' THEN 1 ELSE 0 END) AS flg_CR,
        MAX(CASE WHEN valor_lab in('IN','PPL') THEN 1 ELSE 0 END) AS flg_INPE_PPL,
        MAX(CASE WHEN valor_lab = 'REH' THEN 1 ELSE 0 END) AS flg_REH,
        MAX(CASE WHEN valor_lab in ('RS','RSA','RMA') THEN 1 ELSE 0 END) AS flg_HF,
        MAX(CASE WHEN valor_lab in ('SR') THEN 1 ELSE 0 END) AS flg_SR,
        MAX(CASE WHEN valor_lab in ('DIS') THEN 1 ELSE 0 END) AS flg_DIS,
        MAX(CASE WHEN valor_lab in ('TS','HSH','HTS','TTS','PNP','M','BOM','DCI','EST','TRA','PPL','G','P','OTR','VIH','OM') THEN 1 ELSE 0 END) AS flg_OTR,
        MAX(CASE WHEN valor_lab IN ('E1','DE1','E2','DE2','E3','DE3','E4','DE4') THEN 1 ELSE 0 END) AS flg_ENF,
        MAX(CASE WHEN id_etnia IN ('56','57','58','59','60') THEN 1 ELSE 0 END) AS flg_etnia
    FROM base
    GROUP BY id_cita
)


SELECT
    h.anio,
    h.mes,
    h.cod_2000 AS codigo_establecimiento,
    h.red,
    h.nombre_establecimiento,

     
 --   DT – GESTANTES (código 90714)
SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS gestantes_dt1_10_11,
SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS gestantes_dt2_10_11,
SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS gestantes_dt3_10_11,

SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS gestantes_dt1_12_17,
SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS gestantes_dt2_12_17,
SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS gestantes_dt3_12_17,

SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS gestantes_dt1_18_29,
SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS gestantes_dt2_18_29,
SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS gestantes_dt3_18_29,

SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS gestantes_dt1_30_49,
SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS gestantes_dt2_30_49,
SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS gestantes_dt3_30_49,

SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab = '1' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS gestante_Tdap1_10_11a,
SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab = '1' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS gestante_Tdap1_12_17a,
SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab = '1' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS gestante_Tdap1_18_29a,
SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab = '1' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS gestante_Tdap1_30_49a,
SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item = '90715' AND h.valor_lab = '1' AND h.edad BETWEEN 50 AND 60 THEN 1 ELSE 0 END) AS gestante_Tdap1_50_60a,

   
 SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS no_gestantes_dt1_10_11,
SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS no_gestantes_dt2_10_11,
SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 10 AND 11 THEN 1 ELSE 0 END) AS no_gestantes_dt3_10_11,

SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS no_gestantes_dt1_12_17,
SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS no_gestantes_dt2_12_17,
SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS no_gestantes_dt3_12_17,

SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS no_gestantes_dt1_18_29,
SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS no_gestantes_dt2_18_29,
SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS no_gestantes_dt3_18_29,

SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS no_gestantes_dt1_30_49,
SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS no_gestantes_dt2_30_49,
SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS no_gestantes_dt3_30_49,

SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad BETWEEN 50 AND 59 THEN 1 ELSE 0 END) AS no_gestantes_dt1_50_59,
SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad BETWEEN 50 AND 59 THEN 1 ELSE 0 END) AS no_gestantes_dt2_50_59,
SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad BETWEEN 50 AND 59 THEN 1 ELSE 0 END) AS no_gestantes_dt3_50_59,

SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '1' AND h.edad >= 60 THEN 1 ELSE 0 END) AS no_gestantes_dt1_may_60a,
SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '2' AND h.edad >= 60 THEN 1 ELSE 0 END) AS no_gestantes_dt2_may_60a,
SUM(CASE WHEN g.es_gestante = 0 AND h.codigo_item = '90714' AND h.valor_lab = '3' AND h.edad >= 60 THEN 1 ELSE 0 END) AS no_gestantes_dt3_may_60a,

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
SUM(CASE WHEN h.codigo_item = '90585' AND COALESCE(TRIM(h.valor_lab), '') IN ('', 'DU', '1', 'D1') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS bcg_12horas,
SUM(CASE WHEN h.codigo_item = '90585' AND COALESCE(TRIM(h.valor_lab), '') IN ('1', 'D1') AND h.tip_edad = 'D' AND h.edad BETWEEN 2 AND 29 THEN 1 ELSE 0 END) AS bcg_12_24h,
SUM(CASE WHEN h.codigo_item = '90585' AND COALESCE(TRIM(h.valor_lab), '') IN ('1', 'D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS bcg_1_11m,

-- HVB
SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('', 'DU') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS hvb_12_24h,
SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('1', 'D1') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS hvb_24h,

-- PENTA
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna Penta1 men_1a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna Penta2 men_1a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna Penta3 men_1a",

-- IPV
SUM(CASE WHEN h.codigo_item = '90713' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna Ipv1 men_1a",
SUM(CASE WHEN h.codigo_item = '90713' AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna Ipv2 men_1a",
SUM(CASE WHEN h.codigo_item = '90713' AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna Ipv3 men_1a",

-- Neumococo
SUM(CASE WHEN h.codigo_item = '90670' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna neumo1 men_1a",
SUM(CASE WHEN h.codigo_item = '90670' AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna neumo2 men_1a",

-- Rotavirus
SUM(CASE WHEN h.codigo_item = '90681' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna rotav1 men_1a",
SUM(CASE WHEN h.codigo_item = '90681' AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna rotav2 men_1a",

-- Influenza
SUM(CASE WHEN h.codigo_item = '90657' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna influenza1 men_1a",
SUM(CASE WHEN h.codigo_item = '90657' AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna influenza2 men_1a",

-- DT pediátrico
SUM(CASE WHEN h.codigo_item = '90702' AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico2 men_1a",
SUM(CASE WHEN h.codigo_item = '90702' AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico3 men_1a",

-- HIB
SUM(CASE WHEN h.codigo_item = '90648' AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna hib2 men_1a",
SUM(CASE WHEN h.codigo_item = '90648' AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna hib3 men_1a",

-- Hepatitis B
SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna HVB2 men_1a",
SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna HVB3 men_1a",

-- VACUNACIÓN 1 AÑO
SUM(CASE WHEN h.codigo_item IN ('90717') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna AMA1 1a",
SUM(CASE WHEN h.codigo_item IN ('90633.01') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna Hepatitis1 A 1a",
SUM(CASE WHEN h.codigo_item IN ('90670') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "NEUMO1 1a",

SUM(CASE WHEN h.codigo_item IN ('90707') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna SPR1 1a",
SUM(CASE WHEN h.codigo_item IN ('90707') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna SPR2 1a",

SUM(CASE WHEN h.codigo_item IN ('90716') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna VARICELA1 1a",

SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90687') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna influenza1 1a",
SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90687') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna influenza2 1a",
SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90687') AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','DA','DDA') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna influenza DU 1a",

SUM(CASE WHEN h.codigo_item IN ('90701') AND COALESCE(TRIM(h.valor_lab), '') IN ('DA','DDA') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna DPT1 1a",

SUM(CASE WHEN h.codigo_item IN ('90712','90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('DA','DDA') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna APO_IPV 1a",

SUM(CASE WHEN h.codigo_item IN ('90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna IPV1 1a",
SUM(CASE WHEN h.codigo_item IN ('90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna IPV2 1a",

SUM(CASE WHEN h.codigo_item IN ('90712','90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna APO3 1a",

SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna Penta1 1a",

SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna Penta2 1a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna Penta3 1a",

SUM(CASE WHEN h.codigo_item IN ('90702') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico2 1a",
SUM(CASE WHEN h.codigo_item IN ('90702') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico3 1a",

SUM(CASE WHEN h.codigo_item IN ('90648') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna hib2 1a",
SUM(CASE WHEN h.codigo_item IN ('90648') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna hib3 1a",

SUM(CASE WHEN h.codigo_item IN ('90744') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna HVB2 1a",
SUM(CASE WHEN h.codigo_item IN ('90744') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna HVB3 1a",

SUM(CASE WHEN h.codigo_item IN ('90585') AND h.tip_edad = 'A' AND h.edad = 1 THEN 1 ELSE 0 END) AS "BCG Contacto de TB P 1a",

---VACUNACION  DE 2 AÑO

SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 1 AND h.edad = 2 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS "influenza1_con_morbi 2a",
SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 0 AND h.edad = 2 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS "influenza1 sin morbi 2a",

SUM(CASE WHEN h.codigo_item IN ('90669','90670','Z238') AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','DA','DAA') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Neumococo con Comorbilidad 2a",

SUM(CASE WHEN h.codigo_item IN ('90717') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna AMA 2a",

-- trazador
SUM(CASE WHEN h.codigo_item IN ('90657') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "3325405 Vacuna influenza1 2a",
SUM(CASE WHEN h.codigo_item IN ('90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna IPV1 2a",
SUM(CASE WHEN h.codigo_item IN ('90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna IPV2 2a",

SUM(CASE WHEN h.codigo_item IN ('90712','90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna APO3 2a",

SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna Penta1 2a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna Penta2 2a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna Penta3 2a",

SUM(CASE WHEN h.codigo_item IN ('90702') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D3') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico2 2a",
SUM(CASE WHEN h.codigo_item IN ('90702') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico3 2a",

SUM(CASE WHEN h.codigo_item IN ('90648') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna hib2 2a",
SUM(CASE WHEN h.codigo_item IN ('90648') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna hib3 2a",

SUM(CASE WHEN h.codigo_item IN ('90744') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna HVB2 2a",
SUM(CASE WHEN h.codigo_item IN ('90744') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna HVB3 2a",

SUM(CASE WHEN h.codigo_item IN ('90585') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "BCG (Contacto de TB P) 2a",

SUM(CASE WHEN h.codigo_item IN ('90716') AND h.tip_edad = 'A' AND h.edad = 2 THEN 1 ELSE 0 END) AS "Vacuna VARICELA1 2a",
  
SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna influenza1 con morbi 3a",
SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna influenza1 sin morbi 3a",

SUM(CASE WHEN h.codigo_item IN ('90669','90670','Z238') AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','DA','DAA') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Neumococo con Comorbilidad 3a",

SUM(CASE WHEN h.codigo_item IN ('90717') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna AMA 3a",

-- trazador
SUM(CASE WHEN h.codigo_item IN ('90657') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna influenza1 3a",

SUM(CASE WHEN h.codigo_item IN ('90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna IPV1 3a",
SUM(CASE WHEN h.codigo_item IN ('90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna IPV2 3a",

SUM(CASE WHEN h.codigo_item IN ('90712','90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna APO3 3a",

SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna Penta1 3a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna Penta2 3a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna Penta3 3a",

SUM(CASE WHEN h.codigo_item IN ('90702') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D3') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico2 3a",
SUM(CASE WHEN h.codigo_item IN ('90702') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico3 3a",

SUM(CASE WHEN h.codigo_item IN ('90648') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna hib2 3a",
SUM(CASE WHEN h.codigo_item IN ('90648') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna hib3 3a",

SUM(CASE WHEN h.codigo_item IN ('90744') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna HVB2 3a",
SUM(CASE WHEN h.codigo_item IN ('90744') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna HVB3 3a",

SUM(CASE WHEN h.codigo_item IN ('90585') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "BCG Contacto de TB P 3a",

SUM(CASE WHEN h.codigo_item IN ('90716') AND h.tip_edad = 'A' AND h.edad = 3 THEN 1 ELSE 0 END) AS "Vacuna VARICELA1 3a",


SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna influenza1 con morbi 4a",
SUM(CASE WHEN h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna influenza1 sin morbi 4a",

SUM(CASE WHEN h.codigo_item IN ('90669','90670','Z238') AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','DA','DAA') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Neumococo con Comorbilidad 4a",

SUM(CASE WHEN h.codigo_item IN ('90717') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna AMA 4a",

-- trazador
SUM(CASE WHEN h.codigo_item IN ('90657') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna influenza1 4a",

SUM(CASE WHEN h.codigo_item IN ('90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna IPV1 4a",
SUM(CASE WHEN h.codigo_item IN ('90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna IPV2 4a",

SUM(CASE WHEN h.codigo_item IN ('90712','90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna APO3 4a",

SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna Penta1 4a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna Penta2 4a",
SUM(CASE WHEN h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna Penta3 4a",

SUM(CASE WHEN h.codigo_item IN ('90702') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D3') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico2 4a",
SUM(CASE WHEN h.codigo_item IN ('90702') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna DT pediatrico3 4a",

SUM(CASE WHEN h.codigo_item IN ('90648') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna hib2 4a",
SUM(CASE WHEN h.codigo_item IN ('90648') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna hib3 4a",

SUM(CASE WHEN h.codigo_item IN ('90744') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna HVB2 4a",
SUM(CASE WHEN h.codigo_item IN ('90744') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna HVB3 4a",

SUM(CASE WHEN h.codigo_item IN ('90585') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "BCG Contacto de TB P 4a",

SUM(CASE WHEN h.codigo_item IN ('90701') AND COALESCE(TRIM(h.valor_lab), '') IN ('DA','DDA') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna DPT1 4a",

SUM(CASE WHEN h.codigo_item IN ('90712','90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('DA','DDA') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna APO_IPV 4a",

SUM(CASE WHEN h.codigo_item IN ('90716') AND h.tip_edad = 'A' AND h.edad = 4 THEN 1 ELSE 0 END) AS "Vacuna VARICELA1 4a",

-- VACUNACIÓN NEONATO
SUM(CASE WHEN h.codigo_item = '90585' AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','1','D1') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna BCG RN 24H",
SUM(CASE WHEN h.codigo_item = '90585' AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','1','D1') AND h.tip_edad = 'D' AND h.edad > 1 THEN 1 ELSE 0 END) AS "Vacuna BCG RN 2-28DIAS",
SUM(CASE WHEN h.codigo_item = '90585' AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','1','D1') AND h.tip_edad = 'M' THEN 1 ELSE 0 END) AS "Vacuna BCG MEN1A",

SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('','DU') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna HVB RN 12H",
SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'D' AND h.edad = 1 THEN 1 ELSE 0 END) AS "Vacuna HVB RN 24H",

-- REACCIONES ADVERSAS
SUM(CASE WHEN h.codigo_item = 'T881' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS "Reacciones Adversas por vacuna",

SUM(CASE WHEN h.codigo_item = '90670' AND h.tipo_diagnostico = 'D' AND h.tip_edad = 'D' THEN 1 ELSE 0 END) AS "Vacuna Neum madres VIH",

-- SARAMPIÓN – RUBÉOLA
SUM(CASE WHEN h.codigo_item = '90707' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DDA','BD','BU') AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS "Vacuna SPR 5-11a",
SUM(CASE WHEN h.codigo_item = '90707' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DDA','BD','BU') AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS "Vacuna SPR 12-17a",
SUM(CASE WHEN h.codigo_item = '90707' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DDA','BD','BU') AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS "Vacuna SPR 18-29a",
SUM(CASE WHEN h.codigo_item = '90707' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DDA','BD','BU') AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS "Vacuna SPR 30-49a",
SUM(CASE WHEN h.codigo_item = '90707' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DDA','BD','BU') AND h.tip_edad = 'A' AND h.edad >= 50 THEN 1 ELSE 0 END) AS "Vacuna SPR 50AMAS",

-- SPR con banderas
SUM(CASE WHEN h.codigo_item = '90707' AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','') AND ci.flg_ST = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY18a_ST,
SUM(CASE WHEN h.codigo_item = '90707' AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','') AND ci.flg_AER = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY18a_AER,
SUM(CASE WHEN h.codigo_item = '90707' AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','') AND ci.flg_TER = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY18a_TER,

SUM(CASE WHEN h.codigo_item = '90707' AND COALESCE(TRIM(h.valor_lab), '') IN ('FRO','') AND ci.flg_AER = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY18a_FRON,

SUM(CASE WHEN h.codigo_item = '90707' AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','') AND ci.flg_RSA = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY18a_RSA,
SUM(CASE WHEN h.codigo_item = '90707' AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','') AND ci.flg_END = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY18a_END,

SUM(CASE WHEN h.codigo_item = '90707' AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','') AND ci.flg_etnia = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS SARAM_RUEBOLA_MAY5a_ETNIA,

 
SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS "Vacuna HVB1 5-11a",

SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS "Vacuna HVB1 12-17a",

SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS "Vacuna HVB1 18-29a",

SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 59 THEN 1 ELSE 0 END) AS "Vacuna HVB1 30-59a",

SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad >= 60 THEN 1 ELSE 0 END) AS "Vacuna HVB1 60AMAS",


SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS "Vacuna HVB2 5-11a",

SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS "Vacuna HVB2 12-17a",

SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS "Vacuna HVB2 18-29a",

SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 59 THEN 1 ELSE 0 END) AS "Vacuna HVB2 30-59a",

SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad >= 60 THEN 1 ELSE 0 END) AS "Vacuna HVB2 60AMAS",


SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS "Vacuna HVB3 5-11a",

SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS "Vacuna HVB3 12-17a",

SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS "Vacuna HVB3 18-29a",

SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 59 THEN 1 ELSE 0 END) AS "Vacuna HVB3 30-59a",

SUM(CASE WHEN h.codigo_item = '90744' AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad >= 60 THEN 1 ELSE 0 END) AS "Vacuna HVB3 60AMAS",


SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND ci.flg_ST = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS HVB1_MAY5_ST,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND ci.flg_ST = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS HVB2_MAY5_ST,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND ci.flg_ST = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS HVB3_MAY5_ST,


SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND ci.flg_VIH = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS HVB1_MAY5_VIH,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND ci.flg_VIH = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS HVB2_MAY5_VIH,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND ci.flg_VIH = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS HVB3_MAY5_VIH,


SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND ci.flg_OM = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS HVB1_MAY5_OM,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND ci.flg_OM = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS HVB2_MAY5_OM,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND ci.flg_OM = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS HVB3_MAY5_OM,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1') AND ci.flg_OTR = 1 AND h.edad >= 18 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS HVB1_MAY5_OTR,
SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab),'') IN ('2','D2') AND ci.flg_OTR = 1 AND h.edad >= 5 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS HVB2_MAY5_OTR,
SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab),'') IN ('3','D3') AND ci.flg_OTR = 1 AND h.edad >= 5 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS HVB3_MAY5_OTR,

SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1') AND ci.flg_ENF = 1 AND h.edad >= 18 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS HVB1_MAY5_ENF,
SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab),'') IN ('2','D2') AND ci.flg_ENF = 1 AND h.edad >= 5 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS HVB2_MAY5_ENF,
SUM(CASE WHEN h.codigo_item IN ('90744','90746') AND COALESCE(TRIM(h.valor_lab),'') IN ('3','D3') AND ci.flg_ENF = 1 AND h.edad >= 5 AND h.tip_edad = 'A' THEN 1 ELSE 0 END) AS HVB3_MAY5_ENF,

SUM(CASE WHEN h.codigo_item = '90717' AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS "Vacuna AMA 5_11a",
SUM(CASE WHEN h.codigo_item = '90717' AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS "Vacuna AMA 12_17a",
SUM(CASE WHEN h.codigo_item = '90717' AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS "Vacuna AMA 18_29a",
SUM(CASE WHEN h.codigo_item = '90717' AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 59 THEN 1 ELSE 0 END) AS "Vacuna AMA 30_59a",
SUM(CASE WHEN h.codigo_item = '90717' AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad >= 60 THEN 1 ELSE 0 END) AS "Vacuna AMA 60A_MASa",

SUM(CASE WHEN h.codigo_item = '90716' AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','BU','DA','DDA','') AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS "Vacuna varicela 5_11a",
SUM(CASE WHEN h.codigo_item = '90716' AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','BU','DA','DDA','') AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS "Vacuna varicela 12_17a",
SUM(CASE WHEN h.codigo_item = '90716' AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','BU','DA','DDA','') AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS "Vacuna varicela 18_29a",
SUM(CASE WHEN h.codigo_item = '90716' AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','BU','DA','DDA','') AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 59 THEN 1 ELSE 0 END) AS "Vacuna varicela 30_59a",
SUM(CASE WHEN h.codigo_item = '90716' AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','BU','DA','DDA','') AND h.tip_edad = 'A' AND h.edad >= 60 THEN 1 ELSE 0 END) AS "Vacuna varicela 60A_MASa",

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS neumo1_5_11a_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS neumo1_12_17a_mas_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS neumo1_18_29a_mas_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS neumo1_30_49a_mas_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 1 AND h.tip_edad = 'A' AND h.edad BETWEEN 50 AND 59 THEN 1 ELSE 0 END) AS neumo1_50_59a_mas_comorb,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS neumo_5_11a_sin_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS neumo_12_17a_sin_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 18 AND 29 THEN 1 ELSE 0 END) AS neumo_18_29a_sin_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 30 AND 49 THEN 1 ELSE 0 END) AS neumo_30_49a_sin_comorb,
SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 0 AND h.tip_edad = 'A' AND h.edad BETWEEN 50 AND 59 THEN 1 ELSE 0 END) AS neumo_50_59a_sin_comorb,-- ================================

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','') AND h.edad >= 60 THEN 1 ELSE 0 END) AS neumo_60a_mas,

SUM(CASE WHEN g.es_gestante = 1 AND h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') THEN 1 ELSE 0 END) AS neumo_gest,

SUM(CASE WHEN p.es_puerpera = 1 AND h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') THEN 1 ELSE 0 END) AS neumo_puerpera,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_ST = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_st,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_FNI = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_fni,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_PNP = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_pnp,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_M = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_m,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_BOM = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_bom,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_DCI = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_dci,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_EST = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_est,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_CR = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_cr,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_INPE_PPL = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_inpe_ppl,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_REH = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_reh,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_EF = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_ef,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_SR = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_sr,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_DIS = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_dis,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_OTR = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_otr,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_VIH = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_vih,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_OM = 1 AND h.edad >= 18 THEN 1 ELSE 0 END) AS neum_may5_om,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_etnia = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS neum_may5_etnias,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_OM = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS neumo_viviendo_con_vih_mas5a,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_vih = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS esplenicos_oncohematologicos_mas5a,

SUM(CASE WHEN h.codigo_item IN ('90669','90670') AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','') AND ci.flg_ST = 1 AND h.edad >= 5 THEN 1 ELSE 0 END) AS neumo_personal_salud_mas5a,

SUM(CASE WHEN h.codigo_item = '90649' AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1') AND ci.flg_VPH = 1 AND h.genero = 'F' AND h.edad < 9 THEN 1 ELSE 0 END) AS vph1_fem_men9a,

SUM(CASE WHEN h.codigo_item = '90649' AND COALESCE(TRIM(h.valor_lab),'') IN ('2','D2') AND ci.flg_VPH = 1 AND h.genero = 'F' AND h.edad < 9 THEN 1 ELSE 0 END) AS vph2_fem_men9a,

SUM(CASE WHEN h.codigo_item = '90649' AND COALESCE(TRIM(h.valor_lab),'') IN ('DU','') AND ci.flg_VPH = 1 AND h.genero = 'M' AND h.edad < 9 THEN 1 ELSE 0 END) AS vph3_mas_men9a,

SUM(CASE WHEN h.codigo_item = '90649' AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1') AND ci.flg_VPH = 1 AND h.genero = 'F' AND h.edad BETWEEN 9 AND 13 THEN 1 ELSE 0 END) AS vph1_fem_9_13a,

SUM(CASE WHEN h.codigo_item = '90649' AND COALESCE(TRIM(h.valor_lab),'') IN ('2','D2') AND ci.flg_VPH = 1 AND h.genero = 'F' AND h.edad BETWEEN 9 AND 13 THEN 1 ELSE 0 END) AS vph2_fem_9_13a,

SUM(CASE WHEN h.codigo_item = '90649' AND COALESCE(TRIM(h.valor_lab),'') IN ('DU','') AND ci.flg_VPH = 1 AND h.genero = 'M' AND h.edad BETWEEN 9 AND 13 THEN 1 ELSE 0 END) AS vph3_mas_9_13a,

SUM(CASE WHEN h.codigo_item = '90649' AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1') AND ci.flg_VPH = 1 AND h.genero = 'F' AND h.edad >= 14 THEN 1 ELSE 0 END) AS vph1_fem_may_14a,

SUM(CASE WHEN h.codigo_item = '90649' AND COALESCE(TRIM(h.valor_lab),'') IN ('2','D2') AND ci.flg_VPH = 1 AND h.genero = 'F' AND h.edad >= 14 THEN 1 ELSE 0 END) AS vph2_fem_may_14a,

SUM(CASE WHEN h.codigo_item = '90649' AND COALESCE(TRIM(h.valor_lab),'') IN ('DU','') AND ci.flg_VPH = 1 AND h.genero = 'M' AND h.edad >= 14 THEN 1 ELSE 0 END) AS vph3_mas_may_14a


FROM base h
LEFT JOIN gestante_flag g ON h.id_cita = g.id_cita
LEFT JOIN flags_cita ci ON h.id_cita = ci.id_cita
LEFT JOIN puerpera_flag p ON h.id_cita = p.id_cita


   GROUP BY
    h.anio,
    h.mes,
    h.cod_2000,
    h.red,
    h.nombre_establecimiento
    
    

ORDER BY
    h.cod_2000,
    h.anio,
    h.mes;
