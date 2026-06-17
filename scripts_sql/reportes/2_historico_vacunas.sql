
/*CREATE INDEX idx_his_base
ON es_ivan.his_proceso2024 (anio, id_cita, codigo_item, valor_lab);

CREATE INDEX idx_his_edad
ON es_ivan.his_proceso2024 (tip_edad, edad);  */

--DROP TABLE IF EXISTS es_ivan.VACUNAS_2026;

create table es_ivan.VACUNAS_2026 
AS

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
    WHERE h.anio between 2022 and 2025
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
    FROM es_ivan.his_proceso b
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
    FROM es_ivan.his_proceso b
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
COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90714'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 10 AND 11
) AS gestantes_dt1_10_11,

COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90714'
      AND h.valor_lab = '2'
      AND h.edad BETWEEN 10 AND 11
) AS gestantes_dt2_10_11,

COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90714'
      AND h.valor_lab = '3'
      AND h.edad BETWEEN 10 AND 11
) AS gestantes_dt3_10_11,

-- DT – GESTANTES 12–17
COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90714'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 12 AND 17
) AS gestantes_dt1_12_17,

COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90714'
      AND h.valor_lab = '2'
      AND h.edad BETWEEN 12 AND 17
) AS gestantes_dt2_12_17,

COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90714'
      AND h.valor_lab = '3'
      AND h.edad BETWEEN 12 AND 17
) AS gestantes_dt3_12_17,

-- DT – GESTANTES 18–29
COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90714'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 18 AND 29
) AS gestantes_dt1_18_29,

COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90714'
      AND h.valor_lab = '2'
      AND h.edad BETWEEN 18 AND 29
) AS gestantes_dt2_18_29,

COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90714'
      AND h.valor_lab = '3'
      AND h.edad BETWEEN 18 AND 29
) AS gestantes_dt3_18_29,

-- DT – GESTANTES 30–49
COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90714'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 30 AND 49
) AS gestantes_dt1_30_49,

COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90714'
      AND h.valor_lab = '2'
      AND h.edad BETWEEN 30 AND 49
) AS gestantes_dt2_30_49,

COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90714'
      AND h.valor_lab = '3'
      AND h.edad BETWEEN 30 AND 49
) AS gestantes_dt3_30_49,

-- Tdap GESTANTES (código 90715)
COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90715'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 10 AND 11
) AS gestante_Tdap1_10_11a,

COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90715'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 12 AND 17
) AS gestante_Tdap1_12_17a,

COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90715'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 18 AND 29
) AS gestante_Tdap1_18_29a,

COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90715'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 30 AND 49
) AS gestante_Tdap1_30_49a,

COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item = '90715'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 50 AND 60
) AS gestante_Tdap1_50_60a,

   
   
    COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 10 AND 11
) AS no_gestantes_dt1_10_11,

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '2'
      AND h.edad BETWEEN 10 AND 11
) AS no_gestantes_dt2_10_11,

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '3'
      AND h.edad BETWEEN 10 AND 11
) AS no_gestantes_dt3_10_11,

--NO GESTANTES 12–17 AÑOS

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 12 AND 17
) AS no_gestantes_dt1_12_17,

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '2'
      AND h.edad BETWEEN 12 AND 17
) AS no_gestantes_dt2_12_17,

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '3'
      AND h.edad BETWEEN 12 AND 17
) AS no_gestantes_dt3_12_17,

-- NO GESTANTES 18–29 AÑOS

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 18 AND 29
) AS no_gestantes_dt1_18_29,

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '2'
      AND h.edad BETWEEN 18 AND 29
) AS no_gestantes_dt2_18_29,

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '3'
      AND h.edad BETWEEN 18 AND 29
) AS no_gestantes_dt3_18_29,

-- NO GESTANTES 30–49 AÑOS

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 30 AND 49
) AS no_gestantes_dt1_30_49,

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '2'
      AND h.edad BETWEEN 30 AND 49
) AS no_gestantes_dt2_30_49,

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '3'
      AND h.edad BETWEEN 30 AND 49
) AS no_gestantes_dt3_30_49,

