


-- INCREMENTANDO CEROS A cod_unico
UPDATE es_ivan.maestro_his_establecimiento SET codigo_unico = LPAD(codigo_unico::text, 9, '0');
UPDATE es_ivan.maestro_eess_susalud SET cod_unico = LPAD(cod_unico::text, 9, '0');

--actualizando  unidades ejecutoras
UPDATE es_ivan.maestro_eess_susalud2025
SET desc_ue = CASE cod_ue
    WHEN '1169' THEN 'UE - HOSPITAL ANTONIO LORENA'
    WHEN '1130' THEN 'UE - HOSPITAL REGIONAL CUSCO'
    WHEN '1547' THEN 'UE - HOSPITAL ESPINAR'
    WHEN '1626' THEN 'UE - HOSPITAL QUILLABAMBA'
    WHEN '1625' THEN 'UE - HOSPITAL SICUANI'
    WHEN '1129' THEN 'UE - SALUD CANAS - CANCHIS - ESPINAR'
    WHEN '1666' THEN 'UE - SALUD CHUMBIVILCAS'
    WHEN '798'  THEN 'UE - SALUD CUSCO'
    WHEN '1348' THEN 'UE - SALUD CUSCO NORTE'
    WHEN '1322' THEN 'UE - SALUD CUSCO SUR'
    WHEN '1347' THEN 'UE - SALUD KIMBIRI PICHARI'
    WHEN '1170' THEN 'UE - SALUD LA CONVENCION'
    ELSE desc_ue
END
WHERE inst = 'GOBIERNO REGIONAL'
  AND cod_ue IN ('1169','1130','1547','1626','1625','1129','1666','798','1348','1322','1347','1170');
-- =========================================
-- ACTUALIZANDO REDES, MICROREDES E IPRESS
-- =========================================

-- HOSPITALES CATEGORIA III
UPDATE es_ivan.maestro_his_establecimiento SET nombre_establecimiento = 'HOSPITAL REGIONAL CUSCO', codigo_red = '07',   red = 'HOSPITALES III',    microred = 'HOSPITAL' WHERE disa = 'CUSCO' AND id_establecimiento = '2288';
UPDATE es_ivan.maestro_his_establecimiento SET nombre_establecimiento = 'HOSPITAL ANTONIO LORENA', codigo_red = '07',   red = 'HOSPITALES III',    microred = 'HOSPITAL' WHERE disa = 'CUSCO' AND id_establecimiento = '2304';

-- Actualización microredes
UPDATE es_ivan.maestro_his_establecimiento25 SET codigo_microred = '02', microred = 'EL DESCANSO' WHERE disa = 'CUSCO' AND codigo_red = '04' AND id_establecimiento = '2366'; 
UPDATE es_ivan.maestro_his_establecimiento25 SET codigo_microred = '04', microred = 'TECHO OBRERO' WHERE disa = 'CUSCO' AND codigo_red = '04' AND id_establecimiento = '2368';
UPDATE es_ivan.maestro_his_establecimiento25 SET codigo_microred = '04', microred = 'TECHO OBRERO' WHERE disa = 'CUSCO' AND codigo_red = '04' AND id_establecimiento = '2369';
UPDATE es_ivan.maestro_his_establecimiento25 SET codigo_microred = '04', microred = 'TECHO OBRERO' WHERE disa = 'CUSCO' AND codigo_red = '04' AND id_establecimiento = '2370';

--ACTUALIZADO IPRESS DE SALUD MENTAL
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000026181',Nombre_Establecimiento='MENTAL SAN SEBASTIAN', Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='16', MicroRed='CUSCO',Categoria_Establecimiento='I-2' WHERE Disa='CUSCO' AND Id_Establecimiento='9999023';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000026181',Nombre_Establecimiento='MENTAL SAN SEBASTIAN', Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='16', MicroRed='CUSCO',Categoria_Establecimiento='I-2' WHERE Disa='CUSCO' AND Id_Establecimiento='35937';

UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000026387',Nombre_Establecimiento='MENTAL COMUNITARIO SICUANI', Ubigueo_Establecimiento='080601',Codigo_Red='04', Red='CANAS-CANCHIS-ESPINAR',Codigo_MicroRed='05', MicroRed='PAMPAPHALLA', Categoria_Establecimiento='I-2', Provincia='CANCHIS',Distrito='SICUANI'WHERE Disa='CUSCO' AND Id_Establecimiento='9999020';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000026387',Nombre_Establecimiento='MENTAL COMUNITARIO SICUANI', Ubigueo_Establecimiento='080601',Codigo_Red='04', Red='CANAS-CANCHIS-ESPINAR',Codigo_MicroRed='05', MicroRed='PAMPAPHALLA', Categoria_Establecimiento='I-2', Provincia='CANCHIS',Distrito='SICUANI'WHERE Disa='CUSCO' AND Id_Establecimiento='36090';

UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000026386',Nombre_Establecimiento='MENTAL QUILLABAMBA', Codigo_Red='03', Red='LA CONVENCION',Codigo_MicroRed='01', MicroRed='SANTA ANA', Categoria_Establecimiento='I-2'WHERE Disa='CUSCO' AND Id_Establecimiento='9999021';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000026386',Nombre_Establecimiento='MENTAL QUILLABAMBA', Codigo_Red='03', Red='LA CONVENCION',Codigo_MicroRed='01', MicroRed='SANTA ANA', Categoria_Establecimiento='I-2'WHERE Disa='CUSCO' AND Id_Establecimiento='36147';

UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000026182',Nombre_Establecimiento='MENTAL SANTIAGO', Codigo_Red='02', Red='CUSCO NORTE',Codigo_MicroRed='01', MicroRed='BELEMPAMPA', Categoria_Establecimiento='I-2'WHERE Disa='CUSCO' AND Id_Establecimiento='9999022';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000026182',Nombre_Establecimiento='MENTAL SANTIAGO', Codigo_Red='02', Red='CUSCO NORTE',Codigo_MicroRed='01', MicroRed='BELEMPAMPA', Categoria_Establecimiento='I-2'WHERE Disa='CUSCO' AND Id_Establecimiento='35938';

UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000026273',Nombre_Establecimiento='MENTAL COMUNITARIO CALCA', Ubigueo_Establecimiento='080401', Codigo_Red='02', Red='CUSCO NORTE',Codigo_MicroRed='06', MicroRed='CALCA', Categoria_Establecimiento='I-2', Provincia='CALCA',Distrito='CALCA'WHERE Disa='CUSCO' AND Id_Establecimiento='9999024';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000026273',Nombre_Establecimiento='MENTAL COMUNITARIO CALCA', Ubigueo_Establecimiento='080401', Codigo_Red='02', Red='CUSCO NORTE',Codigo_MicroRed='06', MicroRed='CALCA', Categoria_Establecimiento='I-2', Provincia='CALCA',Distrito='CALCA'WHERE Disa='CUSCO' AND Id_Establecimiento='36087';

UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000030666',Nombre_Establecimiento='MENTAL COMUNITARIO URUBAMBA', Codigo_Red='02', Red='CUSCO NORTE',Codigo_MicroRed='07', MicroRed='URUBAMBA', Categoria_Establecimiento='I-2'WHERE Disa='CUSCO' AND Id_Establecimiento='9999148';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000030666',Nombre_Establecimiento='MENTAL COMUNITARIO URUBAMBA', Codigo_Red='02', Red='CUSCO NORTE',Codigo_MicroRed='07', MicroRed='URUBAMBA', Categoria_Establecimiento='I-2'WHERE Disa='CUSCO' AND Id_Establecimiento='39188';

UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000030366',Nombre_Establecimiento='MENTAL COMUNITARIO ESPINAR', Codigo_Red='04', Red='CANAS-CANCHIS-ESPINAR',Codigo_MicroRed='06', MicroRed='YAURI', Categoria_Establecimiento='I-2'WHERE Disa='CUSCO' AND Id_Establecimiento='9999146';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000030366',Nombre_Establecimiento='MENTAL COMUNITARIO ESPINAR', Codigo_Red='04', Red='CANAS-CANCHIS-ESPINAR',Codigo_MicroRed='06', MicroRed='YAURI', Categoria_Establecimiento='I-2'WHERE Disa='CUSCO' AND Id_Establecimiento='39165';

UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000030708',Nombre_Establecimiento='MENTAL COMUNITARIO HUARO', Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='12', MicroRed='URCOS', Categoria_Establecimiento='I-2'WHERE Disa='CUSCO' AND Id_Establecimiento='9999147';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000030708',Nombre_Establecimiento='MENTAL COMUNITARIO HUARO', Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='12', MicroRed='URCOS', Categoria_Establecimiento='I-2'WHERE Disa='CUSCO' AND Id_Establecimiento='39185';

UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000037347',Nombre_Establecimiento='MENTAL SANTO TOMAS', Codigo_Red='06', Red='CHUMBIVILCAS',Codigo_MicroRed='09', MicroRed='SANTO TOMAS', Categoria_Establecimiento='I-2'WHERE Disa='CUSCO' AND Id_Establecimiento='65260';
                                                                                                    
-- ACTUALIZADO HOSPITALES CAT II
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000025210',Nombre_Establecimiento='TUPAC AMARU', Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='00', MicroRed='HOSPITAL', Categoria_Establecimiento='II-E'WHERE Disa='CUSCO' AND Id_Establecimiento='2303';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Nombre_Establecimiento='TUPAC AMARU', MicroRed='HOSPITAL' WHERE Disa='CUSCO' AND Id_Establecimiento='35470';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Nombre_Establecimiento='HOSPITAL SICUANI', MicroRed='HOSPITAL' WHERE Disa='CUSCO' AND Id_Establecimiento='2377';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Nombre_Establecimiento='HOSPITAL SANTO TOMAS', MicroRed='HOSPITAL' WHERE Disa='CUSCO' AND Id_Establecimiento='2397';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Nombre_Establecimiento='HOSPITAL QUILLABAMBA', MicroRed='HOSPITAL' WHERE Disa='CUSCO' AND Id_Establecimiento='2420';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Nombre_Establecimiento='SAN JUAN DE KIMBIRI-VRAEM', MicroRed='HOSPITAL' WHERE Disa='CUSCO' AND Id_Establecimiento='2468';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Nombre_Establecimiento='HOSPITAL ESPINAR', MicroRed='HOSPITAL' WHERE Disa='CUSCO' AND Id_Establecimiento='7111';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Nombre_Establecimiento='HUASQUILLAY' WHERE Disa='CUSCO' AND Id_Establecimiento='7122';

-- ACTUALIZADO IPRESS DE ESSALUD POR RED
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000010077',Nombre_Establecimiento='ESSALUD-PAUCARTAMBO',      Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='06', MicroRed='PAUCARTAMBO' WHERE Disa='CUSCO' AND Id_Establecimiento='11752';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000010065',Nombre_Establecimiento='ESSALUD-SAN SEBASTIAN',    Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='16', MicroRed='CUSCO' WHERE Disa='CUSCO' AND Id_Establecimiento='11734';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000026385',Nombre_Establecimiento='ESSALUD-URCOS',            Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='12', MicroRed='URCOS' WHERE Disa='CUSCO' AND Id_Establecimiento='11741';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000026385',Nombre_Establecimiento='ESSALUD-URCOS',            Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='12', MicroRed='URCOS' WHERE Disa='CUSCO' AND Id_Establecimiento='35998';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000010076',Nombre_Establecimiento='ESSALUD-ACOMAYO',          Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='13', MicroRed='ACOMAYO' WHERE Disa='CUSCO' AND Id_Establecimiento='11751';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000010041',Nombre_Establecimiento='ESSALUD-ADOLFO GUEVARA V.',Codigo_Red='02', Red='CUSCO NORTE',Codigo_MicroRed='02', MicroRed='WANCHAQ' WHERE Disa='CUSCO' AND Id_Establecimiento='11707';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000026183',Nombre_Establecimiento='ESSALUD-METROPOLITANO',    Codigo_Red='02', Red='CUSCO NORTE',Codigo_MicroRed='02', MicroRed='WANCHAQ' WHERE Disa='CUSCO' AND Id_Establecimiento='35670';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000010069',Nombre_Establecimiento='ESSALUD-CALCA',            Codigo_Red='02', Red='CUSCO NORTE',Codigo_MicroRed='06', MicroRed='CALCA' WHERE Disa='CUSCO' AND Id_Establecimiento='11742';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000010073',Nombre_Establecimiento='ESSALUD-MACHU PICCHU',     Codigo_Red='02', Red='CUSCO NORTE',Codigo_MicroRed='07', MicroRed='URUBAMBA' WHERE Disa='CUSCO' AND Id_Establecimiento='11749';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000010062',Nombre_Establecimiento='ESSALUD-QUILLABAMBA',      Codigo_Red='03', Red='LA CONVENCION',Codigo_MicroRed='01', MicroRed='SANTA ANA' WHERE Disa='CUSCO' AND Id_Establecimiento='11724';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000010075',Nombre_Establecimiento='ESSALUD-HUYRO',            Codigo_Red='03', Red='LA CONVENCION',Codigo_MicroRed='02', MicroRed='MARANURA' WHERE Disa='CUSCO' AND Id_Establecimiento='11750';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000034417',Nombre_Establecimiento='ESSALUD-ECHARATE/KITENI',  Codigo_Red='03', Red='LA CONVENCION',Codigo_MicroRed='04', MicroRed='KITENI' WHERE Disa='CUSCO' AND Id_Establecimiento='56124';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000010063',Nombre_Establecimiento='ESSALUD-SICUANI',          Codigo_Red='04', Red='CANAS-CANCHIS-ESPINAR',Codigo_MicroRed='04', MicroRed='TECHO OBRERO' WHERE Disa='CUSCO' AND Id_Establecimiento='11726';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000010061',Nombre_Establecimiento='ESSALUD-ESPINAR',          Codigo_Red='04', Red='CANAS-CANCHIS-ESPINAR',Codigo_MicroRed='06', MicroRed='YAURI' WHERE Disa='CUSCO' AND Id_Establecimiento='11721';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000013185',Nombre_Establecimiento='ESSALUD-SANTO TOMAS',      Codigo_Red='06', Red='CHUMBIVILCAS',Codigo_MicroRed='09', MicroRed='SANTO TOMAS' WHERE Disa='CUSCO' AND Id_Establecimiento='17748';
UPDATE es_ivan.MAESTRO_HIS_ESTABLECIMIENTO SET Codigo_Unico='000027948',Nombre_Establecimiento='ESSALUD-PICHARI',          Codigo_Red='05', Red='KIMBIRI PICHARI',Codigo_MicroRed='02', MicroRed='PICHARI' WHERE Disa='CUSCO' AND Id_Establecimiento='37861' ;

UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000010060',Nombre_Establecimiento='ESSALUD-URUBAMBA', Codigo_Red='02', Red='CUSCO NORTE',Codigo_MicroRed='07', MicroRed='URUBAMBA' WHERE Disa='CUSCO' AND Id_Establecimiento='11718';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000029514',Nombre_Establecimiento='ESSALUD-ANTA', Codigo_Red='02', Red='CUSCO NORTE',Codigo_MicroRed='03', MicroRed='ANTA' WHERE Disa='CUSCO' AND Id_Establecimiento='59135';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000034933',Nombre_Establecimiento='ESSALUD-SANTIAGO', Codigo_Red='02', Red='CUSCO NORTE',Codigo_MicroRed='01', MicroRed='BELEMPAMPA' WHERE Disa='CUSCO' AND Id_Establecimiento='59685';

-- ACTUALIZADO IPRESS DE LA PNP POR RED
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000024663',Nombre_Establecimiento='SANIDAD-SICUANI PNP', Codigo_Red='04', Red='CANAS-CANCHIS-ESPINAR',Codigo_MicroRed='04', MicroRed='TECHO OBRERO' WHERE Disa='CUSCO' AND Id_Establecimiento='33192';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000011744',Nombre_Establecimiento='SANIDAD-QUILLABAMBA PNP', Codigo_Red='03', Red='LA CONVENCION',Codigo_MicroRed='01', MicroRed='SANTA ANA' WHERE Disa='CUSCO' AND Id_Establecimiento='15122';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000011747',Nombre_Establecimiento='SANIDAD-PUCUTO PNP', Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='12', MicroRed='URCOS' WHERE Disa='CUSCO' AND Id_Establecimiento='15127';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000011743',Nombre_Establecimiento='SANIDAD-SANTA ROSA PNP', Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='16', MicroRed='CUSCO' WHERE Disa='CUSCO' AND Id_Establecimiento='12849';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000036660',Nombre_Establecimiento='SANIDAD-PICHARI PNP', Codigo_Red='05', Red='KIMBIRI PICHARI',Codigo_MicroRed='02', MicroRed='PICHARI' WHERE Disa='CUSCO' AND Id_Establecimiento='64771';

-- ACTUALIZADO IPRESS DE LA INPE POR RED
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000018926',Nombre_Establecimiento='INPE-VARONES CUSCO', Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='16', MicroRed='CUSCO' WHERE Disa='CUSCO' AND Id_Establecimiento='29411';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000021187',Nombre_Establecimiento='INPE-MUJERES CUSCO', Codigo_Red='01', Red='CUSCO SUR',Codigo_MicroRed='16', MicroRed='CUSCO' WHERE Disa='CUSCO' AND Id_Establecimiento='30950';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000024653',Nombre_Establecimiento='INPE-QUILLABAMBA', Codigo_Red='03', Red='LA CONVENCION',Codigo_MicroRed='01', MicroRed='SANTA ANA' WHERE Disa='CUSCO' AND Id_Establecimiento='33197';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000024639',Nombre_Establecimiento='INPE-SICUANI', Codigo_Red='04', Red='CANAS-CANCHIS-ESPINAR',Codigo_MicroRed='04', MicroRed='TECHO OBRERO' WHERE Disa='CUSCO' AND Id_Establecimiento='33481';

