
CREATE OR REPLACE PROCEDURE es_ivan.sp_generar_iras_edas_{ANIO}()
LANGUAGE plpgsql
AS $$
BEGIN
	
	 -- 1️⃣ Eliminar tabla final si existe
 DROP TABLE IF EXISTS es_ivan.IRAS_EDAS_{ANIO};

    -- 2️⃣ Eliminar tabla temporal si existe


CREATE TABLE es_ivan.IRAS_EDAS_{ANIO} AS

WITH citas_con_desh AS (
    SELECT DISTINCT id_cita
    FROM es_ivan.tabla_iras_edas
    WHERE codigo_item LIKE 'E86%'
),

citas_con_desh_shock AS (
    SELECT DISTINCT id_cita
    FROM es_ivan.tabla_iras_edas
    WHERE codigo_item LIKE 'R57%'
       OR codigo_item LIKE 'K56%'
       OR codigo_item LIKE 'E87%'
),

citas_Oxigenoterapia  AS (
    SELECT DISTINCT id_cita
    FROM es_ivan.tabla_iras_edas
    WHERE codigo_item LIKE 'R57%'
       OR codigo_item LIKE 'K56%'
       OR codigo_item LIKE 'E87%'
),

base AS (
    SELECT
        hp.anio,
        hp.mes,
        hp.cod_2000,
		hp.desc_ue,
        hp.red,
        hp.provincia,
	    hp.distrito,
    	hp.microred,
        hp.nombre_establecimiento,
		hp.dni_paciente,
        hp.fecha_atencion,
		hp.fecha_nacimiento,
        hp.id_cita,
        hp.tipo_diagnostico,
        hp.codigo_item,
		hp.Valor_lab,
        hp.tip_edad,
        hp.edad,
		hp.fg_tipo,
        hp.id_etnia,
        hp.genero
    FROM es_ivan.tabla_iras_edas hp
    WHERE hp.anio >= {ANIO}


)