-- NO GESTANTES 50–59 AÑOS

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '1'
      AND h.edad BETWEEN 50 AND 59
) AS no_gestantes_dt1_50_59,

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '2'
      AND h.edad BETWEEN 50 AND 59
) AS no_gestantes_dt2_50_59,

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '3'
      AND h.edad BETWEEN 50 AND 59
) AS no_gestantes_dt3_50_59,

-- NO GESTANTES ≥ 60 AÑOS

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '1'
      AND h.edad >= 60
) AS no_gestantes_dt1_may_60a,

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '2'
      AND h.edad >= 60
) AS no_gestantes_dt2_may_60a,

COUNT(*) FILTER (
    WHERE g.es_gestante = 0
      AND h.codigo_item = '90714'
      AND h.valor_lab = '3'
      AND h.edad >= 60
) AS no_gestantes_dt3_may_60a,
    
	COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('1','D1')
      AND h.edad BETWEEN 10 AND 11
) AS varones_dt1_10_11,

COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('2','D2')
      AND h.edad BETWEEN 10 AND 11
) AS varones_dt2_10_11,

COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('3','D3')
      AND h.edad BETWEEN 10 AND 11
) AS varones_dt3_10_11,

-- 12–17 años


COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('1','D1')
      AND h.edad BETWEEN 12 AND 17
) AS varones_dt1_12_17,

COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('2','D2')
      AND h.edad BETWEEN 12 AND 17
) AS varones_dt2_12_17,

COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('3','D3')
      AND h.edad BETWEEN 12 AND 17
) AS varones_dt3_12_17,

-- 18–29 años

COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('1','D1')
      AND h.edad BETWEEN 18 AND 29
) AS varones_dt1_18_29,

COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('2','D2')
      AND h.edad BETWEEN 18 AND 29
) AS varones_dt2_18_29,

COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('3','D3')
      AND h.edad BETWEEN 18 AND 29
) AS varones_dt3_18_29,

-- 30–49 años

COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('1','D1')
      AND h.edad BETWEEN 30 AND 49
) AS varones_dt1_30_49,

COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('2','D2')
      AND h.edad BETWEEN 30 AND 49
) AS varones_dt2_30_49,

COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('3','D3')
      AND h.edad BETWEEN 30 AND 49
) AS varones_dt3_30_49,

--🔹 ≥ 60 años

COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('1','D1')
      AND h.edad >= 60
) AS varones_dt1_60a_mas,

COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('2','D2')
      AND h.edad >= 60
) AS varones_dt2_60a_mas,

COUNT(*) FILTER (
    WHERE h.genero = 'M'
      AND h.codigo_item = '90714'
      AND h.valor_lab IN ('3','D3')
      AND h.edad >= 60
) AS varones_dt3_60a_mas,

-- VACUNACIÓN RECIÉN NACIDOS – CON FILTER
--BCG

COUNT(*) FILTER (
    WHERE h.codigo_item = '90585'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('', 'DU', '1', 'D1')
      AND h.tip_edad = 'D'
      AND h.edad = 1
) AS bcg_12horas,

COUNT(*) FILTER (
    WHERE h.codigo_item = '90585'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1', 'D1')
      AND h.tip_edad = 'D'
      AND h.edad BETWEEN 2 AND 29
) AS bcg_12_24h,

COUNT(*) FILTER (
    WHERE h.codigo_item = '90585'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1', 'D1')
      AND h.tip_edad = 'M'
) AS bcg_1_11m,

-- HVB

COUNT(*) FILTER (
    WHERE h.codigo_item = '90744'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('', 'DU')
      AND h.tip_edad = 'D'
      AND h.edad = 1
) AS hvb_12_24h,