-- ACTUALIZADO IPRESS DEL EJERCITO POR RED
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000010920',Nombre_Establecimiento='EJERCITO-QUINTA BRIGADA DE MONTAÑA', Codigo_Red='02', Red='CUSCO NORTE', Codigo_MicroRed='01', MicroRed='BELEMPAMPA' WHERE Disa='CUSCO' AND Id_Establecimiento='13725';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000023721',Nombre_Establecimiento='EJERCITO-PERUANO', Codigo_Red='03', Red='LA CONVENCION', Codigo_MicroRed='01', MicroRed='SANTA ANA' WHERE Disa='CUSCO' AND Id_Establecimiento='32850';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000024638',Nombre_Establecimiento='EJERCITO-MILITAR PICHARI', Codigo_Red='05', Red='KIMBIRI PICHARI', Codigo_MicroRed='02', MicroRed='PICHARI' WHERE Disa='CUSCO' AND Id_Establecimiento='33200';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000024583',Nombre_Establecimiento='EJERCITO-KEPASHIATO 314', Codigo_Red='03', Red='LA CONVENCION', Codigo_MicroRed='04', MicroRed='KITENI' WHERE Disa='CUSCO' AND Id_Establecimiento='33487';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000024296',Nombre_Establecimiento='EJERCITO-MIARIA 334', Codigo_Red='03', Red='LA CONVENCION', Codigo_MicroRed='04', MicroRed='KITENI' WHERE Disa='CUSCO' AND Id_Establecimiento='33543';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000024637',Nombre_Establecimiento='EJERCITO-INCAHUASI 331', Codigo_Red='03', Red='LA CONVENCION', Codigo_MicroRed='06', MicroRed='PUCYURA' WHERE Disa='CUSCO' AND Id_Establecimiento='33666';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Unico='000024957',Nombre_Establecimiento='EJERCITO-LA OROYA 34', Codigo_Red='05', Red='KIMBIRI PICHARI', Codigo_MicroRed='01', MicroRed='KIMBIRI' WHERE Disa='CUSCO' AND Id_Establecimiento='34237';

-- PRIVADOS
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Red='21', Red='PRIVADO', Codigo_MicroRed='00', MicroRed='SIN MICRORED' WHERE Disa='CUSCO' AND Descripcion_Sector='PRIVADO';
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Red='22', Red='SAMUE', Codigo_MicroRed='00', MicroRed='SIN MICRORED' WHERE Disa='CUSCO' AND Id_Establecimiento='38075';

-- OTROS
UPDATE es_ivan.maestro_his_establecimiento SET Codigo_Red='23', Red='BENEFICENCIA', Codigo_MicroRed='00', MicroRed='SIN MICRORED' WHERE Disa='CUSCO' AND Descripcion_Sector='OTRO' AND id_establecimiento='17498';

-- DISTRITOS
UPDATE es_ivan.maestro_his_establecimiento SET Ubigueo_Establecimiento='080915', Departamento='CUSCO',Provincia='LA CONVENCION',Distrito='KUMPIRUSHIATO' WHERE Disa='CUSCO' AND Id_Establecimiento='2431';
UPDATE es_ivan.maestro_his_establecimiento SET Ubigueo_Establecimiento='080915', Departamento='CUSCO',Provincia='LA CONVENCION',Distrito='KUMPIRUSHIATO' WHERE Disa='CUSCO' AND Id_Establecimiento='2433';
UPDATE es_ivan.maestro_his_establecimiento SET Ubigueo_Establecimiento='080915', Departamento='CUSCO',Provincia='LA CONVENCION',Distrito='KUMPIRUSHIATO' WHERE Disa='CUSCO' AND Id_Establecimiento='17698';
UPDATE es_ivan.maestro_his_establecimiento SET Ubigueo_Establecimiento='080915', Departamento='CUSCO',Provincia='LA CONVENCION',Distrito='KUMPIRUSHIATO' WHERE Disa='CUSCO' AND Id_Establecimiento='17699';