SELECT
    b.anio,
    b.mes,
    b.cod_2000,
	b.desc_ue,
    b.red,
    b.provincia,
    b.distrito,
    b.microred,
    b.nombre_establecimiento,
    

    /* EDA ACUOSA SIN DESHIDRATACIÓN */
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad IN ('D','M')
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_menor1a,
    
     
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_1a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_2a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_3a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_4a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and  b.tip_edad IN ('D','M') and (b.tip_edad='A' and  b.edad<5)
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_men5a_3331201, 

  COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_5_11a,
    
    
    ----SOSPECHA DE COLERA SIN DESHIDRATACION
    
        COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad IN ('D','M')
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_menor1a,
    
     
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera__1a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera__2a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera__3a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera__4a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and  b.tip_edad IN ('D','M') and (b.tip_edad='A' and  b.edad<5)
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera__men5a, 

     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
		and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera__men5_11a,

  
    -----DISENTERICA SIN  DESHIDRATACION 
   
        COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad IN ('D','M')
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_menor1a,
    
     
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica__1a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica__2a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica__3a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica__4a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and  b.tip_edad IN ('D','M') and (b.tip_edad='A' and  b.edad<5)
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica__men5a,

   COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
		and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica__men5_11a,


   
    ----EDA PERSISTENTE SIN  DESHIDRATACON 
       
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item='A09X' 
          AND b.tip_edad IN ('D','M')
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_menor1a,
    
     
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_1a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_2a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_3a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4
         AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_4a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
 		and  b.tip_edad IN ('D','M') and (b.tip_edad='A' and  b.edad<5)
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_men5a_3331201, 
    
 COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
		and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_men5_11a, 
    
   
    
     /* EDA ACUOSA CON DESHIDRATACIÓN */
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad IN ('D','M')
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_menor1a,
    
     
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_1a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_2a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_3a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_4a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and  b.tip_edad IN ('D','M') and (b.tip_edad='A' and  b.edad<5)
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_men5a, 

	COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
		and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_men5_11a, 
    
    
    ----
    ----SOSPECHA DE COLERA CON DESHIDRATACION
    
        COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad IN ('D','M')
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_menor1a,
    
     
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_1a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_2a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_3a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_4a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and  b.tip_edad IN ('D','M') and (b.tip_edad='A' and  b.edad<5)
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_men5a,

	COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
		and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_men5_11a,



    -----DISENTERICA CON  DESHIDRATACION 
   
        COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad IN ('D','M')
          AND b.id_cita in (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_menor1a,
    
     
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_1a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_2a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_3a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_4a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and  b.tip_edad IN ('D','M') and (b.tip_edad='A' and  b.edad<5)
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_men5a,

 COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
		and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_men5_11a,


    ---EDA PERSISTENTE CON DESHIDRATACION 
               
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item='A09X' 
          AND b.tip_edad IN ('D','M')
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_menor1a,
    
     
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_1a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_2a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_3a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4
         AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_4a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and  b.tip_edad IN ('D','M') and (b.tip_edad='A' and  b.edad<5)
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_men5a_3331201, 

   COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_men5_11, 
    


    ----EDA CON DESHIDRATACION CON  SHOCK
    
       COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad IN ('D','M')
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_shock_menor1a,
    
     
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_shock_1a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_shock_2a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_shock_3a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_shock_4a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and  b.tip_edad IN ('D','M') and (b.tip_edad='A' and  b.edad<5)
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_shock_men5a, 

  COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
         and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item IN (
              'A009','A011','A012','A013','A014',
              'A020','A040','A041','A049',
              'A059','A062','A072','A080',
              'A082','A083','A084','A090','A099'
          )
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_acuosa_desh_shock_men5_11a, 
    
    



    ----
    ----SOSPECHA DE COLERA CON DESHIDRATACION con shcok
    
        COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad IN ('D','M')
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_shock_menor1a,
    
     
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_shock_1a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_shock_2a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_shock_3a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_shock_4a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and  b.tip_edad IN ('D','M') and (b.tip_edad='A' and  b.edad<5)
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_shock_men5a,

     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
       and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item IN ('A00','A000','A001','A009')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS sosp_colera_desh_shock_men5_11a,
    

 
    -----DISENTERICA CON  DESHIDRATACION CON SHOCK  
   
        COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad IN ('D','M')
          AND b.id_cita in (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_shock_menor1a,
    
     
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_shock_1a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_shock_2a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_shock_3a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_shock_4a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and  b.tip_edad IN ('D','M') and (b.tip_edad='A' and  b.edad<5)
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_shock_men5a,

    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item IN ( 'A030', 'A039', 'A042', 'A043', 'A045','A060')
          AND b.tip_edad='A'
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita  IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS disenterica_desh_shock_men5_11a,


    ---EDA PERSISTENTE CON DESHIDRATACION  CON SHOCK
               
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item='A09X' 
          AND b.tip_edad IN ('D','M')
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_shock_menor1a,
    
     
    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_shock_1a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_shock_2a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_shock_3a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4
         AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_shock_4a,
    
     COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and  b.tip_edad IN ('D','M') and (b.tip_edad='A' and  b.edad<5)
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_shock_men5a_3331201,

    COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item='A09X' 
          AND b.tip_edad='A'
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS eda_persistente_desh_shock_men5_11a,


----ADMINISTRACIÓN DE ZINC Y SAL DE REHIDRATACIÓN ORAL 
COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item='99199.11'  and valor_lab='SRO'
          AND b.tip_edad IN ('D','M')
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS tto_SRO_menor1a,

 COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1 and b.tip_edad='A'
          AND b.codigo_item='99199.11'  and valor_lab='SRO'
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS tto_SRO_1a,

COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2 and b.tip_edad='A'
          AND b.codigo_item='99199.11'  and valor_lab='SRO'
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS tto_SRO_2a,

COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3 and b.tip_edad='A'
          AND b.codigo_item='99199.11'  and valor_lab='SRO'
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS tto_SRO_3a,

COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4 and b.tip_edad='A'
          AND b.codigo_item='99199.11'  and valor_lab='SRO'
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS tto_SRO_4a,
    

COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
		and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item='99199.11'  and valor_lab='SRO'
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS tto_SRO_5_11a,


----ADMINISTRACIÓN DE ZINC 
COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
          AND b.codigo_item='99199.11'  and valor_lab='ZN'
          AND b.tip_edad IN ('D','M')
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS tto_ZN_menor1a,

 COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=1 and b.tip_edad='A'
          AND b.codigo_item='99199.11'  and valor_lab='ZN'
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS tto_ZN_1a,

COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=2 and b.tip_edad='A'
          AND b.codigo_item='99199.11'  and valor_lab='ZN'
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS tto_ZN_2a,

COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=3 and b.tip_edad='A'
          AND b.codigo_item='99199.11'  and valor_lab='ZN'
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS tto_ZN_3a,

COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
        and b.edad=4 and b.tip_edad='A'
          AND b.codigo_item='99199.11'  and valor_lab='ZN'
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS tto_ZN_4a,
    

COUNT(*) FILTER (
        WHERE b.tipo_diagnostico = 'D'
		and edad BETWEEN 5 and 11
        and b.tip_edad='A'
          AND b.codigo_item='99199.11'  and valor_lab='ZN'
          AND b.tip_edad='A'
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh)
          AND b.id_cita NOT IN (SELECT id_cita FROM citas_con_desh_shock)
    ) AS tto_ZN_5_11a,



    
    
  ---- INFECCIONES RESPIRATORIAS AGUDAS  
    
    COUNT(*) filter ( where  b.codigo_item IN ('J00X','J040','J041','J042','J060','J068','J069','J209') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad IN ('D') OR (b.tip_edad='M' AND b.edad <2))
        ) as  "IRA no complicada MEN 2m ",
        
        COUNT(*) FILTER ( WHERE  b.codigo_item IN ('J00X','J040','J041','J042','J060','J068','J069','J209') 
             AND b.tipo_diagnostico = 'D' 
             AND b.tip_edad='M' AND b.edad between 2 and 11
        )AS "IRA no complicada 2_11m ",
        
         COUNT(*) FILTER ( WHERE  b.codigo_item IN ('J00X','J040','J041','J042','J060','J068','J069','J209') 
             AND b.tipo_diagnostico = 'D' 
             AND b.tip_edad='A' AND b.edad=1
        )AS "IRA no complicada 1A",
        
          COUNT(*) FILTER ( WHERE  b.codigo_item IN ('J00X','J040','J041','J042','J060','J068','J069','J209') 
             AND b.tipo_diagnostico = 'D' 
             AND b.tip_edad='A' AND b.edad=2
        )AS "IRA no complicada 2A",
        
          COUNT(*) FILTER ( WHERE  b.codigo_item IN ('J00X','J040','J041','J042','J060','J068','J069','J209') 
             AND b.tipo_diagnostico = 'D' 
             AND b.tip_edad='A' AND b.edad=3
        )AS "IRA no complicada 3",
        
          COUNT(*) FILTER ( WHERE  b.codigo_item IN ('J00X','J040','J041','J042','J060','J068','J069','J209') 
             AND b.tipo_diagnostico = 'D' 
             AND b.tip_edad='A' AND b.edad=4
        )AS "IRA no complicada 4A",
        
          COUNT(*) FILTER ( WHERE  b.codigo_item IN ('J00X','J040','J041','J042','J060','J068','J069','J209') 
             AND b.tipo_diagnostico = 'D' 
             AND b.tip_edad='A' AND b.edad between 5 and 9 
        )AS "IRA no complicada 5_9",
        
         COUNT(*) FILTER ( WHERE  b.codigo_item IN ('J00X','J040','J041','J042','J060','J068','J069','J209') 
             AND b.tipo_diagnostico = 'D' 
             AND b.tip_edad='A' AND b.edad between 10 and 11 
        )AS "IRA no complicada 10_11",

   COUNT(*) FILTER ( WHERE b.codigo_item IN ('J00X','J040','J041','J042','J060','J068','J069','J209') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad IN ('D','M') OR (b.tip_edad='A' AND b.edad <= 5))
        ) AS "3331101: IRA no complicada <5a",
        
   COUNT(*) FILTER ( WHERE b.codigo_item IN ('J020','J029','J030','J038','J039') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' OR (b.tip_edad='A' AND b.edad = 1))
        ) AS "Faringoamigdalitis aguda 1a",
        
           COUNT(*) FILTER ( WHERE b.codigo_item IN ('J020','J029','J030','J038','J039') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' OR (b.tip_edad='A' AND b.edad = 2))
        ) AS "Faringoamigdalitis aguda 2a",
        
           COUNT(*) FILTER ( WHERE b.codigo_item IN ('J020','J029','J030','J038','J039') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' OR (b.tip_edad='A' AND b.edad = 3))
        ) AS "Faringoamigdalitis aguda 3a",
        
           COUNT(*) FILTER ( WHERE b.codigo_item IN ('J020','J029','J030','J038','J039') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' OR (b.tip_edad='A' AND b.edad = 4))
        ) AS "Faringoamigdalitis aguda 4a",
        
           COUNT(*) FILTER ( WHERE b.codigo_item IN ('J020','J029','J030','J038','J039') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' OR (b.tip_edad='A' AND b.edad between 5 and 9))
        ) AS "Faringoamigdalitis aguda 5-9a",
        
          COUNT(*) FILTER ( WHERE b.codigo_item IN ('J020','J029','J030','J038','J039') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' OR (b.tip_edad='A' AND b.edad between 10 and 11))
        ) AS "Faringoamigdalitis aguda 10-11a",

    COUNT(*) FILTER ( WHERE b.codigo_item IN ('J020','J029','J030','J038','J039') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad IN ('D','M') OR (b.tip_edad='A' AND b.edad <= 5))
        ) AS "3331102: Faringoamigdalitis aguda men5A",
        
        
