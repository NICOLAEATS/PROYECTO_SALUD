# Proyecto_Salud_Cusco - Agent Guidelines (v2 - Web + Cloud)

## 🌐 Idioma
**Siempre responder en español.** No usar inglés para explicaciones, mensajes ni documentación. Solo usar inglés si el usuario lo pide explícitamente o para términos técnicos muy específicos (nombres de funciones, librerías, etc.).

## 🏆 Regla de Oro (Prioridad Absoluta)
**El sistema debe funcionar en CUALQUIER PC donde se ejecute.**
- NO asumas rutas fijas del desarrollador (`C:\Users\Nouch\...`, etc.)
- NO uses rutas absolutas hardcodeadas
- TODO path debe ser configurable por el usuario (input de texto, variable de entorno, o selector)
- La BD debe detectarse automáticamente o configurarse desde la interfaz
- Los scripts Python deben ser autónomos: detectan `PROJECT_ROOT` con `config.py` o `os.path.dirname`
- Cualquier funcionalidad nueva debe preguntarse: "¿esto funcionaría si lo abro en otro PC?"
- Preferir input de texto sobre selectores nativos del SO (el navegador no expone rutas reales)

## Quick Start
```bash
# Web app (desarrollo local)
cd proyecto_salud_cusco_web
venv/bin/python app.py
# Abrir http://localhost:5000

# Desktop app (original)
python main.py
pip install customtkinter psycopg2-binary
```

## Architecture
- **Web entry point**: `proyecto_salud_cusco_web/app.py` - Flask REST API + polling engine + Cloudflare Tunnel endpoints
- **Desktop entry point**: `main.py` - CustomTkinter GUI application
- **DB config**: `db_config.py` - Centralized PostgreSQL connection management (cross-platform: Windows + Linux)
- **Scripts**: `scripts_python/ingesta/*.py` - Data ingestion scripts
- **Key module**: `modulo_maestros.py` - Maestro table processing GUI
- **Frontend**: `proyecto_salud_cusco_web/templates/index.html` SPA con Fetch API REST
- **Static**: `proyecto_salud_cusco_web/static/js/app.js`, `static/css/style.css`
- **Tunnel**: `proyecto_salud_cusco_web/tunnel/` - Cloudflare Tunnel scripts (Windows .ps1, .bat)

## Database Defaults
| Parameter | Value |
|-----------|-------|
| Host | localhost |
| Port | 5432 |
| Database | ivan_proceso_his |
| Schema | es_ivan |
| User | postgres |
| Password | ivan |

## Key Functions in db_config.py
- `get_db_config()` - Load/save config from `%APPDATA%/Proyecto_Salud_Cusco/config/db_connection.json`
- `detectar_postgresql_existente()` - Returns dict with installed, version, service status, ruta_bin (cross-platform)
- `_detectar_postgresql_linux()` - Linux detection: `which psql`, `systemctl`, busca en rutas Linux
- `verificar_bd_esquema()` - Verifies DB and schema exist
- `inicializar_base_datos()` - Creates DB and schema if missing
- `ES_WINDOWS = platform.system() == "Windows"` - Branching flag

## Script Execution Pattern
```bash
python scripts_python/ingesta/01cargacvs_universal.py 2024
python scripts_python/bi/04_generador_reportes.py scripts_sql/reportes/xxx.sql 2024 Todos
```

## Important Quirks
1. **Windows-only**: Use `dir`, `type`, not `ls`, `cat`
2. **PyInstaller frozen**: Check `sys.frozen` before running scripts
3. **PG password auto-detect**: Tries multiple passwords (cfg, "ivan", "", Windows user)
4. **pgpass support**: Reads `%APPDATA%/postgresql/pgpass.conf`
5. **Port 5432 is source of truth**: `detectar_postgresql_existente()` relies on port response, not service status

---

# Sesión de trabajo: Web + Cloud Deployment

## Goal
Convertir el sistema CustomTkinter desktop a web (Flask + HTML/CSS/JS), subir a GitHub, y desplegar en un VPS gratis o económico para acceso desde cualquier PC sin instalar nada local.

## Progress