UPDATE es_ivan.maestro_his_establecimiento SET Ubigueo_Establecimiento='080916', Departamento='CUSCO',Provincia='LA CONVENCION',Distrito='CIELO PUNCO' WHERE Disa='CUSCO' AND Id_Establecimiento='2469';

UPDATE es_ivan.maestro_his_establecimiento SET Ubigueo_Establecimiento='080917', Departamento='CUSCO',Provincia='LA CONVENCION',Distrito='MANITEA' WHERE Disa='CUSCO' AND Id_Establecimiento='2470';
UPDATE es_ivan.maestro_his_establecimiento SET Ubigueo_Establecimiento='080917', Departamento='CUSCO',Provincia='LA CONVENCION',Distrito='MANITEA' WHERE Disa='CUSCO' AND Id_Establecimiento='2472';
UPDATE es_ivan.maestro_his_establecimiento SET Ubigueo_Establecimiento='080917', Departamento='CUSCO',Provincia='LA CONVENCION',Distrito='MANITEA' WHERE Disa='CUSCO' AND Id_Establecimiento='8720';

UPDATE es_ivan.maestro_his_establecimiento SET Ubigueo_Establecimiento='080918', Departamento='CUSCO',Provincia='LA CONVENCION',Distrito='UNION ASHANINKA' WHERE Disa='CUSCO' AND Id_Establecimiento='2494';


DROP FUNCTION IF EXISTS es_ivan.union_eess_region();

CREATE OR REPLACE FUNCTION es_ivan.union_eess_region()
RETURNS TABLE (
    id_eess INT,
    cod_eess TEXT,
    cod_ipress TEXT,
    nombre_eess TEXT,
    cat TEXT,
    desc_eess TEXT,
    ubigueo_eess TEXT,
    red_mred TEXT,
    cod_red TEXT,
    red TEXT,
    cod_mred TEXT,
    microred TEXT,
    cod_dpto TEXT,
    dpto TEXT,
    cod_prov TEXT,
    provincia TEXT,
    cod_dist TEXT,
    distrito TEXT,
    cod_ue INT,
    desc_ue TEXT,
    sector TEXT
)
LANGUAGE sql
AS
$$
SELECT DISTINCT
    -- 🔥 ID como entero
    e.id_establecimiento AS id_eess,

    e.codigo_unico AS cod_eess,

    -- 🔥 equivalente a PATINDEX → quitar ceros a la izquierda
    ltrim(e.codigo_unico, '0') AS cod_ipress,

    e.nombre_establecimiento AS nombre_eess,
    c.cat,

    -- 🔥 CONCAT equivalente
    e.codigo_unico || ' ' || e.nombre_establecimiento AS desc_eess,

    e.ubigueo_establecimiento AS ubigueo_eess,

    -- 🔥 CONCAT
    e.codigo_red || e.codigo_microred AS red_mred,

    e.codigo_red AS cod_red,
    e.red,
    e.codigo_microred AS cod_mred,
    e.microred,

    substring(e.ubigueo_establecimiento,1,2) AS cod_dpto,
    e.departamento AS dpto,
    substring(e.ubigueo_establecimiento,3,2) AS cod_prov,
    e.provincia,
    substring(e.ubigueo_establecimiento,5,2) AS cod_dist,
    e.distrito,

    -- 🔥 conversión segura (porque suele ser TEXT)
    CASE 
        WHEN c.cod_ue ~ '^[0-9]+$' THEN c.cod_ue::INT
        ELSE NULL
    END AS cod_ue,

    c.desc_ue,
    e.descripcion_sector AS sector

FROM es_ivan.maestro_his_establecimiento e
INNER JOIN es_ivan.maestro_eess_susalud c
    ON e.codigo_unico = c.cod_unico

WHERE e.disa = 'CUSCO'
AND (
    (e.descripcion_sector = 'GOBIERNO REGIONAL'
        AND e.id_establecimiento NOT IN (44397,44720,9999020,2383,2331,35363,6947)
    )

    OR (e.descripcion_sector = 'ESSALUD')

    OR (e.descripcion_sector = 'PRIVADO'
        AND c.cat NOT IN ('I-1','I-2','I-3','I-4','Sin Categoría'))

    OR e.descripcion_sector IN (
        'SANIDAD DE LA POLICIA NACIONAL DEL PERU',
        'SANIDAD DEL EJERCITO',
        'INPE'
    )

    OR (e.descripcion_sector = 'OTRO'
        AND c.cat NOT IN ('I-1','I-2','I-3','I-4','Sin Categoría'))
);
$$;