---OTITIS MEDIA AGUDA 
        
    COUNT(*) FILTER ( WHERE b.codigo_item IN ('H650','H651','H660','H669') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad IN ('D') OR (b.tip_edad='M' AND b.edad <= 2))
        ) AS "Otitis media aguda men 2m",
        
        COUNT(*) FILTER ( WHERE b.codigo_item IN ('H650','H651','H660','H669') 
             AND b.tipo_diagnostico = 'D' 
             AND b.tip_edad='M' AND b.edad between 2 AND 11
        ) AS " Otitis media aguda 2_11m",            
               
         COUNT(*) FILTER ( WHERE b.codigo_item IN ('H650','H651','H660','H669') 
             AND b.tipo_diagnostico = 'D' 
             AND  (b.tip_edad='A' AND b.edad=1 )
             ) AS "Otitis media aguda 1A",
        
         COUNT(*) FILTER ( WHERE b.codigo_item IN ('H650','H651','H660','H669') 
             AND b.tipo_diagnostico = 'D' 
             AND  (b.tip_edad='A' AND b.edad=1 )
             ) AS "Otitis media aguda 2A",
        
         COUNT(*) FILTER ( WHERE b.codigo_item IN ('H650','H651','H660','H669') 
             AND b.tipo_diagnostico = 'D' 
             AND  (b.tip_edad='A' AND b.edad=1 )
            ) AS "Otitis media aguda 3A",
            
         COUNT(*) FILTER ( WHERE b.codigo_item IN ('H650','H651','H660','H669') 
             AND b.tipo_diagnostico = 'D' 
             AND  (b.tip_edad='A' AND b.edad=1 )
             ) AS "Otitis media aguda 4A",
             
             COUNT(*) FILTER ( WHERE b.codigo_item IN ('H650','H651','H660','H669') 
             AND b.tipo_diagnostico = 'D' 
             AND  (b.tip_edad='A' AND b.edad between 5 and 9 )
             ) AS "Otitis media aguda 5_9a",
                           
             COUNT(*) FILTER ( WHERE b.codigo_item IN ('H650','H651','H660','H669') 
             AND b.tipo_diagnostico = 'D' 
             AND  (b.tip_edad='A' AND b.edad between 10 and 11 )
             ) AS "Otitis media aguda 10_11a",               
        
         COUNT(*) FILTER ( WHERE b.codigo_item IN ('H650','H651','H660','H669') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad IN ('D','M') OR (b.tip_edad='A' AND b.edad <= 5))
        ) AS "3331103: Otitis media aguda men5",
        

