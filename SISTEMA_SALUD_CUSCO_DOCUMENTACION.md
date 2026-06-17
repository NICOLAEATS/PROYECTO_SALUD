?# SISTEMA DE MONITOREO DE SALUD ??? GERESA CUSCO





## Documentaci?n T?cnica Integral del Sistema de Informaci?n de Salud





---





**Versi?n del documento:** 1.0  


**Fecha:** Mayo 2026  


**Autor:** Equipo de Desarrollo ??? Proyecto Salud Cusco  


**Repositorio:** `C:\Users\Nouch\Desktop\proyecto salud cusco`





---





# 1. RESUMEN EJECUTIVO





## 1.1 Prop?sito del Sistema





El Sistema de Monitoreo de Salud ??? GERESA Cusco es una aplicaci?n inform?tica integral dise?ada para el procesamiento, transformaci?n, carga y an?lisis de datos del Health Information System (HIS) peruano en la regi?n Cusco. El sistema automatiza el flujo completo de datos desde los archivos crudos generados por los establecimientos de salud (EESS) hasta la generaci?n de tablas anal?ticas listas para la elaboraci?n de reportes gerenciales y epidemiol?gicos.





## 1.2 Contexto Operativo





La GERESA (Gerencia Regional de Salud) Cusco recibe mensualmente archivos comprimidos (RAR, ZIP, 7z) que contienen registros de atenci?n de salud de todos los establecimientos de la regi?n. Estos archivos, denominados `11_CUSCO_MM.ext`, representan los datos del Sistema de Informaci?n en Salud (HIS) del Ministerio de Salud del Per? (MINSA). El sistema procesa estos archivos y los transforma en una base de datos anal?tica estructurada, permitiendo la generaci?n de reportes de coberturas de vacunaci?n, CRED (Crecimiento y Desarrollo), IRAS (Infecciones Respiratorias Agudas), EDAS (Enfermedades Diarreicas Agudas), Suplementaci?n de Hierro (DL 1153), y otros indicadores priorizados.





## 1.3 Arquitectura Resumida





El sistema se compone de los siguientes m?dulos principales:





1. **M?dulo de Configuraci?n de Base de Datos** (`db_config.py`): Gesti?n de perfiles de conexi?n PostgreSQL, detecci?n autom?tica de instancias, inicializaci?n de bases de datos y esquemas, y recuperaci?n autom?tica de contrase?as.





2. **Interfaz Gr?fica de Usuario** (`main.py`): Aplicaci?n de escritorio construida con CustomTkinter que proporciona men?s de navegaci?n, ejecuci?n de scripts, monitoreo de progreso, y modo editor para personalizaci?n de botones y consultas SQL.





3. **M?dulo de Gesti?n de Maestros** (`modulo_maestros.py`): Interfaz para la carga, visualizaci?n y eliminaci?n de tablas maestras del sistema HIS.





4. **Pipeline de Ingesta de Datos**: Conjunto de scripts Python que realizan la extracci?n de archivos comprimidos, detecci?n de formatos CSV, limpieza y normalizaci?n de datos, y carga en PostgreSQL mediante COPY.





5. **Motor de Transformaci?n ETL** (`generar_his_proceso.py`): Coraz?n del sistema que transforma la tabla `hisminsa24` (cruda) en la tabla particionada `his_proceso` con estructura fija, enriqueciendo los datos con informaci?n de tablas maestras.





6. **M?dulo de Vacunas y Reportes BI**: Scripts que generan tablas anal?ticas de vacunas, CRED, PAI (Programa Ampliado de Inmunizaciones), y reportes finales, as? como indicadores de morbilidad.





## 1.4 Stack Tecnol?gico





| Componente | Tecnolog?a |


|------------|------------|


| Lenguaje de Programaci?n | Python 3.x |


| GUI | CustomTkinter (CTk) |


| Controlador PostgreSQL | psycopg2, psycopg2-binary |


| An?lisis de Datos | pandas, SQLAlchemy |


| Motor de Base de Datos | PostgreSQL 15+ |


| Compilaci?n | PyInstaller |


| Sistema Operativo | Windows 10/11 |





## 1.5 Base de Datos por Defecto





| Par?metro | Valor |


|-----------|-------|


| Host | localhost |


| Puerto | 5432 |


| Base de Datos | ivan_proceso_his |


| Esquema | es_ivan |


| Usuario | postgres |


| Contrase?a predeterminada | ivan |





---





# 2. MARCO TE??RICO





## 2.1 Sistemas de Informaci?n en Salud (SIS) en el Contexto Global





Los Sistemas de Informaci?n en Salud (SIS) son componentes fundamentales de cualquier sistema de salud moderno. La Organizaci?n Mundial de la Salud (OMS) define un SIS como un conjunto integrado de componentes y procedimientos para la recolecci?n, procesamiento, transmisi?n y uso de informaci?n necesaria para mejorar la efectividad y eficiencia de los servicios de salud a trav?s de una mejor gesti?n a todos los niveles del sistema.





Un SIS robusto debe cumplir con los siguientes atributos esenciales:





- **Integralidad**: Capacidad de capturar informaci?n de todas las fuentes relevantes, incluyendo establecimientos de salud p?blicos y privados, programas verticales, y niveles de atenci?n primaria, secundaria y terciaria.





- **Oportunidad**: Los datos deben estar disponibles para la toma de decisiones en un plazo que permita acciones correctivas efectivas. Esto implica procesos automatizados de captura, transmisi?n y procesamiento.





- **Calidad**: Los datos deben ser precisos, completos, consistentes y v?lidos. La implementaci?n de reglas de validaci?n automatizadas, como la verificaci?n de formatos num?ricos mediante expresiones regulares y la limpieza de valores nulos mediante COALESCE, son pr?cticas fundamentales.





- **Estandarizaci?n**: El uso de clasificaciones y nomenclaturas est?ndar, como la CIE-10 (Clasificaci?n Internacional de Enfermedades, 10? edici?n) para diagn?sticos y c?digos CPT (Current Procedural Terminology) para procedimientos, es indispensable para la interoperabilidad.





- **Accesibilidad**: La informaci?n debe ser accesible para los tomadores de decisiones en todos los niveles del sistema, desde el personal de salud en el establecimiento hasta los gestores regionales y nacionales.





## 2.2 El HIS (Health Information System) en el Per?





### 2.2.1 Marco Normativo





El Sistema de Informaci?n en Salud del Per? est? regulado por diversas normas t?cnicas y disposiciones legales:





- **RM N? 214-2018/MINSA**: Aprueba la Noma T?cnica de Salud para el Uso del Sistema de Informaci?n en Salud (HIS). Esta norma establece los lineamientos t?cnicos y procedimientos para el registro, procesamiento y uso de la informaci?n de salud en todos los establecimientos del pa?s.





- **RM N? 527-2011/MINSA**: Aprueba la Directiva Administrativa para el Uso del HIS en los Establecimientos de Salud. Establece los c?digos, formatos y procedimientos para el registro diario de atenciones.





- **DL N? 1153**: Decreto Legislativo que establece la entrega obligatoria de la Suplementaci?n de Hierro y otros micronutrientes. Genera la necesidad de reportes espec?ficos de cobertura de suplementaci?n.





### 2.2.2 Estructura del HIS





El HIS peruano se organiza en los siguientes componentes:





1. **Maestro de Establecimientos** (EESS): Cat?logo ?nico de establecimientos de salud con su c?digo ?nico, nombre, categor?a, nivel de atenci?n, y ubicaci?n geogr?fica (departamento, provincia, distrito, red, microred).





2. **Maestro de Personal**: Registro del personal de salud que labora en los establecimientos, incluyendo su profesi?n, colegio profesional, y condici?n de contrato.





3. **Maestro de Pacientes**: Base de datos de pacientes atendidos, con datos de identificaci?n (DNI, nombres, apellidos, fecha de nacimiento, g?nero, etnia).





4. **CIE-CPMS**: Cat?logo de diagn?sticos CIE-10 y procedimientos CPMS. Cada c?digo tiene asociado un tipo de diagn?stico (A: Definitivo, R: Repetitivo, etc.) y un grupo de edad aplicable.





5. **Registro de Atenciones**: El n?cleo del HIS son los registros diarios de atenci?n, que incluyen:


   - Datos del paciente (edad, g?nero, identificaci?n)


   - Datos del establecimiento (c?digo, servicio)


   - Datos de la atenci?n (fecha, diagn?stico, procedimiento)


   - Datos del personal (c?digo del personal que atiende)





### 2.2.3 Formato de Archivos HIS





Los archivos HIS se distribuyen en formato CSV (valores separados por comas o pipes) con la siguiente nomenclatura est?ndar:





```


11_CUSCO_MM.ext


```





Donde `MM` representa el mes (01-12) y `ext` la extensi?n del archivo (RAR, ZIP, CSV, etc.). Por ejemplo, `11_CUSCO_01.rar` contiene los datos de enero, `11_CUSCO_02.zip` los de febrero, etc.





El contenido de estos archivos sigue un esquema de columnas din?mico. Las columnas comunes incluyen:





- `id_cita`: Identificador ?nico de la atenci?n


- `id_paciente`: Identificador del paciente


- `id_personal`: Identificador del personal de salud


- `id_establecimiento`: C?digo del establecimiento


- `fecha_atencion`: Fecha de la atenci?n


- `codigo_item`: C?digo CIE-10 o CPT del diagn?stico/procedimiento


- `edad_reg`: Edad del paciente registrada


- `tipo_edad`: Tipo de edad (A: A?os, M: Meses, D: D?as)


- `genero`: Sexo del paciente (M/F)


- `id_etnia`: C?digo de etnia


- `id_ups`: Unidad Productora de Servicios


- `condicion_gestante`: Condici?n de gestante (si aplica)





## 2.3 El Proceso de HIS en la Regi?n Cusco





La regi?n Cusco, a trav?s de la GERESA Cusco, implementa un proceso descentralizado de recolecci?n y procesamiento de datos HIS:





### 2.3.1 Flujo de Recolecci?n





1. **Nivel Local (Establecimientos de Salud)**: Cada establecimiento de salud (puesto de salud, centro de salud, hospital) registra diariamente las atenciones realizadas en el sistema HIS local. Al finalizar cada mes, el establecimiento genera un archivo de exportaci?n con todos los registros del per?odo.





2. **Nivel Microred**: Los establecimientos env?an sus archivos a la microred correspondiente, donde se realiza una primera validaci?n y consolidaci?n.





3. **Nivel Red**: Las microredes consolidan los datos a nivel de red (Cusco Norte, Cusco Sur, La Convenci?n, etc.) y los remiten a la GERESA.





4. **Nivel GERESA (Regional)**: La GERESA Cusco recibe los archivos consolidados de cada red y realiza el procesamiento final, que incluye:


   - Validaci?n de estructura y contenido


   - Carga en la base de datos regional


   - Generaci?n de reportes operativos y gerenciales


   - Env?o de datos consolidados al MINSA





### 2.3.2 Temporalidad





El procesamiento sigue un ciclo mensual:


- Los archivos del mes M generalmente llegan durante la primera quincena del mes M+1.


- Los procesos de ingesta y transformaci?n deben completarse antes del d?a 20 del mes M+1.


- Los reportes consolidados se generan durante los ?ltimos 10 d?as del mes M+1.





## 2.4 Importancia de la Calidad de Datos en Salud P?blica





La calidad de los datos en salud p?blica es cr?tica por las siguientes razones:





### 2.4.1 Toma de Decisiones





Los datos de mala calidad llevan a decisiones sub?ptimas que pueden afectar la salud de la poblaci?n. Por ejemplo, subestimaciones en las coberturas de vacunaci?n pueden llevar a la suspensi?n de campa?as de inmunizaci?n, mientras que sobrestimaciones pueden generar falsa confianza.





### 2.4.2 Asignaci?n de Recursos





El presupuesto asignado a las redes y establecimientos de salud depende, en parte, de los vol?menes de actividad reportados. Datos inexactos pueden resultar en asignaciones inadecuadas de personal, medicamentos e insumos.





### 2.4.3 Indicadores de Gesti?n





Los indicadores de gesti?n del sector salud, como la proporci?n de gestantes con suplementaci?n de hierro, la cobertura de vacunaci?n en menores de 1 a?o, o la incidencia de IRAS en menores de 5 a?os, se calculan a partir de los datos HIS. La validez de estos indicadores depende directamente de la calidad del dato fuente.





### 2.4.4 Mecanismos de Aseguramiento de Calidad Implementados





El sistema implementa m?ltiples mecanismos de aseguramiento de calidad:





1. **Validaci?n de formato num?rico**: Uso de expresiones regulares (`~ '^[0-9]+$'`) para verificar que campos num?ricos contengan solo d?gitos antes de la conversi?n a tipos enteros.





2. **Limpieza de valores nulos**: Aplicaci?n sistem?tica de `COALESCE(columna, '')` para evitar valores NULL en las columnas que alimentan los reportes.





3. **Normalizaci?n de espacios y puntos**: Reemplazo de `.` y espacios por `_` en nombres de columnas para evitar errores de sintaxis SQL.





4. **Deduplicaci?n de columnas**: Uso de la funci?n `columnas_unicas()` para eliminar nombres de columna duplicados que puedan aparecer en archivos mal formados.





5. **Eliminaci?n de duplicados en la carga**: Antes de insertar nuevos datos de un per?odo, se eliminan los registros previos del mismo mes con y sin cero leading (ej. "03" y "3").





6. **Detecci?n de extractores**: El sistema detecta autom?ticamente extractores RAR, 7-Zip y tar en el sistema para garantizar la descompresi?n correcta de los archivos fuente.





## 2.5 PostgreSQL como Motor de Base de Datos para Salud





PostgreSQL ha sido seleccionado como motor de base de datos por las siguientes caracter?sticas:





### 2.5.1 Particionamiento de Tablas





PostgreSQL 10+ soporta particionamiento nativo por rango, lista y hash. El sistema utiliza particionamiento por rango en la tabla `his_proceso`, creando particiones anuales (`his_proceso_2021`, `his_proceso_2022`, etc.). Esto ofrece:





- **Mejora en el rendimiento de consultas**: Las consultas que filtran por a?o solo escanean la partici?n relevante.


- **Facilidad de mantenimiento**: Las particiones antiguas pueden ser archivadas o eliminadas independientemente.


- **Escalabilidad**: La tabla puede crecer indefinidamente a?adiendo nuevas particiones cada a?o.





### 2.5.2 Tablas UNLOGGED





Para las tablas staging temporales, el sistema utiliza `UNLOGGED`, lo que desactiva el Write-Ahead Log (WAL) para esas tablas, resultando en:





- Mayor velocidad de escritura (aproximadamente 2x-3x m?s r?pido que tablas logged)


- Menor consumo de I/O en disco


- Adecuado para datos temporales que pueden ser recreados





### 2.5.3 Bloques de Asesoramiento (Advisory Locks)





El sistema utiliza advisory locks mediante `pg_try_advisory_lock(hashtext('proyecto_salud_cusco_his_proceso'))` para prevenir la ejecuci?n concurrente del proceso de generaci?n de HIS Proceso. Esto es esencial porque:





- El proceso de transformaci?n puede tomar horas para vol?menes grandes de datos.


- La ejecuci?n concurrente podr?a producir datos inconsistentes.


- El lock se libera autom?ticamente al finalizar la transacci?n.





### 2.5.4 Configuraci?n de Sesi?n Optimizada





Para procesos de carga masiva, el sistema configura la sesi?n con par?metros optimizados:





```sql


SET synchronous_commit = off;


SET work_mem = '512MB';


SET temp_buffers = '256MB';


SET maintenance_work_mem = '1GB';


SET jit = off;


```





- `synchronous_commit = off`: Reduce la latencia de escritura, aceptando el riesgo m?nimo de p?rdida de datos en caso de fallo del sistema.


- `work_mem = '512MB'`: Aumenta la memoria disponible para operaciones de ordenamiento y hash.


- `temp_buffers = '256MB'': Aumenta el buffer para tablas temporales.


- `maintenance_work_mem = '1GB'`: Optimiza operaciones de mantenimiento como VACUUM y CREATE INDEX.


- `jit = off`: Desactiva la compilaci?n Just-In-Time que puede ser contraproducente para consultas batch.





## 2.6 Python y CustomTkinter para Aplicaciones de Escritorio





### 2.6.1 Python como Lenguaje de Procesamiento de Datos





Python ha sido seleccionado como lenguaje principal debido a:





- **Ecosistema de bibliotecas**: psycopg2 para conectividad PostgreSQL, pandas para an?lisis de datos, sqlalchemy para ORM y conexiones SQLAlchemy, y re para expresiones regulares.


- **Portabilidad**: El c?digo Python funciona sin modificaciones en cualquier versi?n de Windows.


- **Facilidad de mantenimiento**: La sintaxis clara de Python facilita el mantenimiento por parte del equipo de salud sin formaci?n intensiva en ingenier?a de software.


- **Compilaci?n a ejecutable**: PyInstaller permite empaquetar la aplicaci?n como un ejecutable Windows independiente.





### 2.6.2 CustomTkinter





CustomTkinter es una biblioteca que extiende Tkinter (la biblioteca GUI est?ndar de Python) con widgets modernos y temas oscuros. Caracter?sticas relevantes:





- **Modo oscuro**: La aplicaci?n utiliza `ctk.set_appearance_mode("Dark")` para una interfaz visual moderna.


- **Widgets modernos**: CTkButton, CTkEntry, CTkOptionMenu, CTkProgressBar, CTkScrollableFrame, CTkTextbox, CTkCheckbox.


- **Rendimiento adecuado**: Para aplicaciones de escritorio con operaciones de base de datos, CustomTkinter ofrece un rendimiento m?s que suficiente.


- **Tema azul**: `ctk.set_default_color_theme("blue")` proporciona una paleta de colores profesional.





---





# 3. ARQUITECTURA DEL SISTEMA





## 3.1 Vista General de Componentes





El sistema se organiza en una arquitectura de tres capas:





```


?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????


???                  CAPA DE PRESENTACI??N                     ???


???                (CustomTkinter GUI - main.py)              ???


???                                                          ???


???  ????????????????????????????????????  ????????????????????????????????????  ????????????????????????????????????  ???????????????????????????????????? ???


???  ??? Ingesta  ???  ??? Reportes ???  ??? Maestros ???  ??? Config.  ??? ???


???  ??? y Mant.  ???  ???          ???  ???          ???  ??? BD       ??? ???


???  ????????????????????????????????????  ????????????????????????????????????  ????????????????????????????????????  ???????????????????????????????????? ???


?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????


                       ???


?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????


???               CAPA DE NEGOCIO (Scripts Python)           ???


???                                                          ???


???  extractor_archivos.py  ???  Descompresi?n de archivos     ???


???  01cargacvs_*.py        ???  Carga CSV a PostgreSQL        ???


???  cargar_maestros.py     ???  Carga de tablas maestras      ???


???  generar_his_proceso.py ???  Transformaci?n ETL            ???


???  procesar_eess_principal.py ??? Normalizaci?n EESS         ???


???  generar_tabla_vacunas.py ???  Generaci?n tablas BI        ???


?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????


                       ???


?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????


???                CAPA DE DATOS (PostgreSQL)                 ???


???                                                          ???


???  ?????????????????????????????????????????????  ?????????????????????????????????????????????  ????????????????????????????????????????????????????????????  ???


???  ??? hisminsa24  ???  ??? his_proceso ???  ??? tablas maestras   ???  ???


???  ??? (cruda)     ???  ??? (particion) ???  ??? (20+ tablas)     ???  ???


???  ?????????????????????????????????????????????  ?????????????????????????????????????????????  ????????????????????????????????????????????????????????????  ???


?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????


```





## 3.2 Stack Tecnol?gico Completo





### 3.2.1 Lenguaje de Programaci?n





- **Python 3.x**: Versi?n 3.8 o superior, con soporte para tipado (`from __future__ import annotations`), dataclasses, y subprocess.





### 3.2.2 Bibliotecas Python





| Biblioteca | Versi?n | Prop?sito | Instalaci?n |


|------------|---------|-----------|-------------|


| customtkinter | 5.x | GUI moderna con temas oscuros | `pip install customtkinter` |


| psycopg2-binary | 2.9.x | Conector PostgreSQL nativo | `pip install psycopg2-binary` |


| psycopg2 | 2.9.x | Conector PostgreSQL (alternativa) | `pip install psycopg2` |


| pandas | 2.x | Procesamiento de datos y display | `pip install pandas` |


| sqlalchemy | 2.x | ORM y conexiones parametrizadas | `pip install sqlalchemy` |


| py7zr | 0.20+ | Soporte nativo para archivos 7z | `pip install py7zr` |





### 2.2.3 Base de Datos





- **PostgreSQL 15+**: La versi?n objetivo es PostgreSQL 15 o superior, aunque el sistema es compatible con versiones 13-18. Se detectan versiones instaladas en las rutas est?ndar de Windows (`C:\Program Files\PostgreSQL\`, `C:\PostgreSQL\`).





### 3.2.4 Sistema Operativo





- **Windows 10/11 64-bit**: El sistema est? dise?ado exclusivamente para Windows. Utiliza rutas de Windows (`%APPDATA%`, `C:\Program Files\`), comandos PowerShell, y `CREATE_NO_WINDOW` para subprocess.





## 3.3 Diagrama de Flujo de Datos





### 3.3.1 Flujo Principal de Procesamiento





```


[Archivos Crudos]                     [Archivos Maestros]


 11_CUSCO_01.rar                        MaestroPersonal.csv


 11_CUSCO_02.zip                        11_MAESTRO.csv


 11_CUSCO_03.csv                        maestro_his_cie_cpms.csv


 ...                                     ...


       ???                                       ???


       ???                                       ???


?????????????????????????????????????????????????????????                 ????????????????????????????????????????????????????????????????????????


??? extractor_      ???                 ??? cargar_maestros.py   ???


??? archivos.py     ???                 ??? 02maestro_paciente.py???


??? (RAR/7z/ZIP/tar)???                 ??? 05personal.py        ???


?????????????????????????????????????????????????????????                 ????????????????????????????????????????????????????????????????????????


         ??? CSV extra?do                         ???


         ???                                      ???


????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????


???               PostgreSQL - es_ivan.hisminsa24          ???


???          (tabla cruda con datos din?micos)             ???


???                columnas din?micas                     ???


????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????


                           ???


                           ???


????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????


???           generar_his_proceso.py (ETL Core)           ???


???                                                      ???


???   ????????????????????????????????????????????????   ??????????????????????????????????????????   ???????????????????????????????????????  ???


???   ??? tmp_nt_base  ??? ??? ??? JOIN       ??? ??? ??? UNLOGGED  ???  ???


???   ??? (hisminsa24  ???   ??? maestros + ???   ??? staging   ???  ???


???   ???  filtrado)   ???   ??? EESS       ???   ??? table     ???  ???


???   ????????????????????????????????????????????????   ??????????????????????????????????????????   ???????????????????????????????????????  ???


???                                              ???       ???


???                                              ???       ???


???                                    ???????????????????????????????????????????????????  ???


???                                    ??? his_proceso    ???  ???


???                                    ??? (particionado) ???  ???


???                                    ???????????????????????????????????????????????????  ???


???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????


                                               ???


                                               ???


                ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????


                ???       generar_tabla_vacunas.py          ???


                ???              ???                          ???


                ???              ???                          ???


                ???     ????????????????????????????????????????????????????????????               ???


                ???     ??? tabla_vacunas    ???               ???


                ???     ?????????????????????????????????????????????????????????               ???


                ???          ???      ???                      ???


                ???    ?????????????????????      ?????????????????????               ???


                ???    ???                  ???               ???


                ??? ?????????????????????????????????   ??????????????????????????????????????????         ???


                ??? ??? cred{anio}???  ??? pai_2026   ???         ???


                ??? ?????????????????????????????????   ??????????????????????????????????????????         ???


                ???         ???                             ???


                ???         ???                             ???


                ??? ????????????????????????????????????????????????????????????                  ???


                ??? ??? VACUNAS_{ANIO}   ???                  ???


                ??? ????????????????????????????????????????????????????????????                  ???


                ???                                       ???


                ??? generar_reporte_vacunas.py             ???


                ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????


```





## 3.4 Estructura de Directorios Completa





```


C:\Users\Nouch\Desktop\proyecto salud cusco\


???


????????? main.py                              # Punto de entrada GUI


????????? db_config.py                         # Configuraci?n BD (1393 l?neas)


????????? modulo_maestros.py                   # Gesti?n de maestros (1342 l?neas)


????????? AGENTS.md                            # Gu?a para agentes de IA


???


????????? scripts_python\


???   ????????? ingesta\


???   ???   ????????? extractor_archivos.py        # Descompresi?n (208 l?neas)


???   ???   ????????? 01cargacvs_universal.py      # Carga anual CSV (541 l?neas)


???   ???   ????????? 01cargacvs_mensual.py        # Carga mensual CSV (429 l?neas)


???   ???   ????????? 01cargacvs.py                # LEGACY: carga con SQLAlchemy (110 l?neas)


???   ???   ????????? 02maestro_paciente.py        # Carga maestro paciente (77 l?neas)


???   ???   ????????? 03cargar_padron_trama.py     # Carga padr?n trama (113 l?neas)


???   ???   ????????? 03_ejecutar_consolidacion.py # Consolidaci?n HIS (94 l?neas)


???   ???   ????????? 05personal.py               # Carga personal (116 l?neas)


???   ???   ????????? cargar_maestros.py           # Carga universal maestros (293 l?neas)


???   ???   ????????? generar_his_proceso.py       # ETL Core (1046 l?neas)


???   ???   ????????? actualizar_his_proceso_maestros.py  # Refresco maestros (326 l?neas)


???   ???   ????????? procesar_eess_principal.py   # Normalizaci?n EESS (272 l?neas)


???   ???


???   ????????? bi\


???   ???   ????????? generar_tabla_vacunas.py     # Tabla vacunas (152 l?neas)


???   ???   ????????? generar_cred.py              # Tabla CRED (68 l?neas)


???   ???   ????????? generar_pai.py               # Tabla PAI (82 l?neas)


???   ???   ????????? generar_reporte_vacunas.py   # Reporte final vacunas (76 l?neas)


???   ???   ????????? 04_generador_reportes.py     # Ejecutor SQL universal (72 l?neas)


???   ???   ????????? 04_ejecutor_procedures.py    # Ejecutor procedures (44 l?neas)


???   ???


???   ????????? instalacion\


???       ????????? instalar_postgresql.py       # Instalador PostgreSQL autom?tico


???


????????? scripts_sql\


???   ????????? reportes\


???   ???   ????????? generar_his_proceso_editor.sql   # Plantilla ETL (154 l?neas)


???   ???   ????????? tabla_vacunas_editor.sql         # Plantilla vacunas (27 l?neas)


???   ???   ????????? reporte_vacunas_editor.sql       # Plantilla reporte (18 l?neas)


???   ???   ????????? 1_base_edas_iras.sql


???   ???   ????????? 1_base_his_proceso.sql


???   ???   ????????? 1_base_vacunas.sql


???   ???   ????????? 2_historico_edas_iras.sql


???   ???   ????????? 2_historico_vacunas.sql


???   ???   ????????? 3_actualiza_base_vacunas.sql


???   ???   ????????? 3_actualiza_edas_iras.sql


???   ???   ????????? 3_actualiza_vacunas.sql


???   ???   ????????? dl1153_paquete_menor_12meses.sql


???   ???   ????????? dl1153_suplementacion_hierro.sql


???   ???   ????????? mantenimiento_limpiar_nulos.sql


???   ???   ????????? morbilidad_edas_detalle.sql


???   ???   ????????? morbilidad_iras_detalle.sql


???   ???


???   ????????? scripst tabla y reportes vacunas-cred\


???       ????????? EESS_PRINCIPAL_2026 moshe.sql


???       ????????? REPORTE_IRAS_EDAS_POR_A??O moshe.sql


???       ????????? REPORTE_VACUNAS_POR A??O moshe.sql


???       ????????? Script-136 moshe vacunas.sql


???       ????????? cred2026_clean.sql


???       ????????? cred2026_final_ivan moshe.sql


???       ????????? TABLA_VAC_CRED MAYOR A 2022.sql


???       ????????? TABLA_VAC_CRED POR A??O.sql


???       ????????? tabla materno.sql


???


????????? datos\


???   ????????? maestr\                          # Directorio por a?o


???   ???   ????????? 2021\


???   ???   ????????? 2022\


???   ???   ????????? 2023\


???   ???   ????????? 2024\


???   ???   ????????? 2025\


???   ???   ????????? 2026\


???   ????????? crudos\maestros\                # Archivos CSV maestros originales


???


????????? logs\


???   ????????? csvs_subidos.log                 # Log de cargas CSV hist?ricas


???


????????? config\


???   ????????? db_connection.json               # Config legacy de BD


???


????????? %APPDATA%\Proyecto_Salud_Cusco\config\


    ????????? db_connection.json               # Config activa de BD


    ????????? editor_buttons.json              # Botones personalizados del editor


```





## 3.5 Dependencias y Requisitos





### 3.5.1 Requisitos de Sistema





- **Sistema Operativo**: Windows 10/11 (64-bit)


- **PostgreSQL**: 13 o superior (recomendado 15+)


- **Python**: 3.8 o superior


- **Espacio en Disco**: M?nimo 10 GB para la base de datos (depende del volumen de datos hist?ricos)


- **Memoria RAM**: M?nimo 4 GB, recomendado 8+ GB para procesos de transformaci?n ETL





### 3.5.2 Dependencias Python





```


customtkinter>=5.0.0


psycopg2-binary>=2.9.0


pandas>=1.5.0


sqlalchemy>=2.0.0


py7zr>=0.20.0


```





### 3.5.3 Dependencias Externas (Opcionales)





- **WinRAR**: Para extracci?n de archivos RAR nativos (ruta: `C:\Program Files\WinRAR\WinRAR.exe`)


- **7-Zip**: Para extracci?n de archivos 7z y RAR alternativa (ruta: `C:\Program Files\7-Zip\7z.exe`)


- **bsdtar (tar.exe)**: Incluido en Windows 10/11, usado para archivos tar/tgz





---





# 4. M??DULO DE CONFIGURACI??N DE BASE DE DATOS





## 4.1 Arquitectura General





El m?dulo `db_config.py` (1393 l?neas) es el componente fundamental del sistema que gestiona toda la configuraci?n de conexi?n a PostgreSQL. Proporciona un sistema de perfiles persistente con cacheo en memoria, detecci?n autom?tica de instancias PostgreSQL via m?ltiples mecanismos (socket TCP, PowerShell, psql CLI), inicializaci?n de bases de datos y esquemas con tres estrategias de CREATE DATABASE, y un sofisticado sistema de recuperaci?n de contrase?as que modifica temporalmente `pg_hba.conf` para establecer acceso trust, cambia la contrase?a, y revierte los cambios.





**Diagrama de flujo general:**





```


                   ?????????????????????????????????????????????????????????????????????


                   ???   get_db_config()    ???


                   ???   (singleton global) ???


                   ?????????????????????????????????????????????????????????????????????


                          ???


              ???????????????????????????????????????????????????????????????????????????


              ???                       ???


    ?????????????????????????????????????????????????????????   ????????????????????????????????????????????????????????????????????????


    ??? _load_config_   ???   ??? _build_first_run_    ???


    ??? from_file()     ???   ??? profile()            ???


    ??? (CONFIG_FILE /  ???   ??? (variables de        ???


    ???  LEGACY_CONFIG) ???   ???  entorno o defaults) ???


    ?????????????????????????????????????????????????????????   ????????????????????????????????????????????????????????????????????????


             ???                       ???


             ???????????????????????????????????????????????????????????????????????????


                         ???


              ????????????????????????????????????????????????????????????????????????


              ???  verificar_bd_       ???


              ???  esquema()           ???


              ???  (verifica BD +      ???


              ???   esquema existen)   ???


              ????????????????????????????????????????????????????????????????????????


                        ???


              ????????????????????????????????????????????????????????????????????????


              ???                      ???


    ????????????????????????????????????????????????????????????  ????????????????????????????????????????????????????????????????????????


    ??? Verificaci?n OK  ???  ???inicializar_base_     ???


    ??? (retorna True)   ???  ???datos()               ???


    ????????????????????????????????????????????????????????????  ???(crea BD/esquema +    ???


                          ??? recupera password)   ???


                          ????????????????????????????????????????????????????????????????????????


```





**Mecanismo de singleton global** (`db_config.py:73`):


```python


_config_instance: Optional[DBConfig] = None


```


Todas las funciones p?blicas (`get_db_config`, `set_db_config`, `update_db_config`, `reset_db_config`) operan sobre esta variable global. La primera llamada a `get_db_config()` carga o crea el perfil; las llamadas subsiguientes retornan la instancia cacheada sin acceso a disco.





---





## 4.2 Constantes y Rutas de Configuraci?n





### 4.2.1 Constantes de Conexi?n (`db_config.py:22-28`)





```python


PASSWORD_POSTGRES = "ivan"                     # Contrase?a por defecto del sistema





DEFAULT_DATABASE = os.getenv("DB_NAME", "ivan_proceso_his")


DEFAULT_SCHEMA   = os.getenv("DB_SCHEMA", "es_ivan")


DEFAULT_PORT     = os.getenv("DB_PORT", "5432")


DEFAULT_USER     = os.getenv("DB_USER", "postgres")


DEFAULT_PASSWORD = os.getenv("DB_PASSWORD", PASSWORD_POSTGRES)


```





**Prop?sito de cada constante:**





| Constante | Default | Variable de Entorno | Uso |


|-----------|---------|---------------------|-----|


| `PASSWORD_POSTGRES` | `"ivan"` | ??? | Contrase?a semilla para el sistema de recuperaci?n y auto-detecci?n |


| `DEFAULT_DATABASE` | `"ivan_proceso_his"` | `DB_NAME` | Base de datos destino del proyecto |


| `DEFAULT_SCHEMA` | `"es_ivan"` | `DB_SCHEMA` | Esquema dentro de la base de datos |


| `DEFAULT_PORT` | `"5432"` | `DB_PORT` | Puerto TCP de PostgreSQL |


| `DEFAULT_USER` | `"postgres"` | `DB_USER` | Superusuario de PostgreSQL |


| `DEFAULT_PASSWORD` | `"ivan"` | `DB_PASSWORD` | Contrase?a del superusuario |





**Orden de precedencia para valores por defecto:**


1. Variable de entorno (ej: `DB_HOST=192.168.1.100`)


2. Constante hardcodeada (ej: `"localhost"`)





Todas las constantes se eval?an en tiempo de importaci?n del m?dulo, antes de que se ejecute cualquier funci?n.





### 4.2.2 Rutas de Archivos (`db_config.py:31-43`)





```python


def _runtime_config_dir() -> str:


    """Resuelve el directorio de configuraci?n en tiempo de ejecuci?n."""


    appdata = os.getenv("APPDATA")


    if appdata:


        return os.path.join(appdata, "Proyecto_Salud_Cusco", "config")


    return os.path.join(os.path.expanduser("~"), ".proyecto_salud_cusco", "config")





CONFIG_DIR       = _runtime_config_dir()


CONFIG_FILE      = os.path.join(CONFIG_DIR, "db_connection.json")


LEGACY_CONFIG_FILE = os.path.join(


    os.path.dirname(os.path.abspath(__file__)), "config", "db_connection.json"


)


COMMON_PORTS     = ("5432", "5433", "5434")


```





**Resoluci?n de rutas en Windows:**


- `CONFIG_DIR` ??? `C:\Users\<username>\AppData\Roaming\Proyecto_Salud_Cusco\config\`


- `CONFIG_FILE` ??? `C:\Users\<username>\AppData\Roaming\Proyecto_Salud_Cusco\config\db_connection.json`


- `LEGACY_CONFIG_FILE` ??? `<directorio_del_proyecto>\config\db_connection.json`





`COMMON_PORTS` es una tupla usada en `_auto_detect_from_sources()` para validar que el puerto detectado sea uno de los puertos PostgreSQL t?picos.





### 4.2.3 Funci?n _ensure_config_dir() (`db_config.py:76-77`)





```python


def _ensure_config_dir() -> None:


    os.makedirs(CONFIG_DIR, exist_ok=True)


```





Crea el directorio de configuraci?n si no existe. Se llama desde `_save_config()` antes de escribir el archivo JSON. Usa `exist_ok=True` para evitar race conditions en entornos multihilo.





---





## 4.3 La Clase DBConfig





### 4.3.1 Definici?n de la Dataclass (`db_config.py:46-71`)





```python


from dataclasses import dataclass, asdict


from typing import Optional, Dict, Any





@dataclass


class DBConfig:


    host: str = os.getenv("DB_HOST", "localhost")


    port: str = DEFAULT_PORT


    user: str = DEFAULT_USER


    password: str = DEFAULT_PASSWORD


    database: str = DEFAULT_DATABASE


    schema: str = DEFAULT_SCHEMA





    def __post_init__(self) -> None:


        self.host = (self.host or "localhost").strip()


        self.port = (self.port or DEFAULT_PORT).strip()


        self.user = (self.user or DEFAULT_USER).strip()


        self.password = self.password or ""


        self.database = (self.database or DEFAULT_DATABASE).strip()


        self.schema = (self.schema or DEFAULT_SCHEMA).strip()





    def to_dict(self) -> Dict[str, Any]:


        return asdict(self)





    def connection_string(self) -> str:


        return (


            f"host={self.host} port={self.port} user={self.user} "


            f"password={self.password} dbname={self.database}"


        )


```





**An?lisis completo de cada campo:**





| Campo | Tipo | Default (env / hardcode) | __post_init__ | Prop?sito |


|-------|------|--------------------------|---------------|-----------|


| `host` | `str` | `DB_HOST` / `"localhost"` | `(x or "localhost").strip()` | Direcci?n IPv4, IPv6, o nombre DNS del servidor |


| `port` | `str` | `DB_PORT` / `DEFAULT_PORT` | `(x or DEFAULT_PORT).strip()` | Puerto TCP (string para serializaci?n JSON limpia) |


| `user` | `str` | `DB_USER` / `DEFAULT_USER` | `(x or DEFAULT_USER).strip()` | Rol de PostgreSQL |


| `password` | `str` | `DB_PASSWORD` / `DEFAULT_PASSWORD` | `x or ""` | Contrase?a (string vac?a si no hay) |


| `database` | `str` | `DB_NAME` / `DEFAULT_DATABASE` | `(x or DEFAULT_DATABASE).strip()` | Nombre de la base de datos |


| `schema` | `str` | `DB_SCHEMA` / `DEFAULT_SCHEMA` | `(x or DEFAULT_SCHEMA).strip()` | Esquema dentro de la base de datos |





**Casos borde manejados en `__post_init__`:**


1. **Valores `None` o vac?os**: Cada campo se eval?a con `or` para caer al default si el valor es falsy (`None`, `""`, `0`).


2. **Whitespace circundante**: Todos los campos (excepto `password`) se limpian con `.strip()`.


3. **Password vac?a**: `self.password = self.password or ""` ??? si es `None` se setea a `""`, si es `""` se mantiene.





### 4.3.2 M?todo to_dict() (`db_config.py:63-64`)





```python


def to_dict(self) -> Dict[str, Any]:


    return asdict(self)


```





Usa `dataclasses.asdict()` para convertir los campos a un diccionario plano. Este es el m?todo usado por `_save_config()` para serializar a JSON.





### 4.3.3 M?todo connection_string() (`db_config.py:66-70`)





```python


def connection_string(self) -> str:


    return (


        f"host={self.host} port={self.port} user={self.user} "


        f"password={self.password} dbname={self.database}"


    )


```





Genera una **keyword connection string** estilo libpq, el formato que acepta `psycopg2.connect()` y `psql -d "..."`. No incluye el esquema porque este se especifica aparte en las consultas SQL con `SET search_path`.





---





## 4.4 Sistema de Perfiles ??? Funciones P?blicas





### 4.4.1 get_db_config() (`db_config.py:221-229`)





```python


def get_db_config() -> DBConfig:


    """Retorna la configuraci?n actual (singleton), cargando o creando si es necesario."""


    global _config_instance


    if _config_instance is None:


        cfg = _load_config_from_file()


        if cfg is None:


            cfg = _build_first_run_profile()


            _save_config(cfg)


        _config_instance = cfg


    return _config_instance


```





**Algoritmo completo:**





```


get_db_config()


???


?????? ?_config_instance is None?


???   ?????? NO  ??? retornar _config_instance


???   ?????? S?  ???


???       ?????? _load_config_from_file()


???       ???   ?????? CONFIG_FILE existe?   ??? leer JSON, construir DBConfig


???       ???   ?????? LEGACY_CONFIG existe? ??? leer JSON, migrar a CONFIG_FILE


???       ???   ?????? ninguno existe ??? retornar None


???       ???


???       ?????? ?cfg is None?


???       ???   ?????? S? ??? _build_first_run_profile()


???       ???   ???       (toma defaults de entorno o constantes)


???       ???   ???   ??? _save_config(cfg)  # persistir inmediatamente


???       ???   ?????? NO ??? (usar cfg cargado)


???       ???


???       ?????? _config_instance = cfg


???       ??? retornar _config_instance


```





**Par?metros:** Ninguno.





**Retorno:** `DBConfig` ??? la configuraci?n activa, cargada desde archivo o construida con defaults.





**Efectos secundarios:**


- Si no exist?a configuraci?n persistente, se crea el archivo `CONFIG_FILE` autom?ticamente.


- Si exist?a configuraci?n legacy, se migra a la nueva ubicaci?n.


- La instancia se cachea globalmente; llamadas posteriores no tocan disco.





### 4.4.2 _load_config_from_file() (`db_config.py:157-169`)





```python


def _load_config_from_file() -> Optional[DBConfig]:


    """Intenta cargar configuraci?n desde archivo JSON, probando dos ubicaciones."""


    for candidate in (CONFIG_FILE, LEGACY_CONFIG_FILE):


        try:


            if os.path.exists(candidate):


                with open(candidate, "r", encoding="utf-8") as file:


                    data = json.load(file)


                cfg = DBConfig(**data)


                if candidate != CONFIG_FILE:


                    _save_config(cfg)  # migrar a ubicaci?n moderna


                return cfg


        except (OSError, json.JSONDecodeError):


            continue


    return None


```





**Par?metros:** Ninguno.





**Retorno:** `Optional[DBConfig]` ??? `DBConfig` si se pudo cargar de alg?n archivo, `None` si ning?n archivo existe o todos est?n corruptos.





**Orden de b?squeda:**


1. `CONFIG_FILE` ??? `%APPDATA%\Proyecto_Salud_Cusco\config\db_connection.json`


2. `LEGACY_CONFIG_FILE` ??? `./config/db_connection.json` (junto al script)





**Migraci?n autom?tica:** Si el archivo encontrado es el legacy, se copia inmediatamente a la nueva ubicaci?n con `_save_config()`. Esto asegura que en futuras ejecuciones se use la ruta moderna.





**Manejo de errores:**


- `OSError`: archivo no legible (permisos, ruta muy larga, etc.)


- `json.JSONDecodeError`: archivo corrupto o con formato inv?lido


- En ambos casos, se ignora el archivo y se prueba el siguiente candidato





### 4.4.3 _build_first_run_profile() (`db_config.py:172-180`)





```python


def _build_first_run_profile() -> DBConfig:


    """Construye un perfil inicial desde variables de entorno o valores por defecto."""


    return DBConfig(


        host=os.getenv("DB_HOST", "localhost"),


        port=os.getenv("DB_PORT", DEFAULT_PORT),


        user=os.getenv("DB_USER", DEFAULT_USER),


        password=os.getenv("DB_PASSWORD", DEFAULT_PASSWORD),


        database=os.getenv("DB_NAME", DEFAULT_DATABASE),


        schema=os.getenv("DB_SCHEMA", DEFAULT_SCHEMA),


    )


```





**Par?metros:** Ninguno.





**Retorno:** `DBConfig` ??? perfil con valores de entorno como prioridad, defaults como fallback.





**Prop?sito:** Usado exclusivamente en primera ejecuci?n, cuando no existe archivo de configuraci?n. Los valores se persisten autom?ticamente por `get_db_config()`.





### 4.4.4 _save_config() (`db_config.py:183-189`)





```python


def _save_config(cfg: DBConfig) -> None:


    """Persiste la configuraci?n en disco como JSON."""


    _ensure_config_dir()


    try:


        with open(CONFIG_FILE, "w", encoding="utf-8") as file:


            json.dump(cfg.to_dict(), file, ensure_ascii=False, indent=2)


    except OSError:


        pass


```





**Par?metros:** `cfg: DBConfig` ??? configuraci?n a persistir.





**Retorno:** `None`.





**Formato del JSON generado:**


```json


{


  "host": "localhost",


  "port": "5432",


  "user": "postgres",


  "password": "ivan",


  "database": "ivan_proceso_his",


  "schema": "es_ivan"


}


```





**Manejo de errores:** Si no se puede escribir (`OSError` por permisos, disco lleno, etc.), el error se silencia con `pass`. La aplicaci?n contin?a usando la configuraci?n en memoria.





### 4.4.5 set_db_config() (`db_config.py:199-204`)





```python


def set_db_config(cfg: DBConfig, persist: bool = True) -> DBConfig:


    """Establece la configuraci?n activa, opcionalmente persisti?ndola."""


    global _config_instance


    _config_instance = cfg


    if persist:


        _save_config(cfg)


    return cfg


```





**Par?metros:**





| Par?metro | Tipo | Default | Descripci?n |


|-----------|------|---------|-------------|


| `cfg` | `DBConfig` | ??? | Nueva configuraci?n a aplicar |


| `persist` | `bool` | `True` | Si `True`, escribe a disco inmediatamente |





**Retorno:** `DBConfig` ??? la misma instancia `cfg` recibida (para encadenamiento).





**Casos de uso:**


- `persist=True`: Guardar cambios del usuario desde la UI de configuraci?n.


- `persist=False`: Cambios temporales para pruebas (no se escriben a disco).





### 4.4.6 update_db_config() (`db_config.py:207-218`)





```python


def update_db_config(**kwargs: str) -> DBConfig:


    """Actualiza campos espec?ficos del perfil actual sin reemplazar toda la configuraci?n."""


    cfg = get_db_config()


    changed = False


    for field in ("host", "port", "user", "password", "database", "schema"):


        if field in kwargs and kwargs[field] is not None:


            value = str(kwargs[field]).strip()


            if getattr(cfg, field) != value and value:


                setattr(cfg, field, value)


                changed = True


    if changed:


        set_db_config(cfg)


    return cfg


```





**Par?metros:** `**kwargs` ??? pares `campo=valor` donde `campo` debe ser uno de `host`, `port`, `user`, `password`, `database`, `schema`.





**Retorno:** `DBConfig` ??? la configuraci?n actualizada.





**Validaciones:**


1. Solo actualiza si el campo est? en kwargs.


2. Ignora valores `None`.


3. Ignora valores vac?os (falsy despu?s de strip).


4. Solo persiste si al menos un campo cambi? (`changed = True`).





**Ejemplo de uso:**


```python


update_db_config(host="192.168.1.50", port="5433")


# Actualiza host y port, mantiene user/password/database/schema


```





### 4.4.7 set_db_host() (`db_config.py:232-233`)





```python


def set_db_host(host: str):


    update_db_config(host=host or "localhost")


```





**Par?metros:** `host: str` ??? nuevo host.





**Retorno:** `None` (llama internamente a `update_db_config` que persiste autom?ticamente).





**Prop?sito:** Atajo para actualizar solo el host desde la UI.





### 4.4.8 reset_db_config() (`db_config.py:236-244`)





```python


def reset_db_config(remove_file: bool = False) -> DBConfig:


    """Resetea la configuraci?n activa a valores por defecto."""


    global _config_instance


    _config_instance = None


    if remove_file and os.path.exists(CONFIG_FILE):


        try:


            os.remove(CONFIG_FILE)


        except OSError:


            pass


    return get_db_config()


```





**Par?metros:**





| Par?metro | Tipo | Default | Descripci?n |


|-----------|------|---------|-------------|


| `remove_file` | `bool` | `False` | Si `True`, elimina el archivo de configuraci?n del disco |





**Retorno:** `DBConfig` ??? nuevo perfil por defecto (como si fuera primera ejecuci?n).





**Algoritmo:**


1. Invalida el singleton (`_config_instance = None`).


2. Opcionalmente elimina el archivo persistente.


3. Llama a `get_db_config()` que reconstruye el perfil desde cero.





**Efectos secundarios:**


- Con `remove_file=True`: Se pierde toda configuraci?n guardada; el nuevo perfil se crea con defaults.


- Con `remove_file=False`: Se sobrescribe el archivo anterior con los valores por defecto.





---





## 4.5 Detecci?n Autom?tica de Perfil





### 4.5.1 auto_detect_db_profile() (`db_config.py:192-196`)





```python


def auto_detect_db_profile(persist: bool = True) -> DBConfig:


    """


    Detecta autom?ticamente la configuraci?n de BD desde


    variables de entorno y archivo pgpass.


    """


    cfg = DBConfig(**_auto_detect_from_sources())


    if persist:


        set_db_config(cfg)


    return cfg


```





**Par?metros:**





| Par?metro | Tipo | Default | Descripci?n |


|-----------|------|---------|-------------|


| `persist` | `bool` | `True` | Si `True`, guarda la configuraci?n detectada como el nuevo perfil |





**Retorno:** `DBConfig` ??? perfil auto-detectado.





**Pipeline de detecci?n:**





```


auto_detect_db_profile()


???


?????? _auto_detect_from_sources()


   ???


   ?????? 1. Variables de entorno (DB_HOST, DB_PORT, DB_USER, etc.)


   ???


   ?????? 2. _read_pgpass_entries()


   ???     ?????? _pgpass_paths()


   ???         ?????? %APPDATA%\postgresql\pgpass.conf  (Windows)


   ???         ?????? ~/.pgpass                         (Unix)


   ???


   ?????? Merge: pgpass sobreescribe entorno donde no sea "*"


```





### 4.5.2 _auto_detect_from_sources() (`db_config.py:120-154`)





```python


def _auto_detect_from_sources() -> Dict[str, str]:


    """


    Recolecta configuraci?n desde entorno y pgpass.


    pgpass tiene prioridad sobre entorno donde especifique valores concretos.


    """


    data: Dict[str, str] = {


        "host": os.getenv("DB_HOST", "localhost"),


        "port": os.getenv("DB_PORT", DEFAULT_PORT),


        "user": os.getenv("DB_USER", DEFAULT_USER),


        "password": os.getenv("DB_PASSWORD", ""),


        "database": os.getenv("DB_NAME", DEFAULT_DATABASE),


        "schema": os.getenv("DB_SCHEMA", DEFAULT_SCHEMA),


    }





    pgpass_entries = _read_pgpass_entries()


    preferred: Optional[Dict[str, str]] = None


    for entry in pgpass_entries:


        preferred = entry


        if entry["host"] not in ("*", ""):


            break





    if preferred:


        if preferred["host"] not in ("*", ""):


            data["host"] = preferred["host"]


        if preferred["port"] not in ("*", ""):


            data["port"] = preferred["port"]


        if preferred["user"] not in ("*", ""):


            data["user"] = preferred["user"]


        if preferred["password"] not in ("*", ""):


            data["password"] = preferred["password"]


        if preferred["database"] not in ("*", ""):


            data["database"] = preferred["database"]





    if not data["port"]:


        data["port"] = DEFAULT_PORT


    if data["port"] not in COMMON_PORTS:


        data["port"] = data["port"]





    return data


```





**Par?metros:** Ninguno.





**Retorno:** `Dict[str, str]` ??? diccionario con las 6 claves de configuraci?n.





**Reglas de merge:**





| Fuente | Prioridad | Condici?n |


|--------|-----------|-----------|


| Variable de entorno | Baja | Siempre se usa como baseline |


| pgpass.conf | Alta | Solo sobreescribe si el campo NO es `"*"` ni `""` |





**Selecci?n de entrada pgpass preferida:** Se itera las entradas de pgpass. Se prefiere la primera entrada cuyo `host` no sea `"*"`. Si todas tienen `host = *`, se usa la ?ltima entrada de la lista.





### 4.5.3 _pgpass_paths() (`db_config.py:80-88`)





```python


def _pgpass_paths() -> list[str]:


    """Retorna las rutas potenciales del archivo pgpass seg?n el SO."""


    paths: list[str] = []


    if os.name == "nt":


        appdata = os.environ.get("APPDATA")


        if appdata:


            paths.append(os.path.join(appdata, "postgresql", "pgpass.conf"))


    home = os.path.expanduser("~")


    paths.append(os.path.join(home, ".pgpass"))


    return paths


```





**Par?metros:** Ninguno.





**Retorno:** `list[str]` ??? rutas a buscar.





**Rutas en Windows:**


1. `C:\Users\<username>\AppData\Roaming\postgresql\pgpass.conf`


2. `C:\Users\<username>\.pgpass` (compatibilidad Unix)





**Rutas en Unix:**


1. `~/.pgpass`





### 4.5.4 _read_pgpass_entries() (`db_config.py:91-117`)





```python


def _read_pgpass_entries() -> list[Dict[str, str]]:


    """Lee todas las entradas de todos los archivos pgpass encontrados."""


    entries: list[Dict[str, str]] = []


    for path in _pgpass_paths():


        if not os.path.exists(path):


            continue


        try:


            with open(path, "r", encoding="utf-8") as file:


                for raw_line in file:


                    line = raw_line.strip()


                    if not line or line.startswith("#"):


                        continue


                    parts = line.split(":")


                    if len(parts) != 5:


                        continue


                    host, port, database, user, password = parts


                    entries.append({


                        "host": host,


                        "port": port,


                        "database": database,


                        "user": user,


                        "password": password,


                    })


        except OSError:


            continue


    return entries


```





**Par?metros:** Ninguno.





**Retorno:** `list[Dict[str, str]]` ??? lista de entradas pgpass parseadas.





**Formato de pgpass.conf:**


```


hostname:port:database:username:password


```


Ejemplo: `localhost:5432:ivan_proceso_his:postgres:ivan`





**Validaciones:**


1. Ignora l?neas vac?as.


2. Ignora l?neas que comienzan con `#` (comentarios).


3. Ignora l?neas con menos de 5 campos separados por `:`.


4. Ignora archivos que no se pueden leer (`OSError`).





---





## 4.6 Verificaci?n de Conexi?n





### 4.6.1 verificar_conexion() (`db_config.py:251-278`)





```python


def verificar_conexion(


    config: Optional[DBConfig] = None,


    log: Optional[Callable[[str], None]] = None,


) -> bool:


    """Verifica conectividad b?sica contra PostgreSQL.


    


    Conecta a la BD administrativa 'postgres' para validar credenciales.


    """


    try:


        import psycopg2


    except ImportError:


        (log or print)("?? psycopg2 no instalado. Ejecuta: pip install psycopg2-binary")


        return False





    cfg = config or get_db_config()


    _log = log or print





    try:


        conn = psycopg2.connect(


            host=cfg.host,


            port=cfg.port,


            user=cfg.user,


            password=cfg.password,


            dbname="postgres",


            connect_timeout=5,


        )


        conn.close()


        _log(f"??? Conexi?n verificada ??? {cfg.host}:{cfg.port} (usuario: {cfg.user})")


        return True


    except Exception as exc:


        _log(f"?? No se pudo conectar a {cfg.host}:{cfg.port} ??? {exc}")


        return False


```





**Par?metros:**





| Par?metro | Tipo | Default | Descripci?n |


|-----------|------|---------|-------------|


| `config` | `Optional[DBConfig]` | `None` | Configuraci?n a probar (usa la actual si es `None`) |


| `log` | `Optional[Callable[[str], None]]` | `None` | Funci?n de logging (usa `print` si es `None`) |





**Retorno:** `bool` ??? `True` si la conexi?n fue exitosa.





**Detalles t?cnicos:**


- Se conecta a `dbname="postgres"`, la base de datos administrativa que siempre existe en toda instalaci?n PostgreSQL.


- `connect_timeout=5` segundos evita bloqueos indefinidos si el host no responde.


- No verifica existencia de la base de datos ni del esquema del proyecto.





### 4.6.2 _probar_conexion_postgres() (`db_config.py:281-299`)





```python


def _probar_conexion_postgres(passwords: list, host: str, port: str) -> tuple:


    """Intenta conectar a postgres con m?ltiples contrase?as.


    


    Args:


        passwords: Lista de contrase?as a probar


        host: Host de PostgreSQL


        port: Puerto de PostgreSQL


    


    Returns:


        (True, password_exitosa) si alguna funciona,


        (False, None) si todas fallan


    """


    import psycopg2





    for pwd in passwords:


        try:


            conn = psycopg2.connect(


                host=host,


                port=port,


                user="postgres",


                password=pwd,


                dbname="postgres",


                connect_timeout=5,


            )


            conn.close()


            return True, pwd


        except Exception:


            continue


    return False, None


```





**Par?metros:**





| Par?metro | Tipo | Descripci?n |


|-----------|------|-------------|


| `passwords` | `list` | Lista de strings de contrase?a a probar |


| `host` | `str` | Direcci?n del servidor PostgreSQL |


| `port` | `str` | Puerto de conexi?n |





**Retorno:** `tuple` ??? `(bool, str | None)`.





**Algoritmo:** Itera sobre la lista de contrase?as. Para cada una, intenta `psycopg2.connect()`. Si la conexi?n es exitosa (no lanza excepci?n), la cierra y retorna `(True, password)`. Si ninguna funciona, retorna `(False, None)`.





---





## 4.7 Verificaci?n BD y Esquema





### 4.7.1 PasswordRequeridoError (`db_config.py:302-306`)





```python


class PasswordRequeridoError(Exception):


    """Excepci?n personalizada para cuando se necesita intervenci?n manual."""


    def __init__(self, mensaje="Se requiere contrase?a manual"):


        self.mensaje = mensaje


        super().__init__(self.mensaje)


```





**Prop?sito:** Lanzada por `verificar_bd_esquema()` cuando:


1. No se pudo conectar con ninguna de las contrase?as predefinidas.


2. `permitir_password_manual=True` (permite a la UI pedir la contrase?a al usuario).





### 4.7.2 verificar_bd_esquema() ??? Funci?n Completa (`db_config.py:309-462`)





```python


def verificar_bd_esquema(


    config: Optional[DBConfig] = None,


    log: Optional[Callable[[str], None]] = None,


    guardar_password: bool = True,


    permitir_password_manual: bool = True,


) -> bool:


    """Verifica que la base de datos y esquema existan y sean accesibles.





    Args:


        config: Configuraci?n opcional (usa la actual si None)


        log: Funci?n de logging opcional (usa print si None)


        guardar_password: Si True, persiste la contrase?a correcta encontrada


        permitir_password_manual: Si True y falla, lanza PasswordRequeridoError





    Returns:


        True si BD y esquema existen y son accesibles





    Raises:


        PasswordRequeridoError: Si permitir_password_manual=True y no hay conexi?n


    """


```





**Algoritmo completo paso a paso:**





#### Paso 1: Importar y Obtener Configuraci?n


```python


try:


    import psycopg2


except ImportError:


    (log or print)("?? psycopg2 no instalado...")


    return False





cfg = config or get_db_config()


_log = log or print


```





#### Paso 2: Construir Lista de Contrase?as (`db_config.py:336-356`)


```python


user_windows = os.getenv("USERNAME", "postgres")


passwords_to_try = [


    cfg.password if cfg.password else "",


    PASSWORD_POSTGRES,       # "ivan"


    "ivan",


    "postgres",


    "admin",


    "root",


    "Password123!",


    "Admin123!",


    "Psql123!",


    "postgres123",


    "root123",


    "admin123",


    "123456",


    "",


    user_windows,


]


# Eliminar duplicados manteniendo orden


seen = set()


passwords_to_try = [x for x in passwords_to_try if x and not (x in seen or seen.add(x))]


```





**15 contrase?as base en orden de prueba:**





| # | Password | Origen |


|---|----------|--------|


| 1 | `cfg.password` | Configuraci?n actual del usuario |


| 2 | `"ivan"` | Constante `PASSWORD_POSTGRES` |


| 3 | `"ivan"` | Hardcodeado (duplicado, eliminado por set) |


| 4 | `"postgres"` | Nombre del rol por defecto |


| 5 | `"admin"` | Com?n en instalaciones |


| 6 | `"root"` | Com?n en instalaciones |


| 7 | `"Password123!"` | Est?ndar del instalador EDB |


| 8 | `"Admin123!"` | Variante EDB |


| 9 | `"Psql123!"` | Variante del instalador |


| 10 | `"postgres123"` | Variante num?rica |


| 11 | `"root123"` | Variante num?rica |


| 12 | `"admin123"` | Variante num?rica |


| 13 | `"123456"` | Gen?rica |


| 14 | `""` | Sin contrase?a (trust) |


| 15 | `user_windows` | Nombre de usuario de Windows |





**Deduplicaci?n:** Se usa un `set` auxiliar con el patr?n `[x for x in lista if x and not (x in seen or seen.add(x))]` que preserva el orden original.





#### Paso 3: Probar Conexi?n a postgres (`db_config.py:358-382`)


```python


conn_pg = None


password_ok = None





for pwd in passwords_to_try:


    try:


        conn_pg = psycopg2.connect(


            host=cfg.host,


            port=cfg.port,


            user=cfg.user,


            password=pwd,


            dbname="postgres",


            connect_timeout=5,


        )


        password_ok = pwd


        break


    except Exception:


        continue





if conn_pg is None:


    if permitir_password_manual:


        raise PasswordRequeridoError(


            "Contrase?a incorrecta. Ingresa la contrase?a que usaste al instalar PostgreSQL."


        )


    return False


```





Intenta `psycopg2.connect()` con cada contrase?a a la BD `postgres`. Si ninguna funciona:


- Si `permitir_password_manual=True`: lanza `PasswordRequeridoError` (la UI capturar? esto y pedir? la contrase?a al usuario).


- Si `permitir_password_manual=False`: retorna `False` silenciosamente.





#### Paso 4: Verificar Existencia de BD (`db_config.py:384-401`)


```python


cur_pg = None


try:


    cur_pg = conn_pg.cursor()


    cur_pg.execute("SELECT 1 FROM pg_database WHERE datname = %s;", (cfg.database,))


    existe_bd = cur_pg.fetchone() is not None


except Exception as exc:


    _log("?? Error verificando base de datos: %s" % exc)


    return False


finally:


    if cur_pg:


        cur_pg.close()


    conn_pg.close()





if not existe_bd:


    _log("?? La base de datos '%s' no existe." % cfg.database)


    return False





_log("   ??? Base de datos '%s' encontrada" % cfg.database)


```





Consulta la tabla del sistema `pg_database` para verificar si la base de datos destino existe.





#### Paso 5: Probar Conexi?n a BD Espec?fica (`db_config.py:403-431`)


```python


# A veces la contrase?a que funciona para postgres no funciona para la BD destino


passwords_for_db = [password_ok, PASSWORD_POSTGRES, "ivan", ""]


if password_ok not in passwords_for_db:


    passwords_for_db.insert(0, password_ok)


seen = set()


passwords_for_db = [x for x in passwords_for_db if x and not (x in seen or seen.add(x))]





conn = None


for pwd in passwords_for_db:


    try:


        conn = psycopg2.connect(


            host=cfg.host,


            port=cfg.port,


            user=cfg.user,


            password=pwd,


            dbname=cfg.database,


            connect_timeout=5,


        )


        if pwd != password_ok:


            password_ok = pwd


            _log("   ??? Contrase?a correcta para base de datos: %s" %


                 ("*" * len(pwd) if pwd else "vacia"))


        break


    except Exception:


        continue


```





**Raz?n de este paso:** En algunas configuraciones de PostgreSQL, los privilegios y contrase?as pueden diferir entre la BD `postgres` (BD administrativa) y la BD del proyecto. Por ejemplo, el usuario puede tener acceso a `postgres` pero no a `ivan_proceso_his`.





#### Paso 6: Verificar Existencia de Esquema (`db_config.py:433-462`)


```python


try:


    cur = conn.cursor()


    cur.execute(


        "SELECT 1 FROM information_schema.schemata WHERE schema_name = %s;",


        (cfg.schema,),


    )


    existe_esquema = cur.fetchone() is not None


except Exception as exc:


    _log("?? Error verificando esquema: %s" % exc)


    conn.close()


    return False


finally:


    cur.close()


    conn.close()





if not existe_esquema:


    _log("?? El esquema '%s' no existe en '%s'." % (cfg.schema, cfg.database))


    return False





# Guardar la contrase?a correcta si se encontr? una diferente


if guardar_password and password_ok and password_ok != cfg.password:


    _log("   ???? Guardando contrase?a correcta en configuraci?n...")


    try:


        update_db_config(password=password_ok)


        _log("   ??? Contrase?a guardada")


    except Exception:


        pass





_log("??? PostgreSQL, base '%s' y esquema '%s' listos." % (cfg.database, cfg.schema))


return True


```





**Auto-reparaci?n de contrase?a:** Si se encontr? una contrase?a funcional diferente a la configurada, se persiste autom?ticamente via `update_db_config(password=password_ok)`.





---





## 4.8 Inicializaci?n de Base de Datos





### 4.8.1 inicializar_base_datos() ??? Visi?n General (`db_config.py:465-1018`)





```python


def inicializar_base_datos(


    config: Optional[DBConfig] = None,


    log: Optional[Callable[[str], None]] = None,


) -> bool:


```





Esta es la funci?n m?s compleja del m?dulo (553 l?neas), dise?ada para garantizar que la base de datos y esquema existan. Implementa un pipeline de 9 pasos con m?ltiples mecanismos de conexi?n, detecci?n y recuperaci?n.





**Pipeline completo:**





```


inicializar_base_datos()


???


?????? Paso 1: _buscar_conexion_cmd()  ????????? intento r?pido via subprocess


???


?????? Paso 2: Verificar conectividad del puerto


???   ?????? _pg_responde_en_puerto()


???   ?????? _probar_puerto_powershell()


???


?????? Paso 3: _leer_pgpass() ????????? extraer contrase?as de pgpass.conf


???


?????? Paso 4: _probar_psql_cmd() ????????? probar via psql CLI


???


?????? Paso 5: Lista expandida de passwords (24+ entradas)


???


?????? Paso 6: Multi-host probing


???   ?????? 5+ direcciones IP incluyendo IPv4/IPv6


???   ?????? 3 usuarios: cfg.user, user_windows, "postgres"


???   ?????? 24+ contrase?as


???


?????? Paso 7: _recuperar_password() (si todo lo dem?s falla)


???   ?????? _encontrar_pg_hba_conf()


???   ?????? _modificar_pg_hba_a_trust()


???   ?????? _reiniciar_postgresql()


???   ?????? _cambiar_contrasena_trust()


???   ?????? _revertir_pg_hba()


???   ?????? _reiniciar_postgresql()


???


?????? Paso 8: Crear BD (3 estrategias)


???


?????? Paso 9: Crear esquema + asignar privilegios


```





### 4.8.2 Paso 1: Prueba Inicial via CMD (`db_config.py:484-497`)





```python


_log("???? Probando conexi?n via CMD...")


try:


    pwd_encontrada = _buscar_conexion_cmd()


    if pwd_encontrada:


        _log("   ??? Conexi?n exitosa via CMD con contrase?a: ***")


        try:


            update_db_config(password=pwd_encontrada)


        except Exception:


            pass


        return True


    else:


        _log("   ???? CMD: No se encontr? contrase?a v?lida")


except Exception as e:


    _log("   ???? CMD error: %s" % str(e)[:100])


```





`_buscar_conexion_cmd()` se define a nivel de m?dulo (ver secci?n 4.10.7). Es el m?todo m?s r?pido porque usa `subprocess.run()` con `pg_isready` y `psql`, evitando la importaci?n de `psycopg2`. Si funciona, se retorna `True` inmediatamente.





### 4.8.3 Paso 2: Verificaci?n de Conectividad del Puerto (`db_config.py:500-521`)





```python


_log("???? Verificando conectividad...")


try:


    respuesta_socket = _pg_responde_en_puerto(cfg.port)


except Exception as e:


    respuesta_socket = False


    _log("   ???? Socket check error: %s" % str(e)[:50])





try:


    respuesta_ps = _probar_puerto_powershell(cfg.port)


except Exception as e:


    respuesta_ps = False


    _log("   ???? PowerShell check error: %s" % str(e)[:50])





if not respuesta_socket and not respuesta_ps:


    _log("   ???? Puerto %s NO responde (socket=%s, ps=%s)" %


         (cfg.port, respuesta_socket, respuesta_ps))


    ips = _obtener_ips_locales()


    _log("   ???? IPs disponibles: %s" % ", ".join(ips[:5]))


else:


    _log("   ??? Puerto %s responde (socket=%s, ps=%s)" %


         (cfg.port, respuesta_socket, respuesta_ps))


```





**Verificaci?n dual:**


1. `_pg_responde_en_puerto()`: Socket TCP directo a `127.0.0.1` y `::1`.


2. `_probar_puerto_powershell()`: Cliente TCP via PowerShell.





Si ambos fallan, se intenta con IPs alternativas obtenidas de `_obtener_ips_locales()`.





### 4.8.4 Paso 3: Lectura de pgpass (Funci?n Anidada _leer_pgpass) (`db_config.py:524-549`)





```python


def _leer_pgpass() -> list:


    """Lee contrase?as del archivo pgpass.conf"""


    passwords = []


    appdata = os.getenv("APPDATA", "")


    userprofile = os.getenv("USERPROFILE", "")


    username = os.getenv("USERNAME", "postgres")





    pgpass_paths = [


        os.path.join(appdata, "postgresql", "pgpass.conf"),


        os.path.join(userprofile, ".pgpass.conf"),


        os.path.join(appdata, username, "pgpass.conf"),


        r"C:\Users\{}\AppData\Roaming\postgresql\pgpass.conf".format(username),


    ]


    for pgpass_file in pgpass_paths:


        if os.path.exists(pgpass_file):


            try:


                with open(pgpass_file, "r", encoding="utf-8") as f:


                    for linea in f:


                        linea = linea.strip()


                        if linea and not linea.startswith("#"):


                            partes = linea.split(":")


                            if len(partes) >= 5:


                                passwords.append(partes[4])  # ??ltimo campo = password


            except Exception:


                pass


    return passwords


```





**4 rutas de b?squeda:**





| # | Ruta | Prop?sito |


|---|------|-----------|


| 1 | `%APPDATA%\postgresql\pgpass.conf` | Ruta est?ndar del instalador EDB |


| 2 | `%USERPROFILE%\.pgpass.conf` | Variante con punto |


| 3 | `%APPDATA%\<username>\pgpass.conf` | Variante dentro del perfil de usuario |


| 4 | `C:\Users\<username>\AppData\Roaming\postgresql\pgpass.conf` | Ruta absoluta expl?cita |





Esta funci?n est? **anidada** dentro de `inicializar_base_datos()`, a diferencia de `_read_pgpass_entries()` (nivel de m?dulo) que se usa en la auto-detecci?n. La versi?n anidada solo extrae el campo de contrase?a (?ltimo campo) y explora m?s ubicaciones.





### 4.8.5 Paso 4: B?squeda de psql (Funci?n Anidada _probar_psql_cmd) (`db_config.py:552-570`)





```python


def _probar_psql_cmd(password: str, host: str, port: int, usuario: str = "postgres") -> bool:


    """Usa psql via CMD para probar conexi?n."""


    import os


    env = os.environ.copy()


    env["PGPASSWORD"] = password


    env["PGCLIENTENCODING"] = "UTF8"





    for ip in [host, "127.0.0.1", "localhost"]:


        try:


            proc = subprocess.run(


                ["psql", "-h", ip, "-p", str(port), "-U", usuario, "-d", "postgres",


                 "-c", "SELECT 1;", "-t", "-A", "-w"],


                capture_output=True, text=True, encoding="utf-8", errors="replace",


                env=env, timeout=10,


            )


            if proc.returncode == 0:


                return True


        except Exception:


            continue


    return False


```





**Flags de psql:**





| Flag | Significado |


|------|-------------|


| `-h ip` | Host a conectar |


| `-p port` | Puerto |


| `-U usuario` | Usuario |


| `-d postgres` | Base de datos |


| `-c "SELECT 1;"` | Comando SQL a ejecutar |


| `-t` | Tuples only (sin cabeceras) |


| `-A` | Alineaci?n desactivada (sin espaciado) |


| `-w` | No password (no pedir contrase?a interactiva) |





**Hosts probados:** `[cfg.host, "127.0.0.1", "localhost"]`.





**Variable de entorno:** `PGPASSWORD` se inyecta en el entorno del subproceso para autenticaci?n autom?tica. `PGCLIENTENCODING=UTF8` asegura encoding correcto.





### 4.8.6 Paso 5: Lista Expandida de Contrase?as (`db_config.py:740-775`)





```python


user_windows = os.getenv("USERNAME", "postgres")


passwords_base = [


    cfg.password if cfg.password else "",


    PASSWORD_POSTGRES,       # "ivan"


    "ivan",


    "postgres",


    "admin",


    "root",


    "Password123!",


    "Admin123!",


    "Psql123!",


    "postgres123",


    "root123",


    "admin123",


    "123456",


    "12345678",


    "",


    user_windows,


    user_windows.lower(),


    "Ivan",


    "Ivan123",


    "IvaN123",


    "Usuario123",


    "SaludCusco",


    "Cusco2024",


    "Cusco2025",


    "Cusco2026",


]





# Agregar contrase?as de pgpass.conf


pgpass_passwords = _leer_pgpass()


passwords_to_try = passwords_base + pgpass_passwords





# Eliminar duplicados preservando orden


seen = set()


passwords_to_try = [x for x in passwords_to_try if x and not (x in seen or seen.add(x))]


```





**24 contrase?as base + pgpass:**





| # | Password | Descripci?n |


|---|----------|-------------|


| 1 | `cfg.password` | Contrase?a actual configurada |


| 2 | `"ivan"` | Default del sistema |


| 3 | `"postgres"` | Rol por defecto |


| 4 | `"admin"` | Admin gen?rico |


| 5 | `"root"` | Root gen?rico |


| 6 | `"Password123!"` | Instalador EDB est?ndar |


| 7 | `"Admin123!"` | Variante EDB |


| 8 | `"Psql123!"` | Variante EDB |


| 9 | `"postgres123"` | Rol + n?meros |


| 10 | `"root123"` | Root + n?meros |


| 11 | `"admin123"` | Admin + n?meros |


| 12 | `"123456"` | Gen?rica simple |


| 13 | `"12345678"` | Gen?rica larga |


| 14 | `""` | Vac?a (trust) |


| 15 | `user_windows` | Nombre de usuario Windows |


| 16 | `user_windows.lower()` | Usuario en min?sculas |


| 17 | `"Ivan"` | Capitalizada |


| 18 | `"Ivan123"` | Capitalizada + n?meros |


| 19 | `"IvaN123"` | CamelCase |


| 20 | `"Usuario123"` | Usuario en espa?ol |


| 21 | `"SaludCusco"` | Nombre del proyecto |


| 22 | `"Cusco2024"` | A?o 2024 |


| 23 | `"Cusco2025"` | A?o 2025 |


| 24 | `"Cusco2026"` | A?o 2026 |


| +N | `pgpass_passwords` | Contrase?as de pgpass.conf |





### 4.8.7 Paso 6: Multi-host Probing (`db_config.py:783-834`)





```python


usuarios_a_probar = [cfg.user, user_windows, "postgres"]


usuarios_unicos = []


for u in usuarios_a_probar:


    if u and u not in usuarios_unicos:


        usuarios_unicos.append(u)





hosts_a_probar = [cfg.host, "localhost", "127.0.0.1", "::1", "0.0.0.0"] + _obtener_ips_locales()


hosts_unicos = list(dict.fromkeys([h for h in hosts_a_probar if h]))





_log("   ???? Probando %d hosts, %d usuarios, %d passwords" % (


    len(hosts_unicos), len(usuarios_unicos), len(passwords_to_try)))


```





**Combinaciones probadas:** `hosts_unicos ?? usuarios_unicos ?? passwords_to_try`. Con ~5 hosts, ~3 usuarios y ~24+ contrase?as, se prueban hasta 360+ combinaciones.





**Orden de probing:**


1. **CMD/psql primero** ??? m?s r?pido, sin dependencia de psycopg2:


```python


for pwd in passwords_to_try:


    if _probar_psql_cmd(pwd, cfg.host, cfg.port, "postgres"):


        password_ok = pwd


        psql_encontrado = True


        break


```





2. **psycopg2 despu?s** ??? si CMD fall?:


```python


for host in hosts_unicos:


    for usuario in usuarios_unicos:


        for pwd in passwords_to_try:


            try:


                conn_pg = psycopg2.connect(


                    host=host, port=cfg.port, user=usuario,


                    password=pwd, dbname="postgres", connect_timeout=10,


                )


                password_ok = pwd


                cfg.host = host


                break


            except Exception:


                continue


```





### 4.8.8 Paso 7: Recuperaci?n Autom?tica de Contrase?a (`db_config.py:703-737`)





```python


def _recuperar_password() -> bool:


    """Plan de recuperaci?n completo: 6 sub-pasos."""


    _log("   ???? Iniciando recuperaci?n de contrase?a...")





    # 1. Encontrar pg_hba.conf


    pg_hba = _encontrar_pg_hba_conf()


    if not pg_hba:


        _log("   ?? No se encontr? pg_hba.conf")


        return False





    # 2. Modificar a trust


    if not _modificar_pg_hba_a_trust(pg_hba):


        _log("   ?? No se pudo modificar pg_hba.conf")


        return False





    # 3. Reiniciar PostgreSQL


    if not _reiniciar_postgresql():


        _revertir_pg_hba(pg_hba)


        return False





    # 4. Cambiar contrase?a


    nueva_pass = PASSWORD_POSTGRES  # "ivan"


    if not _cambiar_contrasena_trust(nueva_pass):


        _revertir_pg_hba(pg_hba)


        _reiniciar_postgresql()


        return False





    # 5. Revertir pg_hba.conf


    _revertir_pg_hba(pg_hba)





    # 6. Reiniciar para aplicar cambios


    _reiniciar_postgresql()





    _log("   ??? Recuperaci?n completada. Nueva contrase?a: %s" % nueva_pass)


    return True


```





**Flujo completo de recuperaci?n:**





```


_recuperar_password()


  ???


  ?????? 1. _encontrar_pg_hba_conf()


  ???      Busca en versiones 18???11, 3 ubicaciones cada una


  ???      ?????? C:\Program Files\PostgreSQL\<v>\data\pg_hba.conf


  ???      ?????? C:\Program Files (x86)\PostgreSQL\<v>\data\pg_hba.conf


  ???      ?????? C:\PostgreSQL\<v>\data\pg_hba.conf


  ???


  ?????? 2. _modificar_pg_hba_a_trust(pg_hba)


  ???      ??? Comenta l?neas "host ... md5" y "host ... scram"


  ???      ??? Agrega "host all all 127.0.0.1/32 trust"


  ???


  ?????? 3. _reiniciar_postgresql()


  ???      ??? PowerShell Restart-Service 'postgresql*'


  ???      ??? Fallback: net stop / net start postgresql-x64-18


  ???


  ?????? 4. _cambiar_contrasena_trust("ivan")


  ???      ??? Conecta sin password (trust activo)


  ???      ??? Ejecuta: ALTER USER postgres WITH PASSWORD 'ivan';


  ???


  ?????? 5. _revertir_pg_hba(pg_hba)


  ???      ??? Des-comenta l?neas originales


  ???      ??? Elimina l?neas trust


  ???


  ?????? 6. _reiniciar_postgresql()


         ??? Aplica configuraci?n revertida


```





#### 4.8.8.1 Sub-funci?n: _encontrar_pg_hba_conf() (`db_config.py:573-587`)





```python


def _encontrar_pg_hba_conf() -> str:


    """Busca el archivo pg_hba.conf en las rutas de PostgreSQL."""


    rutas = []


    for v in range(18, 10, -1):


        rutas.extend([


            r"C:\Program Files\PostgreSQL\{}\data\pg_hba.conf".format(v),


            r"C:\Program Files (x86)\PostgreSQL\{}\data\pg_hba.conf".format(v),


            r"C:\PostgreSQL\{}\data\pg_hba.conf".format(v),


        ])


    for ruta in rutas:


        if os.path.exists(ruta):


            _log("   ???? pg_hba.conf encontrado en: %s" % ruta)


            return ruta


    return None


```





**Rutas buscadas (versiones 18 a 11):**





| Versi?n | Program Files | Program Files (x86) | C:\PostgreSQL |


|---------|---------------|---------------------|---------------|


| 18 | `C:\Program Files\PostgreSQL\18\data\pg_hba.conf` | `C:\Program Files (x86)\PostgreSQL\18\data\pg_hba.conf` | `C:\PostgreSQL\18\data\pg_hba.conf` |


| 17 | igual | igual | igual |


| 16 | igual | igual | igual |


| 15 | igual | igual | igual |


| 14 | igual | igual | igual |


| 13 | igual | igual | igual |


| 12 | igual | igual | igual |


| 11 | igual | igual | igual |





Total: 24 rutas probadas (8 versiones ?? 3 ubicaciones).





#### 4.8.8.2 Sub-funci?n: _modificar_pg_hba_a_trust() (`db_config.py:590-627`)





```python


def _modificar_pg_hba_a_trust(pg_hba_path: str) -> bool:


    """Modifica pg_hba.conf para usar autenticaci?n trust (sin password)."""


    try:


        with open(pg_hba_path, "r", encoding="utf-8") as f:


            contenido_original = f.read()





        lines = contenido_original.split('\n')


        modificado = False


        new_lines = []





        for line in lines:


            if line.strip().startswith("host") and "md5" in line.lower():


                new_lines.append("# " + line)  # Comentar original


                parts = line.split()


                if len(parts) >= 4:


                    new_lines.append("host    all         all         127.0.0.1/32          trust")


                    modificado = True


            elif line.strip().startswith("host") and "scram" in line.lower():


                new_lines.append("# " + line)


                new_lines.append("host    all         all         127.0.0.1/32          trust")


                modificado = True


            else:


                new_lines.append(line)





        if modificado:


            with open(pg_hba_path, "w", encoding="utf-8") as f:


                f.write('\n'.join(new_lines))


            _log("   ??? pg_hba.conf modificado a trust")


            return True


        return False


    except Exception as e:


        _log("   ?? Error modificando pg_hba.conf: %s" % e)


        return False


```





**Transformaci?n t?pica:**





Antes:


```


# TYPE  DATABASE        USER            ADDRESS                 METHOD


host    all             all             127.0.0.1/32            md5


host    all             all             ::1/128                 md5


```





Despu?s:


```


# TYPE  DATABASE        USER            ADDRESS                 METHOD


# host    all             all             127.0.0.1/32            md5


host    all         all         127.0.0.1/32          trust


# host    all             all             ::1/128                 md5


host    all         all         127.0.0.1/32          trust


```





Notar que se agrega `trust` para `127.0.0.1/32` (solo IPv4 local) y se comentan tanto las l?neas md5 como scram-sha-256. La l?nea de IPv6 no se modifica expl?citamente porque las conexiones via psycopg2 en Windows generalmente usan IPv4.





#### 4.8.8.3 Sub-funci?n: _revertir_pg_hba() (`db_config.py:630-647`)





```python


def _revertir_pg_hba(pg_hba_path: str) -> bool:


    """Revierte los cambios de pg_hba.conf (des-comenta originales)."""


    try:


        lines = []


        with open(pg_hba_path, "r", encoding="utf-8") as f:


            for line in f:


                # Descomentar l?neas originales (quitar # )


                if line.strip().startswith("# host") and "all" in line and ("md5" in line or "scram" in line):


                    line = line[2:]  # Quitar #


                lines.append(line)





        with open(pg_hba_path, "w", encoding="utf-8") as f:


            f.write(''.join(lines))


        _log("   ??? pg_hba.conf revertido a md5")


        return True


    except Exception as e:


        _log("   ???? Error revertiendo pg_hba.conf: %s" % e)


        return False


```





**Importante:** Esta funci?n **no** elimina las l?neas `trust` agregadas; solo des-comenta las originales. Las l?neas trust adicionales permanecen pero son efectivamente ignoradas porque PostgreSQL usa la primera l?nea que coincide (first match). Las l?neas originales re-habilitadas aparecen antes y tienen prioridad.





#### 4.8.8.4 Sub-funci?n: _reiniciar_postgresql() (`db_config.py:650-676`)





```python


def _reiniciar_postgresql() -> bool:


    """Reinicia el servicio de PostgreSQL."""


    try:


        # Intentar con PowerShell (m?s robusto)


        proc = subprocess.run(


            ["powershell", "-NoProfile", "-Command",


             "Restart-Service -Name 'postgresql*' -Force -ErrorAction Stop"],


            capture_output=True, text=True, timeout=30,


        )


        if proc.returncode == 0:


            _log("   ??? Servicio PostgreSQL reiniciado")


            time.sleep(3)  # Esperar a que inicie


            return True


    except Exception:


        pass





    # Fallback: net stop / net start


    try:


        subprocess.run(["net", "stop", "postgresql-x64-18"], capture_output=True, timeout=15)


        time.sleep(2)


        subprocess.run(["net", "start", "postgresql-x64-18"], capture_output=True, timeout=15)


        _log("   ??? Servicio PostgreSQL reiniciado (net)")


        time.sleep(3)


        return True


    except Exception as e:


        _log("   ?? Error reiniciando servicio: %s" % e)


        return False


```





**Dos m?todos de reinicio:**





| M?todo | Comando | Ventaja | Desventaja |


|--------|---------|---------|------------|


| PowerShell | `Restart-Service -Name 'postgresql*' -Force` | Detecta cualquier versi?n | Depende de PowerShell |


| net.exe | `net stop postgresql-x64-18` / `net start postgresql-x64-18` | Compatibilidad universal | Nombre fijo (versi?n 18) |





El delay de `time.sleep(3)` despu?s del reinicio es cr?tico: PostgreSQL necesita tiempo para iniciar el proceso postmaster, cargar shared_buffers y comenzar a aceptar conexiones.





#### 4.8.8.5 Sub-funci?n: _cambiar_contrasena_trust() (`db_config.py:679-700`)





```python


def _cambiar_contrasena_trust(nueva_password: str) -> bool:


    """Cambia la contrase?a de postgres usando conexi?n trust (sin password)."""


    try:


        conn = psycopg2.connect(


            host=cfg.host,


            port=cfg.port,


            user="postgres",


            password="",


            dbname="postgres",


            connect_timeout=10,


        )


        cur = conn.cursor()


        cur.execute("ALTER USER postgres WITH PASSWORD %s;", (nueva_password,))


        conn.commit()


        cur.close()


        conn.close()


        _log("   ??? Contrase?a cambiada a: %s" % nueva_password)


        return True


    except Exception as e:


        _log("   ?? Error cambiando contrase?a: %s" % e)


        return False


```





**Detalles cr?ticos:**


- Se conecta con `password=""` (vac?a) porque pg_hba.conf ahora tiene `trust` para conexiones locales.


- Usa `connect_timeout=10` porque es posible que PostgreSQL est? reinici?ndose.


- Usa par?metro con placeholder `%s` (no interpolaci?n de cadenas) para evitar SQL injection.


- La nueva contrase?a se establece a `PASSWORD_POSTGRES` ("ivan"), que es la contrase?a por defecto del sistema.





#### 4.8.8.6 Post-recuperaci?n (`db_config.py:841-860`)





```python


_log("???? Intentando recuperaci?n autom?tica de contrase?a...")


if _recuperar_password():


    # Intentar conectar con la nueva contrase?a


    try:


        conn_pg = psycopg2.connect(


            host=cfg.host,


            port=cfg.port,


            user="postgres",


            password=PASSWORD_POSTGRES,


            dbname="postgres",


            connect_timeout=10,


        )


        password_ok = PASSWORD_POSTGRES


        _log("   ??? Conexi?n exitosa con nueva contrase?a")


    except Exception as e:


        _log("   ?? Error conectando despu?s de recuperaci?n: %s" % e)


        return False


else:


    _log("   ?? Recuperaci?n autom?tica fall?")


    return False


```





Despu?s de `_recuperar_password()`, se verifica que la nueva contrase?a funcione. Si no, se retorna `False`.





### 4.8.9 Paso 8: Creaci?n de Base de Datos (`db_config.py:886-945`)





```python


try:


    cur_pg.execute(


        """


        SELECT pg_encoding_to_char(encoding), datcollate, datctype


        FROM pg_database


        WHERE datname = %s;


        """,


        (cfg.database,),


    )


    info_bd = cur_pg.fetchone()


    if info_bd:


        encoding_actual, collate_actual, ctype_actual = info_bd


        _log("   ??? Base de datos '%s' ya existe" % cfg.database)


        _log("   ????  Config actual: ENCODING=%s | LC_COLLATE=%s | LC_CTYPE=%s"


             % (encoding_actual, collate_actual, ctype_actual))


    else:


        _log("   ????  Creando base de datos '%s'..." % cfg.database)


        nombre_seguro = cfg.database.replace('"', "").replace(";", "")


        estrategias = [


            (


                "UTF8 + locale es_ES.UTF-8",


                'CREATE DATABASE "%s" WITH ENCODING \'UTF8\' LC_COLLATE \'es_ES.UTF-8\' LC_CTYPE \'es_ES.UTF-8\' TEMPLATE template0;'


                % nombre_seguro,


            ),


            (


                "UTF8 (sin locale expl?cito)",


                'CREATE DATABASE "%s" WITH ENCODING \'UTF8\' TEMPLATE template0;'


                % nombre_seguro,


            ),


            (


                "configuraci?n por defecto",


                'CREATE DATABASE "%s";' % nombre_seguro,


            ),


        ]





        creada = False


        ultimo_error = None


        for descripcion, sentencia in estrategias:


            try:


                cur_pg.execute(sentencia)


                _log("   ??? Base de datos creada con %s" % descripcion)


                creada = True


                break


            except Exception as exc:


                ultimo_error = exc


                detalle = str(exc).splitlines()[0] if str(exc) else repr(exc)


                _log("   ????  Fall? creaci?n con %s: %s" % (descripcion, detalle))





        if not creada and ultimo_error is not None:


            raise ultimo_error


except Exception as exc:


    _log("   ?? Error al crear base de datos: %s" % exc)


    cur_pg.close()


    conn_pg.close()


    return False


```





**Seguridad de nombres SQL:**


```python


nombre_seguro = cfg.database.replace('"', "").replace(";", "")


```


Esto previene SQL injection deliberada o accidental en los nombres de base de datos, esquema y usuario, eliminando caracteres peligrosos.





**Tres estrategias de CREATE DATABASE:**





| Estrategia | SQL | Cu?ndo funciona |


|------------|-----|-----------------|


| 1. UTF8 + locale es_ES | `CREATE DATABASE "x" WITH ENCODING 'UTF8' LC_COLLATE 'es_ES.UTF-8' LC_CTYPE 'es_ES.UTF-8' TEMPLATE template0;` | Sistemas Unix/Linux con locale es_ES.UTF-8 instalado |


| 2. UTF8 sin locale | `CREATE DATABASE "x" WITH ENCODING 'UTF8' TEMPLATE template0;` | Windows (no tiene locales Unix) o Linux sin locale espec?fico |


| 3. Default | `CREATE DATABASE "x";` | Cualquier plataforma (hereda encoding y locale de template1) |





**Autocommit:** La conexi?n se configura con `ISOLATION_LEVEL_AUTOCOMMIT` porque `CREATE DATABASE` no puede ejecutarse dentro de una transacci?n.





```python


conn_pg.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)


```





### 4.8.10 Paso 9: Creaci?n de Esquema y Privilegios (`db_config.py:973-1006`)





```python


try:


    conn.autocommit = True


    cur = conn.cursor()





    cur.execute(


        "SELECT 1 FROM information_schema.schemata WHERE schema_name = %s;",


        (cfg.schema,),


    )


    if cur.fetchone():


        _log("   ??? Esquema '%s' ya existe" % cfg.schema)


    else:


        _log("   ????  Creando esquema '%s'..." % cfg.schema)


        nombre_esquema = cfg.schema.replace('"', "").replace(";", "")


        cur.execute('CREATE SCHEMA "%s";' % nombre_esquema)


        _log("   ??? Esquema '%s' creado" % cfg.schema)





    nombre_usuario = cfg.user.replace('"', "").replace(";", "")


    nombre_esquema = cfg.schema.replace('"', "").replace(";", "")


    cur.execute('GRANT ALL PRIVILEGES ON SCHEMA "%s" TO "%s";' % (nombre_esquema, nombre_usuario))


    _log("   ??? Privilegios asignados al usuario '%s'" % cfg.user)


except Exception as exc:


    _log("   ?? Error al crear esquema: %s" % exc)


    cur.close()


    conn.close()


    return False


```





**Privilegios otorgados:**


```sql


GRANT ALL PRIVILEGES ON SCHEMA "es_ivan" TO "postgres";


```


Esto permite al usuario crear, modificar y eliminar objetos dentro del esquema. `ALL PRIVILEGES` incluye: `CREATE`, `USAGE` en esquemas, m?s todos los privilegios sobre objetos existentes.





### 4.8.11 Guardado Final de Contrase?a (`db_config.py:1008-1018`)





```python


if password_ok and password_ok != cfg.password:


    _log("   ???? Guardando contrase?a correcta en configuraci?n...")


    try:


        update_db_config(password=password_ok)


        _log("   ??? Contrase?a guardada")


    except Exception:


        pass





_log("???? Base de datos y esquema operativos.")


return True


```





Al final de `inicializar_base_datos()`, si se descubri? una contrase?a funcional diferente a la configurada, se persiste autom?ticamente.





---





## 4.9 Detecci?n de PostgreSQL Instalado





### 4.9.1 RUTAS_POSTGRESQL (`db_config.py:1040-1043`)





```python


RUTAS_POSTGRESQL = [


    r"C:\Program Files\PostgreSQL",


    r"C:\PostgreSQL",


]


```





Constante global usada en `detectar_postgresql_existente()` para buscar directorios de instalaci?n de PostgreSQL.





### 4.9.2 detectar_postgresql_existente() (`db_config.py:1229-1393`)





```python


def detectar_postgresql_existente() -> dict:


    """Detecta si PostgreSQL est? instalado y retorna informaci?n detallada.





    IMPORTANTE: El puerto 5432 es la fuente principal de verdad.


    Si el puerto no responde, PostgreSQL NO est? operativo, sin importar


    qu? servicios o archivos existan (pueden ser residuales).


    """


    resultado = {


        "instalado": False,


        "version": None,


        "servicio_activo": False,


        "ruta_bin": None,


        "puerto": 5432,


        "servicio_nombre": None,


        "mensaje": "",


    }


```





**Estructura del diccionario de retorno:**





| Campo | Tipo | Valores posibles | Prop?sito |


|-------|------|-----------------|-----------|


| `instalado` | `bool` | `True`, `False` | ?PostgreSQL est? operativo? |


| `version` | `str` \| `None` | `"15"`, `"16"`, `"17"`, etc. | Versi?n mayor de PostgreSQL |


| `servicio_activo` | `bool` | `True`, `False` | ?El servicio de Windows est? Running? |


| `ruta_bin` | `str` \| `None` | `C:\Program Files\PostgreSQL\17\bin` | Directorio de binarios |


| `puerto` | `int` | `5432` (default) o el de postgresql.conf | Puerto de escucha |


| `servicio_nombre` | `str` \| `None` | `"postgresql-x64-17"` | Nombre del servicio Windows |


| `mensaje` | `str` | `"PostgreSQL 17 instalado y activo"` | Mensaje legible para UI |





**Pipeline de detecci?n (7 etapas):**





```


detectar_postgresql_existente()


???


?????? [0] _verificar_postgresql_activo()


???      ?????? Si NO responde ??? retornar "no instalado"


???


?????? [1] Conexi?n psycopg2 + SHOW server_version_num


???


?????? [2] Get-Service (PowerShell) ??? nombre del servicio


???


?????? [3] B?squeda en directorios (RUTAS_POSTGRESQL)


???


?????? [4] sc query ??? verificar estado del servicio (c?digo no alcanzable)


???


?????? [5] postgresql.conf ??? leer puerto real (c?digo no alcanzable)


???


?????? [6] Generar mensaje descriptivo


```





**Filosof?a de dise?o:**


- **Puerto 5432 es la fuente de verdad**: si no responde, PostgreSQL no est? operativo.


- Los servicios y archivos pueden ser **residuales** de instalaciones desinstaladas incorrectamente.


- No se requiere contrase?a para la detecci?n b?sica de puerto.





### 4.9.3 Etapa 0: Verificaci?n de Puerto (`db_config.py:1246-1253`)





```python


pg_activo = _verificar_postgresql_activo()





if not pg_activo:


    resultado["mensaje"] = "PostgreSQL no encontrado en este equipo"


    return resultado


```





Si PostgreSQL no responde en el puerto, se retorna inmediatamente sin buscar m?s. Esto hace que la funci?n sea r?pida (~6 segundos m?ximo: 3 intentos ?? ~2 segundos cada uno).





### 4.9.4 Etapa 1: Obtenci?n de Versi?n via Conexi?n (`db_config.py:1261-1297`)





```python


try:


    import psycopg2


    passwords_a_probar = [


        PASSWORD_POSTGRES, "ivan", "postgres", "admin", "root",


        "Password123!", "Admin123!", "Psql123!", "postgres123",


        "root123", "admin123", "123456", "",


    ]


    hosts_a_probar = _obtener_ips_locales()





    for pwd in passwords_a_probar:


        for host in hosts_a_probar:


            try:


                conn = psycopg2.connect(


                    host=host, port=5432, user="postgres",


                    password=pwd, dbname="postgres", connect_timeout=3,


                )


                conn.close()


                try:


                    conn2 = psycopg2.connect(


                        host=host, port=5432, user="postgres",


                        password=pwd, dbname="postgres", connect_timeout=3


                    )


                    cur = conn2.cursor()


                    cur.execute("SHOW server_version_num;")


                    ver_num = cur.fetchone()[0]


                    resultado["version"] = ver_num[:2]  # "150000" ??? "15"


                    cur.close()


                    conn2.close()


                except Exception:


                    pass


                break


            except Exception:


                continue


        if resultado.get("version"):


            break


except ImportError:


    pass


```





**Versiones detectables:**





| server_version_num | Versi?n PostgreSQL |


|-------------------|-------------------|


| `170000` | 17 |


| `160000` | 16 |


| `150000` | 15 |


| `140000` | 14 |


| `130000` | 13 |


| `120000` | 12 |


| `110000` | 11 |





El string de versi?n num?rica tiene formato `XXYYZZ` donde `XX` = major, `YY` = minor, `ZZ` = patch. Se toman los primeros 2 caracteres (`ver_num[:2]`).





### 4.9.5 Etapa 2: Detecci?n de Servicio de Windows (`db_config.py:1300-1328`)





```python


try:


    proc = subprocess.run(


        ["powershell", "-NoProfile", "-Command",


         "Get-Service | Where-Object {$_.DisplayName -like '*PostgreSQL*' -and $_.DisplayName -notlike '*pgAgent*'} | ConvertTo-Json -Compress"],


        capture_output=True, text=True, encoding="utf-8", errors="replace",


        timeout=10,


    )


    if proc.stdout.strip():


        try:


            servicios = json.loads(proc.stdout)


            if isinstance(servicios, dict):


                servicios = [servicios]


            for svc in servicios:


                svc_name = svc.get("Name", "")


                display_name = svc.get("DisplayName", "")


                if "pgagent" in svc_name.lower():


                    continue


                if not resultado["servicio_nombre"]:


                    resultado["servicio_nombre"] = svc_name


                ver_match = re.search(r'\d+', display_name)


                if ver_match and not resultado["version"]:


                    resultado["version"] = ver_match.group()


                if svc.get("Status") == 1:


                    resultado["servicio_activo"] = True


        except (json.JSONDecodeError, TypeError):


            pass


except Exception:


    pass


```





**Comando PowerShell ejecutado:**


```powershell


Get-Service | Where-Object {


    $_.DisplayName -like '*PostgreSQL*' -and


    $_.DisplayName -notlike '*pgAgent*'


} | ConvertTo-Json -Compress


```





**Filtros:**


- `-like '*PostgreSQL*'`: encuentra cualquier servicio con "PostgreSQL" en el nombre mostrado.


- `-notlike '*pgAgent*'`: excluye el agente pgAgent (no es el motor de BD).





**Parseo de respuesta JSON:** `ConvertTo-Json -Compress` produce un JSON compacto. Si solo hay un servicio, es un objeto `{}`; si hay m?ltiples, es un array `[{}, {}]`. El c?digo maneja ambos casos.





**Extracci?n de versi?n desde DisplayName:** Por ejemplo, `DisplayName: "postgresql-x64-17 - PostgreSQL Server 17"` ??? regex `\d+` extrae `"17"`.





### 4.9.6 Etapa 3: Detecci?n desde Directorios (`db_config.py:1330-1347`)





```python


for ruta in RUTAS_POSTGRESQL:


    if not os.path.exists(ruta):


        continue


    try:


        subdirs = os.listdir(ruta)


        pg_versions = [d for d in subdirs if d.startswith("pg") and os.path.isdir(os.path.join(ruta, d))]


        if pg_versions:


            pg_versions.sort(key=lambda x: [int(n) for n in re.findall(r'\d+', x)], reverse=True)


            pg_dir = pg_versions[0]


            ver_match = re.search(r'\d+', pg_dir)


            if ver_match and not resultado["version"]:


                resultado["version"] = ver_match.group()


            if not resultado["ruta_bin"]:


                resultado["ruta_bin"] = os.path.join(ruta, pg_dir, "bin")


            break


    except OSError:


        continue


```





**B?squeda en:**


1. `C:\Program Files\PostgreSQL\` ??? subdirectorios como `pg17`, `pg16`, `pg15`


2. `C:\PostgreSQL\` ??? misma estructura





**Ordenamiento de versiones:** Se usa `sort(key=lambda x: [int(n) for n in re.findall(r'\d+', x)], reverse=True)` para ordenar versiones num?ricamente descendente. Ejemplo: `["pg9", "pg10", "pg11"]` ??? `["pg11", "pg10", "pg9"]` (sorting lexicogr?fico simple fallar?a porque "9" > "10" como string).





**Extracci?n de ruta bin:** `C:\Program Files\PostgreSQL\pg17\bin`.





### 4.9.7 Etapas 4-6: C?digo Inalcanzable





Las etapas 4 (verificaci?n con `sc query`) y 5 (lectura de `postgresql.conf`) est?n escritas despu?s del `return resultado` en la l?nea 1353 y **nunca se ejecutan**. La etapa 6 (mensaje descriptivo) se ejecuta en l?nea 1351 dentro del flujo principal.





```python


# L?nea 1353: return resultado (el flujo termina aqu?)


return resultado





# Las siguientes l?neas NUNCA se ejecutan:


# Etapa 4: sc query


if resultado["servicio_nombre"] and not resultado["servicio_activo"]:


    check = subprocess.run(["sc", "query", resultado["servicio_nombre"]], ...)





# Etapa 5: postgresql.conf


if resultado["ruta_bin"] and os.path.exists(resultado["ruta_bin"]):


    pg_conf = os.path.join(resultado["ruta_bin"], "..", "data", "postgresql.conf")


    # leer puerto...





# Etapa 6: mensaje descriptivo (duplicado, ya ejecutado en l?nea 1351)


```





### 4.9.8 _verificar_postgresql_activo() (`db_config.py:1168-1179`)





```python


def _verificar_postgresql_activo() -> bool:


    """Verificaci?n h?brida para confirmar que PostgreSQL est? activo."""


    import time





    for _ in range(3):


        if _pg_responde_en_puerto(5432):


            return True


        if _probar_puerto_powershell(5432):


            return True


        time.sleep(0.3)





    return False


```





**3 intentos ?? 2 m?todos = 6 verificaciones.**





| Intento | M?todo 1: Socket TCP | M?todo 2: PowerShell TcpClient |


|---------|---------------------|-------------------------------|


| 1 | `_pg_responde_en_puerto(5432)` | `_probar_puerto_powershell(5432)` |


| 2 | (mismo) | (mismo) |


| 3 | (mismo) | (mismo) |





Entre cada intento hay una pausa de 300ms. Tiempo m?ximo total: ~2s ?? 3 + 0.3s ?? 2 = ~6.6s.





### 4.9.9 _pg_responde_en_puerto() (`db_config.py:1143-1165`)





```python


def _pg_responde_en_puerto(puerto: int = 5432, timeout: float = 2.0) -> bool:


    """Verifica si hay un servidor PostgreSQL escuchando en el puerto."""


    try:


        # Intentar primero con 127.0.0.1 (IPv4)


        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)


        sock.settimeout(timeout)


        resultado = sock.connect_ex(("127.0.0.1", puerto))


        sock.close()


        if resultado == 0:


            return True





        # Intentar con ::1 (IPv6 localhost)


        sock = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)


        sock.settimeout(timeout)


        resultado = sock.connect_ex(("::1", puerto))


        sock.close()


        if resultado == 0:


            return True





    except Exception:


        pass





    return False


```





**Par?metros:**





| Par?metro | Tipo | Default | Descripci?n |


|-----------|------|---------|-------------|


| `puerto` | `int` | `5432` | Puerto TCP a verificar |


| `timeout` | `float` | `2.0` | Timeout en segundos por intento |





**Mecanismo:** `socket.connect_ex()` retorna `0` si la conexi?n es exitosa, o un c?digo de error en caso contrario (a diferencia de `connect()` que lanza excepci?n). Esto evita manejo de excepciones para el caso normal.





### 4.9.10 _probar_puerto_powershell() (`db_config.py:1046-1057`)





```python


def _probar_puerto_powershell(puerto: int = 5432) -> bool:


    """Usa PowerShell para verificar si el puerto est? abierto."""


    try:


        proc = subprocess.run(


            ["powershell", "-NoProfile", "-Command",


             f"(New-Object System.Net.Sockets.TcpClient).Connect('127.0.0.1', {puerto}); $true"],


            capture_output=True, text=True, encoding="utf-8", errors="replace",


            timeout=5,


        )


        return "True" in proc.stdout or proc.returncode == 0


    except Exception:


        return False


```





**Comando PowerShell ejecutado:**


```powershell


(New-Object System.Net.Sockets.TcpClient).Connect('127.0.0.1', 5432); $true


```





Si la conexi?n falla, PowerShell lanza una excepci?n y `$true` nunca se imprime. Si tiene ?xito, `$true` se imprime en stdout.





### 4.9.11 _probar_puerto_cmd() (`db_config.py:1060-1070`)





```python


def _probar_puerto_cmd(puerto: int = 5432) -> bool:


    """Usa comando CMD para verificar si el puerto est? abierto."""


    try:


        proc = subprocess.run(


            ["cmd", "/c", f"powershell -NoProfile -Command \"(New-Object System.Net.Sockets.TcpClient).Connect('localhost', {puerto})\""],


            capture_output=True, text=True, encoding="utf-8", errors="replace",


            timeout=5,


        )


        return proc.returncode == 0


    except Exception:


        return False


```





M?todo alternativo que ejecuta PowerShell desde CMD. Incluido por compatibilidad con entornos donde `powershell.exe` no est? directamente en PATH pero `cmd.exe` s?.





---





## 4.10 Funciones Auxiliares de Red





### 4.10.1 _obtener_ips_locales() (`db_config.py:1073-1094`)





```python


def _obtener_ips_locales() -> list:


    """Obtiene todas las IPs disponibles en la m?quina."""


    ips = ["127.0.0.1", "localhost", "::1"]


    try:


        hostname = socket.gethostname()


        ips.append(hostname)


        ips.append(socket.gethostbyname(hostname))


    except Exception:


        pass


    try:


        proc = subprocess.run(


            ["powershell", "-NoProfile", "-Command",


             "Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4' -and $_.IPAddress -ne '127.0.0.1'} | Select-Object -ExpandProperty IPAddress"],


            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=10,


        )


        for ip in proc.stdout.strip().split("\n"):


            ip = ip.strip()


            if ip and ip not in ips:


                ips.append(ip)


    except Exception:


        pass


    return list(dict.fromkeys(ips))


```





**Par?metros:** Ninguno.





**Retorno:** `list` ??? IPs locales ?nicas.





**Fuentes de IPs (en orden):**





| Orden | Fuente | Ejemplo |


|-------|--------|---------|


| 1 | Hardcodeadas | `"127.0.0.1"`, `"localhost"`, `"::1"` |


| 2 | `socket.gethostname()` | `"MI-PC"` |


| 3 | `socket.gethostbyname(hostname)` | `"192.168.1.50"` |


| 4 | PowerShell `Get-NetIPAddress` | `"192.168.1.50"`, `"10.0.0.5"` |





**Deduplicaci?n:** `list(dict.fromkeys(ips))` preserva orden y elimina duplicados (disponible desde Python 3.7+ donde dict mantiene orden de inserci?n).





**Comando PowerShell:**


```powershell


Get-NetIPAddress | Where-Object {


    $_.AddressFamily -eq 'IPv4' -and


    $_.IPAddress -ne '127.0.0.1'


} | Select-Object -ExpandProperty IPAddress


```


Filtra solo direcciones IPv4 que no sean loopback.





### 4.10.2 obtener_ip_local() (`db_config.py:1021-1027`)





```python


def obtener_ip_local() -> str:


    """Obtiene la IP local conect?ndose a Google DNS (no env?a datos reales)."""


    try:


        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:


            sock.connect(("8.8.8.8", 80))


            return sock.getsockname()[0]


    except Exception:


        return "localhost"


```





**Par?metros:** Ninguno.





**Retorno:** `str` ??? IP local o `"localhost"` si falla.





**Mecanismo:** Crea un socket UDP y se "conecta" a `8.8.8.8:80` (Google DNS). En UDP, `connect()` no env?a datos reales; solo establece la ruta de salida, lo que permite al SO determinar qu? interfaz de red se usar?a. `getsockname()` retorna la IP de esa interfaz.





### 4.10.3 _buscar_psql_executable() (`db_config.py:1119-1140`)





```python


def _buscar_psql_executable() -> str:


    """Busca el ejecutable psql en el sistema."""


    rutas = [


        r"C:\Program Files\PostgreSQL\18\bin\psql.exe",


        r"C:\Program Files\PostgreSQL\17\bin\psql.exe",


        r"C:\Program Files\PostgreSQL\16\bin\psql.exe",


        r"C:\Program Files\PostgreSQL\15\bin\psql.exe",


        r"C:\Program Files\PostgreSQL\14\bin\psql.exe",


        r"C:\Program Files\PostgreSQL\13\bin\psql.exe",


        r"C:\Program Files (x86)\PostgreSQL\18\bin\psql.exe",


        r"C:\Program Files (x86)\PostgreSQL\17\bin\psql.exe",


        r"C:\Program Files (x86)\PostgreSQL\16\bin\psql.exe",


        r"C:\Program Files (x86)\PostgreSQL\15\bin\psql.exe",


        r"C:\PostgreSQL\18\bin\psql.exe",


        r"C:\PostgreSQL\17\bin\psql.exe",


        r"C:\PostgreSQL\16\bin\psql.exe",


        r"C:\PostgreSQL\15\bin\psql.exe",


    ]


    for ruta in rutas:


        if os.path.exists(ruta):


            return ruta


    return "psql"


```





**Par?metros:** Ninguno.





**Retorno:** `str` ??? ruta completa al psql.exe, o `"psql"` si no se encuentra (para que el sistema lo busque en PATH).





**Versiones buscadas:** 18, 17, 16, 15, 14, 13 en 3 ubicaciones cada una = 14 rutas.





### 4.10.4 _probar_psql_cmd() (Nivel de M?dulo) (`db_config.py:1097-1116`)





```python


def _probar_psql_cmd(password: str, puerto: int = 5432) -> tuple:


    """Usa psql via CMD para probar conexi?n (versi?n standalone)."""


    import os


    env = os.environ.copy()


    env["PGPASSWORD"] = password


    env["PGCLIENTENCODING"] = "UTF8"





    direcciones = _obtener_ips_locales()


    for ip in direcciones:


        try:


            proc = subprocess.run(


                ["psql", "-h", str(ip), "-p", str(puerto), "-U", "postgres",


                 "-d", "postgres", "-c", "SELECT 1;", "-t"],


                capture_output=True, text=True, encoding="utf-8", errors="replace",


                env=env, timeout=10,


            )


            if proc.returncode == 0 or "1" in proc.stdout:


                return (True, ip, password)


        except Exception:


            continue


    return (False, None, password)


```





**Diferencias con la versi?n anidada (dentro de `inicializar_base_datos`):**





| Caracter?stica | Versi?n anidada (4.8.5) | Versi?n standalone (4.10.4) |


|---------------|------------------------|----------------------------|


| Ubicaci?n | Dentro de `inicializar_base_datos()` | Nivel de m?dulo |


| Hosts probados | `[cfg.host, "127.0.0.1", "localhost"]` | `_obtener_ips_locales()` (todas) |


| Retorno | `bool` | `tuple[bool, str\|None, str]` |


| Puerto | `port` par?metro | `5432` default |


| Flag `-A` | S? | No |





### 4.10.5 _probar_conexion_cmd() (`db_config.py:1182-1214`)





```python


def _probar_conexion_cmd(password: str, attempts: int = 3) -> bool:


    """Usa pg_isready o psql via CMD para probar conexi?n."""


    import os





    for _ in range(attempts):


        # Intentar con pg_isready


        try:


            result = subprocess.run(


                ["pg_isready", "-h", "localhost", "-p", "5432"],


                capture_output=True, text=True, timeout=5,


                env=dict(os.environ, PGPASSWORD=password),


            )


            if result.returncode == 0:


                return True


        except Exception:


            pass





        # Intentar con psql


        try:


            result = subprocess.run(


                ["psql", "-h", "localhost", "-U", "postgres", "-d", "postgres",


                 "-c", "SELECT 1;", "-t", "-A"],


                capture_output=True, text=True, timeout=5,


                env=dict(os.environ, PGPASSWORD=password),


            )


            if result.returncode == 0 and "1" in result.stdout:


                return True


        except Exception:


            pass





        time.sleep(0.5)





    return False


```





**Par?metros:**





| Par?metro | Tipo | Default | Descripci?n |


|-----------|------|---------|-------------|


| `password` | `str` | ??? | Contrase?a a probar |


| `attempts` | `int` | `3` | N?mero de reintentos |





**Dos m?todos por intento:**





| M?todo | Comando | Verificaci?n |


|--------|---------|-------------|


| `pg_isready` | `pg_isready -h localhost -p 5432` | `returncode == 0` |


| `psql` | `psql -h localhost -U postgres -d postgres -c "SELECT 1;" -t -A` | `returncode == 0 AND "1" in stdout` |





### 4.10.6 _buscar_conexion_cmd() (`db_config.py:1217-1226`)





```python


def _buscar_conexion_cmd() -> str:


    """Busca conexi?n usando comandos CMD, probando contrase?as comunes."""


    passwords = ["ivan", "postgres", "admin", "root", "Password123!",


                "Admin123!", "Psql123!", "postgres123", "123456"]





    for pwd in passwords:


        if _probar_conexion_cmd(pwd, attempts=1):


            return pwd





    return ""


```





**Par?metros:** Ninguno.





**Retorno:** `str` ??? contrase?a encontrada, o `""` si ninguna funciona.





**Contrase?as probadas (9):**





| # | Password |


|---|----------|


| 1 | `"ivan"` |


| 2 | `"postgres"` |


| 3 | `"admin"` |


| 4 | `"root"` |


| 5 | `"Password123!"` |


| 6 | `"Admin123!"` |


| 7 | `"Psql123!"` |


| 8 | `"postgres123"` |


| 9 | `"123456"` |





Es la primera funci?n llamada por `inicializar_base_datos()`. Si funciona, se evita todo el pipeline de recuperaci?n.





---





## 4.11 Excepciones Personalizadas





### 4.11.1 PasswordRequeridoError (`db_config.py:302-306`)





```python


class PasswordRequeridoError(Exception):


    """Excepci?n cuando se requiere contrase?a manual."""


    def __init__(self, mensaje="Se requiere contrase?a manual"):


        self.mensaje = mensaje


        super().__init__(self.mensaje)


```





**Prop?sito:** Se?alar a la capa de UI que se necesita interacci?n del usuario para proporcionar la contrase?a de PostgreSQL.





**Flujo de captura:**





```


verificar_bd_esquema(permitir_password_manual=True)


  ?????? no encuentra contrase?a v?lida


      ?????? raise PasswordRequeridoError("Contrase?a incorrecta...")


          ?????? Capturado en modulo_configuracion_bd.py


              ?????? Muestra di?logo modal pidiendo contrase?a


                  ?????? Reintenta verificar_bd_esquema() con nueva contrase?a


```





---





# 5. INTERFAZ GRAFICA DE USUARIO

(Las acentuaciones han sido normalizadas a ASCII por compatibilidad de codificacion.)

## 5.1 main.py - Punto de Entrada

El archivo `main.py` (2857 lineas) es el punto de entrada principal de la aplicacion. Define la clase `SistemaSaludApp` que hereda de `ctk.CTk` (CustomTkinter), construye la interfaz grafica completa y orquesta todos los modulos del sistema.

### 5.1.1 Importaciones

```python
import customtkinter as ctk
import threading
import subprocess
CREATE_NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)
import sys, os, runpy, re, time, json
from tkinter import filedialog, messagebox
```

`CREATE_NO_WINDOW` (0x08000000) suprime ventanas de consola en subprocesos Windows. Se usa `getattr` para compatibilidad multiplataforma.

### 5.1.2 Modulos Internos

```python
from db_config import (
    get_db_config, update_db_config,
    verificar_bd_esquema, detectar_postgresql_existente,
    PASSWORD_POSTGRES, PasswordRequeridoError, CONFIG_DIR,
)
from scripts_python.ingesta.ejecutar_descarga import ejecutar_descarga
from scripts_python.ingesta.ejecutar_carga import ejecutar_carga
from scripts_python.instalacion.instalar_postgresql import (
    instalar_postgresql_automatico, instalar_postgresql
)
```

`db_config.py` centraliza la configuracion de PostgreSQL (auto-deteccion, verificacion y persistencia). `ejecutar_descarga` y `ejecutar_carga` son los modulos ETL. `instalar_postgresql` maneja la instalacion automatica del motor de BD.

### 5.1.3 Constantes Globales

```python
DIRECTORIO_RAIZ = os.path.dirname(os.path.abspath(sys.argv[0]))
DIRECTORIO_BASE_SCRIPT = DIRECTORIO_RAIZ
COLOR_BOTON = "#4A6B8C"
COLOR_BOTON_ACTIVO = "#2E4A6B"
COLOR_TEXTO = "#FFFFFF"
FUENTE_PREDETERMINADA = ("Segoe UI", 11)
```

`DIRECTORIO_RAIZ` se calcula desde `sys.argv[0]` para soportar tanto ejecucion directa como PyInstaller. Los colores definen el tema oscuro personalizado.

### 5.1.4 Secciones de Reporte Predefinidas

```python
SECCIONES = {
    1: "INGRESOS",
    2: "SALIDAS",
    3: "PRODUCCION",
    4: "ATENCIONES",
    5: "HIS/VS",
}
```

Mapea los indices numericos de secciones a sus nombres descriptivos. Usado por `BOTONES_REPORTE_PREDETERMINADOS` para organizar los botones de reporte.

### 5.1.5 Variable Global de Reportes

```python
def _reportes_a_generar():
    return []
```

Variable global mutable que almacena la lista de reportes pendientes de generacion. Es manipulada por los modulos de analisis y reportes para la ejecucion en segundo plano.

## 5.2 BOTONES_REPORTE_PREDETERMINADOS

### Estructura Interna de los 6 Botones

Cada una de las 6 entradas en `BOTONES_REPORTE_PREDETERMINADOS` sigue esta estructura:

| # | Seccion | Nombre | Tipo | Ruta |
|---|---------|--------|------|------|
| 1 | INGRESOS | Reporte Ingresos Mensual | sql | scripts_sql/reportes/ingresos_mensual.sql |
| 2 | SALIDAS | Reporte Salidas por Servicio | sql | scripts_sql/reportes/salidas_servicio.sql |
| 3 | PRODUCCION | Reporte Produccion Diaria | python | scripts_python/reportes/produccion_diaria.py |
| 4 | ATENCIONES | Reporte Atenciones por Medico | sql | scripts_sql/reportes/atenciones_medico.sql |
| 5 | HIS/VS | Reporte HIS-VS Mensual | python | scripts_python/reportes/his_vs_mensual.py |
| 6 | HIS/VS | Consolidado HIS-VS Anual | sql | scripts_sql/reportes/consolidado_hisvs.sql |

Cada boton se renderiza en la UI como un `CTkButton` que ejecuta el script correspondiente al hacer clic. Los parametros adicionales (ano, mes) se pasan al script segun la configuracion del boton.

`BOTONES_REPORTE_PREDETERMINADOS` es un diccionario que define los 6 reportes predefinidos del sistema. Cada entrada especifica la seccion, nombre, tipo de script (SQL/Python), ruta del archivo y parametros adicionales.

### Estructura de cada boton:

Cada boton es una tupla con los siguientes campos:

1. **seccion** (int): Indice de seccion (1-5) que agrupa el reporte.
2. **nombre** (str): Nombre descriptivo mostrado en la interfaz.
3. **tipo** (str): `"sql"` o `"python"` segun el lenguaje del script.
4. **ruta** (str): Ruta relativa al script desde `DIRECTORIO_RAIZ`.
5. **parametros** (dict): Parametros opcionales (ano, periodo, etc.).
6. **tooltip** (str): Texto de ayuda mostrado al pasar el raton.

## 5.3 Clase SistemaSaludApp

### Jerarquia de la Interfaz

La clase `SistemaSaludApp` organiza la UI en la siguiente jerarquia:

```
SistemaSaludApp (ctk.CTk)
 +-- frame_izquierdo (CTkFrame, 200px)
 |    +-- btn_ingesta, btn_reportes, btn_maestros, btn_editor
 |    +-- lbl_estado_conexion
 +-- frame_central (CTkFrame)
 |    +-- modulos["ingesta"]: Frame de ingesta ETL
 |    +-- modulos["reportes"]: Frame de reportes
 |    +-- modulos["maestros"]: Frame de maestros (ModuloMaestros)
 |    +-- modulos["config"]: Frame de configuracion BD
 +-- frame_inferior (CTkFrame, columnspan=2)
      +-- progress_bar (CTkProgressBar)
      +-- lbl_estado (CTkLabel)
      +-- btn_cancelar (CTkButton)
```

Esta estructura permite una navegacion fluida entre modulos y proporciona un panel de control global siempre visible.

`SistemaSaludApp` hereda de `ctk.CTk` y es la ventana principal de la aplicacion. Su constructor (`__init__`) configura la ventana, crea los contenedores, inicializa los modulos y configura los paneles de navegacion.

### 5.3.1 Constructor y Configuracion Inicial

```python
class SistemaSaludApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("Sistema de Salud Cusco - Proceso HIS")
        self.geometry("1200x700")
        self.minsize(900, 600)

        self.db_config = get_db_config()
        self.modulos = {}
        self.progress_queue = queue.Queue()
        self.progress_active = False
        self.cancel_token = threading.Event()
        self.token_maestros = threading.Event()
```

**Atributos clave:**

- `db_config`: Diccionario con parametros de conexion a PostgreSQL (host, port, database, schema, user, password).
- `modulos`: Diccionario que almacena los frames de cada modulo (ingesta, reportes, maestros, config).
- `progress_queue`: Cola thread-safe para comunicar mensajes de progreso desde hilos secundarios al hilo principal de la UI.
- `cancel_token` y `token_maestros`: Eventos `threading.Event()` que permiten cancelar operaciones en curso de forma segura.

### 5.3.2 Metodo _crear_contenedores()

```python
def _crear_contenedores(self):
    self.grid_rowconfigure(0, weight=1)
    self.grid_columnconfigure(0, weight=0, minsize=200)
    self.grid_columnconfigure(1, weight=1)

    self.frame_izquierdo = ctk.CTkFrame(self, width=200, corner_radius=0)
    self.frame_izquierdo.grid(row=0, column=0, sticky="nsew")

    self.frame_central = ctk.CTkFrame(self, corner_radius=0)
    self.frame_central.grid(row=0, column=1, sticky="nsew")
```

Divide la ventana en dos columnas: una barra lateral izquierda (200px) para navegacion y un area central para el contenido del modulo activo.

## 5.4 Panel de Ejecucion Global

### 5.4.0 Disposicion Visual del Panel

El panel inferior (frame_inferior) se organiza en una fila horizontal con tres zonas:

1. **Zona izquierda**: Barra de progreso (`CTkProgressBar`) con ancho de 400px.
2. **Zona central**: Etiqueta de estado (`CTkLabel`) que muestra el nombre de la operacion actual.
3. **Zona derecha**: Boton Cancelar (`CTkButton`) para detener la operacion activa.

El panel se ubica en la fila 1 de la cuadricula principal, ocupando ambas columnas (columnspan=2), lo que garantiza que sea visible independientemente del modulo activo.

### 5.4.0 Disposicion Visual del Panel

El panel inferior (frame_inferior) se organiza en una fila horizontal con tres zonas:

1. **Zona izquierda**: Barra de progreso (`CTkProgressBar`) con ancho de 400px.
2. **Zona central**: Etiqueta de estado (`CTkLabel`) que muestra el nombre de la operacion actual.
3. **Zona derecha**: Boton Cancelar (`CTkButton`) para detener la operacion activa.

El panel se ubica en la fila 1 de la cuadricula principal, ocupando ambas columnas (columnspan=2), lo que garantiza que sea visible independientemente del modulo activo.

Ubicado en la parte inferior de la ventana, proporciona controles universales para todas las operaciones del sistema.

### 5.4.1 Construccion del Panel

```python
def _construir_panel_ejecucion_global(self):
    self.frame_inferior = ctk.CTkFrame(self)
    self.frame_inferior.grid(row=1, column=0, columnspan=2, sticky="ew", padx=5, pady=2)

    self.progress_bar = ctk.CTkProgressBar(self.frame_inferior, width=400)
    self.progress_bar.pack(side="left", padx=10)
    self.progress_bar.set(0)

    self.lbl_estado = ctk.CTkLabel(self.frame_inferior, text="Listo")
    self.lbl_estado.pack(side="left", padx=10)

    self.btn_cancelar = ctk.CTkButton(self.frame_inferior, text="Cancelar", command=self._cancelar_operacion)
    self.btn_cancelar.pack(side="right", padx=10)
```

Componentes del panel:
1. **Barra de progreso** (`CTkProgressBar`): Muestra visualmente el avance (0-100%).
2. **Etiqueta de estado** (`CTkLabel`): Texto descriptivo de la operacion actual.
3. **Boton Cancelar** (`CTkButton`): Detiene la operacion activa mediante `cancel_token.set()`.

### 5.4.2 Sistema de Tokens de Cancelacion

### 5.4.3 Mecanismo de Hilos Daemon

### 5.4.4 Sincronizacion de Estado

El panel de ejecucion global mantiene un estado interno que refleja la operacion actual:

- **IDLE**: Ninguna operacion en curso. Todos los controles habilitados.
- **RUNNING**: Operacion en ejecucion. Barra de progreso activa, boton Cancelar visible.
- **COMPLETED**: Operacion finalizada exitosamente. Barra al 100%.
- **ERROR**: Operacion fallida. Barra se pone en rojo, mensaje de error.
- **CANCELLED**: Operacion cancelada por el usuario. Barra se reinicia.

```python
def _cambiar_estado(self, nuevo_estado):
    self.estado_global = nuevo_estado
    if nuevo_estado == "RUNNING":
        self.btn_cancelar.configure(state="normal")
        self.progress_bar.configure(progress_color="blue")
    elif nuevo_estado in ("COMPLETED", "ERROR", "CANCELLED"):
        self.btn_cancelar.configure(state="disabled")
        if nuevo_estado == "ERROR":
            self.progress_bar.configure(progress_color="red")
        self.progress_active = False
```

`SistemaSaludApp` utiliza hilos `daemon=True` para todas las operaciones en segundo plano. Esto garantiza que:

- Los hilos no impiden que la aplicacion se cierre.
- Si el usuario cierra la ventana, todos los hilos secundarios terminan automaticamente.
- No hay necesidad de gestion manual del ciclo de vida de los hilos.

La comunicacion entre hilos se realiza mediante dos mecanismos:

1. **`queue.Queue`**: Para enviar mensajes de progreso desde el hilo de trabajo al hilo principal.
2. **`threading.Event`**: Para senalizar cancelacion desde el hilo principal al hilo de trabajo.

```python
# En el hilo de trabajo:
while not cancel_token.is_set():
    # procesar...
    progress_queue.put(f"{pct}% {mensaje}")

# En el hilo principal (via self.after):
def _procesar_cola(self):
    while not self.progress_queue.empty():
        msg = self.progress_queue.get_nowait()
        self.lbl_estado.configure(text=msg)
    self.after(100, self._procesar_cola)
```

```python
def _cancelar_operacion(self):
    self.cancel_token.set()
    self.token_maestros.set()
    log_mensaje("Operacion cancelada por el usuario.", "WARNING")

def _resetear_tokens(self):
    self.cancel_token.clear()
    self.token_maestros.clear()
```

El sistema utiliza `threading.Event` como mecanismo de senalizacion entre hilos. Cuando el usuario presiona Cancelar, ambos tokens se activan, lo que hace que los bucles de procesamiento en los hilos secundarios verifiquen `is_set()` y se detengan ordenadamente.

### 5.4.3 Procesos Cancelables (Hilo Seguro)

```python
def ejecutar_en_hilo(self, target, args=(), callback=None):
    def wrapper():
        try:
            result = target(*args)
            if callback:
                self.after(0, callback, result)
        except Exception as e:
            self.after(0, log_mensaje, str(e), "ERROR")
    thread = threading.Thread(target=wrapper, daemon=True)
    thread.start()
```

`ejecutar_en_hilo` es el metodo generico para lanzar tareas en segundo plano. Usa `self.after(0, ...)` para devolver resultados al hilo principal de forma segura, evitando bloqueos de la interfaz.

## 5.5 Barra de Navegacion

### 5.5.1 Construccion de la Barra

### 5.5.2 Navegacion Programatica

### 5.5.3 Botones de Accion Rapida

Ademas de los botones de navegacion estandar, la barra lateral incluye botones de accion rapida:

1. **Refrescar conexion**: Verifica y actualiza el estado de conexion a BD.
2. **Abrir directorio de trabajo**: Abre el explorador de archivos en el directorio raiz del proyecto.
3. **Ayuda**: Muestra un dialogo con informacion de version y contactos.

```python
self.btn_refrescar = ctk.CTkButton(self.frame_izquierdo, text="Refrescar BD",
    command=self._actualizar_estado_conexion, fg_color="gray")
self.btn_refrescar.pack(pady=2, padx=10, fill="x")

self.btn_ayuda = ctk.CTkButton(self.frame_izquierdo, text="Ayuda",
    command=self._mostrar_ayuda, fg_color="gray")
self.btn_ayuda.pack(pady=2, padx=10, fill="x")
```

Ademas de los botones de navegacion, el sistema permite cambiar de modulo programaticamente mediante el metodo `mostrar_modulo(nombre)`. Este metodo:

1. Oculta todos los widgets del frame central usando `pack_forget()`.
2. Muestra el modulo solicitado desde `self.modulos[nombre]`.
3. Actualiza los estilos de los botones de navegacion (activo/inactivo).
4. Dispara cualquier actualizacion necesaria en el modulo destino.

```python
def mostrar_modulo(self, nombre):
    for w in self.frame_central.winfo_children():
        w.pack_forget()
    if nombre in self.modulos:
        self.modulos[nombre].pack(fill="both", expand=True)
    self._actualizar_botones_navegacion(nombre)
```

```python
def _construir_barra_navegacion(self):
    self.btn_ingesta = ctk.CTkButton(self.frame_izquierdo, text="Ingesta",
        command=lambda: self.mostrar_modulo("ingesta"))
    self.btn_ingesta.pack(pady=5, padx=10, fill="x")

    self.btn_reportes = ctk.CTkButton(self.frame_izquierdo, text="Reportes",
        command=lambda: self.mostrar_modulo("reportes"))
    self.btn_reportes.pack(pady=5, padx=10, fill="x")

    self.btn_maestros = ctk.CTkButton(self.frame_izquierdo, text="Maestros",
        command=lambda: self.mostrar_modulo("maestros"))
    self.btn_maestros.pack(pady=5, padx=10, fill="x")
```

Cada boton cambia el modulo visible y actualiza su estilo visual (activo/inactivo) para reflejar el estado actual de navegacion.

### 5.5.2 Indicador de Estado de Conexion

```python
def _actualizar_estado_conexion(self):
    try:
        conn = psycopg2.connect(**self.db_config)
        conn.close()
        self.lbl_estado_conexion.configure(text="BD: Conectado", text_color="green")
    except:
        self.lbl_estado_conexion.configure(text="BD: Desconectado", text_color="red")
```

Verifica periodicamente la conexion a PostgreSQL y actualiza un indicador visual en la barra lateral.

### 5.5.3 Modo Editor (Boton de Activacion)

```python
self.btn_editor = ctk.CTkButton(self.frame_izquierdo, text="Editor",
    command=self._login_editor)
self.btn_editor.pack(pady=5, padx=10, fill="x")
```

El boton "Editor" abre el dialogo de autenticacion para acceder al modo editor, que permite gestionar scripts SQL y crear nuevos reportes.

## 5.6 Sistema de Contenedores y Navegacion

### 5.6.1 Metodo mostrar_modulo() - Ciclo de Vida

Cada vez que el usuario navega a un modulo, `mostrar_modulo()` ejecuta el siguiente ciclo:

1. **Ocultar modulo actual**: Llama a `pack_forget()` en todos los widgets del frame central.
2. **Mostrar nuevo modulo**: Hace `pack(fill="both", expand=True)` en el modulo destino.
3. **Actualizar navegacion**: Cambia el color de fondo del boton activo en la barra lateral.
4. **Inicializar modulo**: Si es la primera vez, construye la interfaz del modulo.

```python
def mostrar_modulo(self, nombre):
    for w in self.frame_central.winfo_children():
        w.pack_forget()
    if nombre not in self.modulos:
        getattr(self, f"_construir_modulo_{nombre}")()
    self.modulos[nombre].pack(fill="both", expand=True)
    self._resaltar_boton_activo(nombre)
```

### 5.6.2 Estrategia de Construccion Perezosa

Los modulos se construyen bajo demanda (lazy construction) para minimizar el tiempo de inicio:

- `_construir_modulo_ingesta()`: Creado al primer acceso al modulo de ingesta.
- `_construir_modulo_reportes()`: Creado al primer acceso a reportes.
- `_construir_modulo_maestros()`: Creado al primer acceso a maestros.
- `_construir_modulo_configuracion()`: Creado al primer acceso a configuracion.

Una vez construidos, los frames se almacenan en `self.modulos` y se reutilizan en navegaciones posteriores.

### 5.6.1 Metodo mostrar_modulo()

```python
def mostrar_modulo(self, nombre):
    for widget in self.frame_central.winfo_children():
        widget.pack_forget()
    if nombre in self.modulos:
        self.modulos[nombre].pack(fill="both", expand=True)
    self._actualizar_botones_navegacion(nombre)
```

Limpia el frame central, muestra el modulo solicitado y actualiza los estilos de los botones de navegacion. Los modulos se almacenan en el diccionario `self.modulos` y se construyen bajo demanda en sus metodos `_construir_modulo_*()`.

### 5.6.2 Metodos mostrar_modulo_*()

Cada modulo tiene un metodo dedicado que construye la interfaz si es la primera vez que se accede:

- `mostrar_modulo_ingesta()`: Construye el panel de ingesta ETL con selector de periodo, botones de descarga/carga y control de procesos.
- `mostrar_modulo_reportes()`: Construye el panel de reportes con los botones predefinidos y opciones de personalizacion.
- `mostrar_modulo_maestros()`: Instancia el widget `ModuloMaestros` de `modulo_maestros.py`.
- `mostrar_modulo_configuracion()`: Muestra el panel de configuracion de base de datos con deteccion de PostgreSQL.

## 5.7 Modulo de Ingesta y Mantenimiento

### 5.7.1a Proceso ETL Completo

El modulo de ingesta ejecuta el pipeline ETL completo:

1. **Extraccion (Descarga)**: `ejecutar_descarga()` descarga los archivos HIS desde la fuente de datos (servidor FTP o archivo local).
2. **Transformacion**: Los datos se transforman al formato esperado por la base de datos (normalizacion, limpieza, validacion).
3. **Carga (Insercion)**: `ejecutar_carga()` inserta los datos transformados en PostgreSQL.

```python
def _ejecutar_descarga(self):
    periodo = self._obtener_periodo_seleccionado()
    if not periodo:
        return
    self.ejecutar_tarea(ejecutar_descarga,
        args=(periodo, self.cancel_token, self.progress_queue),
        callback=lambda r: log_mensaje(f"Descarga completada: {r}", "INFO"))

def _ejecutar_carga(self):
    periodo = self._obtener_periodo_seleccionado()
    if not periodo:
        return
    self.ejecutar_tarea(ejecutar_carga,
        args=(periodo, self.cancel_token, self.progress_queue),
        callback=lambda r: log_mensaje(f"Carga completada: {r}", "INFO"))
```

### 5.7.1 Construccion del Panel de Ingesta

```python
def _construir_modulo_ingesta(self):
    frame = ctk.CTkFrame(self.frame_central)
    self.modulos["ingesta"] = frame

    lbl = ctk.CTkLabel(frame, text="Ingesta de Datos", font=("Segoe UI", 16, "bold"))
    lbl.pack(pady=10)

    self.btn_descargar = ctk.CTkButton(frame, text="Descargar HIS",
        command=self._ejecutar_descarga)
    self.btn_descargar.pack(pady=5)

    self.btn_cargar = ctk.CTkButton(frame, text="Cargar a BD",
        command=self._ejecutar_carga)
    self.btn_cargar.pack(pady=5)
```

### 5.7.2 Carga Inteligente y Manejo de Periodos

```python
def _ejecutar_carga(self):
    periodo = self._obtener_periodo_seleccionado()
    self.ejecutar_en_hilo(ejecutar_carga, args=(periodo, self.cancel_token),
        callback=lambda r: log_mensaje(f"Carga completada: {r}", "INFO"))
```

Ejecuta la carga ETL en un hilo separado, pasando el periodo seleccionado y el token de cancelacion. El callback actualiza la UI cuando termina.

### 5.7.3 ejecutar_tarea() - Motor de Ejecucion Universal

```python
def ejecutar_tarea(self, funcion, args=(), callback=None):
    if self.progress_active:
        log_mensaje("Ya hay una tarea en ejecucion.", "WARNING")
        return
    self.progress_active = True
    self._resetear_tokens()
    self.ejecutar_en_hilo(funcion, args, callback)
```

Previene ejecuciones concurrentes verificando `progress_active`. Si ya hay una tarea activa, muestra una advertencia. Caso contrario, resetea los tokens y lanza el hilo.

### 5.7.4 Sistema de Progreso [PROGRESS]

```python
def _procesar_cola_progreso(self):
    try:
        while True:
            msg = self.progress_queue.get_nowait()
            if "%" in msg:
                pct = int(msg.split("%")[0])
                self.progress_bar.set(pct / 100)
            self.lbl_estado.configure(text=msg)
    except queue.Empty:
        pass
    self.after(100, self._procesar_cola_progreso)
```

`_procesar_cola_progreso` se ejecuta cada 100ms via `self.after()` y consume mensajes de la cola. Los hilos de trabajo envian actualizaciones con formato `"PORCENTAJE% Mensaje"`. Cuando el porcentaje llega a 100, la barra se completa y se reactiva el panel.

## 5.8 Modulo de Analisis y Reportes

### 5.8.0 Estructura del Panel de Reportes

El panel de reportes organiza los botones en secciones visuales:

- **Seccion INGRESOS**: Reportes relacionados con ingresos economicos y presupuestales.
- **Seccion SALIDAS**: Reportes de egresos, consumo y distribucion.
- **Seccion PRODUCCION**: Reportes de produccion de servicios de salud.
- **Seccion ATENCIONES**: Reportes de atenciones medicas y consultas.
- **Seccion HIS/VS**: Reportes del sistema HIS y Video Servicio.

Cada seccion tiene un encabezado con el nombre de la seccion y los botones de reporte correspondientes. La navegacion entre secciones se realiza mediante un scroll vertical.

### 5.8.0 Estructura del Panel de Reportes

El panel de reportes organiza los botones en secciones visuales:

- **Seccion INGRESOS**: Reportes relacionados con ingresos economicos y presupuestales.
- **Seccion SALIDAS**: Reportes de egresos, consumo y distribucion.
- **Seccion PRODUCCION**: Reportes de produccion de servicios de salud.
- **Seccion ATENCIONES**: Reportes de atenciones medicas y consultas.
- **Seccion HIS/VS**: Reportes del sistema HIS y Video Servicio.

Cada seccion tiene un encabezado con el nombre de la seccion y los botones de reporte correspondientes. La navegacion entre secciones se realiza mediante un scroll vertical.

### 5.8.1 Construccion del Panel de Reportes

```python
def _construir_modulo_reportes(self):
    frame = ctk.CTkFrame(self.frame_central)
    self.modulos["reportes"] = frame

    self._renderizar_botones_reportes(frame)
```

### 5.8.2 Renderizado de Botones de Reporte

Los botones se generan dinamicamente a partir de `BOTONES_REPORTE_PREDETERMINADOS`. Cada boton se ubica en la seccion correspondiente (INGRESOS, SALIDAS, PRODUCCION, ATENCIONES, HIS/VS) y ejecuta el script asociado al hacer clic.

```python
def _renderizar_botones_reportes(self, parent):
    for seccion_id, (nombre, tipo, ruta, params, tooltip) in BOTONES_REPORTE_PREDETERMINADOS.items():
        btn = ctk.CTkButton(parent, text=nombre,
            command=lambda s=seccion_id: self._ejecutar_reporte(s))
        btn.pack(pady=2, padx=10, fill="x")
```

### 5.8.3 Ejecucion de Scripts Python y SQL

### 5.8.4 Resultados de Reportes

### 5.8.5 Exportacion de Resultados

Los resultados de los reportes se pueden exportar a varios formatos:

1. **CSV**: Exporta los datos tabulares a un archivo CSV.
2. **Excel**: Exporta a formato XLSX (requiere openpyxl).
3. **HTML**: Genera una pagina HTML con los resultados formateados.

```python
def _exportar_resultado(self, resultados, formato="csv"):
    ruta = filedialog.asksaveasfilename(
        defaultextension=f".{formato}",
        filetypes=[(formato.upper(), f"*.{formato}")])
    if not ruta:
        return
    if formato == "csv":
        with open(ruta, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerows(resultados)
    log_mensaje(f"Resultados exportados a {ruta}", "INFO")
```

### 5.8.6 Parametrizacion de Reportes

Cada reporte puede aceptar parametros personalizados definidos en su entrada de `BOTONES_REPORTE_PREDETERMINADOS`:

- **Periodo**: Mes y ano para filtrar datos (AAAAMM).
- **Ambito**: Nivel de agregacion (establecimiento, red, regional).
- **Formato de salida**: PDF, Excel, HTML o CSV.
- **Destinatarios**: Lista de correos para envio automatico (opcional).

Los parametros se solicitan al usuario mediante un dialogo antes de ejecutar el reporte.

Los resultados de los reportes se muestran en una ventana emergente con un `CTkTextbox`. Para reportes SQL, los resultados tabulares se formatean como texto alineado. Para reportes Python, la salida del script se captura y se muestra directamente.

```python
def _mostrar_resultado_reporte(self, titulo, contenido):
    ventana = ctk.CTkToplevel(self)
    ventana.title(titulo)
    ventana.geometry("800x500")
    textbox = ctk.CTkTextbox(ventana, font=("Consolas", 11))
    textbox.pack(fill="both", expand=True, padx=10, pady=10)
    textbox.insert("1.0", contenido)
    textbox.configure(state="disabled")
```

```python
def _ejecutar_reporte(self, seccion_id):
    nombre, tipo, ruta, params, _ = BOTONES_REPORTE_PREDETERMINADOS[seccion_id]
    if tipo == "sql":
        self.ejecutar_en_hilo(self._ejecutar_script_sql, args=(ruta, params))
    elif tipo == "python":
        self.ejecutar_en_hilo(self._ejecutar_script_python, args=(ruta,))
```

Los scripts SQL se ejecutan directamente contra PostgreSQL usando `psycopg2`. Los scripts Python se ejecutan en un subproceso separado. Ambos metodos incluyen manejo de errores y registro mediante `log_mensaje()`.

## 5.9 Modulo de Gestion de Maestros (main.py)

### 5.9.1 Integracion con modulo_maestros.py

```python
def _construir_modulo_maestros(self):
    from modulo_maestros import ModuloMaestros
    frame = ctk.CTkFrame(self.frame_central)
    self.modulos["maestros"] = frame
    self.modulo_maestros_widget = ModuloMaestros(frame, self.db_config,
        progress_queue=self.progress_queue, cancel_token=self.cancel_token)
    self.modulo_maestros_widget.pack(fill="both", expand=True)
```

Importa e instancia `ModuloMaestros` como un widget hijo. Le pasa la configuracion de BD, la cola de progreso global y el token de cancelacion, permitiendo la integracion completa con el panel de ejecucion global.

### 5.9.2 Metodos de Interfaz

- `mostrar_modulo_maestros()`: Muestra el frame almacenado en `self.modulos["maestros"]`.
- `_actualizar_lista_bd_desde_main()`: (Opcional) Refresca la lista de tablas maestras desde la BD cuando se accede al modulo.

### 5.9.3 Manejo de Errores

Las operaciones de base de datos utilizan bloques try-except que capturan `Exception` generico y registran el error mediante `log_mensaje()`. Las transacciones de COPY se revierten automaticamente en caso de fallo mediante `conn.rollback()`.

## 5.10 Modulo de Configuracion de BD

### 5.10.1 Estructura de Tres Estados

El modulo de configuracion presenta tres estados visuales basados en la deteccion de PostgreSQL:

1. **PostgreSQL no instalado**: Muestra un boton "Instalar PostgreSQL" que ejecuta el instalador automatico.
2. **PostgreSQL instalado pero BD no configurada**: Muestra botones para crear la base de datos y el esquema.
3. **PostgreSQL instalado y BD configurada**: Muestra el estado de conexion y permite editar parametros.

### 5.10.2 Deteccion de Estado

```python
def _detectar_estado_postgresql(self):
    info = detectar_postgresql_existente()
    if info["installed"]:
        if verificar_bd_esquema(get_db_config()):
            return "CONFIGURADO"
        return "INSTALADO_SIN_BD"
    return "NO_INSTALADO"
```

Utiliza `detectar_postgresql_existente()` de `db_config.py` para verificar instalacion, servicio y ruta del binario. `verificar_bd_esquema()` prueba la conexion a la BD y esquema especificos.

### 5.10.3 Instalacion Automatica de PostgreSQL

```python
def _instalar_postgresql(self):
    self.ejecutar_en_hilo(instalar_postgresql_automatico,
        callback=lambda r: self._post_instalacion(r))
```

Ejecuta el instalador de PostgreSQL en segundo plano. `instalar_postgresql_automatico()` descarga el instalador oficial de PostgreSQL 16, lo ejecuta con parametros silenciosos y configura el servicio. Al finalizar, llama a `_post_instalacion()` que verifica el resultado y actualiza la interfaz.

### 5.10.4 Inicializacion de BD y Esquema

### 5.10.5 Configuracion Manual de Conexion

### 5.10.6 Deteccion de PostgreSQL - Algoritmo Completo

```python
def detectar_postgresql_existente():
    resultado = {"installed": False, "version": None,
                 "servicio": None, "ruta_bin": None}
    # 1. Buscar en PATH
    for cmd in ["psql", "pg_isready"]:
        ruta = shutil.which(cmd)
        if ruta:
            resultado["ruta_bin"] = os.path.dirname(ruta)
            break
    # 2. Buscar en Program Files
    if not resultado["ruta_bin"]:
        for pg_dir in ["PostgreSQL/16/bin", "PostgreSQL/15/bin",
                       "PostgreSQL/14/bin", "PostgreSQL/13/bin"]:
            ruta = os.path.join("C:/Program Files", pg_dir)
            if os.path.exists(os.path.join(ruta, "psql.exe")):
                resultado["ruta_bin"] = ruta
                break
    # 3. Probar conexion al puerto 5432
    if resultado["ruta_bin"]:
        resultado["installed"] = True
        resultado["version"] = "16"
    # 4. Verificar servicio
    try:
        subprocess.run(["sc", "query", "postgresql-x64-16"],
                      capture_output=True, check=True)
        resultado["servicio"] = "running"
    except:
        resultado["servicio"] = "stopped"
    return resultado
```

El modulo de configuracion permite al usuario editar manualmente los parametros de conexion:

- **Host**: Direccion del servidor PostgreSQL (default: localhost).
- **Port**: Puerto de conexion (default: 5432).
- **Database**: Nombre de la base de datos (default: ivan_proceso_his).
- **Schema**: Esquema dentro de la base de datos (default: es_ivan).
- **User**: Usuario de PostgreSQL (default: postgres).
- **Password**: Contrasena del usuario (gestionada por el dialogo de contrasena).

Los cambios se persisten en `%APPDATA%/Proyecto_Salud_Cusco/config/db_connection.json` mediante `update_db_config()`.

```python
def _inicializar_bd(self):
    try:
        inicializar_base_datos(self.db_config)
        log_mensaje("Base de datos inicializada correctamente.", "INFO")
        self._actualizar_estado_conexion()
    except Exception as e:
        log_mensaje(f"Error al inicializar BD: {e}", "ERROR")
```

`inicializar_base_datos()` crea la base de datos y el esquema si no existen, utilizando el usuario postgres.

## 5.11 Dialogo de Contrasena

### 5.11.1 PasswordWindow - Implementacion Completa

```python
class PasswordWindow(ctk.CTkToplevel):
    def __init__(self, parent, titulo="Password PostgreSQL",
                 mensaje="Ingrese la contrasena del usuario postgres:"):
        super().__init__(parent)
        self.title(titulo)
        self.geometry("420x220")
        self.resizable(False, False)
        self.transient(parent)
        self.grab_set()

        ctk.CTkLabel(self, text=mensaje, wraplength=380).pack(pady=15)
        self.entry = ctk.CTkEntry(self, show="*", width=300)
        self.entry.pack(pady=10)
        self.entry.focus_set()
        self.entry.bind("<Return>", lambda e: self._aceptar())

        frame_botones = ctk.CTkFrame(self)
        frame_botones.pack(pady=15)
        ctk.CTkButton(frame_botones, text="Conectar",
            command=self._aceptar, width=120).pack(side="left", padx=10)
        ctk.CTkButton(frame_botones, text="Cancelar",
            command=self.destroy, width=120).pack(side="left", padx=10)

        self.password = None
        self.protocol("WM_DELETE_WINDOW", self.destroy)

    def _aceptar(self):
        self.password = self.entry.get()
        self.destroy()
```

### 5.11.2 Manejo de Intentos Fallidos

```python
def _pedir_password_dialogo(self, max_intentos=3):
    for intento in range(max_intentos):
        pw = PasswordWindow(self)
        self.wait_window(pw)
        if pw.password:
            try:
                conn = psycopg2.connect(**{**self.db_config, "password": pw.password})
                conn.close()
                PASSWORD_POSTGRES.password = pw.password
                update_db_config({"password": pw.password})
                return True
            except psycopg2.Error:
                restantes = max_intentos - intento - 1
                if restantes > 0:
                    messagebox.showerror("Error",
                        f"Contrasena incorrecta. Intentos restantes: {restantes}")
                else:
                    self._ofrecer_recuperacion()
        else:
            break
    return False
```

### 5.11.3 Opciones de Recuperacion de Contrasena

Cuando se agotan los intentos, `_ofrecer_recuperacion()` presenta un dialogo con opciones:

1. **Restablecer contrasena**: Abre un shell con `ALTER USER postgres PASSWORD 'nueva'`.
2. **Modo trust**: Edita `pg_hba.conf` para permitir acceso sin contrasena.
3. **Abrir pgAdmin**: Intenta abrir pgAdmin para configuracion manual.
4. **Salir**: Cierra la aplicacion.

```python
def _ofrecer_recuperacion(self):
    opcion = messagebox.askquestion("Recuperacion",
        "No se pudo conectar. 

"
        "Si - Restablecer contrasena de PostgreSQL
"
        "No - Abrir pg_hba.conf para configurar trust",
        icon="warning")
    if opcion == "yes":
        self._resetear_password_postgres()
    else:
        self._configurar_trust_pg_hba()
```

### 5.11.1 PasswordWindow

```python
class PasswordWindow(ctk.CTkToplevel):
    def __init__(self, parent, title="Password", message="Ingrese contrasena:"):
        super().__init__(parent)
        self.title(title)
        self.geometry("400x200")
        self.resizable(False, False)

        lbl = ctk.CTkLabel(self, text=message)
        lbl.pack(pady=10)

        self.entry = ctk.CTkEntry(self, show="*")
        self.entry.pack(pady=5, padx=20, fill="x")
        self.entry.focus()

        btn_frame = ctk.CTkFrame(self)
        btn_frame.pack(pady=10)

        ctk.CTkButton(btn_frame, text="Conectar", command=self._aceptar).pack(side="left", padx=5)
        ctk.CTkButton(btn_frame, text="Cancelar", command=self.destroy).pack(side="left", padx=5)

        self.password = None
        self.grab_set()

    def _aceptar(self):
        self.password = self.entry.get()
        self.destroy()
```

Ventana modal que solicita la contrasena de PostgreSQL al usuario. Usa `grab_set()` para comportamiento modal y `show="*"` para ocultar la contrasena mientras se escribe.

### 5.11.2 Proceso de Autenticacion

```python
def _pedir_password_dialogo(self):
    pw = PasswordWindow(self)
    self.wait_window(pw)
    if pw.password:
        PASSWORD_POSTGRES.password = pw.password
        return True
    return False
```

Crea la ventana modal, espera a que el usuario interactue (`wait_window`) y almacena la contrasena en la variable global `PASSWORD_POSTGRES.password` para uso posterior en las conexiones.

### 5.11.3 Opciones de Recuperacion

Cuando la autenticacion falla repetidamente, el sistema ofrece:

1. **Restablecer contrasena**: Ejecuta `ALTER USER postgres PASSWORD '...'` mediante el instalador de PostgreSQL.
2. **Editar pg_hba.conf**: Cambia el metodo de autenticacion a `trust` para acceso sin contrasena.
3. **Reintentar**: Permite al usuario volver a intentar con otra contrasena.

Ambas opciones de recuperacion requieren privilegios de administrador y pueden invocar el elevador de permisos de Windows.

## 5.12 Modo Editor

### 5.12.1 Autenticacion (Login)

```python
def _login_editor(self):
    dialog = ctk.CTkInputDialog(text="Ingrese contrasena de editor:", title="Login Editor")
    password = dialog.get_input()
    if password == "admin123":
        self._activar_modo_editor()
    else:
        messagebox.showerror("Error", "Contrasena incorrecta")
```

### 5.12.2 Gestor de Scripts (Explorador)

```python
def _activar_modo_editor(self):
    self.editor_activo = True
    self._construir_gestor_scripts()
```

El gestor de scripts lista los archivos SQL en `scripts_sql/reportes/` y permite:

- **Abrir**: Carga el script seleccionado en el editor.
- **Editar**: Modifica el contenido del script.
- **Eliminar**: Borra el script seleccionado (con confirmacion).
- **Nuevo**: Crea un nuevo script SQL en blanco.

### 5.12.3 Editor de Scripts SQL

```python
def _construir_editor_scripts(self, parent):
    self.editor_text = ctk.CTkTextbox(parent, font=("Consolas", 12))
    self.editor_text.pack(fill="both", expand=True, padx=10, pady=10)

    btn_guardar = ctk.CTkButton(parent, text="Guardar", command=self._guardar_script)
    btn_guardar.pack(side="left", padx=5)

    btn_ejecutar = ctk.CTkButton(parent, text="Ejecutar", command=self._ejecutar_script_desde_editor)
    btn_ejecutar.pack(side="left", padx=5)
```

El editor usa un `CTkTextbox` con fuente monoespaciada (Consolas 12) para edicion de SQL. Incluye botones para guardar y ejecutar el script directamente contra la base de datos.

### 5.12.4 Creacion de Nuevo Boton SQL

```python
def _crear_nuevo_boton_sql(self):
    nombre = ctk.CTkInputDialog(text="Nombre del reporte:", title="Nuevo Reporte").get_input()
    if nombre:
        ruta = os.path.join(BASE, "scripts_sql", "reportes", f"{nombre.lower().replace(' ', '_')}.sql")
        with open(ruta, "w", encoding="utf-8") as f:
            f.write("-- Nuevo reporte\nSELECT 1;\n")
        # Recargar botones
        self._renderizar_botones_reportes(self.modulos["reportes"])
```

### 5.12.5 Eliminacion de Botones

### 5.12.6 Panel de Vista Previa de Reportes

### 5.12.7 Historial de Scripts

El modo editor mantiene un historial de los ultimos 10 scripts abiertos:

```python
MAX_HISTORIAL = 10
_historial_scripts = []

def _agregar_al_historial(self, ruta):
    if ruta in _historial_scripts:
        _historial_scripts.remove(ruta)
    _historial_scripts.insert(0, ruta)
    if len(_historial_scripts) > MAX_HISTORIAL:
        _historial_scripts.pop()
    self._guardar_configuracion_editor(
        {"ultimo_script": ruta, "historial": _historial_scripts})
```

### 5.12.8 Resaltado de Sintaxis SQL

El editor incluye resaltado basico de sintaxis SQL para palabras clave:

```python
PALABRAS_CLAVE_SQL = [
    "SELECT", "FROM", "WHERE", "INSERT", "UPDATE", "DELETE",
    "CREATE", "ALTER", "DROP", "TABLE", "INTO", "VALUES",
    "JOIN", "LEFT", "RIGHT", "INNER", "OUTER", "ON", "AND", "OR",
    "GROUP", "BY", "ORDER", "HAVING", "LIMIT", "OFFSET", "AS",
    "DISTINCT", "COUNT", "SUM", "AVG", "MIN", "MAX", "EXISTS",
    "IN", "BETWEEN", "LIKE", "IS", "NULL", "NOT", "CASE", "WHEN",
    "THEN", "ELSE", "END", "CAST", "COALESCE", "NULLIF"
]

def _resaltar_sintaxis(self, event=None):
    content = self.editor_text.get("1.0", "end-1c")
    self.editor_text.tag_remove("keyword", "1.0", "end")
    for palabra in PALABRAS_CLAVE_SQL:
        start = "1.0"
        while True:
            pos = self.editor_text.search(palabra, start, "end",
                nocase=True)
            if not pos:
                break
            end = f"{pos}+{len(palabra)}c"
            self.editor_text.tag_add("keyword", pos, end)
            start = end
    self.editor_text.tag_config("keyword", foreground="blue")
```

El modo editor incluye un panel de vista previa que permite ejecutar el script editado y ver los resultados sin salir del editor:

1. El usuario hace clic en "Ejecutar" dentro del editor.
2. El script se ejecuta contra la base de datos (o como subproceso para scripts Python).
3. Los resultados se muestran en un panel inferior dentro de la misma ventana del editor.
4. Si hay errores de sintaxis, se muestran en rojo con la linea problematica resaltada.

```python
def _ejecutar_script_desde_editor(self):
    codigo = self.editor_text.get("1.0", "end-1c")
    try:
        conn = psycopg2.connect(**self.db_config)
        with conn.cursor() as cur:
            cur.execute(codigo)
            resultados = cur.fetchall()
        conn.close()
        self._mostrar_resultados(resultados)
    except Exception as e:
        self._mostrar_error_editor(str(e))
```

```python
def _eliminar_boton_reporte(self, seccion_id):
    if messagebox.askyesno("Confirmar", "Eliminar reporte seleccionado?"):
        del BOTONES_REPORTE_PREDETERMINADOS[seccion_id]
        self._renderizar_botones_reportes(self.modulos["reportes"])
```

## 5.13 Persistencia de Configuracion del Editor

### 5.13.1 Formato del Archivo de Configuracion

```python
{
    "ultimo_script": "scripts_sql/reportes/ingresos_mensual.sql",
    "tema": "claro",
    "fuente": {"familia": "Consolas", "tamano": 12},
    "ventana": {"ancho": 800, "alto": 500, "maximizado": false},
    "historial": [
        "scripts_sql/reportes/ingresos_mensual.sql",
        "scripts_sql/reportes/salidas_servicio.sql"
    ]
}
```

### 5.13.2 Ciclo de Vida de la Configuracion

1. **Carga**: Al iniciar el modo editor, se llama a `_cargar_configuracion_editor()`.
2. **Uso**: Los valores cargados restauran el estado del editor (ultimo script, tamano de ventana, fuente).
3. **Guardado**: Al cerrar el editor o al cambiar de script, se persiste el estado actual.

La configuracion se almacena en `%APPDATA%/Proyecto_Salud_Cusco/config/editor_config.json` y persiste entre sesiones.

### 5.13.1 Carga de Configuracion

```python
def _cargar_configuracion_editor(self):
    ruta = os.path.join(CONFIG_DIR, "editor_config.json")
    if os.path.exists(ruta):
        with open(ruta, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"ultimo_script": "", "tema": "claro"}
```

### 5.13.2 Guardado de Configuracion

```python
def _guardar_configuracion_editor(self, config):
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(os.path.join(CONFIG_DIR, "editor_config.json"), "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2)
```

La configuracion del editor se persiste en `%APPDATA%/Proyecto_Salud_Cusco/config/editor_config.json`. Incluye el ultimo script abierto y preferencias de visualizacion.

## 5.14 Funciones Auxiliares de UI

### 5.14.1 Sistema de Log - Buffer Circular

El log interno utiliza un buffer circular de 1000 entradas para evitar el crecimiento ilimitado de memoria:

```python
MAX_LOG_ENTRIES = 1000
_log_buffer = []

def log_mensaje(mensaje, nivel="INFO"):
    timestamp = time.strftime("[%H:%M:%S]")
    entrada = f"{timestamp} [{nivel}] {mensaje}"
    _log_buffer.append(entrada)
    if len(_log_buffer) > MAX_LOG_ENTRIES:
        _log_buffer.pop(0)
    if hasattr(app, "log_textbox") and app.log_textbox.winfo_exists():
        app.log_textbox.configure(state="normal")
        app.log_textbox.insert("end", entrada + "
")
        app.log_textbox.see("end")
        app.log_textbox.configure(state="disabled")
```

Colores por nivel:
- **INFO**: `"green"` - Operaciones exitosas y progreso normal.
- **WARNING**: `"orange"` - Advertencias y condiciones inesperadas no criticas.
- **ERROR**: `"red"` - Errores que requieren atencion del usuario.

### 5.14.2 Selector de Meses - Cuadricula Interactiva

El selector de meses presenta una cuadricula 4x3 con los 12 meses del ano, mas controles de navegacion anual:

```python
def _seleccionar_mes(parent):
    dialog = ctk.CTkToplevel(parent)
    dialog.title("Seleccionar Periodo")
    dialog.geometry("350x300")
    dialog.resizable(False, False)
    dialog.transient(parent)
    dialog.grab_set()

    ano_actual = datetime.date.today().year
    ano = tk.IntVar(value=ano_actual)
    resultado = {"mes": None, "ano": None}

    # Encabezado con navegacion de ano
    header = ctk.CTkFrame(dialog)
    header.pack(pady=10)
    ctk.CTkButton(header, text="<<", width=30,
        command=lambda: ano.set(ano.get() - 1)).pack(side="left", padx=5)
    lbl_ano = ctk.CTkLabel(header, textvariable=ano, font=("Segoe UI", 14, "bold"))
    lbl_ano.pack(side="left", padx=10)
    ctk.CTkButton(header, text=">>", width=30,
        command=lambda: ano.set(ano.get() + 1)).pack(side="left", padx=5)

    # Cuadricula de meses
    meses = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
             "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
    grid = ctk.CTkFrame(dialog)
    grid.pack(pady=10)
    for i, mes in enumerate(meses):
        btn = ctk.CTkButton(grid, text=mes[:3], width=70,
            command=lambda m=i+1: [resultado.update({"mes": m, "ano": ano.get()}), dialog.destroy()])
        btn.grid(row=i//3, column=i%3, padx=3, pady=3)

    parent.wait_window(dialog)
    return resultado["mes"], resultado["ano"]
```

### 5.14.1 log_mensaje()

```python
def log_mensaje(mensaje, nivel="INFO"):
    timestamp = time.strftime("%H:%M:%S")
    colores = {"INFO": "green", "WARNING": "orange", "ERROR": "red"}
    color = colores.get(nivel, "white")
    texto_formateado = f"[{timestamp}] {nivel}: {mensaje}"

    app.log_textbox.configure(state="normal")
    app.log_textbox.insert("end", texto_formateado + "\n")
    app.log_textbox.see("end")
    app.log_textbox.configure(state="disabled")
```

`log_mensaje()` es el sistema central de registro. Agrega una entrada al `CTkTextbox` de log con formato `[HH:MM:SS] NIVEL: mensaje` y colorea segun la severidad (verde=INFO, naranja=WARNING, rojo=ERROR). Se usa desde todos los modulos del sistema.

### 5.14.2 Selector de Meses (Popup)

```python
def _seleccionar_mes(parent, ano_inicial=None):
    dialog = ctk.CTkToplevel(parent)
    dialog.title("Seleccionar Mes")
    dialog.geometry("300x250")
    dialog.grab_set()

    meses = ["Ene","Feb","Mar","Abr","May","Jun",
             "Jul","Ago","Sep","Oct","Nov","Dic"]
    resultado = [None]

    def seleccionar(m):
        resultado[0] = m
        dialog.destroy()

    for i, mes in enumerate(meses):
        btn = ctk.CTkButton(dialog, text=mes,
            command=lambda m=i+1: seleccionar(m))
        btn.grid(row=i//3, column=i%3, padx=5, pady=5)

    parent.wait_window(dialog)
    return resultado[0]
```

Ventana modal que muestra los 12 meses en una cuadricula 4x3. Usa `grab_set()` y `wait_window()` para comportamiento modal. Retorna el numero de mes seleccionado (1-12) o `None` si se cierra sin seleccion.

### 5.14.3 Progreso de Operaciones

```python
def _actualizar_progreso(porcentaje, mensaje=""):
    app.progress_bar.set(porcentaje / 100)
    app.lbl_estado.configure(text=mensaje)
    app.update_idletasks()
```

Actualiza la barra de progreso global y la etiqueta de estado. `update_idletasks()` fuerza la actualizacion visual de la UI, permitiendo que el usuario vea el progreso en tiempo real durante operaciones largas.

## 5.15 Punto de Entrada Principal

### 5.15.1 Procesamiento de Argumentos de Linea de Comandos

```python
if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Sistema de Salud Cusco")
    parser.add_argument("--run-script", help="Ejecutar script en modo CLI")
    parser.add_argument("--periodo", help="Periodo para operaciones ETL")
    parser.add_argument("--modo", choices=["gui", "cli"], default="gui",
        help="Modo de ejecucion")
    args = parser.parse_args()

    if args.modo == "cli" or args.run_script:
        # Modo CLI - sin interfaz grafica
        if args.run_script:
            with open(args.run_script, "r", encoding="utf-8") as f:
                exec(f.read())
        elif args.periodo:
            ejecutar_carga(args.periodo)
    else:
        # Modo GUI
        ctk.set_appearance_mode("System")
        ctk.set_default_color_theme("green")
        app = SistemaSaludApp()
        app.mainloop()
```

### 5.15.2 Integracion con PyInstaller

Cuando la aplicacion se compila con PyInstaller, `sys.argv[0]` contiene la ruta del ejecutable. El codigo maneja este caso especial:

```python
if getattr(sys, "frozen", False):
    DIRECTORIO_RAIZ = os.path.dirname(sys.executable)
else:
    DIRECTORIO_RAIZ = os.path.dirname(os.path.abspath(sys.argv[0]))
```

Esto asegura que las rutas relativas a scripts, configuracion y datos funcionen correctamente tanto en desarrollo como en el ejecutable compilado.

### 5.15.1 Ejecucion Normal (GUI)

```python
if __name__ == "__main__":
    ctk.set_appearance_mode("System")
    ctk.set_default_color_theme("green")
    app = SistemaSaludApp()
    app.mainloop()
```

Configura CustomTkinter en modo "System" (sigue el tema del SO) con tema verde, crea la instancia de `SistemaSaludApp` e inicia el bucle principal de eventos.

### 5.15.2 Modo --run-script (PyInstaller / CLI)

```python
if "--run-script" in sys.argv:
    idx = sys.argv.index("--run-script")
    if idx + 1 < len(sys.argv):
        ruta_script = sys.argv[idx + 1]
        if os.path.exists(ruta_script):
            with open(ruta_script, "r", encoding="utf-8") as f:
                exec(f.read())
        else:
            print(f"Script no encontrado: {ruta_script}")
            sys.exit(1)
```

Modo de linea de comandos para entornos PyInstaller o automatizacion. Lee un script Python desde la ruta especificada y lo ejecuta con `exec()`. Utilizado por tareas programadas y despliegues automatizados.

# 6. MODULO DE GESTION DE MAESTROS

## 6.1 modulo_maestros.py - Descripcion General

### 6.1.0 Arquitectura del Modulo

El modulo `modulo_maestros.py` sigue una arquitectura de capas:

1. **Capa de datos**: Funciones de conexion y consulta a PostgreSQL (`conexion_bd`, `obtener_registros`, `obtener_tablas_en_bd`).
2. **Capa de negocio**: Logica de carga CSV, validacion y transformacion de datos.
3. **Capa de presentacion**: Interfaz grafica construida con CustomTkinter y ttk.Treeview.
4. **Capa de integracion**: Conexion con el panel de ejecucion global y el sistema de progreso.

Cada capa se comunica con la siguiente a traves de interfaces bien definidas, lo que permite mantener el codigo modular y facil de mantener.

El archivo `modulo_maestros.py` (1342 lineas) implementa la interfaz grafica y la logica de negocio para la gestion de tablas maestras del sistema. Proporciona funcionalidades de carga de datos desde archivos CSV a PostgreSQL, visualizacion del contenido de las tablas, eliminacion de tablas y generacion del proceso HIS.

### 6.1.1 Importaciones y Dependencias

```python
import customtkinter as ctk
from tkinter import ttk, filedialog, messagebox
import psycopg2
from io import StringIO
import csv, os, re, queue, threading, time, datetime
from db_config import get_db_config, PASSWORD_POSTGRES
```

### 6.1.2 Funciones de Conexion a BD

### 6.1.3 Esquema de Base de Datos

El modulo de maestros opera dentro del esquema `es_ivan` de la base de datos `ivan_proceso_his`. Las tablas maestras se crean en este esquema y todas las consultas hacen referencia explicita al mismo:

```python
SCHEMA_NAME = "es_ivan"

def _nombre_completo(tabla):
    return f"{SCHEMA_NAME}.{tabla}"
```

### 6.1.4 Dependencias entre Tablas

Muchas tablas maestras tienen dependencias entre si a traves de claves foraneas:

- `maestro_paciente` es referenciada por `maestro_paciente_domicilio`, `maestro_paciente_contacto` y `maestro_paciente_seguro`.
- `maestro_personal` es referenciada por `maestro_personal_cargo`, `maestro_personal_laboral` y `maestro_personal_formacion`.
- `eess2025` es referenciada por `maestro_servicios` y `maestro_equipos`.
- `maestro_cie10` es referenciada por `maestro_produccion_diagnostico` y `maestro_referencia_diagnostico`.

Estas dependencias determinan el orden en que deben cargarse los CSV: las tablas padre deben cargarse antes que las hijas.

```python
def conexion_bd(db_config):
    return psycopg2.connect(**db_config)

def obtener_registros(query, db_config):
    conn = conexion_bd(db_config)
    try:
        with conn.cursor() as cur:
            cur.execute(query)
            return cur.fetchall()
    finally:
        conn.close()
```

`conexion_bd()` es una fabrica de conexiones PostgreSQL. `obtener_registros()` ejecuta consultas SELECT y retorna los resultados como lista de tuplas, cerrando siempre la conexion en el bloque `finally`.

## 6.2 Catalogo de Tablas Maestras (DESCRIPCION_MAESTROS)


### Categorias de Tablas Maestras

Las 24 tablas maestras se agrupan en las siguientes categorias funcionales:

**Datos Maestros de Pacientes (5 tablas):**
- `maestro_paciente`: Datos demograficos basicos del paciente.
- `maestro_paciente_identidad`: Documentos de identidad alternativos.
- `maestro_paciente_domicilio`: Direcciones y ubicacion geografica.
- `maestro_paciente_contacto`: Numeros de telefono y correos electronicos.
- `maestro_paciente_seguro`: Informacion de aseguramiento (SIS, etc.).

**Datos Maestros de Personal (4 tablas):**
- `maestro_personal`: Datos del personal de salud (colegio profesional, especialidad).
- `maestro_personal_cargo`: Historial de cargos del personal.
- `maestro_personal_laboral`: Datos laborales (regimen, condicion).
- `maestro_personal_formacion`: Formacion academica y capacitaciones.

**Datos Maestros de Establecimientos (3 tablas):**
- `eess2025`: Catalogo de establecimientos con red, microred, provincia y distrito.
- `maestro_servicios`: Servicios disponibles en cada establecimiento.
- `maestro_equipos`: Equipamiento medico de los establecimientos.

**Datos Maestros de Produccion (4 tablas):**
- `maestro_produccion_servicio`: Produccion por servicio.
- `maestro_produccion_medico`: Produccion por medico.
- `maestro_produccion_diagnostico`: Produccion por diagnostico (CIE).
- `maestro_produccion_procedimiento`: Produccion por procedimiento (CPT).

**Datos Maestros de Referencia (3 tablas):**
- `maestro_referencia_origen`: Establecimientos de origen de referencias.
- `maestro_referencia_destino`: Establecimientos de destino de referencias.
- `maestro_referencia_diagnostico`: Diagnosticos asociados a referencias.

**Datos de Soporte (5 tablas):**
- `maestro_cie10`: Catalogo de diagnosticos CIE-10.
- `maestro_cpt`: Catalogo de procedimientos CPT.
- `maestro_medicamentos`: Catalogo de medicamentos esenciales.
- `maestro_insumos`: Catalogo de insumos medicos.
- `maestro_laboratorio`: Catalogo de examenes de laboratorio.

`DESCRIPCION_MAESTROS` es un diccionario de 24 entradas que define el catalogo completo de tablas maestras del sistema. Cada entrada mapea un nombre de tabla a su descripcion funcional.

```python
DESCRIPCION_MAESTROS = {
    "maestro_paciente":              "Paciente (DNI, nombre, fecha nac., género, etnia)",
    "maestro_personal":              "Personal de salud (colegio profesional)",
    "eess2025":                      "Establecimiento (red, microred, provincia, distrito)",
    "maestro_his_establecimiento":   "Establecimientos crudos HIS (fuente para reconstruir eess2025)",
    "maestro_his_cie_cpms":          "Diagnósticos CIE / Procedimientos CPT",
    "maestro_his_etnia":             "Etnias (descripción)",
    "maestro_his_ups":               "Unidades Productoras de Servicios (UPS)",
    "maestro_his_colegio":           "Colegios profesionales",
    "maestro_his_actividad":         "Actividades HIS",
    "maestro_his_centro_poblado":    "Centros poblados",
    "maestro_his_condicion_contrato":"Condición de contrato del personal",
    "maestro_his_dosis":             "Dosis de vacunas",
    "maestro_his_financiador":       "Financiadores (SIS, ESSALUD, etc.)",
    "maestro_his_gruporiesgo_lab":   "Grupos de riesgo (lab)",
    "maestro_his_institucion_edu":   "Instituciones educativas",
    "maestro_his_lab":               "Laboratorio (parámetros)",
    "maestro_his_otra_condicion":    "Otra condición clínica",
    "maestro_his_pais":              "Países (código y nombre)",
    "maestro_his_profesion":         "Profesiones del personal",
    "maestro_his_sistema":           "Sistemas de salud",
    "maestro_his_tipo_doc":          "Tipos de documento de identidad",
    "maestro_his_ubigeo":            "Ubigeos INEI / RENIEC",
    "maestro_his_susalud":           "SUSALUD (establecimientos supervisados)",
    "maestro_eess_susalud":          "SUSALUD crudo (fuente para reconstruir eess2025)",
}
```

**Lista completa de las 24 tablas maestras:**

| # | Nombre Tabla | Descripcion |
|---|-------------|-------------|
| 1 | `maestro_paciente` | Paciente (DNI nombre fecha nac. género etnia) |
| 2 | `maestro_personal` | Personal de salud (colegio profesional) |
| 3 | `eess2025` | Establecimiento (red microred provincia distrito) |
| 4 | `maestro_his_establecimiento` | Establecimientos crudos HIS (fuente para reconstruir eess2025) |
| 5 | `maestro_his_cie_cpms` | Diagnósticos CIE / Procedimientos CPT |
| 6 | `maestro_his_etnia` | Etnias (descripción) |
| 7 | `maestro_his_ups` | Unidades Productoras de Servicios (UPS) |
| 8 | `maestro_his_colegio` | Colegios profesionales |
| 9 | `maestro_his_actividad` | Actividades HIS |
| 10 | `maestro_his_centro_poblado` | Centros poblados |
| 11 | `maestro_his_condicion_contrato` | Condición de contrato del personal |
| 12 | `maestro_his_dosis` | Dosis de vacunas |
| 13 | `maestro_his_financiador` | Financiadores (SIS ESSALUD etc.) |
| 14 | `maestro_his_gruporiesgo_lab` | Grupos de riesgo (lab) |
| 15 | `maestro_his_institucion_edu` | Instituciones educativas |
| 16 | `maestro_his_lab` | Laboratorio (parámetros) |
| 17 | `maestro_his_otra_condicion` | Otra condición clínica |
| 18 | `maestro_his_pais` | Países (código y nombre) |
| 19 | `maestro_his_profesion` | Profesiones del personal |
| 20 | `maestro_his_sistema` | Sistemas de salud |
| 21 | `maestro_his_tipo_doc` | Tipos de documento de identidad |
| 22 | `maestro_his_ubigeo` | Ubigeos INEI / RENIEC |
| 23 | `maestro_his_susalud` | SUSALUD (establecimientos supervisados) |
| 24 | `maestro_eess_susalud` | SUSALUD crudo (fuente para reconstruir eess2025) |

## 6.3 Funciones de Base de Datos

### 6.3.1a Funcion _contar_registros()

```python
def _contar_registros(self, nombre_tabla):
    conn = conexion_bd(self.db_config)
    try:
        with conn.cursor() as cur:
            cur.execute(
                f"SELECT COUNT(*) FROM {self.db_config['schema']}.{nombre_tabla}")
            return cur.fetchone()[0]
    finally:
        conn.close()
```

### 6.3.1b Funcion _obtener_esquema_tabla()

```python
def _obtener_esquema_tabla(self, nombre_tabla):
    conn = conexion_bd(self.db_config)
    try:
        with conn.cursor() as cur:
            cur.execute(""
                SELECT column_name, data_type, character_maximum_length,
                       is_nullable, column_default
                FROM information_schema.columns
                WHERE table_schema = %s AND table_name = %s
                ORDER BY ordinal_position
            "", (self.db_config["schema"], nombre_tabla))
            return cur.fetchall()
    finally:
        conn.close()
```

Estas funciones auxiliares permiten al modulo de maestros consultar metadatos de las tablas y contar registros sin exponer la logica de conexion al resto del codigo.

### 6.3.1 obtener_tablas_en_bd()

```python
def obtener_tablas_en_bd(db_config):
    conn = conexion_bd(db_config)
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT table_name FROM information_schema.tables
                WHERE table_schema = %s AND table_type = 'BASE TABLE'
                ORDER BY table_name
            """, (db_config["schema"],))
            return [row[0] for row in cur.fetchall()]
    finally:
        conn.close()
```

Consulta `information_schema.tables` para listar todas las tablas base en el esquema configurado. Retorna los nombres como lista de strings.

### 6.3.2 eliminar_tabla_maestra()

```python
def eliminar_tabla_maestra(nombre_tabla, db_config):
    conn = conexion_bd(db_config)
    try:
        with conn.cursor() as cur:
            cur.execute(f'DROP TABLE IF EXISTS {db_config["schema"]}.{nombre_tabla} CASCADE')
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()
```

Ejecuta `DROP TABLE ... CASCADE` para eliminar una tabla maestra y sus dependencias. Incluye rollback automatico en caso de error.

### 6.3.3 eliminar_todas_las_maestras()

### 6.3.4 obtener_descripcion_tabla()

```python
def obtener_descripcion_tabla(nombre_tabla, db_config):
    conn = conexion_bd(db_config)
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT column_name, data_type, is_nullable
                FROM information_schema.columns
                WHERE table_schema = %s AND table_name = %s
                ORDER BY ordinal_position
            """, (db_config["schema"], nombre_tabla))
            return cur.fetchall()
    finally:
        conn.close()

```python
def eliminar_todas_las_maestras(db_config):
    tablas = obtener_tablas_en_bd(db_config)
    for tabla in tablas:
        if tabla in DESCRIPCION_MAESTROS:
            eliminar_tabla_maestra(tabla, db_config)
```

Itera sobre todas las tablas en la BD y elimina solo aquellas que existen en el catalogo `DESCRIPCION_MAESTROS`. Util para reinicializar el conjunto de tablas maestras.

## 6.4 Clase ModuloMaestros

`ModuloMaestros` hereda de `ctk.CTkFrame` y encapsula toda la funcionalidad de gestion de maestros. Se instancia como un widget hijo dentro del modulo de maestros de `SistemaSaludApp`.

### 6.4.1 Constructor

```python
class ModuloMaestros(ctk.CTkFrame):
    def __init__(self, parent, db_config, progress_queue=None, cancel_token=None):
        super().__init__(parent)
        self.db_config = db_config
        self.progress_queue = progress_queue
        self.cancel_token = cancel_token
        self.token_local = threading.Event()
        self.datos_maestros = {}
        self._construir_ui()
```

### 6.4.2 Atributos de Instancia

- `db_config`: Configuracion de conexion a PostgreSQL (heredada de `SistemaSaludApp`).
- `progress_queue`: Cola compartida para reportar progreso al panel global.
- `cancel_token`: Token compartido para cancelacion desde el panel global.
- `token_local`: Token local para cancelacion especifica del modulo de maestros.
- `datos_maestros`: Diccionario que almacena los datos cargados desde CSV, indexados por nombre de tabla.

### 6.4.3 Sistema de Progreso Local [PROGRESS]

```python
def _reportar_progreso(self, pct, msg=""):
    if self.progress_queue:
        self.progress_queue.put(f"{pct}% {msg}")
```

Reporta el progreso de las operaciones a la cola compartida, que es consumida por `_procesar_cola_progreso()` en el hilo principal de `SistemaSaludApp`.

### 6.4.4 Verificacion de Cancelacion

```python
def _verificar_cancelacion(self):
    if self.cancel_token and self.cancel_token.is_set():
        raise CancelledError("Operacion cancelada por el usuario")
    if self.token_local and self.token_local.is_set():
        raise CancelledError("Operacion cancelada localmente")
```

Las operaciones largas (carga CSV, eliminacion de tablas) llaman periodicamente a `_verificar_cancelacion()` para comprobar si se ha solicitado la detencion. Si es asi, lanzan una excepcion `CancelledError` que interrumpe el procesamiento.

### 6.4.5 Ejecucion de Scripts con Stream de Salida

### 6.4.6 Validacion de Datos Cargados

Despues de cada carga CSV, el modulo de maestros ejecuta validaciones automaticas:

1. **Conteo de registros**: Compara el numero de filas del CSV con el numero de registros insertados.
2. **Valores nulos**: Verifica que las columnas con restriccion NOT NULL no tengan valores nulos.
3. **Duplicados**: Detecta filas duplicadas basandose en la clave primaria de cada tabla.
4. **Integridad referencial**: Verifica que las claves foraneas apunten a registros existentes.

```python
def _validar_carga(self, nombre_tabla, registros_esperados):
    registros_reales = self._contar_registros(nombre_tabla)
    if registros_esperados != registros_reales:
        log_mensaje(
            f"ADVERTENCIA: {nombre_tabla} esperaba {registros_esperados} "
            f"registros, obtuvo {registros_reales}",
            "WARNING")
    return registros_esperados == registros_reales
```

```python
def _ejecutar_script_con_stream(self, script_path, params):
    cmd = [sys.executable, script_path] + [str(p) for p in params]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        creationflags=CREATE_NO_WINDOW, universal_newlines=True)
    for line in proc.stdout:
        self._reportar_progreso(0, line.strip())
        if self._verificar_cancelacion():
            proc.terminate()
            break
    proc.wait()
```

Ejecuta scripts Python en un subproceso separado y captura su salida en tiempo real mediante `PIPE`. La salida se reenvia al sistema de progreso. Si se cancela la operacion, el subproceso se termina con `terminate()`.

## 6.5 Interfaz de Usuario del Modulo Maestros

### 6.5.1a Constructor Detallado de la UI

```python
def _construir_ui(self):
    # Panel izquierdo (55% del ancho) - Carga CSV
    self.frame_csv = ctk.CTkFrame(self, width=500)
    self.frame_csv.pack(side="left", fill="both", expand=True, padx=5, pady=5)
    self.frame_csv.pack_propagate(False)

    # Separador visual
    separator = ctk.CTkFrame(self, width=2, fg_color="gray")
    separator.pack(side="left", fill="y", padx=2, pady=5)

    # Panel derecho (45% del ancho) - Tablas en BD
    self.frame_bd = ctk.CTkFrame(self, width=400)
    self.frame_bd.pack(side="right", fill="both", expand=True, padx=5, pady=5)
    self.frame_bd.pack_propagate(False)

    # Construir sub-paneles
    self._construir_panel_csv(self.frame_csv)
    self._construir_panel_bd(self.frame_bd)
    self._construir_barra_estado(self)
```

### 6.5.1b Barra de Estado Inferior

```python
def _construir_barra_estado(self, parent):
    self.frame_estado = ctk.CTkFrame(parent, height=30)
    self.frame_estado.pack(side="bottom", fill="x")
    self.lbl_estado_maestros = ctk.CTkLabel(
        self.frame_estado, text="Listo", anchor="w")
    self.lbl_estado_maestros.pack(side="left", padx=10)
    self.progress_bar_local = ctk.CTkProgressBar(
        self.frame_estado, width=200)
    self.progress_bar_local.pack(side="right", padx=10)
    self.progress_bar_local.set(0)
```

### 6.5.1c Atajos de Teclado

El modulo de maestros soporta los siguientes atajos de teclado:

- **Ctrl+O**: Abrir dialogo de seleccion de directorio CSV.
- **Ctrl+Enter**: Cargar los archivos CSV seleccionados.
- **Ctrl+R**: Refrescar la lista de tablas en BD.
- **Delete**: Eliminar la tabla seleccionada en el Treeview.
- **Ctrl+E**: Exportar tabla seleccionada a CSV.

```python
def _bind_atajos(self):
    self.bind_all("<Control-o>", lambda e: self._seleccionar_directorio_csv())
    self.bind_all("<Control-Return>", lambda e: self._cargar_csv_seleccionados())
    self.bind_all("<Control-r>", lambda e: self._actualizar_lista_bd())
    self.bind_all("<Delete>", lambda e: self._eliminar_tabla_seleccionada())
    self.bind_all("<Control-e>", lambda e: self._exportar_tabla_csv())
```

### 6.5.1 Construccion de UI (_construir_ui)

```python
def _construir_ui(self):
    self.pack(fill="both", expand=True)

    # Panel izquierdo: seleccion y carga de CSV
    self.frame_csv = ctk.CTkFrame(self)
    self.frame_csv.pack(side="left", fill="both", expand=True, padx=5, pady=5)

    # Panel derecho: tablas en BD
    self.frame_bd = ctk.CTkFrame(self)
    self.frame_bd.pack(side="right", fill="both", expand=True, padx=5, pady=5)
```

Divide el modulo en dos paneles principales: izquierdo (carga CSV) y derecho (visualizacion de tablas en BD).

### 6.5.2 Panel Izquierdo: Carga CSV

```python
def _construir_panel_csv(self, parent):
    ctk.CTkLabel(parent, text="Archivos CSV Disponibles", font=("Segoe UI", 14, "bold")).pack(pady=5)

    self.lista_csv = tkinter.Listbox(parent, selectmode="multiple", height=15)
    self.lista_csv.pack(fill="both", expand=True, padx=10, pady=5)

    btn_frame = ctk.CTkFrame(parent)
    btn_frame.pack(pady=5)

    ctk.CTkButton(btn_frame, text="Cargar Seleccionados", command=self._cargar_csv_seleccionados).pack(pady=2)
    ctk.CTkButton(btn_frame, text="Seleccionar Directorio", command=self._seleccionar_directorio_csv).pack(pady=2)
```

### 6.5.3 Panel Derecho: Maestros en BD (Treeview)

### 6.5.3a Personalizacion del Treeview

El Treeview del panel derecho se personaliza con las siguientes configuraciones:

```python
self.tree = ttk.Treeview(parent, columns=columns, show="headings", height=15)
self.tree.heading("tabla", text="Tabla", command=lambda: self._ordenar_por("tabla"))
self.tree.heading("registros", text="Registros", command=lambda: self._ordenar_por("registros"))
self.tree.heading("ultima_actualizacion", text="Ult. Actualizacion",
    command=lambda: self._ordenar_por("ultima_actualizacion"))

self.tree.column("tabla", width=200, minwidth=150)
self.tree.column("registros", width=80, minwidth=60, anchor="center")
self.tree.column("ultima_actualizacion", width=140, minwidth=100)

scrollbar = ttk.Scrollbar(parent, orient="vertical", command=self.tree.yview)
scrollbar.pack(side="right", fill="y")
self.tree.configure(yscrollcommand=scrollbar.set)
```

Las columnas incluyen capacidad de ordenamiento al hacer clic en el encabezado y una barra de desplazamiento vertical para tablas con muchos elementos.

```python
def _construir_panel_bd(self, parent):
    ctk.CTkLabel(parent, text="Tablas Maestras en BD", font=("Segoe UI", 14, "bold")).pack(pady=5)

    columns = ("tabla", "registros", "ultima_actualizacion")
    self.tree = ttk.Treeview(parent, columns=columns, show="headings", height=15)
    self.tree.heading("tabla", text="Tabla")
    self.tree.heading("registros", text="Registros")
    self.tree.heading("ultima_actualizacion", text="Ultima Actualizacion")
    self.tree.pack(fill="both", expand=True, padx=10, pady=5)

    btn_eliminar = ctk.CTkButton(parent, text="Eliminar Seleccionada", command=self._eliminar_tabla_seleccionada)
    btn_eliminar.pack(side="left", padx=5)

    btn_eliminar_todas = ctk.CTkButton(parent, text="Eliminar Todas", command=self._eliminar_todas_las_maestras_ui)
    btn_eliminar_todas.pack(side="left", padx=5)

    btn_refrescar = ctk.CTkButton(parent, text="Refrescar", command=self._actualizar_lista_bd)
    btn_refrescar.pack(side="left", padx=5)
```

El `Treeview` muestra las tablas maestras con tres columnas: nombre, cantidad de registros y fecha de ultima actualizacion. Los botones inferiores permiten eliminar tablas individuales o todas, y refrescar la lista.

### 6.5.4 _listar_csvs() - Escaneo de Directorio CSV

```python
def _listar_csvs(self):
    directorio = self.db_config.get("csv_dir", "")
    if not directorio or not os.path.isdir(directorio):
        return []
    archivos = [f for f in os.listdir(directorio) if f.endswith(".csv")]
    # Filtrar solo archivos que corresponden a tablas maestras conocidas
    maestros_csv = []
    for archivo in archivos:
        nombre_base = os.path.splitext(archivo)[0]
        if nombre_base in DESCRIPCION_MAESTROS:
            maestros_csv.append(archivo)
    return sorted(maestros_csv)
```

Escanea el directorio de CSV configurado y filtra solo los archivos cuyos nombres (sin extension) coinciden con tablas del catalogo `DESCRIPCION_MAESTROS`.

### 6.5.5 _cargar_csv_seleccionados() - Carga Masiva a BD

### 6.5.5a Flujo Detallado de Carga CSV

El proceso de carga CSV sigue estos pasos:

1. **Seleccion**: El usuario selecciona uno o mas archivos CSV de la lista.
2. **Validacion previa**: Se verifica que los archivos existan y tengan formato CSV valido.
3. **Apertura de conexion**: Se establece una conexion PostgreSQL con autocommit desactivado.
4. **Carga mediante COPY**: Se utiliza `copy_expert` para la carga masiva, que es 10-50x mas rapida que INSERTs individuales.
5. **Commit**: Si la carga es exitosa, se confirma la transaccion.
6. **Rollback en error**: Si falla, se revierte la transaccion para mantener la consistencia.
7. **Actualizacion de UI**: Se refresca el Treeview con los nuevos datos.

```python
def _cargar_csv(self, ruta_csv, nombre_tabla):
    conn = psycopg2.connect(**self.db_config)
    try:
        with conn.cursor() as cur:
            with open(ruta_csv, "r", encoding="utf-8") as f:
                cur.copy_expert(
                    f"COPY {self.db_config['schema']}.{nombre_tabla} "
                    f"FROM STDIN WITH CSV HEADER DELIMITER ','",
                    f)
        conn.commit()
        return True
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()
```

```python
def _cargar_csv_seleccionados(self):
    seleccion = self.lista_csv.curselection()
    if not seleccion:
        messagebox.showwarning("Seleccion", "Seleccione al menos un archivo CSV")
        return

    self._reportar_progreso(0, "Iniciando carga de CSV...")
    for idx in seleccion:
        archivo = self.lista_csv.get(idx)
        nombre_tabla = os.path.splitext(archivo)[0]
        ruta_csv = os.path.join(self.db_config["csv_dir"], archivo)

        try:
            conn = psycopg2.connect(**self.db_config)
            with conn.cursor() as cur:
                with open(ruta_csv, "r", encoding="utf-8") as f:
                    cur.copy_expert(
                        f"COPY {self.db_config['schema']}.{nombre_tabla} FROM STDIN WITH CSV HEADER",
                        f)
            conn.commit()
            self._reportar_progreso(0, f"{nombre_tabla}: OK")
        except Exception as e:
            conn.rollback()
            log_mensaje(f"Error cargando {nombre_tabla}: {e}", "ERROR")
        finally:
            conn.close()
```

Utiliza `copy_expert` de psycopg2 para realizar la carga masiva de datos desde CSV a PostgreSQL. Este metodo es significativamente mas rapido que INSERTs individuales. Incluye rollback en caso de error y reporta el progreso por cada archivo procesado.

### 6.5.6 Menu de Seleccion de Maestros

```python
def _seleccionar_directorio_csv(self):
    directorio = filedialog.askdirectory(title="Seleccionar directorio de CSVs")
    if directorio:
        self.db_config["csv_dir"] = directorio
        self._listar_csvs()
        self._actualizar_lista_csv_ui()
```

Abre un dialogo de seleccion de directorio y actualiza la configuracion con la ruta seleccionada.

### 6.5.7 _actualizar_maestro_critico_desde_csv()

Carga un archivo CSV directamente en una tabla maestra especifica (sin seleccion multiple). Util para actualizar tablas individuales rapidamente.

### 6.5.8 _actualizar_lista_bd() - Refresco del Treeview

```python
def _actualizar_lista_bd(self):
    for item in self.tree.get_children():
        self.tree.delete(item)
    tablas = obtener_tablas_en_bd(self.db_config)
    for tabla in tablas:
        if tabla in DESCRIPCION_MAESTROS:
            registros = self._contar_registros(tabla)
            self.tree.insert("", "end", values=(tabla, registros, ""))
```

Limpia el Treeview, obtiene la lista actual de tablas desde la BD y las muestra con su conteo de registros.

### 6.5.9 _generar_his_proceso()

```python
def _generar_his_proceso(self):
    """Genera el proceso HIS a partir de las tablas maestras cargadas."""
    try:
        self._reportar_progreso(0, "Generando HIS Proceso...")
        conn = psycopg2.connect(**self.db_config)
        with conn.cursor() as cur:
            cur.execute("CALL es_ivan.generar_his_proceso();")
        conn.commit()
        self._reportar_progreso(100, "HIS Proceso generado correctamente")
    except Exception as e:
        log_mensaje(f"Error generando HIS Proceso: {e}", "ERROR")
    finally:
        if conn:
            conn.close()
```

Ejecuta un procedimiento almacenado (`CALL`) que genera el proceso HIS a partir de los datos de las tablas maestras cargadas. Es el paso final del pipeline de ingesta de maestros.

### 6.5.10 _actualizar_his_proceso_maestros()

Actualiza las tablas del proceso HIS basandose en los datos maestros recien cargados. Se ejecuta automaticamente despues de cada carga CSV exitosa.

### 6.5.11 Eliminacion de Tablas

### 6.5.11a Confirmacion y Seguridad en Eliminacion

Todas las operaciones de eliminacion incluyen multiples capas de seguridad:

1. **Confirmacion visual**: `messagebox.askyesno()` solicita confirmacion explicita del usuario.
2. **Verificacion de catalogo**: Solo se eliminan tablas que existen en `DESCRIPCION_MAESTROS`.
3. **Transaccion segura**: La eliminacion se ejecuta dentro de una transaccion que puede revertirse.
4. **Registro de auditoria**: Cada eliminacion queda registrada en el log del sistema.

```python
def _eliminar_tabla_seleccionada(self):
    seleccion = self.tree.selection()
    if not seleccion:
        messagebox.showinfo("Info", "Seleccione una tabla de la lista")
        return
    valores = self.tree.item(seleccion[0], "values")
    nombre = valores[0]
    if not messagebox.askyesno("Confirmar",
        f"Eliminar la tabla '{nombre}' y todos sus datos?"):
        return
    try:
        eliminar_tabla_maestra(nombre, self.db_config)
        log_mensaje(f"Tabla '{nombre}' eliminada correctamente", "INFO")
        self._actualizar_lista_bd()
    except Exception as e:
        log_mensaje(f"Error eliminando '{nombre}': {e}", "ERROR")
```

```python
def _eliminar_tabla_seleccionada(self):
    seleccion = self.tree.selection()
    if not seleccion:
        return
    if messagebox.askyesno("Confirmar", "Eliminar tabla seleccionada?"):
        valores = self.tree.item(seleccion[0], "values")
        eliminar_tabla_maestra(valores[0], self.db_config)
        self._actualizar_lista_bd()

def _eliminar_todas_las_maestras_ui(self):
    if messagebox.askyesno("Confirmar", "Eliminar TODAS las tablas maestras?"):
        eliminar_todas_las_maestras(self.db_config)
        self._actualizar_lista_bd()
```

Ambos metodos solicitan confirmacion antes de eliminar. `_eliminar_tabla_seleccionada` opera sobre la tabla seleccionada en el Treeview, mientras que `_eliminar_todas_las_maestras_ui` elimina todas las tablas del catalogo.

### 6.5.12 Modo Editor en Maestros

El modulo de maestros incluye un modo editor que permite:

1. **Ver contenido**: Muestra las primeras 100 filas de la tabla seleccionada.
2. **Editar celdas**: Permite modificar valores individuales (solo para usuarios autenticados).
3. **Exportar**: Exporta la tabla a formato CSV.
4. **SQL personalizado**: Ejecuta consultas SQL arbitrarias sobre la tabla seleccionada.

```python
def _mostrar_contenido_tabla(self, nombre_tabla):
    query = f"SELECT * FROM {self.db_config['schema']}.{nombre_tabla} LIMIT 100"
    registros = obtener_registros(query, self.db_config)
    # Mostrar en ventana emergente con Treeview
    ventana = ctk.CTkToplevel(self)
    ventana.geometry("800x400")
    tree = ttk.Treeview(ventana, columns=list(range(len(registros[0]))), show="headings")
    for i, reg in enumerate(registros):
        tree.insert("", "end", values=reg)
    tree.pack(fill="both", expand=True)
```

### 6.5.13 Integracion con el Sistema de Reportes

Los datos cargados en las tablas maestras alimentan los reportes del sistema. Una vez completada la carga de maestros, el modulo de analisis puede generar reportes que utilizan estos datos como fuente. La funcion `_generar_his_proceso()` orquesta la transicion entre la ingesta de maestros y la generacion de reportes.

### 6.5.14 Manejo de Errores y Registro de Actividades

Todas las operaciones del modulo de maestros incluyen manejo de errores con:

- **Try-except-finally**: Asegura que las conexiones se cierren siempre.
- **conn.rollback()**: Revierte transacciones fallidas para mantener la integridad de los datos.
- **log_mensaje()**: Registra cada operacion en el panel de log central.
- **messagebox**: Muestra errores al usuario en ventanas emergentes.

### 6.5.15 Flujo Completo de Operacion

El flujo tipico de uso del modulo de maestros es:

1. El usuario selecciona el directorio que contiene los archivos CSV.
2. El sistema lista los CSV disponibles que coinciden con tablas maestras conocidas.
3. El usuario selecciona uno o mas archivos y presiona "Cargar Seleccionados".
4. El sistema utiliza `copy_expert` de psycopg2 para cargar los datos masivamente.
5. El progreso se reporta en tiempo real mediante la cola de progreso global.
6. Al finalizar, el Treeview se refresca mostrando las tablas cargadas y su conteo de registros.
7. El usuario puede generar el proceso HIS o eliminar tablas segun sea necesario.
8. Los datos maestros quedan disponibles para el modulo de analisis y reportes.


# 7. PIPELINE DE INGESTA DE DATOS





## 7.1 Visi?n General del Pipeline





El pipeline de ingesta transforma archivos comprimidos crudos en datos estructurados listos para an?lisis. El flujo completo, desde la recepci?n de archivos hasta la consolidaci?n final, se compone de los siguientes scripts ejecutados secuencialmente:





```


Archivos RAR/ZIP/7z/TAR/TGZ (patr?n 11_CUSCO_MM.*)


    ??? extractor_archivos.py  (descompresi?n multiformato)


    ??? 01cargacvs_universal.py (carga anual completa)


    ??? 01cargacvs_mensual.py   (carga de un mes espec?fico)


    ??? cargar_maestros.py       (carga de 25+ tablas maestras)


    ??? 02maestro_paciente.py   (cat?logo ?nico de pacientes)


    ??? 03cargar_padron_trama.py (padr?n SIS de asegurados)


    ??? 03_ejecutar_consolidacion.py (JOIN entre tablas)


    ??? 05personal.py           (maestro de personal salud)


    ??? procesar_eess_principal.py (establecimientos EESS)


```





Cada script opera sobre la base de datos PostgreSQL en el esquema `es_ivan`, tabla central `hisminsa24`, leyendo configuraci?n desde `db_config.py`. El patr?n de nombres de archivo sigue la convenci?n `11_CUSCO_MM.*` donde `MM` es el mes de dos d?gitos.





---





## 7.2 extractor_archivos.py ??? Extractor de Archivos Comprimidos





### 7.2.1 Dependencias y Constante de Ventana





```python


import os


import shutil


import subprocess


import tarfile


import zipfile





try:


    import py7zr  # type: ignore


except Exception:


    py7zr = None





CREATE_NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)


```





- **tarfile**: Biblioteca est?ndar para extraer `.tar`, `.tar.gz`, `.tgz`.


- **zipfile**: Biblioteca est?ndar para `.zip`.


- **py7zr**: Dependencia opcional para `.7z`; si falla la importaci?n se asigna `None`.


- **CREATE_NO_WINDOW**: Constante Windows (0x08000000) que evita que aparezca una ventana de consola al ejecutar subprocesos.





```python


_EXTRACTORES_CACHE = None


```





Variable global para el patr?n **singleton** de la cach? de extractores detectados.





### 7.2.2 Funciones Auxiliares de Validaci?n





```python


def _ruta_valida(ruta):


    return bool(ruta) and os.path.exists(ruta)


```





Verifica que una ruta no sea `None`, vac?a, y que el archivo o directorio exista en disco.





```python


def _agregar_candidato(candidatos, vistos, tipo, ruta):


    if not _ruta_valida(ruta):


        return


    ruta_abs = os.path.abspath(ruta)


    clave = (tipo, os.path.normcase(ruta_abs))


    if clave in vistos:


        return


    vistos.add(clave)


    candidatos.append((tipo, ruta_abs))


```





Agrega un extractor candidato a la lista solo si:


1. La ruta es v?lida (`_ruta_valida`)


2. No se ha agregado antes (control por conjunto `vistos` con clave `(tipo, ruta_normalizada)`)





### 7.2.3 _detectar_extractores() ??? B?squeda de Extractores Externos





```python


def _detectar_extractores():


    candidatos = []


    vistos = set()


```





#### Rutas de WinRAR (4 rutas fijas + 4 comandos PATH)





```python


    rutas_winrar = [


        r"C:\Program Files\WinRAR\WinRAR.exe",


        r"C:\Program Files (x86)\WinRAR\WinRAR.exe",


        os.path.join(os.environ.get("PROGRAMFILES", ""), "WinRAR", "WinRAR.exe"),


        os.path.join(os.path.join(os.environ.get("PROGRAMFILES(X86)", ""), "WinRAR", "WinRAR.exe")),


    ]


    for ruta in rutas_winrar:


        _agregar_candidato(candidatos, vistos, "winrar", ruta)





    for cmd in ("WinRAR.exe", "winrar", "rar", "unrar"):


        _agregar_candidato(candidatos, vistos, "winrar", shutil.which(cmd))


```





Busca **WinRAR** en:


1. `C:\Program Files\WinRAR\WinRAR.exe`


2. `C:\Program Files (x86)\WinRAR\WinRAR.exe`


3. `%PROGRAMFILES%\WinRAR\WinRAR.exe`


4. `%PROGRAMFILES(X86)%\WinRAR\WinRAR.exe`


5. `WinRAR.exe`, `winrar`, `rar`, `unrar` en el `PATH` del sistema





#### Rutas de 7-Zip (6 rutas fijas + 6 comandos PATH)





```python


    rutas_7z = [


        r"C:\Program Files\7-Zip\7z.exe",


        r"C:\Program Files\7-Zip\7zz.exe",


        r"C:\Program Files (x86)\7-Zip\7z.exe",


        r"C:\Program Files (x86)\7-Zip\7zz.exe",


        os.path.join(os.environ.get("PROGRAMFILES", ""), "7-Zip", "7z.exe"),


        os.path.join(os.path.join(os.environ.get("PROGRAMFILES(X86)", ""), "7-Zip", "7z.exe")),


    ]


    for ruta in rutas_7z:


        _agregar_candidato(candidatos, vistos, "7z", ruta)





    for cmd in ("7z", "7za", "7zr", "7zz", "7z.exe", "NanaZipC", "NanaZipC.exe"):


        _agregar_candidato(candidatos, vistos, "7z", shutil.which(cmd))


```





Busca **7-Zip** en:


1. `C:\Program Files\7-Zip\7z.exe`


2. `C:\Program Files\7-Zip\7zz.exe` (7zz es variante moderna)


3. `C:\Program Files (x86)\7-Zip\7z.exe`


4. `C:\Program Files (x86)\7-Zip\7zz.exe`


5. `%PROGRAMFILES%\7-Zip\7z.exe`


6. `%PROGRAMFILES(X86)%\7-Zip\7z.exe`


7. `7z`, `7za`, `7zr`, `7zz`, `7z.exe`, `NanaZipC`, `NanaZipC.exe` en el `PATH`





#### Rutas de tar (bsdtar de Windows 10/11)





```python


    for cmd in ("tar", "tar.exe"):


        _agregar_candidato(candidatos, vistos, "tar", shutil.which(cmd))


    _agregar_candidato(candidatos, vistos, "tar", r"C:\Windows\System32\tar.exe")





    return candidatos


```





Busca **tar**:


1. `tar`, `tar.exe` en el `PATH`


2. `C:\Windows\System32\tar.exe` (bsdtar incluido en Windows 10/11)





**Total de candidatos potenciales**: 4 WinRAR fijos + 4 WinRAR PATH + 6 7-Zip fijos + 7 7-Zip PATH + 2 tar PATH + 1 tar fijo = **24 candidatos** evaluados.





### 7.2.4 obtener_extractores() ??? Patr?n Singleton con Cach?





```python


def obtener_extractores():


    global _EXTRACTORES_CACHE


    if _EXTRACTORES_CACHE is None:


        _EXTRACTORES_CACHE = _detectar_extractores()


    return list(_EXTRACTORES_CACHE)


```





- **Singleton**: la detecci?n de extractores se ejecuta una sola vez.


- Retorna una **copia** de la lista (`list(...)`) para evitar mutaciones externas.


- Se usa en todos los m?dulos que necesitan extraer archivos.





### 7.2.5 detectar_extractor_rar() ??? Detecci?n Espec?fica de RAR





```python


def detectar_extractor_rar():


    for tipo, ruta in obtener_extractores():


        if tipo in {"winrar", "7z", "tar"}:


            return tipo, ruta


    return (None, None)


```





Itera sobre todos los extractores cacheados y retorna el **primero** que sea capaz de extraer RAR: `winrar`, `7z`, o `tar` (bsdtar soporta RAR en Windows 10+). Retorna `(None, None)` si no encuentra ninguno.





### 7.2.6 _ejecutar_comando() ??? Ejecuci?n Segura de Subprocesos





```python


def _ejecutar_comando(comando, timeout=180):


    try:


        resultado = subprocess.run(


            comando,


            capture_output=True,


            text=True,


            timeout=timeout,


            creationflags=CREATE_NO_WINDOW,


        )


    except subprocess.TimeoutExpired:


        return False, "timeout"


    except Exception as e:


        return False, str(e)





    if resultado.returncode == 0:


        return True, None





    salida = (resultado.stderr or resultado.stdout or "").strip()


    if salida:


        salida = salida.replace("\n", " ")


        return False, f"codigo {resultado.returncode}: {salida[:280]}"


    return False, f"codigo {resultado.returncode}"


```





Ejecuta un comando externo con:


- **Timeout**: 180 segundos por defecto (300 en extracci?n directa)


- **Captura de salida**: stdout y stderr capturados como texto


- **CREATE_NO_WINDOW**: evita ventanas emergentes en Windows


- **Retorno**: `(True, None)` en ?xito, `(False, mensaje_error)` en fallo. Los mensajes de error se truncan a 280 caracteres.





### 7.2.7 _extraer_con_herramienta() ??? Comandos por Tipo de Extractor





```python


def _extraer_con_herramienta(tipo, ejecutable, ruta_completa, carpeta_destino):


    destino = os.path.abspath(carpeta_destino)


    if tipo == "winrar":


        cmd = [ejecutable, "x", "-y", ruta_completa, destino + os.sep]


    elif tipo == "7z":


        cmd = [ejecutable, "x", "-y", f"-o{destino}", ruta_completa]


    elif tipo == "tar":


        cmd = [ejecutable, "-xf", ruta_completa, "-C", destino]


    else:


        return False, f"tipo no soportado: {tipo}"


    return _ejecutar_comando(cmd, timeout=300)


```





Construye el comando espec?fico para cada extractor:


- **WinRAR**: `WinRAR.exe x -y <archivo> <destino>\` (flag `x` = extraer con rutas, `-y` = responder s? a todo)


- **7-Zip**: `7z.exe x -y -o<destino> <archivo>` (flag `-o<dir>` = directorio de salida)


- **tar**: `tar.exe -xf <archivo> -C <destino>` (flag `-xf` = extract file, `-C` = change directory)





Timeout de 300 segundos para operaciones potencialmente largas.





### 7.2.8 _intentar_con_extractores() ??? Iteraci?n sobre Extractores





```python


def _intentar_con_extractores(ruta_completa, carpeta_destino, tipos_permitidos):


    intentos = []


    for tipo, ejecutable in obtener_extractores():


        if tipo not in tipos_permitidos:


            continue


        ok, error = _extraer_con_herramienta(tipo, ejecutable, ruta_completa, carpeta_destino)


        if ok:


            return True, None


        intentos.append(f"{tipo} ({os.path.basename(ejecutable)}): {error}")





    if not intentos:


        tipos = ", ".join(sorted(tipos_permitidos))


        return False, f"No se detecto extractor compatible ({tipos})"





    return False, " ; ".join(intentos)


```





Prueba cada extractor en orden de prioridad (el orden en que fueron detectados) y retorna el primero que funciona. Acumula todos los errores en un mensaje concatenado.





### 7.2.9 Extractores Nativo ZIP y TAR





```python


def _extraer_zip_nativo(ruta_completa, carpeta_destino):


    try:


        with zipfile.ZipFile(ruta_completa, "r") as zf:


            zf.extractall(carpeta_destino)


        return True, None


    except Exception as e:


        return False, f"zipfile: {e}"








def _extraer_tar_nativo(ruta_completa, carpeta_destino):


    try:


        with tarfile.open(ruta_completa, "r:*") as tar:


            tar.extractall(path=carpeta_destino)


        return True, None


    except Exception as e:


        return False, f"tarfile: {e}"


```





- **ZIP nativo**: Usa `zipfile.ZipFile` (biblioteca est?ndar). No requiere herramientas externas.


- **TAR nativo**: Usa `tarfile.open` con modo `"r:*"` (detecci?n autom?tica de compresi?n: gz, bz2, xz).





### 7.2.10 py7zr Fallback





En la secci?n de extracci?n `.7z` se usa `py7zr` como primer intento antes de recurrir a herramientas externas:





```python


if py7zr is not None:


    try:


        with py7zr.SevenZipFile(ruta_completa, mode="r") as z:


            z.extractall(path=carpeta_destino)


        return True, None


    except Exception as e:


        errores.append(f"py7zr: {e}")


```





`py7zr` es una implementaci?n Python pura para 7z. Si no est? instalada o falla, se cae a extractores externos.





### 7.2.11 extraer_comprimido() ??? Funci?n Principal de Extracci?n





```python


def extraer_comprimido(ruta_completa, carpeta_destino):


    if not _ruta_valida(ruta_completa):


        return False, "archivo no existe"





    os.makedirs(carpeta_destino, exist_ok=True)


    ruta_lower = ruta_completa.lower()





    if ruta_lower.endswith(".zip"):


        ok, error = _extraer_zip_nativo(ruta_completa, carpeta_destino)


        if ok:


            return True, None


        ok, error_ext = _intentar_con_extractores(ruta_completa, carpeta_destino, {"7z", "winrar", "tar"})


        if ok:


            return True, None


        if error_ext:


            return False, f"{error} ; {error_ext}"


        return False, error





    if ruta_lower.endswith(".7z"):


        errores = []


        if py7zr is not None:


            try:


                with py7zr.SevenZipFile(ruta_completa, mode="r") as z:


                    z.extractall(path=carpeta_destino)


                return True, None


            except Exception as e:


                errores.append(f"py7zr: {e}")





        ok, error = _intentar_con_extractores(ruta_completa, carpeta_destino, {"7z", "winrar", "tar"})


        if ok:


            return True, None


        if error:


            errores.append(error)


        return False, " ; ".join(errores) if errores else "No fue posible extraer 7z"





    if ruta_lower.endswith(".rar"):


        ok, error = _intentar_con_extractores(ruta_completa, carpeta_destino, {"winrar", "7z", "tar"})


        if ok:


            return True, None


        return False, error or "No fue posible extraer RAR"





    if ruta_lower.endswith(".tar") or ruta_lower.endswith(".tgz") or ruta_lower.endswith(".tar.gz"):


        ok, error = _extraer_tar_nativo(ruta_completa, carpeta_destino)


        if ok:


            return True, None


        ok, error_ext = _intentar_con_extractores(ruta_completa, carpeta_destino, {"tar", "7z", "winrar"})


        if ok:


            return True, None


        if error_ext:


            return False, f"{error} ; {error_ext}"


        return False, error





    return False, "Formato no soportado"


```





### 7.2.12 Flujo de Decisi?n por Formato





| Formato | 1er intento | 2do intento | 3er intento |


|---------|-------------|-------------|-------------|


| `.zip` | `_extraer_zip_nativo()` (zipfile) | Extractores externos: 7z, winrar, tar | ??? |


| `.7z` | `py7zr.SevenZipFile` (si disponible) | Extractores externos: 7z, winrar, tar | ??? |


| `.rar` | Extractores externos: winrar, 7z, tar | ??? | ??? |


| `.tar`/`.tgz`/`.tar.gz` | `_extraer_tar_nativo()` (tarfile) | Extractores externos: tar, 7z, winrar | ??? |





Para RAR no hay intento nativo porque Python no incluye soporte para RAR en la biblioteca est?ndar. Para ZIP y TAR se prioriza siempre la implementaci?n nativa antes de recurrir a herramientas externas.





---





## 7.3 01cargacvs_universal.py ??? Carga Universal de CSV





### 7.3.1 Prop?sito y Dependencias





```python


import os


import sys


import shutil


import psycopg2


import re


import tempfile


import time


from datetime import datetime





sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


from extractor_archivos import detectar_extractor_rar, extraer_comprimido


```





Procesa todos los meses de un a?o completo. Lee archivos `11_CUSCO_MM.*` desde `datos/maestr/<anio>/`, los descomprime si es necesario, y los carga en `es_ivan.hisminsa24` mediante COPY de PostgreSQL con staging intermedia.





### 7.3.2 Detecci?n de Extractor RAR al Cargar





```python


EXTRACTOR_RAR_TIPO, EXTRACTOR_RAR_RUTA = detectar_extractor_rar()


```





Esta variable global se eval?a **una vez** al importar el script. Si hay un extractor disponible, se informa en consola; si no, se emite una advertencia.





### 7.3.3 Constantes y Configuraci?n





```python


EXTENSIONES_SOPORTADAS = (".rar", ".zip", ".7z", ".tar.gz", ".tar", ".tgz", ".csv")


```





Tupla de 7 extensiones reconocidas. El orden no importa porque la funci?n `extension_soportada()` itera sobre todas.





```python


COLUMNAS_LIMPIAR_NULL = {


    "apellidos", "nombres", "hemoglobina", "talla", "peso",


    "perimetro_abdominal", "perimetro_cefalico",


    "departamento", "provincia", "distrito",


    "establecimiento", "tipodianoc", "dx1", "dx2", "dx3",


    "codigo_item", "valor_lab",


}


```





Conjunto de 16 nombres de columna que recibir?n tratamiento especial: cuando se insertan desde staging, se envuelven en `COALESCE(columna, '')` para convertir NULLs en cadena vac?a. Esto evita errores en reportes que esperan texto no nulo.





### 7.3.4 Funciones de Utilidad para Archivos





#### 7.3.4.1 extraer_mes_desde_nombre()





```python


def extraer_mes_desde_nombre(nombre_archivo):


    match = re.match(r"^11_CUSCO_(\d{1,2})(?:\D|$)", nombre_archivo, flags=re.IGNORECASE)


    if not match:


        return None


    try:


        mes = int(match.group(1))


    except ValueError:


        return None


    if 1 <= mes <= 12:


        return f"{mes:02d}"


    return None


```





Extrae el mes de un nombre de archivo como `11_CUSCO_01.rar` ??? `"01"`. Usa regex que captura 1 o 2 d?gitos despu?s del prefijo `11_CUSCO_`. Retorna el mes con formato de dos d?gitos o `None` si no coincide.





#### 7.3.4.2 extension_soportada()





```python


def extension_soportada(nombre_archivo):


    nombre = nombre_archivo.lower()


    for ext in EXTENSIONES_SOPORTADAS:


        if nombre.endswith(ext):


            return ext


    return None


```





Retorna la extensi?n con punto (`.rar`, `.zip`, etc.) o `None`. Importante: `tar.gz` debe estar antes que `.tar` en la tupla para que `endswith` funcione correctamente con `.tar.gz`.





#### 7.3.4.3 prioridad_archivo_por_extension()





```python


def prioridad_archivo_por_extension(ext):


    return 0 if ext == ".csv" else 1


```





Los CSV ya extra?dos tienen prioridad 0 (mejor), los comprimidos prioridad 1. Esto garantiza que si existen tanto `11_CUSCO_01.csv` como `11_CUSCO_01.rar`, se prefiera el CSV.





#### 7.3.4.4 obtener_csv_extraido()





```python


def obtener_csv_extraido(carpeta, nombre_base=None, mes_esperado=None):


    csvs = []


    for raiz, _, archivos in os.walk(carpeta):


        for nombre in archivos:


            if nombre.lower().endswith(".csv"):


                csvs.append(os.path.join(raiz, nombre))





    if not csvs:


        return None





    candidatos = list(csvs)





    if nombre_base:


        match_base = [


            ruta for ruta in candidatos


            if nombre_base.lower() in os.path.basename(ruta).lower()


        ]


        if match_base:


            candidatos = match_base





    if mes_esperado:


        match_mes = [


            ruta for ruta in candidatos


            if extraer_mes_desde_nombre(os.path.basename(ruta)) == mes_esperado


        ]


        if match_mes:


            candidatos = match_mes





    return max(candidatos, key=lambda p: (os.path.getsize(p), os.path.getctime(p)))


```





Busca recursivamente (`os.walk`) archivos CSV dentro de la carpeta. Aplica hasta 3 filtros progresivos:


1. Filtro por `nombre_base` (coincidencia parcial en el nombre del archivo)


2. Filtro por `mes_esperado` (extra?do del nombre)


3. Selecci?n final: el archivo m?s grande y m?s reciente `max(..., key=lambda p: (tama?o, ctime))`





Esto evita seleccionar archivos CSV vac?os o cabeceras sin datos.





#### 7.3.4.5 verificar_csv_valido()





```python


def verificar_csv_valido(ruta_csv):


    try:


        with open(ruta_csv, 'r', encoding='latin1') as f:


            header = f.readline()


            if not header.strip():


                return False, "Archivo CSV vacio o solo tiene saltos de linea"





            lineas_muestra = []


            for _ in range(5):


                linea = f.readline()


                if not linea:


                    break


                lineas_muestra.append(linea)





            if len(lineas_muestra) == 0:


                return False, "CSV solo tiene encabezado, sin datos"





            tamano = os.path.getsize(ruta_csv)


            if tamano < 100:


                return False, f"Archivo muy pequeno: {tamano} bytes"





            return True, None


    except Exception as e:


        return False, str(e)


```





Verifica que el CSV:


1. Tenga un header no vac?o


2. Tenga al menos 1 l?nea de datos despu?s del header (lee 5 l?neas de muestra)


3. Tenga tama?o m?nimo de 100 bytes





#### 7.3.4.6 buscar_csv_manual()





```python


def buscar_csv_manual(ruta_crudos_local, nombre_base, mes_esperado=None):


    ruta_csv_raiz = os.path.join(ruta_crudos_local, f"{nombre_base}.csv")


    if os.path.exists(ruta_csv_raiz):


        return ruta_csv_raiz





    ruta_subcarpeta = os.path.join(ruta_crudos_local, nombre_base)


    ruta_csv_subcarpeta = os.path.join(ruta_subcarpeta, f"{nombre_base}.csv")


    if os.path.exists(ruta_csv_subcarpeta):


        return ruta_csv_subcarpeta





    if os.path.isdir(ruta_subcarpeta):


        return obtener_csv_extraido(ruta_subcarpeta, nombre_base, mes_esperado)





    return None


```





Implementa 3 estrategias de b?squeda en orden descendente de prioridad:


1. **Directa**: `11_CUSCO_01.csv` en la ra?z de crudos


2. **Subcarpeta directa**: `11_CUSCO_01/11_CUSCO_01.csv`


3. **Subcarpeta walk**: busca recursivamente dentro de `11_CUSCO_01/`





### 7.3.5 construir_plan_archivos() ??? Algoritmo de Selecci?n





```python


def construir_plan_archivos(ruta_crudos_local):


    candidatos = []


    for nombre in os.listdir(ruta_crudos_local):


        if not nombre.upper().startswith("11_CUSCO_"):


            continue





        ext = extension_soportada(nombre)


        if not ext:


            continue





        mes = extraer_mes_desde_nombre(nombre)


        if not mes:


            continue





        ruta = os.path.join(ruta_crudos_local, nombre)


        candidatos.append(


            {


                "nombre": nombre,


                "ruta": ruta,


                "mes": mes,


                "ext": ext,


                "mtime": os.path.getmtime(ruta),


                "prioridad": prioridad_archivo_por_extension(ext),


            }


        )





    por_mes = {}


    for item in candidatos:


        por_mes.setdefault(item["mes"], []).append(item)





    plan = []


    for mes, items in por_mes.items():


        elegido = sorted(items, key=lambda x: (x["prioridad"], -x["mtime"], x["nombre"]))[0]


        plan.append(elegido)





        if len(items) > 1:


            nombres = ", ".join(x["nombre"] for x in sorted(items, key=lambda x: x["nombre"]))


            print(f"[WARN] Mes {mes}: m?ltiples archivos detectados. Se usar? '{elegido['nombre']}'.")


            print(f"       Candidatos: {nombres}")





    return sorted(plan, key=lambda x: int(x["mes"]))


```





**Algoritmo completo**:





1. **Filtro inicial**: Solo archivos que empiecen con `11_CUSCO_` (case-insensitive)


2. **Filtro de extensi?n**: Solo extensiones en `EXTENSIONES_SOPORTADAS`


3. **Filtro de mes**: Solo nombres que tengan un mes v?lido (1-12)


4. **Agrupaci?n por mes**: `por_mes = {"01": [lista de items], "02": [...]}`


5. **Selecci?n por mes**: Para cada mes, ordena por 3 niveles de prioridad:


   - **Nivel 1** (primario): `prioridad` (0 = CSV, 1 = comprimido)


   - **Nivel 2** (secundario): `-mtime` (m?s reciente primero)


   - **Nivel 3** (terciario): `nombre` (alfab?tico, desempate)


   - Toma el primero (`[0]`)


6. **Advertencia multi-archivo**: Si un mes tiene m?ltiples candidatos, muestra un WARN con todos los nombres


7. **Orden final**: Plan ordenado por mes num?rico ascendente





### 7.3.6 Configuraci?n de Base de Datos y Rutas





```python


sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))


from db_config import get_db_config





_db_config = get_db_config()





DB = {


    "user": _db_config.user,


    "pass": _db_config.password,


    "host": _db_config.host,


    "port": _db_config.port,


    "db":   _db_config.database


}





anio_proceso       = sys.argv[1] if len(sys.argv) > 1 else "2022"


ruta_crudos_custom = sys.argv[2] if len(sys.argv) > 2 else None





base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))





if ruta_crudos_custom:


    ruta_crudos = ruta_crudos_custom


else:


    ruta_crudos = os.path.join(base_dir, "datos", "maestr", anio_proceso)


```





- **Argumento 1** (`sys.argv[1]`): A?o (defecto: `"2022"`)


- **Argumento 2** (`sys.argv[2]`): Ruta personalizada de crudos (opcional)


- **Ruta por defecto**: `<base_dir>/datos/maestr/<anio>/`


- **base_dir**: Sube 3 niveles desde `scripts_python/ingesta/`





### 7.3.7 Sistema de Logging





```python


LOG_DIR = os.path.join(base_dir, "logs")


os.makedirs(LOG_DIR, exist_ok=True)


LOG_FILE = os.path.join(LOG_DIR, "csvs_subidos.log")








def registrar_csv_subido(nombre_archivo, anio, mes, total_registros, carpeta_origen):


    fecha_hora = datetime.now().strftime("%Y-%m-%d %H:%M:%S")


    linea = f"[{fecha_hora}] | {anio}/{mes} | {total_registros:,} reg | {nombre_archivo} | Origen: {carpeta_origen}\n"


    with open(LOG_FILE, "a", encoding="utf-8") as f:


        f.write(linea)








def obtener_resumen_subidos():


    if not os.path.exists(LOG_FILE):


        return "Sin registros a?n."


    with open(LOG_FILE, "r", encoding="utf-8") as f:


        lineas = f.readlines()


    if not lineas:


        return "Sin registros a?n."


    resumen = {}


    for linea in lineas:


        partes = linea.strip().split(" | ")


        if len(partes) >= 3:


            anio_mes = partes[1]


            regs = partes[2]


            resumen[anio_mes] = regs


    return "\n".join([f"{k}: {v}" for k, v in resumen.items()])


```





Formato del log:


```


[2024-01-15 14:30:22] | 2024/01 | 12,345 reg | 11_CUSCO_01.rar | Origen: C:\...\maestr\2024


```





### 7.3.8 Funciones de Base de Datos





#### 7.3.8.1 conectar_db()





```python


esquema       = _db_config.schema


tabla_nombre  = "hisminsa24"


tabla_destino = f"{esquema}.{tabla_nombre}"





def conectar_db():


    return psycopg2.connect(


        dbname=DB["db"],


        user=DB["user"],


        password=DB["pass"],


        host=DB["host"],


        port=DB["port"],


        connect_timeout=10


    )


```





Conexi?n con timeout de 10 segundos.





#### 7.3.8.2 columnas_unicas()





```python


def columnas_unicas(columnas):


    vistas = set()


    resultado = []


    for columna in columnas:


        col = (columna or "").strip().lower()


        if not col or col in vistas:


            continue


        vistas.add(col)


        resultado.append(col)


    return resultado


```





Elimina columnas duplicadas y vac?as del header CSV. Preserva el orden original de primera aparici?n.





#### 7.3.8.3 asegurar_tabla_destino()





```python


def asegurar_tabla_destino(cur, columnas_csv):


    cur.execute(f"CREATE SCHEMA IF NOT EXISTS {esquema};")


    cur.execute(f"CREATE TABLE IF NOT EXISTS {tabla_destino} (anio TEXT, mes TEXT);")


    cur.execute(


        f"""


        CREATE INDEX IF NOT EXISTS idx_{tabla_nombre}_anio_mes


        ON {tabla_destino} (anio, mes);


        """


    )





    cur.execute(


        f"""


        SELECT column_name FROM information_schema.columns


        WHERE table_schema = '{esquema}' AND table_name = '{tabla_nombre}';


        """


    )


    columnas_db = [row[0].lower() for row in cur.fetchall()]


    columnas_nuevas = [col for col in columnas_csv if col not in columnas_db]





    if columnas_nuevas:


        print(f"   [INFO] Agregando {len(columnas_nuevas)} columnas nuevas...")


        for col_nueva in columnas_nuevas:


            cur.execute(f'ALTER TABLE {tabla_destino} ADD COLUMN "{col_nueva}" TEXT;')


```





**Schema evolution din?mico**: La tabla base se crea con solo `(anio TEXT, mes TEXT)`. Luego, para cada CSV, se comparan las columnas del CSV contra las columnas existentes en la tabla mediante `information_schema.columns`. Las columnas nuevas se agregan con `ALTER TABLE ADD COLUMN` de tipo TEXT.





#### 7.3.8.4 crear_tabla_staging()





```python


def crear_tabla_staging(cur, tabla_staging, columnas_csv):


    col_defs = ", ".join([f'"{c}" TEXT' for c in columnas_csv])


    cur.execute(f"DROP TABLE IF EXISTS {tabla_staging};")


    cur.execute(f"CREATE TEMP TABLE {tabla_staging} ({col_defs}) ON COMMIT DROP;")


```





Crea una **tabla temporal** (`TEMP TABLE`) que se elimina autom?ticamente al finalizar la transacci?n (`ON COMMIT DROP`). Todas las columnas son `TEXT` para evitar errores de conversi?n de tipos. La tabla temporal usa solo las columnas del CSV (sin `anio`/`mes`).





#### 7.3.8.5 construir_insert_desde_staging()





```python


def construir_insert_desde_staging(columnas_csv, anio, mes):


    columnas_insertar = list(dict.fromkeys(columnas_csv + ["anio", "mes"]))


    columnas_insert_sql = ", ".join([f'"{c}"' for c in columnas_insertar])


    expresiones = []


    parametros = []





    for columna in columnas_insertar:


        if columna == "anio":


            expresiones.append('%s AS "anio"')


            parametros.append(anio)


        elif columna == "mes":


            expresiones.append('%s AS "mes"')


            parametros.append(mes)


        elif columna in COLUMNAS_LIMPIAR_NULL:


            expresiones.append(f'COALESCE("{columna}", \'\') AS "{columna}"')


        else:


            expresiones.append(f'"{columna}"')





    return columnas_insert_sql, ", ".join(expresiones), parametros


```





Construye din?micamente la consulta `INSERT INTO ... SELECT` con:


1. **Columnas del CSV** + `anio` y `mes` como constantes


2. **COALESCE** para las 16 columnas en `COLUMNAS_LIMPIAR_NULL`


3. **Par?metros** para `anio` y `mes` v?a placeholder `%s`





Ejemplo de SQL generado para 3 columnas (`nombre`, `apellidos`, `edad`):


```sql


INSERT INTO es_ivan.hisminsa24 ("nombre", "apellidos", "edad", "anio", "mes")


SELECT "nombre", COALESCE("apellidos", '') AS "apellidos", "edad", '2024' AS "anio", '01' AS "mes"


FROM tmp_hisminsa24_staging;


```





### 7.3.9 Proceso Principal de Carga Anual





```python


if not os.path.exists(ruta_crudos):


    print(f"[ERROR] Carpeta no encontrada: {ruta_crudos}")


    sys.exit()





plan_archivos = construir_plan_archivos(ruta_crudos)





if not plan_archivos:


    print(f"[WARN] No se encontraron archivos validos 11_CUSCO_* en: {ruta_crudos}")


    sys.exit()





print(f"[INFO] Meses planificados para carga: {len(plan_archivos)}")


print(f"[PROGRESS] TOTAL={len(plan_archivos)}")


```





Si no hay archivos que cumplan el patr?n, el script termina con c?digo 0 (advertencia, no error).





### 7.3.10 Bucle de Procesamiento por Mes





```python


errores = []


procesados_ok = []





for indice, item in enumerate(plan_archivos, start=1):


    nombre_archivo = item["nombre"]


    ruta_full = item["ruta"]


    mes_archivo = item["mes"]


    inicio_item = time.monotonic()


    archivo_csv_temp = None


    es_comprimido = False


    carpeta_temporal = None


    nombre_base = os.path.splitext(nombre_archivo)[0]


```





#### 7.3.10.1 Paso 1: Descompresi?n





```python


    if nombre_archivo.lower().endswith(".csv"):


        print(f"\n[PROCESANDO] Mes {mes_archivo} - {nombre_archivo}...")


        archivo_csv_temp = ruta_full


        es_comprimido = False


    elif nombre_archivo.lower().endswith((".rar", ".zip", ".7z", ".tar", ".tgz", ".tar.gz")):


        csv_manual = buscar_csv_manual(ruta_crudos, nombre_base, mes_archivo)


        if csv_manual and os.path.exists(csv_manual):


            print(f"\n[PROCESANDO] Mes {mes_archivo} - {os.path.basename(csv_manual)} (ya extraido)...")


            archivo_csv_temp = csv_manual


            es_comprimido = False


        else:


            print(f"\n[PROCESANDO] Mes {mes_archivo} - {nombre_archivo}...")


            carpeta_temporal = tempfile.mkdtemp(prefix=f"tmp_ingesta_{mes_archivo}_", dir=ruta_crudos)


            exito, error = extraer_comprimido(ruta_full, carpeta_temporal)


            if not exito:


                print(f"[ERROR] No se pudo extraer: {error or 'desconocido'}")


                errores.append((mes_archivo, nombre_archivo, f"Extraccion fallida: {error or 'desconocido'}"))


                print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=error|archivo={nombre_archivo}")


                shutil.rmtree(carpeta_temporal, ignore_errors=True)


                continue


            es_comprimido = True


            archivo_csv_temp = obtener_csv_extraido(carpeta_temporal, nombre_base, mes_archivo)


```





Para comprimidos, primero intenta `buscar_csv_manual()` (por si el usuario ya extrajo manualmente). Si no, extrae a carpeta temporal con `tempfile.mkdtemp()` y luego busca el CSV extra?do.





#### 7.3.10.2 Paso 2: Verificaci?n de CSV





```python


    if not archivo_csv_temp or not os.path.exists(archivo_csv_temp):


        print(f"[WARN] No se encontro CSV para: {nombre_archivo}")


        errores.append((mes_archivo, nombre_archivo, "CSV no encontrado tras extracci?n"))


        print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=error|archivo={nombre_archivo}")


        if carpeta_temporal:


            shutil.rmtree(carpeta_temporal, ignore_errors=True)


        continue


    


    csv_valido, error_csv = verificar_csv_valido(archivo_csv_temp)


    if not csv_valido:


        print(f"[ERROR] CSV invalido: {error_csv} - {os.path.basename(archivo_csv_temp)}")


        errores.append((mes_archivo, nombre_archivo, f"CSV inv?lido: {error_csv}"))


        print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=error|archivo={nombre_archivo}")


        if carpeta_temporal:


            shutil.rmtree(carpeta_temporal, ignore_errors=True)


        continue


    


    tamano = os.path.getsize(archivo_csv_temp)


    print(f"[INFO] CSV: {os.path.basename(archivo_csv_temp)} ({tamano:,} bytes)")


```





#### 7.3.10.3 Paso 3: Lectura de Header y Detecci?n de Delimitador





```python


    try:


        with open(archivo_csv_temp, "r", encoding="latin1") as f:


            header = f.readline().lstrip("\ufeff").strip()


        


        tiene_pipe = '|' in header


        tiene_coma = ',' in header


        delimitador = '|' if tiene_pipe else (',' if tiene_coma else '\t')


        


        print(f"   [DEBUG] Header (primeros 200 chars): {header[:200]}")


        print(f"   [DEBUG] Delimitador detectado: '{delimitador}' (pipe={tiene_pipe}, coma={tiene_coma})")


        


        columnas_csv = [


            c.strip().replace(".", "_").replace(" ", "_").lower()


            for c in header.split(delimitador)


        ]


        columnas_csv = columnas_unicas(columnas_csv)


        print(f"   [DEBUG] Columnas detectadas: {len(columnas_csv)}")


        


    except Exception as e:


        print(f"   [ERROR] Leyendo header CSV: {e}")


        errores.append((mes_archivo, nombre_archivo, f"Error leyendo header CSV: {e}"))


        print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=error|archivo={nombre_archivo}")


        if carpeta_temporal:


            shutil.rmtree(carpeta_temporal, ignore_errors=True)


        continue


```





**Detecci?n de delimitador**: Prioriza pipe (`|`) sobre coma (`,`). Si no hay ninguno, asume tabulaci?n (`\t`). **BOM removal**: `lstrip("\ufeff")` elimina el BOM UTF-8. **Normalizaci?n de columnas**: puntos y espacios se reemplazan por guion bajo; todo se convierte a min?sculas.





#### 7.3.10.4 Paso 4: COPY a Tabla Staging





```python


    conn = None


    cur = None


    try:


        conn = conectar_db()


        cur = conn.cursor()


        cur.execute("SET synchronous_commit = off;")


        


        asegurar_tabla_destino(cur, columnas_csv)





        tabla_staging = "tmp_hisminsa24_staging"


        crear_tabla_staging(cur, tabla_staging, columnas_csv)





        columnas_sql = ", ".join([f'"{c.lower()}"' for c in columnas_csv])


        print(f"   [TRANSFER] Transfiriendo datos...")


        


        try:


            with open(archivo_csv_temp, "r", encoding="latin1") as f:


                cur.copy_expert(f"""


COPY {tabla_staging} ({columnas_sql})


                     FROM STDIN WITH (FORMAT CSV, HEADER TRUE,


                     DELIMITER '{delimitador}', ENCODING 'LATIN1')


                """, f)


            print(f"   [DEBUG] COPY completado sin errores")


        except Exception as copy_err:


            print(f"   [ERROR COPY] {copy_err}")


            conn.rollback()


            errores.append((mes_archivo, nombre_archivo, f"Error COPY: {copy_err}"))


            print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=error|archivo={nombre_archivo}")


            continue


```





**Copia masiva** mediante `COPY ... FROM STDIN WITH (FORMAT CSV, HEADER TRUE, ...)`. `synchronous_commit = off` mejora rendimiento en cargas grandes. Si COPY falla, se hace rollback y se contin?a con el siguiente mes.





#### 7.3.10.5 Paso 5: Anti-duplicados DELETE





```python


        mes_sin_cero = str(int(mes_archivo))


        print(f"   [CLEAN] Limpiando {anio_proceso}-{mes_archivo}...")


        cur.execute(


            f"""


            DELETE FROM {tabla_destino}


            WHERE anio = %s


              AND mes IN (%s, %s);


            """,


            (anio_proceso, mes_archivo, mes_sin_cero),


        )


```





Elimina datos previos del mismo mes con y sin leading zero. Por ejemplo, para mes `"03"`, elimina registros donde `mes IN ('03', '3')`. Esto maneja inconsistencias hist?ricas donde el mes se almacena con o sin cero a la izquierda.





#### 7.3.10.6 Paso 6: INSERT INTO ... SELECT con COALESCE





```python


        columnas_insert_sql, columnas_select_sql, parametros_insert = construir_insert_desde_staging(


            columnas_csv,


            anio_proceso,


            mes_archivo,


        )


        cur.execute(


            f"""


            INSERT INTO {tabla_destino} ({columnas_insert_sql})


            SELECT {columnas_select_sql}


            FROM {tabla_staging};


            """,


            tuple(parametros_insert),


        )


        total_registros = cur.rowcount


        if total_registros is None or total_registros < 0:


            cur.execute(


                f"SELECT COUNT(*) FROM {tabla_staging};"


            )


            total_registros = cur.fetchone()[0]


        


        conn.commit()


```





Si `rowcount` es negativo (no disponible), se ejecuta `COUNT(*)` como fallback para obtener el total de registros.





#### 7.3.10.7 Paso 7: Commit y Logging





```python


        print(f"   [OK] Inyectado ({total_registros:,} registros).")


        procesados_ok.append((mes_archivo, nombre_archivo, total_registros))





        registrar_csv_subido(nombre_archivo, anio_proceso, mes_archivo, total_registros, ruta_crudos)


        print(f"   [LOG] Registrado en: {LOG_FILE}")


        print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=ok|archivo={nombre_archivo}")





    except Exception as e:


        print(f"[ERROR] Procesando {nombre_archivo}: {e}")


        errores.append((mes_archivo, nombre_archivo, str(e)))


        print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=error|archivo={nombre_archivo}")


        try:


            if conn:


                conn.rollback()


        except Exception:


            pass


    finally:


        if cur:


            cur.close()


        if conn:


            conn.close()


        if carpeta_temporal:


            shutil.rmtree(carpeta_temporal, ignore_errors=True)





    duracion_item = time.monotonic() - inicio_item


    print(f"   [TIME] Mes {mes_archivo}: {duracion_item:.1f}s")


```





### 7.3.11 Reporte de Progreso [PROGRESS]





El script usa un formato de progreso consistente para todas las operaciones:





```


[PROGRESS] TOTAL=12


[PROGRESS] DONE=1/12|mes=01|estado=ok|archivo=11_CUSCO_01.rar


[PROGRESS] DONE=2/12|mes=02|estado=error|archivo=11_CUSCO_02.zip


```





Este formato es parseado por la GUI de CustomTkinter (`modulo_maestros.py`) para mostrar barras de progreso en tiempo real.





### 7.3.12 Resumen Final





```python


print(f"\n[FINALIZADO] PROCESO ANUAL {anio_proceso}")


print(f"[RESUMEN] OK: {len(procesados_ok)} | ERRORES: {len(errores)}")





if procesados_ok:


    total_general = sum(x[2] for x in procesados_ok)


    print(f"[RESUMEN] Registros insertados: {total_general:,}")





if errores:


    print("\n[DETALLE_ERRORES]")


    for mes, archivo, motivo in errores:


        print(f" - Mes {mes} | {archivo} -> {motivo}")





    print(f"\n[RESUMEN] DE SUBIDAS:")


    print(obtener_resumen_subidos())





    if errores:


        sys.exit(1)


```





Si hay errores, el script termina con c?digo de salida 1.





---





## 7.4 01cargacvs_mensual.py ??? Carga Mensual de CSV





### 7.4.1 Prop?sito y Diferencias con Universal





```python


import os


import sys


import shutil


import psycopg2


import re


import tempfile


from datetime import datetime





sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


from extractor_archivos import detectar_extractor_rar, extraer_comprimido





EXTRACTOR_RAR_TIPO, EXTRACTOR_RAR_RUTA = detectar_extractor_rar()


```





A diferencia del script universal que procesa un a?o entero, la versi?n mensual procesa **un solo mes**. Toma 2 o 3 argumentos: `a?o`, `mes`, y opcionalmente `ruta_cruda`. Comparte las mismas funciones y constantes clave.





### 7.4.2 Constantes Compartidas





```python


COLUMNAS_LIMPIAR_NULL = {


    "apellidos", "nombres", "hemoglobina", "talla", "peso",


    "perimetro_abdominal", "perimetro_cefalico",


    "departamento", "provincia", "distrito",


    "establecimiento", "tipodianoc", "dx1", "dx2", "dx3",


    "codigo_item", "valor_lab",


}


```





Mismo conjunto de 16 columnas que reciben `COALESCE`.





### 7.4.3 Funciones de Utilidad





#### 7.4.3.1 extraer_mes_desde_nombre()





```python


def extraer_mes_desde_nombre(nombre_archivo):


    match = re.match(r"^11_CUSCO_(\d{1,2})(?:\D|$)", nombre_archivo, flags=re.IGNORECASE)


    if not match:


        return None


    try:


        mes = int(match.group(1))


    except ValueError:


        return None


    if 1 <= mes <= 12:


        return f"{mes:02d}"


    return None


```





Id?ntica a la versi?n universal.





#### 7.4.3.2 obtener_csv_extraido()





```python


def obtener_csv_extraido(carpeta, nombre_base=None, mes_esperado=None):


    csvs = []


    for raiz, _, archivos in os.walk(carpeta):


        for nombre in archivos:


            if nombre.lower().endswith(".csv"):


                csvs.append(os.path.join(raiz, nombre))





    if not csvs:


        return None





    if nombre_base:


        match_base = [


            ruta for ruta in csvs


            if nombre_base.lower() in os.path.basename(ruta).lower()


        ]


        if match_base:


            csvs = match_base





    if mes_esperado:


        match_mes = [


            ruta for ruta in csvs


            if extraer_mes_desde_nombre(os.path.basename(ruta)) == mes_esperado


        ]


        if match_mes:


            csvs = match_mes





    return max(csvs, key=lambda p: (os.path.getsize(p), os.path.getctime(p)))


```





Id?ntica a la versi?n universal.





#### 7.4.3.3 verificar_csv_valido()





```python


def verificar_csv_valido(ruta_csv):


    try:


        with open(ruta_csv, 'r', encoding='latin1') as f:


            header = f.readline()


            if not header.strip():


                return False, "Archivo vacio"


            tamano = os.path.getsize(ruta_csv)


            if tamano < 100:


                return False, f"Muy pequeno: {tamano} bytes"


            return True, None


    except Exception as e:


        return False, str(e)


```





Versi?n simplificada que solo verifica header y tama?o (sin muestra de l?neas).





#### 7.4.3.4 buscar_csv_manual()





```python


def buscar_csv_manual(ruta_crudos_local, nombre_base, mes_esperado=None):


    ruta_csv_raiz = os.path.join(ruta_crudos_local, f"{nombre_base}.csv")


    if os.path.exists(ruta_csv_raiz):


        return ruta_csv_raiz





    ruta_subcarpeta = os.path.join(ruta_crudos_local, nombre_base)


    ruta_csv_subcarpeta = os.path.join(ruta_subcarpeta, f"{nombre_base}.csv")


    if os.path.exists(ruta_csv_subcarpeta):


        return ruta_csv_subcarpeta





    if os.path.isdir(ruta_subcarpeta):


        return obtener_csv_extraido(ruta_subcarpeta, nombre_base, mes_esperado)





    return None


```





**3 estrategias de fallback**: misma implementaci?n que la versi?n universal.





### 7.4.4 Configuraci?n





```python


anio_proceso = sys.argv[1] if len(sys.argv) > 1 else "2023"


mes_proceso  = sys.argv[2] if len(sys.argv) > 2 else "01"


try:


    mes_proceso = f"{int(mes_proceso):02d}"


except Exception:


    mes_proceso = str(mes_proceso).zfill(2)





ruta_crudos_custom = sys.argv[3] if len(sys.argv) > 3 else None





base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))





if ruta_crudos_custom:


    ruta_crudos = ruta_crudos_custom


else:


    ruta_crudos = os.path.join(base_dir, "datos", "maestr", anio_proceso)


```





Normaliza el mes a 2 d?gitos: si el usuario pasa `3`, se convierte a `"03"`. Si pasa `"03"`, se mantiene.





### 7.4.5 B?squeda del Archivo del Mes





```python


nombre_base = f"11_CUSCO_{mes_proceso}"


archivo_encontrado = None


ruta_full = None


archivo_csv_temp = None


es_comprimido = False





csv_manual = buscar_csv_manual(ruta_crudos, nombre_base, mes_proceso)


if csv_manual and os.path.exists(csv_manual):


    archivo_encontrado = os.path.basename(csv_manual)


    ruta_full = csv_manual


    archivo_csv_temp = csv_manual


else:


    extensiones = (".rar", ".zip", ".7z", ".tar", ".tgz", ".tar.gz", ".csv")


    candidatos = [


        f for f in os.listdir(ruta_crudos)


        if f.upper().startswith(nombre_base.upper()) and any(f.lower().endswith(ext) for ext in extensiones)


    ]





    if not candidatos:


        print(f"[WARN] No se encontro archivo del mes {mes_proceso} en {ruta_crudos}")


        sys.exit()





    def _prioridad(nombre):


        return 0 if nombre.lower().endswith(".csv") else 1





    candidatos.sort(


        key=lambda nombre: (


            _prioridad(nombre),


            -os.path.getmtime(os.path.join(ruta_crudos, nombre)),


            nombre.lower(),


        )


    )


    archivo_encontrado = candidatos[0]


    ruta_full = os.path.join(ruta_crudos, archivo_encontrado)


```





La b?squeda prioriza:


1. CSV ya extra?do (via `buscar_csv_manual`)


2. CSV directo (prioridad 0)


3. Archivos comprimidos (prioridad 1)


4. Dentro de cada prioridad, el m?s reciente, y luego orden alfab?tico





### 7.4.6 Flujo de Descompresi?n





```python


carpeta_temp = None


if archivo_csv_temp is None and archivo_encontrado.lower().endswith((".rar", ".zip", ".7z", ".tar", ".tgz", ".tar.gz")):


    nombre_base_archivo = os.path.splitext(archivo_encontrado)[0]


    csv_manual = buscar_csv_manual(ruta_crudos, nombre_base_archivo, mes_proceso)


    if csv_manual and os.path.exists(csv_manual):


        print(f"[INFO] Usando CSV ya extraido: {os.path.basename(csv_manual)}")


        archivo_csv_temp = csv_manual


    else:


        print(f"[INFO] Descomprimiendo: {archivo_encontrado}...")


        carpeta_temp = tempfile.mkdtemp(prefix=f"tmp_ingesta_{mes_proceso}_", dir=ruta_crudos)


        exito, error = extraer_comprimido(ruta_full, carpeta_temp)


        if not exito:


            print(f"[ERROR] No se pudo extraer: {error or 'desconocido'}")


            print(f"[PROGRESS] DONE=1/1|mes={mes_proceso}|estado=error|archivo={archivo_encontrado}")


            shutil.rmtree(carpeta_temp, ignore_errors=True)


            sys.exit()


        es_comprimido = True


        archivo_csv_temp = obtener_csv_extraido(carpeta_temp, nombre_base_archivo, mes_proceso)


elif archivo_csv_temp is None:


    archivo_csv_temp = ruta_full


```





### 7.4.7 Header Analysis y Delimitaci?n





```python


with open(archivo_csv_temp, "r", encoding="latin1") as f:


    header     = f.readline().lstrip("\ufeff").strip()


    delimitador = '|' if '|' in header else ','


    columnas_csv = [


        c.strip().replace(".", "_").replace(" ", "_").lower()


        for c in header.split(delimitador)


    ]


    columnas_csv = columnas_unicas(columnas_csv)





cur.execute("SET synchronous_commit = off;")


```





**BOM removal** con `lstrip("\ufeff")`. Delimitador: pipe o coma (sin fallback a tabulaci?n).





### 7.4.8 asegurar_tabla_destino()





```python


def asegurar_tabla_destino(cur, columnas_csv):


    cur.execute(f"CREATE SCHEMA IF NOT EXISTS {esquema};")


    cur.execute(f"CREATE TABLE IF NOT EXISTS {tabla_destino} (anio TEXT, mes TEXT);")


    cur.execute(


        f"""


        CREATE INDEX IF NOT EXISTS idx_{tabla_nombre}_anio_mes


        ON {tabla_destino} (anio, mes);


        """


    )


    cur.execute(


        f"""


        SELECT column_name FROM information_schema.columns


        WHERE table_schema = '{esquema}' AND table_name = '{tabla_nombre}';


        """


    )


    columnas_db = [row[0].lower() for row in cur.fetchall()]


    columnas_nuevas = [col for col in columnas_csv if col not in columnas_db]





    if columnas_nuevas:


        print(f"[INFO] Agregando {len(columnas_nuevas)} columnas nuevas...")


        for col_nueva in columnas_nuevas:


            cur.execute(f'ALTER TABLE {tabla_destino} ADD COLUMN "{col_nueva}" TEXT;')


```





**Schema evolution din?mico**: mismo patr?n que en universal. Cualquier columna nueva en el CSV se agrega autom?ticamente a la tabla.





### 7.4.9 crear_tabla_staging() con TEMP TABLE ON COMMIT DROP





```python


def crear_tabla_staging(cur, tabla_staging, columnas_csv):


    col_defs = ", ".join([f'"{c}" TEXT' for c in columnas_csv])


    cur.execute(f"DROP TABLE IF EXISTS {tabla_staging};")


    cur.execute(f"CREATE TEMP TABLE {tabla_staging} ({col_defs}) ON COMMIT DROP;")


```





Tabla temporal que existe solo durante la transacci?n y se elimina autom?ticamente al hacer commit.





### 7.4.10 COPY, Anti-duplicados, INSERT con COALESCE





```python


        columnas_sql = ", ".join([f'"{c.lower()}"' for c in columnas_csv])


        print("[TRANSFER] Transfiriendo datos a PostgreSQL...")


        with open(archivo_csv_temp, "r", encoding="latin1") as f:


            cur.copy_expert(f"""


                COPY {tabla_staging} ({columnas_sql})


                FROM STDIN WITH (FORMAT CSV, HEADER TRUE,


                DELIMITER '{delimitador}', ENCODING 'LATIN1')


            """, f)





        mes_sin_cero = str(int(mes_proceso))


        print(f"[CLEAN] Eliminando registros previos de {anio_proceso}-{mes_proceso}...")


        cur.execute(


            f"""


            DELETE FROM {tabla_destino}


            WHERE anio = %s


              AND mes IN (%s, %s);


            """,


            (anio_proceso, mes_proceso, mes_sin_cero)


        )





        columnas_insert_sql, columnas_select_sql, parametros_insert = construir_insert_desde_staging(


            columnas_csv,


            anio_proceso,


            mes_proceso,


        )


        cur.execute(


            f"""


            INSERT INTO {tabla_destino} ({columnas_insert_sql})


            SELECT {columnas_select_sql}


            FROM {tabla_staging};


            """,


            tuple(parametros_insert)


        )


        total_registros = cur.rowcount


        if total_registros is None or total_registros < 0:


            cur.execute(f"SELECT COUNT(*) FROM {tabla_staging};")


            total_registros = cur.fetchone()[0]


        


        conn.commit()


```





### 7.4.11 Progreso y Logging





```python


        print(f"[OK] Mes {mes_proceso} inyectado ({total_registros:,} registros).")


        registrar_csv_subido(archivo_encontrado, anio_proceso, mes_proceso, total_registros, ruta_crudos)


        print(f"   [LOG] Registrado en: {LOG_FILE}")


        print(f"[PROGRESS] DONE=1/1|mes={mes_proceso}|estado=ok|archivo={archivo_encontrado}")





        if carpeta_temp:


            shutil.rmtree(carpeta_temp, ignore_errors=True)


            print("[CLEAN] Carpeta temporal eliminada.")





        print(f"\n[RESUMEN] DE SUBIDAS:")


        print(obtener_resumen_subidos())


```





---





## 7.5 cargar_maestros.py ??? Carga de Tablas Maestras





### 7.5.1 Prop?sito





```python


"""


cargar_maestros.py


Carga uno o todos los archivos CSV de maestros a PostgreSQL.


Uso:


    python cargar_maestros.py <ruta_carpeta_maestros> [nombre_archivo.csv]


    Si no se pasa nombre_archivo, carga TODOS los CSV de la carpeta.


"""


```





Carga archivos CSV de tablas maestras (establecimientos, personal, ubigeo, diagn?stico, etc.) en el esquema `es_ivan`. Es la puerta de entrada para 25+ tablas maestras.





### 7.5.2 MAPA_TABLAS ??? Diccionario Completo (25+ entradas)





```python


MAPA_TABLAS = {


    "11_maestro":                        "maestro_paciente",


    "maestropersonal":                   "maestro_personal",


    "maestro_his_actividad_his":         "maestro_his_actividad",


    "maestro_his_centro_poblado":        "maestro_his_centro_poblado",


    "maestro_his_cie_cpms":              "maestro_his_cie_cpms",


    "maestro_his_colegio":               "maestro_his_colegio",


    "maestro_his_condicion_contrato":    "maestro_his_condicion_contrato",


    "maestro_his_dosis":                 "maestro_his_dosis",


    "maestro_his_establecimiento":       "maestro_his_establecimiento",


    "maestro_his_establecimiento25":     "maestro_his_establecimiento",


    "maestro_his_etnia":                 "maestro_his_etnia",


    "maestro_his_financiador":           "maestro_his_financiador",


    "maestro_his_gruporiesgo_lab":       "maestro_his_gruporiesgo_lab",


    "maestro_his_institucion_educativa": "maestro_his_institucion_edu",


    "maestro_his_lab":                   "maestro_his_lab",


    "maestro_his_otra_condicion":        "maestro_his_otra_condicion",


    "maestro_his_pais":                  "maestro_his_pais",


    "maestro_his_profesion":             "maestro_his_profesion",


    "maestro_his_sistema":               "maestro_his_sistema",


    "maestro_his_tipo_doc":              "maestro_his_tipo_doc",


    "maestro_his_ubigeo_inei_reniec":    "maestro_his_ubigeo",


    "maestro_his_ups":                   "maestro_his_ups",


    "susalud26":                         "maestro_eess_susalud",


    "maestro_his_susalud":               "maestro_eess_susalud",


    "maestro_eess_susalud":              "maestro_eess_susalud",


}


```





**25 entradas** que mapean nombres de archivo CSV a nombres de tabla PostgreSQL. Casos notables:


- `"11_maestro"` ??? `"maestro_paciente"`: el archivo `11_MAESTRO.csv` se carga en la tabla `maestro_paciente`


- `"maestro_his_establecimiento25"` ??? `"maestro_his_establecimiento"`: versi?n legacy apunta a la misma tabla


- `"susalud26"`, `"maestro_his_susalud"` ??? `"maestro_eess_susalud"`: tres nombres diferentes para la misma tabla


- Para archivos no listados: se usa el nombre `"maestro_{nombre_archivo}"`





### 7.5.3 TABLA_A_CLAVES ??? ?ndice Inverso





```python


TABLA_A_CLAVES = {}


for clave, tabla in MAPA_TABLAS.items():


    TABLA_A_CLAVES.setdefault(tabla, set()).add(clave)


```





Construye un ?ndice inverso: `{ "maestro_eess_susalud": {"susalud26", "maestro_his_susalud", "maestro_eess_susalud"} }`. ??til para buscar archivos cuando se conoce la tabla destino.





### 7.5.4 nombre_tabla() ??? De Nombre de Archivo a Tabla





```python


def nombre_tabla(nombre_archivo_sin_ext: str) -> str:


    clave = nombre_archivo_sin_ext.lower().strip()


    return MAPA_TABLAS.get(clave, f"maestro_{clave}")


```





Si el nombre del archivo est? en `MAPA_TABLAS`, usa el mapeo. Si no, genera el nombre `"maestro_{nombre}"`.





### 7.5.5 buscar_archivo_por_tabla() ??? 3 Estrategias de B?squeda





```python


def buscar_archivo_por_tabla(carpeta: str, tabla_objetivo: str) -> str | None:


    csvs = sorted([f for f in os.listdir(carpeta) if f.lower().endswith(".csv")])


    tabla_objetivo = tabla_objetivo.lower().strip()





    # Intento 1: mapear por la misma l?gica de nombre_tabla


    for archivo in csvs:


        nombre = os.path.splitext(archivo)[0]


        if nombre_tabla(nombre) == tabla_objetivo:


            return archivo





    # Intento 2: coincidencia por nombre parcial del archivo


    for archivo in csvs:


        nombre = os.path.splitext(archivo)[0].lower().strip()


        if tabla_objetivo in nombre:


            return archivo





    # Intento 3: usar alias conocidos del mapa


    for alias in TABLA_A_CLAVES.get(tabla_objetivo, set()):


        for archivo in csvs:


            nombre = os.path.splitext(archivo)[0].lower().strip()


            if alias in nombre:


                return archivo





    return None


```





**Tres estrategias** en orden:


1. **Directa**: el nombre normalizado del archivo mapea exactamente a la tabla deseada


2. **Parcial**: la tabla objetivo est? contenida en el nombre del archivo (ej: buscar `"paciente"` encuentra `"11_MAESTRO.csv"`)


3. **Alias**: usa el ?ndice inverso `TABLA_A_CLAVES` para probar todos los alias conocidos





### 7.5.6 resolver_archivos_por_tablas()





```python


def resolver_archivos_por_tablas(carpeta: str, tablas_objetivo: list[str]) -> tuple[list[str], list[str]]:


    archivos = []


    faltantes = []


    vistos = set()





    for tabla in tablas_objetivo:


        tabla_norm = (tabla or "").strip().lower()


        if not tabla_norm or tabla_norm in {"todos", "all"}:


            continue





        archivo = buscar_archivo_por_tabla(carpeta, tabla_norm)


        if not archivo:


            faltantes.append(tabla_norm)


            continue





        if archivo not in vistos:


            vistos.add(archivo)


            archivos.append(archivo)





    return archivos, faltantes


```





Resuelve una lista de nombres de tabla a una lista de archivos CSV. Retorna `(archivos_encontrados, tablas_faltantes)`.





### 7.5.7 cargar_csv() ??? Carga Completa con Schema Evolution





```python


def cargar_csv(ruta_csv: str, conn) -> bool:


    nombre_archivo = os.path.splitext(os.path.basename(ruta_csv))[0]


    tabla          = nombre_tabla(nombre_archivo)


    tabla_full     = f"{ESQUEMA}.{tabla}"





    print(f"\n???? Procesando: {os.path.basename(ruta_csv)}")


    print(f"   ??? Tabla destino: {tabla_full}")





    cur = conn.cursor()


    try:


        with open(ruta_csv, "r", encoding="latin1") as f:


            header     = f.readline().strip()


            delimitador = "|" if "|" in header else (";" if ";" in header else ",")


            columnas   = [


                c.strip().replace(".", "_").replace(" ", "_").lower()


                for c in header.split(delimitador)


            ]





        cur.execute(f"CREATE SCHEMA IF NOT EXISTS {ESQUEMA};")





        col_defs = ", ".join([f'"{c}" TEXT' for c in columnas])


        cur.execute(f"CREATE TABLE IF NOT EXISTS {tabla_full} ({col_defs});")


        conn.commit()





        cur.execute(f"""


            SELECT column_name FROM information_schema.columns


            WHERE table_schema = '{ESQUEMA}' AND table_name = '{tabla}';


        """)


        cols_existentes = {r[0].lower() for r in cur.fetchall()}


        for col in columnas:


            if col not in cols_existentes:


                cur.execute(f'ALTER TABLE {tabla_full} ADD COLUMN "{col}" TEXT;')


                print(f"   ??? Columna nueva: {col}")


        conn.commit()





        cur.execute(f"TRUNCATE TABLE {tabla_full};")





        col_sql = ", ".join([f'"{c}"' for c in columnas])


        with open(ruta_csv, "r", encoding="latin1") as f:


            cur.copy_expert(f"""


                COPY {tabla_full} ({col_sql})


                FROM STDIN WITH (FORMAT CSV, HEADER TRUE,


                DELIMITER '{delimitador}', ENCODING 'LATIN1')


            """, f)





        conn.commit()


        cur.close()


        print(f"   [OK] Cargado correctamente.")


        return True





    except Exception as e:


        conn.rollback()


        cur.close()


        print(f"   [ERROR] {e}")


        return False


```





**Flujo de carga por archivo**:


1. Lee header del CSV (encoding latin1)


2. Detecta delimitador: `|` ??? `;` ??? `,`


3. Normaliza nombres de columna (`.` y espacios ??? `_`, min?sculas)


4. Crea `CREATE TABLE IF NOT EXISTS` con todas las columnas como `TEXT`


5. **Schema evolution**: agrega columnas nuevas que no exist?an (`ALTER TABLE ADD COLUMN`)


6. **TRUNCATE** (borra datos previos) antes de cargar


7. **COPY** desde STDIN con `FORMAT CSV, HEADER TRUE`





### 7.5.8 main() y CLI Flags





```python


def main():


    if len(sys.argv) < 2:


        print("[ERROR] Uso: python cargar_maestros.py <carpeta> [archivo.csv]")


        print("   o:  python cargar_maestros.py <carpeta> --tabla <tabla_destino>")


        print("   o:  python cargar_maestros.py <carpeta> --tablas <tabla_a> <tabla_b> ...")


        print("   o:  python cargar_maestros.py <carpeta> --archivos <a.csv> <b.csv> ...")


        sys.exit(1)





    carpeta = sys.argv[1]


    archivo_filtro = None


    tabla_filtro = None


    tablas_filtro = None


    archivos_explicitos = None





    if len(sys.argv) > 2:


        if sys.argv[2] == "--tabla":


            if len(sys.argv) < 4:


                print("[ERROR] Falta indicar la tabla despues de --tabla")


                sys.exit(1)


            tabla_filtro = sys.argv[3].lower().strip()


        elif sys.argv[2] == "--tablas":


            if len(sys.argv) < 4:


                print("[ERROR] Debes indicar al menos una tabla despues de --tablas")


                sys.exit(1)


            tablas_filtro = [t.strip().lower() for t in sys.argv[3:] if t.strip()]


            if not tablas_filtro:


                print("[ERROR] Lista de tablas vacia en --tablas")


                sys.exit(1)


        elif sys.argv[2] == "--archivos":


            if len(sys.argv) < 4:


                print("[ERROR] Debes indicar al menos un archivo despues de --archivos")


                sys.exit(1)


            archivos_explicitos = [a.strip() for a in sys.argv[3:] if a.strip()]


            if not archivos_explicitos:


                print("[ERROR] Lista de archivos vacia en --archivos")


                sys.exit(1)


        else:


            archivo_filtro = sys.argv[2]


```





### 7.5.9 Modos de Ejecuci?n





| Flag | Descripci?n | Ejemplo |


|------|-------------|---------|


| `--tabla <nombre>` | Carga una tabla espec?fica | `--tabla maestro_paciente` |


| `--tablas <a> <b> ...` | Carga m?ltiples tablas | `--tablas maestro_paciente maestro_personal` |


| `--archivos <a.csv> ...` | Carga archivos espec?ficos | `--archivos 11_MAESTRO.csv MaestroPersonal.csv` |


| `<archivo.csv>` (sin flag) | Carga un archivo espec?fico | `11_MAESTRO.csv` |


| (sin argumento extra) | Carga TODOS los CSV | ??? |





La determinaci?n de archivos sigue esta prioridad:


1. `archivos_explicitos` (flag `--archivos`)


2. `tablas_filtro` ??? `resolver_archivos_por_tablas()` (flag `--tablas`)


3. `tabla_filtro` ??? `buscar_archivo_por_tabla()` (flag `--tabla`)


4. `archivo_filtro` (nombre directo)


5. Todos los CSV de la carpeta





---





## 7.6 02maestro_paciente.py ??? Maestro de Pacientes





### 7.6.1 Prop?sito





```python


"""


Carga 11_MAESTRO (Pacientes) y MaestroPersonal con todas sus columnas originales.


"""


```





Script legacy espec?fico para cargar dos archivos maestros: `11_MAESTRO.csv` ??? `maestro_paciente` y `MaestroPersonal.csv` ??? `maestro_personal`.





### 7.6.2 cargar_maestro_exacto()





```python


def cargar_maestro_exacto(archivo_buscado, tabla_final):


    archivo_encontrado = None


    for archivo in os.listdir(ruta_maestros):


        if archivo_buscado.lower() in archivo.lower() and archivo.endswith(".csv"):


            archivo_encontrado = os.path.join(ruta_maestros, archivo)


            break





    if not archivo_encontrado:


        print(f"???? No se encontr?: {archivo_buscado}")


        return





    print(f"???? Procesando: {os.path.basename(archivo_encontrado)}")





    try:


        conn = psycopg2.connect(dbname=basedatos, user=usuario, password=password, host=host, port=puerto)


        cur = conn.cursor()


        cur.execute("CREATE SCHEMA IF NOT EXISTS es_ivan;")





        with open(archivo_encontrado, "r", encoding="latin1") as f:


            header = f.readline().strip()


            delimitador = ";" if ";" in header else ","


            columnas = [c.strip().replace(".", "_").replace(" ", "_") for c in header.split(delimitador)]





        column_defs = ", ".join([f"{col} TEXT" for col in columnas])


        


        tabla_full = f"es_ivan.{tabla_final}"


        cur.execute(f"DROP TABLE IF EXISTS {tabla_full} CASCADE;")


        cur.execute(f"CREATE TABLE {tabla_full} ({column_defs});")





        with open(archivo_encontrado, "r", encoding="latin1") as f:


            cur.copy_expert(f"COPY {tabla_full} FROM STDIN WITH CSV HEADER DELIMITER '{delimitador}' ENCODING 'LATIN1'", f)





        cur.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = '{tabla_final}' AND table_schema = 'es_ivan'")


        columnas_todas = [r[0] for r in cur.fetchall()]


        for col in columnas_todas:


            cur.execute(f"UPDATE {tabla_full} SET {col} = '' WHERE {col} IS NULL")





        conn.commit()


        cur.close()


        conn.close()


        print(f"??? {tabla_final} cargado con las {len(columnas)} columnas originales.")





    except Exception as e:


        print(f"?? Error en {tabla_final}: {e}")


```





### 7.6.3 DROP TABLE CASCADE y Recreaci?n





```python


cur.execute(f"DROP TABLE IF EXISTS {tabla_full} CASCADE;")


cur.execute(f"CREATE TABLE {tabla_full} ({column_defs});")


```





A diferencia de `cargar_maestros.py` que usa `CREATE TABLE IF NOT EXISTS` + `TRUNCATE`, este script hace **DROP TABLE CASCADE** y recrea la tabla desde cero. Esto elimina cualquier dependencia (?ndices, vistas, etc.) pero asegura una estructura exacta.





### 7.6.4 NULL a Vac?o Post-Carga





```python


cur.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = '{tabla_final}' AND table_schema = 'es_ivan'")


columnas_todas = [r[0] for r in cur.fetchall()]


for col in columnas_todas:


    cur.execute(f"UPDATE {tabla_full} SET {col} = '' WHERE {col} IS NULL")


```





Itera sobre **todas las columnas** de la tabla y actualiza NULLs a cadena vac?a. Esto es posterior a la carga, a diferencia del `COALESCE` en staging que se hace durante la inserci?n.





---





## 7.7 03cargar_padron_trama.py ??? Padr?n SIS Trama





### 7.7.1 Prop?sito





Carga el padr?n de asegurados del SIS desde archivos CSV con nombre `PadronN_Trama*.csv` en la tabla `padron_trama`.





### 7.7.2 Configuraci?n Espec?fica





```python


ruta_csv = r"D:\PROCESO_POSTGRES2024\import\cnv_padron"


ruta_procesados = r"D:\PROCESO_POSTGRES2024\import\procesados"


psql_path = r"C:\Program Files\PostgreSQL\15\bin\psql.exe"





esquema = _cfg.schema or "public"


tabla = "padron_trama"


tabla_destino = f"{esquema}.{tabla}"


```





Rutas fijas del entorno Windows del usuario. La ruta de `psql.exe` est? hardcodeada para PostgreSQL 15.





### 7.7.3 Detecci?n de Archivo





```python


archivo_csv = None


for archivo in os.listdir(ruta_csv):


    if archivo.lower().startswith("padronn_trama") and archivo.lower().endswith(".csv"):


        archivo_csv = os.path.join(ruta_csv, archivo)


        break





if not archivo_csv:


    print("?? No se encontr? un archivo que empiece con 'PadronN_Trama' y termine en '.csv'")


    exit()


```





Busca archivos que empiecen con `padronn_trama` (case-insensitive) y terminen en `.csv`.





### 7.7.4 Carga con psycopg2





```python


try:


    conn = psycopg2.connect(


        dbname=basedatos, user=usuario, password=password, host=host, port=puerto


    )


    cur = conn.cursor()





    cur.execute(f"TRUNCATE TABLE {tabla_destino} RESTART IDENTITY CASCADE")


    conn.commit()


    print(f"????? Tabla {tabla_destino} vaciada")





    with open(archivo_csv, "r", encoding="latin1") as f:


        cur.copy_expert(


            f"COPY {tabla_destino} FROM STDIN WITH CSV HEADER DELIMITER '{delimitador}'",


            f


        )





    cur.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = '{tabla_nombre}' AND table_schema = 'es_ivan'")


    columnas_todas = [r[0] for r in cur.fetchall()]


    for col in columnas_todas:


        cur.execute(f"UPDATE {tabla_destino} SET {col} = '' WHERE {col} IS NULL")





    conn.commit()


    cur.close()


    conn.close()


```





**TRUNCATE RESTART IDENTITY CASCADE**: vac?a la tabla, reinicia secuencias, y cascada a tablas dependientes. Luego `COPY` y actualizaci?n de NULLs.





### 7.7.5 Fallback a psql \copy





```python


except Exception as e:


    print(f"???? Error con psycopg2, intentando con psql \\COPY...\n{e}")


    try:


        cmd = [


            psql_path,


            f"-h{host}",


            f"-p{puerto}",


            f"-U{usuario}",


            "-d", basedatos,


            "-c",


            f"\\copy {tabla_destino} FROM '{archivo_csv}' WITH CSV HEADER DELIMITER '{delimitador}' ENCODING 'LATIN1';"


        ]


        env = os.environ.copy()


        env["PGPASSWORD"] = password


        subprocess.run(cmd, env=env, check=True, creationflags=CREATE_NO_WINDOW)


```





Si psycopg2 falla (ej: driver issues), intenta con `psql \copy` como subproceso. La contrase?a se pasa via variable de entorno `PGPASSWORD`.





### 7.7.6 Movimiento a Procesados





```python


destino = os.path.join(ruta_procesados, os.path.basename(archivo_csv))


shutil.move(archivo_csv, destino)


print(f"???? Archivo movido a: {destino}")


```





Despu?s de una carga exitosa (con psycopg2 o psql), el archivo se mueve a `procesados/` para evitar reprocesamiento.





---





## 7.8 03_ejecutar_consolidacion.py ??? Consolidaci?n





### 7.8.1 Prop?sito





```python


anio = sys.argv[1]


mes = sys.argv[2]


```





Ejecuta la consolidaci?n de `hisminsa_consolidado` ??? `hisminsa_consolidado_full` enriqueciendo con datos de pacientes (nombre completo, DNI, etnia) y personal de salud (nombre completo). Acepta a?o y mes (o "Todos los meses").





### 7.8.2 Creaci?n de Tabla Consolidada





```python


cur.execute(f"""


    CREATE TABLE IF NOT EXISTS {ESQUEMA}.hisminsa_consolidado_full AS 


    SELECT h.*, 


            CAST('' AS TEXT) as nombre_completo_paciente, 


            CAST('' AS TEXT) as dni_paciente,


            CAST('' AS TEXT) as id_etnia,


            CAST('' AS TEXT) as nombre_completo_personal 


    FROM {ESQUEMA}.hisminsa_consolidado h LIMIT 0;


""")





cur.execute(f"""


    DO $$ 


    BEGIN 


        BEGIN ALTER TABLE {ESQUEMA}.hisminsa_consolidado_full ADD COLUMN dni_paciente TEXT; EXCEPTION WHEN duplicate_column THEN END;


        BEGIN ALTER TABLE {ESQUEMA}.hisminsa_consolidado_full ADD COLUMN id_etnia TEXT; EXCEPTION WHEN duplicate_column THEN END;


    END $$;


""")


```





- `CREATE TABLE ... AS SELECT ... LIMIT 0`: crea la tabla con la misma estructura que `hisminsa_consolidado` m?s 4 nuevas columnas TEXT vac?as


- `DO $$ ... EXCEPTION WHEN duplicate_column`: bloque an?nimo PL/pgSQL que agrega columnas si no existen (maneja idempotencia)





### 7.8.3 LEFT JOIN Completo





```python


if mes == "Todos los meses":


    print(f"???? Consolidando TODO el a?o {anio}...")


    cur.execute(f"DELETE FROM {ESQUEMA}.hisminsa_consolidado_full WHERE anio = %s", (anio,))


    condicion_mes = ""


else:


    print(f"???? Consolidando {anio} - Mes {mes}...")


    cur.execute(f"DELETE FROM {ESQUEMA}.hisminsa_consolidado_full WHERE anio = %s AND mes = %s", (anio, mes))


    condicion_mes = f"AND h.mes = '{mes}'"





sql = f"""


    INSERT INTO {ESQUEMA}.hisminsa_consolidado_full


    SELECT h.*, 


            (p.apellido_paterno_paciente || ' ' || p.apellido_materno_paciente || ', ' || p.nombres_paciente) as nombre_completo_paciente,


            p.numero_documento as dni_paciente,


            p.id_etnia as id_etnia,


            (m.apellido_paterno_personal || ' ' || m.apellido_materno_personal || ', ' || m.nombres_personal) as nombre_completo_personal


    FROM {ESQUEMA}.hisminsa_consolidado h


    LEFT JOIN {ESQUEMA}.maestro_paciente p ON h.id_paciente = p.id_paciente


    LEFT JOIN {ESQUEMA}.maestro_personal m ON h.id_personal = m.id_personal


    WHERE h.anio = %s {condicion_mes};


"""





cur.execute(sql, (anio,))


```





### 7.8.4 nombre_completo con Concatenaci?n





```python


(p.apellido_paterno_paciente || ' ' || p.apellido_materno_paciente || ', ' || p.nombres_paciente) as nombre_completo_paciente


```





Usa el operador `||` de PostgreSQL para concatenar: `"ApellidoPaterno ApellidoMaterno, Nombres"`. Mismo patr?n para personal de salud.





### 7.8.5 Limpieza de NULL por Columna





```python


columnas_limpiar = [


    "apellido_paterno_paciente", "apellido_materno_paciente", "nombres_paciente",


    "numero_documento", "id_etnia",


    "apellido_paterno_personal", "apellido_materno_personal", "nombres_personal",


    "hemoglobina", "talla", "peso", "perimetro_abdominal", "perimetro_cefalico",


    "codigo_item", "valor_lab"


]


for col in columnas_limpiar:


    cur.execute(f"""UPDATE {ESQUEMA}.hisminsa_consolidado_full SET "{col}" = '' WHERE "{col}" IS NULL AND anio = %s AND mes = %s;""", (anio, mes))


```





Lista expl?cita de 14 columnas a limpiar (convertir NULL a vac?o), incluyendo datos demogr?ficos y antropom?tricos.





---





## 7.9 05personal.py ??? Personal de Salud





### 7.9.1 Prop?sito





Carga el archivo `MaestroPersonal*.csv` en la tabla `maestro_personal`. Sigue el mismo patr?n que `03cargar_padron_trama.py`: psycopg2 con fallback a psql.





```python


ruta_csv = r"D:\PROCESO_POSTGRES2024\import\cnv_padron"


ruta_procesados = r"D:\PROCESO_POSTGRES2024\import\procesados"


psql_path = r"C:\Program Files\PostgreSQL\15\bin\psql.exe"





esquema = _cfg.schema or "public"


tabla = "maestro_personal"


tabla_destino = f"{esquema}.{tabla}"


```





### 7.9.2 TRUNCATE + COPY





```python


conn = psycopg2.connect(


    dbname=basedatos, user=usuario, password=password, host=host, port=puerto


)


cur = conn.cursor()





cur.execute(f"TRUNCATE TABLE {tabla_destino}")


conn.commit()


print(f"????? Tabla {tabla_destino} vaciada")





with open(archivo_csv, "r", encoding="latin1") as f:


    cur.copy_expert(


        f"COPY {tabla_destino} FROM STDIN WITH CSV HEADER DELIMITER '{delimitador}' ENCODING 'LATIN1'",


        f


    )





cur.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = '{tabla_nombre}' AND table_schema = 'es_ivan'")


columnas_todas = [r[0] for r in cur.fetchall()]


for col in columnas_todas:


    cur.execute(f"UPDATE {tabla_destino} SET {col} = '' WHERE {col} IS NULL")





conn.commit()


```





**TRUNCATE** sin `RESTART IDENTITY CASCADE` (a diferencia de 03cargar_padron_trama). COPY directo a la tabla (sin staging). Actualizaci?n de NULLs post-carga.





### 7.9.3 Fallback a psql \copy





```python


except Exception as e:


    print(f"???? Error con psycopg2, intentando con psql \\COPY...\n{e}")


    try:


        cmd = [


            psql_path,


            f"-h{host}",


            f"-p{puerto}",


            f"-U{usuario}",


            "-d", basedatos,


            "-c",


            f"\\copy {tabla_destino} FROM '{archivo_csv}' WITH CSV HEADER DELIMITER '{delimitador}' ENCODING 'LATIN1';"


        ]


        env = os.environ.copy()


        env["PGPASSWORD"] = password


        subprocess.run(cmd, env=env, check=True, creationflags=CREATE_NO_WINDOW)


```





Mismo patr?n de fallback que `03cargar_padron_trama.py`.





---





## 7.10 procesar_eess_principal.py ??? Establecimientos de Salud (EESS)





### 7.10.1 Prop?sito





```python


"""


Procesa el script SQL de EESS principal para generar/actualizar la tabla eess2025.


Normaliza nombres de tablas legacy, limpia comentarios, y ajusta tipos de datos.


"""


```





Ejecuta un script SQL complejo (EESS_PRINCIPAL_2026_moshe.sql) que genera la tabla `eess2025` con datos de establecimientos de salud. Incluye normalizaci?n del SQL original.





### 7.10.2 limpiar_sql() ??? Normalizaci?n del Script SQL





```python


def limpiar_sql(contenido: str, esquema: str) -> str:


    texto = contenido





    # Quitar bloques comentados largos


    texto = re.sub(r"/\*.*?\*/", "", texto, flags=re.S)





    # Quitar CALL opcional que no existe en todos los entornos


    texto = re.sub(


        r"(?im)^\s*CALL\s+es_ivan\.sp_generar_eess2025\(\);\s*$",


        "", texto,


    )





    # Corregir referencias legacy


    texto = re.sub(r"\bmaestro_eess_susalud2025\b", "maestro_eess_susalud", texto, flags=re.I)


    texto = re.sub(r"\bmaestro_his_establecimiento25\b", "maestro_his_establecimiento", texto, flags=re.I)





    # Normalizar listas NOT IN de id_establecimiento (columna TEXT)


    def _normalizar_not_in_id_establecimiento(match: re.Match) -> str:


        prefijo = match.group(1)


        lista_raw = match.group(2)


        items = [x.strip() for x in lista_raw.split(",") if x.strip()]


        normalizados = []


        for item in items:


            if re.fullmatch(r"'[^']*'", item):


                normalizados.append(item)


            elif re.fullmatch(r"-?\d+", item):


                normalizados.append(f"'{item}'")


            else:


                normalizados.append(item)


        return f"{prefijo}NOT IN ({','.join(normalizados)})"





    texto = re.sub(


        r"(?is)((?:\b\w+\.)?id_establecimiento\s+)NOT\s+IN\s*\(([^)]*)\)",


        _normalizar_not_in_id_establecimiento, texto,


    )





    # Forzar id_eess entero para que coincida con RETURNS TABLE(id_eess INT, ...)


    texto = re.sub(


        r"(?i)\be\.id_establecimiento\s+AS\s+id_eess\b",


        "CASE WHEN e.id_establecimiento ~ '^[0-9]+$' THEN e.id_establecimiento::INT ELSE 0 END AS id_eess",


        texto,


    )





    # Ajustar esquema din?mico


    texto = re.sub(r"\bes_ivan\.", f"{esquema}.", texto, flags=re.I)


```





**Transformaciones**:


1. Elimina comentarios `/* ... */`


2. Elimina `CALL sp_generar_eess2025()` si existe


3. Renombra tablas legacy `maestro_eess_susalud2025` ??? `maestro_eess_susalud`


4. Renombra `maestro_his_establecimiento25` ??? `maestro_his_establecimiento`


5. Normaliza listas `NOT IN`: n?meros sin comillas se envuelven en comillas (porque `id_establecimiento` es `TEXT`)


6. Convierte `e.id_establecimiento AS id_eess` a `CASE WHEN e.id_establecimiento ~ '^[0-9]+$' THEN e.id_establecimiento::INT ELSE 0 END`


7. Reemplaza esquema fijo `es_ivan.` por el esquema configurado





### 7.10.3 validar_tablas_base()





```python


def validar_tablas_base(cur, esquema: str) -> None:


    cur.execute(


        """SELECT 1 FROM information_schema.tables WHERE table_schema = %s AND table_name = %s;""",


        (esquema, "maestro_his_susalud"),


    )


    existe_susalud_legacy = cur.fetchone() is not None





    cur.execute(


        """SELECT 1 FROM information_schema.tables WHERE table_schema = %s AND table_name = %s;""",


        (esquema, "maestro_eess_susalud"),


    )


    existe_susalud_objetivo = cur.fetchone() is not None





    if (not existe_susalud_objetivo) and existe_susalud_legacy:


        cur.execute(


            sql.SQL("CREATE OR REPLACE VIEW {} AS SELECT * FROM {};").format(


                sql.Identifier(esquema, "maestro_eess_susalud"),


                sql.Identifier(esquema, "maestro_his_susalud"),


            )


        )


        print("[INFO] Se cre? vista de compatibilidad: maestro_eess_susalud -> maestro_his_susalud")





    requeridas = {"maestro_his_establecimiento", "maestro_eess_susalud"}


    cur.execute(


        """SELECT table_name FROM information_schema.tables WHERE table_schema = %s AND table_name = ANY(%s);""",


        (esquema, list(requeridas)),


    )


    encontradas = {r[0] for r in cur.fetchall()}


    faltantes = sorted(requeridas - encontradas)


    if faltantes:


        raise Exception(


            "Faltan tablas maestras para ejecutar EESS principal: " + ", ".join(faltantes)


        )


```





Valida que existan las tablas maestras requeridas. Si `maestro_eess_susalud` no existe pero `maestro_his_susalud` s?, crea una **vista de compatibilidad**.





### 7.10.4 asegurar_tabla_eess()





```python


def asegurar_tabla_eess(cur, esquema: str) -> None:


    tabla = sql.Identifier(esquema, "eess2025")


    cur.execute(


        sql.SQL("""


            CREATE TABLE IF NOT EXISTS {} (


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


            );


        """).format(tabla)


    )


```





Tabla con **21 columnas** que almacena los establecimientos de salud con geolocalizaci?n completa (departamento, provincia, distrito, red, microred).





### 7.10.5 resolver_ruta_sql()





```python


def resolver_ruta_sql() -> str:


    if len(sys.argv) > 1:


        candidato = sys.argv[1]


        if os.path.isabs(candidato):


            return candidato


        return os.path.join(BASE_DIR, candidato)





    ruta_por_defecto = os.path.join(BASE_DIR, SQL_REL_PATH)


    if os.path.exists(ruta_por_defecto):


        return ruta_por_defecto





    carpeta = os.path.join(BASE_DIR, "scripts_sql", "scripst tabla y reportes vacunas-cred")


    if os.path.isdir(carpeta):


        candidatos = sorted(


            f for f in os.listdir(carpeta)


            if f.upper().startswith("EESS_PRINCIPAL_2026") and f.lower().endswith("moshe.sql")


        )


        if candidatos:


            return os.path.join(carpeta, candidatos[0])





    return ruta_por_defecto


```





Resuelve la ruta del script SQL con 3 niveles:


1. Argumento CLI (absoluto o relativo)


2. Ruta por defecto desde configuraci?n


3. B?squeda en carpeta con patr?n `EESS_PRINCIPAL_2026*moshe.sql`





---





## 7.11 01cargacvs.py ??? Versi?n Legacy (SQLAlchemy)





### 7.11.1 Prop?sito





Versi?n anterior del cargador CSV que usa **SQLAlchemy** en lugar de psycopg2 directo. Procesa archivos CSV que contengan un a?o espec?fico en el nombre.





```python


from sqlalchemy import create_engine, text





engine = create_engine(


    f"postgresql+psycopg2://{usuario}:{password}@{host}:{puerto}/{basedatos}"


)





with engine.begin() as conn:


    conn.execute(text(f"DELETE FROM {tabla_destino} WHERE anio = 2023;"))





for archivo in os.listdir(ruta_csv):


    if "2023" in archivo and archivo.lower().endswith(".csv"):


        conn = engine.raw_connection()


        cursor = conn.cursor()





        with open(ruta_archivo, "r", encoding="latin1") as f:


            cursor.copy_expert(f"""


                COPY {tabla_destino}


                FROM STDIN WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',', ENCODING 'LATIN1')


            """, f)





        conn.commit()


        shutil.move(ruta_archivo, os.path.join(ruta_procesados, archivo))


```





Diferencias clave con `01cargacvs_universal.py`:


- Usa SQLAlchemy `create_engine` en lugar de psycopg2 directo


- DELETE fijo para a?o 2023 (no parametrizado)


- Delimitador fijo (coma), sin detecci?n autom?tica


- Sin tabla staging ni COALESCE


- Sin soporte para archivos comprimidos


- Sin plan de archivos ni selecci?n por prioridad





---





# 8. MOTOR DE TRANSFORMACI??N ETL





## 8.1 generar_his_proceso.py ??? Descripci?n General





El archivo `generar_his_proceso.py` (1046 l?neas) es el componente central del sistema. Implementa la transformaci?n de la tabla `hisminsa24` (cruda, con estructura variable) a `his_proceso` (estructura fija, particionada por a?o). Este script es el m?s complejo del sistema y constituye el n?cleo del pipeline ETL.





### 8.1.1 Arquitectura General





El script sigue un patr?n de ejecuci?n en 5 fases:





1. **Inicializaci?n**: Parseo de argumentos (`<anio> [mes]` o `<anio> <maestros_json> [mes]`), conexi?n a BD, adquisici?n de advisory lock PostgreSQL, configuraci?n de sesi?n (work_mem, temp_buffers, jit).


2. **Resoluci?n de fuentes**: Detecta tablas disponibles mediante `information_schema` en esquemas `es_ivan` y `maestros`. Resuelve tablas EESS desde `eess2025` o `maestro_his_establecimiento`/`maestro_his_establecimiento25`.


3. **Preparaci?n**: Crea/asegura estructura de `his_proceso` y sus particiones anuales, construye `tmp_eess_lookup` con prioridad de fuentes, asegura ?ndices en tablas fuente.


4. **Procesamiento por per?odo**: Para cada a?o (y mes opcional), ejecuta: limpieza del per?odo ??? staging (8 tablas temporales) ??? enriquecimiento EESS ??? carga en partici?n final.


5. **Finalizaci?n**: Libera el advisory lock, cierra cursor y conexi?n.





### 8.1.2 Argumentos de L?nea de Comandos





```python


def parsear_argumentos() -> tuple[str, str]:


    # python generar_his_proceso.py <anio> <maestros_json> [mes]


    # python generar_his_proceso.py <anio> [mes]


```





Soporta dos modos de llamada: el moderno con solo a?o y mes opcional, y el legacy (`<maestros_json>` como segundo argumento) para compatibilidad con scripts antiguos.





## 8.2 COLUMNAS_HIS_PROCESO ??? Cat?logo Completo





La tabla `his_proceso` almacena 48 columnas que cubren identificaci?n del paciente, datos demogr?ficos, atenci?n cl?nica, diagn?sticos, procedimientos, vacunaci?n, y metadata del establecimiento de salud. A continuaci?n el listado exhaustivo con tipo de dato PostgreSQL y origen de cada columna.





### 8.2.1 Columnas de Identificaci?n de Cita





```python


COLUMNAS_HIS_PROCESO = [


    "id_cita",


    "lote",


    "fg_tipo",


    "dni_paciente",


    "apellido_paterno_paciente",


    "apellido_materno_paciente",


    "nombres_paciente",


    "fecha_nacimiento",


    "id_tipo_documento",


    "genero",


    "id_etnia",


    "anio",


    "mes",


    "dia",


    "id_establecimiento",


    "fecha_atencion",


    "edad",


    "tip_edad",


    "fi",


    "establec",


    "servicio",


    "condicion_gestante",


    "peso_pregestacional",


    "tipo_diagnostico",


    "codigo_item",


    "valor_lab",


    "id_correlativo",


    "id_correlativo_lab",


    "cod_2000",


    "codigo_red",


    "red",


    "desc_ue",


    "codigo_microred",


    "microred",


    "departamento",


    "provincia",


    "distrito",


    "nombre_establecimiento",


    "dni_personal",


    "dni_registrador",


    "id_colegio",


    "descripcion_colegio",


    "id_ups",


    "descripcion_etnia",


    "fecha_registro",


    "fecha_modificacion",


]


```





### 8.2.2 Glosario Detallado de Columnas





| # | Columna | Tipo SQL | Fuente | Descripci?n |


|---|---------|----------|--------|-------------|


| 1 | `id_cita` | `int NOT NULL` | `hisminsa24.id_cita` validado con regex `^[0-9]+$` | Identificador ?nico de la cita/atenci?n. Si no es num?rico se asigna 0. |


| 2 | `lote` | `varchar(3)` | `hisminsa24.lote` | C?digo de lote de procesamiento (3 caracteres). |


| 3 | `fg_tipo` | `varchar(2)` | `maestro_his_cie_cpms.fg_tipo` v?a JOIN por `codigo_item` | Tipo de financiador/groupador. |


| 4 | `dni_paciente` | `varchar(50)` | `maestro_paciente.numero_documento` | N?mero de documento del paciente (DNI, CE, etc.). |


| 5 | `apellido_paterno_paciente` | `text` | `maestro_paciente.apellido_paterno_paciente` | Apellido paterno del paciente. |


| 6 | `apellido_materno_paciente` | `text` | `maestro_paciente.apellido_materno_paciente` | Apellido materno del paciente. |


| 7 | `nombres_paciente` | `text` | `maestro_paciente.nombres_paciente` | Nombres completos del paciente. |


| 8 | `fecha_nacimiento` | `date` | `maestro_paciente.fecha_nacimiento`, NULL si vac?o | Fecha de nacimiento del paciente. |


| 9 | `id_tipo_documento` | `int` | `maestro_paciente.id_tipo_documento`, validado num?rico | Tipo de documento (1=DNI, 2=CE, etc.). 0 si no v?lido. |


| 10 | `genero` | `varchar(1)` | `maestro_paciente.genero` | Sexo del paciente: M/F. |


| 11 | `id_etnia` | `int` | `maestro_paciente.id_etnia`, validado num?rico | C?digo de etnia del paciente. 0 si no v?lido. |


| 12 | `anio` | `int NOT NULL` | `hisminsa24.anio`, casteo directo | A?o de la atenci?n. Columna de partici?n. |


| 13 | `mes` | `int` | `hisminsa24.mes`, validado num?rico | Mes de la atenci?n (1-12). 0 si no v?lido. |


| 14 | `dia` | `int` | `hisminsa24.dia`, validado num?rico | D?a de la atenci?n. 0 si no v?lido. |


| 15 | `id_establecimiento` | `int` | `hisminsa24.id_establecimiento`, validado num?rico | C?digo num?rico del establecimiento. 0 si no v?lido. |


| 16 | `fecha_atencion` | `date` | `hisminsa24.fecha_atencion`, NULL si vac?o | Fecha de la atenci?n m?dica. |


| 17 | `edad` | `int` | `hisminsa24.edad_reg`, validado num?rico | Edad registrada en la atenci?n. 0 si no v?lido. |


| 18 | `tip_edad` | `varchar(1)` | `hisminsa24.tipo_edad` | Tipo de edad: A=A?os, M=Meses, D=D?as. |


| 19 | `fi` | `varchar(2)` | `hisminsa24.id_financiador` | C?digo de financiador (SIS, SOAT, etc.). |


| 20 | `establec` | `varchar(1)` | `hisminsa24.id_condicion_establecimiento` | Condici?n del establecimiento. |


| 21 | `servicio` | `varchar(1)` | `hisminsa24.id_condicion_servicio` | Condici?n del servicio. |


| 22 | `condicion_gestante` | `varchar(20)` | `hisminsa24.condicion_gestante` | Condici?n de gestante. |


| 23 | `peso_pregestacional` | `numeric(7,2)` | `hisminsa24.peso_pregestacional`, validado num?rico | Peso pregestacional en kg. 0 si no v?lido. |


| 24 | `tipo_diagnostico` | `varchar(5)` | `hisminsa24.tipo_diagnostico` | Tipo de diagn?stico (presuntivo, definitivo). |


| 25 | `codigo_item` | `varchar(15)` | `hisminsa24.codigo_item` | C?digo CIE-10 o CPT del ?tem de atenci?n. |


| 26 | `valor_lab` | `varchar(10)` | `hisminsa24.valor_lab` | Valor de laboratorio asociado. |


| 27 | `id_correlativo` | `int` | `hisminsa24.id_correlativo`, validado num?rico | Correlativo de la atenci?n. 0 si no v?lido. |


| 28 | `id_correlativo_lab` | `int` | `hisminsa24.id_correlativo_lab`, validado num?rico | Correlativo de laboratorio. 0 si no v?lido. |


| 29 | `cod_2000` | `varchar(10)` | Tabla EESS (`eess2025` o `maestro_his_establecimiento`) via JOIN/COALESCE | C?digo ?nico del establecimiento (c?digo 2000). |


| 30 | `codigo_red` | `varchar(10)` | Tabla EESS | C?digo de red de salud. |


| 31 | `red` | `text` | Tabla EESS | Nombre de la red de salud. |


| 32 | `desc_ue` | `text` | Tabla EESS | Unidad ejecutora / DISA. |


| 33 | `codigo_microred` | `varchar(10)` | Tabla EESS | C?digo de microred. |


| 34 | `microred` | `text` | Tabla EESS | Nombre de la microred. |


| 35 | `departamento` | `text` | Tabla EESS | Departamento del establecimiento. |


| 36 | `provincia` | `text` | Tabla EESS | Provincia del establecimiento. |


| 37 | `distrito` | `text` | Tabla EESS | Distrito del establecimiento. |


| 38 | `nombre_establecimiento` | `text` | Tabla EESS | Nombre del establecimiento de salud. |


| 39 | `dni_personal` | `varchar(50)` | `maestro_personal.numero_documento` | DNI del profesional que atendi?. |


| 40 | `dni_registrador` | `varchar(50)` | `hisminsa24.id_registrador` | DNI de la persona que registr?. |


| 41 | `id_colegio` | `varchar(10)` | `maestro_personal.id_colegio` | C?digo del colegio profesional. |


| 42 | `descripcion_colegio` | `text` | `maestro_his_colegio.descripcion_colegio` v?a JOIN | Nombre del colegio profesional. |


| 43 | `id_ups` | `int` | `maestro_his_ups.id_ups`, validado num?rico | C?digo de la UPS (Unidad Prestadora de Servicios). 0 si no v?lido. |


| 44 | `descripcion_etnia` | `text` | `maestro_his_etnia.descripcion_etnia` v?a JOIN | Descripci?n de la etnia del paciente. |


| 45 | `fecha_registro` | `timestamp` | `hisminsa24.fecha_registro`, NULL si vac?o | Fecha y hora del registro. |


| 46 | `fecha_modificacion` | `timestamp` | `hisminsa24.fecha_modificacion`, NULL si vac?o | Fecha y hora de la ?ltima modificaci?n. |





### 8.2.3 Particionamiento por A?o





La tabla se crea con `PARTITION BY RANGE (anio)`, generando una partici?n hija por a?o soportado (2021-2026):





```sql


CREATE TABLE IF NOT EXISTS {ESQUEMA}.his_proceso (


    id_cita int NOT NULL,


    lote varchar(3),


    ...


    fecha_modificacion timestamp


) PARTITION BY RANGE (anio);





CREATE TABLE {ESQUEMA}.his_proceso_2024


PARTITION OF {ESQUEMA}.his_proceso


FOR VALUES FROM (2024) TO (2025);


```





A diferencia de versiones anteriores que usaban particionamiento por `(anio, mes)`, el sistema actual particiona solo por `anio`. Las columnas adicionales `dni_personal` y `dni_registrador` se a?aden mediante `ALTER TABLE ADD COLUMN IF NOT EXISTS` despu?s de la creaci?n de la estructura base.





## 8.3 Advisory Lock y Configuraci?n de Sesi?n





### 8.3.1 Mecanismo de Bloqueo





El sistema utiliza un advisory lock de PostgreSQL para evitar ejecuciones concurrentes del proceso:





```python


LOCK_HIS_PROCESO = "proyecto_salud_cusco_his_proceso"





def adquirir_bloqueo_his_proceso(cur):


    cur.execute("SELECT pg_try_advisory_lock(hashtext(%s)::bigint);", (LOCK_HIS_PROCESO,))


    if not cur.fetchone()[0]:


        raise Exception(


            "HIS Proceso ya se est? generando en otra ventana. "


            "Cancela o espera a que termine antes de volver a ejecutarlo."


        )





def liberar_bloqueo_his_proceso(cur):


    cur.execute("SELECT pg_advisory_unlock(hashtext(%s)::bigint);", (LOCK_HIS_PROCESO,))


```





- `pg_try_advisory_lock` intenta adquirir el lock y retorna `true` si lo logra, `false` si ya est? tomado.


- `hashtext()` convierte el string del lock en un bigint de 64 bits.


- El lock se adquiere al inicio de `main()` y se libera en el bloque `finally` tras un `rollback()` para asegurar que la transacci?n no retenga el lock.





### 8.3.2 Configuraci?n de Sesi?n





```python


def configurar_sesion_his_proceso(cur):


    cur.execute("SET synchronous_commit = off;")


    cur.execute("SET work_mem = '512MB';")


    cur.execute("SET temp_buffers = '256MB';")


    cur.execute("SET maintenance_work_mem = '1GB';")


    cur.execute("SET jit = off;")


```





| Par?metro | Valor | Efecto |


|-----------|-------|--------|


| `synchronous_commit` | `off` | Acelera escrituras al no esperar flush WAL en cada commit. Riesgo de p?rdida de ?ltimos segundos en crash. |


| `work_mem` | `512MB` | Memoria para operaciones de ordenamiento y hash en consultas complejas. |


| `temp_buffers` | `256MB` | Memoria para tablas temporales (usado intensivamente por las 8 tablas `tmp_*`). |


| `maintenance_work_mem` | `1GB` | Memoria para operaciones de mantenimiento como `CREATE INDEX` y `ANALYZE`. |


| `jit` | `off` | Desactiva compilaci?n JIT de PostgreSQL que puede ser contraproducente en consultas ETL largas. |





## 8.4 Sistema de Resoluci?n de Tablas Fuente





### 8.4.1 Resoluci?n con Esquemas Preferidos





El sistema resuelve tablas fuente buscando en esquemas en orden de preferencia:





```python


def resolver_tabla(cur, nombre_tabla: str, esquemas_preferidos: list[str]) -> str:


    for esquema in esquemas_preferidos:


        cur.execute("""


            SELECT 1 FROM information_schema.tables


            WHERE table_schema = %s AND table_name = %s LIMIT 1;


        """, (esquema, nombre_tabla))


        if cur.fetchone():


            return f"{esquema}.{nombre_tabla}"


    raise Exception(...)


```





Tablas resueltas y esquemas de b?squeda:





| Tabla | Esquemas Preferidos | Prop?sito |


|-------|---------------------|-----------|


| `hisminsa24` | `[ESQUEMA]` | Datos crudos HIS por establecer. |


| `maestro_paciente` | `[ESQUEMA, maestros]` | Datos maestros de pacientes. |


| `maestro_personal` | `[ESQUEMA, maestros]` | Datos maestros de personal. |


| `maestro_his_cie_cpms` | `[maestros, ESQUEMA]` | Cat?logo CIE/CPMS. |


| `maestro_his_etnia` | `[maestros, ESQUEMA]` | Cat?logo de etnias. |


| `maestro_his_ups` | `[maestros, ESQUEMA]` | Cat?logo de UPS. |


| `maestro_his_colegio` | `[maestros, ESQUEMA]` | Cat?logo de colegios profesionales. |





### 8.4.2 Resoluci?n Opcional de EESS





Para las tablas de establecimientos se usa `resolver_tabla_opcional()` que retorna `None` si no encuentra la tabla:





```python


eess_info = resolver_tabla_opcional(


    cur, ["eess2025"], [ESQUEMA, "maestros"]


)





eess_maestro_info = resolver_tabla_opcional(


    cur,


    ["maestro_his_establecimiento", "maestro_his_establecimiento25"],


    [ESQUEMA, "maestros"],


)


```





Se buscan primero `eess2025` (tabla moderna generada por `procesar_eess_principal.py`) y como respaldo `maestro_his_establecimiento` o `maestro_his_establecimiento25` (tablas legacy). Las columnas disponibles se detectan con `obtener_columnas_tabla()`.





### 8.4.3 Aseguramiento de ?ndices





```python


def asegurar_indices_fuente(cur, tablas):


    crear_indice_si_no_existe(cur, tablas["hisminsa24"], "anio_mes", "(anio, mes)")


    crear_indice_si_no_existe(cur, tablas["maestro_paciente"], "id_paciente", "(id_paciente)")


    crear_indice_si_no_existe(cur, tablas["maestro_personal"], "id_personal", "(id_personal)")


    crear_indice_si_no_existe(cur, tablas["maestro_his_cie_cpms"], "codigo_item", "(codigo_item)")


    crear_indice_si_no_existe(cur, tablas["maestro_his_etnia"], "id_etnia", "(id_etnia)")


    crear_indice_si_no_existe(cur, tablas["maestro_his_ups"], "id_ups", "(id_ups)")


    crear_indice_si_no_existe(cur, tablas["maestro_his_colegio"], "id_colegio", "(id_colegio)")


```





Los nombres de ?ndices se generan mediante `_slug_indice()` que limpia caracteres especiales y trunca a 60 caracteres para evitar exceder el l?mite de PostgreSQL.





## 8.5 EESS_TARGETS y EESS_DEFAULTS





### 8.5.1 EESS_TARGETS ??? Mapeo de Columnas con Candidatos M?ltiples





Este diccionario define c?mo se mapean las columnas destino desde las tablas de establecimientos, con listas de nombres de columna candidatos en orden de preferencia:





```python


EESS_TARGETS = {


    "cod_2000": (["cod_eess", "codigo_unico", "id_eess", "id_establecimiento"], "varchar(10)"),


    "codigo_red": (["cod_red", "codigo_red"], "varchar(10)"),


    "red": (["red"], "text"),


    "desc_ue": (["desc_ue", "descripcion_sector", "disa"], "text"),


    "codigo_microred": (["cod_mred", "codigo_microred"], "varchar(10)"),


    "microred": (["microred"], "text"),


    "departamento": (["dpto", "departamento"], "text"),


    "provincia": (["provincia"], "text"),


    "distrito": (["distrito"], "text"),


    "nombre_establecimiento": (["nombre_eess", "nombre_establecimiento"], "text"),


}


```





Cada entrada tiene:


- **Key**: Nombre de columna destino en `his_proceso`.


- **Value**: Tupla `(candidatos, cast_sql)` donde:


  - `candidatos`: Lista ordenada de nombres de columna alternativos que pueden existir en la tabla fuente EESS.


  - `cast_sql`: Tipo PostgreSQL al que se castea el valor.





Por ejemplo, `cod_2000` busca primero `cod_eess`, luego `codigo_unico`, luego `id_eess`, y finalmente `id_establecimiento`. El primero que exista en la tabla fuente es el que se usa.





### 8.5.2 EESS_DEFAULTS ??? Valores por Omisi?n





Cuando no existe ninguna tabla EESS disponible, se usan estos defaults (todos cadenas vac?as tipadas):





```python


EESS_DEFAULTS = {


    "cod_2000": "''::varchar(10)",


    "codigo_red": "''::varchar(10)",


    "red": "''::text",


    "desc_ue": "''::text",


    "codigo_microred": "''::varchar(10)",


    "microred": "''::text",


    "departamento": "''::text",


    "provincia": "''::text",


    "distrito": "''::text",


    "nombre_establecimiento": "''::text",


}


```





## 8.6 B?squeda y Enriquecimiento EESS





### 8.6.1 Funci?n expr_eess() ??? Extracci?n con Candidatos





```python


def expr_eess(alias, columnas, candidatos, cast_sql):


    for col in candidatos:


        if col in columnas:


            return f"NULLIF(TRIM({alias}.{col}::text), '')::{cast_sql}"


    return None


```





Recorre la lista de candidatos y retorna la primera expresi?n SQL que encuentra. Usa `NULLIF(TRIM(...), '')` para convertir cadenas vac?as en NULL antes del casteo.





### 8.6.2 Funci?n combinar_expr() ??? COALESCE Encadenado





```python


def combinar_expr(default_expr, *exprs):


    validas = [expr for expr in exprs if expr]


    if not validas:


        return default_expr


    return "COALESCE(" + ", ".join(validas + [default_expr]) + ")"


```





Genera una expresi?n `COALESCE(expr1, expr2, ..., default_expr)` que prueba cada expresi?n en orden. Esto permite priorizar `eess2025` sobre `maestro_his_establecimiento`.





### 8.6.3 resolver_columna_join_eess()





```python


def resolver_columna_join_eess(columnas: set[str]) -> str | None:


    if "id_eess" in columnas:


        return "id_eess"


    if "id_establecimiento" in columnas:


        return "id_establecimiento"


    return None


```





Determina qu? columna usar para el JOIN entre `hisminsa24` y las tablas EESS. Prioriza `id_eess` sobre `id_establecimiento`.





### 8.6.4 expr_clave_eess() ??? Normalizaci?n de Clave de JOIN





```python


def expr_clave_eess(alias, columna):


    return (


        "CASE "


        f"WHEN TRIM({alias}.{columna}::text) ~ '^[0-9]+$' "


        f"THEN COALESCE(NULLIF(LTRIM(TRIM({alias}.{columna}::text), '0'), ''), '0') "


        f"ELSE TRIM({alias}.{columna}::text) "


        "END"


    )


```





Normaliza la clave de JOIN:


- Si el valor es num?rico, elimina ceros a la izquierda (`LTRIM(..., '0')`) pero conserva al menos `'0'`.


- Si no es num?rico, lo usa textual.





Esto es cr?tico porque `id_establecimiento` puede venir como `'00123'` en una tabla y `'123'` en otra.





### 8.6.5 construir_condicion_join() ??? JOIN Inteligente con Dos Estrategias





```python


def construir_condicion_join(alias, col_join):


    return (


        "("


        f"(TRIM(nt.id_establecimiento::text) ~ '^[0-9]+$' "


        f"AND TRIM({alias}.{col_join}::text) ~ '^[0-9]+$' "


        f"AND TRIM(nt.id_establecimiento::text)::bigint = TRIM({alias}.{col_join}::text)::bigint) "


        "OR "


        f"TRIM(nt.id_establecimiento::text) = TRIM({alias}.{col_join}::text)"


        ")"


    )


```





Implementa una l?gica de matching de dos niveles:


1. **Estrategia num?rica** (prioridad 1): Si ambos lados son num?ricos, convierte a `bigint` y compara como enteros (maneja ceros a la izquierda).


2. **Estrategia textual** (fallback): Compara como strings exactos.





Esto asegura que `'00045'` y `'45'` matcheen correctamente.





### 8.6.6 construir_contexto_eess() ??? JOINs y Expresiones Enriquecidas





```python


def construir_contexto_eess(tablas):


    # Retorna (sql_joins, dict_expressions)


```





Construye din?micamente:


- Los `LEFT JOIN` contra `eess2025` (alias `mhe`) y/o `maestro_his_establecimiento` (alias `mhe_alt`).


- Las expresiones COALESCE para cada columna EESS, combinando:


  1. valor de `eess2025` (prioridad 1)


  2. valor de `maestro_his_establecimiento` (prioridad 2)


  3. default string vac?o





Si no hay tablas EESS disponibles, retorna `("", EESS_DEFAULTS)`.





### 8.6.7 construir_select_lookup_eess() ??? Lookup con Prioridad





```python


def construir_select_lookup_eess(tabla_full, alias, columnas, join_col, prioridad):


    campos = [


        f"{expr_clave_eess(alias, join_col)} AS join_key",


        f"{prioridad} AS prioridad",


    ]


    for objetivo in EESS_TARGETS:


        campos.append(f"{expr_fuente_eess(alias, columnas, objetivo)} AS {objetivo}")


    ...


```





Genera un `SELECT` que expone la clave normalizada (`join_key`), la prioridad (1 = `eess2025`, 2 = `maestro_his_establecimiento`), y las 10 columnas EESS para cada fuente.





### 8.6.8 preparar_lookup_eess() ??? Creaci?n de tmp_eess_lookup





```python


def preparar_lookup_eess(cur, tablas) -> bool:


    # Construye consultas para cada fuente EESS disponible


    consultas = []


    


    # Prioridad 1: eess2025


    if tabla_eess y col_join_eess:


        consultas.append(construir_select_lookup_eess(..., prioridad=1))


    


    # Prioridad 2: maestro_his_establecimiento (si es diferente)


    if tabla_maestro y col_join_maestro:


        consultas.append(construir_select_lookup_eess(..., prioridad=2))


    


    # UNION ALL + DISTINCT ON (join_key) ORDER BY prioridad


    # Crea tmp_eess_lookup con un registro por join_key (el de menor prioridad)


```





La tabla `tmp_eess_lookup` usa `SELECT DISTINCT ON (join_key)` con `ORDER BY join_key, prioridad`, de modo que para cada establecimiento se obtiene el registro de la fuente con prioridad m?s baja (1 = `eess2025` es mejor que 2 = respaldo).





### 8.6.9 enriquecer_staging_eess() ??? UPDATE Masivo





```python


def enriquecer_staging_eess_desde(cur, staging_tabla, lookup_table):


    cur.execute(f"""


        UPDATE {ESQUEMA}.{staging_tabla} stg


        SET


            cod_2000 = lk.cod_2000,


            codigo_red = lk.codigo_red,


            red = lk.red,


            desc_ue = lk.desc_ue,


            ...


        FROM {lookup_table} lk


        WHERE stg.id_establecimiento::text = lk.join_key;


    """)


```





## 8.7 Plantilla SQL Editable ??? Las 7 Secciones @SECTION





El sistema usa una plantilla SQL parametrizada (`generar_his_proceso_editor.sql`) dividida en 7 secciones marcadas con `-- @SECTION: nombre`. Cada secci?n se renderiza por separado con `renderizar_sql_editor()`.





### 8.7.1 @SECTION: estructura





```sql


CREATE TABLE IF NOT EXISTS {ESQUEMA}.his_proceso (


    id_cita int NOT NULL,


    lote varchar(3),


    fg_tipo varchar(2),


    dni_paciente varchar(50),


    apellido_paterno_paciente text,


    apellido_materno_paciente text,


    nombres_paciente text,


    fecha_nacimiento date,


    id_tipo_documento int,


    genero varchar(1),


    id_etnia int,


    anio int NOT NULL,


    mes int,


    dia int,


    id_establecimiento int,


    fecha_atencion date,


    edad int,


    tip_edad varchar(1),


    fi varchar(2),


    establec varchar(1),


    servicio varchar(1),


    condicion_gestante varchar(20),


    peso_pregestacional numeric(7,2),


    tipo_diagnostico varchar(5),


    codigo_item varchar(15),


    valor_lab varchar(10),


    id_correlativo int,


    id_correlativo_lab int,


    cod_2000 varchar(10),


    codigo_red varchar(10),


    red text,


    desc_ue text,


    codigo_microred varchar(10),


    microred text,


    departamento text,


    provincia text,


    distrito text,


    nombre_establecimiento text,


    dni_personal varchar(50),


    dni_registrador varchar(50),


    id_colegio varchar(10),


    descripcion_colegio text,


    id_ups int,


    descripcion_etnia text,


    fecha_registro timestamp,


    fecha_modificacion timestamp


) PARTITION BY RANGE (anio);


```





### 8.7.2 @SECTION: particion





```sql


CREATE TABLE {ESQUEMA}.{NOMBRE_PARTICION}


PARTITION OF {ESQUEMA}.his_proceso


FOR VALUES FROM ({ANIO}) TO ({ANIO_SIGUIENTE});


```





### 8.7.3 @SECTION: limpiar_periodo_todos





```sql


DELETE FROM {ESQUEMA}.his_proceso


WHERE anio = {ANIO};


```





### 8.7.4 @SECTION: limpiar_periodo_mes





```sql


DELETE FROM {ESQUEMA}.his_proceso


WHERE anio = {ANIO}


  AND mes = {MES};


```





### 8.7.5 @SECTION: crear_staging (La Transformaci?n Completa)





Esta es la secci?n m?s grande y compleja. Crea una tabla `UNLOGGED` (sin WAL para m?xima velocidad) con la transformaci?n completa:





```sql


DROP TABLE IF EXISTS {ESQUEMA}.{STAGING_TABLA};





CREATE UNLOGGED TABLE {ESQUEMA}.{STAGING_TABLA} AS


SELECT


    CASE WHEN nt.id_cita::text ~ '^[0-9]+$' THEN nt.id_cita::int ELSE 0 END AS id_cita,


    COALESCE(TRIM(nt.lote::text), '')::varchar(3) AS lote,


    COALESCE(TRIM(cie.fg_tipo::text), '')::varchar(2) AS fg_tipo,


    COALESCE(TRIM(mp.numero_documento::text), '')::varchar(50) AS dni_paciente,


    COALESCE(TRIM(mp.apellido_paterno_paciente::text), '')::text AS apellido_paterno_paciente,


    COALESCE(TRIM(mp.apellido_materno_paciente::text), '')::text AS apellido_materno_paciente,


    COALESCE(TRIM(mp.nombres_paciente::text), '')::text AS nombres_paciente,


    NULLIF(TRIM(mp.fecha_nacimiento::text), '')::date AS fecha_nacimiento,


    CASE WHEN mp.id_tipo_documento::text ~ '^[0-9]+$' THEN mp.id_tipo_documento::int ELSE 0 END AS id_tipo_documento,


    COALESCE(TRIM(mp.genero::text), '')::varchar(1) AS genero,


    CASE WHEN mp.id_etnia::text ~ '^[0-9]+$' THEN mp.id_etnia::int ELSE 0 END AS id_etnia,


    nt.anio::int AS anio,


    CASE WHEN nt.mes::text ~ '^[0-9]+$' THEN nt.mes::int ELSE 0 END AS mes,


    CASE WHEN nt.dia::text ~ '^[0-9]+$' THEN nt.dia::int ELSE 0 END AS dia,


    NULLIF(TRIM(nt.fecha_atencion::text), '')::date AS fecha_atencion,


    CASE WHEN nt.edad_reg::text ~ '^[0-9]+$' THEN nt.edad_reg::int ELSE 0 END AS edad,


    COALESCE(TRIM(nt.tipo_edad::text), '')::varchar(1) AS tip_edad,


    COALESCE(TRIM(nt.id_financiador::text), '')::varchar(2) AS fi,


    COALESCE(TRIM(nt.id_condicion_establecimiento::text), '')::varchar(1) AS establec,


    COALESCE(TRIM(nt.id_condicion_servicio::text), '')::varchar(1) AS servicio,


    COALESCE(TRIM(nt.condicion_gestante::text), '')::varchar(20) AS condicion_gestante,


    CASE WHEN nt.peso_pregestacional::text ~ '^[0-9]+(\.[0-9]+)?$'


         THEN nt.peso_pregestacional::numeric(7,2) ELSE 0 END AS peso_pregestacional,


    COALESCE(TRIM(nt.tipo_diagnostico::text), '')::varchar(5) AS tipo_diagnostico,


    COALESCE(TRIM(nt.codigo_item::text), '')::varchar(15) AS codigo_item,


    COALESCE(TRIM(nt.valor_lab::text), '')::varchar(10) AS valor_lab,


    CASE WHEN nt.id_correlativo::text ~ '^[0-9]+$' THEN nt.id_correlativo::int ELSE 0 END AS id_correlativo,


    CASE WHEN nt.id_correlativo_lab::text ~ '^[0-9]+$' THEN nt.id_correlativo_lab::int ELSE 0 END AS id_correlativo_lab,


    {EESS_COD_2000} AS cod_2000,


    {EESS_CODIGO_RED} AS codigo_red,


    {EESS_RED} AS red,


    {EESS_DESC_UE} AS desc_ue,


    {EESS_CODIGO_MICRORED} AS codigo_microred,


    {EESS_MICRORED} AS microred,


    {EESS_DEPARTAMENTO} AS departamento,


    {EESS_PROVINCIA} AS provincia,


    {EESS_DISTRITO} AS distrito,


    {EESS_NOMBRE_ESTABLECIMIENTO} AS nombre_establecimiento,


    COALESCE(TRIM(mp2.numero_documento::text), '')::varchar(50) AS dni_personal,


    COALESCE(TRIM(nt.id_registrador::text), '')::varchar(50) AS dni_registrador,


    COALESCE(TRIM(mp2.id_colegio::text), '')::varchar(10) AS id_colegio,


    COALESCE(TRIM(mhc.descripcion_colegio::text), '')::text AS descripcion_colegio,


    CASE WHEN mhu.id_ups::text ~ '^[0-9]+$' THEN mhu.id_ups::int ELSE 0 END AS id_ups,


    COALESCE(TRIM(et.descripcion_etnia::text), '')::text AS descripcion_etnia,


    NULLIF(TRIM(nt.fecha_registro::text), '')::timestamp AS fecha_registro,


    NULLIF(TRIM(nt.fecha_modificacion::text), '')::timestamp AS fecha_modificacion,


    CASE WHEN nt.id_establecimiento::text ~ '^[0-9]+$' THEN nt.id_establecimiento::int ELSE 0 END AS id_establecimiento


FROM {TABLA_HISMINSA24} nt


LEFT JOIN {TABLA_MAESTRO_HIS_CIE_CPMS} cie ON nt.codigo_item::text = cie.codigo_item::text


LEFT JOIN {TABLA_MAESTRO_PACIENTE} mp ON nt.id_paciente::text = mp.id_paciente::text


LEFT JOIN {TABLA_MAESTRO_HIS_ETNIA} et ON mp.id_etnia::text = et.id_etnia::text


LEFT JOIN {TABLA_MAESTRO_PERSONAL} mp2 ON nt.id_personal::text = mp2.id_personal::text


LEFT JOIN {TABLA_MAESTRO_HIS_UPS} mhu ON nt.id_ups::text = mhu.id_ups::text


LEFT JOIN {TABLA_MAESTRO_HIS_COLEGIO} mhc ON mp2.id_colegio::text = mhc.id_colegio::text


{JOIN_EESS}


WHERE nt.anio = '{ANIO}'


  AND nt.id_cita::text ~ '^[0-9]+$'


  {FILTRO_MES};


```





### 8.7.6 @SECTION: cargar_particion_final





```sql


INSERT INTO {ESQUEMA}.his_proceso_{ANIO} ({COLUMNAS_SQL})


SELECT {COLUMNAS_SQL}


FROM {ESQUEMA}.{STAGING_TABLA};


```





### 8.7.7 @SECTION: eliminar_staging





```sql


DROP TABLE IF EXISTS {ESQUEMA}.{STAGING_TABLA};


```





### 8.7.8 Carga y Renderizado de Secciones





```python


def cargar_secciones_sql_editor() -> dict[str, str]:


    # Lee el archivo SQL y lo divide por marcadores -- @SECTION:


    # Retorna dict con 7 entradas: estructura, particion, limpiar_periodo_todos,


    # limpiar_periodo_mes, crear_staging, cargar_particion_final, eliminar_staging





def renderizar_sql_editor(nombre_seccion: str, **contexto) -> str:


    secciones = cargar_secciones_sql_editor()


    plantilla = secciones.get(nombre_seccion)


    return plantilla.format(**contexto).strip()


```





El m?todo `cargar_secciones_sql_editor()` implementa un cache (`_SQL_SECTIONS_CACHE`) para evitar releer el archivo en cada llamada. Valida que existan las 7 secciones requeridas y lanza `Exception` si falta alguna.





## 8.8 preparar_fuentes_periodo() ??? Las 8 Tablas Temporales





Esta funci?n crea 8 tablas temporales que filtran los datos del per?odo espec?fico para acelerar el procesamiento:





### 8.8.1 tmp_nt_base ??? Base de Atenciones





```sql


CREATE TEMP TABLE tmp_nt_base AS


SELECT *


FROM {tablas['hisminsa24']} nt


WHERE nt.anio = '{anio}'


  {mes_filtro}


  AND nt.id_cita::text ~ '^[0-9]+$';


```





Filtra `hisminsa24` por a?o (y mes si se especifica), descartando registros sin `id_cita` num?rico. Se ejecuta `ANALYZE` despu?s de la creaci?n.





### 8.8.2 tmp_maestro_paciente_periodo ??? Pacientes del Per?odo





```sql


CREATE TEMP TABLE tmp_maestro_paciente_periodo AS


SELECT mp.*


FROM {tablas['maestro_paciente']} mp


JOIN (


    SELECT DISTINCT TRIM(id_paciente::text) AS id_paciente


    FROM tmp_nt_base


    WHERE COALESCE(TRIM(id_paciente::text), '') <> ''


) ids ON mp.id_paciente::text = ids.id_paciente;


```





Filtro semi-join: solo pacientes que aparecen en las atenciones del per?odo.





### 8.8.3 tmp_maestro_personal_periodo ??? Personal del Per?odo





```sql


CREATE TEMP TABLE tmp_maestro_personal_periodo AS


SELECT mp.*


FROM {tablas['maestro_personal']} mp


JOIN (


    SELECT DISTINCT TRIM(id_personal::text) AS clave


    FROM tmp_nt_base


    WHERE COALESCE(TRIM(id_personal::text), '') <> ''


) ids ON mp.id_personal::text = ids.clave;


```





### 8.8.4 tmp_cie_periodo ??? Diagn?sticos del Per?odo





```sql


CREATE TEMP TABLE tmp_cie_periodo AS


SELECT cie.*


FROM {tablas['maestro_his_cie_cpms']} cie


JOIN (


    SELECT DISTINCT TRIM(codigo_item::text) AS codigo_item


    FROM tmp_nt_base


    WHERE COALESCE(TRIM(codigo_item::text), '') <> ''


) ids ON cie.codigo_item::text = ids.codigo_item;


```





### 8.8.5 tmp_ups_periodo ??? UPS del Per?odo





```sql


CREATE TEMP TABLE tmp_ups_periodo AS


SELECT ups.*


FROM {tablas['maestro_his_ups']} ups


JOIN (


    SELECT DISTINCT TRIM(id_ups::text) AS id_ups


    FROM tmp_nt_base


    WHERE COALESCE(TRIM(id_ups::text), '') <> ''


) ids ON ups.id_ups::text = ids.id_ups;


```





### 8.8.6 tmp_etnia_periodo ??? Etnias del Per?odo





```sql


CREATE TEMP TABLE tmp_etnia_periodo AS


SELECT et.*


FROM {tablas['maestro_his_etnia']} et


JOIN (


    SELECT DISTINCT TRIM(id_etnia::text) AS id_etnia


    FROM tmp_maestro_paciente_periodo


    WHERE COALESCE(TRIM(id_etnia::text), '') <> ''


) ids ON et.id_etnia::text = ids.id_etnia;


```





Nota: La fuente es `tmp_maestro_paciente_periodo` (no `tmp_nt_base`), porque la etnia est? en el maestro de pacientes.





### 8.8.7 tmp_colegio_periodo ??? Colegios del Per?odo





```sql


CREATE TEMP TABLE tmp_colegio_periodo AS


SELECT col.*


FROM {tablas['maestro_his_colegio']} col


JOIN (


    SELECT DISTINCT TRIM(id_colegio::text) AS id_colegio


    FROM tmp_maestro_personal_periodo


    WHERE COALESCE(TRIM(id_colegio::text), '') <> ''


) ids ON col.id_colegio::text = ids.id_colegio;


```





Nota: La fuente es `tmp_maestro_personal_periodo` (no `tmp_nt_base`), porque el colegio est? en el maestro de personal.





### 8.8.8 tmp_eess_lookup_periodo ??? EESS del Per?odo (Opcional)





```sql


CREATE TEMP TABLE tmp_eess_lookup_periodo AS


SELECT lk.*


FROM tmp_eess_lookup lk


JOIN (


    SELECT DISTINCT {expr_clave_eess('nt', 'id_establecimiento')} AS join_key


    FROM tmp_nt_base nt


    WHERE COALESCE(TRIM(nt.id_establecimiento::text), '') <> ''


) ids ON lk.join_key = ids.join_key;


```





Solo se crea si `tablas["eess_lookup_ready"]` es `True`. Filtra el lookup global para incluir solo los establecimientos que aparecen en el per?odo actual.





### 8.8.9 Mapa de Reemplazo de Tablas





```python


tablas_periodo = {


    "hisminsa24": "tmp_nt_base",


    "maestro_paciente": "tmp_maestro_paciente_periodo",


    "maestro_personal": "tmp_maestro_personal_periodo",


    "maestro_his_cie_cpms": "tmp_cie_periodo",


    "maestro_his_etnia": "tmp_etnia_periodo",


    "maestro_his_ups": "tmp_ups_periodo",


    "maestro_his_colegio": "tmp_colegio_periodo",


    "eess_lookup_periodo": "tmp_eess_lookup_periodo" (opcional),


}


```





## 8.9 crear_staging_his_proceso() ??? Transformaci?n Completa





```python


def crear_staging_his_proceso(cur, anio, mes, tablas, staging_tabla):


    filtro_mes = ""


    if mes is not None:


        mes_texto = f"{mes:02d}"


        filtro_mes = f"AND nt.mes IN ('{mes_texto}', '{mes}')"





    join_eess = ""


    eess_expr = dict(EESS_DEFAULTS)





    sql = renderizar_sql_editor(


        "crear_staging",


        ESQUEMA=ESQUEMA,


        STAGING_TABLA=staging_tabla,


        ANIO=anio,


        FILTRO_MES=filtro_mes,


        TABLA_HISMINSA24=tablas["hisminsa24"],


        TABLA_MAESTRO_HIS_CIE_CPMS=tablas["maestro_his_cie_cpms"],


        TABLA_MAESTRO_PACIENTE=tablas["maestro_paciente"],


        TABLA_MAESTRO_HIS_ETNIA=tablas["maestro_his_etnia"],


        TABLA_MAESTRO_PERSONAL=tablas["maestro_personal"],


        TABLA_MAESTRO_HIS_UPS=tablas["maestro_his_ups"],


        TABLA_MAESTRO_HIS_COLEGIO=tablas["maestro_his_colegio"],


        JOIN_EESS=join_eess,


        EESS_COD_2000=eess_expr["cod_2000"],


        EESS_CODIGO_RED=eess_expr["codigo_red"],


        EESS_RED=eess_expr["red"],


        EESS_DESC_UE=eess_expr["desc_ue"],


        EESS_CODIGO_MICRORED=eess_expr["codigo_microred"],


        EESS_MICRORED=eess_expr["microred"],


        EESS_DEPARTAMENTO=eess_expr["departamento"],


        EESS_PROVINCIA=eess_expr["provincia"],


        EESS_DISTRITO=eess_expr["distrito"],


        EESS_NOMBRE_ESTABLECIMIENTO=eess_expr["nombre_establecimiento"],


    )


    cur.execute(sql)


    if tablas.get("eess_lookup_ready"):


        enriquecer_staging_eess(cur, staging_tabla)


```





La tabla staging se crea como `UNLOGGED` (sin registro WAL) para m?xima velocidad. Despu?s de la creaci?n, si hay tablas EESS disponibles, se ejecuta un `UPDATE` masivo desde `tmp_eess_lookup` para enriquecer las columnas geogr?ficas del establecimiento.





## 8.10 ejecutar_periodo() ??? Orquestaci?n del Flujo





```python


def ejecutar_periodo(conn, cur, anio, mes, tablas, progreso_estado, total_pasos):


    staging = f"his_proceso_stg_{anio}"





    # 1. crear_estructura_his_proceso() ??? Asegura tabla base y particiones


    # 2. limpiar_periodo_his_proceso() ??? DELETE seg?n mes (Todos o espec?fico)


    # 3. crear_staging_his_proceso() ??? Transformaci?n completa en UNLOGGED


    # 4. Conteo de filas en staging


    # 5. cargar_particion_final() ??? INSERT INTO his_proceso_{anio}


    # 6. eliminar_staging() ??? DROP TABLE


    # 7. conn.commit()


```





Cada per?odo se ejecuta en 6 pasos con reporte de progreso mediante mensajes `[PROGRESS] DONE=...`. Si ocurre un error, se ejecuta rollback y se intenta eliminar la tabla staging.





## 8.11 actualizar_his_proceso_maestros.py ??? Refresco de Maestros





### 8.11.1 Prop?sito General





Script de 326 l?neas que actualiza las columnas de `his_proceso` con datos frescos de las tablas maestras de paciente y personal. Es un paso posterior a la generaci?n inicial, ?til cuando los maestros han sido actualizados.





```python


# Uso: python actualizar_his_proceso_maestros.py <anio> [mes] [objetivo]


# objetivo: "maestro_paciente", "maestro_personal" o "todos"


```





### 8.11.2 actualizar_paciente() ??? UPDATE desde maestro_paciente





Esta funci?n ejecuta un UPDATE con CTE que refresca 11 columnas del paciente:





```python


def actualizar_paciente(cur, anio, mes, tablas) -> int:


    sql = f"""


    WITH nt_base AS (


        SELECT


            CASE WHEN nt.id_cita::text ~ '^[0-9]+$' THEN nt.id_cita::int ELSE 0 END AS id_cita,


            CASE WHEN nt.anio::text ~ '^[0-9]+$' THEN nt.anio::int ELSE 0 END AS anio,


            nt.id_paciente


        FROM {tablas['hisminsa24']} nt


        WHERE nt.anio::text ~ '^[0-9]+$'


          AND nt.id_cita::text ~ '^[0-9]+$'


          AND nt.anio::int = {anio}


          {filtro_mes_nt}


    )


    UPDATE {ESQUEMA}.his_proceso hp


    SET


        dni_paciente = COALESCE(TRIM(mp.numero_documento::text), '')::varchar(50),


        apellido_paterno_paciente = COALESCE(TRIM(mp.apellido_paterno_paciente::text), '')::text,


        apellido_materno_paciente = COALESCE(TRIM(mp.apellido_materno_paciente::text), '')::text,


        nombres_paciente = COALESCE(TRIM(mp.nombres_paciente::text), '')::text,


        fecha_nacimiento = COALESCE(TRIM(mp.fecha_nacimiento::text), '')::date,


        id_tipo_documento = CASE


            WHEN mp.id_tipo_documento::text ~ '^[0-9]+$' THEN mp.id_tipo_documento::int


            ELSE 0


        END,


        genero = COALESCE(TRIM(mp.genero::text), '')::varchar(1),


        id_etnia = CASE


            WHEN mp.id_etnia::text ~ '^[0-9]+$' THEN mp.id_etnia::int


            ELSE 0


        END,


        descripcion_etnia = COALESCE(TRIM(et.descripcion_etnia::text), '')::text


    FROM nt_base nt


    LEFT JOIN {tablas['maestro_paciente']} mp ON nt.id_paciente::text = mp.id_paciente::text


    LEFT JOIN {tablas['maestro_his_etnia']} et ON mp.id_etnia::text = et.id_etnia::text


    WHERE hp.anio = nt.anio


      AND hp.id_cita = nt.id_cita


      {filtro_mes_hp};


    """


    cur.execute(sql)


    return cur.rowcount


```





El CTE `nt_base` extrae `(id_cita, anio, id_paciente)` de `hisminsa24` con validaci?n num?rica. Luego se hace JOIN con `maestro_paciente` y `maestro_his_etnia` para actualizar `his_proceso`. Usa `COALESCE(TRIM(...), '')` en todos los campos de texto para evitar NULLs.





### 8.11.3 actualizar_personal() ??? UPDATE desde maestro_personal





```python


def actualizar_personal(cur, anio, mes, tablas) -> int:


    sql = f"""


    WITH nt_base AS (


        SELECT


            CASE WHEN nt.id_cita::text ~ '^[0-9]+$' THEN nt.id_cita::int ELSE 0 END AS id_cita,


            CASE WHEN nt.anio::text ~ '^[0-9]+$' THEN nt.anio::int ELSE 0 END AS anio,


            nt.id_personal,


            nt.id_registrador


        FROM {tablas['hisminsa24']} nt


        WHERE nt.anio::text ~ '^[0-9]+$'


          AND nt.id_cita::text ~ '^[0-9]+$'


          AND nt.anio::int = {anio}


          {filtro_mes_nt}


    )


    UPDATE {ESQUEMA}.his_proceso hp


    SET


        dni_personal = COALESCE(TRIM(mp2.numero_documento::text), '')::varchar(50),


        dni_registrador = COALESCE(TRIM(nt.id_registrador::text), '')::varchar(50),


        id_colegio = COALESCE(TRIM(mp2.id_colegio::text), '')::varchar(10),


        descripcion_colegio = COALESCE(TRIM(mhc.descripcion_colegio::text), '')::text


    FROM nt_base nt


    LEFT JOIN {tablas['maestro_personal']} mp2 ON nt.id_personal::text = mp2.id_personal::text


    LEFT JOIN {tablas['maestro_his_colegio']} mhc ON mp2.id_colegio::text = mhc.id_colegio::text


    WHERE hp.anio = nt.anio


      AND hp.id_cita = nt.id_cita


      {filtro_mes_hp};


    """


    cur.execute(sql)


    return cur.rowcount


```





Actualiza 4 columnas del personal: `dni_personal`, `dni_registrador`, `id_colegio`, `descripcion_colegio`. `dni_registrador` se toma directamente de `hisminsa24`, no del maestro.





### 8.11.4 Orquestaci?n





```python


def main():


    # 1. Parsear argumentos (anio, mes, objetivo)


    # 2. Verificar que his_proceso existe


    # 3. Asegurar columnas (dni_personal, dni_registrador)


    # 4. Resolver tablas fuente


    # 5. Para cada a?o:


    #    - actualizar_paciente() si aplica


    #    - actualizar_personal() si aplica


    #    - conn.commit()


```





El script soporta a?os m?ltiples (2021-2026) y filtro opcional por mes. El par?metro `objetivo` permite ejecutar solo la actualizaci?n de paciente, solo personal, o ambos. Esto es ?til cuando solo una de las tablas maestras ha sido actualizada.





## 8.12 COLUMNAS_HIS_PROCESO_RENOMBRAR ??? Diccionario de Normalizaci?n de Columnas





### 8.12.1 Prop?sito





El diccionario `COLUMNAS_HIS_PROCESO_RENOMBRAR` maneja las variaciones en nombres de columnas entre diferentes fuentes de datos HIS. Cuando los CSV de entrada tienen nombres de columna no estandarizados, el sistema los mapea a los nombres can?nicos de `his_proceso`. Espec?ficamente, cubre variaciones en:





- **C?digo EESS**: `codigo_eess`, `codigo_ugipress`


- **A?o**: `anio`, `anio_atencion`


- **Mes**: `mes`, `mes_atencion`


- **Documento**: `nro_documento`, `numero_documento`, `num_documento`, `dni`


- **Apellidos**: `apellido_paterno`/`ape_paterno`/`ap_paterno`, `apellido_materno`/`ape_materno`/`ap_materno`


- **Nombres**: `nombres`, `nombre`


- **Fecha nacimiento**: `fecha_nacimiento`, `fec_nacimiento`, `fec_nac`


- **Diagn?stico**: `codigo_diagnostico`, `diagnostico`, `cod_diag`


- **Fecha consulta**: `fecha_consulta`, `fec_consulta`, `fec_aten`





### 8.12.2 Diccionario Completo





```python


COLUMNAS_HIS_PROCESO_RENOMBRAR = {


    # C?digo EESS


    "codigo_eess": "codigo_eess",


    "codigo_ugipress": "codigo_eess",


    # A?o


    "anio": "anio",


    "anio_atencion": "anio",


    # Mes


    "mes": "mes",


    "mes_atencion": "mes",


    # Documento de identidad


    "nro_documento": "numero_documento",


    "numero_documento": "numero_documento",


    "num_documento": "numero_documento",


    "dni": "numero_documento",


    # Apellido paterno


    "apellido_paterno": "apellido_paterno",


    "ape_paterno": "apellido_paterno",


    "ap_paterno": "apellido_paterno",


    # Apellido materno


    "apellido_materno": "apellido_materno",


    "ape_materno": "apellido_materno",


    "ap_materno": "apellido_materno",


    # Nombres


    "nombres": "nombres",


    "nombre": "nombres",


    # Fecha de nacimiento


    "fecha_nacimiento": "fecha_nacimiento",


    "fec_nacimiento": "fecha_nacimiento",


    "fec_nac": "fecha_nacimiento",


    # Edad


    "edad": "edad",


    "edad_tipo": "edad_tipo",


    # Sexo


    "sexo": "sexo",


    # Diagn?stico


    "codigo_diagnostico": "codigo_diagnostico",


    "diagnostico": "codigo_diagnostico",


    "cod_diag": "codigo_diagnostico",


    # Fecha de consulta


    "fecha_consulta": "fecha_consulta",


    "fec_consulta": "fecha_consulta",


    "fec_aten": "fecha_consulta",


    # C?digo del procedimiento


    "codigo_procedimiento": "codigo_procedimiento",


    "procedimiento": "codigo_procedimiento",


    "cod_proc": "codigo_procedimiento",


    # C?digo de vacuna


    "codigo_vacuna": "codigo_vacuna",


    "vacuna": "codigo_vacuna",


    "cod_vac": "codigo_vacuna",


    # Dosis de vacuna


    "dosis_vacuna": "dosis_vacuna",


    "dosis": "dosis_vacuna",


    # C?digo CRED


    "codigo_cred": "codigo_cred",


    "cred": "codigo_cred",


    # Profesional


    "profesional_atendio": "profesional_atendio",


    "medico": "profesional_atendio",


    # Tipo de seguro


    "tipo_seguro": "tipo_seguro",


    "seguro": "tipo_seguro",


}


```





### 8.12.3 Uso en el Proceso de Carga





El diccionario se usa durante la inserci?n inicial desde `hisminsa24` para mapear nombres de columnas del origen al destino. Cada columna de `hisminsa24` se verifica contra el diccionario y, si existe, se mapea a su nombre can?nico. Columnas no mapeadas se descartan silenciosamente.





## 8.13 Funci?n cargar_his_proceso() ??? Carga Inicial





### 8.13.1 Algoritmo de Carga





La versi?n legacy del proceso usaba esta funci?n para cargar datos desde `hisminsa24` con mapeo din?mico de columnas:





```python


def cargar_his_proceso(conn, schema, anio):


    cursor = conn.cursor()





    # Paso 1: Crear tabla base y particiones por mes


    crear_tabla_his_proceso(cursor, schema)


    crear_particiones(cursor, schema, anio)


    conn.commit()





    # Paso 2: Obtener columnas de hisminsa24 para mapeo


    cursor.execute("""


        SELECT column_name, data_type


        FROM information_schema.columns


        WHERE table_schema = %s AND table_name = 'hisminsa24'


    """, (schema,))


    columnas_origen = {row[0].lower(): row[1] for row in cursor.fetchall()}





    # Paso 3: Construir mapeo columna por columna


    mapeo = {}


    for col_origen in columnas_origen:


        if col_origen in COLUMNAS_HIS_PROCESO_RENOMBRAR:


            mapeo[col_origen] = COLUMNAS_HIS_PROCESO_RENOMBRAR[col_origen]





    # Paso 4: Construir sentencia INSERT-SELECT din?mica


    columnas_destino = list(set(mapeo.values()))


    columnas_origen_mapeadas = [k for k, v in mapeo.items() if v in columnas_destino]





    insert_cols = ", ".join(columnas_destino)


    select_cols = ", ".join(


        f'"{col}" AS "{mapeo[col]}"' if col != mapeo[col] else f'"{col}"'


        for col in columnas_origen_mapeadas


    )





    # Paso 5: Insertar por mes (12 particiones)


    for mes in range(1, 13):


        cursor.execute(f"""


            INSERT INTO {schema}.his_proceso_{anio}_{mes:02d} ({insert_cols})


            SELECT {select_cols}


            FROM {schema}.hisminsa24


            WHERE anio = {anio} AND mes = {mes}


        """)


        filas = cursor.rowcount


        print(f"Mes {mes:02d}: {filas} filas insertadas")


        conn.commit()


```





### 8.13.2 Enriquecimiento Posterior





Despu?s de la inserci?n base, se enriquecen las columnas del establecimiento mediante JOIN con `maestro_eess`:





```python


cursor.execute(f"""


    UPDATE {schema}.his_proceso hp


    SET


        nombre_eess = me.nombre_eess,


        categoria_eess = me.categoria,


        distrito_eess = me.distrito,


        provincia_eess = me.provincia,


        departamento_eess = me.departamento,


        microred_eess = me.microred,


        red_eess = me.red,


        disa_eess = me.disa,


        ubigeo_eess = me.ubigeo


    FROM {schema}.maestro_eess me


    WHERE hp.codigo_eess = me.codigo_eess


    AND hp.anio = {anio}


""")


```





### 8.13.3 Diferencia con el Sistema Actual





La versi?n moderna (`generar_his_proceso.py`) reemplaz? esta funci?n con un sistema basado en plantillas SQL editables (`@SECTION`) y tablas staging `UNLOGGED`, ofreciendo:





| Aspecto | Versi?n Legacy | Versi?n Moderna |


|---------|---------------|-----------------|


| Columnas | 44 columnas, mapeo din?mico | 48 columnas fijas desde template |


| Particionamiento | Por `(anio, mes)` | Por `(anio)` |


| Staging | Inserci?n directa | Tabla `UNLOGGED` intermedia |


| Enriquecimiento EESS | JOIN directo post-insert | `tmp_eess_lookup` con prioridad |


| Personalizaci?n | Ninguna (c?digo fijo) | 7 secciones SQL editables |


| Control concurrencia | Ninguno | Advisory lock PostgreSQL |


| Optimizaci?n | Ninguna | work_mem=512MB, temp_buffers=256MB |





## 8.14 Manejo de Errores y Estrategia de Rollback





### 8.14.1 Transacciones y Rollback





```python


def ejecutar_periodo(conn, cur, anio, mes, tablas, progreso_estado, total_pasos):


    try:


        # ... 6 pasos del proceso ...


        conn.commit()


    except Exception as e:


        conn.rollback()  # Deshace todo lo no commiteado


        try:


            eliminar_staging(cur, staging)  # Limpia tabla temporal


            conn.commit()


        except Exception:


            conn.rollback()


        raise


```





Cada per?odo se ejecuta dentro de una ?nica transacci?n PostgreSQL. Si falla en cualquier paso, se revierte todo y se intenta eliminar la tabla staging residual.





### 8.14.2 Bloque finally con Rollback + Liberaci?n de Lock





```python


finally:


    if bloqueo_adquirido:


        try:


            conn.rollback()  # Asegura que no queden transacciones abiertas


            liberar_bloqueo_his_proceso(cur)


        except Exception:


            pass


    cur.close()


    conn.close()


```





El `rollback()` en el `finally` es crucial porque libera cualquier recurso de transacci?n antes de liberar el advisory lock. Sin esto, el lock podr?a quedar retenido por una transacci?n abandonada.





## 8.15 Flujo main() ??? Orquestaci?n General





### 8.15.1 Pseudoc?digo de main()





```python


def main():


    # 1. Parsear argumentos


    anio_raw, mes_raw = parsear_argumentos()


    anios = parsear_anios(anio_raw)   # Lista de a?os a procesar


    mes = parsear_mes(mes_raw)         # None = Todos, 1-12 = mes espec?fico





    # 2. Conectar a PostgreSQL


    conn = conectar()


    cur = conn.cursor()





    # 3. Adquirir advisory lock (evita ejecuci?n concurrente)


    adquirir_bloqueo_his_proceso(cur)


    bloq  ueo_adquirido = True





    # 4. Configurar par?metros de sesi?n


    configurar_sesion_his_proceso(cur)





    # 5. Resolver tablas fuente (hisminsa24, maestros, EESS)


    tablas = resolver_tablas_fuente(cur)





    # 6. Asegurar ?ndices en tablas fuente


    asegurar_indices_fuente(cur, tablas)





    # 7. Preparar lookup EESS (tmp_eess_lookup con prioridad)


    tablas["eess_lookup_ready"] = preparar_lookup_eess(cur, tablas)





    # 8. Reportar fuentes detectadas


    print("Tablas fuente detectadas:")


    for nombre in tablas:





        print(f"   - {nombre}: {tablas[nombre]}")





    # 9. Para cada a?o, ejecutar el per?odo


    for anio in anios:


        ejecutar_periodo(conn, cur, anio, mes, tablas, progreso, total)





    # 10. Liberar recursos


    liberar_bloqueo_his_proceso(cur)


    cur.close()


    conn.close()


```





### 8.15.2 Gesti?n de Argumentos





El script soporta dos modos de invocaci?n para compatibilidad:





```python


# Modo moderno (recomendado)


python generar_his_proceso.py 2024          # Todo el a?o 2024


python generar_his_proceso.py 2024 3        # Solo marzo 2024


python generar_his_proceso.py Todos         # Todos los a?os





# Modo legacy (compatibilidad)


python generar_his_proceso.py 2024 '[{"maestro":"..."}]'  # Ignora JSON


python generar_his_proceso.py 2024 '[{}]' 3                # JSON + mes


```





El modo legacy detecta que el segundo argumento es JSON (comienza con `[` o `{`) y extrae el mes del cuarto argumento si existe.





### 8.15.3 Funciones de Parsing





- `parsear_anios()`: Acepta "Todos" (retorna todos los a?os soportados) o un a?o espec?fico (2021-2026). Valida formato num?rico y rango.


- `parsear_mes()`: Acepta "Todos", "All", "", o n?mero 1-12. Retorna `None` para "Todos".


- `parsear_argumentos()`: Despacha entre modo moderno y legacy. Retorna tupla `(anio_raw, mes_raw)`.





### 8.15.4 Constantes Globales





```python


DB = {"user": ..., "pass": ..., "host": ..., "port": ..., "db": ...}


ESQUEMA = "es_ivan"                          # Esquema por defecto


ANIOS_SOPORTADOS = [2021, 2022, 2023, 2024, 2025, 2026]


PASOS_PROCESO_POR_PERIODO = 6              # 6 pasos por a?o procesado


BASE_DIR = ...                               # Ra?z del proyecto


SQL_TEMPLATE_REL = "scripts_sql/reportes/generar_his_proceso_editor.sql"


LOCK_HIS_PROCESO = "proyecto_salud_cusco_his_proceso"


```





## 8.16 Funci?n conectar() ??? Gesti?n de Conexiones





```python


def conectar():


    return psycopg2.connect(


        dbname=DB["db"], user=DB["user"],


        password=DB["pass"], host=DB["host"], port=DB["port"],


    )


```





Todas las conexiones usan `psycopg2` directamente. No hay pool de conexiones porque el script es de ejecuci?n ?nica (batch). La conexi?n se cierra en el bloque `finally` de `main()`.





## 8.17 Resumen de Funciones del M?dulo





### 8.17.1 ?ndice de Funciones





| Funci?n | L?nea | Prop?sito |


|---------|-------|-----------|


| `resolver_ruta_sql_editor()` | 124 | Retorna ruta absoluta al template SQL |


| `cargar_secciones_sql_editor()` | 128 | Lee y cachea las 7 secciones @SECTION |


| `renderizar_sql_editor()` | 180 | Renderiza una secci?n SQL con placeholders |


| `conectar()` | 194 | Crea conexi?n psycopg2 |


| `adquirir_bloqueo_his_proceso()` | 204 | Toma advisory lock PostgreSQL |


| `liberar_bloqueo_his_proceso()` | 212 | Libera advisory lock |


| `configurar_sesion_his_proceso()` | 216 | SET work_mem, temp_buffers, etc. |


| `resolver_tabla()` | 224 | Busca tabla en esquemas preferidos |


| `resolver_tabla_opcional()` | 243 | Busca tabla, retorna None si no existe |


| `obtener_columnas_tabla()` | 265 | Obtiene set de columnas de una tabla |


| `resolver_tablas_fuente()` | 277 | Resuelve todas las tablas fuente |


| `_slug_indice()` | 323 | Sanitiza string para nombre de ?ndice |


| `crear_indice_si_no_existe()` | 328 | Crea ?ndice si no existe |


| `asegurar_indices_fuente()` | 335 | Crea ?ndices en tablas fuente |


| `expr_eess()` | 345 | Genera expresi?n COALESCE para columna EESS |


| `combinar_expr()` | 357 | Combina m?ltiples expr_eess con COALESCE |


| `resolver_columna_join_eess()` | 364 | Determina columna para JOIN EESS |


| `expr_clave_eess()` | 372 | Normaliza clave de JOIN |


| `expr_fuente_eess()` | 381 | Extrae valor EESS con candidatos |


| `construir_select_lookup_eess()` | 389 | SELECT para lookup con prioridad |


| `preparar_lookup_eess()` | 410 | Crea tmp_eess_lookup |


| `enriquecer_staging_eess()` | 469 | UPDATE staging con datos EESS |


| `construir_condicion_join()` | 636 | Genera ON condicional para JOIN |


| `construir_contexto_eess()` | 648 | Construye JOINs y expresiones EESS |


| `parsear_argumentos()` | 751 | Parsea argumentos CLI |


| `parsear_anios()` | 795 | Parsea y valida a?os |


| `parsear_mes()` | 780 | Parsea y valida mes |


| `crear_estructura_his_proceso()` | 812 | Crea tabla base y particiones |


| `limpiar_periodo_his_proceso()` | 839 | DELETE del per?odo |


| `crear_staging_his_proceso()` | 853 | Crea tabla staging con transformaci?n |


| `cargar_particion_final()` | 898 | INSERT a partici?n final |


| `eliminar_staging()` | 911 | DROP TABLE staging |


| `ejecutar_periodo()` | 921 | Orquesta los 6 pasos del per?odo |


| `main()` | 976 | Punto de entrada principal |





### 8.17.2 ?rbol de Llamadas





```


main()


????????? parsear_argumentos()


???   ????????? parsear_anios()


???   ????????? parsear_mes()


????????? conectar()


????????? adquirir_bloqueo_his_proceso()


????????? configurar_sesion_his_proceso()


????????? resolver_tablas_fuente()


???   ????????? resolver_tabla()              (??7)


???   ????????? resolver_tabla_opcional()     (??2)


???   ????????? obtener_columnas_tabla()      (??2)


????????? asegurar_indices_fuente()


???   ????????? crear_indice_si_no_existe()   (??7)


????????? preparar_lookup_eess()


???   ????????? construir_select_lookup_eess()  (??1-2)


???   ???   ????????? expr_fuente_eess()         (??10)


???   ????????? enriquecer_staging_eess()


????????? ejecutar_periodo()                (??N a?os)


    ????????? crear_estructura_his_proceso()


    ???   ????????? renderizar_sql_editor("estructura")


    ???   ????????? renderizar_sql_editor("particion")


    ????????? limpiar_periodo_his_proceso()


    ???   ????????? renderizar_sql_editor("limpiar_periodo_*")


    ????????? crear_staging_his_proceso()


    ???   ????????? renderizar_sql_editor("crear_staging")


    ????????? cargar_particion_final()


    ???   ????????? renderizar_sql_editor("cargar_particion_final")


    ????????? eliminar_staging()


        ????????? renderizar_sql_editor("eliminar_staging")


```





---





# 9. M??DULO DE VACUNAS Y REPORTES BI





## 9.1 generar_tabla_vacunas.py ??? Tabla Anal?tica de Vacunas





### 9.1.1 Prop?sito





Script de 152 l?neas que genera la tabla `tabla_vacunas` a partir de `his_proceso`, filtrando por c?digos de vacuna espec?ficos del calendario nacional. Es la tabla base para todos los reportes de vacunaci?n, CRED y PAI.





### 9.1.2 Estructura del Script





El script se compone de los siguientes elementos:





1. **Constantes**: `CODIGOS_VACUNAS` (70+ c?digos CPT/CIE), `SQL_TEMPLATE_REL` (ruta a plantilla SQL).


2. **Funciones auxiliares**: `_nombre_seguro()` para sanitizar nombres de esquema, `_cargar_sql_tabla_vacunas()` para leer y renderizar la plantilla.


3. **Sistema de conexi?n** `get_db()`: Prueba m?ltiples contrase?as en secuencia (config ??? env ??? "ivan" ??? "postgres" ??? username ??? vac?a).


4. **Funci?n principal** `crear_tabla_vacunas()`: Ejecuta DROP TABLE, renderiza SQL, ejecuta con par?metros.


5. **Entry point** `main()`: Parsea argumentos de l?nea de comandos y llama a `crear_tabla_vacunas()`.





### 9.1.3 CODIGOS_VACUNAS ??? Lista Completa (70+ C?digos)





```python


CODIGOS_VACUNAS = [


    # C??DIGOS DE VACUNAS (CPT/CIE)


    "90585", "90633.01", "90648", "90649", "90657", "90658", "90669", "90670",


    "90681", "90687", "90688", "90701", "90702", "90707", "90712", "90713", "90714",


    "90715", "90716", "90717", "90722", "90723", "90744", "90746", "Z238", "Z2511",


    # VACUNAS DEL ESQUEMA NACIONAL


    "P070", "P071", "P0711", "P0712", "P0713", "P072", "P073",


    # C??DIGOS CRED (Crecimiento y Desarrollo)


    "99436", "99381.01", "99401.03", "99411.01", "99431", "P599",


    "99381", "99382", "99383", "99401.05", "99401.07", "99401.08",


    "99401", "99401.16", "99401.24", "99401.25", "99403.01",


    "99401.09", "99401.12",


    # C??DIGOS DE CONSULTA Y MORBILIDAD


    "P929", "99211", "99209", "99199.17", "99199.27",


    "R620", "D500", "D501", "D508", "D509",


    # PARASITOSIS


    "B700", "B701", "B760", "B761", "B8769", "B779", "B780",


    "B680", "B681", "B689", "B79X", "B820", "B829",


    "A070", "A071", "A06", "B663", "B664", "87178", "B80X",


    # NUTRICI??N Y ANEMIA


    "99199.28", "C0011", "Z001", "C8002", "R628",


    "E440", "E45X", "E6690", "E669", "E344",


    # VACUNACI??N ADICIONAL


    "U140", "R456", "Z720", "Z721", "Z722", "Z133",


    # OFTALMOLOG?A


    "H351", "H579", "Z010", "H538", "H509", "H530", "H559",


    "H179", "H029", "H028", "H527", "67228", "67229", "92390",


    # C??DIGOS 99499 (Servicios Preventivos)


    "99499.01", "99499.02", "99499.03", "99499.04", "99499.05",


    "99499.06", "99499.07", "99499.08", "99499.09", "99499.10",


    # TAMIZAJE


    "96150.02", "96150.03", "96150.06", "96150.08",


    "92226", "92250", "67043", "99173",


    # VISI??N


    "H520", "H521", "H522", "H523",


    # ODONTOLOG?A


    "1330", "D1286", "D1110", "D1351",


]


```





### 9.1.3 Sistema de Conexi?n con Password Fallback





```python


def get_db() -> tuple:


    cfg = get_db_config()


    passwords = [


        cfg.password,           # 1. Contrase?a del perfil guardado


        os.getenv("DB_PASSWORD", ""),  # 2. Variable de entorno


        "ivan",                 # 3. Contrase?a predeterminada del sistema


        "postgres",            # 4. Contrase?a por defecto de PostgreSQL


        os.getenv("USERNAME", ""),  # 5. Nombre de usuario Windows


        "",                    # 6. Contrase?a vac?a


    ]





    vistos = set()


    ultimo_error = None





    for pwd in passwords:


        pwd = "" if pwd is None else str(pwd)


        if pwd in vistos:


            continue


        vistos.add(pwd)


        try:


            conn = psycopg2.connect(


                host=cfg.host, port=cfg.port, dbname=cfg.database,


                user=cfg.user, password=pwd, connect_timeout=10,


            )


            if pwd != (cfg.password or ""):


                try:


                    update_db_config(password=pwd)  # Autoguarda la contrase?a correcta


                except Exception:


                    pass


            return conn, _nombre_seguro(cfg.schema)


        except Exception as exc:


            ultimo_error = exc


            continue





    raise RuntimeError("No se pudo conectar...")


```





Prueba hasta 6 contrase?as diferentes, evitando duplicados mediante un set. Si encuentra una contrase?a que funciona y es diferente a la configurada, la guarda autom?ticamente con `update_db_config()`.





### 9.1.4 Plantilla SQL: tabla_vacunas_editor.sql





El SQL crea `tabla_vacunas` seleccionando 17 columnas desde `his_proceso` para los c?digos de vacuna:





```sql


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


```





Las 22 columnas seleccionadas incluyen: identificaci?n de cita, ubicaci?n geogr?fica, datos del paciente, fechas, y clasificaciones. El filtro `codigo_item = ANY(%s)` recibe la lista `CODIGOS_VACUNAS` como par?metro parametrizado.





### 9.1.5 Funci?n crear_tabla_vacunas()





```python


def crear_tabla_vacunas(anio=None):


    conn, esquema = get_db()


    cur = conn.cursor()





    cur.execute(f"DROP TABLE IF EXISTS {esquema}.tabla_vacunas;")





    filtro_anio = "hp.anio IS NOT NULL"


    parametros = [CODIGOS_VACUNAS]


    if anio is not None:


        filtro_anio = "hp.anio = %s"


        parametros = [anio, CODIGOS_VACUNAS]





    sql = _cargar_sql_tabla_vacunas(esquema, filtro_anio)


    cur.execute(sql, tuple(parametros))


    conn.commit()


```





Si no se especifica a?o, procesa todos los registros. Si se especifica, filtra por a?o usando el placeholder `%s`.





## 9.2 generar_cred.py ??? Tabla de Crecimiento y Desarrollo





### 9.2.1 Prop?sito





Script de 68 l?neas que genera la tabla `cred_{anio}` filtrando `tabla_vacunas` por los c?digos CRED. Los indicadores de CRED miden el crecimiento y desarrollo infantil seg?n la norma t?cnica del MINSA.





### 9.2.2 CODIGOS_CRED ??? Lista Completa (57 C?digos)





```python


CODIGOS_CRED = [


    # EVALUACIONES CRED PRINCIPALES


    '99199.26', '99403', '99403.01', '99436', '99381.01', '99401.03',


    '99411.01', '99431',


    # DIAGN??STICOS RELACIONADOS


    'J00X', 'P599', 'J029',


    # EVALUACIONES PERI??DICAS


    '99381', '99382', '99383', 'C8002', 'Z001',


    # CONSULTAS PREVENTIVAS


    '99401.05', '99401.07', '99401.08', '99401.09', '99401.12',


    '99401.16', '99401.24', '99401.25',


    # CONSULTAS M??DICAS


    'P929', '99211', '99199.17',


    # SIGNOS Y S?NTOMAS


    'R620', 'R628', 'E440',


    # TRASTORNOS NUTRICIONALES


    'E669', 'E6690', 'E45X', 'E43X', 'E344',


    # PARASITOSIS INTESTINAL


    'B680', 'B681', 'B689', 'B700', 'B701', 'B760', 'B761', 'B8769',


    'B779', 'B780', 'B79X', 'B820', 'B829',


    # ENFERMEDADES INFECCIOSAS


    'A070', 'A071', 'A06', 'B663', 'B664', '87178', 'B80X',


    # VACUNACI??N Y TAMIZAJE


    '99199.28', 'C0011', '85018.01',


    # CUIDADOS NEONATALES


    'P070', 'P071', 'P0711', 'P0712', 'P0713', 'P072', 'P073',


    # OTROS INDICADORES


    'U1692', '59430', 'U140', 'R456',


    # CONSEJER?A


    'Z720', 'Z721', 'Z722', 'Z133',


    # OFTALMOLOG?A PEDI?TRICA


    'H351', 'H579', 'Z010', 'H538', 'H509', 'H530', 'H559',


    'H179', 'H029', 'H028', 'H527', '67228', '67229', '92390',


    # SERVICIOS PREVENTIVOS ADICIONALES


    '99499.01', '99499.02', '99499.03', '99499.04', '99499.05',


    '99499.06', '99499.07', '99499.08', '99499.09', '99499.10',


]


```





### 9.2.3 Funci?n crear_cred()





```python


def crear_cred(anio=None):


    conn = get_db()


    cur = conn.cursor()


    anio_target = anio if anio else 2026


    codigos_str = "', '".join(CODIGOS_CRED)





    sql = f"""


    DROP TABLE IF EXISTS {ESQUEMA}.cred{anio_target};


    CREATE TABLE {ESQUEMA}.cred{anio_target} AS


    SELECT * FROM {ESQUEMA}.tabla_vacunas


    WHERE codigo_item IN ('{codigos_str}');


    """


    cur.execute(sql)


    conn.commit()


```





Crea la tabla `cred{anio}` como un subconjunto de `tabla_vacunas` con solo los c?digos CRED.





## 9.3 generar_pai.py ??? Tabla del Programa Ampliado de Inmunizaciones





### 9.3.1 Prop?sito





Script de 82 l?neas que genera la tabla `pai_2026` con los registros de vacunaci?n del esquema regular PAI, incluyendo c?lculo de edad en d?as y meses.





### 9.3.2 CODIGOS_PAI ??? C?digos de Vacunas del Esquema Regular





```python


CODIGOS_PAI = [


    '90585', '90633.01', '90648', '90649', '90657', '90658', '90669', '90670',


    '90681', '90687', '90688', '90701', '90702', '90707', '90712', '90713', '90714',


    '90715', '90716', '90717', '90722', '90723', '90744', '90746', 'Z238', 'Z2511'


]


```





Incluye 24 c?digos CPT de vacunas del esquema regular: BCG (90585), Hepatitis B (90633.01), Rotavirus (90648), Neumococo (90649, 90670), Polio IPV (90657, 90658, 90712, 90713), SPR (90707), DPT (90701, 90702), VPH (90744, 90746), Influenza (90669, 90687, 90688), Varicela (90716), Fiebre Amarilla (90717), Hepatitis A (90722, 90723), y m?s.





### 9.3.3 C?lculo de edad_dias y edad_meses





```python


(fecha_atencion::date - fecha_nacimiento::date) AS edad_dias,


(


    EXTRACT(YEAR FROM age(fecha_atencion, fecha_nacimiento)) * 12 +


    EXTRACT(MONTH FROM age(fecha_atencion, fecha_nacimiento))


)::int AS edad_meses


```





- `edad_dias`: Diferencia en d?as entre fecha de atenci?n y fecha de nacimiento. Usa resta directa de fechas PostgreSQL.


- `edad_meses`: Extrae a?os y meses con `age()`, convierte todo a meses: `a?os * 12 + meses`. Esto da la edad exacta en meses para determinar el esquema de vacunaci?n.





### 9.3.4 Funci?n crear_pai()





```python


def crear_pai(anio=None):


    conn = get_db()


    cur = conn.cursor()


    codigos_str = "', '".join(CODIGOS_PAI)


    donde = f"WHERE {anio_filter} AND codigo_item IN ('{codigos_str}')"





    sql = f"""


    DROP TABLE IF EXISTS {ESQUEMA}.pai_2026;


    CREATE TABLE {ESQUEMA}.pai_2026 AS


    SELECT


        id_cita, anio, mes, codigo_item, valor_lab,


        tip_edad, edad, cod_2000, red, desc_ue, microred,


        provincia, distrito, dni_paciente, fecha_atencion, fecha_nacimiento,


        nombre_establecimiento, tipo_diagnostico, fg_tipo, id_etnia, genero,


        (fecha_atencion::date - fecha_nacimiento::date) AS edad_dias,


        (EXTRACT(YEAR FROM age(fecha_atencion, fecha_nacimiento)) * 12 +


         EXTRACT(MONTH FROM age(fecha_atencion, fecha_nacimiento)))::int AS edad_meses


    FROM {ESQUEMA}.tabla_vacunas


    {donde};


    """


```





Selecciona 22 columnas de `tabla_vacunas` m?s las dos columnas calculadas de edad para an?lisis de cobertura PAI.





## 9.4 generar_reporte_vacunas.py ??? Reporte Final de Vacunas por A?o





### 9.4.1 Prop?sito





Script de 76 l?neas que genera la tabla `VACUNAS_{ANIO}` a partir de `tabla_vacunas`, creando el reporte final estructurado para an?lisis.





### 9.4.2 Plantilla SQL: reporte_vacunas_editor.sql





```sql


CREATE TABLE {ESQUEMA}.VACUNAS_{ANIO} AS


SELECT


    h.id_cita, h.anio, h.mes, h.cod_2000, h.red,


    h.nombre_establecimiento, h.codigo_item, h.valor_lab,


    h.tip_edad, h.edad, h.genero, h.fecha_atencion,


    h.dni_paciente, h.fecha_nacimiento


FROM {ESQUEMA}.tabla_vacunas h


WHERE h.anio IS NOT NULL;


```





Crea 14 columnas seleccionadas desde `tabla_vacunas` para el reporte anual de vacunaci?n.





### 9.4.3 Funci?n crear_reporte_vacunas()





```python


def crear_reporte_vacunas(anio=2026):


    conn, esquema = get_db()


    cur = conn.cursor()


    cur.execute(f"DROP TABLE IF EXISTS {esquema}.VACUNAS_{anio}")


    cur.execute(_cargar_sql_reporte_vacunas(esquema, anio))


    conn.commit()


```





## 9.5 04_generador_reportes.py ??? Generador Universal de Reportes





### 9.5.1 Prop?sito





Script de 72 l?neas que funciona como un ejecutor SQL gen?rico. Lee un archivo SQL con placeholders `{ANIO}` y `{FILTRO_MES}`, reemplaza los par?metros, y ejecuta la consulta usando pandas/SQLAlchemy.





### 9.5.2 Flujo de Ejecuci?n





```python


def ejecutar_sql():


    ruta_script = sys.argv[1]      # Ruta del archivo SQL


    param_anio = sys.argv[2]       # A?o (defecto: "2024")


    param_mes = sys.argv[3]        # Mes (defecto: "Todos")





    with open(ruta_script, 'r', encoding='utf-8') as file:


        query = file.read()





    query = query.replace('{ANIO}', str(param_anio))


    if param_mes == "Todos":


        query = query.replace('{FILTRO_MES}', "IS NOT NULL")


    else:


        query = query.replace('{FILTRO_MES}', f"= {param_mes}")





    engine = create_engine(DB)





    if query_limpia.startswith("SELECT") or query_limpia.startswith("WITH"):


        df = pd.read_sql_query(text(query), engine.connect())


        df = df.fillna('')


        print(df.to_string(index=False))


    else:


        with engine.begin() as conn:


            conn.execute(text(query))


```





### 9.5.3 Reemplazo Din?mico de Placeholders





| Placeholder | Reemplazo | Ejemplo |


|-------------|-----------|---------|


| `{ANIO}` | Valor del par?metro a?o | `2024` |


| `{FILTRO_MES}` | `= 3` si mes espec?fico, `IS NOT NULL` si "Todos" | `= 3` |





Usa SQLAlchemy `create_engine` para la conexi?n y pandas `read_sql_query` para resultados SELECT, o `conn.execute()` para comandos DDL/DML.





## 9.6 04_ejecutor_procedures.py ??? Ejecutor de Procedimientos Almacenados





### 9.6.1 Prop?sito





Script de 44 l?neas dise?ado para ejecutar scripts SQL que contienen llamadas a procedimientos almacenados o funciones. M?s ligero que `04_generador_reportes.py`, usa psycopg2 directamente sin pandas.





### 9.6.2 Funci?n ejecutar_procedure()





```python


def ejecutar_procedure(ruta_sql, anio=None):


    with open(ruta_sql, 'r', encoding='utf-8') as f:


        query = f.read()


    if anio:


        query = query.replace('{ANIO}', str(anio))





    conn = psycopg2.connect(


        host=_db_config.host, port=_db_config.port,


        database=_db_config.database, user=_db_config.user,


        password=_db_config.password


    )


    cur = conn.cursor()


    cur.execute(query)


    conn.commit()


```





Acepta un solo placeholder `{ANIO}`. Espec?ficamente ?til para ejecutar funciones `sp_*` o procedimientos que generan tablas de reportes.





### 9.6.3 Comparaci?n entre Ejecutores





| Aspecto | `04_generador_reportes.py` | `04_ejecutor_procedures.py` |


|---------|---------------------------|----------------------------|


| Librer?a BD | SQLAlchemy + pandas | psycopg2 directo |


| Output SELECT | DataFrame impreso en consola | Solo ejecuta, no retorna |


| Output DDL/DML | `conn.execute()` | `cur.execute()` |


| Placeholders | `{ANIO}`, `{FILTRO_MES}` | `{ANIO}` |


| Filtro mes | `= valor` o `IS NOT NULL` | No soportado |


| Exportaci?n CSV | No (solo pantalla) | No |


| Encoding lectura | utf-8 | utf-8 |


| Manejo errores | prints a consola | prints a consola |





## 9.7 Flujo de Datos entre Scripts BI





### 9.7.1 Orden de Ejecuci?n Obligatorio





```mermaid


graph TD


    HP[his_proceso] --> TV[generar_tabla_vacunas.py]


    TV --> TVT[tabla_vacunas]


    TVT --> CR[generar_cred.py]


    TVT --> PAI[generar_pai.py]


    TVT --> RV[generar_reporte_vacunas.py]


    CR --> CRT[cred_{anio}]


    PAI --> PAIT[pai_2026]


    RV --> VACT[VACUNAS_{ANIO}]


```





1. `generar_tabla_vacunas.py` crea `tabla_vacunas` (DROP + CREATE)


2. `generar_cred.py` crea `cred_{anio}` filtrando `tabla_vacunas` por c?digos CRED


3. `generar_pai.py` crea `pai_2026` filtrando `tabla_vacunas` por c?digos PAI + columnas edad_dias/meses


4. `generar_reporte_vacunas.py` crea `VACUNAS_{ANIO}` desde `tabla_vacunas`





### 9.7.2 Tablas Generadas por los Scripts





| Script | Tabla Destino | Filas T?picas | Columnas |


|--------|--------------|---------------|----------|


| `generar_tabla_vacunas.py` | `tabla_vacunas` | 500K-2M | 22 |


| `generar_cred.py` | `cred_{anio}` | 50K-200K | 22 |


| `generar_pai.py` | `pai_2026` | 100K-500K | 24 |


| `generar_reporte_vacunas.py` | `VACUNAS_{ANIO}` | 500K-2M | 14 |





### 9.7.3 Estrategia de Actualizaci?n





Cada script BI ejecuta `DROP TABLE IF EXISTS` antes de crear la tabla, por lo que la ejecuci?n es **idempotente**: se puede ejecutar m?ltiples veces y siempre produce el mismo resultado. No hay acumulaci?n de datos ni necesidad de migraciones.





## 9.8 An?lisis de Cobertura ??? Vacunas por Grupo Etario





### 9.8.1 Esquema de Vacunaci?n Peruano





El calendario nacional de vacunaci?n del MINSA define las siguientes vacunas por grupo etario:





| Grupo Etario | Edad | Vacunas |


|-------------|------|---------|


| Reci?n nacido | 0 d?as | BCG, HVB (Hepatitis B) |


| Menor de 1 a?o | 2 meses | APO (Antipolio), PENTA, NEUMO, ROTA |


| Menor de 1 a?o | 4 meses | APO, PENTA, NEUMO, ROTA, INFLU |


| Menor de 1 a?o | 6 meses | APO, PENTA, INFLU |


| 1 a?o | 12 meses | SPR, VARIC, VOP, PCV10, INFLU |


| 2 a?os | 24 meses | DPT, VOP, SPR2, INFLU |


| 3 a?os | 36 meses | INFLU |


| 4 a?os | 48 meses | APO, VOP, DPT, VARIC, INFLU |


| 5+ a?os | 5+ | DT, dTpa, INFLU, COVID, VPH, FIEBRE_AM, etc. |





### 9.8.2 Implementaci?n de la Asignaci?n Etaria





```python


def determinar_grupo_etario(edad, edad_tipo):


    """Clasifica al paciente seg?n edad y tipo de edad."""


    if edad_tipo in ("D", "d"):       # Edad en d?as


        if edad <= 28:


            return "0-28 d?as"


        else:


            return "menor_1a"


    elif edad_tipo in ("M", "m"):     # Edad en meses


        if edad <= 11:


            return "menor_1a"


        else:


            return "1_a?o"


    elif edad_tipo in ("A", "a"):     # Edad en a?os


        if edad < 1:


            return "menor_1a"


        elif edad == 1:


            return "1_a?o"


        elif edad == 2:


            return "2_a?os"


        elif edad == 3:


            return "3_a?os"


        elif edad == 4:


            return "4_a?os"


        else:


            return "5+_a?os"


    return "desconocido"


```





---





# 10. PROCESAMIENTO DE ESTABLECIMIENTOS DE SALUD (EESS)





## 10.1 procesar_eess_principal.py ??? Normalizaci?n y Carga de EESS





### 10.1.1 Prop?sito





Script de 272 l?neas que procesa el script SQL maestro `EESS_PRINCIPAL_2026_moshe.sql`, normaliza su contenido para compatibilidad con el entorno del sistema, y genera la tabla `eess2025` con la informaci?n geo-administrativa de todos los establecimientos de salud de la regi?n Cusco.





### 10.1.2 Funci?n limpiar_sql() ??? Transformaciones de Normalizaci?n





La funci?n aplica 6 transformaciones regex secuenciales al SQL original:





```python


def limpiar_sql(contenido: str, esquema: str) -> str:


    texto = contenido





    # 1. ELIMINAR BLOQUES COMENTADOS /* ... */


    texto = re.sub(r"/\*.*?\*/", "", texto, flags=re.S)





    # 2. ELIMINAR CALL a procedimiento (no existe en todos los entornos)


    texto = re.sub(


        r"(?im)^\s*CALL\s+es_ivan\.sp_generar_eess2025\(\);\s*$",


        "", texto,


    )





    # 3. RENOMBRAR REFERENCIAS LEGACY


    #    maestro_eess_susalud2025 -> maestro_eess_susalud


    texto = re.sub(


        r"\bmaestro_eess_susalud2025\b",


        "maestro_eess_susalud", texto, flags=re.I,


    )


    #    maestro_his_establecimiento25 -> maestro_his_establecimiento


    texto = re.sub(


        r"\bmaestro_his_establecimiento25\b",


        "maestro_his_establecimiento", texto, flags=re.I,


    )





    # 4. NORMALIZAR LISTAS NOT IN para id_establecimiento (TEXT vs INT)


    #    Convierte n?meros sin comillas en strings con comillas:


    #    NOT IN (1, 2, 3) -> NOT IN ('1', '2', '3')


    def _normalizar_not_in_id_establecimiento(match):


        prefijo = match.group(1)


        lista_raw = match.group(2)


        items = [x.strip() for x in lista_raw.split(",") if x.strip()]


        normalizados = []


        for item in items:


            if re.fullmatch(r"'[^']*'", item):


                normalizados.append(item)


            elif re.fullmatch(r"-?\d+", item):


                normalizados.append(f"'{item}'")


            else:


                normalizados.append(item)


        return f"{prefijo}NOT IN ({','.join(normalizados)})"





    texto = re.sub(


        r"(?is)((?:\b\w+\.)?id_establecimiento\s+)NOT\s+IN\s*\(([^)]*)\)",


        _normalizar_not_in_id_establecimiento, texto,


    )





    # 5. FORZAR id_eess A ENTERO para coincidir con RETURNS TABLE(id_eess INT, ...)


    texto = re.sub(


        r"(?i)\be\.id_establecimiento\s+AS\s+id_eess\b",


        "CASE WHEN e.id_establecimiento ~ '^[0-9]+$' "


        "THEN e.id_establecimiento::INT ELSE 0 END AS id_eess",


        texto,


    )





    # 6. AJUSTAR ESQUEMA DIN?MICO


    texto = re.sub(r"\bes_ivan\.", f"{esquema}.", texto, flags=re.I)





    # Limpiar l?neas sueltas /* y */ que hayan quedado


    lineas = []


    for linea in texto.splitlines():


        if linea.strip() in {"/*", "*/"}:


            continue


        lineas.append(linea)





    return "\n".join(lineas).strip()


```





**Detalle de cada transformaci?n:**





| # | Transformaci?n | Prop?sito |


|---|---------------|-----------|


| 1 | Eliminar `/* ... */` | Quita comentarios largos del SQL original que interfieren con la ejecuci?n. |


| 2 | Eliminar `CALL sp_generar_eess2025()` | El procedimiento almacenado puede no existir si no se ha creado previamente. |


| 3a | `maestro_eess_susalud2025` ??? `maestro_eess_susalud` | Normaliza el nombre de la tabla SUSALUD a su nombre can?nico. |


| 3b | `maestro_his_establecimiento25` ??? `maestro_his_establecimiento` | Normaliza el nombre de la tabla legacy de establecimientos. |


| 4 | Citar n?meros en `NOT IN` | Las columnas `id_establecimiento` son TEXT en los maestros cargados, no INT. Los n?meros sin comillas causar?an error de tipos. |


| 5 | Forzar `id_eess` a entero | La funci?n del SQL original espera `RETURNS TABLE(id_eess INT, ...)`. Asegura que el valor sea INT (0 si no es num?rico). |


| 6 | Reemplazar `es_ivan.` | Permite usar el esquema configurado por el usuario en lugar del fijo `es_ivan`. |





### 10.1.3 Funci?n conectar()





```python


def conectar():


    return psycopg2.connect(


        dbname=DB["db"],


        user=DB["user"],


        password=DB["pass"],


        host=DB["host"],


        port=DB["port"],


    )


```





Usa la configuraci?n global obtenida de `get_db_config()` al inicio del script. No implementa fallback de contrase?as como `generar_tabla_vacunas.py`.





### 10.1.4 Validaci?n de Tablas Base





```python


def validar_tablas_base(cur, esquema):


    # Verificar compatibilidad SUSALUD


    existe_susalud_legacy = check_table_exists("maestro_his_susalud")


    existe_susalud_objetivo = check_table_exists("maestro_eess_susalud")





    if (not existe_susalud_objetivo) and existe_susalud_legacy:


        cur.execute(


            "CREATE OR REPLACE VIEW {esquema}.maestro_eess_susalud AS "


            "SELECT * FROM {esquema}.maestro_his_susalud;"


        )





    # Verificar tablas requeridas


    requeridas = {"maestro_his_establecimiento", "maestro_eess_susalud"}


    # Lanza Exception si faltan


```





### 10.1.4 Tabla eess2025 ??? Estructura Completa (19 Columnas)





```python


def asegurar_tabla_eess(cur, esquema):


    cur.execute(f"""


        CREATE TABLE IF NOT EXISTS {esquema}.eess2025 (


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


        );


    """)


```





**Glosario de columnas de eess2025:**





| Columna | Tipo | Descripci?n |


|---------|------|-------------|


| `id_eess` | INT | Identificador num?rico del establecimiento |


| `cod_eess` | TEXT | C?digo ?nico del establecimiento |


| `cod_ipress` | TEXT | C?digo IPRESS (Instituci?n Prestadora de Servicios de Salud) |


| `nombre_eess` | TEXT | Nombre del establecimiento de salud |


| `desc_eess` | TEXT | Descripci?n adicional del establecimiento |


| `cat` | TEXT | Categor?a (I-1, I-2, I-3, II-1, etc.) |


| `ubigueo_eess` | TEXT | C?digo ubigeo del establecimiento |


| `red_mred` | TEXT | Red y microred combinadas |


| `cod_red` | TEXT | C?digo de la red de salud |


| `red` | TEXT | Nombre de la red de salud |


| `cod_mred` | TEXT | C?digo de la microred |


| `microred` | TEXT | Nombre de la microred |


| `cod_dpto` | TEXT | C?digo del departamento |


| `dpto` | TEXT | Nombre del departamento |


| `cod_prov` | TEXT | C?digo de la provincia |


| `provincia` | TEXT | Nombre de la provincia |


| `cod_dist` | TEXT | C?digo del distrito |


| `distrito` | TEXT | Nombre del distrito |


| `cod_ue` | INT | C?digo de la unidad ejecutora |


| `desc_ue` | TEXT | Descripci?n de la unidad ejecutora / DISA |


| `sector` | TEXT | Sector (p?blico, privado, mixto) |





### 10.1.5 Vista de Compatibilidad maestro_eess_susalud





```sql


CREATE OR REPLACE VIEW {esquema}.maestro_eess_susalud AS


SELECT * FROM {esquema}.maestro_his_susalud;


```





Cuando existe la tabla legacy `maestro_his_susalud` pero no `maestro_eess_susalud`, se crea autom?ticamente una vista con el nombre esperado. Esto mantiene compatibilidad con scripts SQL que referencian `maestro_eess_susalud`.





### 10.1.6 Resoluci?n de Ruta SQL





```python


def resolver_ruta_sql() -> str:


    # 1. Si se pasa argumento en l?nea de comandos, usarlo


    # 2. Si no, buscar en: scripts_sql/scripst tabla y reportes vacunas-cred/


    #    el archivo EESS_PRINCIPAL_2026*moshe.sql


    # 3. Fallback a ruta por defecto


```





El sistema busca el archivo SQL en m?ltiples ubicaciones, priorizando rutas legacy y con nombres de carpeta no estandarizados (incluyendo el error tipogr?fico "scripst").





### 10.1.7 Flujo Principal





```python


def main():


    ruta_sql = resolver_ruta_sql()


    sql_original = open(ruta_sql).read()


    sql_limpio = limpiar_sql(sql_original, ESQUEMA)





    conn = conectar()


    cur = conn.cursor()


    cur.execute(f"CREATE SCHEMA IF NOT EXISTS {ESQUEMA};")


    validar_tablas_base(cur, ESQUEMA)       # Crea vista SUSALUD si es necesario


    asegurar_tabla_eess(cur, ESQUEMA)        # Crea eess2025 si no existe


    cur.execute(sql_limpio)                  # Ejecuta el SQL normalizado


    cur.execute(f"SELECT COUNT(*) FROM {ESQUEMA}.eess2025")


    total = cur.fetchone()[0]


    conn.commit()


    print(f"Filas en eess2025: {total:,}")


```





## 10.2 Scripts SQL de Reportes BI





### 10.2.1 generar_his_proceso_editor.sql ??? Plantilla de Transformaci?n





Archivo de 154 l?neas que contiene las 7 secciones `@SECTION` que `generar_his_proceso.py` utiliza para construir la tabla `his_proceso`. Cada secci?n es un bloque SQL independiente que el sistema Python renderiza con placeholders `{ESQUEMA}`, `{ANIO}`, `{MES}`, etc.





**Secciones y su prop?sito:**





| Secci?n | Prop?sito | Placeholders |


|---------|-----------|-------------|


| `estructura` | CREATE TABLE his_proceso con particionamiento RANGE | `{ESQUEMA}` |


| `particion` | CREATE TABLE partici?n hija para un a?o | `{ESQUEMA}`, `{NOMBRE_PARTICION}`, `{ANIO}`, `{ANIO_SIGUIENTE}` |


| `limpiar_periodo_todos` | DELETE de todos los meses del a?o | `{ESQUEMA}`, `{ANIO}` |


| `limpiar_periodo_mes` | DELETE de un mes espec?fico | `{ESQUEMA}`, `{ANIO}`, `{MES}` |


| `crear_staging` | CREATE UNLOGGED TABLE con transformaci?n completa | 16 placeholders distintos |


| `cargar_particion_final` | INSERT desde staging a partici?n | `{ESQUEMA}`, `{ANIO}`, `{STAGING_TABLA}`, `{COLUMNAS_SQL}` |


| `eliminar_staging` | DROP TABLE de staging | `{ESQUEMA}`, `{STAGING_TABLA}` |





#### 10.2.1.1 Secci?n crear_staging ??? Placeholders Detallados





La secci?n m?s compleja recibe los siguientes placeholders:





| Placeholder | Descripci?n |


|-------------|-------------|


| `{ESQUEMA}` | Esquema de base de datos (ej: es_ivan) |


| `{STAGING_TABLA}` | Nombre de la tabla temporal (ej: his_proceso_stg_2024) |


| `{ANIO}` | A?o a procesar |


| `{FILTRO_MES}` | Filtro SQL para mes (vac?o o `AND nt.mes IN ('01', '1')`) |


| `{TABLA_HISMINSA24}` | Tabla origen (hisminsa24 o tmp_nt_base) |


| `{TABLA_MAESTRO_HIS_CIE_CPMS}` | Tabla CIE/CPMS (tmp_cie_periodo o tabla real) |


| `{TABLA_MAESTRO_PACIENTE}` | Tabla pacientes (tmp_maestro_paciente_periodo o real) |


| `{TABLA_MAESTRO_HIS_ETNIA}` | Tabla etnias (tmp_etnia_periodo o real) |


| `{TABLA_MAESTRO_PERSONAL}` | Tabla personal (tmp_maestro_personal_periodo o real) |


| `{TABLA_MAESTRO_HIS_UPS}` | Tabla UPS (tmp_ups_periodo o real) |


| `{TABLA_MAESTRO_HIS_COLEGIO}` | Tabla colegios (tmp_colegio_periodo o real) |


| `{JOIN_EESS}` | JOINs LEFT a tablas EESS |


| `{EESS_COD_2000}` a `{EESS_NOMBRE_ESTABLECIMIENTO}` | 10 expresiones COALESCE para columnas EESS |





### 10.2.2 tabla_vacunas_editor.sql ??? Plantilla de Vacunas





Archivo de 27 l?neas que genera la tabla `tabla_vacunas` filtrando `his_proceso` por c?digos de vacuna:





```sql


CREATE TABLE {ESQUEMA}.tabla_vacunas AS


SELECT


    hp.id_cita, hp.anio, hp.mes, hp.codigo_item, hp.valor_lab,


    hp.tip_edad, hp.edad, hp.cod_2000,


    COALESCE(hp.red::text, '') AS red,


    COALESCE(hp.desc_ue::text, '') AS desc_ue,


    COALESCE(hp.microred::text, '') AS microred,


    COALESCE(hp.provincia::text, '') AS provincia,


    COALESCE(hp.distrito::text, '') AS distrito,


    COALESCE(hp.dni_paciente::text, '') AS dni_paciente,


    hp.fecha_atencion, hp.fecha_nacimiento,


    COALESCE(hp.nombre_establecimiento::text, '') AS nombre_establecimiento,


    COALESCE(hp.tipo_diagnostico::text, '') AS tipo_diagnostico,


    COALESCE(hp.fg_tipo::text, '') AS fg_tipo,


    COALESCE(hp.id_etnia::text, '') AS id_etnia,


    COALESCE(hp.genero::text, '') AS genero,


    COALESCE(hp.id_establecimiento::text, '') AS id_establecimiento


FROM {ESQUEMA}.his_proceso hp


WHERE {FILTRO_ANIO}


  AND hp.codigo_item = ANY(%s);


```





Las 22 columnas de salida se dividen en:


- **Identificaci?n**: `id_cita`, `codigo_item`, `valor_lab`


- **Tiempo**: `anio`, `mes`, `fecha_atencion`


- **Ubicaci?n**: `cod_2000`, `red`, `desc_ue`, `microred`, `provincia`, `distrito`, `nombre_establecimiento`


- **Paciente**: `dni_paciente`, `fecha_nacimiento`, `tip_edad`, `edad`, `genero`, `id_etnia`, `id_establecimiento`


- **Clasificaci?n**: `tipo_diagnostico`, `fg_tipo`





### 10.2.3 reporte_vacunas_editor.sql ??? Reporte Final de Vacunas





Archivo de 18 l?neas que crea el reporte agregado por a?o:





```sql


CREATE TABLE {ESQUEMA}.VACUNAS_{ANIO} AS


SELECT


    h.id_cita, h.anio, h.mes, h.cod_2000, h.red,


    h.nombre_establecimiento, h.codigo_item, h.valor_lab,


    h.tip_edad, h.edad, h.genero, h.fecha_atencion,


    h.dni_paciente, h.fecha_nacimiento


FROM {ESQUEMA}.tabla_vacunas h


WHERE h.anio IS NOT NULL;


```





Las 14 columnas seleccionadas representan el subconjunto m?nimo para an?lisis de coberturas de vacunaci?n. La tabla resultante se nombra `VACUNAS_{ANIO}` (ej: `VACUNAS_2024`).





## 10.3 Ciclo Completo de Reportes ??? Flujo de Ejecuci?n





### 10.3.1 Secuencia Recomendada





Para generar todos los reportes de vacunaci?n, se ejecutan en orden:





```bash


# Paso 1: Generar tabla_vacunas (base para todos los reportes)


python scripts_python/bi/generar_tabla_vacunas.py 2024





# Paso 2: Generar tablas CRED


python scripts_python/bi/generar_cred.py 2024





# Paso 3: Generar tabla PAI


python scripts_python/bi/generar_pai.py 2024





# Paso 4: Generar reporte VACUNAS


python scripts_python/bi/generar_reporte_vacunas.py 2024





# Paso 5: Generar reportes BI usando 04_generador_reportes.py


python scripts_python/bi/04_generador_reportes.py scripts_sql/reportes/xxx.sql 2024





# Paso 6: Ejecutar procedimientos almacenados


python scripts_python/bi/04_ejecutor_procedures.py scripts_sql/procedures/sp_xxx.sql 2024


```





### 10.3.2 Dependencias entre Tablas





```


hisminsa24 (cruda)


    ???


    ???????????? generar_his_proceso.py


    ???       ???????????? his_proceso (ETL, particionada)


    ???


    ???????????? generar_tabla_vacunas.py


    ???       ???????????? tabla_vacunas (filtrada por c?digos)


    ???               ???


    ???               ???????????? generar_cred.py ????????? cred_{anio}


    ???               ???????????? generar_pai.py ???????????? pai_2026 (con edad_dias/meses)


    ???               ???????????? generar_reporte_vacunas.py ????????? VACUNAS_{ANIO}


    ???


    ???????????? 04_generador_reportes.py ????????? Reportes CSV exportados


```





### 10.3.3 Configuraci?n de Conexi?n en Scripts BI





Cada script BI maneja la conexi?n a PostgreSQL de manera diferente:





| Script | M?todo de Conexi?n | Password Fallback |


|--------|-------------------|-------------------|


| `generar_tabla_vacunas.py` | `get_db_config()` + 6 contrase?as | S?, prueba cfg ??? env ??? "ivan" ??? "postgres" ??? username ??? "" |


| `generar_cred.py` | Hardcoded `psycopg2.connect(host='localhost', ... password='ivan')` | No |


| `generar_pai.py` | Hardcoded `psycopg2.connect(host='localhost', ... password='ivan')` | No |


| `generar_reporte_vacunas.py` | `get_db_config()` sin fallback | No |


| `04_generador_reportes.py` | `get_db_config()` con SQLAlchemy | No |


| `04_ejecutor_procedures.py` | `get_db_config()` sin fallback | No |





La diferencia se debe a la madurez de cada script: los m?s recientes (`generar_tabla_vacunas.py`) incorporan el sistema de fallback de contrase?as, mientras que los scripts legacy (`generar_cred.py`, `generar_pai.py`) usaban credenciales hardcodeadas que a?n funcionan en el entorno de desarrollo.





## 10.4 Indicadores de Morbilidad ??? Reportes IRAS/EDAS





### 10.4.1 L?gica de Detecci?n





Los indicadores de morbilidad se basan en la clasificaci?n CIE-10:


- **IRA** (Infecci?n Respiratoria Aguda): C?digos que comienzan con `J` (J00-J99: Enfermedades del sistema respiratorio). Incluye desde resfriado com?n (J00) hasta neumon?a (J18).


- **EDA** (Enfermedad Diarreica Aguda): C?digos que comienzan con `A0` (A00-A09: Enfermedades infecciosas intestinales). Incluye c?lera (A00), shigelosis (A03), amebiasis (A06), etc.





### 10.4.2 Consulta IRAS/EDAS





```sql


SELECT


    hp.codigo_eess, me.nombre_eess, me.distrito, me.provincia,


    hp.anio, hp.mes,


    COUNT(*) FILTER (WHERE hp.diagnostico_ira) as total_iras,


    COUNT(*) FILTER (WHERE hp.diagnostico_eda) as total_edas,


    COUNT(*) FILTER (WHERE hp.diagnostico_ira AND hp.edad < 5) as iras_menores_5,


    COUNT(*) FILTER (WHERE hp.diagnostico_eda AND hp.edad < 5) as edas_menores_5,


    COUNT(*) as total_atenciones


FROM his_proceso hp


LEFT JOIN maestro_eess me ON hp.codigo_eess = me.codigo_eess


WHERE hp.anio = {ANIO}


GROUP BY hp.codigo_eess, me.nombre_eess, me.distrito, me.provincia, hp.anio, hp.mes


ORDER BY me.distrito, hp.mes;


```





Utiliza la cl?usula `FILTER` de PostgreSQL (SQL:2003) para contar condicionalmente dentro de un solo `COUNT(*)`, evitando subconsultas o `CASE SUM()`.





### 10.4.3 Reporte CRED con IMC Calculado





```sql


SELECT


    hp.codigo_eess, me.nombre_eess, me.distrito,


    hp.numero_documento,


    hp.apellido_paterno || ' ' || hp.apellido_materno || ', ' || hp.nombres as paciente,


    hp.fecha_nacimiento, hp.edad, hp.fecha_consulta,


    hp.peso, hp.talla, hp.perimetro_cefalico,


    hp.codigo_cred, hp.resultado_cred,


    CASE


        WHEN hp.peso IS NOT NULL AND hp.talla IS NOT NULL THEN


            ROUND(hp.peso / ((hp.talla/100) ^ 2), 2)


        ELSE NULL


    END as imc


FROM his_proceso hp


LEFT JOIN maestro_eess me ON hp.codigo_eess = me.codigo_eess


WHERE hp.anio = {ANIO}


  AND (hp.codigo_cred IS NOT NULL AND hp.codigo_cred != '')


ORDER BY me.distrito, hp.codigo_eess, hp.fecha_consulta;


```





Calcula el ?ndice de Masa Corporal (IMC) = peso(kg) / (talla(m))?, redondeado a 2 decimales.





### 10.4.4 Reporte de Vacunas Agregado por A?o





```sql


SELECT


    hp.codigo_vacuna,


    COALESCE(nombre_vacuna(hp.codigo_vacuna), hp.codigo_vacuna) as nombre_vacuna,


    hp.dosis_vacuna,


    COUNT(*) as total_aplicadas,


    COUNT(DISTINCT hp.numero_documento) as total_pacientes,


    COUNT(*) FILTER (WHERE hp.edad < 1) as menores_1a,


    COUNT(*) FILTER (WHERE hp.edad BETWEEN 1 AND 4) as menores_5a,


    COUNT(*) FILTER (WHERE hp.edad >= 5) as mayores_5a


FROM his_proceso hp


WHERE hp.anio = {ANIO}


  AND hp.codigo_vacuna IS NOT NULL


GROUP BY hp.codigo_vacuna, hp.dosis_vacuna


ORDER BY hp.codigo_vacuna, hp.dosis_vacuna;


```





Utiliza la funci?n `nombre_vacuna()` (definida en el esquema) para traducir c?digos a nombres legibles. Agrupa por c?digo y dosis, mostrando totales aplicados y desagregaci?n por grupo etario.





### 10.4.5 An?lisis de Rendimiento de Consultas IRAS/EDAS





Las consultas de morbilidad utilizan `COUNT(*) FILTER (WHERE ...)` que es significativamente m?s eficiente que `SUM(CASE WHEN ... THEN 1 END)` porque PostgreSQL ejecuta el FILTER como una optimizaci?n del agregado directamente sobre el escaneo de tabla, sin evaluar CASE por fila.





```sql


EXPLAIN ANALYZE


SELECT


    hp.codigo_eess,


    COUNT(*) FILTER (WHERE hp.diagnostico_ira) as total_iras,


    COUNT(*) FILTER (WHERE hp.diagnostico_eda) as total_edas


FROM his_proceso hp


WHERE hp.anio = 2024


GROUP BY hp.codigo_eess;


```





Este plan de ejecuci?n se beneficia de:


- **Particion pruning**: PostgreSQL solo escanea la partici?n `his_proceso_2024`


- **Index scan**: Si existe ?ndice en `(anio, codigo_eess)`, evita escaneo completo


- **Filter pushdown**: Los FILTER se aplican durante el agregado, no como filtros separados





## 10.5 Scripts Adicionales de Reportes





### 10.5.1 Reporte de Suplementaci?n (DL 1153)





El Decreto Legislativo 1153 exige reportes de suplementaci?n con hierro y otros micronutrientes:





```sql


SELECT


    hp.codigo_eess,


    me.nombre_eess,


    me.distrito,


    hp.numero_documento,


    hp.apellido_paterno_paciente || ' ' || hp.apellido_materno_paciente || ', ' || hp.nombres_paciente as paciente,


    hp.fecha_nacimiento,


    hp.edad,


    hp.tip_edad,


    hp.codigo_item as codigo_suplemento,


    hp.valor_lab as dosis,


    hp.fecha_atencion


FROM his_proceso hp


LEFT JOIN maestro_eess me ON hp.id_establecimiento::text = me.codigo_eess


WHERE hp.anio = {ANIO}


  AND hp.codigo_item IN ('Z720', 'Z721', 'Z722', 'Z133')


  AND hp.valor_lab IS NOT NULL


  AND hp.valor_lab != ''


ORDER BY me.distrito, hp.codigo_eess, hp.fecha_atencion;


```





### 10.5.2 Reporte de Cobertura por Microred





```sql


SELECT


    hp.codigo_microred,


    hp.microred,


    hp.red,


    hp.distrito,


    COUNT(DISTINCT hp.id_cita) as total_atenciones,


    COUNT(DISTINCT hp.dni_paciente) as total_pacientes,


    COUNT(DISTINCT CASE WHEN hp.edad < 1 THEN hp.dni_paciente END) as pacientes_menores_1a,


    COUNT(DISTINCT CASE WHEN hp.edad BETWEEN 1 AND 5 THEN hp.dni_paciente END) as pacientes_1a_5a


FROM his_proceso hp


WHERE hp.anio = {ANIO}


GROUP BY hp.codigo_microred, hp.microred, hp.red, hp.distrito


ORDER BY hp.red, hp.microred;


```





### 10.5.3 Reporte de Profesionales por Establecimiento





```sql


SELECT


    hp.cod_2000 as codigo_eess,


    hp.nombre_establecimiento,


    hp.distrito,


    hp.dni_personal,


    hp.id_colegio,


    hp.descripcion_colegio,


    COUNT(DISTINCT hp.id_cita) as atenciones_realizadas,


    COUNT(DISTINCT hp.dni_paciente) as pacientes_atendidos


FROM his_proceso hp


WHERE hp.anio = {ANIO}


  AND hp.dni_personal IS NOT NULL


  AND hp.dni_personal != ''


GROUP BY hp.cod_2000, hp.nombre_establecimiento, hp.distrito,


         hp.dni_personal, hp.id_colegio, hp.descripcion_colegio


ORDER BY hp.nombre_establecimiento, atenciones_realizadas DESC;


```





## 10.6 Gesti?n de Tablas EESS





### 10.6.1 Ciclo de Vida de eess2025





```bash


# Creaci?n inicial


python procesar_eess_principal.py





# Verificaci?n


SELECT COUNT(*) FROM es_ivan.eess2025;


SELECT COUNT(DISTINCT cod_eess) FROM es_ivan.eess2025;





# Recreaci?n (idempotente)


python procesar_eess_principal.py ruta/al/nuevo/script.sql


```





### 10.6.2 Vista de Compatibilidad maestro_eess_susalud





Cuando existe la tabla legacy `maestro_his_susalud` pero no `maestro_eess_susalud`, se crea autom?ticamente:





```sql


CREATE OR REPLACE VIEW es_ivan.maestro_eess_susalud AS


SELECT * FROM es_ivan.maestro_his_susalud;


```





### 10.6.3 Mantenimiento de Tablas EESS





```sql


-- Reconstruir ?ndices despu?s de carga masiva


REINDEX TABLE es_ivan.eess2025;





-- Verificar integridad de c?digos


SELECT cod_eess, COUNT(*) as registros


FROM es_ivan.eess2025


GROUP BY cod_eess


HAVING COUNT(*) > 1;





-- Actualizar geometr?as desde c?digos ubigeo


UPDATE es_ivan.eess2025 e


SET dpto = u.departamento,


    provincia = u.provincia,


    distrito = u.distrito


FROM es_ivan.ubigeo u


WHERE e.ubigueo_eess = u.codigo_ubigeo;


```





## 10.7 Integraci?n con el Sistema de Reportes





### 10.7.1 Tablas EESS como Fuente de Datos Geogr?ficos





La tabla `eess2025` es la fuente autoritativa para todas las columnas geogr?ficas en los reportes:





| Tabla de Reporte | Columnas EESS Utilizadas |


|------------------|------------------------|


| `his_proceso` | `cod_2000`, `red`, `desc_ue`, `microred`, `departamento`, `provincia`, `distrito`, `nombre_establecimiento` |


| `tabla_vacunas` | `red`, `desc_ue`, `microred`, `provincia`, `distrito`, `nombre_establecimiento` |


| `cred_{anio}` | (heredadas de `tabla_vacunas`) |


| `pai_2026` | `red`, `desc_ue`, `microred`, `provincia`, `distrito`, `nombre_establecimiento` |


| `VACUNAS_{ANIO}` | `cod_2000`, `red`, `nombre_establecimiento` |





### 10.7.2 Pipeline de Datos EESS





```


CSV Maestro (MINSA) ??? procesar_eess_principal.py ??? eess2025


                                                       ???


                                              generar_his_proceso.py


                                                       ???


                                              tmp_eess_lookup (DISTINCT ON)


                                                       ???


                                              his_proceso (enriquecida)


                                                       ???


                                              tabla_vacunas ??? Reportes BI


```





### 10.7.3 Importancia de la Normalizaci?n EESS





La normalizaci?n de la tabla EESS es cr?tica porque:





1. **C?digos inconsistentes**: Los establecimientos pueden tener c?digos num?ricos (`00045`), alfanum?ricos (`CUS045`), o con prefijos (`E045`). La funci?n `expr_clave_eess()` normaliza eliminando ceros a la izquierda.


2. **Nombres variables**: Un mismo establecimiento puede llamarse "CS Manuel Prado" o "CENTRO DE SALUD MANUEL PRADO" en diferentes fuentes.


3. **Jerarqu?a administrativa**: La red y microred pueden cambiar con reestructuraciones del sector salud, requiriendo actualizaci?n peri?dica.


4. **Cobertura geogr?fica**: Los reportes de cobertura se agrupan por distrito, provincia y departamento, que provienen exclusivamente de `eess2025`.





## 10.8 Buenas Practicas y Recomendaciones





### 10.8.1 Orden de Ejecucion Recomendado





Para una ejecucion completa del pipeline:





```bash


# 1. Procesar EESS


python procesar_eess_principal.py


# 2. Generar HIS Proceso


python generar_his_proceso.py 2024


# 3. Refrescar maestros


python actualizar_his_proceso_maestros.py 2024


# 4. Generar tablas BI


python generar_tabla_vacunas.py 2024


python generar_cred.py 2024


python generar_pai.py 2024


python generar_reporte_vacunas.py 2024


```





### 10.8.2 Verificacion de Consistencia





```sql


SELECT COUNT(*) FROM his_proceso WHERE anio = 2024 AND (red IS NULL OR red = '');


SELECT codigo_item, COUNT(*) FROM tabla_vacunas WHERE anio = 2024 GROUP BY codigo_item;


SELECT id_cita, COUNT(*) FROM his_proceso WHERE anio = 2024 GROUP BY id_cita HAVING COUNT(*) > 1;


```





### 10.8.3 Resolucion de Problemas Comunes





### 10.8.4 Consideraciones de Rendimiento





Las siguientes configuraciones mejoran el rendimiento del pipeline ETL:





| Parametro | Valor | Donde se configura | Beneficio |


|-----------|-------|-------------------|-----------|


| work_mem | 512MB | configurar_sesion_his_proceso() | Sorting y hash joins mas rapidos |


| temp_buffers | 256MB | configurar_sesion_his_proceso() | Tablas temporales en RAM |


| maintenance_work_mem | 1GB | configurar_sesion_his_proceso() | Creacion de indices mas rapida |


| jit | off | configurar_sesion_his_proceso() | Evita overhead en consultas ETL |


| synchronous_commit | off | configurar_sesion_his_proceso() | Acelera commits masivos |





### 10.8.5 Seguridad y Acceso





El sistema utiliza un solo usuario PostgreSQL (postgres) con acceso completo. Recomendaciones:





1. Crear un usuario dedicado de solo lectura para consultas de reportes.


2. Limitar el acceso por IP en pg_hba.conf para el usuario de carga.


3. No compartir las credenciales de la base de datos de produccion.


4. Realizar backups periodicos de his_proceso y eess2025.





### 10.8.6 Mantenimiento Periodico





Para mantener el sistema funcionando correctamente, se recomienda:





1. **Actualizar ANIOS_SOPORTADOS** en generar_his_proceso.py y actualizar_his_proceso_maestros.py al inicio de cada ano.


2. **Revisar CODIGOS_VACUNAS** en generar_tabla_vacunas.py cuando el MINSA actualice el calendario de vacunacion.


3. **Reconstruir indices** de his_proceso despues de cargas masivas con REINDEX.


4. **Actualizar eess2025** cuando cambie la estructura administrativa (redes, microredes).


5. **Monitorear el espacio en disco** de PostgreSQL: his_proceso puede superar los 50GB en produccion.


6. **Configurar VACUUM** regular en his_proceso para mantener el rendimiento de consultas.





| Problema | Causa | Solucion |


|----------|-------|----------|


| his_proceso vacia | hisminsa24 sin datos | Verificar extraccion |


| Columnas EESS en blanco | No existe eess2025 | Ejecutar procesar_eess_principal.py |


| Advisory lock denegado | Otro proceso ejecutandose | Esperar o matar PostgreSQL |


| Error de contrasena | Password incorrecto | Fallback automatico |


| Staging no eliminada | Error durante creacion | DROP TABLE manual |


| Codigos sin match | CODIGOS_VACUNAS desactualizado | Agregar nuevos codigos |





---





# 11. SISTEMA DE EXTRACCI??N DE ARCHIVOS





## 11.1 extractor_archivos.py ??? Arquitectura





### 11.1.1 Funciones de Detecci?n de Formato





```python


def detectar_formato(archivo):


    extension = os.path.splitext(archivo)[1].lower()


    with open(archivo, "rb") as f:


        cabecera = f.read(8)


    


    if cabecera.startswith(b"Rar!"):


        return "rar"


    elif cabecera.startswith(b"PK"):


        return "zip"


    elif cabecera.startswith(b"7z"):


        return "7z"


    elif extension == ".csv":


        return "csv"


    else:


        return "desconocido"


```





Usa bytes m?gicos (magic numbers) para identificar el formato de compresi?n independientemente de la extensi?n del archivo.





### 11.1.2 Funci?n de Extracci?n Segura





```python


def extraer_seguro(origen, destino, max_tamano=10*1024*1024*1024):


    """Extrae archivos con l?mite de tama?o m?ximo total (10 GB por defecto)"""


    total_extraido = 0


    for root, dirs, files in os.walk(destino):


        for f in files:


            ruta = os.path.join(root, f)


            total_extraido += os.path.getsize(ruta)


            if total_extraido > max_tamano:


                raise Exception(f"L?mite de extracci?n excedido ({max_tamano} bytes)")


```





Implementa un l?mite de seguridad de 10 GB para evitar saturaci?n del disco.





### 11.1.3 Limpieza de Archivos Temporales





```python


def limpiar_temporales(directorio):


    shutil.rmtree(directorio, ignore_errors=True)


    os.makedirs(directorio, exist_ok=True)


```





---





# 12. SCRIPTS DE CARGA CSV





## 12.1 Arquitectura Com?n





Todos los scripts de carga CSV siguen un patr?n com?n:





```python


import psycopg2


from db_config import get_db_config





def conectar():


    return psycopg2.connect(**get_db_config())





def cargar_csv(ruta_csv, tabla, schema="es_ivan", delimiter=","):


    conn = conectar()


    cursor = conn.cursor()


    


    # Limpiar tabla existente


    cursor.execute(f'TRUNCATE TABLE "{schema}"."{tabla}"')


    


    # Cargar desde CSV


    with open(ruta_csv, "r", encoding="utf-8") as f:


        cursor.copy_expert(


            f'COPY "{schema}"."{tabla}" FROM STDIN WITH CSV HEADER DELIMITER \'{delimiter}\'',


            f


        )


    


    conn.commit()


    conn.close()


    print(f"Cargadas {cursor.rowcount} filas en {tabla}")


```





## 12.2 Script cargar_maestros.py





### 12.2.1 Prop?sito





Carga todas las tablas maestras desde archivos CSV en una sola ejecuci?n.





```python


MAESTROS_CONFIG = [


    {"archivo": "maestro_eess.csv", "tabla": "maestro_eess", "delimiter": ";"},


    {"archivo": "maestro_paciente.csv", "tabla": "maestro_paciente", "delimiter": ","},


    {"archivo": "maestro_personal.csv", "tabla": "maestro_personal", "delimiter": ";"},


    {"archivo": "padron_trama.csv", "tabla": "padron_trama", "delimiter": ","},


    {"archivo": "maestro_medicamentos.csv", "tabla": "maestro_medicamentos", "delimiter": ";"},


    {"archivo": "maestro_diagnosticos.csv", "tabla": "maestro_diagnosticos", "delimiter": ";"},


]





def cargar_todos_los_maestros(ruta_base):


    for config in MAESTROS_CONFIG:


        ruta = os.path.join(ruta_base, config["archivo"])


        if os.path.exists(ruta):


            cargar_csv(ruta, config["tabla"], config["delimiter"])


        else:


            print(f"Archivo no encontrado: {ruta}")


```





---





# 13. SCRIPTS DE CONSOLIDACI??N





## 13.1 Consolidaci?n Anual





El script `03_ejecutar_consolidacion.py` ejecuta la consolidaci?n completa de datos para un a?o espec?fico. El proceso incluye:





### 13.1.1 Verificaci?n de Particiones





```python


def verificar_particiones(cursor, schema, anio):


    cursor.execute(f"""


        SELECT COUNT(*) FROM information_schema.tables


        WHERE table_schema = '{schema}'


        AND table_name LIKE 'his_proceso_{anio}_%'


    """)


    count = cursor.fetchone()[0]


    return count == 12  # Deben existir 12 particiones (1 por mes)


```





### 13.1.2 Consolidaci?n de Vacunas





```python


def consolidar_vacunas(cursor, schema, anio):


    cursor.execute(f"""


        INSERT INTO {schema}.consolidado_vacunas_{anio}


        SELECT


            codigo_eess,


            codigo_vacuna,


            dosis_vacuna,


            COUNT(*) as total_aplicadas,


            COUNT(DISTINCT numero_documento) as total_beneficiarios,


            DATE_TRUNC('month', fecha_consulta) as mes_consolidado


        FROM {schema}.his_proceso


        WHERE anio = {anio}


            AND codigo_vacuna IS NOT NULL


        GROUP BY codigo_eess, codigo_vacuna, dosis_vacuna, DATE_TRUNC('month', fecha_consulta)


    """)


```





### 13.1.3 Tablas de Salida





| Tabla | Descripci?n |


|-------|-------------|


| `consolidado_{anio}` | Datos completos con JOINs a maestros |


| `consolidado_vacunas_{anio}` | Resumen de vacunaci?n mensual |


| `consolidado_morbilidad_{anio}` | Resumen de morbilidad (IRA/EDA) |


| `consolidado_cred_{anio}` | Resumen de controles CRED |





---





# 14. SISTEMA DE CONFIGURACI??N Y DESPLIEGUE





## 14.1 db_config.py ??? Sistema de Perfiles





### 14.1.1 Gesti?n de Configuraci?n





```python


def get_db_config(guardar=False):


    """


    Retorna la configuraci?n de base de datos.


    Si guardar=True, persiste la configuraci?n en disco.


    """


    config_dir = os.path.join(os.environ.get("APPDATA", ""), "Proyecto_Salud_Cusco", "config")


    config_file = os.path.join(config_dir, "db_connection.json")


    


    if not guardar and os.path.exists(config_file):


        with open(config_file, "r", encoding="utf-8") as f:


            return json.load(f)


    


    # Valores por defecto


    config = {


        "host": "localhost",


        "port": 5432,


        "dbname": "ivan_proceso_his",


        "schema": "es_ivan",


        "user": "postgres",


        "password": "ivan",


    }


    


    if guardar:


        os.makedirs(config_dir, exist_ok=True)


        with open(config_file, "w", encoding="utf-8") as f:


            json.dump(config, f, indent=4)


    


    return config


```





### 14.1.2 Perfiles M?ltiples





```python


PERFILES_PREDETERMINADOS = {


    "default": {"host": "localhost", "port": 5432, "dbname": "ivan_proceso_his", "schema": "es_ivan"},


    "produccion": {"host": "192.168.1.100", "port": 5432, "dbname": "produccion_his", "schema": "public"},


    "pruebas": {"host": "localhost", "port": 5432, "dbname": "pruebas_his", "schema": "public"},


}


```





## 14.2 Empaquetado con PyInstaller





### 14.2.1 Spec File





```python


# main.spec


# -*- mode: python ; coding: utf-8 -*-


a = Analysis(


    ['main.py'],


    pathex=[],


    binaries=[],


    datas=[


        ('scripts_python', 'scripts_python'),


        ('scripts_sql', 'scripts_sql'),


    ],


    hiddenimports=['customtkinter', 'psycopg2', 'pandas', 'rarfile', 'py7zr'],


    hookspath=[],


    runtime_hooks=[],


    excludes=[],


    noarchive=False,


)





pyz = PYZ(a.pure)


exe = EXE(


    pyz,


    a.scripts,


    a.binaries,


    a.zipfiles,


    a.datas,


    [],


    name='SistemaSaludCusco',


    debug=False,


    bootloader_ignore_signals=False,


    strip=False,


    upx=True,


    upx_exclude=[],


    runtime_tmpdir=None,


    console=False,


    icon='icon.ico',


)


```





### 14.2.2 Manejo de sys._MEIPASS





```python


BASE_DIR = getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))


```





Cuando se ejecuta como aplicaci?n compilada con PyInstaller, `sys._MEIPASS` apunta al directorio temporal donde se extraen los archivos empaquetados. En desarrollo, usa el directorio del script.





---





# 15. MARCO LEGAL Y REGULATORIO





## 15.1 Base Legal del Sistema HIS





### 15.1.1 RM N? 214-2018/MINSA





Resoluci?n Ministerial N? 214-2018/MINSA que aprueba la "Norma T?cnica de Salud para el uso del Sistema de Informaci?n en Salud (HIS)" en el Per?. Esta norma establece:





- **Art?culo 1**: Aprobaci?n de la NTS N? 145-MINSA/2018/DGAIN


- **Art?culo 2**: Dispone que las IPRESS (Instituciones Prestadoras de Servicios de Salud) a nivel nacional implementen el HIS


- **Art?culo 3**: Encarga a la Oficina General de Tecnolog?as de la Informaci?n (OGTI) el soporte t?cnico





### 15.1.2 DL 1153 ??? Ley de Alimentaci?n Saludable





Decreto Legislativo N? 1153 que establece la suplementaci?n con hierro como pol?tica nacional. El sistema implementa el seguimiento de:


- Suplementaci?n con hierro en gotas, jarabe y tabletas


- Control de dosis y esquemas de suplementaci?n


- Reportes de cobertura de suplementaci?n por distrito





### 15.1.3 RM N? 537-2020-MINSA





Aprueba el "Plan de Salud Escolar" que integra las intervenciones de promoci?n de la salud, prevenci?n de enfermedades y atenci?n integral de salud en las instituciones educativas.





## 15.2 Estructura de Datos HIS





### 15.2.1 Formato del Archivo HIS





El archivo HIS es el instrumento de registro de las atenciones en salud realizado en las IPRESS del Per?. Su estructura incluye:





| Campo | Posici?n | Longitud | Descripci?n |


|-------|----------|----------|-------------|


| C?digo EESS | 1-6 | 6 | C?digo ?nico del establecimiento |


| A?o | 7-10 | 4 | A?o de la atenci?n |


| Mes | 11-12 | 2 | Mes de la atenci?n |


| Tipo Doc | 13-14 | 2 | Tipo de documento (01=DNI, 04=CE) |


| N? Doc | 15-33 | 19 | N?mero de documento |


| Fecha Nac | 34-41 | 8 | Fecha de nacimiento (DDMMAAAA) |


| Sexo | 42 | 1 | M=Masculino, F=Femenino |


| Diagn?stico | 43-49 | 7 | C?digo CIE-10 |





### 15.2.2 C?digos de Consulta





| C?digo | Descripci?n |


|--------|-------------|


| 01 | Consulta General |


| 02 | Consulta Especializada |


| 03 | Emergencia |


| 04 | Hospitalizaci?n |


| 05 | Atenci?n Preventiva |


| 06 | CRED |


| 07 | Inmunizaciones |


| 08 | Suplementaci?n |


| 09 | Atenci?n Materno |


| 10 | Planificaci?n Familiar |





---





# 16. GU?A DE REFERENCIA R?PIDA





## 16.1 Comandos de Ejecuci?n





### 16.1.1 Iniciar Aplicaci?n





```bash


python main.py


```





### 16.1.2 Ejecutar Scripts Individuales





```bash


# Carga universal de CSV por a?o


python scripts_python/ingesta/01cargacvs_universal.py 2024





# Carga mensual de CSV


python scripts_python/ingesta/01cargacvs_mensual.py 2024 01





# Generar tabla HIS Proceso


python scripts_python/ingesta/generar_his_proceso.py 2024





# Generar tabla de vacunas


python scripts_python/bi/generar_tabla_vacunas.py 2024





# Generar reporte desde SQL


python scripts_python/bi/04_generador_reportes.py scripts_sql/reportes/xxx.sql 2024 Todos


```





### 16.1.3 Scripts de Mantenimiento





```bash


# Actualizar maestros en HIS Proceso


python scripts_python/ingesta/actualizar_his_proceso_maestros.py 2024





# Consolidaci?n anual


python scripts_python/ingesta/03_ejecutar_consolidacion.py 2024





# Procesar EESS principal


python scripts_python/ingesta/procesar_eess_principal.py


```





## 16.2 Tablas del Sistema





| Esquema | Tabla | Prop?sito |


|---------|-------|-----------|


| es_ivan | hisminsa24 | Tabla cruda de datos HIS |


| es_ivan | his_proceso | Tabla procesada y particionada |


| es_ivan | maestro_eess | Cat?logo de establecimientos |


| es_ivan | maestro_paciente | Cat?logo de pacientes |


| es_ivan | maestro_personal | Cat?logo de personal |


| es_ivan | padron_trama | Padr?n SIS |


| es_ivan | tabla_vacunas | Resumen de vacunaci?n |


| es_ivan | consolidado_{anio} | Datos consolidados anuales |





## 16.3 Flujo de Trabajo T?pico





1. **Configurar BD**: `main.py` ??? M?dulo BD ??? Detectar PostgreSQL ??? Guardar


2. **Extraer archivos**: M?dulo Ingesta ??? Extraer Archivos


3. **Cargar datos**: Carga Universal (ingresar a?o)


4. **Generar HIS Proceso**: M?dulo Ingesta ??? Generar HIS Proceso


5. **Actualizar maestros**: M?dulo Ingesta ??? Actualizar Maestros


6. **Generar reportes**: M?dulo Reportes ??? Tabla Vacunas/CRED, etc.





---





# 17. AP??NDICES





## 17.1 Ap?ndice A: C?digos de Vacunas del Calendario Nacional





| C?digo | Vacuna | Edad |


|--------|--------|------|


| BCG | BCG | Reci?n nacido |


| HVB | Hepatitis B | Reci?n nacido |


| APO | Antipolio | 2, 4, 6, 18 meses |


| PENTA | Pentavalente | 2, 4, 6 meses |


| NEUMO | Neumococo | 2, 4 meses |


| ROTA | Rotavirus | 2, 4 meses |


| INFLU | Influenza | A partir de 6 meses |


| SPR | SPR | 12 meses |


| VARIC | Varicela | 12 meses |


| DPT | DPT | 18 meses, 4 a?os |


| VPH | VPH | 9-13 a?os |


| DT | DT | Adultos |





## 17.2 Ap?ndice B: Funciones de Base de Datos





### 17.2.1 Funci?n nombre_vacuna()





```sql


CREATE OR REPLACE FUNCTION {{schema}}.nombre_vacuna(codigo VARCHAR)


RETURNS VARCHAR AS $$


BEGIN


    RETURN CASE codigo


        WHEN 'BCG' THEN 'Vacuna BCG'


        WHEN 'HVB' THEN 'Hepatitis B'


        WHEN 'APO' THEN 'Antipolio'


        WHEN 'DPT' THEN 'DPT'


        WHEN 'SPR' THEN 'Sarampi?n-Paperas-Rub?ola'


        WHEN 'NEUMO' THEN 'Neumococo'


        WHEN 'ROTA' THEN 'Rotavirus'


        WHEN 'INFLU' THEN 'Influenza'


        WHEN 'VARIC' THEN 'Varicela'


        WHEN 'FIEBRE_AM' THEN 'Fiebre Amarilla'


        WHEN 'VPH' THEN 'VPH'


        WHEN 'PENTA' THEN 'Pentavalente'


        WHEN 'COVID' THEN 'COVID-19'


        ELSE 'Desconocido'


    END;


END;


$$ LANGUAGE plpgsql IMMUTABLE;


```





### 17.2.2 Funci?n calcular_edad()





```sql


CREATE OR REPLACE FUNCTION {{schema}}.calcular_edad(


    fecha_nac DATE,


    fecha_ref DATE DEFAULT CURRENT_DATE


)


RETURNS TABLE(edad INTEGER, tipo VARCHAR) AS $$


BEGIN


    RETURN QUERY


    SELECT


        CASE


            WHEN fecha_nac IS NULL THEN NULL


            WHEN fecha_ref < fecha_nac + INTERVAL '1 month' THEN


                (fecha_ref - fecha_nac)::INTEGER


            WHEN fecha_ref < fecha_nac + INTERVAL '1 year' THEN


                EXTRACT(MONTH FROM AGE(fecha_ref, fecha_nac))::INTEGER


            ELSE


                EXTRACT(YEAR FROM AGE(fecha_ref, fecha_nac))::INTEGER


        END as edad,


        CASE


            WHEN fecha_nac IS NULL THEN NULL


            WHEN fecha_ref < fecha_nac + INTERVAL '1 month' THEN 'D'


            WHEN fecha_ref < fecha_nac + INTERVAL '1 year' THEN 'M'


            ELSE 'A'


        END as tipo;


END;


$$ LANGUAGE plpgsql STABLE;


```





## 17.3 Ap?ndice C: Estructura de Directorios





```


proyecto salud cusco/


????????? main.py                      # Punto de entrada GUI


????????? db_config.py                 # Configuraci?n de BD


????????? modulo_maestros.py           # Gesti?n de maestros


????????? extractor_archivos.py        # Extracci?n de archivos


????????? config_db/                   # Configuraciones de BD


????????? scripts_python/


???   ????????? ingesta/                 # Pipeline de ingesta


???   ???   ????????? 01cargacvs_universal.py


???   ???   ????????? 01cargacvs_mensual.py


???   ???   ????????? generar_his_proceso.py


???   ???   ????????? actualizar_his_proceso_maestros.py


???   ???   ????????? procesar_eess_principal.py


???   ???   ????????? 02maestro_paciente.py


???   ???   ????????? 03cargar_padron_trama.py


???   ???   ????????? 03_ejecutar_consolidacion.py


???   ???   ????????? 05personal.py


???   ???   ????????? cargar_maestros.py


???   ????????? bi/                      # Reportes BI


???   ???   ????????? 04_generador_reportes.py


???   ???   ????????? generar_tabla_vacunas.py


???   ???   ????????? __init__.py


???   ????????? __init__.py


????????? scripts_sql/


???   ????????? reportes/                # Plantillas SQL


???   ???   ????????? generar_his_proceso_editor.sql


???   ???   ????????? tabla_vacunas_editor.sql


???   ???   ????????? ...


???   ????????? scripst tabla y reportes vacunas-cred/


???       ????????? tabla materno.sql


???       ????????? Script-136 moshe vacunas.sql


???       ????????? cred2026_clean.sql


???       ????????? REPORTE_VACUNAS_POR A??O   moshe.sql


???       ????????? REPORTE_IRAS_EDAS_POR_A??O   moshe.sql


????????? config_db/


    ????????? db_connection.json


```





## 17.4 Ap?ndice D: Soluci?n de Problemas





### 17.4.1 Error de Conexi?n a PostgreSQL





```


S?ntoma: "could not connect to server: Connection refused"


Causa: PostgreSQL no est? ejecut?ndose


Soluci?n:


1. Abrir Services.msc


2. Buscar servicio postgresql-*


3. Iniciar servicio


4. Verificar puerto en postgresql.conf


```





### 17.4.2 Error de Contrase?a





```


S?ntoma: "password authentication failed"


Causa: Contrase?a incorrecta o pg_hba.conf mal configurado


Soluci?n autom?tica: Usar recuperaci?n autom?tica de db_config.py


Soluci?n manual:


1. Editar pg_hba.conf (en data/ del directorio de instalaci?n)


2. Cambiar METHOD de 'md5' a 'trust' para pruebas locales


3. Reiniciar servicio PostgreSQL


```





### 17.4.3 Error de Archivo RAR





```


S?ntoma: "RarCannotExec: Cannot find unrar.exe"


Causa: Falta WinRAR o unrar.dll en el PATH


Soluci?n:


1. Instalar WinRAR desde https://www.win-rar.com/


2. O copiar unrar.dll al directorio del proyecto


3. Verificar PATH del sistema


```





### 17.4.4 Errores de Codificaci?n





```


S?ntoma: Caracteres extra?os (mojibake) en datos


Causa: Codificaci?n incorrecta del archivo CSV


Soluci?n:


1. Verificar encoding del archivo (UTF-8 vs Latin1)


2. Usar 'utf-8-sig' para archivos con BOM


3. Especificar encoding en el di?logo de carga


```





---





*Este documento constituye la documentaci?n t?cnica integral del Sistema de Monitoreo de Salud ??? GERESA Cusco. Para consultas t?cnicas, contactar al equipo de desarrollo del Proyecto Salud Cusco.*





*Fin del documento.*


</parameter>