DROP FUNCTION IF EXISTS es_ivan.crear_eess();

CREATE OR REPLACE FUNCTION es_ivan.crear_eess()
RETURNS TABLE (
    id_eess INT,
    cod_eess TEXT,
    cod_ipress TEXT,
    nombre_eess TEXT,
    desc_eess TEXT,
    cat TEXT,
    ubigueo_eess TEXT,
    red_mred TEXT,
    cod_red TEXT,
    red TEXT,
    cod_mred TEXT,
    microred TEXT,
    cod_dpto TEXT,
    dpto TEXT,
    cod_prov TEXT,
    provincia TEXT,
    cod_dist TEXT,
    distrito TEXT,
    cod_ue INT,
    desc_ue TEXT,
    sector TEXT
)
LANGUAGE sql
AS
$$
SELECT
    id_eess,
    cod_eess,
    cod_ipress,
    nombre_eess,
    desc_eess,
    cat,
    ubigueo_eess,
    red_mred,
    cod_red,
    red,
    cod_mred,
    microred,
    cod_dpto,
    dpto,
    cod_prov,
    provincia,
    cod_dist,
    distrito,
    cod_ue,
    desc_ue,
    sector
FROM es_ivan.union_eess_region()

-- 🔥 IMPORTANTE: usar enteros (no texto)
WHERE id_eess NOT IN (
    9999024,9999146,9999147,9999020,
    9999148,9999021,9999023,9999022,
    11741,2303
);
$$;



DROP PROCEDURE IF EXISTS es_ivan.inserta_eess;

CREATE OR REPLACE PROCEDURE es_ivan.inserta_eess()
LANGUAGE plpgsql
AS $$
BEGIN

    -- 🔥 Vaciar tabla destino
    TRUNCATE TABLE es_ivan.eess2025;

    -- 🔥 Insertar datos desde la función
    INSERT INTO es_ivan.eess2025 (
        id_eess, cod_eess, nombre_eess, desc_eess, cat,
        ubigueo_eess, red_mred, cod_red, red, cod_mred,
        microred, cod_dpto, dpto, cod_prov, provincia,
        cod_dist, distrito, cod_ue, desc_ue, sector
    )
    SELECT
        id_eess, cod_eess, nombre_eess, desc_eess, cat,
        ubigueo_eess, red_mred, cod_red, red, cod_mred,
        microred, cod_dpto, dpto, cod_prov, provincia,
        cod_dist, distrito, cod_ue, desc_ue, sector
    FROM es_ivan.crear_eess();

END;
$$;



CALL es_ivan.inserta_eess();
