---SINUSITIS.
        
            COUNT(*) FILTER ( WHERE b.codigo_item IN ('J010','J011','J012','J013','J0145','J019') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad IN ('D') OR (b.tip_edad='M' AND b.edad <= 2))
        ) AS "Sinusitis aguda MEN2_m",
        
        COUNT(*) FILTER ( WHERE b.codigo_item IN ('J010','J011','J012','J013','J0145','J019') 
             AND b.tipo_diagnostico = 'D' 
             AND b.tip_edad='M' AND b.edad between 2 AND 11 
        ) AS "Sinusitis aguda 2_11",
        
          
        COUNT(*) FILTER ( WHERE b.codigo_item IN ('J010','J011','J012','J013','J0145','J019') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad=1 )
        ) AS "Sinusitis aguda 1a",
        
           COUNT(*) FILTER ( WHERE b.codigo_item IN ('J010','J011','J012','J013','J0145','J019') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad=2 )
        ) AS "Sinusitis aguda 2a",
        
        COUNT(*) FILTER ( WHERE b.codigo_item IN ('J010','J011','J012','J013','J0145','J019') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad=3 )
        ) AS "Sinusitis aguda 3a",
        
        COUNT(*) FILTER ( WHERE b.codigo_item IN ('J010','J011','J012','J013','J0145','J019') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad=4 )
        ) AS "Sinusitis aguda 4a",
        
                COUNT(*) FILTER ( WHERE b.codigo_item IN ('J010','J011','J012','J013','J0145','J019') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad between 5 AND 9)
        ) AS "Sinusitis aguda 5_9a",
        
               COUNT(*) FILTER ( WHERE b.codigo_item IN ('J010','J011','J012','J013','J0145','J019') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad between 10 AND 11)
        ) AS "Sinusitis aguda 10_11a",
        
         COUNT(*) FILTER ( WHERE b.codigo_item IN ('J010','J011','J012','J013','J0145','J019') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad IN ('D','M') OR (b.tip_edad='A' AND b.edad <= 5))
        ) AS "3331104: Sinusitis aguda MEN5a",
        
   ---NEUMONIA NO COMPLICADA
        
         COUNT(*) FILTER ( WHERE b.codigo_item IN ('J129','J159','J189') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad=1)
        ) AS "Neumonía no complicada 1a",
        
          
         COUNT(*) FILTER ( WHERE b.codigo_item IN ('J129','J159','J189') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad=2)
        ) AS "Neumonía no complicada 2a",
          
         COUNT(*) FILTER ( WHERE b.codigo_item IN ('J129','J159','J189') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad=3)
        ) AS "Neumonía no complicada 3a",
        
          
         COUNT(*) FILTER ( WHERE b.codigo_item IN ('J129','J159','J189') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad=4)
        ) AS "Neumonía no complicada 4a",
        
          
         COUNT(*) FILTER ( WHERE b.codigo_item IN ('J129','J159','J189') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad between 5 and 9)
        ) AS "Neumonía no complicada 5_9a",
        

        COUNT(*) FILTER ( WHERE b.codigo_item IN ('J129','J159','J189') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad between 10 and 11)
        ) AS "Neumonía no complicada 10_11a",
        
        
    	COUNT(*) FILTER ( WHERE b.codigo_item IN ('J129','J159','J189') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad IN ('D','M') OR (b.tip_edad='A' AND b.edad <= 5))
        ) AS "Neumonía no complicada men5a",
        
        COUNT(*) FILTER ( WHERE b.codigo_item IN ('A369','A370','A371','A378','A379','J120','J121','J122','J123','J128','J13X','J14X','J150','J151','J152','J153','J154','J157','J158','J160','J168') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad IN ('D') OR (b.tip_edad='M' AND b.edad <= 2))
        ) AS "IRAS con complicaciones men2m",
        
           
          COUNT(*) FILTER ( WHERE b.codigo_item IN ('A369','A370','A371','A378','A379','J120','J121','J122','J123','J128','J13X','J14X','J150','J151','J152','J153','J154','J157','J158','J160','J168') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad IN ('M') AND b.edad between 2 and 11)
        ) AS "IRAS con complicaciones 2_11m",
        
           COUNT(*) FILTER ( WHERE b.codigo_item IN ('A369','A370','A371','A378','A379','J120','J121','J122','J123','J128','J13X','J14X','J150','J151','J152','J153','J154','J157','J158','J160','J168') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad=1)
        ) AS "IRAS con complicaciones 1a",
        
               COUNT(*) FILTER ( WHERE b.codigo_item IN ('A369','A370','A371','A378','A379','J120','J121','J122','J123','J128','J13X','J14X','J150','J151','J152','J153','J154','J157','J158','J160','J168') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad=2)
        ) AS "IRAS con complicaciones 2a",
        
            COUNT(*) FILTER ( WHERE b.codigo_item IN ('A369','A370','A371','A378','A379','J120','J121','J122','J123','J128','J13X','J14X','J150','J151','J152','J153','J154','J157','J158','J160','J168') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad=3)
        ) AS "IRAS con complicaciones 3a",
        
            COUNT(*) FILTER ( WHERE b.codigo_item IN ('A369','A370','A371','A378','A379','J120','J121','J122','J123','J128','J13X','J14X','J150','J151','J152','J153','J154','J157','J158','J160','J168') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad=4)
        ) AS "IRAS con complicaciones 4a",
        
            COUNT(*) FILTER ( WHERE b.codigo_item IN ('A369','A370','A371','A378','A379','J120','J121','J122','J123','J128','J13X','J14X','J150','J151','J152','J153','J154','J157','J158','J160','J168') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad between 5 and 9 )
        ) AS "IRAS con complicaciones 5_9a",
                
            COUNT(*) FILTER ( WHERE b.codigo_item IN ('A369','A370','A371','A378','A379','J120','J121','J122','J123','J128','J13X','J14X','J150','J151','J152','J153','J154','J157','J158','J160','J168') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad='A' AND b.edad between 10 and 11 )
        ) AS "IRAS con complicaciones 10_11a",
        
        COUNT(*) FILTER ( WHERE b.codigo_item IN ('A369','A370','A371','A378','A379','J120','J121','J122','J123','J128','J13X','J14X','J150','J151','J152','J153','J154','J157','J158','J160','J168') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad IN ('D','M') OR (b.tip_edad='A' AND b.edad<5))
        ) AS "3331301: IRAS con complicaciones",
        
        
    	COUNT(*) FILTER ( WHERE b.codigo_item IN ('J050','J051','J851','J860','J869','J100','J111','J155','J156','J18','J181','J182','J188') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad = 'D' OR (b.tip_edad = 'M' AND b.edad <= 2))
        ) AS "3331302: Neumonía y EMG en niños menores de 2 meses",

   		 COUNT(*) FILTER ( WHERE b.codigo_item IN ('J050','J051','J851','J860','J869','J100','J111','J155','J156','J18','J181','J182','J188') 
             AND b.tipo_diagnostico = 'D' 
             AND  (b.tip_edad = 'M' AND b.edad >= 2) OR (b.tip_edad = 'A' AND b.edad <= 4)
        ) AS "3331305: Neumonía y EMG en niños de 2 meses a 4 años",
        
        COUNT(*) FILTER ( WHERE b.codigo_item IN ('J050','J051','J851','J860','J869','J100','J111','J155','J156','J18','J181','J182','J188') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad = 'D' OR (b.tip_edad = 'M' AND b.edad <= 2))
        ) AS "3331302: Neumonía y EMG men a 2m",
	        
	    COUNT(*) FILTER ( WHERE b.codigo_item IN ('J050','J051','J851','J860','J869','J100','J111','J155','J156','J18','J181','J182','J188') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad = 'D' OR (b.tip_edad = 'M' AND b.edad BETWEEN 2 AND 11))
        ) AS "3331302: Neumonía y EMG 2_11m",
        
   		COUNT(*) FILTER ( WHERE b.codigo_item IN ('J050','J051','J851','J860','J869','J100','J111','J155','J156','J18','J181','J182','J188') 
             AND b.tipo_diagnostico = 'D' 
             AND  (b.tip_edad = 'A' AND b.edad=1)
        ) AS "3331302: Neumonía y EMG 1a",
        
   		COUNT(*) FILTER ( WHERE b.codigo_item IN ('J050','J051','J851','J860','J869','J100','J111','J155','J156','J18','J181','J182','J188') 
             AND b.tipo_diagnostico = 'D' 
             AND (b.tip_edad = 'A' AND b.edad=2)
        ) AS "3331302: Neumonía y EMG 2a",
           
   		COUNT(*) FILTER ( WHERE b.codigo_item IN ('J050','J051','J851','J860','J869','J100','J111','J155','J156','J18','J181','J182','J188') 
             AND b.tipo_diagnostico = 'D' 
             AND  (b.tip_edad = 'A' AND b.edad=3)
        ) AS "3331302: Neumonía y EMG 3a",
        
    	COUNT(*) FILTER ( WHERE b.codigo_item IN ('J050','J051','J851','J860','J869','J100','J111','J155','J156','J18','J181','J182','J188') 
             AND b.tipo_diagnostico = 'D' 
             AND  (b.tip_edad = 'A' AND b.edad=4)
        ) AS "3331302: Neumonía y EMG 4a",
        
    	COUNT(*) FILTER ( WHERE b.codigo_item IN ('J050','J051','J851','J860','J869','J100','J111','J155','J156','J18','J181','J182','J188') 
             AND b.tipo_diagnostico = 'D' 
             AND  (b.tip_edad = 'A' AND b.edad BETWEEN 5 AND 9)
             ) AS "3331302: Neumonía y EMG 5_9a",
        
    	COUNT(*) FILTER ( WHERE b.codigo_item IN ('J050','J051','J851','J860','J869','J100','J111','J155','J156','J18','J181','J182','J188') 
             AND b.tipo_diagnostico = 'D' 
             AND  (b.tip_edad = 'A' AND b.edad BETWEEN 10 AND 11)
        ) AS "3331302: Neumonía y EMG 10_11a",
        
    -- 1 año


        SUM(
    CASE 
        WHEN (
            b.codigo_item LIKE 'J15%'
            OR b.codigo_item LIKE 'J16%'
            OR b.codigo_item LIKE 'A036%'
            OR b.codigo_item LIKE 'A037%'
            OR b.codigo_item LIKE 'AJ12%'
            OR b.codigo_item LIKE 'AJ13%'
            OR b.codigo_item LIKE 'AJ14%'
        )
        AND b.tipo_diagnostico = 'D'
        AND b.tip_edad = 'A'
        AND b.edad = 1
        THEN 1 ELSE 0
    END
) AS "3331305 Neumonía 1A",