COUNT(*) FILTER (
    WHERE h.codigo_item = '90744'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1', 'D1')
      AND h.tip_edad = 'D'
      AND h.edad = 1
) AS hvb_24h,	

    
    
    ---VACUNACION MENORES DE 1 AÑO

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90722','90723')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
      AND h.tip_edad = 'M'
) AS "Vacuna Penta1 men_1a",

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90722','90723')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
      AND h.tip_edad = 'M'
) AS "Vacuna Penta2 men_1a",

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90722','90723')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
      AND h.tip_edad = 'M'
) AS "Vacuna Penta3 men_1a",

-- IPV

COUNT(*) FILTER (
    WHERE h.codigo_item = '90713'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
      AND h.tip_edad = 'M'
) AS "Vacuna Ipv1 men_1a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90713'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
      AND h.tip_edad = 'M'
) AS "Vacuna Ipv2 men_1a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90713'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
      AND h.tip_edad = 'M'
) AS "Vacuna Ipv3 men_1a",

-- Neumococo

COUNT(*) FILTER (
    WHERE h.codigo_item = '90670'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
      AND h.tip_edad = 'M'
) AS "Vacuna neumo1 men_1a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90670'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
      AND h.tip_edad = 'M'
) AS "Vacuna neumo2 men_1a",

--Rotavirus

COUNT(*) FILTER (
    WHERE h.codigo_item = '90681'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
      AND h.tip_edad = 'M'
) AS "Vacuna rotav1 men_1a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90681'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
      AND h.tip_edad = 'M'
) AS "Vacuna rotav2 men_1a",
--
-- Influenza

COUNT(*) FILTER (
    WHERE h.codigo_item = '90657'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
      AND h.tip_edad = 'M'
) AS "Vacuna influenza1 men_1a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90657'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
      AND h.tip_edad = 'M'
) AS "Vacuna influenza2 men_1a",

-- DT pediátrico

COUNT(*) FILTER (
    WHERE h.codigo_item = '90702'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
      AND h.tip_edad = 'M'
) AS "Vacuna DT pediatrico2 men_1a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90702'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
      AND h.tip_edad = 'M'
) AS "Vacuna DT pediatrico3 men_1a",

-- HIB

COUNT(*) FILTER (
    WHERE h.codigo_item = '90648'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
      AND h.tip_edad = 'M'
) AS "Vacuna hib2 men_1a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90648'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
      AND h.tip_edad = 'M'
) AS "Vacuna hib3 men_1a",

-- Hepatitis B

COUNT(*) FILTER (
    WHERE h.codigo_item = '90744'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
      AND h.tip_edad = 'M'
) AS "Vacuna HVB2 men_1a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90744'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
      AND h.tip_edad = 'M'
) AS "Vacuna HVB3 men_1a",
    
 
  --VACUNACION  DE 1 AÑO

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90717')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna AMA1 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90633.01')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna Hepatitis1 A 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90670')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "NEUMO1 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90707')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna SPR1 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90707')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna SPR2 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90716')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna VARICELA1 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90657','Z2511','90687')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna influenza1 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90657','Z2511','90687')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna influenza2 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90657','Z2511','90687')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','DA','DDA')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna influenza DU 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90701')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DA','DDA')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna DPT1 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90712','90713')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DA','DDA')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna APO_IPV 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90713')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna IPV1 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90713')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna IPV2 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90712','90713')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna APO3 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90722','90723')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna Penta1 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90722','90723')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna Penta2 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90722','90723')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna Penta3 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90702')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna DT pediatrico2 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90702')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna DT pediatrico3 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90648')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna hib2 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90648')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna hib3 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90744')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna HVB2 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90744')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "Vacuna HVB3 1a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90585')
    AND h.tip_edad = 'A'
    AND h.edad = 1
) AS "BCG Contacto de TB P 1a",


   ---VACUNACION  DE 2 AÑO