### Done
- SocketIO reemplazado por polling REST: estado compartido thread-safe (`_exec_state`) + endpoint `GET /api/ejecucion/status/<token>` + `POST /api/ejecucion/cancel`.
- Frontend: motor `startPolling(token, callbacks)` con poll cada 800ms, tracking de líneas nuevas por índice, detección de estados terminales.
- Cancel button funcional: `POST /api/ejecucion/cancel` + `proc.terminate()`/`proc.kill()`.
- Ingesta: barra de progreso alimentada con datos reales del subprocess (done/total/ETA).
- Eliminadas dependencias `flask-socketio`, `python-socketio`, `eventlet`.
- Verificado: todos los endpoints responden 200 en `http://localhost:5000`.
- Push a GitHub (`master`): `https://github.com/NICOLAEATS/proyecto_salud_cusco.git`
- `.gitignore` ignora `venv/`, `__pycache__/`, `build/`, `dist/`, `datos/`, `logs/`.
- Corregidos 723 errores ortográficos en `tesis correcciones.docx`.
- Creados archivos del paquete pacman en `proyecto-salud-pkg/` (PKGBUILD, bin script, .desktop, install scripts).
- `config.py` auto-detecta `PROJECT_ROOT` (busca `scripts_python/` o env var `PROYECTO_SALUD_ROOT`).
- PostgreSQL detection cross-platform:
  - `_detectar_postgresql_linux()`: `which psql`, `systemctl`, busca en rutas Linux.
  - `ES_WINDOWS` branching, código Windows original conservado.
  - Distingue: no instalado, instalado pero detenido, instalado y activo.
- `/api/db/start-service` soporta Linux: `sudo -n systemctl start postgresql`.
- Cloudflare Tunnel integrado:
  - Endpoints REST: `POST/GET /api/tunnel/*`.
  - Frontend: botón "🌐 Publicar" + sección "Acceso Remoto" con toggle y URL.
  - Scripts Windows: `tunnel/start_tunnel.ps1`, `tunnel/start_tunnel.bat`.
- Debug mode controlado por `FLASK_DEBUG` env var (desactivado por defecto).
- Instalación local ejecutada con éxito en `~/.local/share/proyecto-salud/`.
- **Nuevos módulos web**: Padrón/Población (PN+CNV unificados), Geolocalización (Leaflet), Dashboards.
  - `static/js/modules.js`: JS independiente para los 4 módulos nuevos.
  - `scripts_python/bi/cargar_padron_nominal.py`: Carga PN CSV → tabla `padron_nominal`.
  - `scripts_python/bi/cargar_cnv.py`: Carga CNV CSV → tabla `cnv_cusco` (dinámica desde headers).
  - 8 endpoints REST en `app.py`: status/carga/consulta para PN y CNV, `/api/mapa/*`, `/api/dashboards/*`.
- **Fix CNV**: 0 registros → 257,019. Causas: NUL (0x00) en datos, columna `Ubigeo_LugarNacido` mal nombrada, batch final sin try/except.
- **Fix encoding PN/CNV**: `_detect_encoding()` ahora lee inicio+medio+fin del archivo (3 muestras de 64KB) para detectar correctamente `utf-8-sig`, `utf-8`, `cp1252` o `latin-1`. Antes solo leía primeros 8KB y fallaba si bytes Latin-1 (0xF1 para ñ) aparecían más adelante. PN pasó de ~3,000 registros (con replace) → 347,265 registros con ñ correctos.
- **Fix CASCADE en CNV**: `DROP TABLE IF EXISTS ... CASCADE` para no fallar cuando existe la vista `es_ivan.cnv` que depende de la tabla.
- **Layout web**: eliminado `max-height: 70vh` de resultados; sidebar responsivo hasta 480px; módulo activo usa `height: 100%` para llenar viewport.
- **Fix reportes**: `pandas`+`sqlalchemy` instalados en web venv. `UnicodeEncodeError` corregido con `sys.stdout.reconfigure(encoding='utf-8', errors='replace')`.
- **Fix SQL scripts**: `tabla vacunas cred_ivan.sql`, `tabla_materno_ivan.sql`, `tabla_iras_edas_ivan_2026.sql` — agregado `DROP TABLE IF EXISTS + CREATE TABLE ... AS ... WHERE 1=0` donde faltaba.
- **Fix `04_ejecutor_procedures.py` — Bug multi-statement**: psycopg2 no ejecuta multi-statement correctamente cuando incluye comandos de utilidad (`CREATE TABLE AS`, `SET`). **Solución:** dividir el SQL por `;` y ejecutar cada statement individualmente con `cur.execute()` separado. Función `_split_statements()` con manejo de bloques `$$` y comentarios `/* */`.
- **Fix DROP saltado por comentarios**: statements que empezaban con líneas `--` eran saltados por `stmt.startswith('--')` aunque contuvieran SQL real (ej: `DROP TABLE` con comentario arriba). **Solución:** filtrar solo líneas comentario, no todo el statement.
- **Fix `/* */` block comments**: la función split cortaba dentro de `/*...*/` por el `;` interno. **Solución:** `_strip_block_comments()` remueve block comments antes de dividir.
- **Fix años hardcodeados en INSERTs**: `tabla_materno_ivan.sql:82` tenía `WHERE nt.anio = 2026`, `tabla_iras_edas_ivan_2026.sql:107` y `tabla vacunas cred_ivan.sql:117` tenían `WHERE nt.anio = 2025` — todos cambiados a `{ANIO}`.
- **Resultado tablas con datos (año 2024)**:
  - `tabla_materno` → **1,531,528 rows**
  - `tabla_vacunas` → **13,108,188 rows**
  - `tabla_iras_edas` → **911,199 rows**