-- 2 años
SUM(
    CASE 
        WHEN (
            b.codigo_item LIKE 'J15%'
            OR b.codigo_item LIKE 'J16%'
            OR b.codigo_item LIKE 'A036%'
            OR b.codigo_item LIKE 'A037%'
            OR b.codigo_item LIKE 'AJ12%'
            OR b.codigo_item LIKE 'AJ13%'
            OR b.codigo_item LIKE 'AJ14%'
        )
        AND b.tipo_diagnostico = 'D'
        AND b.tip_edad = 'A'
        AND b.edad = 2
        THEN 1 ELSE 0
    END
) AS "3331305 Neumonía 2A",

-- 3 años
SUM(
    CASE 
        WHEN (
            b.codigo_item LIKE 'J15%'
            OR b.codigo_item LIKE 'J16%'
            OR b.codigo_item LIKE 'A036%'
            OR b.codigo_item LIKE 'A037%'
            OR b.codigo_item LIKE 'AJ12%'
            OR b.codigo_item LIKE 'AJ13%'
            OR b.codigo_item LIKE 'AJ14%'
        )
        AND b.tipo_diagnostico = 'D'
        AND b.tip_edad = 'A'
        AND b.edad = 3
        THEN 1 ELSE 0
    END
) AS "3331305 Neumonía 3A",