COUNT(*) FILTER (WHERE h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 1 AND h.edad = 2 AND h.tip_edad = 'A') AS "influenza1_con_morbi 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90657','Z2511','90658','90687','90688') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','') AND ci.flg_comorbilidad = 0 AND h.edad = 2 AND h.tip_edad = 'A') AS "influenza1 sin morbi 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90669','90670','Z238') AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','DA','DAA') AND h.tip_edad = 'A' AND h.edad = 2) AS "Neumococo con Comorbilidad 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90717') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna AMA 2a",

-- trazador
COUNT(*) FILTER (WHERE h.codigo_item IN ('90657') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 2) AS "3325405 Vacuna influenza1 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna IPV1 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna IPV2 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90712','90713') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna APO3 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna Penta1 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna Penta2 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90722','90723') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna Penta3 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90702') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D3') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna DT pediatrico2 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90702') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna DT pediatrico3 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90648') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna hib2 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90648') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna hib3 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90744') AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna HVB2 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90744') AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna HVB3 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90585') AND h.tip_edad = 'A' AND h.edad = 2) AS "BCG (Contacto de TB P) 2a",
COUNT(*) FILTER (WHERE h.codigo_item IN ('90716') AND h.tip_edad = 'A' AND h.edad = 2) AS "Vacuna VARICELA1 2a",

    
  
---VACUNACION  DE 3 AÑO

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90657','Z2511','90658','90687','90688')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna influenza1 con morbi 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90657','Z2511','90658','90687','90688')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna influenza1 sin morbi 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90669','90670','Z238')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','DA','DAA')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Neumococo con Comorbilidad 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90717')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna AMA 3a",

-- trazador
COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90657')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna influenza1 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90713')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna IPV1 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90713')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna IPV2 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90712','90713')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna APO3 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90722','90723')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna Penta1 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90722','90723')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna Penta2 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90722','90723')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna Penta3 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90702')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna DT pediatrico2 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90702')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna DT pediatrico3 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90648')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna hib2 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90648')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna hib3 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90744')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna HVB2 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90744')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna HVB3 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90585')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "BCG Contacto de TB P 3a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90716')
    AND h.tip_edad = 'A'
    AND h.edad = 3
) AS "Vacuna VARICELA1 3a",



COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90657','Z2511','90658','90687','90688')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna influenza1 con morbi 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90657','Z2511','90658','90687','90688')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna influenza1 sin morbi 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90669','90670','Z238')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','DA','DAA')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Neumococo con Comorbilidad 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90717')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna AMA 4a",

-- trazador
COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90657')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna influenza1 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90713')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna IPV1 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90713')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna IPV2 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90712','90713')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna APO3 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90722','90723')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna Penta1 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90722','90723')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna Penta2 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90722','90723')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna Penta3 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90702')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna DT pediatrico2 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90702')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna DT pediatrico3 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90648')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna hib2 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90648')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna hib3 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90744')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna HVB2 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90744')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna HVB3 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90585')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "BCG Contacto de TB P 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90701')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DA','DDA')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna DPT1 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90712','90713')
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DA','DDA')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna APO_IPV 4a",

COUNT(*) FILTER (
  WHERE h.codigo_item IN ('90716')
    AND h.tip_edad = 'A'
    AND h.edad = 4
) AS "Vacuna VARICELA1 4a",


--  VACUNACIÓN NEONATO (versión FILTER)
COUNT(*) FILTER (
  WHERE h.codigo_item = '90585'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','1','D1')
    AND h.tip_edad = 'D'
    AND h.edad = 1
) AS "Vacuna BCG RN 24H",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90585'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','1','D1')
    AND h.tip_edad = 'D'
    AND h.edad > 1
) AS "Vacuna BCG RN 2-28DIAS",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90585'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','1','D1')
    AND h.tip_edad = 'M'
) AS "Vacuna BCG MEN1A",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('','DU')
    AND h.tip_edad = 'D'
    AND h.edad = 1
) AS "Vacuna HVB RN 12H",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'D'
    AND h.edad = 1
) AS "Vacuna HVB RN 24H",