/*
--TABLA MESES
DROP TABLE IF EXISTS es_ivan.meses;

CREATE TABLE es_ivan.meses (
    mes SMALLINT NOT NULL,
    cmes CHAR(2) NOT NULL,
    nommes VARCHAR(12) NOT NULL,
    anio SMALLINT NOT NULL
);


--INSERTAR MESES
INSERT INTO es_ivan.meses (mes, cmes, nommes, anio)
SELECT 
    m,
    lpad(m::text, 2, '0'),
    to_char(make_date(2026, m, 1), 'Month'),
    2026
FROM generate_series(1,12) AS m;


-- ELIMINAR TABLA SI EXISTE
DROP TABLE IF EXISTS es_ivan.edades;

-- CREAR TABLA
CREATE TABLE es_ivan.edades (
    edad INTEGER NOT NULL,
    tip_edad VARCHAR(1),
    tipo_edad VARCHAR(1),
    edad_r INTEGER,
    descr_edad VARCHAR(20),
    g_edad VARCHAR(20),
    etapas VARCHAR(20),
    edad_epi VARCHAR(25),
    campo_id INTEGER,
    edad_susalud INTEGER,
    edad2 VARCHAR(20),
    edad3 VARCHAR(20)
);


INSERT INTO es_ivan.edades (
    edad, tip_edad, tipo_edad, edad_r, descr_edad,
    g_edad, etapas, edad_epi, campo_id, edad_susalud, edad2, edad3
) VALUES
-- 🔹 DIAS (0 - 28)
(1,'D','3',1,'1 DIA','0 - 28 DIAS','NINO','INFANCIA (<1 AÑO)',1,1,'0 MESES','0M - 5M'),
(2,'D','3',2,'2 DIAS','0 - 28 DIAS','NINO','INFANCIA (<1 AÑO)',1,1,'0 MESES','0M - 5M'),
(3,'D','3',3,'3 DIAS','0 - 28 DIAS','NINO','INFANCIA (<1 AÑO)',1,1,'0 MESES','0M - 5M'),
(4,'D','3',4,'4 DIAS','0 - 28 DIAS','NINO','INFANCIA (<1 AÑO)',1,1,'0 MESES','0M - 5M'),
(5,'D','3',5,'5 DIAS','0 - 28 DIAS','NINO','INFANCIA (<1 AÑO)',1,1,'0 MESES','0M - 5M'),
(6,'D','3',6,'6 DIAS','0 - 28 DIAS','NINO','INFANCIA (<1 AÑO)',1,1,'0 MESES','0M - 5M'),
(7,'D','3',7,'7 DIAS','0 - 28 DIAS','NINO','INFANCIA (<1 AÑO)',1,1,'0 MESES','0M - 5M'),
(8,'D','3',8,'8 DIAS','0 - 28 DIAS','NINO','INFANCIA (<1 AÑO)',1,1,'0 MESES','0M - 5M'),
(9,'D','3',9,'9 DIAS','0 - 28 DIAS','NINO','INFANCIA (<1 AÑO)',1,1,'0 MESES','0M - 5M'),
(10,'D','3',10,'10 DIAS','0 - 28 DIAS','NINO','INFANCIA (<1 AÑO)',1,1,'0 MESES','0M - 5M'),

-- 🔹 FIN NEONATAL
(29,'D','3',29,'29 DIAS','29 DIAS - 11 MESES','NINO','INFANCIA (<1 AÑO)',1,1,'0 MESES','0M - 5M'),

-- 🔹 MESES
(1,'M','2',51,'1 MES','29 DIAS - 11 MESES','NINO','INFANCIA (<1 AÑO)',1,1,'1 MES','0M - 5M'),
(2,'M','2',52,'2 MESES','29 DIAS - 11 MESES','NINO','INFANCIA (<1 AÑO)',2,1,'2 MESES','0M - 5M'),
(6,'M','2',56,'6 MESES','29 DIAS - 11 MESES','NINO','INFANCIA (<1 AÑO)',2,1,'6 MESES','6M - 11M'),
(11,'M','2',61,'11 MESES','29 DIAS - 11 MESES','NINO','INFANCIA (<1 AÑO)',2,1,'11 MESES','6M - 11M'),

-- 🔹 AÑOS
(1,'A','1',101,'1 AÑO','1 AÑO','NINO','PREESCOLAR (1 - 4 AÑOS)',3,2,'1 AÑO','12M-23M'),
(2,'A','1',102,'2 AÑOS','2 AÑOS','NINO','PREESCOLAR (1 - 4 AÑOS)',4,2,'2 AÑOS','24M-36M'),
(5,'A','1',105,'5 AÑOS','5 - 9 AÑOS','NINO','ESCOLAR (5 - 17 AÑOS)',7,3,'5 AÑOS','5A'),
(10,'A','1',110,'10 AÑOS','10 - 14 AÑOS','NINO','ESCOLAR (5 - 17 AÑOS)',8,4,'10 AÑOS','10A'),
(15,'A','1',115,'15 AÑOS','15 - 19 AÑOS','ADOLESCENTE','ESCOLAR (5 - 17 AÑOS)',10,5,'15 AÑOS','15A'),
(20,'A','1',120,'20 AÑOS','20 - 49 AÑOS','JOVEN','20 - 49 AÑOS',11,6,'20 AÑOS','20A'),
(30,'A','1',130,'30 AÑOS','20 - 49 AÑOS','ADULTO','20 - 49 AÑOS',13,8,'30 AÑOS','30A'),
(40,'A','1',140,'40 AÑOS','20 - 49 AÑOS','ADULTO','20 - 49 AÑOS',13,10,'40 AÑOS','40A'),
(50,'A','1',150,'50 AÑOS','50 - 59 AÑOS','ADULTO','50 - 59 AÑOS',15,12,'50 AÑOS','50A'),
(60,'A','1',160,'60 AÑOS','60 - 64 AÑOS','ADULTO MAYOR','60 - 64 AÑOS',16,14,'60 AÑOS','60A'),
(65,'A','1',165,'65 AÑOS','65 - + AÑOS','ADULTO MAYOR','65 - + AÑOS',16,15,'65 AÑOS','65A');
*/

CALL es_ivan.sp_generar_eess2025();

*/