-- 4 años
SUM(
    CASE 
        WHEN (
            b.codigo_item LIKE 'J15%'
            OR b.codigo_item LIKE 'J16%'
            OR b.codigo_item LIKE 'A036%'
            OR b.codigo_item LIKE 'A037%'
            OR b.codigo_item LIKE 'AJ12%'
            OR b.codigo_item LIKE 'AJ13%'
            OR b.codigo_item LIKE 'AJ14%'
        )
        AND b.tipo_diagnostico = 'D'
        AND b.tip_edad = 'A'
        AND b.edad = 4
        THEN 1 ELSE 0
    END
) AS "3331305 Neumonía 4A",

-- 5 a 9 años
SUM(
    CASE 
        WHEN (
            b.codigo_item LIKE 'J15%'
            OR b.codigo_item LIKE 'J16%'
            OR b.codigo_item LIKE 'A036%'
            OR b.codigo_item LIKE 'A037%'
            OR b.codigo_item LIKE 'AJ12%'
            OR b.codigo_item LIKE 'AJ13%'
            OR b.codigo_item LIKE 'AJ14%'
        )
        AND b.tipo_diagnostico = 'D'
        AND b.tip_edad = 'A'
        AND b.edad BETWEEN 5 AND 9
        THEN 1 ELSE 0
    END
) AS "3331305 Neumonía 5_9a",