-- REACCIONES ADVERSAS
COUNT(*) FILTER (
  WHERE h.codigo_item = 'T881'
    AND h.tip_edad = 'D'
) AS "Reacciones Adversas por vacuna",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90670'
    AND h.tipo_diagnostico = 'D'
    AND h.tip_edad = 'D'
) AS "Vacuna Neum madres VIH",

-- SARAMPIÓN – RUBÉOLA (5 años a más)
COUNT(*) FILTER (
  WHERE h.codigo_item = '90707'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DDA','BD','BU')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 5 AND 11
) AS "Vacuna SPR 5-11a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90707'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DDA','BD','BU')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 12 AND 17
) AS "Vacuna SPR 12-17a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90707'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DDA','BD','BU')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 18 AND 29
) AS "Vacuna SPR 18-29a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90707'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DDA','BD','BU')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 30 AND 49
) AS "Vacuna SPR 30-49a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90707'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DDA','BD','BU')
    AND h.tip_edad = 'A'
    AND h.edad >= 50
) AS "Vacuna SPR 50AMAS",

-- SPR con banderas (ST, AER, TER, etc.)
COUNT(*) FILTER (
  WHERE h.codigo_item = '90707'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','')
    AND ci.flg_ST = 1
    AND h.edad >= 18
) AS SARAM_RUEBOLA_MAY18a_ST,

COUNT(*) FILTER (
  WHERE h.codigo_item = '90707'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','')
    AND ci.flg_AER = 1
    AND h.edad >= 18
) AS SARAM_RUEBOLA_MAY18a_AER,

COUNT(*) FILTER (
  WHERE h.codigo_item = '90707'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','')
    AND ci.flg_TER = 1
    AND h.edad >= 18
) AS SARAM_RUEBOLA_MAY18a_TER,

COUNT(*) FILTER (
  WHERE h.codigo_item = '90707'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('FRO','')
    AND ci.flg_AER = 1
    AND h.edad >= 18
) AS SARAM_RUEBOLA_MAY18a_FRON,

COUNT(*) FILTER (
  WHERE h.codigo_item = '90707'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','')
    AND ci.flg_RSA = 1
    AND h.edad >= 18
) AS SARAM_RUEBOLA_MAY18a_RSA,

COUNT(*) FILTER (
  WHERE h.codigo_item = '90707'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','')
    AND ci.flg_END = 1
    AND h.edad >= 18
) AS SARAM_RUEBOLA_MAY18a_END,

COUNT(*) FILTER (
  WHERE h.codigo_item = '90707'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('DU','')
    AND ci.flg_etnia = 1
    AND h.edad >= 5
) AS SARAM_RUEBOLA_MAY5a_ETNIA,


 
--POBLACIÓN DE 05 A 59 AÑOS
--VACUNACIÓN CONTRA HEPATITIS B (versión FILTER)
-- HVB – DOSIS 1
COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 5 AND 11
) AS "Vacuna HVB1 5-11a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 12 AND 17
) AS "Vacuna HVB1 12-17a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 18 AND 29
) AS "Vacuna HVB1 18-29a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 30 AND 59
) AS "Vacuna HVB1 30-59a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
    AND h.tip_edad = 'A'
    AND h.edad >= 60
) AS "Vacuna HVB1 60AMAS",

-- HVB – DOSIS 2

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 5 AND 11
) AS "Vacuna HVB2 5-11a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 12 AND 17
) AS "Vacuna HVB2 12-17a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 18 AND 29
) AS "Vacuna HVB2 18-29a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 30 AND 59
) AS "Vacuna HVB2 30-59a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
    AND h.tip_edad = 'A'
    AND h.edad >= 60
) AS "Vacuna HVB2 60AMAS",

-- HVB – DOSIS 3

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 5 AND 11
) AS "Vacuna HVB3 5-11a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 12 AND 17
) AS "Vacuna HVB3 12-17a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 18 AND 29
) AS "Vacuna HVB3 18-29a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad BETWEEN 30 AND 59
) AS "Vacuna HVB3 30-59a",