- **Push a GitHub**: commits `268448a` (módulos), `983923d` (correcciones encoding + docs + SQLs), `bb7ae22` (fix CREATE TABLE), `cd47af7` (fix */*/ garbage).
- **Módulo Formatos MINSA CRED**: Implementación de `_reporte_completo_cred()` con routing dual: `_reporte_cred_2024()` para 2024 usa 5 tablas pre-agregadas `cred2024*` (~900 cols, cobertura COMPLETA de 38 secciones en 3 páginas) y `_reporte_completo_cred_old()` para 2025/2026 usa `his_proceso` con cobertura parcial (~10 secciones).
  - FORMULARIO NIÑO CRED (18 secciones): Atención RN, Condición Nacimiento, Tamizaje Neonatal, Sesiones Tempranas, Lactancia, Evaluación Desarrollo, Plan Integral, Consejería, Evaluación Nutricional, Laboratorio, Profilaxis Antiparasitaria, Visita Domiciliaria, Tamizajes, ROP, Salud Ocular, Errores Refracción, Salud Bucal, Seguimiento.
  - SUPLEMENTACION (12 secciones): Sup. Preventiva <6m, Multimicronutrientes 6-11m/1a/2a/3a/4a/5-11a, Vitamina A, Sup. Hierro MEF/Gest/Puerp, Dosaje HB, Consulta Nutricional, Consejería Nutricional.
  - TRATAMIENTO ANEMIA (8 secciones): Sulfato Ferroso por edad, Dosaje HB Control, Consulta Médica, Consulta Nutricional.
- **Módulo Formatos MINSA IRAS EDAS**: `_reporte_iras_edas_2024()` con 3 páginas. Página 1 usa `iras_edas_2024` (178 cols) para 6 secciones con datos reales: IRA (6 tipos con desglose etario), NEUMONIA Y EMG, SOB/ASMA, EDA (4 tipos × 3 niveles de gravedad), SRO, Zinc. Páginas 2-3 reusan `_build_cred_suplementacion()` y `_build_cred_tx_anemia()`.
- **Descubiertas y validadas tablas pre-agregadas**: `cred2024` (270 cols), `cred2024_1` (267 cols), `cred2024_2` (34 cols), `cred2024_3` (163 cols), `cred2024_4` (174 cols), `iras_edas_2024` (178 cols), `pai_2024` (237 cols), `pai_2024_1` (51 cols). Cada una con 4481 filas (12 meses × ~373 establecimientos).
- **Módulo `html_report_builder.py` completo**: `proyecto_salud_cusco_web/html_report_builder.py` con todas las ~22 secciones del FORMATO NIÑO como funciones `_sec_*()` que generan HTML idéntico al Excel (17 columnas, Calibri 8pt, helpers `td()`/`th()`/`hdr_row()`/`data_row()`). Integrado en `app.py` vía `sys.path.insert(0, '.')` + import directo; `data_composite` = merge de todas las columnas de `cred2024_*` sin prefijos C1_/C2_/C3_/C4_.
- **Secciones implementadas**: HEADER, CRED CONTROLS, ATENCIÓN RN, CONDICIÓN NACIMIENTO, TAMIZAJE NEONATAL, EVALUACIÓN DESARROLLO, SESIONES+LACTANCIA, PLAN INTEGRAL, CONSEJERÍA (10 items), EVALUACIÓN NUTRICIONAL (<5a y 5-11a), PARASITOSIS (IMC), LABORATORIO/TAMIZAJES, PROFILAXIS ANTIPARASITARIA, VISITA DOMICILIARIA, SALUD MENTAL (test habilidades + agudeza + auditiva + tanner + postural), TAMIZAJES (violencia/depresión/alcohol/neurodesarrollo), TAMIZAJES POSITIVOS, ROP (12 actividades), SALUD OCULAR <3a (examen ojos/visión/referencia), ERRORES REFRACCIÓN (hipermetropía/miopía/astigmatismo).
- **Tema claro predeterminado**: `index.html` → `data-theme="light"`, `app.js` fallback → `'light'`.
- **`tabla_html`** en respuesta API; `modules.js` usa `p.tabla_html` cuando existe.

### Blocked / Paused
- **Oracle Cloud Free Tier**: El usuario pagó $1 USD de verificación pero la creación de cuenta falla con error genérico ("Lo sentimos, se ha producido un error al crear su cuenta"). Sugerencias: esperar 24h, probar otro navegador en incógnito, verificar que la dirección de facturación coincida exactamente con la tarjeta, no usar VPN.
- **Alternativa**: Hetzner CX22 (€3.99/mes con PayPal) como plan B si Oracle no funciona.
- **Auto-generación de tablas agregadas para dashboards**: los SPs (`reporte_cred_ivan_2026.sql`, 6226 líneas) son demasiado complejos para ejecución inline. Los generadores `generar_pai.py`/`generar_cred.py` crean formato detail (48 cols), no crosstab (237-270 cols). Solución pendiente: rediseñar dashboards para consultar `tabla_vacunas` directamente.

## Key Functions in app.py (Formatos MINSA)
- `_reporte_cred_2024()` - Reporte CRED completo 2024 usando tablas pre-agregadas cred2024_* (3 páginas, ~38 secciones)
- `_reporte_iras_edas_2024()` - Reporte IRAS EDAS 2024 usando iras_edas_2024 + cred2024_* (3 páginas, ~26 secciones)
- `_build_cred_suplementacion()` - Construye secciones de Suplementación desde cred2024/cred2024_2/cred2024_4
- `_build_cred_tx_anemia()` - Construye secciones de Tx Anemia desde cred2024/cred2024_2/cred2024_4
- `_reporte_completo_cred_old()` - Reporte CRED para 2025/2026 usando his_proceso (cobertura parcial ~10 secciones)
- `_reporte_iras_edas_old()` - Reporte IRAS EDAS para 2025/2026 usando his_proceso (7 secciones con CIE codes)
- `_qcred_cols()` - Query dinámica de columnas bigint desde tablas pre-agregadas con prefijo de alias
- `_cred_flat()` - Helper para construir secciones planas (INDICADOR + TOTAL)
- Endpoints: `/api/reportes-minsa/tipos` (tipos disponibles), `/api/reportes-minsa/ejecutar` (generar reporte), `/api/reportes-minsa/exportar` (exportar a Excel con openpyxl)

## Key Decisions
- **Formatos MINSA dual routing**: `_reporte_completo_cred()` redirige a `_reporte_cred_2024()` para 2024 (tablas pre-agregadas, cobertura completa) o `_reporte_completo_cred_old()` para 2025/2026 (his_proceso, cobertura parcial). `_reporte_iras_edas()` análogo con su routing 2024 vs old.
- **Dashboard fallback**: `_resolve_year_table()` retorna año de fallback + flag `fallback: true` → frontend muestra banner con enlace "🔍 Diagnosticar" que consume `/api/dashboards/check-year`. No se intenta generación automática porque las tablas agregadas requieren estructura crosstab compleja (237-270 cols).
- **`toast()`**: usa `.innerHTML` en vez de `.textContent` para soportar HTML en notificaciones.
- **`openpyxl`**: eliminado de imports (código muerto tras remover endpoints `/api/reportes-excel/*`).
- SocketIO → polling REST para eliminar errores de protocolo.
- `config.py` usa auto-detección de `PROJECT_ROOT` + env var override.
- PostgreSQL detection cross-platform con `ES_WINDOWS` branching.
- Cloudflare Tunnel para acceso remoto temporal gratuito (sin cuenta).
- Oracle Cloud Free Tier (gratis siempre) o Hetzner (€3.99/mes PayPal) como destino de despliegue.
- **CSV dinámico**: `cargar_cnv.py` crea tabla desde headers del CSV (lowercased+stripped) para evitar mismatch de nombres.
- **Módulos nuevos en `modules.js`** separado de `app.js` para no afectar código existente.
- **Statement-by-statement execution**: `04_ejecutor_procedures.py` usa `_split_statements()` + `_strip_block_comments()` para evitar bug de protocolo extendido de psycopg2 con multi-statement.
- **Revisar INSERT final en SQLs**: siempre verificar que `WHERE nt.anio = ...` use `{ANIO}` (no 2024/2025/2026 hardcodeado).

## Relevant Paths
- `proyecto_salud_cusco_web/app.py` - Flask REST API + polling + tunnel + endpoints Formatos MINSA (~4200 líneas)
- `proyecto_salud_cusco_web/templates/index.html` - SPA frontend (~614 líneas)
- `proyecto_salud_cusco_web/static/js/app.js` - Frontend JS polling + Fetch (~1341 líneas)
- `proyecto_salud_cusco_web/static/js/modules.js` - JS módulos nuevos: PN, CNV, Mapa, Dashboards, Formatos MINSA (~1195 líneas)
- `proyecto_salud_cusco_web/static/css/style.css` - Temas claro/oscuro + `.data-table`
- `proyecto_salud_cusco_web/config.py` - Auto-detección PROJECT_ROOT + rutas SCRIPTS_PADRONES, SCRIPTS_BI_LOAD
- `proyecto_salud_cusco_web/html_report_builder.py` - Generador HTML completo para FORMATO NIÑO (todas las ~22 secciones, 17 columnas)
- `proyecto_salud_cusco_web/tunnel/` - Scripts tunnel (Windows)
- `scripts_python/bi/cargar_cnv.py` - Carga CNV con sanitize NUL + tabla dinámica
- `scripts_python/bi/cargar_padron_nominal.py` - Carga PN con sanitize NUL + batch final seguro
- `scripts_python/bi/04_generador_reportes.py` - Generador reportes con fix encoding UTF-8
- `scripts_python/bi/04_ejecutor_procedures.py` - Ejecutor SQL con split multi-statement, strip block comments, skip comment lines
- `scripts_sql/SCRIPTS CORREGIDOS ULTIMOS/tabla_materno_ivan.sql` - 82 lines, usó `{ANIO}`, resultó 1,531,528 rows
- `scripts_sql/SCRIPTS CORREGIDOS ULTIMOS/tabla vacunas cred_ivan.sql` - 117 lines, usó `{ANIO}`, resultó 13,108,188 rows
- `scripts_sql/SCRIPTS CORREGIDOS ULTIMOS/tabla_iras_edas_ivan_2026.sql` - 116 lines, usó `{ANIO}`, resultó 911,199 rows
- `scripts_sql/SCRIPTS CORREGIDOS ULTIMOS/reporte_cred_ivan_2026.sql` - Stored procedure con año en nombre (sin parametrizar)
- `scripts_sql/SCRIPTS CORREGIDOS ULTIMOS/reporte_iras_edas_2026_ivan.sql` - Stored procedure con año en nombre (sin parametrizar)
- `db_config.py` - PostgreSQL detection cross-platform (Linux + Windows)
- `proyecto-salud-pkg/` - Paquete pacman (PKGBUILD, scripts install/uninstall)

## Work Strategy: Recursive Incremental Execution
Cuando el trabajo es demasiado grande para un solo contexto, DEBES:
1. **Planificar** con `todowrite` dividiendo en chunks pequeños (~200-400 líneas)
2. **Delegar** usando `task()` para cada chunk independiente
3. **Validar** tras cada sub-tarea (iniciar app, probar endpoint)
4. **Encadenar** sub-tareas secuencialmente (cuando una termina, lanzar la siguiente)
5. **Verificar** todo al final (app corre, endpoints responden 200)

No intentes hacer todo en una sola respuesta. Avanza paso a paso llamándote recursivamente hasta completar la meta.