-- 10 a 11 años
SUM(
    CASE 
        WHEN (
            b.codigo_item LIKE 'J15%'
            OR b.codigo_item LIKE 'J16%'
            OR b.codigo_item LIKE 'A036%'
            OR b.codigo_item LIKE 'A037%'
            OR b.codigo_item LIKE 'AJ12%'
            OR b.codigo_item LIKE 'AJ13%'
            OR b.codigo_item LIKE 'AJ14%'
        )
        AND b.tipo_diagnostico = 'D'
        AND b.tip_edad = 'A'
        AND b.edad BETWEEN 10 AND 11
        THEN 1 ELSE 0
    END
) AS "3331305 Neumonía 10_11a",

---SOB ASMA

-- 2 a 11 MESES
SUM(
    CASE 
        WHEN (
            b.codigo_item LIKE 'J21%'
            OR b.codigo_item LIKE 'J44%'
            OR b.codigo_item LIKE 'J45%'
            OR b.codigo_item LIKE 'J46%'
            
        )
        AND b.tipo_diagnostico = 'D'
        AND b.tip_edad = 'M'
        AND b.edad BETWEEN 2 AND 11
        THEN 1 ELSE 0
    END
) AS "SOB_ASMA 2_11m",

-- 1 AÑO SOB ASMA
SUM(
    CASE 
        WHEN (
            b.codigo_item LIKE 'J21%'
            OR b.codigo_item LIKE 'J44%'
            OR b.codigo_item LIKE 'J45%'
            OR b.codigo_item LIKE 'J46%'
            
        )
        AND b.tipo_diagnostico = 'D'
        AND b.tip_edad = 'M'
        AND b.edad=1
        THEN 1 ELSE 0
    END
) AS "3331305 SOB_ASMA 1a",