COUNT(*) FILTER (
  WHERE h.codigo_item = '90744'
    AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
    AND h.tip_edad = 'A'
    AND h.edad >= 60
) AS "Vacuna HVB3 60AMAS",
  

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
      AND ci.flg_ST = 1
      AND h.edad >= 18
) AS HVB1_MAY5_ST,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
      AND ci.flg_ST = 1
      AND h.edad >= 18
) AS HVB2_MAY5_ST,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
      AND ci.flg_ST = 1
      AND h.edad >= 18
) AS HVB3_MAY5_ST,


-- ===============================
-- VACUNA HEPATITIS B – VIH MAYORES DE 5 AÑOS
-- ===============================

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
      AND ci.flg_VIH = 1
      AND h.edad >= 18
) AS HVB1_MAY5_VIH,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
      AND ci.flg_VIH = 1
      AND h.edad >= 5
) AS HVB2_MAY5_VIH,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
      AND ci.flg_VIH = 1
      AND h.edad >= 5
) AS HVB3_MAY5_VIH,


-- ===============================
-- VACUNA HEPATITIS B – OTRAS MORBILIDADES
-- ===============================

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
      AND ci.flg_OM = 1
      AND h.edad >= 18
) AS HVB1_MAY5_OM,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
      AND ci.flg_OM = 1
      AND h.edad >= 5
) AS HVB2_MAY5_OM,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
      AND ci.flg_OM = 1
      AND h.edad >= 5
) AS HVB3_MAY5_OM,  



-- ===============================
-- HEPATITIS B – OTRAS CONDICIONES (OTR)
-- ===============================

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
      AND ci.flg_OTR = 1
      AND h.edad >= 18
) AS HVB1_MAY5_OTR,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
      AND ci.flg_OTR = 1
      AND h.edad >= 5
) AS HVB2_MAY5_OTR,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
      AND ci.flg_OTR = 1
      AND h.edad >= 5
) AS HVB3_MAY5_OTR,



COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1')
      AND ci.flg_ENF = 1
      AND h.edad >= 18
) AS HVB1_MAY5_ENF,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('2','D2')
      AND ci.flg_ENF = 1
      AND h.edad >= 5
) AS HVB2_MAY5_ENF,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90744','90746')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('3','D3')
      AND ci.flg_ENF = 1
      AND h.edad >= 5
) AS HVB3_MAY5_ENF,


 ---ANTIAMARILICA DE 5A MAS AÑOS 
    
    COUNT(*) FILTER (
    WHERE h.codigo_item = '90717'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU',' ')
      AND h.tip_edad = 'A'
      AND h.edad BETWEEN 5 AND 11
) AS "Vacuna AMA 5_11a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90717'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU',' ')
      AND h.tip_edad = 'A'
      AND h.edad BETWEEN 12 AND 17
) AS "Vacuna AMA 12_17a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90717'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU',' ')
      AND h.tip_edad = 'A'
      AND h.edad BETWEEN 18 AND 29
) AS "Vacuna AMA 18_29a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90717'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU',' ')
      AND h.tip_edad = 'A'
      AND h.edad BETWEEN 30 AND 59
) AS "Vacuna AMA 30_59a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90717'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU',' ')
      AND h.tip_edad = 'A'
      AND h.edad >= 60
) AS "Vacuna AMA 60A_MASa",

-- VARICELA – 5 A MÁS AÑOS

COUNT(*) FILTER (
    WHERE h.codigo_item = '90716'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','BU','DA','DDA','')
      AND h.tip_edad = 'A'
      AND h.edad BETWEEN 5 AND 11
) AS "Vacuna varicela 5_11a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90716'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','BU','DA','DDA','')
      AND h.tip_edad = 'A'
      AND h.edad BETWEEN 12 AND 17
) AS "Vacuna varicela 12_17a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90716'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','BU','DA','DDA','')
      AND h.tip_edad = 'A'
      AND h.edad BETWEEN 18 AND 29
) AS "Vacuna varicela 18_29a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90716'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','BU','DA','DDA','')
      AND h.tip_edad = 'A'
      AND h.edad BETWEEN 30 AND 59
) AS "Vacuna varicela 30_59a",