-- 2 AÑOS SOB ASMA
SUM(
    CASE 
        WHEN (
            b.codigo_item LIKE 'J21%'
            OR b.codigo_item LIKE 'J44%'
            OR b.codigo_item LIKE 'J45%'
            OR b.codigo_item LIKE 'J46%'
            
        )
        AND b.tipo_diagnostico = 'D'
        AND b.tip_edad = 'M'
        AND b.edad=2
        THEN 1 ELSE 0
    END
) AS "3331305 SOB_ASMA 2a",

-- 3 AÑOS SOB ASMA
SUM(
    CASE 
        WHEN (
            b.codigo_item LIKE 'J21%'
            OR b.codigo_item LIKE 'J44%'
            OR b.codigo_item LIKE 'J45%'
            OR b.codigo_item LIKE 'J46%'
            
        )
        AND b.tipo_diagnostico = 'D'
        AND b.tip_edad = 'M'
        AND b.edad=3
        THEN 1 ELSE 0
    END
) AS "3331305 SOB_ASMA 3a",

-- 4 AÑOS SOB ASMA
SUM(
    CASE 
        WHEN (
            b.codigo_item LIKE 'J21%'
            OR b.codigo_item LIKE 'J44%'
            OR b.codigo_item LIKE 'J45%'
            OR b.codigo_item LIKE 'J46%'
            
        )
        AND b.tipo_diagnostico = 'D'
        AND b.tip_edad = 'M'
        AND b.edad=4
        THEN 1 ELSE 0
    END
) AS "3331305 SOB_ASMA 4a",

-- 5-9 AÑOS SOB ASMA
SUM(
    CASE 
        WHEN (
            b.codigo_item LIKE 'J21%'
            OR b.codigo_item LIKE 'J44%'
            OR b.codigo_item LIKE 'J45%'
            OR b.codigo_item LIKE 'J46%'
            
        )
        AND b.tipo_diagnostico = 'D'
        AND b.tip_edad = 'M'
        AND b.edad BETWEEN 5 AND 9
        THEN 1 ELSE 0
    END
) AS "3331305 SOB_ASMA 5_9a",

-- 10-11 AÑOS SOB ASMA
SUM(
    CASE 
        WHEN (
            b.codigo_item LIKE 'J21%'
            OR b.codigo_item LIKE 'J44%'
            OR b.codigo_item LIKE 'J45%'
            OR b.codigo_item LIKE 'J46%'
            
        )
        AND b.tipo_diagnostico = 'D'
        AND b.tip_edad = 'M'
        AND b.edad BETWEEN 10 AND 11
        THEN 1 ELSE 0
    END
) AS "3331305 SOB_ASMA 10_11a"





FROM base b
GROUP BY
    b.anio,
    b.mes,
    b.cod_2000,
	b.desc_ue,
    b.red,
    b.provincia,
    b.distrito,
    b.microred,
    b.nombre_establecimiento
ORDER BY
    b.anio,
    b.mes,
    b.red,
    b.nombre_establecimiento;

 RAISE NOTICE 'Proceso IRAS_EDAS_{ANIO} finalizado correctamente';

END;
$$;

CALL es_ivan.sp_generar_iras_edas_{ANIO}();