COUNT(*) FILTER (
    WHERE h.codigo_item = '90716'
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','BU','DA','DDA','')
      AND h.tip_edad = 'A'
      AND h.edad >= 60
) AS "Vacuna varicela 60A_MASa",


   

-- NEUMOCOCO 5+ CON COMORBILIDAD

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA',' ')
      AND ci.flg_comorbilidad = 1
      AND h.edad BETWEEN 5 AND 11
) AS neumo1_5_11a_comorb,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA',' ')
      AND ci.flg_comorbilidad = 1
      AND h.edad BETWEEN 12 AND 17
) AS neumo1_12_17a_mas_comorb,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA',' ')
      AND ci.flg_comorbilidad = 1
      AND h.edad BETWEEN 18 AND 29
) AS neumo1_18_29a_mas_comorb,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA',' ')
      AND ci.flg_comorbilidad = 1
      AND h.edad BETWEEN 30 AND 49
) AS neumo1_30_59a_mas_comorb,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA',' ')
      AND ci.flg_comorbilidad = 1
      AND h.edad BETWEEN 50 AND 59
) AS neumo1_50_59a_mas_comorb,


    
-- ================================
-- NEUMOCOCO SIN COMORBILIDAD
-- ================================

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_comorbilidad = 0
      AND h.edad BETWEEN 5 AND 11
) AS neumo_5_11a_sin_comorb,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_comorbilidad = 0
      AND h.edad BETWEEN 12 AND 17
) AS neumo_12_17a_sin_comorb,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_comorbilidad = 0
      AND h.edad BETWEEN 18 AND 29
) AS neumo_18_29a_sin_comorb,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_comorbilidad = 0
      AND h.edad BETWEEN 30 AND 49
) AS neumo_30_49a_sin_comorb,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_comorbilidad = 0
      AND h.edad BETWEEN 50 AND 59
) AS neumo_50_59a_sin_comorb,

-- ================================
-- NEUMOCOCO POBLACIÓN GENERAL
-- ================================

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab), '') IN ('1','D1','DU','DA','DAA','')
      AND h.edad >= 60
) AS neumo_60a_mas,


      
-- ================================
-- NEUMO – Gestantes y Puérperas
-- ================================

COUNT(*) FILTER (
    WHERE g.es_gestante = 1
      AND h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
) AS neumo_gest,

COUNT(*) FILTER (
    WHERE p.es_puerpera = 1
      AND h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
) AS neumo_puerpera,


-- ================================
-- NEUMO – Grupos especiales ≥ 18 años
-- ================================

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_ST = 1
      AND h.edad >= 18
) AS neum_may5_st,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_FNI = 1
      AND h.edad >= 18
) AS neum_may5_fni,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_PNP = 1
      AND h.edad >= 18
) AS neum_may5_pnp,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_M = 1
      AND h.edad >= 18
) AS neum_may5_m,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_BOM = 1
      AND h.edad >= 18
) AS neum_may5_bom,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_DCI = 1
      AND h.edad >= 18
) AS neum_may5_dci,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_EST = 1
      AND h.edad >= 18
) AS neum_may5_est,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_CR = 1
      AND h.edad >= 18
) AS neum_may5_cr,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_INPE_PPL = 1
      AND h.edad >= 18
) AS neum_may5_inpe_ppl,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_REH = 1
      AND h.edad >= 18
) AS neum_may5_reh,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_EF = 1
      AND h.edad >= 18
) AS neum_may5_ef,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_SR = 1
      AND h.edad >= 18
) AS neum_may5_sr,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_DIS = 1
      AND h.edad >= 18
) AS neum_may5_dis,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_OTR = 1
      AND h.edad >= 18
) AS neum_may5_otr,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_VIH = 1
      AND h.edad >= 18
) AS neum_may5_vih,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_OM = 1
      AND h.edad >= 18
) AS neum_may5_om,

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_etnia = 1
      AND h.edad >= 5
) AS neum_may5_etnias,
    

--NEUMO – Población viviendo con VIH / condiciones especiales (≥ 5 años)
/* =====================
   VACUNA NEUMO – VIVIENDO CON VIH ≥ 5 AÑOS
   ===================== */

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_OM = 1
      AND h.edad >= 5
) AS neumo_viviendo_con_vih_mas5a,


/* =====================
   Esplénicos / Oncohematológicos ≥ 5 años
   ===================== */

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_vih = 1
      AND h.edad >= 5
) AS esplenicos_oncohematologicos_mas5a,


/* =====================
   Neumococo – Personal de Salud ≥ 5 años
   ===================== */

COUNT(*) FILTER (
    WHERE h.codigo_item IN ('90669','90670')
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1','DU','DA','DAA','')
      AND ci.flg_ST = 1
      AND h.edad >= 5
) AS neumo_personal_salud_mas5a,


-- =====================================
-- VACUNA VPH – MENORES DE 9 AÑOS
-- =====================================

COUNT(*) FILTER (
    WHERE h.codigo_item = '90649'
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1')
      AND ci.flg_VPH = 1
      AND h.genero = 'F'
      AND h.edad < 9
) AS vph1_fem_men9a,

COUNT(*) FILTER (
    WHERE h.codigo_item = '90649'
      AND COALESCE(TRIM(h.valor_lab),'') IN ('2','D2')
      AND ci.flg_VPH = 1
      AND h.genero = 'F'
      AND h.edad < 9
) AS vph2_fem_men9a,

COUNT(*) FILTER (
    WHERE h.codigo_item = '90649'
      AND COALESCE(TRIM(h.valor_lab),'') IN ('DU','')
      AND ci.flg_VPH = 1
      AND h.genero = 'M'
      AND h.edad < 9
) AS vph3_mas_men9a,


-- =====================================
-- VACUNA VPH – 9 A 13 AÑOS
-- =====================================

COUNT(*) FILTER (
    WHERE h.codigo_item = '90649'
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1')
      AND ci.flg_VPH = 1
      AND h.genero = 'F'
      AND h.edad BETWEEN 9 AND 13
) AS vph1_fem_9_13a,

COUNT(*) FILTER (
    WHERE h.codigo_item = '90649'
      AND COALESCE(TRIM(h.valor_lab),'') IN ('2','D2')
      AND ci.flg_VPH = 1
      AND h.genero = 'F'
      AND h.edad BETWEEN 9 AND 13
) AS vph2_fem_9_13a,

COUNT(*) FILTER (
    WHERE h.codigo_item = '90649'
      AND COALESCE(TRIM(h.valor_lab),'') IN ('DU','')
      AND ci.flg_VPH = 1
      AND h.genero = 'M'
      AND h.edad BETWEEN 9 AND 13
) AS vph3_mas_9_13a,


-- =====================================
-- VACUNA VPH – ≥ 14 AÑOS
-- =====================================

COUNT(*) FILTER (
    WHERE h.codigo_item = '90649'
      AND COALESCE(TRIM(h.valor_lab),'') IN ('1','D1')
      AND ci.flg_VPH = 1
      AND h.genero = 'F'
      AND h.edad >= 14
) AS vph1_fem_may_14a,

COUNT(*) FILTER (
    WHERE h.codigo_item = '90649'
      AND COALESCE(TRIM(h.valor_lab),'') IN ('2','D2')
      AND ci.flg_VPH = 1
      AND h.genero = 'F'
      AND h.edad >= 14
) AS vph2_fem_may_14a,

COUNT(*) FILTER (
    WHERE h.codigo_item = '90649'
      AND COALESCE(TRIM(h.valor_lab),'') IN ('DU','')
      AND ci.flg_VPH = 1
      AND h.genero = 'M'
      AND h.edad >= 14
) AS vph3_mas_may_14a


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
