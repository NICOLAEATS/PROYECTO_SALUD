# DOCUMENTACIÃ“N COMPLETA DEL SISTEMA WEB - DIRESA CUSCO
## Sistema de Monitoreo de Salud - GERESA Cusco

---

## 1. ARQUITECTURA GENERAL

### 1.1 Stack TecnolÃ³gico

| Componente | TecnologÃ­a |
|------------|-----------|
| Backend | Python 3.10+ / Flask 2.x |
| Frontend | HTML5 + CSS3 + JavaScript Vanilla (SPA) |
| Base de Datos | PostgreSQL 15+ con esquema `es_ivan` |
| Mapas | Leaflet.js + OpenStreetMap (gratuito) |
| Polling | REST polling cada 800ms (sin WebSockets) |
| TÃºneles | Cloudflare Tunnel (acceso remoto temporal) |
| Desktop (opcional) | CustomTkinter (main.py) |

### 1.2 Estructura de Directorios

```
proyecto salud cusco/                    # PROJECT_ROOT
â”œâ”€â”€ main.py                              # Entry point desktop (CustomTkinter)
â”œâ”€â”€ db_config.py                         # ConfiguraciÃ³n BD cross-platform
â”œâ”€â”€ run.py                               # Lanzador web
â”œâ”€â”€ read_excel.py                        # Lector Excel
â”œâ”€â”€ modulo_maestros.py                   # MÃ³dulo maestros desktop
â”‚
â”œâ”€â”€ proyecto_salud_cusco_web/            # Web app (Flask)
â”‚   â”œâ”€â”€ app.py                           # ~4770 lÃ­neas - API REST + lÃ³gica
â”‚   â”œâ”€â”€ config.py                        # Rutas y constantes web
â”‚   â”œâ”€â”€ html_report_builder.py           # ~1664 lÃ­neas - Generador HTML MINSA
â”‚   â”œâ”€â”€ analyze_excel.py                 # Analizador Excel
â”‚   â”œâ”€â”€ requirements.txt                 # Dependencias Python
â”‚   â”œâ”€â”€ templates/
â”‚   â”‚   â””â”€â”€ index.html                   # SPA completa (todo el HTML)
â”‚   â”œâ”€â”€ static/
â”‚   â”‚   â”œâ”€â”€ js/
â”‚   â”‚   â”‚   â”œâ”€â”€ app.js                   # ~1340 lÃ­neas - Core SPA
â”‚   â”‚   â”‚   â””â”€â”€ modules.js              # ~1249 lÃ­neas - MÃ³dulos
â”‚   â”‚   â””â”€â”€ css/
â”‚   â”‚       â””â”€â”€ style.css                # ~1304 lÃ­neas - Estilos
â”‚   â”œâ”€â”€ tunnel/                          # Scripts Cloudflare Tunnel
â”‚   â”‚   â”œâ”€â”€ start_tunnel.bat
â”‚   â”‚   â”œâ”€â”€ start_tunnel.ps1
â”‚   â”‚   â””â”€â”€ TUNNEL_README.md
â”‚   â””â”€â”€ venv/                            # Virtual environment
â”‚
â”œâ”€â”€ scripts_python/                      # Scripts Python
â”‚   â”œâ”€â”€ ingesta/                         # Pipeline de datos
â”‚   â”‚   â”œâ”€â”€ 01cargacvs_universal.py      # Carga CSV completa
â”‚   â”‚   â”œâ”€â”€ 01cargacvs_mensual.py        # Carga CSV por mes
â”‚   â”‚   â”œâ”€â”€ 01cargacvs_hisminsa.py       # Carga HIS MINSA
â”‚   â”‚   â”œâ”€â”€ generar_his_proceso.py       # ETL principal (~1046 lÃ­neas)
â”‚   â”‚   â”œâ”€â”€ cargar_maestros.py           # Carga maestros
â”‚   â”‚   â”œâ”€â”€ procesar_eess_principal.py   # Procesa EESS
â”‚   â”‚   â””â”€â”€ actualizar_his_proceso_maestros.py
â”‚   â”œâ”€â”€ bi/                              # Business Intelligence
â”‚   â”‚   â”œâ”€â”€ cargar_padron_nominal.py     # Carga PN
â”‚   â”‚   â”œâ”€â”€ cargar_cnv.py               # Carga CNV
â”‚   â”‚   â”œâ”€â”€ generar_tabla_vacunas.py     # Genera tabla_vacunas
â”‚   â”‚   â”œâ”€â”€ generar_cred.py              # Genera tablas cred2024*
â”‚   â”‚   â”œâ”€â”€ generar_pai.py              # Genera tablas pai_2024
â”‚   â”‚   â”œâ”€â”€ 04_generador_reportes.py     # Ejecuta SQL SELECT
â”‚   â”‚   â”œâ”€â”€ 04_ejecutor_procedures.py    # Ejecuta SQL multi-statement
â”‚   â”‚   â”œâ”€â”€ selector_carpeta.py          # DiÃ¡logo nativo de carpeta
â”‚   â”‚   â””â”€â”€ verificar_tablas.py          # VerificaciÃ³n
â”‚   â”œâ”€â”€ mantenimiento/
â”‚   â”‚   â””â”€â”€ 02_eliminar_datos.py         # EliminaciÃ³n de datos
â”‚   â””â”€â”€ instalacion/
â”‚       â””â”€â”€ instalar_postgresql.py       # InstalaciÃ³n PostgreSQL
â”‚
â”œâ”€â”€ scripts_sql/                         # Scripts SQL
â”‚   â”œâ”€â”€ SCRIPTS CORREGIDOS ULTIMOS/      # SQLs finales
â”‚   â”‚   â”œâ”€â”€ tabla vacunas cred_ivan.sql  # Tabla Vacunas/CRED
â”‚   â”‚   â”œâ”€â”€ tabla_materno_ivan.sql       # Tabla Materno
â”‚   â”‚   â”œâ”€â”€ tabla_iras_edas_ivan_2026.sql # Tabla IRAS/EDAS
â”‚   â”‚   â”œâ”€â”€ reporte_cred_ivan_2026.sql   # SP CRED (~6226 lÃ­neas)
â”‚   â”‚   â””â”€â”€ reporte_iras_edas_2026_ivan.sql
â”‚   â”œâ”€â”€ scripst tabla y reportes vacunas-cred/
â”‚   â”œâ”€â”€ reportes/                        # Reportes SQL
â”‚   â”œâ”€â”€ PADRONES/                        # SQLs de padrÃ³n
â”‚   â””â”€â”€ reportes exel/                   # HTMLs de referencia + Excel
â”‚       â”œâ”€â”€ referencia de formato exel cred.txt
â”‚       â”œâ”€â”€ referencia de foramto exel iras_edas.txt
â”‚       â”œâ”€â”€ CRED FINAL 2026.xlsm
â”‚       â””â”€â”€ IRAS_EDAS 2026.xlsm
â”‚
â”œâ”€â”€ config/                              # Config persistente
â”‚   â””â”€â”€ db_connection.json               # Config BD guardada
â”‚
â””â”€â”€ proyecto-salud-pkg/                  # Paquete pacman Linux
```

### 1.3 Pipeline de Datos Completo

```
ARCHIVOS CRUDOS (11_CUSCO_MM.zip/rar/7z)
  â”‚  (mensuales por mes, contienen CSVs con datos HIS)
  â–¼
EXTRACTOR (extractor_archivos.py, externo)
  â”‚  (descompresiÃ³n a carpeta temporal)
  â–¼
CARGA CSV (01cargacvs_universal.py o 01cargacvs_mensual.py)
  â”‚  Lee CSVs â†’ staging table: es_ivan.hisminsa24
  â”‚  (todos los archivos CSV del mes/aÃ±o)
  â–¼
CARGA MAESTROS (cargar_maestros.py)
  â”‚  Tablas: maestro_paciente, maestro_personal, eess2025,
  â”‚  maestro_his_cie_cpms, maestro_his_*, etc.
  â–¼
GENERAR HIS PROCESO (generar_his_proceso.py)
  â”‚  ETL principal: JOIN hisminsa24 + maestros
  â”‚  â†’ es_ivan.his_proceso_YYYY (tabla detalle)
  â”‚  (~1,046 lÃ­neas, la transformaciÃ³n mÃ¡s compleja)
  â–¼
TABLAS AGREGADAS:
  â”œâ”€ generar_tabla_vacunas.py â†’ es_ivan.tabla_vacunas
  â”œâ”€ generar_cred.py          â†’ es_ivan.cred2024* (5 tablas)
  â”‚                               cred2024 (270 cols, crosstab)
  â”‚                               cred2024_1 (267 cols)
  â”‚                               cred2024_2 (34 cols)
  â”‚                               cred2024_3 (163 cols)
  â”‚                               cred2024_4 (174 cols)
  â”œâ”€ generar_pai.py           â†’ es_ivan.pai_2024* (2 tablas)
  â”œâ”€ SQL Scripts              â†’ es_ivan.tabla_materno
  â”‚                              es_ivan.tabla_iras_edas
  â””â”€ Cargas externas:
     â”œâ”€ cargar_padron_nominal.py â†’ es_ivan.padron_nominal
     â””â”€ cargar_cnv.py           â†’ es_ivan.cnv_cusco
```

---

## 2. CONFIGURACIÃ“N DE BASE DE DATOS (db_config.py)

**Archivo**: `db_config.py` (~1476 lÃ­neas)
**PropÃ³sito**: GestiÃ³n centralizada de conexiÃ³n PostgreSQL

### 2.1 ParÃ¡metros por Defecto

| ParÃ¡metro | Valor | Variable de Entorno |
|-----------|-------|---------------------|
| Host | localhost | DB_HOST |
| Puerto | 5432 | DB_PORT |
| Base de Datos | ivan_proceso_his | DB_NAME |
| Esquema | es_ivan | DB_SCHEMA |
| Usuario | postgres | DB_USER |
| ContraseÃ±a | ivan | DB_PASSWORD |

### 2.2 Persistencia

- Config guardada en: `%APPDATA%/Proyecto_Salud_Cusco/config/db_connection.json`
- Formato JSON con todos los parÃ¡metros
- Lectura automÃ¡tica al iniciar la app
- Si no existe, se crea con defaults

### 2.3 Funciones Clave

| FunciÃ³n | PropÃ³sito |
|---------|-----------|
| `get_db_config()` | Retorna DBConfig singleton (cargado de archivo o defaults) |
| `update_db_config(host, port, database, schema, password)` | Guarda nueva config en JSON |
| `detectar_postgresql_existente()` | Detecta PostgreSQL instalado (cross-platform) |
| `verificar_bd_esquema(config)` | Verifica BD y esquema existen |
| `inicializar_base_datos(log)` | Crea BD y esquema si faltan |
| `_detectar_postgresql_linux()` | DetecciÃ³n Linux: which psql, systemctl |
| `_pgpass_paths()` | Busca pgpass en rutas estÃ¡ndar |

### 2.4 Endpoints Web Relacionados

```
/api/db/config [GET, POST]     â†’ Obtener/Guardar config
/api/db/detect [POST]          â†’ Detectar PostgreSQL
/api/db/verify [POST]          â†’ Verificar BD+esquema
/api/db/install [POST]         â†’ Instalar PostgreSQL
/api/db/start-service [POST]   â†’ Iniciar servicio PostgreSQL
/api/db/init [POST]           â†’ Crear BD+esquema
/api/db/recover-password [POST] â†’ Recuperar/crear base de datos
```

---

## 3. API REST FLASK (app.py)

**Archivo**: `proyecto_salud_cusco_web/app.py` (~4770 lÃ­neas)
**Framework**: Flask 2.x con CORS habilitado
**Puerto**: 5000
**Host**: 0.0.0.0 (accesible desde la red local)

### 3.1 InicializaciÃ³n

```python
app = Flask(__name__,
    template_folder=BASE_DIR/'templates',
    static_folder=BASE_DIR/'static',
    static_url_path='/static')
app.secret_key = 'sistema-salud-cusco-web-2026'
CORS(app)
```

- Template Ãºnico: `index.html` (SPA)
- Archivos estÃ¡ticos: `/static/js/*`, `/static/css/*`
- Cache deshabilitado para HTML y JS (vÃ­a `@app.after_request`)
- Debug mode controlado por `FLASK_DEBUG` env var (desactivado por defecto)

### 3.2 Helper Utilities

| FunciÃ³n | LÃ­nea | PropÃ³sito |
|---------|-------|-----------|
| `_nuevo_token()` | 62 | Genera UUID para seguimiento de ejecuciones |
| `_init_state(token, nombre)` | 65 | Inicializa estado de ejecuciÃ³n |
| `_append_line(token, line)` | 80 | Agrega lÃ­nea al log de ejecuciÃ³n |
| `_set_progress(token, ...)` | 90 | Actualiza progreso (done/total/porcentaje/ETA) |
| `_set_status(token, status, ...)` | 105 | Cambia estado (starting/running/completed/error/cancelled) |
| `_get_state(token)` | 118 | Obtiene estado actual de ejecuciÃ³n |
| `_cleanup_old_states()` | 125 | Limpia estados viejos (>5 min) |
| `_resolver_ruta_script(script_rel)` | 133 | Resuelve ruta absoluta de script (soporta PyInstaller) |
| `_cargar_config_editor()` | 140 | Carga configuraciÃ³n del editor SQL |
| `_guardar_config_editor(config)` | 147 | Guarda configuraciÃ³n del editor SQL |
| `ejecutar_script(ruta_script, args, mostrar_progreso)` | 152 | Ejecuta script Python/SQL en hilo separado con polling |
| `_db_cursor()` | 726 | Obtiene conexiÃ³n PostgreSQL |
| `_get_esquema()` | 1063 | Retorna nombre del esquema |
| `_tabla_existe(nombre_tabla)` | 733 | Verifica si tabla existe en BD |
| `_meses_con_datos(anio)` | 418 | Retorna meses con datos en BD |
| `_borrar_anio_bd(anio)` | 436 | Borra registros de un aÃ±o |
| `_resolve_year_table(cur, schema, template, year, fallback)` | 1099 | Resuelve tabla por aÃ±o con fallback |
| `_compute_python_kde(coords, grid_size)` | 1207 | KDE gaussiano sin SciPy para mapas de calor |
| `_qident(value)` / `_qcol(column)` / `_qtable(schema, table)` | 1074 | SQL safe-quoting |

### 3.3 Endpoints Completos (66 endpoints)

#### 3.3.1 PÃ¡gina Principal

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| GET | / | `index()` | Renderiza index.html (SPA) |
| GET | /_ah/health | `health()` | Health check para Google Cloud |

#### 3.3.2 Base de Datos (7 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| GET, POST | /api/db/config | `db_config()` | Obtener/Guardar config BD |
| POST | /api/db/detect | `db_detect()` | Detectar PostgreSQL instalado |
| POST | /api/db/verify | `db_verify()` | Verificar BD+esquema |
| POST | /api/db/install | `db_install()` | Instalar PostgreSQL (script externo) |
| POST | /api/db/start-service | `db_start_service()` | Iniciar servicio PostgreSQL |
| POST | /api/db/init | `db_init()` | Crear BD+esquema |
| POST | /api/db/recover-password | `db_recover_password()` | Recuperar/inicializar base de datos |

#### 3.3.3 EjecuciÃ³n (2 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| GET | /api/ejecucion/status/<token> | `ejecucion_status()` | Estado de ejecuciÃ³n (polling) |
| POST | /api/ejecucion/cancel | `ejecucion_cancel()` | Cancelar ejecuciÃ³n en curso |

#### 3.3.4 Ingesta (4 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| POST | /api/ingesta/check | `ingesta_check()` | Verificar meses con datos en BD |
| POST | /api/ingesta/import | `ingesta_import()` | Importar CSVs (modo reemplazar/completar) |
| POST | /api/ingesta/refresh | `ingesta_refresh()` | Refrescar HIS proceso con maestros actualizados |
| POST | /api/ingesta/delete | `ingesta_delete()` | Eliminar datos (todo/aÃ±o/mes) |

#### 3.3.5 Reportes SQL (4 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| GET | /api/reportes/config | `reportes_config()` | Obtener botones/config del editor |
| POST | /api/reportes/run | `reportes_run()` | Ejecutar script SQL/Python |
| POST | /api/reportes/save-config | `reportes_save_config()` | Guardar configuraciÃ³n del editor |
| POST | /api/reportes/new | `reportes_new()` | Crear nuevo reporte SQL |
| POST | /api/reportes/delete | `reportes_delete()` | Eliminar reporte |

#### 3.3.6 Maestros (7 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| GET | /api/maestros/tablas | `maestros_tablas()` | Listar tablas del esquema |
| POST | /api/maestros/ejecutar | `maestros_ejecutar()` | Ejecutar script de maestros |
| POST | /api/maestros/csv-list | `maestros_csv_list()` | Listar CSVs en carpeta |
| POST | /api/maestros/eliminar | `maestros_eliminar()` | Eliminar tablas seleccionadas |
| POST | /api/maestros/eliminar-todos | `maestros_eliminar_todos()` | Eliminar todas las tablas maestro* |
| GET | /api/maestros/descriptions | `maestros_descriptions()` | Descripciones de tablas maestro |
| GET | /api/maestros/estado (en script) | - | Estado de carga de maestros |

#### 3.3.7 PadrÃ³n Nominal (5 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| GET | /api/padron/status | `padron_status()` | Estado de tabla padron_nominal |
| POST | /api/padron/cargar | `padron_cargar()` | Cargar PN desde CSV |
| POST | /api/padron/consulta | `padron_consulta()` | Consultar PN con paginaciÃ³n/bÃºsqueda |
| GET | /api/padron/geojson | `padron_geojson()` | GeoJSON para mapa (hasta 5000 pts) |
| POST | /api/padron/exportar | (en script) | Exportar a Excel |

#### 3.3.8 CNV (3 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| GET | /api/cnv/status | `cnv_status()` | Estado de tabla cnv_cusco |
| POST | /api/cnv/cargar | `cnv_cargar()` | Cargar CNV desde CSV |
| POST | /api/cnv/consulta | `cnv_consulta()` | Consultar CNV con paginaciÃ³n |

#### 3.3.9 Mapa / GeolocalizaciÃ³n (4 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| POST | /api/mapa/kde | `mapa_kde()` | KDE heatmap (PN, IRAS o EDAS) |
| GET | /api/mapa/establecimientos | `mapa_establecimientos()` | Listar establecimientos |
| GET | /api/mapa/pacientes-por-distrito | `mapa_pacientes_por_distrito()` | Conteo PN por distrito |
| GET | /api/poblacion/resumen | `dash_poblacion()` | Resumen poblaciÃ³n/demografÃ­a |

#### 3.3.10 Dashboards (6 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| GET | /api/dashboards/resumen | `dashboards_resumen_old()` | Resumen conteo tablas |
| GET | /api/dashboards/iras-edas | `dash_iras_edas()` | Dashboard IRAS/EDAS |
| GET | /api/dashboards/vacunacion | `dash_vacunacion()` | Dashboard VacunaciÃ³n |
| GET | /api/dashboards/cred | `dash_cred()` | Dashboard CRED |
| GET | /api/dashboards/suplementacion | `dash_suplementacion()` | Dashboard SuplementaciÃ³n |
| GET | /api/dashboards/materno | `dash_materno()` | Dashboard Materno |
| GET | /api/dashboards/poblacion | `dash_poblacion()` | Dashboard PoblaciÃ³n |

#### 3.3.11 Formatos MINSA (4 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| GET | /api/reportes-minsa/filtros | `reportes_minsa_filtros()` | Opciones de filtro (red, microred, etc.) |
| POST | /api/reportes-minsa/ejecutar | `reportes_minsa_ejecutar()` | Generar reporte MINSA |
| POST | /api/reportes-minsa/exportar | `reportes_minsa_exportar()` | Exportar a Excel |
| GET | /api/reportes-minsa/vista-previa | `reportes_minsa_vista_previa()` | Vista standalone HTML |

#### 3.3.12 Editor SQL (7 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| GET | /api/editor/archivos | (en JS) | Listar archivos SQL |
| POST | /api/editor/abrir | (en JS) | Abrir archivo SQL |
| POST | /api/editor/guardar | (en JS) | Guardar archivo SQL |
| POST | /api/editor/ejecutar | (en JS) | Ejecutar SQL desde editor |
| POST | /api/editor/crear | (en JS) | Crear nuevo archivo SQL |
| POST | /api/editor/eliminar | (en JS) | Eliminar archivo SQL |
| POST | /api/editor/config | (en JS) | Config botones editor |

#### 3.3.13 Consulta SQL (2 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| POST | /api/consulta/ejecutar | (en app.py) | Ejecutar consulta SQL ad-hoc |
| GET | /api/consulta/tablas | (en app.py) | Listar tablas disponibles |

#### 3.3.14 Tunnel / Acceso Remoto (3 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| POST | /api/tunnel/iniciar | `tunnel_iniciar()` | Iniciar Cloudflare Tunnel |
| GET | /api/tunnel/status | `tunnel_status()` | Estado del tÃºnel |
| POST | /api/tunnel/detener | `tunnel_detener()` | Detener tÃºnel |

#### 3.3.15 Sistema / Utilidad (6 endpoints)

| MÃ©todo | Ruta | FunciÃ³n | PropÃ³sito |
|--------|------|---------|-----------|
| POST | /api/theme | `theme_set()` | Cambiar tema (claro/oscuro) |
| GET | /api/config | `app_config()` | Config general |
| GET | /api/categorias | `categorias_list()` | Listar categorÃ­as |
| POST | /api/seleccionar-carpeta | `seleccionar_carpeta()` | Selector nativo de carpeta |
| POST | /api/listar-carpeta | `listar_carpeta()` | Explorador de carpetas web |
| POST | /api/his-proceso/generar | (en app.py) | Generar HIS proceso |

---

## 4. FRONTEND SPA

### 4.1 Estructura General

El frontend es una **Single Page Application** (SPA) con todo el HTML embebido en `index.html`.

**Archivos**:
- `templates/index.html` â†’ Estructura HTML completa (todos los mÃ³dulos)
- `static/js/app.js` â†’ Core: navegaciÃ³n, polling, modales (~1340 lÃ­neas)
- `static/js/modules.js` â†’ MÃ³dulos especÃ­ficos: PN, CNV, Mapas, Dashboards, MINSA (~1249 lÃ­neas)
- `static/css/style.css` â†’ Estilos con tema claro/oscuro (~1304 lÃ­neas)

### 4.2 Sistema de Temas

```javascript
// app.js
function setThemeMode(theme) {
    document.documentElement.setAttribute('data-theme', mode);
}
```

- Persistencia: `localStorage.getItem('psc_theme')`
- Default: claro (`data-theme="light"`)
- Toggle button #theme-toggle

### 4.3 NavegaciÃ³n (app.js)

```javascript
document.querySelectorAll('.nav-btn[data-module]')
// MÃ³dulos: bd, ingesta, reportes, maestros, consulta, editor,
//          dashboards, poblacion, mapa, minsa, tunnel
```

**ProtecciÃ³n**: Los mÃ³dulos ingesta/reportes/maestros requieren BD verificada (`S.bdOk`).

### 4.4 Sistema de Polling (app.js)

```javascript
const S = {
    bdOk: false, ejecutando: false, activeToken: 0,
    pollTimer: null, pollLastLine: {},
    ingTotal: 0, ingDone: 0, ingStart: 0, ingEta: ''
};
```

**Flujo**: POST â†’ recibe token â†’ polling 800ms â†’ muestra lÃ­neas nuevas â†’ barra progreso â†’ detecta estados terminales â†’ botÃ³n cancelar.

### 4.5 MÃ³dulos del Frontend (modules.js)

#### 4.5.1 PadrÃ³n Nominal (PN)
```javascript
var PN = { pagina: 1, total: 0, porPagina: 50 };
async function pnCargar()     â†’ POST /api/padron/cargar
async function pnConsultar()  â†’ POST /api/padron/consulta (paginaciÃ³n 50)
function pnRenderTabla(d)     â†’ Renderiza tabla HTML
```

#### 4.5.2 CNV
```javascript
var CNV = { pagina: 1, total: 0, porPagina: 50 };
async function cnvCargar()    â†’ POST /api/cnv/cargar
async function cnvConsultar() â†’ POST /api/cnv/consulta
```

#### 4.5.3 Dashboard (6 dashboards)
```javascript
var dashCharts = {};
function dashCambiar(vista)   â†’ Resumen, IRAS/EDAS, VacunaciÃ³n, CRED, SuplementaciÃ³n, Materno, PoblaciÃ³n
async function dashCargar(tipo, anio, extras)
```

#### 4.5.4 Mapa (Leaflet)
```javascript
var MAPA = null;
function mapaInit()          â†’ Inicializa mapa Leaflet
async function mapaKDE()     â†’ POST /api/mapa/kde
```

#### 4.5.5 Formatos MINSA
```javascript
var RM_DATA = null;
var RM_TAB_ACTUAL = 0;

async function rmInit()      â†’ GET /api/reportes-minsa/filtros
async function rmEjecutar()  â†’ POST /api/reportes-minsa/ejecutar
function rmRender(d)         â†’ Renderiza resultado con pestaÃ±as
function rmRenderPagina(p)   â†’ Renderiza pÃ¡gina individual
function rmExportar()        â†’ POST /api/reportes-minsa/exportar
```

---

## 5. GENERADOR HTML REPORTES MINSA (html_report_builder.py)

**Archivo**: `proyecto_salud_cusco_web/html_report_builder.py` (~1664 lÃ­neas)

### 5.1 Arquitectura

El builder genera HTML para los formatos oficiales DIRESA CUSCO usando CSS classes que coinciden exactamente con los archivos de referencia en `scripts_sql/reportes/reportes exel/`.

### 5.2 Funciones Principales

| FunciÃ³n | LÃ­nea | PropÃ³sito |
|---------|-------|-----------|
| `_REPORT_CSS` | 59 | CSS completo del reporte (~35 reglas) |
| `_esc(v)` | 10 | Escape HTML |
| `_fmt(v)` | 16 | Formateo de nÃºmeros |
| `_v(d, k)` | 25 | Valor desde dict con default 0 |
| `_num(v)` | 37 | TD con clase numÃ©rica |
| `_td(v, cls)` | 45 | TD genÃ©rico |
| `_s(d, k)` | 52 | Shortcut para _td(_v(d, k)) |
| `_sec_header(filtros)` | 100 | Encabezado con filtros (.filter-row + .filter-row2) |
| `_sec_cred_controls(col_names, filas, totales)` | 128 | Tabla Control CRED (13 cols fijas) |
| `_sec_atencion_rn(c24, c1, c4)` | 169 | AtenciÃ³n del RN (dual-grid, 6 sub-secciones) |
| `_sec_sesiones(all_data)` | 315 | Sesiones de estimulaciÃ³n temprana |
| `_sec_lactancia(all_data)` | 337 | Lactancia materna (tabla 50% width) |
| `_sec_evaluacion_desarrollo(all_data)` | 284 | EvaluaciÃ³n del desarrollo (rowspan 3, 13 cols) |
| `_sec_plan_integral(all_data)` | 355 | Plan integral (13 edades, elaborado/ejecutado) |
| `_sec_consejeria(all_data)` | 387 | ConsejerÃ­a (10 items Ã— 14 columnas) |
| `_sec_evaluacion_nutricional(all_data)` | 478 | EvaluaciÃ³n nutricional + IMC 5-11a + Parasitosis |
| `_sec_laboratorio(all_data)` | 555 | Laboratorio/tamizajes (5 grupos etarios Ã— 3 cols) |
| `_sec_profilaxis(all_data)` | 604 | Profilaxis antiparasitaria (1ra/2da dosis) |
| `_sec_visita_domiciliaria(all_data)` | 629 | Visita domiciliaria (5 tipos Ã— 7 edades) |
| `_sec_salud_mental(all_data)` | 662 | Salud mental (dual-grid: psicosocial + agudeza/postural/tanner) |
| `_sec_tamizajes(all_data)` | 731 | Tamizajes (violencia, depresiÃ³n, alcohol, neurodesarrollo) |
| `_sec_tamizajes_positivos(all_data)` | 767 | Tamizajes positivos |
| `_sec_rop(all_data)` | 801 | ROP (12 actividades Ã— 4 edades) |
| `_sec_salud_ocular_menor3(all_data)` | 842 | Salud ocular <3a (4 actividades Ã— 6 edades) |
| `_sec_errores_refraccion(all_data)` | 870 | Errores refracciÃ³n (3 categorÃ­as Ã— 3 edades) |
| `_sec_iras_edas(all_data)` | 908 | IRAS/EDAS (IRA + SOB + EDA + Zinc/SRO con colgroups) |
| `build_page1_html(...)` | 1069 | PÃ¡gina 1 completa (6 secciones del ref) |
| `build_iras_edas_html(data)` | 1109 | IRAS/EDAS standalone (IRA con fÃ³rmulas, oxigenoterapia, SOB 7 edades, EDA 3 edades, Zinc, Resumen) |
| `build_suplementacion_html(secciones)` | 1645 | PÃ¡gina 2: SuplementaciÃ³n |
| `build_tx_anemia_html(secciones)` | 1656 | PÃ¡gina 3: Tratamiento Anemia |
| `_render_seccion_table(sec)` | 1602 | Renderiza secciÃ³n genÃ©rica con CSS classes |

### 5.3 Estructura de PÃ¡gina 1 (CRED)

```
<div class="page">
  <div class="header">DIRESA CUSCO...</div>
  <div class="filter-row">4 columnas filtros</div>
  <div class="filter-row2">5 columnas filtros</div>

  <div class="section-title">CONTROL DE CRECIMIENTO Y DESARROLLO DEL NIÃ‘O(A)</div>
  <div class="sub-section-title">NÂ° de Controles de Crecimiento y Desarrollo de 0 a 11 AÃ±os</div>
  <table> 13 columnas (GRUPO ETAREO + PROGRAMACIÃ“N + 11 controles) </table>

  <div class="section-title">I. ATENCIÃ“N DEL RECIÃ‰N NACIDO</div>
  <div class="dual-grid">
    <div> AtenciÃ³n Inmediata + CondiciÃ³n Nacimiento + Tamizaje Neonatal </div>
    <div> Alojamiento Conjunto + ConsejerÃ­a + Visita Domiciliaria </div>
  </div>

  <div class="section-title">IX. EVALUACIÃ“N DEL DESARROLLO</div>
  <table> (header con rowspan=3, 13 cols) </table>

  <div class="dual-grid">
    <div class="sub-section-title">II. SESIONES DE ATENCIÃ“N TEMPRANA</div>
    <table>
    <div class="section-title">VI. LACTANCIA MATERNA EXCLUSIVA</div>
    <table style="width:50%">
  </div>

  <div class="section-title">XVI. ATENCIÃ“N DE LAS ENFERMEDADES PREVALENTES DE LA INFANCIA</div>
  <table> IRA + SOB/Asma + EDA + Zinc/SRO </table>
</div>
```

### 5.4 Archivos de Referencia (guÃ­a exacta)

UbicaciÃ³n: `scripts_sql/reportes/reportes exel/`

1. **`referencia de formato exel cred.txt`** (566 lÃ­neas)
   - HTML completo del reporte CRED
   - CSS completo + estructura de 6 secciones
   - Colgroups: 14%+9%+7%Ã—11 (Control CRED)

2. **`referencia de foramto exel iras_edas.txt`** (678 lÃ­neas)
   - HTML completo del reporte IRAS/EDAS
   - Secciones: IRA (9 cols con fÃ³rmulas), Oxigenoterapia, SOB/Asma (10 cols), EDA (6 cols), Zinc/SRO, Resumen

3. **`CRED FINAL 2026.xlsm`** - Excel original
4. **`IRAS_EDAS 2026.xlsm`** - Excel original

---

## 6. PIPELINE DE DATOS DETALLADO

### 6.1 Carga CSV (Ingesta)

**Script**: `01cargacvs_universal.py` o `01cargacvs_mensual.py`

1. Recibe: aÃ±o (y opcionalmente meses/ruta carpeta)
2. Busca archivos CSV (patrÃ³n: `*MM*.csv`, `11_CUSCO_MM*.csv`, etc.)
3. Para cada CSV: detecta encoding, lee con pandas en chunks, mapea columnas, inserta
4. Tabla destino: `es_ivan.hisminsa24`

### 6.2 Carga de Maestros

**Script**: `cargar_maestros.py`
- Busca archivos CSV/DAT, identifica tipo por nombre, carga a tabla correspondiente

### 6.3 GeneraciÃ³n HIS Proceso (ETL Core)

**Script**: `generar_his_proceso.py` (~1046 lÃ­neas)
- JOIN hisminsa24 + maestros â†’ `his_proceso_YYYY`

### 6.4 GeneraciÃ³n de Tablas Agregadas

| Script | Tabla(s) | Filas |
|--------|----------|-------|
| `generar_tabla_vacunas.py` | `tabla_vacunas` | 13,108,188 |
| `generar_cred.py` | `cred2024`, `cred2024_1..4` | 4,481 |
| `generar_pai.py` | `pai_2024`, `pai_2024_1` | 4,481 |
| SQL: `tabla vacunas cred_ivan.sql` | `tabla_vacunas` | 13,108,188 |
| SQL: `tabla_materno_ivan.sql` | `tabla_materno` | 1,531,528 |
| SQL: `tabla_iras_edas_ivan_2026.sql` | `tabla_iras_edas` | 911,199 |

### 6.5 Carga PadrÃ³n Nominal
**Script**: `cargar_padron_nominal.py` â†’ 347,265 registros

### 6.6 Carga CNV
**Script**: `cargar_cnv.py` â†’ 257,019 registros

---

## 7. EJECUCIÃ“N DE SCRIPTS (Polling)

### 7.1 Estado Compartido Thread-Safe

```python
_exec_state = {}              # dict(token â†’ state)
_exec_state_lock = threading.Lock()
_active_process = None        # subprocess activo
_active_process_lock = threading.Lock()
```

### 7.2 Estados

| Estado | DescripciÃ³n |
|--------|-------------|
| `starting` | Iniciando proceso |
| `running` | EjecutÃ¡ndose |
| `completed` | Terminado exitosamente |
| `error` | Error |
| `cancelled` | Cancelado por usuario |

### 7.3 Respuesta de Estado

```json
{
    "token": "uuid", "nombre": "script_name", "status": "running",
    "lines": ["line1", ...], "line_count": 42,
    "progress": { "done": 50, "total": 100, "porcentaje": 0.5, "eta": "2m 30s" },
    "start_time": 1234567890.123, "end_time": null, "exit_code": null, "error": null
}
```

### 7.4 Progreso desde Scripts

```
[PROGRESS]TOTAL=100
[PROGRESS]DONE=50|PCT=50|ETA=2m 30s
```

---

## 8. CLOUDFLARE TUNNEL

| MÃ©todo | Ruta | FunciÃ³n |
|--------|------|---------|
| POST | /api/tunnel/iniciar | Inicia cloudflared tunnel |
| GET | /api/tunnel/status | Estado del tÃºnel |
| POST | /api/tunnel/detener | Detiene el tÃºnel |

---

## 9. BASES DE DATOS Y TABLAS

### 9.1 Esquema: `es_ivan`

| Tabla | Tipo | Filas | PropÃ³sito |
|-------|------|-------|-----------|
| `hisminsa24` | Staging | Variable | Datos crudos de importaciÃ³n CSV |
| `his_proceso_YYYY` | Detalle | Millones | Datos enriquecidos por aÃ±o |
| `padron_nominal` | Maestro | 347,265 | PadrÃ³n nominal de niÃ±os |
| `cnv_cusco` | Maestro | 257,019 | Certificados de nacido vivo |
| `maestro_*` (22 tablas) | Maestro | Variable | CatÃ¡logos del sistema |
| `eess2025` | Maestro | ~400 | Establecimientos de salud |
| `tabla_vacunas` | Agregada | 13,108,188 | VacunaciÃ³n |
| `tabla_materno` | Agregada | 1,531,528 | AtenciÃ³n materna |
| `tabla_iras_edas` | Agregada | 911,199 | IRAS/EDAS |
| `cred2024*` (5 tablas) | Agregada | 4,481 | CRED crosstab |
| `pai_2024*` (2 tablas) | Agregada | 4,481 | PAI crosstab |

---

## 10. DESPLIEGUE

### 10.1 Local (Desarrollo)

```bash
cd proyecto_salud_cusco_web
venv\Scripts\python app.py
# Abrir http://localhost:5000
```

### 10.2 VPS (ProducciÃ³n)

- **Oracle Cloud Free Tier** (gratis siempre): En proceso de creaciÃ³n
- **Hetzner CX22** (â‚¬3.99/mes): Plan B
- Tunnel Cloudflare para acceso remoto temporal

---

## 11. CONFIGURACIÃ“N CRUZADA (app.py â†” frontend)

### 11.1 Versiones de Archivos EstÃ¡ticos

```html
<script src="/static/js/modules.js?v=3"></script>
```

Para forzar recarga, incrementar `?v=` en `index.html`.

### 11.2 Cache-Control

Flask agrega headers anti-cache para HTML y JS.

### 11.3 Formato de Respuesta API

```json
{
    "tipo": "formato_nino_cred",
    "anio": "2024",
    "meses": [1,2,3,4,5,6,7,8,9,10,11,12],
    "filtros": {},
    "paginas": [
        {
            "id": "formato_nino",
            "titulo": "FORMATO NIÃ‘O - CRED",
            "tabla_html": "<style>...</style><div class=\"page\">...</div>",
            "columnas": [...],
            "filas": [...],
            "totales": {...},
            "secciones": [...]
        }
    ]
}
```

---

## 12. ARCHIVOS DE REFERENCIA (HTML EXACTO)

Para replicar visualmente los formatos, usar los HTMLs en:
`scripts_sql/reportes/reportes exel/`

**CSS clave del ref**:
- `* { box-sizing: border-box; margin: 0; padding: 0; }`
- `body { font-family: Arial; font-size: 10px; }`
- `.page { max-width: 1400px; margin: 0 auto; }`
- `.section-title { background: #4472C4; color: #fff; text-transform: uppercase; }`
- `.dual-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }`
- `@media print { @page { size: A3 landscape; margin: 10mm; } }`

---

## 13. FLUJO DE TRABAJO TÃPICO

### Usuario nuevo:
1. Abrir `http://localhost:5000`
2. Ir a "Configurar BD" â†’ Detectar â†’ Verificar â†’ Iniciar BD
3. Ir a "Ingesta" â†’ Seleccionar carpeta con CSVs â†’ Importar (modo reemplazar)
4. Ir a "Procesar" â†’ Cargar maestros â†’ Generar HIS Proceso
5. Ir a "Reportes" â†’ Generar tablas agregadas
6. Ir a "Formatos MINSA" â†’ Seleccionar aÃ±o/meses â†’ Generar reporte
7. Usar Dashboards para visualizaciÃ³n rÃ¡pida
8. Usar Mapa para geolocalizaciÃ³n

### Usuario existente (solo actualizar datos):
1. Ir a "Ingesta" â†’ Importar nuevos CSVs (modo completar)
2. Ir a "Procesar" â†’ Refrescar HIS proceso
3. Ir a "Reportes" â†’ Regenerar tablas agregadas
4. Ir a "Formatos MINSA" â†’ Generar reporte actualizado

---

## 14. DIAGNÃ“STICO DE ERRORES DEL MÃ“DULO FORMATOS MINSA

### 14.1 LISTA COMPLETA DE ERRORES CONOCIDOS (CRÃTICOS Y MENORES)

A continuaciÃ³n se enumeran **todos los errores** identificados en el mÃ³dulo Formatos MINSA al momento de esta documentaciÃ³n. Se clasifican por gravedad y se detalla la causa raÃ­z, el archivo/ lÃ­nea y la soluciÃ³n.

---

### 14.2 ERRORES BLOQUEANTES (CRÃTICOS)

#### E01. Error de sintaxis JS: `/*` sin `*/` en modules.js

**Archivo**: `static/js/modules.js`
**LÃ­nea**: ~908 (entre dashPoblacion y el resto del cÃ³digo)
**SÃ­ntoma**: Todo el JavaScript despuÃ©s del bloque `/*` abierto dejaba de ejecutarse. Los mÃ³dulos Mapa, Dashboards y Formatos MINSA no funcionaban. El error se ve en consola del navegador como `Uncaught SyntaxError: Unexpected end of input`.
**Causa**: Un bloque de comentario `/* ... */` se abriÃ³ pero nunca se cerrÃ³ con `*/`.
**SoluciÃ³n**: Cerrar el comentario con `*/` antes del `catch` o eliminar el bloque.
**Estado**: CORREGIDO.

#### E02. `tabla_html` sin `<style>` en aÃ±os â‰  2024

**Archivo**: `app.py` en `_reporte_completo_cred_old()`
**LÃ­nea**: ~3894
**SÃ­ntoma**: Para aÃ±os 2025/2026, el HTML generado contenÃ­a las clases CSS (`.section-title`, `.th-dark`, etc.) pero NO incluÃ­a el `<style>` con las reglas CSS. El navegador no aplicaba los estilos y el reporte se veÃ­a como HTML plano (texto negro sobre fondo blanco, sin bordes, sin colores).
**Causa**: El loop que genera `tabla_html` para aÃ±os viejos no anteponÃ­a `'<style>' + _REPORT_CSS + '</style>'` al HTML.
**SoluciÃ³n**: Agregar `'<style>' + _REPORT_CSS + '</style>'` al inicio del `tabla_html` generado en el loop de pÃ¡ginas.
**Estado**: CORREGIDO.

#### E03. Columnas dinÃ¡micas en `_sec_cred_controls` no coinciden con el ref

**Archivo**: `html_report_builder.py` en `_sec_cred_controls()`
**LÃ­nea**: 128-164
**SÃ­ntoma**: Originalmente usaba `col_names[2:]` para determinar las columnas de controles, que producÃ­a un nÃºmero variable de columnas. El ref HTML exige exactamente 13 columnas fijas: GRUPO ETAREO + PROGRAMACIÃ“N + 11 controles (1er Ctrl 29-59d ... 11vo Ctrl).
**Causa**: El cÃ³digo original generaba columnas dinÃ¡micas desde la consulta BD.
**SoluciÃ³n**: Reemplazar con 13 columnas fijas usando `ctrl_names` y `ctrl_keys` hardcodeados.
**Estado**: CORREGIDO.

#### E04. Colgroups faltantes en `_sec_cred_controls` e `_sec_iras_edas`

**Archivo**: `html_report_builder.py`
**LÃ­neas**: 128-164 y 908-1064
**SÃ­ntoma**: Las tablas no tenÃ­an `<colgroup>` o tenÃ­an widths incorrectos. El ref HTML especifica widths exactos: 14%+9%+7%Ã—11 para Control CRED; 28%+10%Ã—6+12% para IRA/SOB; 28%+11%Ã—6+12% para EDA/Zinc.
**Causa**: El builder original no incluÃ­a `<colgroup>`.
**SoluciÃ³n**: Agregar `<colgroup>` con los % exactos del ref.
**Estado**: CORREGIDO.

#### E05. Segundo `.filter-row` usaba clase incorrecta

**Archivo**: `html_report_builder.py` en `_sec_header()`
**LÃ­nea**: 100-123
**SÃ­ntoma**: El header tenÃ­a dos filas de filtros pero ambas usaban `class="filter-row"`. El ref HTML usa `.filter-row` (4 columnas, border-top + border-bottom) y `.filter-row2` (5 columnas, solo border-bottom).
**Causa**: CÃ³digo original usaba `filter-row` para ambas.
**SoluciÃ³n**: Cambiar la segunda fila a `class="filter-row2"` con 5 columnas (Ãºltima vacÃ­a).
**Estado**: CORREGIDO.

#### E06. Header VD con texto incorrecto "ACTIVIDADES"

**Archivo**: `html_report_builder.py` en `_sec_atencion_rn()`
**LÃ­nea**: ~262
**SÃ­ntoma**: La secciÃ³n "E) AtenciÃ³n del ReciÃ©n Nacido en Visita Domiciliaria" tenÃ­a header `ACTIVIDADES` pero el ref HTML dice `DIAGNÃ“STICOS`.
**Causa**: Copia incorrecta del label del ref.
**SoluciÃ³n**: Cambiar "ACTIVIDADES" a "DIAGNÃ“STICOS".
**Estado**: CORREGIDO.

#### E07. Secciones extra en PÃ¡gina 1 que no estÃ¡n en el ref

**Archivo**: `html_report_builder.py` en `build_page1_html()`
**LÃ­nea**: ~1069-1103
**SÃ­ntoma**: La pÃ¡gina 1 incluÃ­a 11 secciones extras: Plan Integral, ConsejerÃ­a, EvaluaciÃ³n Nutricional, Laboratorio/ Tamizajes, Profilaxis Antiparasitaria, Visita Domiciliaria, Salud Mental, Tamizajes, Tamizajes Positivos, ROP, Salud Ocular, Errores RefracciÃ³n. El ref HTML solo tiene 6 secciones: Control CRED, AtenciÃ³n RN, EvaluaciÃ³n Desarrollo, Sesiones, Lactancia, IRAS/EDAS.
**Causa**: El builder original construÃ­a todas las secciones del Excel completo en pÃ¡gina 1.
**SoluciÃ³n**: Eliminar las secciones extras de `build_page1_html()`.
**Estado**: CORREGIDO.

#### E08. Sesiones y Lactancia no estaban lado a lado en dual-grid

**Archivo**: `html_report_builder.py` en `build_page1_html()`
**LÃ­nea**: ~1088-1092
**SÃ­ntoma**: Sesiones II y Lactancia VI se renderizaban en filas separadas (una debajo de otra), pero el ref HTML y el Excel las muestran lado a lado.
**Causa**: Faltaba envolverlas en `<div class="dual-grid">`.
**SoluciÃ³n**: Envolver ambas secciones en `<div class="dual-grid">`.
**Estado**: CORREGIDO.

#### E09. Falta de overflow auto en `.page` CSS

**Archivo**: `static/css/style.css`
**LÃ­nea**: 1190-1202
**SÃ­ntoma**: El contenido del reporte se desbordaba del contenedor sin scroll horizontal.
**Causa**: `.page` no tenÃ­a `overflow: auto`.
**SoluciÃ³n**: Agregar `overflow: auto` a `.page`.
**Estado**: CORREGIDO.

---

### 14.3 ERRORES DE FUNCIONALIDAD (PROBABLES)

#### E10. `_sec_sesiones` solo tiene fila "RN" (incompleta)

**Archivo**: `html_report_builder.py` en `_sec_sesiones()`
**LÃ­nea**: 315-331
**SÃ­ntoma**: La tabla de sesiones de atenciÃ³n temprana solo tiene una fila (RN). DeberÃ­a tener mÃºltiples filas para diferentes edades con sesiones 1-5 y columna de "completas (Mensual)" y "completas (Acum.)".
**Causa**: El ref HTML muestra una estructura mÃ¡s compleja con varias filas etarias.
**SoluciÃ³n pendiente**: Implementar las filas restantes segÃºn el ref HTML.

#### E11. `_sec_evaluacion_desarrollo` tiene fÃ³rmula hardcodeada "TD=..." en la Ãºltima columna

**Archivo**: `html_report_builder.py` en `_sec_evaluacion_desarrollo()`
**LÃ­nea**: 306
**SÃ­ntoma**: En vez de mostrar un valor numÃ©rico real de "EvaluaciÃ³n Normal", muestra un texto de fÃ³rmula "TD=D+DX=Z006+LAB=ED".
**Causa**: Falta la query BD para obtener el valor real de evaluaciones normales.
**SoluciÃ³n pendiente**: Agregar consulta BD y reemplazar la fÃ³rmula hardcodeada.

#### E12. `_sec_sesiones` y `_sec_lactancia` muestran datos inconsistentes

**Archivo**: `html_report_builder.py`
**SÃ­ntoma**: Ambas secciones usan `all_data.get(...)` con keys que pueden no existir en `data_composite` porque los datos vienen de tablas diferentes (cred2024 vs his_proceso). Cuando no hay datos, muestran 0.
**Causa**: `data_composite` se construye mergeando todas las columnas de cred2024* pero las keys pueden diferir.
**SoluciÃ³n**: Verificar que las keys en `_sec_sesiones` y `_sec_lactancia` coincidan con las columnas reales de las tablas.

#### E13. `tabla_html` puede no estar presente en la respuesta para 2024

**Archivo**: `app.py` en `_reporte_cred_2024()`
**LÃ­nea**: ~2833-3493
**SÃ­ntoma**: Para 2024, la respuesta incluye `tabla_html` solo si el builder se ejecuta correctamente. Si hay un error en el builder (como un KeyError por columna faltante), se cae al `except` y usa `_reporte_completo_cred_old()`, que anteriormente no generaba `tabla_html`.
**Causa**: El `try/except` en `_reporte_completo_cred()` captura cualquier error del builder.
**SoluciÃ³n**: Asegurar que tanto 2024 como old siempre generen `tabla_html`.

#### E14. ExportaciÃ³n a Excel puede fallar si faltan columnas

**Archivo**: `app.py` en `reportes_minsa_exportar()`
**SÃ­ntoma**: La exportaciÃ³n a Excel usa `openpyxl` directamente en memoria. Si la estructura de `secciones` o `filas` cambia, la exportaciÃ³n puede fallar con KeyError.
**Estado**: CONFIRMADO como funcional en pruebas anteriores, pero frÃ¡gil ante cambios de estructura.

#### E15. Respuesta `/api/reportes-minsa/ejecutar` no tiene cache busting

**SÃ­ntoma**: Flask tiene debug mode off y los cambios en `modules.js` pueden no reflejarse si el navegador cachea el archivo.
**SoluciÃ³n**: Incrementar `v=` en `index.html` para forzar recarga de JS.

---

### 14.4 ERRORES DE VISUALIZACIÃ“N (MENORES)

#### E16. `modules.js` no tiene `rmRenderSeccion` ni `rmRenderPagina` correctas para el nuevo formato HTML con CSS classes

**Archivo**: `static/js/modules.js`
**LÃ­neas**: 1088-1123
**SÃ­ntoma**: `rmRenderPagina()` tiene un `if (p.tabla_html && p.tabla_html.length > 0)` que renderiza directamente el HTML. Pero si `tabla_html` estÃ¡ vacÃ­o o es `undefined`, cae al cÃ³digo legacy que usa `columnas`/`filas`/`secciones` con inline styles. El cÃ³digo legacy **nunca** genera el nuevo formato de CSS classes.
**Causa**: El builder ahora genera `tabla_html` para todas las rutas, pero el cÃ³digo legacy se mantiene como fallback.
**Estado**: El cÃ³digo legacy es cÃ³digo muerto si `tabla_html` siempre se genera.

#### E17. `.filter-row2` tiene grid de 5 columnas pero la Ãºltima estÃ¡ vacÃ­a

**Archivo**: `html_report_builder.py` en `_sec_header()` y `static/css/style.css`
**SÃ­ntoma**: La Ãºltima celda de `.filter-row2` es un `<div class="filter-cell"></div>` vacÃ­o. Esto es intencional para mantener 5 columnas, pero en el ref HTML esa celda no existe (el ref usa 4 columnas en ambas filas).
**Causa**: Se agregÃ³ una 5ta columna vacÃ­a para que el layout coincida visualmente con el ref.
**Estado**: Intencional, pero puede causar problemas de layout responsivo.

#### E18. `dual-grid` no tiene comportamiento responsivo

**Archivo**: `static/css/style.css` lÃ­nea 1288-1293
**SÃ­ntoma**: `.dual-grid` usa `grid-template-columns: 1fr 1fr` fijo. En pantallas pequeÃ±as (<768px) las dos columnas se comprimen demasiado.
**Causa**: No hay media query que cambie a 1 columna.
**SoluciÃ³n**: Agregar `@media (max-width: 768px) { .dual-grid { grid-template-columns: 1fr; } }`.
**Estado**: NO CORREGIDO.

---

### 14.5 ERRORES DE DATOS

#### E19. `_query_iras_ref()` usa `his_proceso_2024` hardcodeado

**Archivo**: `app.py` en `_query_iras_ref()`
**LÃ­nea**: 3962
**SÃ­ntoma**: La funciÃ³n construye `tbl = f'es_ivan.his_proceso_{anio}'` pero solo se llama desde `_reporte_iras_edas_2024()` con `anio=2024` hardcodeado.
**Estado**: Funcional para 2024 pero no reutilizable.

#### E20. Los filtros en `_query_iras_ref()` y `_query_age_groups()` usan LIKE con LOWER vulnerable a SQL injection

**Archivo**: `app.py` en funciones de query
**LÃ­nea**: 3929
**SÃ­ntoma**: `LOWER({col}) LIKE LOWER('%{val}%')` con interpolaciÃ³n directa. Aunque `val` reemplaza `'`, es una prÃ¡ctica insegura.
**Estado**: Riesgo bajo porque solo se usa con valores de la BD (categorÃ­as existentes), pero anticuado.

#### E21. `_reporte_cred_2024()` no usa la funciÃ³n `_build_cred_where()` correctamente

**Archivo**: `app.py`
**LÃ­nea**: 2835
**SÃ­ntoma**: `where = _build_cred_where(2024, meses, filtros)` hardcodea 2024.
**Estado**: Funcional porque solo se ejecuta para 2024.

---

### 14.6 ERRORES DE ARQUITECTURA

#### E22. Doble ruteo (2024 vs old) es frÃ¡gil y duplica lÃ³gica

**Archivo**: `app.py` en `_reporte_completo_cred()` y `_reporte_iras_edas()`
**LÃ­neas**: 3907 y 4380
**SÃ­ntoma**: Dos implementaciones completamente separadas para el mismo reporte (una para 2024 usando tablas pre-agregadas, otra para otros aÃ±os usando his_proceso). Esto duplica ~1500 lÃ­neas de lÃ³gica y hace que cualquier cambio deba aplicarse en ambos lados.
**Causa**: Las tablas pre-agregadas `cred2024*` solo existen para 2024. Para aÃ±os diferentes se debe usar `his_proceso_YYYY`.
**SoluciÃ³n propuesta**: Unificar ambas rutas consultando directamente las tablas pre-agregadas cuando existan y haciendo fallback a his_proceso. O generar tablas agregadas dinÃ¡micamente para el aÃ±o solicitado.

#### E23. `_reporte_completo_cred_old()` usa `_qflat()` que tiene SQL injection potencial

**Archivo**: `app.py`
**LÃ­nea**: 3506-3546
**SÃ­ntoma**: `codes_str = "','".join(codes)` y `f"WHERE codigo_item IN ('{cs}')"`.
**Estado**: CÃ³digos controlados (CRED_CODES es constante), pero inseguro en general.

#### E24. `data_composite` mergea 5 tablas sin prefijos Ãºnicos

**Archivo**: `app.py` en `_reporte_cred_2024()`
**SÃ­ntoma**: El merge de `{**c24, **c1, **c2, **c3, **c4}` puede sobreescribir keys si hay columnas con mismo nombre en diferentes tablas.
**SoluciÃ³n**: Usar prefijos C1_, C2_, C3_, C4_ que ya existen en las tablas.

#### E25. `config.py` puede no detectar correctamente PROJECT_ROOT en Windows

**Archivo**: `config.py`
**SÃ­ntoma**: Busca `scripts_python/` y `proyecto_salud_cusco_web/` en el Ã¡rbol de directorios ascendente. En algunas configuraciones de Windows con rutas con espacios, la detecciÃ³n puede fallar.
**SoluciÃ³n**: Usar `os.environ.get('PROYECTO_SALUD_ROOT')` como fallback.

---

### 14.7 DIAGRAMA DE FLUJO DEL MÃ“DULO FORMATOS MINSA

```
USUARIO: 
  1. Navega a "Formatos MINSA"
  2. rmInit() â†’ GET /api/reportes-minsa/filtros
     â†’ Puebla selects: aÃ±o, red, microred, establecimiento, provincia, distrito
  3. Selecciona aÃ±o, meses, filtros
  4. rmEjecutar() â†’ POST /api/reportes-minsa/ejecutar
     â†“
app.py: reportes_minsa_ejecutar()
  â”œâ”€ tipo = body['tipo']  ('formato_nino_cred' | 'formato_iras_edas')
  â”œâ”€ anio = body['anio']
  â”œâ”€ meses = body['meses']
  â”œâ”€ filtros = body[...]
  â”‚
  â”œâ”€ if tipo == 'formato_nino_cred':
  â”‚   â””â”€ _reporte_completo_cred(cur, esquema, anio, meses, filtros)
  â”‚       â”œâ”€ if anio == '2024':
  â”‚       â”‚   â””â”€ _reporte_cred_2024(cur, esquema, anio, meses, filtros)
  â”‚       â”‚       â”œâ”€ _qcred_cols() Ã— 5 (c24, c1, c2, c3, c4)
  â”‚       â”‚       â”œâ”€ _build_cred_where(2024, meses, filtros)
  â”‚       â”‚       â”œâ”€ Construye 'secciones' (formato dict legacy)
  â”‚       â”‚       â”œâ”€ build_page1_html() â†’ tabla_html CON <style>
  â”‚       â”‚       â”œâ”€ build_suplementacion_html() â†’ tabla_html
  â”‚       â”‚       â””â”€ build_tx_anemia_html() â†’ tabla_html
  â”‚       â”‚
  â”‚       â””â”€ else (2025/2026):
  â”‚           â””â”€ _reporte_completo_cred_old(cur, esquema, anio, meses, filtros)
  â”‚               â”œâ”€ CRED_CODES, ATENCION_RN_CODES, etc.
  â”‚               â”œâ”€ _qflat(), _qval(), _qmonth_pivot()
  â”‚               â”œâ”€ Construye 'secciones' (formato dict legacy)
  â”‚               â””â”€ Genera tabla_html con loop inline + <style>
  â”‚
  â”œâ”€ if tipo == 'formato_iras_edas':
  â”‚   â””â”€ _reporte_iras_edas(cur, esquema, anio, meses, filtros)
  â”‚       â”œâ”€ if anio == '2024':
  â”‚       â”‚   â””â”€ _reporte_iras_edas_2024()
  â”‚       â”‚       â”œâ”€ _qcred_cols(cur, {'IE':'iras_edas_2024'}, where)
  â”‚       â”‚       â”œâ”€ _query_iras_ref(cur, 2024, filtros) â†’ diag
  â”‚       â”‚       â”œâ”€ _query_age_groups(cur, 2024, CPT codes) â†’ proc
  â”‚       â”‚       â”œâ”€ _query_resumen_mensual(cur, 2024) â†’ resumen
  â”‚       â”‚       â””â”€ build_iras_edas_html() â†’ tabla_html
  â”‚       â””â”€ else (2025/2026):
  â”‚           â””â”€ _reporte_iras_edas_old()
  â”‚               â”œâ”€ CIE_IRAS, CIE_SOB_ASMA, CIE_EDAS, etc.
  â”‚               â”œâ”€ _query_cie() para cada grupo
  â”‚               â””â”€ Construye 'secciones' (formato dict legacy)
  â”‚
  â””â”€ Retorna { tipo, anio, meses, filtros, paginas: [{tabla_html, ...}] }
     â†“
FRONTEND: rmRender(d)
  â”œâ”€ Crea tabs por pÃ¡gina
  â”œâ”€ Extrae CSS de tabla_html[0] â†’ inyecta en <head>
  â””â”€ rmRenderPagina(p)
      â”œâ”€ if p.tabla_html: renderiza DIRECTAMENTE
      â””â”€ else: renderiza legacy (columnas/filas/secciones con inline styles)
```

### 14.8 MAPA DE ARCHIVOS DEL MÃ“DULO FORMATOS MINSA

| Archivo | LÃ­neas | Rol |
|---------|--------|-----|
| `app.py:2576` | reportes_minsa_ejecutar() | Endpoint POST principal del mÃ³dulo |
| `app.py:2833-3493` | _reporte_cred_2024() | Reporte CRED 2024 (tablas pre-agregadas) |
| `app.py:3494-3906` | _reporte_completo_cred_old() | Reporte CRED 2025/2026 (his_proceso) |
| `app.py:3907-3916` | _reporte_completo_cred() | Router CRED (2024 â†’ nuevo, else â†’ old) |
| `app.py:3918-4168` | _query_age_groups(), _query_iras_ref() | Queries auxiliares IRAS/EDAS |
| `app.py:4169-4213` | _reporte_iras_edas_2024() | Reporte IRAS/EDAS 2024 (his_proceso_2024) |
| `app.py:4215-4377` | _build_cred_suplementacion(), _build_cred_tx_anemia() | Constructores de secciones SuplementaciÃ³n y Tx Anemia |
| `app.py:4380-4389` | _reporte_iras_edas() | Router IRAS/EDAS (2024 â†’ nuevo, else â†’ old) |
| `app.py:4392-4726` | _reporte_iras_edas_old() | Reporte IRAS/EDAS 2025/2026 |
| `app.py:4727+` | reportes_minsa_vista_previa() | Endpoint vista previa standalone (GET) |
| `html_report_builder.py:10-95` | Helpers (_esc, _fmt, _v, _num, _td, _s) + _REPORT_CSS | Utilidades de renderizado |
| `html_report_builder.py:100-123` | _sec_header() | Header con filtros (.filter-row + .filter-row2) |
| `html_report_builder.py:128-164` | _sec_cred_controls() | Tabla Control CRED |
| `html_report_builder.py:169-279` | _sec_atencion_rn() | AtenciÃ³n RN (dual-grid) |
| `html_report_builder.py:284-310` | _sec_evaluacion_desarrollo() | EvaluaciÃ³n Desarrollo |
| `html_report_builder.py:315-332` | _sec_sesiones() | Sesiones AtenciÃ³n Temprana |
| `html_report_builder.py:337-350` | _sec_lactancia() | Lactancia Materna |
| `html_report_builder.py:355-382` | _sec_plan_integral() | Plan Integral |
| `html_report_builder.py:387-473` | _sec_consejeria() | ConsejerÃ­a |
| `html_report_builder.py:478-550` | _sec_evaluacion_nutricional() | EvaluaciÃ³n Nutricional + IMC + Parasitosis |
| `html_report_builder.py:555-599` | _sec_laboratorio() | Laboratorio/Tamizajes |
| `html_report_builder.py:604-624` | _sec_profilaxis() | Profilaxis Antiparasitaria |
| `html_report_builder.py:629-657` | _sec_visita_domiciliaria() | Visita Domiciliaria |
| `html_report_builder.py:662-726` | _sec_salud_mental() | Salud Mental |
| `html_report_builder.py:731-762` | _sec_tamizajes() | Tamizajes |
| `html_report_builder.py:767-796` | _sec_tamizajes_positivos() | Tamizajes Positivos |
| `html_report_builder.py:801-837` | _sec_rop() | ROP |
| `html_report_builder.py:842-865` | _sec_salud_ocular_menor3() | Salud Ocular <3a |
| `html_report_builder.py:870-903` | _sec_errores_refraccion() | Errores RefracciÃ³n |
| `html_report_builder.py:908-1064` | _sec_iras_edas() | IRAS/EDAS |
| `html_report_builder.py:1069-1103` | build_page1_html() | PÃ¡gina 1 builder |
| `html_report_builder.py:1109-1599` | build_iras_edas_html() | IRAS/EDAS standalone builder |
| `html_report_builder.py:1602-1642` | _render_seccion_table() | Renderizador de secciÃ³n genÃ©rica |
| `html_report_builder.py:1645-1653` | build_suplementacion_html() | PÃ¡gina 2 builder |
| `html_report_builder.py:1656-1664` | build_tx_anemia_html() | PÃ¡gina 3 builder |
| `modules.js:960-1222` | rmInit(), rmEjecutar(), rmRender(), rmRenderPagina(), rmExportar() | Frontend Formatos MINSA |
| `style.css:1189-1304` | Clases del reporte (.page, .section-title, .th-dark, .dual-grid, etc.) | Estilos del reporte |

### 14.9 CONSTANTES Y DATOS CRÃTICOS (app.py)

#### Constantes de cÃ³digos CRED
```python
CRED_CODES = [
    '99411', '99412', '99413', '99414', '99415', '99416', '99417', '99418',
    '99419', '99420', '99421', '99422', '99423', '99424', '99425'
]
```

#### Constantes de cÃ³digos AtenciÃ³n RN
```python
ATENCION_RN_CODES = ['99501', '99502', '99503', '99504', '99505', '99506', '99507', '99508', '99509']
```

#### Constantes CIE IRAS/EDAS
```python
CIE_IRAS = {
    'IRA no complicada': {'codes': ['J00X','J040','J041','J042','J060','J068','J069','J209']},
    'Faringoamigdalitis': {'codes': ['J020','J029','J030','J038','J039']},
    'OMA': {'codes': ['H650','H651','H660','H669']},
    'Sinusitis': {'codes': ['J010','J011','J012','J013','J014','J019']},
    'NeumonÃ­a sin complicaciones': {'codes': ['J129','J159','J189']},
}
CIE_SOB_ASMA = {'SOB/Asma': {'codes': ['J210','J211','J218','J219','J440','J441','J448','J449','J450','J451','J458','J459','J4591','J46X']}}
CIE_EDAS = {
    'DAA sin desh': {'codes': ['A009','A010','A011','A012','A013','A014','A020','A040','A041','A049','A059','A062','A071','A072','A080','A082','A083','A084','A090','A099']},
    'DAA con desh': {'codes': ['A009+E86X','A010+E86X','A011+E86X','A012+E86X','A013+E86X','A014+E86X']},
}
```

### 14.10 ESTRUCTURA DE TABLAS PRE-AGREGADAS (cred2024*)

Cada tabla `cred2024*` tiene la siguiente estructura:
- `eess` (VARCHAR) - CÃ³digo del establecimiento
- `mes` (INTEGER) - Mes (1-12)
- `C1_*` o `C2_*` o `C3_*` o `C4_*` (BIGINT) - Columnas de indicadores
- ~270 columnas en `cred2024`, ~267 en `cred2024_1`, etc.

Ejemplo de columnas en `cred2024`:
```
eess, mes, C1_atenc_inmediata_rn_sano, C1_corte_cordon_umbilical_cnv,
C1_contacto_piel_piel, C1_examen_fisico_rn_normal, C1_lactancia_1ra_hora_cnv,
C1_bcg_menores_1m, C1_hvb_rn, C1_tamizaje_toma_muestra, C1_tamizaje_hipoacusia,
...
```

### 14.11 TABLA DE CORRESPONDENCIA REF HTML â†” BUILDER

| SecciÃ³n del Ref | FunciÃ³n Builder | LÃ­nea | Estado |
|----------------|----------------|-------|--------|
| Header (.filter-row + .filter-row2) | `_sec_header()` | 100 | âœ… OK |
| Control CRED (13 cols fijas) | `_sec_cred_controls()` | 128 | âœ… OK |
| I. AtenciÃ³n RN (dual-grid) | `_sec_atencion_rn()` | 169 | âœ… OK |
| IX. EvaluaciÃ³n Desarrollo | `_sec_evaluacion_desarrollo()` | 284 | âš ï¸ FÃ³rmula hardcodeada |
| II. Sesiones AtenciÃ³n Temprana | `_sec_sesiones()` | 315 | âš ï¸ Solo RN |
| VI. Lactancia Materna | `_sec_lactancia()` | 337 | âœ… OK |
| XVI. IRAS/EDAS | `_sec_iras_edas()` | 908 | âœ… OK |
| SuplementaciÃ³n (Page 2) | `build_suplementacion_html()` | 1645 | âœ… OK |
| Tx Anemia (Page 3) | `build_tx_anemia_html()` | 1656 | âœ… OK |

---

## 15. COMMANDS ÃšTILES

### 15.1 Iniciar/Reiniciar la App Web
```bash
cd proyecto_salud_cusco_web
& ".\venv\Scripts\python.exe" app.py
```

### 15.2 Forzar recarga de JS (cache busting)
Editar `templates/index.html`, incrementar `?v=` en:
```html
<script src="/static/js/modules.js?v=4"></script>
```

### 15.3 Ver logs de errores en tiempo real
```powershell
Get-Content .\app.log -Wait -Tail 30
```

### 15.4 Probar endpoint de reportes MINSA directamente
```powershell
$body = @{tipo="formato_nino_cred"; anio="2024"; meses=@(1,2,3,4,5,6)} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:5000/api/reportes-minsa/ejecutar" -Method Post -Body $body -ContentType "application/json"
```

### 15.5 Verificar que la respuesta incluye tabla_html
```powershell
$r = Invoke-RestMethod -Uri "http://localhost:5000/api/reportes-minsa/ejecutar" -Method Post -Body $body -ContentType "application/json"
$r.paginas[0].tabla_html.Length
```

---

## 16. CHANGELOG DE CORRECCIONES DEL MÃ“DULO FORMATOS MINSA

| Fecha | Issue | Archivo | Cambio |
|-------|-------|---------|--------|
| 2026-06-22 | E01 | `modules.js` | Cerrado `/*` sin `*/` |
| 2026-06-22 | E02 | `app.py:3894` | Agregado `<style>` a tabla_html de aÃ±os â‰  2024 |
| 2026-06-22 | E03 | `html_report_builder.py:128` | 13 columnas fijas en vez de dinÃ¡micas |
| 2026-06-22 | E04 | `html_report_builder.py:132,914,973,990,1044` | Agregados colgroups con % exactos |
| 2026-06-22 | E05 | `html_report_builder.py:116` | `.filter-row2` con 5 columnas |
| 2026-06-22 | E06 | `html_report_builder.py:262` | "ACTIVIDADES" â†’ "DIAGNÃ“STICOS" |
| 2026-06-22 | E07 | `html_report_builder.py:1069` | Eliminadas 11 secciones extras |
| 2026-06-22 | E08 | `html_report_builder.py:1089` | Sesiones+Lactancia en dual-grid |
| 2026-06-22 | E09 | `style.css:1201` | `.page` con `overflow:auto` |
| 2026-06-22 | DOC | `DOCUMENTACION_SISTEMA_WEB.md` | DocumentaciÃ³n completa creada |

---

## 17. PRIORIDAD DE CORRECCIONES PENDIENTES

| Prioridad | Issue | DescripciÃ³n | Impacto |
|-----------|-------|-------------|---------|
| ðŸ”´ Alta | E10 | `_sec_sesiones` incompleta (solo RN) | Faltan datos de sesiones para edades > RN |
| ðŸ”´ Alta | E11 | `_sec_evaluacion_desarrollo` fÃ³rmula hardcodeada | Muestra fÃ³rmula en vez de datos reales |
| ðŸŸ¡ Media | E12 | Keys inconsistentes entre builder y datos | Posibles ceros donde deberÃ­a haber datos |
| ðŸŸ¡ Media | E22 | Doble ruteo frÃ¡gil (2024 vs old) | ~1500 lÃ­neas duplicadas, cambios deben aplicarse dos veces |
| ðŸŸ¢ Baja | E18 | dual-grid no responsivo | Mala visualizaciÃ³n en pantallas <768px |
| ðŸŸ¢ Baja | E17 | filter-row2 columna vacÃ­a | Leve, solo afecta layout responsivo |
| ðŸŸ¢ Baja | E16 | CÃ³digo legacy muerto en rmRenderPagina | No afecta funcionalidad actual |

---

*DocumentaciÃ³n generada del cÃ³digo fuente. Sistema de Monitoreo de Salud - GERESA Cusco (DIRESA CUSCO)*
*Web: http://localhost:5000 | BD: PostgreSQL/es_ivan | Python/Flask + JS Vanilla SPA*
*Ãšltima actualizaciÃ³n: 22 de junio de 2026*

---

## 18. CÓDIGO FUENTE COMPLETO - html_report_builder.py

```python
"""HTML Report Builder - Generates CSS-class-based HTML matching reference DIRESA CUSCO style.

Each _sec_*() returns a complete <div> + <table> block using CSS classes
(.section-title, .sub-section-title, .th-dark, .dual-grid, etc.)
"""

# ============================================================
# HELPER FUNCTIONS
# ============================================================
def _esc(v):
    if v is None: return ''
    if isinstance(v, (int, float)): return f'{v:,.0f}'
    s = str(v)
    return s.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;')

def _fmt(v):
    if v is None: return '0'
    if isinstance(v, (int, float)):
        if v == int(v): return f'{int(v):,}'
        return f'{v:,.1f}'
    s = str(v)
    if s.startswith('#REF!'): return '0'
    return s

def _v(d, k):
    if k is None: return 0
    v = d.get(k, 0)
    if v is None or v == '#REF!': return 0
    if isinstance(v, str):
        try:
            if v.startswith('#'): return 0
            return float(v.replace(',', ''))
        except:
            return 0
    return int(v) if v == int(v) else v

def _num(v):
    n = _v({}, v) if isinstance(v, str) else v
    if n is None or n == '': return '<td class="num">0</td>'
    if isinstance(n, (int, float)):
        if n == 0: return '<td class="zero">0</td>'
        return f'<td class="num">{n:,.0f}</td>'
    return f'<td>{_esc(n)}</td>'

def _td(v, cls=''):
    if v is None or v == '': return f'<td class="{cls}">0</td>'
    if isinstance(v, (int, float)):
        if v == 0: return f'<td class="{cls} zero">0</td>'
        return f'<td class="{cls} num">{v:,.0f}</td>'
    return f'<td class="{cls}">{_esc(v)}</td>'

def _s(d, k):
    """Shortcut: _s(c24, 'C1_col')"""
    return _td(_v(d, k))

# ============================================================
# REPORT CSS (inline to avoid parent-style overrides)
# ============================================================
_REPORT_CSS = '''
* { box-sizing: border-box; margin: 0; padding: 0; }
.page { width: 100%; max-width: 1400px; margin: 0 auto; padding: 10px; overflow: auto; }
.header { text-align: center; margin-bottom: 6px; }
.header h2 { font-size: 11px; font-weight: bold; text-transform: uppercase; }
.header h3 { font-size: 10px; font-weight: bold; text-transform: uppercase; }
.header h4 { font-size: 11px; font-weight: bold; text-transform: uppercase; color: #2E75B6; margin-top: 2px; }
.filter-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; font-size: 9px; margin-bottom: 6px; padding: 4px 0; border-top: 1px solid #4472C4; border-bottom: 1px solid #4472C4; }
.filter-row2 { display: grid; grid-template-columns: repeat(5, 1fr); gap: 8px; font-size: 9px; margin-bottom: 6px; padding: 4px 0; border-bottom: 1px solid #4472C4; }
.filter-cell { display: flex; flex-direction: column; }
.filter-cell label { font-weight: bold; color: #2E75B6; }
.filter-cell span { border-bottom: 1px solid #9DC3E6; }
.section-title { background: #4472C4; color: #fff; font-weight: bold; font-size: 10px; padding: 3px 6px; text-transform: uppercase; margin-bottom: 2px; }
.sub-section-title { background: #D6E4F7; font-weight: bold; font-size: 9px; padding: 2px 6px; margin-bottom: 2px; border-left: 3px solid #4472C4; }
.sub2-title { background: #F2F2F2; font-weight: bold; font-size: 9px; padding: 2px 6px; margin-bottom: 2px; }
table { border-collapse: collapse; width: 100%; margin-bottom: 6px; font-size: 9px; }
th, td { border: 1px solid #000; padding: 2px 4px; vertical-align: middle; text-align: center; }
th { background: #BDD7EE; font-weight: bold; font-size: 8.5px; }
.th-dark { background: #2E75B6; color: #fff; }
.th-medium { background: #9DC3E6; }
.th-green { background: #70AD47; color: #fff; }
.th-orange { background: #ED7D31; color: #fff; }
td.label-left { text-align: left; padding-left: 4px; }
td.label-indent { text-align: left; padding-left: 12px; font-size: 8.5px; }
td.nota { font-size: 7.5px; color: #595959; font-style: italic; text-align: left; padding-left: 4px; }
td.num { font-weight: bold; }
td.zero { color: #595959; }
.row-header { background: #DDEBF7; font-weight: bold; }
.row-sub { background: #F2F2F2; }
.row-total { background: #2E75B6; color: #fff; font-weight: bold; }
.dual-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 6px; }
td.diag { text-align: left; padding-left: 6px; background: #F2F2F2; font-size: 8.5px; }
td.diag-sub { text-align: left; padding-left: 14px; font-size: 8.5px; }
td.formula { text-align: left; padding-left: 4px; font-size: 7.5px; color: #595959; font-style: italic; }
.note-row td { background: #FFF2CC; font-size: 8px; text-align: left; padding-left: 4px; border: 1px solid #BF9000; }
@media print { body { font-size: 8px; } .page { max-width: 100%; padding: 5px; } @page { size: A3 landscape; margin: 10mm; } }
'''

# ============================================================
# HEADER
# ============================================================
def _sec_header(filtros):
    f = filtros or {}
    anio = str(f.get('anio', '2026'))
    html = '''
    <div class="header">
        <h2>DIRECCI\u00d3N REGIONAL DE SALUD CUSCO</h2>
        <h3>DIRECCI\u00d3N DE ESTAD\u00cdSTICA E INFORM\u00c1TICA Y TELECOMUNICACI\u00d3N</h3>
        <h4>INFORME MENSUAL DEL CUIDADO INTEGRAL DEL NI\u00d1O(A)</h4>
    </div>'''
    html += '''
    <div class="filter-row">
        <div class="filter-cell"><label>RED DE SALUD:</label><span>''' + _esc(f.get('red', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>MICRO RED:</label><span>''' + _esc(f.get('microred', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>PROVINCIA:</label><span>''' + _esc(f.get('provincia', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>A\u00d1O:</label><span>''' + anio + '''</span></div>
    </div>
    <div class="filter-row2">
        <div class="filter-cell"><label>ESTABLECIMIENTO:</label><span>''' + _esc(f.get('establecimiento', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>DISTRITO:</label><span>''' + _esc(f.get('distrito', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>MES INICIO:</label><span>''' + str(f.get('mes_ini', f.get('mes_inicio', '1'))) + '''</span></div>
        <div class="filter-cell"><label>MES FIN:</label><span>''' + str(f.get('mes_fin', f.get('mes_fin', '6'))) + '''</span></div>
        <div class="filter-cell"></div>
    </div>'''
    return html

# ============================================================
# SECTION: CRED CONTROLS
# ============================================================
def _sec_cred_controls(col_names, filas_cred, totales_main):
    html = '<div class="section-title">CONTROL DE CRECIMIENTO Y DESARROLLO DEL NI\u00d1O(A)</div>'
    html += '<div class="sub-section-title">N\u00b0 de Controles de Crecimiento y Desarrollo de 0 a 11 A\u00f1os</div>'
    html += '<table>'
    html += '<colgroup><col style="width:14%"><col style="width:9%">'
    for _ in range(11):
        html += '<col style="width:7%">'
    html += '</colgroup>'
    html += '<thead><tr>'
    html += '<th class="th-dark">GRUPO ETAREO</th>'
    html += '<th class="th-dark">PROGRAMACI\u00d3N</th>'
    ctrl_names = ['1er Ctrl 29-59d','2do Ctrl 60-89d','3er Ctrl 90-119d','4to Ctrl 120-149d',
                  '5to Ctrl 180-209d','6to Ctrl 210-239d','7mo Ctrl 270-299d',
                  '8vo Ctrl','9no Ctrl','10mo Ctrl','11vo Ctrl']
    for cn in ctrl_names:
        html += f'<th class="th-medium">{cn}</th>'
    html += '</tr></thead><tbody>'
    ctrl_keys = ['1ER.CONTROL','2DO.CONTROL','3ER.CONTROL','4TO.CONTROL',
                 '5TO.CONTROL','6TO.CONTROL','7MO.CONTROL','8VO.CONTROL',
                 '9NO.CONTROL','10MO.CONTROL','11VO.CONTROL']
    for ri, fila in enumerate(filas_cred):
        cls = ' class="row-sub"' if ri % 2 == 1 else ''
        html += f'<tr{cls}>'
        html += f'<td class="label-left">{_esc(fila.get("EDADES", ""))}</td>'
        html += '<td></td>'
        for ck in ctrl_keys:
            v = fila.get(ck, 0) or 0
            if v == 0: html += '<td class="zero">0</td>'
            else: html += f'<td class="num">{v:,.0f}</td>'
        html += '</tr>'
    html += '<tr class="row-total"><td>TOTAL</td><td></td>'
    for ck in ctrl_keys:
        v = totales_main.get(ck, 0) or 0
        if v == 0: html += '<td class="zero">0</td>'
        else: html += f'<td class="num">{v:,.0f}</td>'
    html += '</tr></tbody></table>'
    return html

# ============================================================
# SECTION: I. ATENCIÃ“N DEL RECIÃ‰N NACIDO (dual-grid)
# ============================================================
def _sec_atencion_rn(c24, c1, c4):
    html = '<div class="section-title">I. ATENCI\u00d3N DEL RECI\u00c9N NACIDO</div>'
    html += '<div class="dual-grid">'

    # LEFT: A) AtenciÃ³n Inmediata
    html += '<div>'
    html += '<div class="sub2-title">A) Atenci\u00f3n Inmediata</div>'
    html += '<table><thead><tr><th class="th-dark">ACTIVIDADES</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    left_items = [
        ('Atenci\u00f3n Inmediata', c24, 'C1_atenc_inmediata_rn_sano'),
        ('Corte tard\u00edo del Cord\u00f3n Umbilical', c24, 'C1_corte_cordon_umbilical_cnv'),
        ('Contacto Piel a Piel con la madre', c24, 'C1_contacto_piel_piel'),
        ('Examen f\u00edsico del reci\u00e9n nacido normal', c24, 'C1_examen_fisico_rn_normal'),
        ('Lactancia Materna en la 1\u00aa Hora', c24, 'C1_lactancia_1ra_hora_cnv'),
        ('BCG MENORES A 1m', c24, 'C1_bcg_menores_1m'),
        ('HVB RN', c24, 'C1_hvb_rn'),
    ]
    for i, (label, d, col) in enumerate(left_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_s(d, col)}</tr>'
    html += '</tbody></table>'

    # LEFT: B) CondiciÃ³n de Nacimiento
    html += '<div class="sub2-title" style="margin-top:4px;">B) Condici\u00f3n de Nacimiento del Reci\u00e9n Nacido</div>'
    html += '<table><thead><tr><th class="th-dark">DIAGN\u00d3STICOS</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    cond_items = [
        ('Extremadamente bajo peso', c4, 'C4_peso_extremadamente_bajo'),
        ('Muy bajo peso al nacer', c4, 'C4_muy_bajo_peso'),
        ('Bajo peso al nacer', c4, 'C4_bajo_peso'),
        ('Macros\u00f3mico', c4, 'C4_macrosomico'),
        ('Microcefalia', c4, 'C4_microcefalia'),
        ('Reci\u00e9n nacido prematuro', c4, 'C4_prematuro'),
        ('Reci\u00e9n Nacido Normal', c4, 'no_col'),
    ]
    for i, (label, d, col) in enumerate(cond_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_s(d, col)}</tr>'
    html += '</tbody></table>'

    # LEFT: B) Resultados del Tamizaje Neonatal
    html += '<div class="sub2-title" style="margin-top:4px;">B) Resultados del Tamizaje Neonatal</div>'
    html += '<table><thead><tr><th class="th-dark">DIAGN\u00d3STICOS</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    tamiz_items = [
        ('Hipotiroidismo Cong\u00e9nito', c4, 'C4_hipotiroidismo_congenito_sin_bocio'),
        ('Fenilcetonuria Cl\u00e1sica', c4, 'C4_fenilcetonuria_clasica'),
        ('Hiperplasia Suprarrenal Cong\u00e9nita', c4, 'C4_hiperplasia_suprarrenal_congenita'),
        ('Tamizaje de Cardiopat\u00eda Cong\u00e9nita', c4, 'C4_cardiopatia_congenita_tipo1'),
        ('Fibrosis Qu\u00edstica, sin otra especificaci\u00f3n', c4, 'C4_fibrosis_quistica_sin_otra_especificacion'),
        ('Catarata Cong\u00e9nita', c4, 'C4_catarata_congenita'),
        ('Cardiopat\u00eda cong\u00e9nita', c4, 'no_col'),
        ('Hipoacusia conductiva', c4, 'C4_hipoacusia_conductiva'),
    ]
    for i, (label, d, col) in enumerate(tamiz_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_s(d, col)}</tr>'
    html += '</tbody></table>'
    html += '</div>'  # end left column

    # RIGHT: C) Alojamiento Conjunto
    html += '<div>'
    html += '<div class="sub2-title">C) Atenci\u00f3n de Reci\u00e9n Nacido en Alojamiento Conjunto</div>'
    html += '<table><thead><tr><th class="th-dark">ACTIVIDADES</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    right_items = [
        ('Atenci\u00f3n del RN en Alojamiento Conjunto', c4, 'C4_atencion_alojamiento_conjunto'),
        ('Evaluaci\u00f3n m\u00e9dica del reci\u00e9n nacido', c4, 'C4_evaluacion_medica_rn'),
        ('Tamizaje neonatal: toma de muestra', c24, 'C1_tamizaje_toma_muestra'),
        ('Tamizaje de hipoacusia', c24, 'C1_tamizaje_hipoacusia'),
        ('Tamizaje de catarata cong\u00e9nita', c24, 'C1_tamizaje_catarata_congenita'),
        ('Tamizaje de cardiopat\u00eda cong\u00e9nita', c24, 'C1_tamizaje_cardiopatia'),
    ]
    for i, (label, d, col) in enumerate(right_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_s(d, col)}</tr>'
    html += '</tbody></table>'

    # RIGHT: ConsejerÃ­a
    html += '<div class="sub2-title" style="margin-top:4px;">Consejer\u00eda en Atenci\u00f3n del RN - Alojamiento Conjunto</div>'
    html += '<table><thead><tr><th class="th-dark">ACTIVIDADES</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    cons_items = [
        ('Consejer\u00eda en corte y cuidado del cord\u00f3n umbilical', c4, 'C4_corte_cordon_umbilical'),
        ('Consejer\u00eda en Lactancia Materna Exclusiva', c4, 'C4_conse_lme'),
        ('Consejer\u00eda en importancia del control CRED (4 controles)', c4, 'C4_consej_import_control_cred'),
        ('Consejer\u00eda de identificaci\u00f3n de signos de alarma', c4, 'C4_conse_signos_alarma'),
        ('Consejer\u00eda en higiene del RN y cuidado en el hogar', c4, 'no_col'),
        ('Consejer\u00eda en alimentaci\u00f3n con suced\u00e1neos (neonatos VIH)', c4, 'no_col'),
    ]
    for i, (label, d, col) in enumerate(cons_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_s(d, col)}</tr>'
    html += '</tbody></table>'

    # RIGHT: E) AtenciÃ³n RN en VD
    html += '<div class="sub2-title" style="margin-top:4px;">E) Atenci\u00f3n del Reci\u00e9n Nacido en Visita Domiciliaria</div>'
    html += '<table><thead><tr><th class="th-dark">DIAGN\u00d3STICOS</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    vd_items = [
        ('Visita domiciliaria para el cuidado y evaluaci\u00f3n neonatal', c4, 'C4_vd_cuidado_y_evaluacion_neonatal'),
        ('Anamnesis y examen f\u00edsico del RN normal', c4, 'C4_anamnesis_y_ex_fisico_rn_normal'),
        ('Consejer\u00eda en higiene del RN y cuidado en el hogar', c4, 'no_col'),
        ('Consejer\u00eda en cuidado del cord\u00f3n umbilical', c4, 'no_col'),
        ('Consejer\u00eda en importancia del control CRED (4 controles)', c4, 'C4_consej_import_control_cred'),
        ('Consejer\u00eda de identificaci\u00f3n de signos de alarma', c4, 'C4_conse_signos_alarma'),
        ('Consejer\u00eda en higiene de manos', c4, 'no_col'),
        ('Consejer\u00eda en Lactancia Materna Exclusiva hasta 6 meses', c4, 'C4_conse_lme'),
    ]
    for i, (label, d, col) in enumerate(vd_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_s(d, col)}</tr>'
    html += '</tbody></table>'
    html += '</div>'  # end right column
    html += '</div>'  # end dual-grid
    return html

# ============================================================
# SECTION: IX. EVALUACIÃ“N DEL DESARROLLO
# ============================================================
def _sec_evaluacion_desarrollo(all_data):
    html = '<div class="section-title">IX. EVALUACI\u00d3N DEL DESARROLLO</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="3">Edades</th>'
    html += '<th class="th-dark" colspan="10">Retardo del Desarrollo</th>'
    html += '<th class="th-dark" rowspan="3">Evaluac.<br>Normal</th>'
    html += '</tr><tr>'
    for dom in ['Lenguaje', 'Motora', 'Social', 'Coordinaci\u00f3n', 'Cognitiva']:
        html += f'<th class="th-medium" colspan="2">{dom}</th>'
    html += '</tr><tr>'
    for _ in range(5):
        html += '<th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>'
    html += '</tr></thead><tbody>'

    dev_groups = [('< 1 a\u00f1o', 'men1a'), ('01 a\u00f1o', '1a'), ('02 a\u00f1os', '2a')]
    for gi, (label, suf) in enumerate(dev_groups):
        cls = ' class="row-sub"' if gi % 2 == 1 else ''
        html += f'<tr{cls}>'
        html += f'<td class="label-left">{label}</td>'
        for dom in ['len', 'mot', 'soc', 'coo', 'cog']:
            html += _td(all_data.get(f'retardo_desarrollo_{dom}_{suf}', 0))
            html += _td(all_data.get(f'rec_retardo_desarrollo_{dom}_{suf}', 0))
        html += '<td class="nota">TD=D+DX=Z006+LAB=ED</td>'
        html += '</tr>'
    html += '<tr class="row-sub"><td colspan="12" style="text-align:left;padding-left:4px;font-size:8px;">Dx: Diagnosticado &nbsp;&nbsp;&nbsp; Recup: Recuperado</td></tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: II. SESIONES DE ATENCIÃ“N TEMPRANA
# ============================================================
def _sec_sesiones(all_data):
    html = '<div class="sub-section-title">II. SESIONES DE ATENCI\u00d3N TEMPRANA (99411)</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark">Edad</th>'
    for s in ['1\u00aa Sesi\u00f3n', '2\u00aa Sesi\u00f3n', '3\u00aa Sesi\u00f3n', '4\u00aa Sesi\u00f3n', '5\u00aa Sesi\u00f3n']:
        html += f'<th class="th-medium">{s}</th>'
    html += '<th class="th-dark">Ni\u00f1o con sesiones completas (Mensual)</th>'
    html += '<th class="th-dark">Ni\u00f1o con sesiones completas (Acum.)</th>'
    html += '</tr></thead><tbody>'
    # RN
    html += '<tr><td class="label-left">RN</td>'
    html += _td(all_data.get('sesion_est_temprana_menor_1a_1', 0))
    html += '<td></td><td></td><td></td><td></td>'
    html += _td(all_data.get('sesion_est_temprana_menor_1a_1', 0))
    html += '<td></td>'
    html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: VI. LACTANCIA MATERNA EXCLUSIVA
# ============================================================
def _sec_lactancia(all_data):
    html = '<div class="section-title">VI. LACTANCIA MATERNA EXCLUSIVA</div>'
    html += '<table style="width:50%"><thead><tr>'
    html += '<th class="th-dark">CONDICI\u00d3N</th><th class="th-dark">N\u00b0</th>'
    html += '</tr></thead><tbody>'
    for label, key in [
        ('Con lactancia materna exclusiva', 'lactancia_exclusiva'),
        ('Con lactancia materna no exclusiva', 'lactancia_no_exclusiva'),
        ('Con lactancia artificial', 'lactancia_artificial'),
        ('Con alimentaci\u00f3n mixta', 'alimentacion_mixta'),
    ]:
        html += f'<tr><td class="label-left">{label}</td>{_td(all_data.get(key, 0))}</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: X. PLAN DE ATENCIÃ“N INTEGRAL
# ============================================================
def _sec_plan_integral(all_data):
    html = '<div class="section-title">X. PLAN DE ATENCI\u00d3N INTEGRAL</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">Edades</th>'
    ages = ['0-28d', '29d-11m', '12-23m', '24-35m', '36-47m', '4a', '5a', '6a', '7a', '8a', '9a', '10a', '11a']
    for a in ages:
        html += f'<th class="th-medium">{a}</th>'
    html += '</tr></thead><tbody>'

    elab_keys = ['plan_ais_ini_rn', 'plan_ais_ini_1m', 'plan_ais_ini_1a',
                 'plan_ais_ini_2a', 'plan_ais_ini_3a', 'plan_ais_ini_4a',
                 'plan_ais_ini_5a', 'plan_ais_ini_6a', 'plan_ais_ini_7a',
                 'plan_ais_ini_8a', 'plan_ais_ini_9a', 'plan_ais_ini_10a', 'plan_ais_ini_11a']
    html += '<tr><td class="label-left">Elaborado</td>'
    for k in elab_keys:
        html += _td(all_data.get(k, 0))
    html += '</tr>'

    ejec_keys = ['plan_ais_ta_rn', 'plan_ais_termino_7m', 'plan_ais_termino_1a',
                 'plan_ais_termino_2a', 'plan_ais_termino_3a', 'plan_ais_termino_4a',
                 'plan_ais_ta_5a', 'plan_ais_ta_6a', 'plan_ais_ta_7a',
                 'plan_ais_ta_8a', 'plan_ais_ta_9a', 'plan_ais_ta_10a', 'plan_ais_ta_11a']
    html += '<tr><td class="label-left">Ejecutado</td>'
    for k in ejec_keys:
        html += _td(all_data.get(k, 0))
    html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: IV. CONSEJERÃA
# ============================================================
def _sec_consejeria(all_data):
    html = '<div class="section-title">IV. CONSEJER\u00cdA EN LA ATENCI\u00d3N DEL NI\u00d1O(A)</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">Tipos / Edades</th>'
    html += '<th class="th-dark" rowspan="2">Total</th>'
    age_labels = ['RN', '<1a', '1a', '2a', '3a', '4a', '5a', '6a', '7a', '8a', '9a', '10a', '11a']
    for a in age_labels:
        html += f'<th class="th-medium">{a}</th>'
    html += '</tr></thead><tbody>'

    consej_items = [
        ('Consejer\u00eda en atenci\u00f3n temprana del desarrollo',
         ['consej_atc_tempra_desarrollo_rn', 'consej_atc_tempra_desarrollo_men_1a',
          'consej_atc_tempra_desarrollo_1a', 'consej_atc_tempra_desarrollo_2a',
          'consej_atc_tempra_desarrollo_3a', 'consej_atc_tempra_desarrollo_4a',
          'consej_atc_tempra_desarrollo_5a', 'consej_atc_tempra_desarrollo_6a',
          'consej_atc_tempra_desarrollo_7a', 'consej_atc_tempra_desarrollo_8a',
          'consej_atc_tempra_desarrollo_9a', 'consej_atc_tempra_desarrollo_10a',
          'consej_atc_tempra_desarrollo_11a']),
        ('Consejer\u00eda en inmunizaciones',
         ['consej_inmunizaciones_rn', 'consej_inmunizaciones_men_1a',
          'consej_inmunizaciones_1a', 'consej_inmunizaciones_2a', 'consej_inmunizaciones_3a',
          'consej_inmunizaciones_4a', 'consej_inmunizaciones_5a', 'consej_inmunizaciones_6a',
          'consej_inmunizaciones_7a', 'consej_inmunizaciones_8a', 'consej_inmunizaciones_9a',
          'consej_inmunizaciones_10a', 'consej_inmunizaciones_11a']),
        ('Consejer\u00eda de identificaci\u00f3n de signos de alarma',
         ['conse_signos_alarma_rn', 'conse_signos_alarma_men_1a',
          'conse_signos_alarma_1a', 'conse_signos_alarma_2a', 'conse_signos_alarma_3a',
          'conse_signos_alarma_4a', 'conse_signos_alarma_5a', 'conse_signos_alarma_6a',
          'conse_signos_alarma_7a', 'conse_signos_alarma_8a', 'conse_signos_alarma_9a',
          'conse_signos_alarma_10a', 'conse_signos_alarma_11a']),
        ('Consejer\u00eda prevenci\u00f3n muerte s\u00fabita del lactante',
         ['conse_prev_muerte_subita_lactant_rn', 'conse_prev_muerte_subita_lactant_men_1a',
          'conse_prev_muerte_subita_lactant_1a', 'conse_prev_muerte_subita_lactant_2a',
          'conse_prev_muerte_subita_lactant_3a', 'conse_prev_muerte_subita_lactant_4a',
          'conse_prev_muerte_subita_lactant_5a', 'conse_prev_muerte_subita_lactant_6a',
          'conse_prev_muerte_subita_lactant_7a', 'conse_prev_muerte_subita_lactant_8a',
          'conse_prev_muerte_subita_lactant_9a', 'conse_prev_muerte_subita_lactant_10a',
          'conse_prev_muerte_subita_lactant_11a']),
        ('Consejer\u00eda prevenci\u00f3n enfermedades prevalentes (EDA, IRA)',
         ['conse_prev_enf_prevalentes_ira_eda_rn', 'conse_prev_enf_prevalentes_ira_eda_men_1a',
          'conse_prev_enf_prevalentes_ira_eda_1a', 'conse_prev_enf_prevalentes_ira_eda_2a',
          'conse_prev_enf_prevalentes_ira_eda_3a', 'conse_prev_enf_prevalentes_ira_eda_4a',
          'conse_prev_enf_prevalentes_ira_eda_5a', 'conse_prev_enf_prevalentes_ira_eda_6a',
          'conse_prev_enf_prevalentes_ira_eda_7a', 'conse_prev_enf_prevalentes_ira_eda_8a',
          'conse_prev_enf_prevalentes_ira_eda_9a', 'conse_prev_enf_prevalentes_ira_eda_10a',
          'conse_prev_enf_prevalentes_ira_eda_11a']),
        ('Consejer\u00eda en salud ocular',
         ['conse_salud_ocular_rn', 'conse_salud_ocular_men_1a',
          'conse_salud_ocular_1a', 'conse_salud_ocular_2a', 'conse_salud_ocular_3a',
          'conse_salud_ocular_4a', 'conse_salud_ocular_5a', 'conse_salud_ocular_6a',
          'conse_salud_ocular_7a', 'conse_salud_ocular_8a', 'conse_salud_ocular_9a',
          'conse_salud_ocular_10a', 'conse_salud_ocular_11a']),
        ('Consejer\u00eda en higiene de manos',
         ['conse_higiene_manos_rn', 'conse_higiene_manos_men_1a',
          'conse_higiene_manos_1a', 'conse_higiene_manos_2a', 'conse_higiene_manos_3a',
          'conse_higiene_manos_4a', 'conse_higiene_manos_5a', 'conse_higiene_manos_6a',
          'conse_higiene_manos_7a', 'conse_higiene_manos_8a', 'conse_higiene_manos_9a',
          'conse_higiene_manos_10a', 'conse_higiene_manos_11a']),
        ('Consejer\u00eda en pautas de crianza, buen trato',
         ['conse_pautas_crianza_rn', 'conse_pautas_crianza_men_1a',
          'conse_pautas_crianza_1a', 'conse_pautas_crianza_2a', 'conse_pautas_crianza_3a',
          'conse_pautas_crianza_4a', 'conse_pautas_crianza_5a', 'conse_pautas_crianza_6a',
          'conse_pautas_crianza_7a', 'conse_pautas_crianza_8a', 'conse_pautas_crianza_9a',
          'conse_pautas_crianza_10a', 'conse_pautas_crianza_11a']),
        ('Consejer\u00eda nutricional: Alimentaci\u00f3n saludable',
         ['conse_aliment_saludable_rn', 'conse_aliment_saludable_men_1a',
          'conse_aliment_saludable_1a', 'conse_aliment_saludable_2a', 'conse_aliment_saludable_3a',
          'conse_aliment_saludable_4a', 'conse_aliment_saludable_5a', 'conse_aliment_saludable_6a',
          'conse_aliment_saludable_7a', 'conse_aliment_saludable_8a', 'conse_aliment_saludable_9a',
          'conse_aliment_saludable_10a', 'conse_aliment_saludable_11a']),
        ('Consejer\u00eda en Lactancia Materna Exclusiva hasta 06m',
         ['', 'conse_lme_6m_men_1a', 'conse_lme_1a', 'conse_lme_2a', 'conse_lme_3a', 'conse_lme_4a',
          'conse_lme_5a', 'conse_lme_6a', 'conse_lme_7a', 'conse_lme_8a', 'conse_lme_9a', 'conse_lme_10a',
          'conse_lme_11a']),
    ]

    for i, (label, keys) in enumerate(consej_items):
        vals = [all_data.get(k, 0) if k else 0 for k in keys]
        total = sum(v for v in vals)
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_td(total)}'
        for v in vals:
            html += _td(v)
        html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: V. EVALUACIÃ“N NUTRICIONAL
# ============================================================
def _sec_evaluacion_nutricional(all_data):
    html = '<div class="section-title">V. EVALUACI\u00d3N NUTRICIONAL</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="3">GRUPO DE EDAD</th>'
    html += '<th class="th-dark" colspan="2">Peso para la Edad (PE)</th>'
    html += '<th class="th-dark" colspan="2">Peso para la Edad (TP)</th>'
    html += '<th class="th-dark" colspan="2">Talla para la Edad (TE)</th>'
    html += '</tr><tr>'
    for label in ['Desnutrici\u00f3n Global', 'Obesidad', 'Sobrepeso', 'Desnutrici\u00f3n Aguda', 'Desnutrici\u00f3n Cr\u00f3nica']:
        html += f'<th class="th-medium" colspan="2">{label}</th>'
    html += '</tr><tr>'
    for _ in range(5):
        html += '<th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>'
    html += '</tr></thead><tbody>'

    nut_groups = [('< 1 a\u00f1o', 'men1a'), ('1 a\u00f1o', '1a'), ('2 a\u00f1os', '2a'), ('3 a\u00f1os', '3a'), ('4 a\u00f1os', '4a')]
    nut_cols = [
        ('desnutric_global', 'desnutric_global_pr'),
        ('obeso', 'sobre_peso_pr'),
        ('sobre_peso', 'sobre_peso_pr'),
        ('desnutric_aguda', 'desnutric_aguda_pr'),
        ('desnutric_cronica', 'desnutric_cronica_pr'),
    ]
    for gi, (label, suf) in enumerate(nut_groups):
        cls = ' class="row-sub"' if gi % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        for dx_base, rec_base in nut_cols:
            html += _td(all_data.get(f'{dx_base}_{suf}', 0))
            html += _td(all_data.get(f'{rec_base}_{suf}', 0))
        html += '</tr>'
    html += '</tbody></table>'

    # 5-11 years IMC
    html += '<div class="sub-section-title">C) En los Ni\u00f1os y Ni\u00f1as de 05 a 11 a\u00f1os</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">GRUPO DE EDAD</th>'
    html += '<th class="th-dark" colspan="2">Obesidad</th>'
    html += '<th class="th-dark" colspan="2">Sobrepeso</th>'
    html += '<th class="th-dark" colspan="2">Talla Alta</th>'
    html += '</tr><tr>'
    html += '<th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>'
    html += '<th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>'
    html += '<th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>'
    html += '</tr></thead><tbody>'
    html += '<tr><td class="label-left">05 a 11 a\u00f1os</td>'
    html += _td(all_data.get('obeso_5_11a', 0))
    html += _td(all_data.get('obeso_rec_5_11a', 0))
    html += _td(all_data.get('sobre_peso_5_11a', 0))
    html += _td(all_data.get('sobre_peso_rec_5_11a', 0))
    html += _td(all_data.get('te_alto_5_11a', 0))
    html += _td(all_data.get('te_alto_rec_5_11a', 0))
    html += '</tr></tbody></table>'

    # Parasitosis IMC
    html += '<div class="section-title">VIII PARASITOSIS</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" colspan="2">Evaluaci\u00f3n por IMC de 5 a 11 a\u00f1os</th>'
    html += '<th class="th-dark">Dx</th><th class="th-dark">Recup</th>'
    html += '</tr></thead><tbody>'
    para_items = [
        ('Delgadez', 'delgadez_imc_5_11a', 'delgadez_imc_rec_5_11a'),
        ('Normal', 'normal_imc_5_11a', ''),
        ('Sobrepeso', 'sobrepeso_imc_5_11a', 'sobrepeso_imc_rec_5_11a'),
        ('Obeso', 'obeso_imc_5_11a', 'obeso_imc_rec_5_11a'),
    ]
    for i, (label, dx_key, rec_key) in enumerate(para_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td><td></td>'
        html += _td(all_data.get(dx_key, 0))
        html += _td(all_data.get(rec_key, 0) if rec_key else '')
        html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: LABORATORIO
# ============================================================
def _sec_laboratorio(all_data):
    html = '<div class="section-title">EX\u00c1MENES DE LABORATORIO / TAMIZAJES</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">ACTIVIDAD</th>'
    for age in ['1 a\u00f1o', '2 a\u00f1os', '3 a\u00f1os', '4 a\u00f1os', '5 a 11 a\u00f1os']:
        html += f'<th class="th-dark" colspan="3">{age}</th>'
    html += '</tr><tr>'
    for _ in range(5):
        html += '<th class="th-medium">Prog</th><th class="th-medium">Mensual</th><th class="th-medium">%</th>'
    html += '</tr></thead><tbody>'

    lab_items = [
        ('Total de Dosaje HB/HTO',
         ['dosa_hb_1a', 'dosa_hb_2a', 'dosa_hb_3a', 'dosa_hb_4a', 'dosa_hb_5_11a']),
        ('Nro Total de Test de Graham',
         ['test_graham_1a', 'test_graham_2a', 'test_graham_3a', 'test_graham_4a', 'test_graham_5_11a']),
        ('Nro de Test de Graham Positivos',
         ['test_graham_posit_1a', 'test_graham_posit_2a', 'test_graham_posit_3a', 'test_graham_posit_4a', 'test_graham_posit_5_11a']),
        ('Nro Total de Examen Seriado de Heces',
         ['seriado_heces_1a', 'seriado_heces_2a', 'seriado_heces_3a', 'seriado_heces_4a', 'seriado_heces_5_11a']),
        ('Nro de Examen Seriado de Heces Positivos',
         ['seriado_heces_positivo_1a', 'seriado_heces_positivo_2a', 'seriado_heces_positivo_3a', 'seriado_heces_positivo_4a', 'seriado_heces_positivo_5_11a']),
    ]
    for i, (label, keys) in enumerate(lab_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        for k in keys:
            html += '<td>0</td>'
            html += _td(all_data.get(k, 0))
            html += '<td>0</td>'
        html += '</tr>'

    # Parasitosis tratados
    graham_pos = sum(all_data.get(f'test_graham_posit_{suf}', 0) for suf in ['1a','2a','3a','4a','5_11a'])
    seriado_pos = sum(all_data.get(f'seriado_heces_positivo_{suf}', 0) for suf in ['1a','2a','3a','4a','5_11a'])
    html += f'<tr><td class="label-left">PARASITOSIS TEST GRAHAM O EXAMEN HECES TRATADOS</td>'
    for _ in range(5):
        html += '<td></td><td></td><td></td>'
    html += '</tr>'
    html += f'<tr><td class="label-left">DX DE PARASITOSIS</td><td class="num" colspan="3">{graham_pos + seriado_pos:,}</td>'
    for _ in range(4):
        html += '<td></td><td></td><td></td>'
    html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: IX. PROFILAXIS ANTIPARASITARIA
# ============================================================
def _sec_profilaxis(all_data):
    html = '<div class="section-title">IX. ADMINISTRACI\u00d3N DE PROFILAXIS ANTIPARASITARIA</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">ACTIVIDADES</th>'
    for age in ['01 a\u00f1o', '02 a\u00f1os', '03 a\u00f1os', '04 a\u00f1os', '05 - 11 a\u00f1os']:
        html += f'<th class="th-dark" colspan="2">{age}</th>'
    html += '</tr><tr>'
    for _ in range(5):
        html += '<th class="th-medium">1\u00ba</th><th class="th-medium">2\u00ba</th>'
    html += '</tr></thead><tbody>'
    html += '<tr><td class="label-left">Administraci\u00f3n de Profilaxis Antiparasitaria</td>'
    html += _td(all_data.get('antiparasitaria_1_1a', 0))
    html += _td(all_data.get('antiparasitaria_2_1a', 0))
    for k1, k2 in [('antiparasitaria_1_2a','antiparasitaria_2_2a'),
                    ('antiparasitaria_1_3a','antiparasitaria_2_3a'),
                    ('antiparasitaria_1_4a','antiparasitaria_2_4a'),
                    ('antiparasitaria_1_5_11a','antiparasitaria_2_5_11a')]:
        html += _td(all_data.get(k1, 0))
        html += _td(all_data.get(k2, 0))
    html += '</tr></tbody></table>'
    return html

# ============================================================
# SECTION: XII. VISITA DOMICILIARIA
# ============================================================
def _sec_visita_domiciliaria(all_data):
    html = '<div class="section-title">XII. VISITA DOMICILIARIA</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">TIPOS DE VISITA / EDADES</th>'
    html += '<th class="th-dark" rowspan="2">Total</th>'
    for a in ['RN', '<1a', '1a', '2a', '3a', '4a', '5-11a']:
        html += f'<th class="th-medium">{a}</th>'
    html += '</tr></thead><tbody>'

    vd_items = [
        ('Seguimiento al Control CRED', 'vd_seg_cred'),
        ('Seguimiento a Problemas Nutricionales', 'vd_seg_nutric'),
        ('Seguimiento a Problemas del Desarrollo', 'vd_seg_desarrollo'),
        ('Entrega de Suplementaci\u00f3n', 'vd_entrega_suplem'),
        ('Verificaci\u00f3n de Consumo de Micronutrientes', 'vd_verif_micronut'),
    ]
    for i, (label, prefix) in enumerate(vd_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        html += _td(all_data.get(f'{prefix}_total', 0))
        for a_suf in ['rn', 'men_1a', '1a', '2a', '3a', '4a', '5_11a']:
            html += _td(all_data.get(f'{prefix}_{a_suf}', 0))
        html += '</tr>'
    html += '<tr class="row-total"><td>TOTAL</td>'
    html += '<td></td>'
    for _ in range(7):
        html += '<td></td>'
    html += '</tr></tbody></table>'
    return html

# ============================================================
# SECTION: XV. SALUD MENTAL
# ============================================================
def _sec_salud_mental(all_data):
    html = '<div class="section-title">XV. SALUD MENTAL</div>'
    html += '<div class="dual-grid">'
    # Left: Psicosocial
    html += '<div>'
    html += '<div class="sub2-title">2.1 Evaluaci\u00f3n del desarrollo psicosocial con test de habilidades</div>'
    html += '<table><thead><tr><th class="th-dark">Resultado</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    psico_items = [
        ('Muy Bajo', 'sm_eval_psicosocial_muy_bajo'),
        ('Bajo', 'sm_eval_psicosocial_bajo'),
        ('Promedio Bajo', 'sm_eval_psicosocial_prom_bajo'),
        ('Promedio', 'sm_eval_psicosocial_prom'),
        ('Promedio Alto', 'sm_eval_psicosocial_prom_alto'),
        ('Alto', 'sm_eval_psicosocial_alto'),
        ('Muy Alto', 'sm_eval_psicosocial_muy_alto'),
    ]
    for i, (label, key) in enumerate(psico_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_td(all_data.get(key, 0))}</tr>'
    html += '</tbody></table>'
    html += '</div>'

    # Right column with 2 sections stacked
    html += '<div>'
    # Agudeza visual
    html += '<div class="sub2-title">2.2 Evaluaci\u00f3n de Agudeza visual</div>'
    html += '<table><thead><tr><th class="th-dark">Resultado</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    agudeza_items = [
        ('Normal', 'sm_eval_agudeza_normal'),
        ('Disminuci\u00f3n de Agudeza visual', 'sm_eval_agudeza_disminuida'),
    ]
    for i, (label, key) in enumerate(agudeza_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_td(all_data.get(key, 0))}</tr>'
    html += '</tbody></table>'

    # Postural
    html += '<div class="sub2-title" style="margin-top:4px;">2.5 Evaluaci\u00f3n F\u00edsico Postural</div>'
    html += '<table><thead><tr><th class="th-dark">Resultado</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    postural_items = [
        ('Normal', 'sm_eval_postural_normal'),
        ('Hiperlordosis', 'sm_eval_postural_hiperlordosis'),
        ('Hipercifosis', 'sm_eval_postural_hipercifosis'),
        ('Escoliosis', 'sm_eval_postural_escoliosis'),
    ]
    for i, (label, key) in enumerate(postural_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_td(all_data.get(key, 0))}</tr>'
    html += '</tbody></table>'

    # Tanner
    html += '<div class="sub2-title" style="margin-top:4px;">2.4 Desarrollo sexual seg\u00fan Tanner</div>'
    html += '<table><thead><tr><th class="th-dark">Resultado</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    tanner_items = [
        ('Adecuado', 'sm_tanner_adecuado'),
        ('Retardo', 'sm_tanner_retardo'),
        ('Precoz', 'sm_tanner_precoz'),
    ]
    for i, (label, key) in enumerate(tanner_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_td(all_data.get(key, 0))}</tr>'
    html += '</tbody></table>'
    html += '</div>'
    html += '</div>'  # end dual-grid
    return html

# ============================================================
# SECTION: TAMIZAJES
# ============================================================
def _sec_tamizajes(all_data):
    html = '<div class="section-title">TAMIZAJES</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">EDAD</th>'
    for h in ['< 1 - 2', '3 - 5', '6 - 9', '10 - 11']:
        html += f'<th class="th-dark">{h}</th>'
    html += '<th class="th-dark" rowspan="2">TOTAL</th>'
    html += '</tr></thead><tbody>'

    tamizajes_items = [
        ('VIOLENCIA FAMILIAR / MALTRATO INFANTIL',
         ['tamizaje_viol_1_2a', 'tamizaje_viol_3_5a', 'tamizaje_viol_6_9a', 'tamizaje_viol_10_11a']),
        ('TRASTORNO DEPRESIVO',
         ['', '', '', 'tamizaje_td_10_11a']),
        ('ALCOHOL Y DROGAS',
         ['', '', 'tamizaje_ad_6_9a', 'tamizaje_ad_10_11a']),
        ('PROBLEMAS DEL NEURODESARROLLO 0-3 A\u00d1OS',
         ['tamizaje_nd_2a', '', '', '']),
        ('TRASTORNOS MENTALES Y DEL COMPORTAMIENTO',
         ['', '', '', '']),
    ]
    for i, (label, keys) in enumerate(tamizajes_items):
        vals = [all_data.get(k, 0) if k else 0 for k in keys]
        total = sum(v for v in vals)
        cls = ' class="row-header"' if i == 0 else (' class="row-sub"' if i % 2 == 0 else '')
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        for v in vals:
            html += _td(v)
        html += _td(total)
        html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: TAMIZAJES POSITIVOS
# ============================================================
def _sec_tamizajes_positivos(all_data):
    html = '<div class="section-title">TAMIZAJES POSITIVOS</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">EDAD</th>'
    for h in ['< 1 - 2', '3 - 5', '6 - 9', '10 - 11']:
        html += f'<th class="th-dark">{h}</th>'
    html += '<th class="th-dark" rowspan="2">TOTAL</th>'
    html += '</tr></thead><tbody>'

    pos_items = [
        ('VIOLENCIA FAMILIAR / MALTRATO INFANTIL',
         ['tamizaje_viol_posit_1_2a', 'tamizaje_viol_posit_3_5a', 'tamizaje_viol_posit_6_9a', 'tamizaje_viol_posit_10_11a']),
        ('TRASTORNO DEPRESIVO', ['', '', '', 'tamizaje_td_posit_10_11a']),
        ('TRASTORNO DE CONSUMO DE ALCOHOL', ['', '', '', 'tamizaje_ad_alcohol_posit_10_11a']),
        ('TRASTORNO DE CONSUMO DE TABACO', ['', '', '', 'tamizaje_ad_tabaco_posit_10_11a']),
        ('TRASTORNO DE CONSUMO DE DROGAS', ['', '', '', 'tamizaje_ad_drogas_posit_10_11a']),
        ('PROBLEMAS DEL NEURODESARROLLO', ['', '', '', '']),
        ('TRASTORNOS MENTALES Y DEL COMPORTAMIENTO', ['', '', '', '']),
    ]
    for i, (label, keys) in enumerate(pos_items):
        vals = [all_data.get(k, 0) if k else 0 for k in keys]
        total = sum(v for v in vals)
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        for v in vals:
            html += _td(v)
        html += _td(total)
        html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: XV. SALUD OCULAR / ROP
# ============================================================
def _sec_rop(all_data):
    html = '<div class="section-title">XV. SALUD OCULAR</div>'
    html += '<div class="sub-section-title">RETINOPAT\u00cdA DE LA PREMATURIDAD - ROP</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">Actividad</th>'
    for age in ['< 1m', '1m - 6m', '7m - 11m', '1a - 3a']:
        html += f'<th class="th-medium">{age}</th>'
    html += '<th class="th-dark" rowspan="2">TOTAL</th>'
    html += '</tr></thead><tbody>'

    rop_items = [
        ('Tamizaje y seguimiento de RN con sospecha de ROP', 'o_tamrn_fr'),
        ('Tamizaje de reci\u00e9n nacidos con factores de riesgo', 'o_tamrn_fr_n'),
        ('Seguimiento de reci\u00e9n nacidos con factores de riesgo', 'o_tamrn_fr_s'),
        ('Referencia de reci\u00e9n nacidos con FR de ROP', 'o_tamrn_fr_r'),
        ('Diagn\u00f3stico de RN con ROP', 'o_dx_retinoprema'),
        ('Casos de reci\u00e9n nacidos con ROP', 'o_dx_retinoprema_c'),
        ('Referencia de reci\u00e9n nacidos con ROP', 'o_ref_retinoprema'),
        ('Tratamiento de RN con ROP', 'o_tto_retinoprema'),
        ('Tratamiento con L\u00e1ser', 'o_tto_retinoprema_ct_l'),
        ('Tratamiento con antiangiog\u00e9nico', 'o_tto_retinoprema_ct_a'),
        ('Tratamiento L\u00e1ser + antiangiog\u00e9nico', 'o_tto_retinoprema_ct_lm'),
        ('Tratamiento intrav\u00edtreo', 'o_tto_retinoprema_ct_i'),
    ]
    for i, (label, prefix) in enumerate(rop_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        for age_suf in ['0_29d', '6m', '7m11m', '1_3a']:
            html += _td(all_data.get(f'{prefix}_{age_suf}', 0))
        html += _td(all_data.get(f'{prefix}_total', 0))
        html += '</tr>'
    html += '<tr class="row-total"><td>TOTAL</td>'
    for _ in range(5):
        html += '<td></td>'
    html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: ATENCIÃ“N SALUD OCULAR < 3a
# ============================================================
def _sec_salud_ocular_menor3(all_data):
    html = '<div class="section-title">ATENCI\u00d3N DE SALUD OCULAR EN NI\u00d1OS MENORES 3 A\u00d1OS</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">Actividad</th>'
    for age in ['< 1a', '1a', '2a', '3a', '4a', '5a']:
        html += f'<th class="th-medium">{age}</th>'
    html += '<th class="th-dark" rowspan="2">TOTAL</th>'
    html += '</tr></thead><tbody>'

    ocular_items = [
        ('Examen de los Ojos y de la Visi\u00f3n - Normal', 'o_ex_ojo_vis_n'),
        ('Examen de los Ojos y de la Visi\u00f3n - Anormal', 'o_ex_ojo_vis_a'),
        ('Evaluaci\u00f3n sospecha alteraciones oculares', 'o_eva_ojo_vis_n'),
        ('Referencia de alteraciones oculares', 'o_ex_ojo_vis_rf'),
    ]
    for i, (label, prefix) in enumerate(ocular_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        for age_suf in ['0_11m', '1a', '2a', '3a', '4a', '5a']:
            html += _td(all_data.get(f'{prefix}_{age_suf}', 0))
        html += _td(all_data.get(f'{prefix}_0_5a_total', 0))
        html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: ERRORES DE REFRACCIÃ“N
# ============================================================
def _sec_errores_refraccion(all_data):
    html = '<div class="section-title">ERRORES DE REFRACCI\u00d3N EN NI\u00d1OS DE 3 A 11 A\u00d1OS - ER</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">EDAD</th>'
    for age in ['3 - 4a', '5 - 7a', '8 - 11a']:
        html += f'<th class="th-medium">{age}</th>'
    html += '<th class="th-dark" rowspan="2">TOTAL</th>'
    html += '</tr></thead><tbody>'

    er_items = [
        ('Tamizaje de ER', [
            ('Detecci\u00f3n de la Agudeza Visual', 'o_determ_agudeza_visual')]),
        ('Evaluaci\u00f3n de ER', [
            ('Evaluaci\u00f3n Errores Refractivos', 'o_determ_agudeza_visual_eva')]),
        ('Diagn\u00f3stico de ER', [
            ('Hipermetrop\u00eda', 'o_dx_errr_hip'),
            ('Miop\u00eda', 'o_dx_errr_mio'),
            ('Astigmatismo', 'o_dx_errr_ast'),
        ]),
    ]
    for cat, items in er_items:
        html += f'<tr class="row-header"><td class="label-left">{cat}</td>'
        for _ in range(4):
            html += '<td></td>'
        html += '</tr>'
        for i, (label, prefix) in enumerate(items):
            cls = ' class="row-sub"' if i % 2 == 1 else ''
            html += f'<tr{cls}><td class="label-indent">{label}</td>'
            for age_suf in ['3_4a', '5_7a', '8_11a']:
                html += _td(all_data.get(f'{prefix}_{age_suf}', 0))
            html += _td(all_data.get(f'{prefix}_total', 0))
            html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: XVI. IRAS/EDAS (within FORMATO NIÃ‘O)
# ============================================================
def _sec_iras_edas(all_data):
    html = '<div class="section-title">XVI. ATENCI\u00d3N DE LAS ENFERMEDADES PREVALENTES DE LA INFANCIA</div>'

    # A. IRA
    html += '<div class="sub-section-title">A. INFECCI\u00d3N RESPIRATORIA AGUDA (IRA)</div>'
    html += '<table>'
    html += '<colgroup><col style="width:28%"><col style="width:10%"><col style="width:10%"><col style="width:10%"><col style="width:10%"><col style="width:10%"><col style="width:10%"><col style="width:12%"></colgroup>'
    html += '<thead><tr><th class="th-dark" rowspan="2">DIAGN\u00d3STICOS</th>'
    html += '<th class="th-dark" colspan="6">Grupo de Edad</th>'
    html += '<th class="th-dark" rowspan="2">Total</th>'
    html += '</tr><tr>'
    for h in ['29d a 59 D\u00edas', '02 - 11 Meses', '01 a\u00f1o', '2 a\u00f1o', '3 a\u00f1o', '4 a\u00f1o']:
        html += f'<th class="th-medium">{h}</th>'
    html += '</tr></thead><tbody>'

    html += '<tr class="row-header"><td class="label-left">1. Total de Casos de IRA (1+2+3)</td>'
    for _ in range(7):
        html += '<td class="zero">0</td>'
    html += '</tr>'

    html += '<tr class="row-sub"><td class="label-left">1.1 N\u00b0 casos de IRA sin complicaciones (a+b+c+d+e)</td>'
    for suf in ['29d_59d', '2_11m', '1a', '2a', '3a', '4a']:
        html += _td(all_data.get(f'ira_sin_compl_{suf}', 0))
    html += _td(all_data.get('ira_sin_compl_total', 0))
    html += '</tr>'

    ira_sub_items = [
        ('a. IRA no complicada', 'ira_no_compl'),
        ('b. Faringoamigdalitis Aguda', 'faringoamigdalitis'),
        ('c. Otitis Media Aguda (OMA)', 'oma'),
        ('d. Sinusitis Aguda', 'sinusitis'),
        ('e. Neumon\u00eda sin complicaciones', 'neumonia_sin_compl'),
    ]
    for i, (label, prefix) in enumerate(ira_sub_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-indent">{label}</td>'
        for suf in ['29d_59d', '2_11m', '1a', '2a', '3a', '4a']:
            html += _td(all_data.get(f'{prefix}_{suf}', 0))
        html += _td(all_data.get(f'{prefix}_total', 0))
        html += '</tr>'

    html += '<tr class="row-sub"><td class="label-left">1.2 N\u00b0 casos IRA con complicaciones (a+b+c)</td>'
    for suf in ['29d_59d', '2_11m', '1a', '2a', '3a', '4a']:
        html += _td(all_data.get(f'ira_con_compl_{suf}', 0))
    html += _td(all_data.get('ira_con_compl_total', 0))
    html += '</tr>'

    ira_compl = [
        ('a. IRA con complicaciones', 'ira_con_compl'),
        ('b. Neumon\u00eda Grave / EMG < 2 Meses', 'neumonia_grave_men2m'),
        ('c. Neumon\u00eda y EMG en 2m a 4a', 'neumonia_emg_2m_4a'),
    ]
    for i, (label, prefix) in enumerate(ira_compl):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-indent">{label}</td>'
        for suf in ['29d_59d', '2_11m', '1a', '2a', '3a', '4a']:
            html += _td(all_data.get(f'{prefix}_{suf}', 0))
        html += _td(all_data.get(f'{prefix}_total', 0))
        html += '</tr>'

    html += '</tbody></table>'

    # B. SOB
    html += '<div class="sub-section-title">B. S\u00cdNDROME DE OBSTRUCCI\u00d3N BRONQUIAL (SOB) - ASMA</div>'
    html += '<table>'
    html += '<colgroup><col style="width:28%"><col style="width:10%"><col style="width:10%"><col style="width:10%"><col style="width:10%"><col style="width:10%"><col style="width:10%"><col style="width:12%"></colgroup>'
    html += '<thead><tr><th class="th-dark" rowspan="2">DIAGN\u00d3STICOS</th>'
    html += '<th class="th-dark" colspan="6">Grupo de Edad</th>'
    html += '<th class="th-dark" rowspan="2">Total</th>'
    html += '</tr><tr>'
    for h in ['02 - 11 Meses', '01 a\u00f1o', '2 a\u00f1o', '3 a\u00f1o', '4 a\u00f1o', '05 - 11 A\u00f1os']:
        html += f'<th class="th-medium">{h}</th>'
    html += '</tr></thead><tbody>'
    html += '<tr><td class="label-indent">a. SOB/Asma</td>'
    for suf in ['2_11m', '1a', '2a', '3a', '4a', '5_11a']:
        html += _td(all_data.get(f'sob_asma_{suf}', 0))
    html += _td(all_data.get('sob_asma_total', 0))
    html += '</tr></tbody></table>'

    # C. EDA
    html += '<div class="sub-section-title">C. ENFERMEDAD DIARREICA AGUDA (EDA)</div>'
    html += '<table>'
    html += '<colgroup><col style="width:28%"><col style="width:11%"><col style="width:11%"><col style="width:11%"><col style="width:11%"><col style="width:11%"><col style="width:11%"><col style="width:12%"></colgroup>'
    html += '<thead><tr><th class="th-dark" rowspan="2">DIAGN\u00d3STICOS</th>'
    html += '<th class="th-dark" colspan="6">Grupo de Edad</th>'
    html += '<th class="th-dark" rowspan="2">Total</th>'
    html += '</tr><tr>'
    for h in ['< 01 A\u00f1o', '01 a\u00f1o', '2 a\u00f1o', '3 a\u00f1o', '4 a\u00f1o', '05 - 11 A\u00f1os']:
        html += f'<th class="th-medium">{h}</th>'
    html += '</tr></thead><tbody>'

    html += '<tr class="row-header"><td class="label-left">1. Enfermedades Diarreicas sin complicaciones (a+b+c)</td>'
    for suf in ['men1a', '1a', '2a', '3a', '4a', '5_11a']:
        html += _td(all_data.get(f'eda_sin_compl_{suf}', 0))
    html += _td(all_data.get('eda_sin_compl_total', 0))
    html += '</tr>'

    eda_sub = [
        ('a. Diarrea Aguda Acuosa sin deshidrataci\u00f3n', 'daa_sin_desh'),
        ('b. Diarrea Aguda Disent\u00e9rica sin deshidrataci\u00f3n', 'dad_sin_desh'),
        ('c. Diarrea Persistente sin deshidrataci\u00f3n', 'dp_sin_desh'),
    ]
    for i, (label, prefix) in enumerate(eda_sub):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-indent">{label}</td>'
        for suf in ['men1a', '1a', '2a', '3a', '4a', '5_11a']:
            html += _td(all_data.get(f'{prefix}_{suf}', 0))
        html += _td(all_data.get(f'{prefix}_total', 0))
        html += '</tr>'

    html += '<tr class="row-header"><td class="label-left">2. Enfermedades Diarreicas con complicaciones (a+b+c+d+e+f)</td>'
    for suf in ['men1a', '1a', '2a', '3a', '4a', '5_11a']:
        html += _td(all_data.get(f'eda_con_compl_{suf}', 0))
    html += _td(all_data.get('eda_con_compl_total', 0))
    html += '</tr>'

    eda_compl = [
        ('a. Diarrea Aguda Acuosa con deshidrataci\u00f3n', 'daa_con_desh'),
        ('b. Diarrea Aguda Disent\u00e9rica con deshidrataci\u00f3n', 'dad_con_desh'),
        ('c. Diarrea Persistente con deshidrataci\u00f3n', 'dp_con_desh'),
        ('d. DAA con deshidrataci\u00f3n con shock', 'daa_con_desh_shock'),
        ('e. DAD con deshidrataci\u00f3n con shock', 'dad_con_desh_shock'),
        ('f. DP con deshidrataci\u00f3n con shock', 'dp_con_desh_shock'),
    ]
    for i, (label, prefix) in enumerate(eda_compl):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-indent">{label}</td>'
        for suf in ['men1a', '1a', '2a', '3a', '4a', '5_11a']:
            html += _td(all_data.get(f'{prefix}_{suf}', 0))
        html += _td(all_data.get(f'{prefix}_total', 0))
        html += '</tr>'
    html += '</tbody></table>'

    # Zinc y SRO
    html += '<div class="sub-section-title">ADMINISTRACI\u00d3N DE ZINC Y SAL DE REHIDRATACI\u00d3N ORAL</div>'
    html += '<table>'
    html += '<colgroup><col style="width:28%"><col style="width:11%"><col style="width:11%"><col style="width:11%"><col style="width:11%"><col style="width:11%"><col style="width:11%"><col style="width:12%"></colgroup>'
    html += '<thead><tr><th class="th-dark" rowspan="2">ACTIVIDADES</th>'
    html += '<th class="th-dark" colspan="6">Grupo de Edad</th>'
    html += '<th class="th-dark" rowspan="2">Total</th>'
    html += '</tr><tr>'
    for h in ['< 1 a\u00f1o', '01 a\u00f1o', '2 a\u00f1o', '3 a\u00f1o', '4 a\u00f1o', '05 - 11 A\u00f1os']:
        html += f'<th class="th-medium">{h}</th>'
    html += '</tr></thead><tbody>'
    html += '<tr><td class="label-left">Administraci\u00f3n de tratamiento - SRO</td>'
    for suf in ['men1a', '1a', '2a', '3a', '4a', '5_11a']:
        html += _td(all_data.get(f'sro_{suf}', 0))
    html += _td(all_data.get('sro_total', 0))
    html += '</tr>'
    html += '<tr class="row-sub"><td class="label-left">Administraci\u00f3n de tratamiento - Zinc (ZN)</td>'
    for suf in ['men1a', '1a', '2a', '3a', '4a', '5_11a']:
        html += _td(all_data.get(f'zinc_{suf}', 0))
    html += _td(all_data.get('zinc_total', 0))
    html += '</tr>'
    html += '</tbody></table>'

    return html

# ============================================================
# TOP-LEVEL BUILDER
# ============================================================
def build_page1_html(col_names, filas_cred, totales_main, secciones,
                     c24, c1, c2, c3, c4, data_composite=None, filtros=None):
    """Build Page 1 HTML matching referencia de formato exel cred.txt EXACTLY."""
    html = '<style>' + _REPORT_CSS + '</style>'
    html += '<div class="page">'
    d = data_composite or {}

    # === HEADER ===
    html += _sec_header(filtros or {})

    # === CONTROL CRECIMIENTO Y DESARROLLO ===
    html += _sec_cred_controls(col_names, filas_cred, totales_main)

    # === I. ATENCIÃ“N DEL RECIÃ‰N NACIDO ===
    html += _sec_atencion_rn(c24, c1, c4)

    # === IX. EVALUACIÃ“N DEL DESARROLLO ===
    html += _sec_evaluacion_desarrollo(d)

    # === II. SESIONES + VI. LACTANCIA (dual-grid) ===
    html += '<div class="dual-grid">'
    html += _sec_sesiones(d)
    html += _sec_lactancia(d)
    html += '</div>'

    # === XVI. IRAS/EDAS ===
    html += _sec_iras_edas(d)

    # Footer
    html += '''
    <div style="font-size:8px;color:#595959;margin-top:8px;border-top:1px solid #9DC3E6;padding-top:4px;">
        DIRESA CUSCO &nbsp;|&nbsp; DEIT &nbsp;|&nbsp; Sistema HIS &nbsp;|&nbsp; CRED 2026
    </div>
    </div>'''
    return html


# ============================================================
# IRAS/EDAS STANDALONE PAGE BUILDER
# ============================================================
def build_iras_edas_html(data):
    """Build IRAS/EDAS page matching ref HTML EXACTLY.

    data dict keys:
        filtros, anio, ie (iras_edas_2024 data), diag (diagnosis data with ref age groups),
        proc (CPT procedure data), resumen (monthly summary)
    """
    html = '<style>' + _REPORT_CSS + '</style>'
    html += '<div class="page">'
    f = data.get('filtros', {})
    anio = str(data.get('anio', '2026'))

    # === HEADER ===
    html += '''
    <div class="header">
        <h2>DIRECCI\u00d3N REGIONAL DE SALUD CUSCO</h2>
        <h3>DIRECCI\u00d3N DE ESTAD\u00cdSTICA E INFORM\u00c1TICA Y TELECOMUNICACI\u00d3N</h3>
    </div>'''
    html += '''
    <div class="filter-row">
        <div class="filter-cell"><label>RED DE SALUD:</label><span>''' + _esc(f.get('red', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>MICRO RED:</label><span>''' + _esc(f.get('microred', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>PROVINCIA:</label><span>''' + _esc(f.get('provincia', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>A\u00d1O:</label><span>''' + anio + '''</span></div>
    </div>
    <div class="filter-row">
        <div class="filter-cell"><label>ESTABLECIMIENTO:</label><span>''' + _esc(f.get('establecimiento', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>DISTRITO:</label><span>''' + _esc(f.get('distrito', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>MES INICIO:</label><span>''' + str(f.get('mes_ini', f.get('mes_inicio', '1'))) + '''</span></div>
        <div class="filter-cell"><label>MES FIN:</label><span>''' + str(f.get('mes_fin', f.get('mes_fin', '6'))) + '''</span></div>
    </div>'''

    html += '<div class="page-number">P\u00e1gina 01</div>'
    html += '<div class="section-title">XVI. ATENCI\u00d3N DE LAS ENFERMEDADES PREVALENTES DE LA INFANCIA</div>'

    ie = data.get('ie', {})
    diag = data.get('diag', {})
    proc = data.get('proc', {})

    def _iv(key):
        return ie.get(f'IE_{key}', 0) or 0

    def _diag(cat, age_key):
        return diag.get(cat, {}).get(age_key, 0) or 0

    # ================================================================
    # A. INFECCIÃ“N RESPIRATORIA AGUDA (IRA)
    # ================================================================
    html += '<div class="sub-section-title">A. INFECCI\u00d3N RESPIRATORIA AGUDA (IRA)</div>'
    html += '''<table>
    <colgroup>
      <col style="width:5%"><col style="width:22%">
      <col style="width:11%"><col style="width:11%"><col style="width:11%"><col style="width:11%"><col style="width:11%">
      <col style="width:10%"><col style="width:8%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">DIAGN\u00d3STICOS</th>
        <th class="th-dark" colspan="6">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 29 D\u00edas</th>
        <th class="th-medium">29d a 59 D\u00edas</th>
        <th class="th-medium">02 - 11 Meses</th>
        <th class="th-medium">01 - 04 A\u00f1os</th>
        <th class="th-medium">05 - 11 A\u00f1os</th>
        <th class="th-medium">Total</th>
      </tr>
    </thead>
    <tbody>'''

    AGE5 = ['men29d', '29d_59d', '2_11m', '1_4a', '5_11a']

    def _td_age(val):
        if val == 0: return '<td class="zero">0</td>'
        return f'<td class="num">{val:,}</td>'

    def _row_total(cat):
        return sum(_diag(cat, a) for a in AGE5)

    # -- IRA formula texts --
    F_IRA_NO_COMPL = 'TD=D+DX=J00X, J040, J041, J042, J060, J068, J069, J209'
    F_FARINGO = 'TD=D+DX=J020, J029, J030, J038, J039'
    F_OMA = 'TD=D+DX=H650, H651, H660, H669'
    F_SINUSITIS = 'TD=D+DX=J010, J011, J012, J013, J014, J019'
    F_NEUMONIA = 'TD=D+DX=J129, J159, J189'
    F_IRAS_COMPL = 'TD=D+DX=A369, A370, A371, A378, A379, J120, J121, J122, J123, J128, J13X, J14X, J150\u2026'
    F_NEUM_GRAVE = 'TD=D+DX=J050, J051, J851, J860, J869, J90X, J939, J100, J110\u2026'
    F_NEUM_EMG = 'TD=D+DX=J050, J051, J851, J860, J869, J90X, J939, J100, J110\u2026'

    def _ira_sum_row(label, cat):
        """Row: label (colspan=2) | 5 formula cells | subtotal | grand_total"""
        r = f'<tr class="row-header"><td class="bold" colspan="2" style="text-align:left;padding-left:6px;">{_esc(label)}</td>'
        row_total = _row_total(cat)
        for a in AGE5:
            r += _td_age(_diag(cat, a))
        r += _td_age(row_total)
        r += '<td class="zero">0</td></tr>'
        return r

    def _ira_sub_row(label, formula, cat):
        """Sub-item row: empty | diag-sub | 5 formula cells | subtotal | grand_total"""
        row_total = _row_total(cat)
        r = f'<tr><td></td><td class="diag-sub">{_esc(label)}</td>'
        for a in AGE5:
            v = _diag(cat, a)
            if v == 0:
                r += f'<td class="formula">{_esc(formula)}</td>'
            else:
                r += _td_age(v)
        r += _td_age(row_total)
        r += '<td class="zero">0</td></tr>'
        return r

    def _ira_sub_row_nf(label, formula, cat):
        """Sub-item row with NO subtotal (neumonia grave has fewer cols)."""
        row_total = _row_total(cat)
        r = f'<tr><td></td><td class="diag-sub">{_esc(label)}</td>'
        for a in AGE5:
            v = _diag(cat, a)
            if v == 0:
                r += f'<td class="formula">{_esc(formula)}</td>'
            else:
                r += _td_age(v)
        r += _td_age(row_total)
        r += '<td class="zero">0</td></tr>'
        return r

    # 1. Total de Casos de IRA
    html += _ira_sum_row('1. Total de Casos de IRA (1+2+3)', 'ira_total')

    # 1.1 IRA sin complicaciones
    html += f'<tr class="row-sub"><td class="bold" colspan="2" style="text-align:left;padding-left:6px;">1.1 N\u00b0 casos de IRA sin complicaciones (a+b+c+d+e)</td>'
    sin_compl_total = sum(_diag(c, 'subtotal') for c in ['ira_no_compl','faringo','oma','sinusitis','neumonia_sin_compl'])
    for a in AGE5:
        html += _td_age(sum(_diag(c, a) for c in ['ira_no_compl','faringo','oma','sinusitis','neumonia_sin_compl']))
    html += _td_age(sin_compl_total)
    html += '<td class="zero">0</td></tr>'

    html += _ira_sub_row('a. Infecci\u00f3n Respiratoria Aguda (IRA) no complicada', F_IRA_NO_COMPL, 'ira_no_compl')
    html += _ira_sub_row('b. Faringoamigdalitis Aguda', F_FARINGO, 'faringo')
    html += _ira_sub_row('c. Otitis Media Aguda (OMA)', F_OMA, 'oma')
    html += _ira_sub_row('d. Sinusitis Aguda', F_SINUSITIS, 'sinusitis')
    html += _ira_sub_row('e. Neumon\u00eda sin complicaciones', F_NEUMONIA, 'neumonia_sin_compl')

    # 1.2 IRA con complicaciones
    html += f'<tr class="row-sub"><td class="bold" colspan="2" style="text-align:left;padding-left:6px;">1.2 N\u00b0 casos IRA con complicaciones (a+b+c)</td>'
    con_compl_total = sum(_diag(c, 'subtotal') for c in ['iras_con_compl','neumonia_grave_men2m','neumonia_emg_2m_4a'])
    for a in AGE5:
        html += _td_age(sum(_diag(c, a) for c in ['iras_con_compl','neumonia_grave_men2m','neumonia_emg_2m_4a']))
    html += _td_age(con_compl_total)
    html += '<td class="zero">0</td></tr>'

    html += _ira_sub_row('a. Infecciones Respiratorias Agudas con complicaciones', F_IRAS_COMPL, 'iras_con_compl')
    html += _ira_sub_row_nf('b. Neumon\u00eda Grave o Enfermedad Muy Grave en Ni\u00f1os Menores de 2 Meses', F_NEUM_GRAVE, 'neumonia_grave_men2m')
    html += _ira_sub_row_nf('c. Neumon\u00eda y Enfermedad Muy Grave en Ni\u00f1os de 2 Meses a 4 A\u00f1os', F_NEUM_EMG, 'neumonia_emg_2m_4a')

    html += '</tbody></table>'

    # ================================================================
    # OXIGENOTERAPIA / OXIMETRÃA
    # ================================================================
    OXI_IRA_F = '(TD=R+DX=(J129,J159,J189)+DX=94799.02)'
    OXM_IRA_F = '(TD=R+DX=(J129,J159,J189)+DX=94760)'

    html += '<div class="sub-section-title">OXIGENOTERAPIA / OXIMETR\u00cdA</div>'
    html += '''<table>
    <colgroup>
      <col style="width:5%"><col style="width:22%">
      <col style="width:11%"><col style="width:11%"><col style="width:11%"><col style="width:11%"><col style="width:11%">
      <col style="width:10%"><col style="width:8%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">ACTIVIDAD</th>
        <th class="th-dark" colspan="6">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 29 D\u00edas</th>
        <th class="th-medium">29d a 59 D\u00edas</th>
        <th class="th-medium">02 - 11 Meses</th>
        <th class="th-medium">01 - 04 A\u00f1os</th>
        <th class="th-medium">05 - 11 A\u00f1os</th>
        <th class="th-medium">Total</th>
      </tr>
    </thead>
    <tbody>'''

    oxi_ira = proc.get('oxigeno_ira', {})
    oxm_ira = proc.get('oximetria_ira', {})

    def _oxi_row(label, formula, data):
        r = f'<tr><td></td><td class="diag-sub">{_esc(label)}</td>'
        total = 0
        for a in AGE5:
            v = data.get(a, 0) or 0
            total += v
            if v == 0:
                r += f'<td class="formula">{_esc(formula)}</td>'
            else:
                r += _td_age(v)
        r += _td_age(total)
        r += '<td class="zero">0</td></tr>'
        return r

    html += _oxi_row('Oxigenoterapia', OXI_IRA_F, oxi_ira)
    html += _oxi_row('Oximetr\u00eda', OXM_IRA_F, oxm_ira)

    html += '</tbody></table>'

    # ================================================================
    # B. SÃNDROME DE OBSTRUCCIÃ“N BRONQUIAL (SOB) - ASMA
    # ================================================================
    SOB_AGE7 = ['men29d', '29d_59d', '2_11m', '12_23m', '2a', '3_4a', '5_11a']
    SOB_HEADERS = ['< 29 D\u00edas', '29d a 59 D\u00edas', '02 - 11 Meses', '12m - 23m', '02 - 02 A\u00f1os 11m', '03 - 04 A\u00f1os', '05 - 11 A\u00f1os']
    F_SOB = 'TD=D+DX=J210,J211,J218,J219,J440,J441,J448,J449,J450,J451,J459,J46X'

    html += '<div class="sub-section-title">B. S\u00cdNDROME DE OBSTRUCCI\u00d3N BRONQUIAL (SOB) - ASMA</div>'
    html += '''<table>
    <colgroup>
      <col style="width:5%"><col style="width:19%">
      <col style="width:9%"><col style="width:9%"><col style="width:9%"><col style="width:9%"><col style="width:9%"><col style="width:9%"><col style="width:9%">
      <col style="width:7%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">DIAGN\u00d3STICOS</th>
        <th class="th-dark" colspan="7">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>'''
    for h in SOB_HEADERS:
        html += f'<th class="th-medium">{h}</th>'
    html += '</tr></thead><tbody>'

    sob_total = sum(_diag('sob_asma', a) for a in SOB_AGE7)
    html += '<tr class="row-header"><td colspan="2" style="text-align:left;padding-left:6px;font-weight:bold;">SOB/Asma</td>'
    for a in SOB_AGE7:
        html += _td_age(_diag('sob_asma', a))
    html += _td_age(sob_total)
    html += '</tr>'

    html += '<tr><td></td><td class="diag-sub">a. SOB/Asma</td>'
    for a in SOB_AGE7:
        v = _diag('sob_asma', a)
        if v == 0:
            html += f'<td class="formula">{_esc(F_SOB)}</td>'
        else:
            html += _td_age(v)
    html += _td_age(sob_total)
    html += '</tr>'

    html += '</tbody></table>'

    # ================================================================
    # OXIGENOTERAPIA Y NEBULIZACIÃ“N
    # ================================================================
    OXI_SOB_F = '(TD=R+DX=(J210\u2026J46X)+DX=94799.02)'
    NEB_SOB_F = '(TD=R+DX=(J210\u2026J46X)+DX=94664)'

    html += '<div class="sub-section-title">OXIGENOTERAPIA Y NEBULIZACI\u00d3N</div>'
    html += '''<table>
    <colgroup>
      <col style="width:5%"><col style="width:19%">
      <col style="width:9%"><col style="width:9%"><col style="width:9%"><col style="width:9%"><col style="width:9%"><col style="width:9%"><col style="width:9%">
      <col style="width:7%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">ACTIVIDADES</th>
        <th class="th-dark" colspan="7">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>'''
    for h in SOB_HEADERS:
        html += f'<th class="th-medium">{h}</th>'
    html += '</tr></thead><tbody>'

    oxi_sob = proc.get('oxigeno_sob', {})
    neb_sob = proc.get('nebulizacion_sob', {})

    def _sob_proc_row(label, formula, data):
        r = f'<tr><td></td><td class="diag-sub">{_esc(label)}</td>'
        total = 0
        for a in SOB_AGE7:
            v = data.get(a, 0) or 0
            total += v
            if v == 0:
                r += f'<td class="formula">{_esc(formula)}</td>'
            else:
                r += _td_age(v)
        r += _td_age(total)
        return r + '</tr>'

    html += _sob_proc_row('Oxigenoterapia', OXI_SOB_F, oxi_sob)
    html += _sob_proc_row('Nebulizaci\u00f3n / Inhaloterapia', NEB_SOB_F, neb_sob)
    html += '<tr class="note-row"><td colspan="10">Fuentes Externas &nbsp;&nbsp;&nbsp; Reporte de Egresos</td></tr>'
    html += '</tbody></table>'

    # ================================================================
    # C. ENFERMEDAD DIARREICA AGUDA (EDA)
    # ================================================================
    EDA_AGE3 = ['menor1a', '1a_4a', '5_11a']
    EDA_HEADERS = ['< 01 A\u00f1o', '01 - 04 A\u00f1os', '05 - 11 A\u00f1os']
    F_DAA = 'TD=D+DX=A00.9,A01.0,A01.1,A01.2,A01.3,A01.4,A02.0,A04.0,A04.1,A04.9,A05.9,A06.2,A07.1,A07.2,A08.0,A08.2,A08.3,A08.4,A09.0,A09.9'
    F_DAD = 'TD=D+DX=A03.0,A03.9,A04.2,A04.3,A04.5,A06.0'
    F_DP = 'TD=D+DX=A09X'
    F_DAA_DESH = 'TD=D+DX=A00.9+E86X,A01.0+E86X,A01.1+E86X\u2026A09.9+E86X'
    F_DAD_DESH = 'TD=D+DX=A030+E86X,A039+E86X,A042+E86X,A043+E86X,A045+E86X,A060+E86X'
    F_DP_DESH = 'TD=D+DX=A09X+E86X'
    F_DAA_SHOCK = 'TD=D+DX=A00.9+E86X+R57.1\u2026A09.9+E86X+R57.1'
    F_DAD_SHOCK = 'TD=D+DX=A030+E86X+R57.1\u2026A060+E86X+R57.1'
    F_DP_SHOCK = 'TD=D+DX=A09X+E86X+R57.1'
    F_SRO = '(EDAD <= 11M) + DX=99199.11 + LAB=SRO'
    F_ZN = '(EDAD <= 11M) + DX=99199.11 + LAB=ZINC'

    def _eda_total(prefix, sfx, age_map):
        """Sum iras_edas_2024 columns for EDA diagnosis (sin_compl/desh/shock)."""
        total = 0
        a_keys = {'menor1a': 'menor1a', '1a_4a': '1a', '5_11a': '5_11a'}
        for ref_k, db_k in age_map.items():
            if ref_k == '1a_4a':
                total += (_iv(f'{prefix}{sfx}_{db_k}') + _iv(f'{prefix}{sfx}_2a') +
                         _iv(f'{prefix}{sfx}_3a') + _iv(f'{prefix}{sfx}_4a'))
            else:
                total += _iv(f'{prefix}{sfx}_{db_k}')
        return total

    def _eda_row(label, prefix, sfx=''):
        r = f'<tr><td></td><td class="diag-sub">{_esc(label)}</td>'
        # <1a
        v1 = _iv(f'{prefix}{sfx}_menor1a')
        # 1-4a
        v2 = (_iv(f'{prefix}{sfx}_1a') + _iv(f'{prefix}{sfx}_2a') +
              _iv(f'{prefix}{sfx}_3a') + _iv(f'{prefix}{sfx}_4a'))
        # 5-11a
        v3 = _iv(f'{prefix}{sfx}_5_11a')
        total = v1 + v2 + v3
        for v in [v1, v2, v3]:
            r += _td_age(v)
        r += _td_age(total)
        return r + '</tr>'

    html += '<div class="sub-section-title">C. ENFERMEDAD DIARREICA AGUDA (EDA)</div>'
    html += '''<table>
    <colgroup>
      <col style="width:5%"><col style="width:28%">
      <col style="width:18%"><col style="width:18%"><col style="width:14%">
      <col style="width:10%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">DIAGN\u00d3STICOS</th>
        <th class="th-dark" colspan="3">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 01 A\u00f1o</th>
        <th class="th-medium">01 - 04 A\u00f1os</th>
        <th class="th-medium">05 - 11 A\u00f1os</th>
      </tr>
    </thead>
    <tbody>'''

    # 1. EDA sin complicaciones
    def _eda_sin_compl_total():
        t = 0
        for pref in ['eda_acuosa', 'disenterica', 'eda_persistente']:
            t += (_iv(f'{pref}_menor1a') + _iv(f'{pref}_1a') + _iv(f'{pref}_2a') +
                  _iv(f'{pref}_3a') + _iv(f'{pref}_4a') + _iv(f'{pref}_5_11a'))
        return t

    html += '<tr class="row-header"><td class="bold" colspan="2" style="text-align:left;padding-left:6px;">1. Enfermedades Diarreicas sin complicaciones (a+b+c)</td>'
    s1_men1a = sum(_iv(f'{p}_menor1a') for p in ['eda_acuosa','disenterica','eda_persistente'])
    s1_1a4a = sum(_iv(f'{p}_1a')+_iv(f'{p}_2a')+_iv(f'{p}_3a')+_iv(f'{p}_4a') for p in ['eda_acuosa','disenterica','eda_persistente'])
    s1_5_11 = sum(_iv(f'{p}_5_11a') for p in ['eda_acuosa','disenterica','eda_persistente'])
    html += _td_age(s1_men1a) + _td_age(s1_1a4a) + _td_age(s1_5_11) + _td_age(s1_men1a+s1_1a4a+s1_5_11) + '</tr>'

    html += _eda_row('a. Diarrea Aguda Acuosa sin deshidrataci\u00f3n', 'eda_acuosa')
    html += _eda_row('b. Diarrea Aguda Disent\u00e9rica sin deshidrataci\u00f3n', 'disenterica')
    html += _eda_row('c. Diarrea Persistente sin deshidrataci\u00f3n', 'eda_persistente')

    # 2. EDA con complicaciones
    html += '<tr class="row-header"><td class="bold" colspan="2" style="text-align:left;padding-left:6px;">2. Enfermedades Diarreicas con complicaciones (a+b+c+d+e+f)</td>'
    s2_men1a = sum(_iv(f'{p}_desh_menor1a')+_iv(f'{p}_desh_shock_menor1a') for p in ['eda_acuosa','disenterica','eda_persistente'])
    s2_1a4a = sum(_iv(f'{p}_desh_1a')+_iv(f'{p}_desh_2a')+_iv(f'{p}_desh_3a')+_iv(f'{p}_desh_4a') +
                  _iv(f'{p}_desh_shock_1a')+_iv(f'{p}_desh_shock_2a')+_iv(f'{p}_desh_shock_3a')+_iv(f'{p}_desh_shock_4a')
                  for p in ['eda_acuosa','disenterica','eda_persistente'])
    s2_5_11 = sum(_iv(f'{p}_desh_5_11a')+_iv(f'{p}_desh_shock_5_11a') for p in ['eda_acuosa','disenterica','eda_persistente'])
    html += _td_age(s2_men1a) + _td_age(s2_1a4a) + _td_age(s2_5_11) + _td_age(s2_men1a+s2_1a4a+s2_5_11) + '</tr>'

    html += _eda_row('a. Diarrea Aguda Acuosa con deshidrataci\u00f3n', 'eda_acuosa', '_desh')
    html += _eda_row('b. Diarrea Aguda Disent\u00e9rica con deshidrataci\u00f3n', 'disenterica', '_desh')
    html += _eda_row('c. Diarrea Persistente con deshidrataci\u00f3n', 'eda_persistente', '_desh')
    html += _eda_row('d. Diarrea Aguda Acuosa con deshidrataci\u00f3n con shock', 'eda_acuosa', '_desh_shock')
    html += _eda_row('e. Diarrea Aguda Disent\u00e9rica con deshidrataci\u00f3n con shock', 'disenterica', '_desh_shock')
    html += _eda_row('f. Diarrea Persistente con deshidrataci\u00f3n con shock', 'eda_persistente', '_desh_shock')

    html += '</tbody></table>'

    # ================================================================
    # ADMINISTRACIÃ“N DE ZINC Y SAL DE REHIDRATACIÃ“N ORAL
    # ================================================================
    html += '<div class="sub-section-title">ADMINISTRACI\u00d3N DE ZINC Y SAL DE REHIDRATACI\u00d3N ORAL</div>'
    html += '''<table>
    <colgroup>
      <col style="width:5%"><col style="width:28%">
      <col style="width:18%"><col style="width:18%"><col style="width:14%">
      <col style="width:10%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">ACTIVIDADES</th>
        <th class="th-dark" colspan="3">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 1 a\u00f1o</th>
        <th class="th-medium">01 - 04 A\u00f1os</th>
        <th class="th-medium">05 - 11 A\u00f1os</th>
      </tr>
    </thead>
    <tbody>'''

    def _sro_row(label, prefix, formula):
        r = f'<tr><td></td><td class="diag-sub">{_esc(label)}</td>'
        v1 = _iv(f'{prefix}_menor1a')
        v2 = _iv(f'{prefix}_1a') + _iv(f'{prefix}_2a') + _iv(f'{prefix}_3a') + _iv(f'{prefix}_4a')
        v3 = _iv(f'{prefix}_5_11a')
        total = v1 + v2 + v3
        for v in [v1, v2, v3]:
            if v == 0:
                r += f'<td class="formula">{_esc(formula)}</td>'
            else:
                r += _td_age(v)
        r += _td_age(total)
        return r + '</tr>'

    html += _sro_row('Administraci\u00f3n de tratamiento (Sales de Rehidrataci\u00f3n Oral - SRO)', 'tto_sro', F_SRO)
    html += _sro_row('Administraci\u00f3n de tratamiento (Zinc - ZN)', 'tto_zn', F_ZN)

    html += '</tbody></table>'

    # ================================================================
    # RESUMEN ACUMULADO
    # ================================================================
    resumen = data.get('resumen', [])
    if not resumen:
        resumen = [{'mes': m} for m in range(1, 7)]

    RH = ['Mes', 'EDA Acuosa <1a', 'EDA Acuosa 1a', 'EDA Acuosa 2a', 'EDA Acuosa 3a', 'EDA Acuosa 4a',
          'IRA no comp <5a', 'Faringoamig. <5a', 'OMA <5a', 'Neumonia <5a', 'IRAS comp.', 'FONI']
    RK = ['eda_acuosa_men1a','eda_acuosa_1a','eda_acuosa_2a','eda_acuosa_3a','eda_acuosa_4a',
          'ira_no_compl_men5a','faringo_men5a','oma_men5a','neumonia_men5a','iras_compl','foni']

    html += f'<div class="sub-section-title">RESUMEN ACUMULADO (Enero - Junio {anio}) - HOJA PROCESO</div>'
    html += '<table><thead><tr>'
    for h in RH:
        cls = ' class="th-dark"' if h in ('Mes', 'FONI') else ' class="th-medium"'
        html += f'<th{cls}>{_esc(h)}</th>'
    html += '</tr></thead><tbody>'

    MESES = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Setiembre','Octubre','Noviembre','Diciembre']
    TR = {k: 0 for k in RK}
    for rm in resumen:
        mi = int(rm.get('mes', 1))
        row_cls = ' class="row-sub"' if mi % 2 == 0 else ''
        html += f'<tr{row_cls}><td>{mi} - {_esc(MESES[mi-1] if mi <= len(MESES) else "")}</td>'
        for k in RK:
            v = int(rm.get(k, 0) or 0)
            html += _td_age(v)
            TR[k] += v
        html += '</tr>'

    html += '<tr style="background:#2E75B6;color:#fff;font-weight:bold;"><td>TOTAL GENERAL</td>'
    for k in RK:
        html += _td_age(TR[k])
    html += '</tr>'

    html += '</tbody></table>'

    # Footer
    html += f'''
    <div style="font-size:8px;color:#595959;margin-top:8px;border-top:1px solid #9DC3E6;padding-top:4px;">
        DIRESA CUSCO &nbsp;|&nbsp; DEIT &nbsp;|&nbsp; Sistema HIS &nbsp;|&nbsp; A\u00f1o {anio} &nbsp;|&nbsp; Impreso: <span id="fecha_ie"></span>
    </div>'''

    html += '</div>'
    return html


def _render_seccion_table(sec):
    """Render a single seccion dict as CSS-class table."""
    titulo = sec.get('titulo', '')
    cols = sec.get('columnas', ['INDICADOR', 'TOTAL'])
    filas = sec.get('filas', [])
    html = f'<div class="section-title">{_esc(titulo)}</div>'
    html += '<table><thead><tr>'
    for c in cols:
        html += f'<th class="th-dark">{_esc(c)}</th>'
    html += '</tr></thead><tbody>'
    for fi, fila in enumerate(filas):
        if isinstance(fila, dict):
            vals = [fila.get(c, 0) for c in cols]
        elif isinstance(fila, list):
            vals = fila
        else:
            vals = [fila]
        cls = ' class="row-sub"' if fi % 2 == 1 else ''
        html += f'<tr{cls}>'
        for vi, v in enumerate(vals):
            if vi == 0:
                html += f'<td class="label-left">{_esc(str(v))}</td>'
            else:
                vn = int(v) if isinstance(v, (int, float)) else 0
                if vn == 0:
                    html += '<td class="zero">0</td>'
                else:
                    html += f'<td class="num">{vn:,}</td>'
        html += '</tr>'
    total = sec.get('total', 0)
    if total:
        html += f'<tr class="row-total"><td>TOTAL</td>'
        for c in cols[1:]:
            vn = int(total) if isinstance(total, (int, float)) else 0
            if vn == 0:
                html += '<td class="zero">0</td>'
            else:
                html += f'<td class="num">{vn:,}</td>'
        html += '</tr>'
    html += '</tbody></table>'
    return html


def build_suplementacion_html(secciones):
    """Build Page 2: Suplementacion."""
    html = '<style>' + _REPORT_CSS + '</style>'
    html += '<div class="page">'
    html += _sec_header({})
    for sec in secciones:
        html += _render_seccion_table(sec)
    html += '</div>'
    return html


def build_tx_anemia_html(secciones):
    """Build Page 3: Tratamiento de Anemia."""
    html = '<style>' + _REPORT_CSS + '</style>'
    html += '<div class="page">'
    html += _sec_header({})
    for sec in secciones:
        html += _render_seccion_table(sec)
    html += '</div>'
    return html

```

---

## 19. CÓDIGO FUENTE COMPLETO - app.py (Módulo Formatos MINSA)

```python
def reportes_minsa_ejecutar():
    data = request.json or {}
    tipo = data.get('tipo', 'formato_nino_cred')
    anio = str(data.get('anio', '2025'))
    meses = data.get('meses', [])
    filtros = {}
    for k in ['red','microred','nombre_establecimiento','provincia','distrito']:
        v = data.get(k, '').strip()
        if v and v != '(Todas)':
            filtros[k] = v
    conn = _db_cursor()
    cur = conn.cursor()
    esquema = _get_esquema()
    try:
        if tipo == 'formato_nino_cred':
            result = _reporte_completo_cred(cur, esquema, anio, meses, filtros)
        elif tipo == 'formato_iras_edas':
            result = _reporte_iras_edas(cur, esquema, anio, meses, filtros)
        else:
            return jsonify({'error': 'Tipo no vï¿½lido'}), 400
        return jsonify(result)
    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ============ REPORTE COMPLETO CRED (3 pï¿½ginas) ============
def _build_cred_where(anio, meses, filtros, alias=''):
    """Build WHERE clause for cred2024-style tables."""
    clauses = [f"anio = {anio}"]
    if meses:
        ms = ','.join(str(m) for m in meses)
        clauses.append(f"mes IN ({ms})")
    for col in ['red','microred','nombre_establecimiento','provincia','distrito']:
        val = filtros.get(col, '')
        if val:
            clauses.append(f"LOWER({col}) LIKE LOWER('%{val.replace(chr(39), chr(39)+chr(39))}%')")
    return ' AND '.join(clauses)

def _qcred_sum(cur, table, columns, where):
    """Query SUM of multiple columns from a cred2024-style table."""
    sums = ', '.join(f'COALESCE(SUM("{c}"),0) as "{c}"' for c in columns)
    cur.execute(f'SELECT {sums} FROM {table} WHERE {where}')
    row = cur.fetchone()
    return dict(zip([c for c in columns], [r or 0 for r in row]))

def _qcred_cols(cur, tables, where):
    """Query ALL numeric columns from cred2024 tables."""
    result = {}
    for alias, tname in tables.items():
        cur.execute(f"SELECT column_name FROM information_schema.columns WHERE table_schema='es_ivan' AND table_name='{tname}' AND data_type='bigint' ORDER BY ordinal_position")
        cols = [r[0] for r in cur.fetchall()]
        data = _qcred_sum(cur, f'es_ivan."{tname}"', cols, where)
        for k, v in data.items():
            result[f'{alias}_{k}'] = v
    return result

def _cred_flat(cred, cols):
    """Build flat section from cred data dict."""
    items = []
    total = 0
    for key, label, col in cols:
        v = cred.get(col, 0) or 0
        items.append({'INDICADOR': label, 'TOTAL': v})
        total += v
    return {'columnas': ['INDICADOR', 'TOTAL'], 'filas': items, 'total': total}

def _excel_grid(titulo, headers, row_defs):
    """Create a grid section matching Excel multi-column layout.
    headers: list of column header strings (first is row-label header)
    row_defs: list of dicts with 'label' and column values
    """
    col_count = len(headers)
    rows = []
    totals = {h: 0 for h in headers[1:]}
    for rd in row_defs:
        celdas = [rd.get('label', '')]
        for h in headers[1:]:
            val = rd.get(h, 0) or 0
            celdas.append(val)
            totals[h] = totals.get(h, 0) + val
        rows.append(celdas)
    total_celdas = ['TOTAL'] + [totals[h] for h in headers[1:]]
    return {
        'titulo': titulo,
        'tipo': 'grid',
        'grid': {
            'headers': headers,
            'rows': rows,
            'totales': total_celdas,
            'col_count': col_count
        }
    }


def _side_by_side(titulo, izquierda, derecha):
    return {
        'tipo': 'side_by_side',
        'titulo': titulo,
        'izquierda': izquierda,
        'derecha': derecha,
    }


def _sb_subsecciones(titulo, items_data):
    filas = []
    total = 0
    for label, valor in items_data:
        v = valor if isinstance(valor, (int, float)) else 0
        filas.append({'label': label, 'valor': v})
        total += v
    return {
        'titulo': titulo,
        'columnas': ['INDICADOR', 'TOTAL'],
        'filas': filas,
        'total': total
    }


# ============ HTML TABLE BUILDERS (Excel-matching layout) ============
def _esc(v):
    """Format value for HTML display."""
    if v is None: return ''
    if isinstance(v, (int, float)): return f'{v:,.0f}'
    s = str(v)
    s = s.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')
    return s

def _btd(v, extra=''):
    return f'<td style="border:1px solid #999;padding:2px 6px;vertical-align:top;{extra}">{_esc(v)}</td>'

def _bth(v, extra=''):
    return f'<th style="border:1px solid #999;padding:3px 6px;text-align:center;font-weight:bold;background:#f0f0f0;{extra}">{_esc(v)}</th>'

def _section_header(titulo, colspan, extra=''):
    return f'<tr><td colspan="{colspan}" style="border:1px solid #999;padding:4px 6px;font-weight:bold;background:#e8e8e8;{extra}">{_esc(titulo)}</td></tr>'

def _build_sec_table(sec):
    """Build HTML table for a single section (flat or grid)."""
    if not sec: return ''
    h = ''
    if sec.get('tipo') == 'grid' and sec.get('grid'):
        g = sec['grid']
        ncols = len(g['headers'])
        h += f'<table style="border-collapse:collapse;width:100%;font-family:Calibri,sans-serif;font-size:9pt;">'
        h += f'<tr>{"".join(_bth(c) for c in g["headers"])}</tr>'
        for row in g['rows']:
            h += '<tr>'
            for i, v in enumerate(row):
                h += _btd(v, 'text-align:right;' if i > 0 else '')
            h += '</tr>'
        if g.get('totales'):
            h += '<tr>'
            for i, v in enumerate(g['totales']):
                h += _btd(v, 'font-weight:bold;text-align:right;' if i > 0 else 'font-weight:bold;')
            h += '</tr>'
        h += '</table>'
        return h
    cols = sec.get('columnas', ['INDICADOR', 'TOTAL'])
    filas = sec.get('filas', [])
    if not filas:
        return ''
    ncols = len(cols)
    h += f'<table style="border-collapse:collapse;width:100%;font-family:Calibri,sans-serif;font-size:9pt;">'
    h += f'<tr>{"".join(_bth(c) for c in cols)}</tr>'
    for item in filas:
        h += '<tr>'
        for i, c in enumerate(cols):
            val = item.get(c)
            if val is None: val = item.get(c.lower())
            if val is None and i == 0: val = item.get('label', '')
            if val is None and i == 1: val = item.get('valor', 0)
            h += _btd(val, 'text-align:right;' if i > 0 else '')
        h += '</tr>'
    total = sec.get('total')
    if total is not None:
        h += '<tr>'
        h += _btd('TOTAL', 'font-weight:bold;')
        h += _btd(total, 'font-weight:bold;text-align:right;')
        h += '</tr>'
    h += '</table>'
    return h

def _build_page1_html(col_names, filas_cred, totales_main, secciones):
    """Build ONE HTML string for Page 1 (FORMATO NIÃ‘O) matching Excel layout."""
    STBL = 'border-collapse:collapse;width:100%;font-family:Calibri,sans-serif;font-size:9pt;'
    html = f'<table style="{STBL}">'
    # Title row
    html += f'<tr><td colspan="12" style="border:1px solid #999;text-align:center;font-weight:bold;font-size:13pt;padding:6px;">FORMATO NIÃ‘O - CRED (2024)</td></tr>'
    # CRED visits header
    html += '<tr>' + ''.join(_bth(c) for c in col_names) + '</tr>'
    # CRED visits data
    for fila in filas_cred:
        html += '<tr>' + _btd(fila.get('EDADES',''))
        for cn in col_names[1:]:
            html += _btd(fila.get(cn, 0), 'text-align:right;')
        html += '</tr>'
    # Total
    html += '<tr>' + _btd('TOTALES', 'font-weight:bold;')
    for cn in col_names[1:]:
        html += _btd(totales_main.get(cn, 0), 'font-weight:bold;text-align:right;')
    html += '</tr>'
    html += '</table>'

    # Each section as its own table
    for sec in secciones:
        html += f'<table style="{STBL}margin-top:4px;">'
        if sec.get('tipo') == 'side_by_side' and sec.get('izquierda') and sec.get('derecha'):
            html += _section_header(sec['titulo'], 2)
            # Nested table for left/right
            html += '<tr><td colspan="2" style="border:none;padding:0;">'
            html += '<table style="width:100%;"><tr>'
            html += '<td style="width:50%;vertical-align:top;padding-right:4px;border:none;">'
            html += _build_sec_table(sec['izquierda'])
            html += '</td>'
            html += '<td style="width:50%;vertical-align:top;padding-left:4px;border:none;">'
            html += _build_sec_table(sec['derecha'])
            html += '</td>'
            html += '</tr></table>'
            html += '</td></tr>'
        elif sec.get('tipo') == 'grid' and sec.get('grid'):
            g = sec['grid']
            html += _section_header(sec['titulo'], len(g['headers']))
            html += '<tr>' + ''.join(_bth(c) for c in g['headers']) + '</tr>'
            for row in g['rows']:
                html += '<tr>'
                for i, v in enumerate(row):
                    html += _btd(v, 'text-align:right;' if i > 0 else '')
                html += '</tr>'
            if g.get('totales'):
                html += '<tr>'
                for i, v in enumerate(g['totales']):
                    html += _btd(v, 'font-weight:bold;text-align:right;' if i > 0 else 'font-weight:bold;')
                html += '</tr>'
        else:
            # Flat section
            cols = sec.get('columnas', ['INDICADOR', 'TOTAL'])
            html += _section_header(sec['titulo'], len(cols))
            html += '<tr>' + ''.join(_bth(c) for c in cols) + '</tr>'
            for item in sec.get('filas', []):
                html += '<tr>'
                for i, c in enumerate(cols):
                    val = item.get(c)
                    if val is None: val = item.get(c.lower())
                    if val is None and i == 0: val = item.get('label', '')
                    if val is None and i == 1: val = item.get('valor', 0)
                    html += _btd(val, 'text-align:right;' if i > 0 else '')
                html += '</tr>'
            total = sec.get('total')
            if total is not None:
                html += '<tr>' + _btd('TOTAL', 'font-weight:bold;') + _btd(total, 'font-weight:bold;text-align:right;') + '</tr>'
        html += '</table>'
    return html


def _reporte_cred_2024(cur, esquema, anio, meses, filtros):
    """Reporte completo usando tablas pre-agregadas cred2024_* (solo aï¿½o 2024)."""
    where = _build_cred_where(2024, meses, filtros)
    qt = lambda t: f'es_ivan."{t}"'

    # Query ALL bigint columns from all 5 tables
    c24 = _qcred_cols(cur, {'C1':'cred2024'}, where)
    c1 = _qcred_cols(cur, {'C1':'cred2024_1'}, where)
    c2 = _qcred_cols(cur, {'C2':'cred2024_2'}, where)
    c3 = _qcred_cols(cur, {'C3':'cred2024_3'}, where)
    c4 = _qcred_cols(cur, {'C4':'cred2024_4'}, where)

    def v(d, k):
        return d.get(k, 0) or 0
    def sec(titulo, cols, flat=True):
        if flat:
            items = []
            total = 0
            for key, label, col in cols:
                val = v(key, col)
                items.append({'label': label, 'valor': val})
                total += val
            return {'titulo': titulo, 'columnas': ['INDICADOR', 'TOTAL'], 'filas': items, 'total': total}
        else:
            items = []
            for key, label, col in cols:
                val = v(key, col)
                items.append({'label': label, 'valor': val})
            return {'titulo': titulo, 'columnas': ['INDICADOR', 'TOTAL'], 'filas': items, 'total': sum(i['valor'] for i in items)}

    secciones = []

    def _flat_sb(dict_list, vfunc):
        return [(l, vfunc(d, c)) for d, l, c in dict_list]

    # ===== 1. I. ATENCIÃ“N DEL RECIÃ‰N NACIDO (side-by-side) =====
    atenc_inmed = [
        (c24, '1. AtenciÃ³n Inmediata RN Sano', 'C1_atenc_inmediata_rn_sano'),
        (c24, '2. AtenciÃ³n Inmediata RN Prematuro', 'C1_atenc_inmediata_rn_premat'),
        (c24, '3. AtenciÃ³n Inmediata BPN', 'C1_atencion_inmediata_bpn'),
        (c24, '4. Corte CordÃ³n Umbilical', 'C1_corte_cordon_umbilical_cnv'),
        (c24, '5. Lactancia 1ra Hora', 'C1_lactancia_1ra_hora_cnv'),
        (c24, '6. Contacto Piel a Piel', 'C1_contacto_piel_piel'),
        (c24, '7. Examen FÃ­sico RN Normal', 'C1_examen_fisico_rn_normal'),
        (c24, '8. Tamizaje Toma Muestra', 'C1_tamizaje_toma_muestra'),
        (c24, '9. Tamizaje Hipoacusia', 'C1_tamizaje_hipoacusia'),
        (c24, '10. Tamizaje Catarata CongÃ©nita', 'C1_tamizaje_catarata_congenita'),
        (c24, '11. Tamizaje CardiopatÃ­a', 'C1_tamizaje_cardiopatia'),
    ]
    aloj_conj = [
        (c4, '1. AtenciÃ³n Alojamiento Conjunto', 'C4_atencion_alojamiento_conjunto'),
        (c4, '2. AtenciÃ³n Inmediata NiÃ±o Sano', 'C4_atenc_inmed_nino_sano'),
        (c4, '3. EvaluaciÃ³n MÃ©dica RN', 'C4_evaluacion_medica_rn'),
        (c4, '4. BCG 12h', 'C4_bcg_12horas'),
        (c4, '5. BCG 12-24h', 'C4_bcg_12_24h'),
        (c4, '6. BCG 1-11m', 'C4_bcg_1_11m'),
        (c4, '7. HVB 12-24h', 'C4_hvb_12_24h'),
        (c4, '8. HVB 24h', 'C4_hvb_24h'),
    ]
    secciones.append(_side_by_side('I. ATENCIÃ“N DEL RECIÃ‰N NACIDO',
        _sb_subsecciones('A) AtenciÃ³n Inmediata', _flat_sb(atenc_inmed, v)),
        _sb_subsecciones('C) AtenciÃ³n de ReciÃ©n Nacido en Alojamiento Conjunto', _flat_sb(aloj_conj, v))))

    # ===== 2. B) CondiciÃ³n de Nacimiento / CONSEJERÃA (side-by-side) =====
    cond_nac = [
        (c4, '1. Extremadamente bajo peso', 'C4_peso_extremadamente_bajo'),
        (c4, '2. Muy bajo peso', 'C4_muy_bajo_peso'),
        (c4, '3. Bajo peso al nacer', 'C4_bajo_peso'),
        (c4, '4. MacrosÃ³mico', 'C4_macrosomico'),
        (c4, '5. Microcefalia', 'C4_microcefalia'),
        (c4, '6. Prematuro', 'C4_prematuro'),
        (c4, '7. Post-tÃ©rmino', 'C4_post_termino'),
    ]
    cons_brief = [
        (c4, '1. ConsejerÃ­a en atenciÃ³n temprana del desarrollo', 'C4_consej_atc_tempra_desarrollo'),
        (c4, '2. ConsejerÃ­a en inmunizaciones', 'C4_consej_inmunizaciones'),
        (c4, '3. ConsejerÃ­a de identificaciÃ³n de signos de alarma', 'C4_conse_signos_alarma'),
        (c4, '4. ConsejerÃ­a para la prevenciÃ³n de muerte sÃºbita del lactante', 'C4_conse_prev_muerte_subita_lactant'),
        (c4, '5. ConsejerÃ­a para la prevenciÃ³n de enfermedades prevalentes', 'C4_conse_prev_enf_prevalentes_ira_eda'),
        (c4, '6. ConsejerÃ­a en salud ocular', 'C4_conse_salud_ocular'),
        (c4, '7. ConsejerÃ­a en pautas de crianza', 'C4_conse_pautas_crianza'),
        (c4, '8. ConsejerÃ­a nutricional', 'C4_conse_aliment_saludable'),
        (c4, '9. ConsejerÃ­a en Lactancia Materna', 'C4_conse_lme'),
    ]
    secciones.append(_side_by_side('B) CondiciÃ³n de Nacimiento / CONSEJERÃA',
        _sb_subsecciones('B) CondiciÃ³n de Nacimiento', _flat_sb(cond_nac, v)),
        _sb_subsecciones('CONSEJERÃA', _flat_sb(cons_brief, v))))

    # ===== 3. B) Tamizaje Neonatal / E) AtenciÃ³n RN en VD (side-by-side) =====
    tamiz_diag = [
        (c4, '1. Hipotiroidismo CongÃ©nito', 'C4_hipotiroidismo_congenito_sin_bocio'),
        (c4, '2. Fenilcetonuria ClÃ¡sica', 'C4_fenilcetonuria_clasica'),
        (c4, '3. Hiperplasia Suprarrenal CongÃ©nita', 'C4_hiperplasia_suprarrenal_congenita'),
        (c4, '4. CardiopatÃ­a CongÃ©nita Tipo 1', 'C4_cardiopatia_congenita_tipo1'),
        (c4, '5. CardiopatÃ­a CongÃ©nita Tipo 2', 'C4_cardiopatia_congenita_tipo2'),
        (c4, '6. Fibrosis QuÃ­stica', 'C4_fibrosis_quistica_sin_otra_especificacion'),
        (c4, '7. Catarata CongÃ©nita', 'C4_catarata_congenita'),
        (c4, '8. Hipoacusia Conductiva', 'C4_hipoacusia_conductiva'),
    ]
    atenc_vd = [
        (c4, '1. VD Cuidado y EvaluaciÃ³n Neonatal', 'C4_vd_cuidado_y_evaluacion_neonatal'),
        (c4, '2. Anamnesis y Ex. FÃ­sico RN Normal', 'C4_anamnesis_y_ex_fisico_rn_normal'),
        (c1, '3. Visita Domiciliaria 1 BPN', 'C1_vis_domic_1_bpn'),
        (c1, '4. Visita Domiciliaria 2 BPN', 'C1_vis_domic_2_bpn'),
        (c1, '5. Visita Domiciliaria 3 BPN', 'C1_vis_domic_3_bpn'),
        (c1, '6. Visita Domiciliaria 6-23m', 'C1_vis_domic1_6_23m'),
        (c1, '7. Visita Domiciliaria 2 6-23m', 'C1_vis_domic2_6_23m'),
        (c1, '8. Visita Domiciliaria 3 6-23m', 'C1_vis_domic3_6_23m'),
        (c1, '9. Visita Domiciliaria 36-59m', 'C1_vis_domic1_36_59m'),
        (c1, '10. Visita Domiciliaria <1m', 'C1_vis_domic_1_men1a'),
        (c1, '11. Visita Domiciliaria 2 <1m', 'C1_vis_domic_2_men1a'),
    ]
    secciones.append(_side_by_side('B) Resultados del Tamizaje Neonatal / E) AtenciÃ³n RN en VD',
        _sb_subsecciones('B) Resultados del Tamizaje Neonatal', _flat_sb(tamiz_diag, v)),
        _sb_subsecciones('E) AtenciÃ³n de ReciÃ©n Nacido en la Visita Domiciliaria', _flat_sb(atenc_vd, v))))

    # ===== 4. IX. EVALUACIÃ“N DEL DESARROLLO (grid) =====
    dev_headers = ['Edad', 'Dx Lenguaje', 'Dx Motor', 'Dx Social', 'Dx CoordinaciÃ³n', 'Dx Cognitivo',
                   'Recup Lenguaje', 'Recup Motor', 'Recup Social', 'Recup CoordinaciÃ³n', 'Recup Cognitivo']
    dev_areas = ['len', 'mot', 'soc', 'coo', 'cog']
    area_map = {'len': 'Lenguaje', 'mot': 'Motor', 'soc': 'Social', 'coo': 'CoordinaciÃ³n', 'cog': 'Cognitivo'}
    dev_row_defs = []
    for edad_label, edad_suf in [('< 1 aÃ±o', 'm1a'), ('01 aÃ±o', '1a'), ('02 aÃ±os', '2a')]:
        mapped = {'label': edad_label}
        for area in dev_areas:
            mapped[f'Dx {area_map[area]}'] = v(c1, f'C1_retardo_desarrollo_{area}_{edad_suf}')
            mapped[f'Recup {area_map[area]}'] = v(c1, f'C1_rec_retardo_desarrollo_{area}_{edad_suf}')
        dev_row_defs.append(mapped)
    secciones.append(_excel_grid('IX. EVALUACIÃ“N DEL DESARROLLO', dev_headers, dev_row_defs))

    # ===== 5. II. SESIONES DE ATENCIÃ“N TEMPRANA / VI. LACTANCIA MATERNA (side-by-side) =====
    ses_headers = ['Sesiones', 'RN', '< 1 aÃ±o', '01 aÃ±o', '02 aÃ±os', '03 aÃ±os', 'Total']
    ses_grupos = [('RN', 'rn', c24, 'C1_sesion_est_temprana_rn_'),
        ('< 1 aÃ±o', 'menor_1a', c1, 'C1_sesion_est_temprana_menor_1a_'),
        ('01 aÃ±o', '1a', c1, 'C1_sesion_est_temprana_1a_'),
        ('02 aÃ±os', '2a', c1, 'C1_sesion_est_temprana_2a_'),
        ('03 aÃ±os', '3a', c1, 'C1_sesion_est_temprana_3a_')]
    ses_row_defs = []
    for si in range(1, 6):
        row = {'label': f'SesiÃ³n {si}', 'Total': 0}
        for label, age, d, pref in ses_grupos:
            val = v(d, f'{pref}{si}')
            row[label] = val
            row['Total'] += val
        ses_row_defs.append(row)
    izq_sesiones = _excel_grid('II. SESIONES DE ATENCIÃ“N TEMPRANA', ses_headers, ses_row_defs)
    der_lactancia = _sb_subsecciones('VI. LACTANCIA MATERNA', _flat_sb([
        (c24, 'LME 1ra Hora', 'C1_lme_1ra_hora'),
        (c24, 'SuspensiÃ³n LME 6m', 'C1_suspencion_lme_6m'),
        (c4, 'Lactancia 1ra Hora CNV', 'C4_lactancia_1ra_hora_cnv'),
        (c4, 'Contacto Piel a Piel', 'C4_contacto_piel_piel'),
        (c4, 'SuspensiÃ³n LME 6m', 'C4_suspencion_lme_6m'),
    ], v))
    secciones.append(_side_by_side('II. SESIONES DE ATENCIÃ“N TEMPRANA / VI. LACTANCIA MATERNA', izq_sesiones, der_lactancia))

    # ===== 6. X. PLAN DE ATENCIÃ“N INTEGRAL =====
    secciones.append({'titulo': 'X. PLAN DE ATENCIÃ“N INTEGRAL', **_cred_flat({**c24, **c4}, [
        (c24, 'Plan AIS Inicio RN', 'C1_plan_ais_ini_rn'),
        (c24, 'Plan AIS TÃ©rmino RN', 'C1_plan_ais_ta_rn'),
        (c4, 'Plan AIS Inicio 1m', 'C4_plan_ais_ini_1m'),
        (c4, 'Plan AIS TÃ©rmino 7m', 'C4_plan_ais_termino_7m'),
        (c4, 'Plan AIS Inicio 1a', 'C4_plan_ais_ini_1a'),
        (c4, 'Plan AIS TÃ©rmino 1a', 'C4_plan_ais_termino_1a'),
        (c4, 'Plan AIS Inicio 2a', 'C4_plan_ais_ini_2a'),
        (c4, 'Plan AIS TÃ©rmino 2a', 'C4_plan_ais_termino_2a'),
        (c4, 'Plan AIS Inicio 3a', 'C4_plan_ais_ini_3a'),
        (c4, 'Plan AIS TÃ©rmino 3a', 'C4_plan_ais_termino_3a'),
        (c4, 'Plan AIS Inicio 4a', 'C4_plan_ais_ini_4a'),
        (c4, 'Plan AIS TÃ©rmino 4a', 'C4_plan_ais_termino_4a'),
        (c4, 'Plan AIS Inicio 5-11a', 'C4_plan_ais_ini_5a'),
        (c4, 'Plan AIS TÃ©rmino 5-11a', 'C4_plan_ais_ta_5a'),
    ])})

    # ===== 7. IV. CONSEJERÃA EN LA ATENCIÃ“N DEL NIÃ‘O(A) (grid) =====
    cons_headers = ['Tipos / Edades', 'Total', 'RN', '<1 aÃ±o', '01 aÃ±o', '02 aÃ±os', '03 aÃ±os', '04 aÃ±os',
                    '5 aÃ±os', '6 aÃ±os', '7 aÃ±os', '8 aÃ±os', '9 aÃ±os', '10 aÃ±os', '11 aÃ±os']
    cons_age_order = ['rn', 'men_1a', '1a', '2a', '3a', '4a', '5a', '6a', '7a', '8a', '9a', '10a', '11a']
    cons_types = [
        'ConsejerÃ­a en atenciÃ³n temprana del desarrollo',
        'ConsejerÃ­a en inmunizaciones',
        'ConsejerÃ­a de identificaciÃ³n de signos de alarma',
        'ConsejerÃ­a para la prevenciÃ³n de muerte sÃºbita del lactante',
        'ConsejerÃ­a para la prevenciÃ³n de enfermedades prevalentes (EDA, IRA, entre otras)',
        'ConsejerÃ­a en salud ocular',
        'ConsejerÃ­a en pautas de crianza, buen trato, comunicaciÃ³n y cuidados adecuados',
        'ConsejerÃ­a nutricional: AlimentaciÃ³n saludable',
        'ConsejerÃ­a en Lactancia Materna Exclusiva hasta los 06 meses',
    ]
    cons_prefixes = {
        'ConsejerÃ­a en atenciÃ³n temprana del desarrollo': 'C4_consej_atc_tempra_desarrollo',
        'ConsejerÃ­a en inmunizaciones': 'C4_consej_inmunizaciones',
        'ConsejerÃ­a de identificaciÃ³n de signos de alarma': 'C4_conse_signos_alarma',
        'ConsejerÃ­a para la prevenciÃ³n de muerte sÃºbita del lactante': 'C4_conse_prev_muerte_subita_lactant',
        'ConsejerÃ­a para la prevenciÃ³n de enfermedades prevalentes (EDA, IRA, entre otras)': 'C4_conse_prev_enf_prevalentes_ira_eda',
        'ConsejerÃ­a en salud ocular': 'C4_conse_salud_ocular',
        'ConsejerÃ­a en pautas de crianza, buen trato, comunicaciÃ³n y cuidados adecuados': 'C4_conse_pautas_crianza',
        'ConsejerÃ­a nutricional: AlimentaciÃ³n saludable': 'C4_conse_aliment_saludable',
        'ConsejerÃ­a en Lactancia Materna Exclusiva hasta los 06 meses': 'C4_conse_lme',
    }
    cons_row_defs = []
    for ct in cons_types:
        pref = cons_prefixes[ct]
        row = {'label': ct, 'Total': 0}
        age_vals = []
        for i, age in enumerate(cons_age_order):
            val = v(c4, f'{pref}_{age}')
            age_vals.append(val)
            row['Total'] += val
        for i, h in enumerate(cons_headers[2:]):
            row[h] = age_vals[i]
        cons_row_defs.append(row)
    secciones.append(_excel_grid('IV. CONSEJERÃA EN LA ATENCIÃ“N DEL NIÃ‘O(A)', cons_headers, cons_row_defs))

    # ===== 8. V. EVALUACIÃ“N NUTRICIONAL (grid) =====
    nut_headers = ['Indicador', '< 1 aÃ±o', '01 aÃ±o', '02 aÃ±os', '03 aÃ±os', '04 aÃ±os', '5-11 aÃ±os', 'Total']
    nut_age_suf = ['men1a', '1a', '2a', '3a', '4a', '5_11a']
    nut_age_h = ['< 1 aÃ±o', '01 aÃ±o', '02 aÃ±os', '03 aÃ±os', '04 aÃ±os', '5-11 aÃ±os']
    nut_mapped_rows = []
    for nt, pref in [('DesnutriciÃ³n Global', 'C1_desnutric_global'), ('DesnutriciÃ³n Aguda', 'C1_desnutric_aguda'),
        ('DesnutriciÃ³n CrÃ³nica', 'C1_desnutric_cronica'), ('DesnutriciÃ³n Severa', 'C1_desnutric_severa'),
        ('Obesidad', 'C1_obeso'), ('Sobrepeso', 'C1_sobre_peso')]:
        vals = [v(c1, f'{pref}_{s}') for s in nut_age_suf]
        if not any(vals):
            continue
        row = {'label': nt}
        for i, s in enumerate(nut_age_suf):
            row[nut_age_h[i]] = vals[i]
        row['Total'] = sum(vals)
        nut_mapped_rows.append(row)
    for label, pref, suffixes in [('Gan. Inadec. Peso', 'C1_g_inadecuada_pe', ['men1a']),
        ('Gan. Inadec. Talla', 'C1_g_inadecuada_talla', ['men1a']),
        ('Talla Alta', 'C1_te_alto', ['5_11a'])]:
        row = {'label': label, 'Total': 0}
        for i, s in enumerate(nut_age_suf):
            val = v(c1, f'{pref}_{s}') if s in suffixes else 0
            row[nut_age_h[i]] = val
            row['Total'] += val
        nut_mapped_rows.append(row)
    secciones.append(_excel_grid('V. EVALUACIÃ“N NUTRICIONAL', nut_headers, nut_mapped_rows))

    # ===== 9. VIII. PARASITOSIS / EXÃMENES DE LABORATORIO =====
    lab_items = [
        (c1, 'Test Graham <1a', 'C1_test_graham_1a'),
        (c1, 'Test Graham 1a', 'C1_test_graham_men1a'),
        (c1, 'Test Graham 2a', 'C1_test_graham_2a'),
        (c1, 'Test Graham 3a', 'C1_test_graham_3a'),
        (c1, 'Test Graham 4a', 'C1_test_graham_4a'),
        (c1, 'Test Graham 5-11a', 'C1_test_graham_5_11a'),
        (c1, 'Test Graham Positivo <1a', 'C1_test_graham_posit_1a'),
        (c1, 'Test Graham Positivo 2a', 'C1_test_graham_posit_2a'),
        (c1, 'Test Graham Positivo 3a', 'C1_test_graham_posit_3a'),
        (c1, 'Test Graham Positivo 4a', 'C1_test_graham_posit_4a'),
        (c1, 'Test Graham Positivo 5-11a', 'C1_test_graham_posit_5_11a'),
        (c1, 'Test Graham Tratado <1a', 'C1_test_graham_tto_1a'),
        (c1, 'Test Graham Tratado 2a', 'C1_test_graham_tto_2a'),
        (c1, 'Test Graham Tratado 3a', 'C1_test_graham_tto_3a'),
        (c1, 'Test Graham Tratado 4a', 'C1_test_graham_tto_4a'),
        (c1, 'Test Graham Tratado 5-11a', 'C1_test_graham_tto_5_11a'),
        (c1, 'Seriado Heces <1a', 'C1_seriado_heces_1a'),
        (c1, 'Seriado Heces 2a', 'C1_seriado_heces_2a'),
        (c1, 'Seriado Heces 3a', 'C1_seriado_heces_3a'),
        (c1, 'Seriado Heces 4a', 'C1_seriado_heces_4a'),
        (c1, 'Seriado Heces 5-11a', 'C1_seriado_heces_5_11a'),
        (c1, 'Seriado Heces Positivo <1a', 'C1_seriado_heces_positivo_1a'),
        (c1, 'Seriado Heces Positivo 2a', 'C1_seriado_heces_positivo_2a'),
        (c1, 'Seriado Heces Positivo 3a', 'C1_seriado_heces_positivo_3a'),
        (c1, 'Seriado Heces Positivo 4a', 'C1_seriado_heces_positivo_4a'),
        (c1, 'Seriado Heces Positivo 5-11a', 'C1_seriado_heces_positivo_5_11a'),
        (c1, 'SH Positivo Tratado <1a', 'C1_sh_positivo_tto_1a'),
        (c1, 'SH Positivo Tratado 2a', 'C1_sh_positivo_tto_2a'),
        (c1, 'SH Positivo Tratado 3a', 'C1_sh_positivo_tto_3a'),
        (c1, 'SH Positivo Tratado 4a', 'C1_sh_positivo_tto_4a'),
        (c1, 'SH Positivo Tratado 5-11a', 'C1_sh_positivo_tto_5_11a'),
    ]
    secciones.append({'titulo': 'VIII. PARASITOSIS / EXÃMENES DE LABORATORIO', **_cred_flat(c1, lab_items)})

    # ===== 10. IX. ADMINISTRACIÃ“N DE PROFILAXIS ANTIPARASITARIA (grid) =====
    para_headers = ['Dosis', '< 1 aÃ±o', '02 aÃ±os', '03 aÃ±os', '04 aÃ±os', '5-11 aÃ±os', 'Total']
    para_ages = {'< 1 aÃ±o': '1a', '02 aÃ±os': '2a', '03 aÃ±os': '3a', '04 aÃ±os': '4a', '5-11 aÃ±os': '5_11a'}
    para_row_defs = []
    for dose_num, dose_label in [(1, '1ra Dosis'), (2, '2da Dosis')]:
        row = {'label': dose_label, 'Total': 0}
        for header, suf in para_ages.items():
            val = v(c1, f'C1_antiparasitaria_{dose_num}_{suf}')
            row[header] = val
            row['Total'] += val
        para_row_defs.append(row)
    secciones.append(_excel_grid('IX. ADMINISTRACIÃ“N DE PROFILAXIS ANTIPARASITARIA', para_headers, para_row_defs))

    # ===== 11. XII. VISITA DOMICILIARIA (grid) =====
    vd_headers = ['Tipo', '< 1 aÃ±o', '1-5 aÃ±os', 'Total']
    vd_row_defs = []
    for label, col in [('Visita Domiciliaria 1 BPN', 'C1_vis_domic_1_bpn'),
        ('Visita Domiciliaria 2 BPN', 'C1_vis_domic_2_bpn'),
        ('Visita Domiciliaria 3 BPN', 'C1_vis_domic_3_bpn'),
        ('Visita Domiciliaria 6-23m', 'C1_vis_domic1_6_23m'),
        ('Visita Domiciliaria 2 6-23m', 'C1_vis_domic2_6_23m'),
        ('Visita Domiciliaria 3 6-23m', 'C1_vis_domic3_6_23m'),
        ('Visita Domiciliaria 36-59m', 'C1_vis_domic1_36_59m'),
        ('Visita Domiciliaria <1m', 'C1_vis_domic_1_men1a'),
        ('Visita Domiciliaria 2 <1m', 'C1_vis_domic_2_men1a'),
        ('VD Cuidado y EvaluaciÃ³n Neonatal', 'C4_vd_cuidado_y_evaluacion_neonatal'),
        ('Anamnesis y Ex. FÃ­sico RN Normal', 'C4_anamnesis_y_ex_fisico_rn_normal'),
    ]:
        d = c1 if col.startswith('C1_') else c4
        val = v(d, col)
        vd_row_defs.append({'label': label, '< 1 aÃ±o': val, '1-5 aÃ±os': 0, 'Total': val})
    secciones.append(_excel_grid('XII. VISITA DOMICILIARIA', vd_headers, vd_row_defs))

    # ===== 12. XV. SALUD MENTAL (Tamizajes) =====
    secciones.append({'titulo': 'XV. SALUD MENTAL', **_cred_flat(c3, [
        (c3, 'Tamizaje Neurodesarrollo 2a', 'C3_tamizaje_nd_2a'),
        (c3, 'Tamizaje Trastorno Mental 6-9a', 'C3_tamizaje_tm_6_9a'),
        (c3, 'Tamizaje Trastorno Mental 10-11a', 'C3_tamizaje_tm_10_11a'),
    ])})

    # ===== 13. TAMIZAJES =====
    secciones.append({'titulo': 'TAMIZAJES', **_cred_flat(c3, [
        (c3, 'Tamizaje Violencia 1-2a', 'C3_tamizaje_viol_1_2a'),
        (c3, 'Tamizaje Violencia 3-5a', 'C3_tamizaje_viol_3_5a'),
        (c3, 'Tamizaje Violencia 6-9a', 'C3_tamizaje_viol_6_9a'),
        (c3, 'Tamizaje Violencia 10-11a', 'C3_tamizaje_viol_10_11a'),
        (c3, 'Tamizaje Alcohol/Drogas 6-9a', 'C3_tamizaje_ad_6_9a'),
        (c3, 'Tamizaje Alcohol/Drogas 10-11a', 'C3_tamizaje_ad_10_11a'),
        (c3, 'Tamizaje Trastorno Depresivo 10-11a', 'C3_tamizaje_td_10_11a'),
    ])})

    # ===== 14. TAMIZAJES POSITIVOS =====
    secciones.append({'titulo': 'TAMIZAJES POSITIVOS', **_cred_flat(c3, [
        (c3, 'Tamizaje Violencia POSITIVO 1-2a', 'C3_tamizaje_viol_posit_1_2a'),
        (c3, 'Tamizaje Violencia POSITIVO 3-5a', 'C3_tamizaje_viol_posit_3_5a'),
        (c3, 'Tamizaje Violencia POSITIVO 6-9a', 'C3_tamizaje_viol_posit_6_9a'),
        (c3, 'Tamizaje Violencia POSITIVO 10-11a', 'C3_tamizaje_viol_posit_10_11a'),
        (c3, 'Tamizaje Alcohol POSITIVO 10-11a', 'C3_tamizaje_ad_alcohol_posit_10_11a'),
        (c3, 'Tamizaje Tabaco POSITIVO 10-11a', 'C3_tamizaje_ad_tabaco_posit_10_11a'),
        (c3, 'Tamizaje Drogas POSITIVO 10-11a', 'C3_tamizaje_ad_drogas_posit_10_11a'),
        (c3, 'Tamizaje TD POSITIVO 10-11a', 'C3_tamizaje_td_posit_10_11a'),
    ])})

    # ===== 15. XV. RETINOPATÃA DE LA PREMATURIDAD - ROP =====
    secciones.append({'titulo': 'XV. RETINOPATÃA DE LA PREMATURIDAD - ROP', **_cred_flat(c3, [
        (c3, 'Tamizaje RN Factores Riesgo Sano', 'C3_o_tamrn_fr_s_0_29d'),
        (c3, 'Tamizaje RN Factores Riesgo Normal', 'C3_o_tamrn_fr_n_0_29d'),
        (c3, 'Tamizaje RN Factores Riesgo Referido', 'C3_o_tamrn_fr_r_0_29d'),
        (c3, 'Dx RetinopatÃ­a Prematuros RN', 'C3_o_dx_retinoprema_c_0_29d'),
        (c3, 'Dx RetinopatÃ­a Prematuros 6m', 'C3_o_dx_retinoprema_c_6m'),
        (c3, 'Dx RetinopatÃ­a Prematuros <3a', 'C3_o_dx_retinoprema_c_1_3a'),
        (c3, 'Tto LÃ¡ser RetinopatÃ­a', 'C3_o_tto_retinoprema_ct_l_0_29d'),
        (c3, 'Tto AntiangiogÃ©nico RetinopatÃ­a', 'C3_o_tto_retinoprema_ct_i_0_29d'),
        (c3, 'Tto LÃ¡ser+AntiangiogÃ©nico', 'C3_o_tto_retinoprema_ct_lm_0_29d'),
    ])})

    # ===== 16. ATENCIÃ“N DE SALUD OCULAR / AGUDEZA VISUAL =====
    secciones.append({'titulo': 'ATENCIÃ“N DE SALUD OCULAR - AGUDEZA VISUAL', **_cred_flat(c3, [
        (c3, 'DeterminaciÃ³n Agudeza Visual 3-4a', 'C3_o_determ_agudeza_visual_3_4a'),
        (c3, 'DeterminaciÃ³n Agudeza Visual 5-7a', 'C3_o_determ_agudeza_visual_5_7a'),
        (c3, 'DeterminaciÃ³n Agudeza Visual 8-11a', 'C3_o_determ_agudeza_visual_8_11a'),
        (c3, 'EvaluaciÃ³n Agudeza Visual', 'C3_o_determ_agudeza_visual_eva_total'),
        (c3, 'Referencia Agudeza Visual', 'C3_o_determ_agudeza_visual_ref_total'),
        (c3, 'Examen Ojos/VisiÃ³n Normal', 'C3_o_ex_ojo_vis_n_0_5a_total'),
        (c3, 'Examen Ojos/VisiÃ³n Anormal', 'C3_o_ex_ojo_vis_a_0_5a_total'),
        (c3, 'Examen Ojos/VisiÃ³n Ref.', 'C3_o_ex_ojo_vis_rf_0_5a_total'),
    ])})

    # ===== 17. ERRORES DE REFRACCIÃ“N =====
    secciones.append({'titulo': 'ERRORES DE REFRACCIÃ“N', **_cred_flat(c3, [
        (c3, 'Dx HipermetropÃ­a 3-4a', 'C3_o_dx_errr_hip_3_4a'),
        (c3, 'Dx MiopÃ­a 3-4a', 'C3_o_dx_errr_mio_3_4a'),
        (c3, 'Dx Astigmatismo 3-4a', 'C3_o_dx_errr_ast_3_4a'),
        (c3, 'Dx AnisometropÃ­a 3-4a', 'C3_o_dx_errr_ani_3_4a'),
        (c3, 'Tto/ProvisiÃ³n Anteojos 3-4a', 'C3_o_tto_prov_anteo_3_4a'),
        (c3, 'Dx HipermetropÃ­a 5-7a', 'C3_o_dx_errr_hip_5_7a'),
        (c3, 'Dx MiopÃ­a 5-7a', 'C3_o_dx_errr_mio_5_7a'),
        (c3, 'Dx Astigmatismo 5-7a', 'C3_o_dx_errr_ast_5_7a'),
        (c3, 'Dx AnisometropÃ­a 5-7a', 'C3_o_dx_errr_ani_5_7a'),
        (c3, 'Tto/ProvisiÃ³n Anteojos 5-7a', 'C3_o_tto_prov_anteo_5_7a'),
        (c3, 'Dx HipermetropÃ­a 8-11a', 'C3_o_dx_errr_hip_8_11a'),
        (c3, 'Dx MiopÃ­a 8-11a', 'C3_o_dx_errr_mio_8_11a'),
        (c3, 'Dx Astigmatismo 8-11a', 'C3_o_dx_errr_ast_8_11a'),
        (c3, 'Dx AnisometropÃ­a 8-11a', 'C3_o_dx_errr_ani_8_11a'),
        (c3, 'Tto/ProvisiÃ³n Anteojos 8-11a', 'C3_o_tto_prov_anteo_8_11a'),
    ])})

    # ===== 18. ATENCIÃ“N EN SALUD BUCAL =====
    secciones.append({'titulo': 'ATENCIÃ“N EN SALUD BUCAL', **_cred_flat(c3, [
        (c3, 'InstrucciÃ³n Higiene Oral', 'C3_b_iho_i_0_28d'),
        (c3, 'Cepillado Dental 5-11a', 'C3_b_iho_5_11a'),
        (c3, 'AsesorÃ­a Nutricional Control Enf. Dentales', 'C3_b_anced_i_0_28d'),
        (c3, 'AplicaciÃ³n FlÃºor Barniz', 'C3_b_abf_i_0_28d'),
        (c3, 'Profilaxis Dental', 'C3_b_pd_i_0_28d'),
        (c3, 'AplicaciÃ³n Sellantes', 'C3_b_aseln_ct_2a'),
    ])})

    # ===== 19. SEGUIMIENTO =====
    seg_items = [
        (c1, 'Seguimiento Control CRED', 'C1_seguim_control_cred_1a'),
        (c1, 'Seguim. Prob. Nutricionales RN', 'C1_seguim_problemas_nutric_rn'),
        (c1, 'Seguim. Prob. Nutricionales <1a', 'C1_seguim_problemas_nutric_men_1a'),
        (c1, 'Seguim. Prob. Nutricionales 1a', 'C1_seguim_problemas_nutric_1a'),
        (c1, 'Seguim. Prob. Nutricionales 2a', 'C1_seguim_problemas_nutric_2a'),
        (c1, 'Seguim. Prob. Nutricionales 3a', 'C1_seguim_problemas_nutric_3a'),
        (c1, 'Seguim. Prob. Nutricionales 4a', 'C1_seguim_problemas_nutric_4a'),
        (c1, 'Seguim. Prob. Nutricionales 5-11a', 'C1_seguim_problemas_nutric_5_11a'),
        (c1, 'Seguim. Prob. Desarrollo RN', 'C1_seguim_problemas_desarr_rn'),
        (c1, 'Seguim. Prob. Desarrollo <1a', 'C1_seguim_problemas_desarr_men_1a'),
        (c1, 'Seguim. Prob. Desarrollo 1a', 'C1_seguim_problemas_desarr_1a'),
        (c1, 'Seguim. Prob. Desarrollo 2a', 'C1_seguim_problemas_desarr_2a'),
        (c1, 'Seguim. Prob. Desarrollo 3a', 'C1_seguim_problemas_desarr_3a'),
        (c1, 'Seguim. Prob. Desarrollo 4a', 'C1_seguim_problemas_desarr_4a'),
        (c1, 'Seguim. Prob. Desarrollo 5-11a', 'C1_seguim_problemas_desarr_5_11a'),
    ]
    secciones.append({'titulo': 'SEGUIMIENTO - VISITA DOMICILIARIA', **_cred_flat({**c1, **c24}, seg_items)})

    # ---- PAGE 1: FORMATO NIÃ‘O ----
    # CRED visits main table from cred2024 columns
    cred_row_names = [
        ('Reciï¿½n Nacido Sano 3-6d', ['C1_cred1_rn_3_6d','C1_cred2_rn_7_13d','C1_cred3_rn_14_21d','C1_cred4_rn_22_a_mas_dias']),
        ('< 1 aï¿½o', ['C1_cred1_29_59d_men1a','C1_cred2_60_89d_men1a','C1_cred3_90_119d_men1a','C1_cred4_120_149d_men1a','C1_cred5_180_209d_men1a','C1_cred6_210_239d_men1a','C1_cred7_270_299d_men1a','C1_cred8_men1a','C1_cred9_men1a','C1_cred10_men1a','C1_cred11_men1a']),
        ('1 aï¿½o', ['C1_cred1_360_389d_1a','C1_cred2_450_479d_1a','C1_cred3_540_569d_1a','C1_cred4_630_659d_1a','C1_cred5_1a','C1_cred6_1a']),
        ('2 aï¿½os', ['C1_cred1_2a','C1_cred2_2a','C1_cred3_2a','C1_cred4_2a']),
        ('3 aï¿½os', ['C1_cred1_3a','C1_cred2_3a','C1_cred3_3a','C1_cred4_3a']),
        ('4 aï¿½os', ['C1_cred1_4a','C1_cred2_4a','C1_cred3_4a','C1_cred4_4a']),
        ('5-9 aï¿½os', ['C1_cred1_5a','C1_cred1_6a','C1_cred1_7a','C1_cred1_8a','C1_cred1_9a']),
        ('10-11 aï¿½os', ['C1_cred1_10a','C1_cred1_11a']),
    ]
    col_names = ['EDADES','1ER.CONTROL','2DO.CONTROL','3ER.CONTROL','4TO.CONTROL',
                 '5TO.CONTROL','6TO.CONTROL','7MO.CONTROL','8VO.CONTROL',
                 'TOTAL ATENCIONES','TOTAL NIï¿½OS ATENDIDOS']
    totales_main = {cn:0 for cn in col_names[1:]}
    filas_cred = []
    for grupo, cols in cred_row_names:
        total = sum(v({**c24, **c1}, col) for col in cols)
        fila = {'EDADES': grupo}
        # Distribute total across columns (we don't have per-control breakdown in cred2024)
        fila['1ER.CONTROL'] = total
        for cn in col_names[2:]:
            fila[cn] = 0
        fila['TOTAL ATENCIONES'] = total
        fila['TOTAL NIï¿½OS ATENDIDOS'] = total
        for cn in col_names[1:]:
            totales_main[cn] += fila.get(cn, 0)
        filas_cred.append(fila)

    data_composite = {}
    for d in [c24, c1, c2, c3, c4]:
        data_composite.update({k.replace('C1_','').replace('C2_','').replace('C3_','').replace('C4_',''): v for k, v in d.items()})
    tabla_html = build_page1_html(col_names, filas_cred, totales_main, secciones,
                                  c24, c1, c2, c3, c4,
                                  data_composite=data_composite,
                                  filtros=filtros)
    pages = [{
        'id': 'formato_nino', 'titulo': 'FORMATO NIï¿½O - CRED',
        'tabla_html': tabla_html,
        # Keep original data for Excel export
        'columnas': col_names, 'filas': filas_cred, 'totales': totales_main,
        'secciones': secciones
    }]

    # ---- PAGE 2: SUPLEMENTACION ----
    sup_secciones = []

    # 1. Suplementaciï¿½n <6m (RN BPN/Prematuro + 4-5m sano)
    sup_secciones.append(sec('1. Sup. Preventiva <6m', [
        (c24, 'RN Bajo Peso 1ra', 'C1_ta_suplem_bpn'),
        (c24, 'RN Prematuro', 'C1_ta_suplem_bpn'),
        (c24, '4m Sano', 'C1_suplem_4m_sano'),
        (c24, '5m Sano', 'C1_suplem_5m_sano'),
        (c24, 'TA 5-6m Sano', 'C1_ta_suplem_5_6m_sano'),
    ]))

    # 2-3. Multimicronutriente 6-59m + Sulfato Ferroso
    sup_edades = [('6-11m', '6_11m'), ('1a', '1a'), ('2a', '2a'), ('3a', '3a'), ('4a', '4a'), ('5-11a', '5_11a')]
    for grupo, suf in sup_edades:
        sup_secciones.append(sec(f'Multimicronutrientes {grupo}', [
            (c24, f'1ra Entrega', f'C1_suplem_1ra_{suf}'),
            (c24, f'2da Entrega', f'C1_suplem_2da_{suf}'),
            (c24, f'3ra Entrega', f'C1_suplem_3ra_{suf}'),
            (c24, f'4ta Entrega', f'C1_suplem_4ta_{suf}'),
            (c24, f'5ta Entrega', f'C1_suplem_5ta_{suf}'),
            (c24, f'6ta Entrega', f'C1_suplem_6ta_{suf}'),
            (c24, f'TA', f'C1_ta_suplem_{suf}'),
        ]))

    # Vitamina A
    sup_secciones.append(sec('4. Vitamina A', [
        (c24, 'VA1 6-11m', 'C1_va1_6_11m'),
        (c24, 'VA1 1a', 'C1_va1_1a'),
        (c24, 'VA2 1a', 'C1_va2_1a'),
        (c24, 'VA1 2a', 'C1_va1_2a'),
        (c24, 'VA2 2a', 'C1_va2_2a'),
        (c24, 'VA1 3a', 'C1_va1_3a'),
        (c24, 'VA2 3a', 'C1_va2_3a'),
        (c24, 'VA1 4a', 'C1_va1_4a'),
        (c24, 'VA2 4a', 'C1_va2_4a'),
    ]))

    # Suplementaciï¿½n Gestantes, Puï¿½rperas, MEF
    sup_secciones.append(sec('9. Sup. Hierro MEF/Gestantes/Puerperas', [
        (c24, 'Suplem Gestante 1', 'C1_suplem_gest1'),
        (c24, 'Suplem Gestante 2', 'C1_suplem_gest2'),
        (c24, 'Suplem Gestante 3', 'C1_suplem_gest3'),
        (c24, 'Suplem Gestante 4', 'C1_suplem_gest4'),
        (c24, 'Suplem Gestante 5', 'C1_suplem_gest5'),
        (c24, 'Suplem Gestante 6', 'C1_suplem_gest6'),
        (c24, 'Suplem Gestante TA', 'C1_suplem_gest_ta'),
        (c24, 'Suplem Puï¿½rpera 1', 'C1_suplem_puer1'),
        (c24, 'Suplem Puï¿½rpera 2', 'C1_suplem_puer2'),
        (c24, 'Suplem Puï¿½rpera 3', 'C1_suplem_puer3'),
        (c24, 'Suplem Puï¿½rpera 4', 'C1_suplem_puer4'),
        (c24, 'Suplem Puï¿½rpera 5', 'C1_suplem_puer5'),
        (c24, 'Suplem Puï¿½rpera 6', 'C1_suplem_puer6'),
        (c24, 'Suplem Puï¿½rpera 7', 'C1_suplem_puer7'),
        (c24, 'Suplem Puï¿½rpera TA', 'C1_suple_puer_ta'),
        (c24, 'Suplem MEF 1', 'C1_suplem_mef1'),
        (c24, 'Suplem MEF 2', 'C1_suplem_mef2'),
        (c24, 'Suplem MEF 3', 'C1_suplem_mef3'),
        (c24, 'Suplem MEF TA', 'C1_suplem_mef_ta'),
        (c24, 'Suplem Adol. 12-17 1', 'C1_suplem1_12_17'),
        (c24, 'Suplem Adol. 12-17 2', 'C1_suplem2_12_17'),
        (c24, 'Suplem Adol. 12-17 3', 'C1_suplem3_12_17'),
        (c24, 'Suplem Adol. 12-17 TA', 'C1_suplem4_12_17ta'),
    ]))

    # 6. Dosaje HB
    sup_secciones.append(sec('6. DOSAJE DE HEMOGLOBINA', [
        (c2, '1er Dosaje BPN', 'C2_primer_dosaje_hb_bpn'),
        (c2, '2do Dosaje BPN', 'C2_segundo_dosaje_hb_bpn'),
        (c2, 'HB 6-11m 1er', 'C2_hb_6_11m_primer'),
        (c2, 'HB 6-11m 2do', 'C2_hb_6_11m_segundo'),
        (c2, 'HB 12-23m 1er', 'C2_hb_12_23m_primer'),
        (c2, 'HB 12-23m 2do', 'C2_hb_12_23m_segundo'),
        (c2, 'HB 12-23m 3er', 'C2_hb_12_23m_tercer'),
        (c2, 'HB 24-35m 1er', 'C2_hb_24_35m_primer'),
        (c2, 'HB 24-35m 2do', 'C2_hb_24_35m_segundo'),
        (c2, 'HB 36-59m 1er', 'C2_hb_36_59m_primer'),
        (c2, 'HB 36-59m 2do', 'C2_hb_36_59m_segundo'),
        (c2, 'HB 5-11a', 'C2_hb_5_11a'),
        (c2, 'HB Adolescente 1er', 'C2_hb_adolescente_primer'),
        (c2, 'HB Adolescente 2do', 'C2_hb_adolescente_segundo'),
        (c2, 'HB Gestante 1er', 'C2_hb_gestante_primer'),
        (c2, 'HB Gestante 2do', 'C2_hb_gestante_segundo'),
        (c2, 'HB Gestante 3er', 'C2_hb_gestante_tercero'),
        (c2, 'HB MEF', 'C2_hb_mef'),
        (c2, 'HB Puï¿½rpera', 'C2_hb_puerpera'),
    ]))

    # 7. Consulta Nutricional
    con_items = [
        (c4, 'Consulta Nutricional BPN', 'C4_consulta_nutric_bpn'),
        (c4, 'Consulta Nutricional 4-5m', 'C4_consulta_nutric1_4_5m'),
        (c4, 'Consulta Nutricional 6-11m', 'C4_consulta_nutric_1_6_11m'),
        (c4, 'Consulta Nutricional 1a', 'C4_consulta_nutric_1_1a'),
        (c4, 'Consulta Nutricional 2a', 'C4_consulta_nutric_1_2a'),
        (c4, 'Consulta Nutricional 3a', 'C4_consulta_nutric_1_3a'),
        (c4, 'Consulta Nutricional 4a', 'C4_consulta_nutric_1_4a'),
        (c4, 'Consulta Nutricional 5-11a', 'C4_consulta_nutric_1_5_11a'),
        (c24, 'Cons. Nutr. Gestante 1', 'C1_cons_nutric1_gest'),
        (c24, 'Cons. Nutr. Gestante 2', 'C1_cons_nutric2_gest'),
        (c24, 'Cons. Nutr. Gestante 3', 'C1_cons_nutric3_gest'),
        (c24, 'Cons. Nutr. Gestante 4', 'C1_cons_nutric4_gest'),
        (c24, 'Cons. Nutr. Gestante 5', 'C1_cons_nutric5_gest'),
        (c24, 'Cons. Nutr. Gestante 6', 'C1_cons_nutric6_gest'),
        (c24, 'Cons. Nutr. Puï¿½rpera 1', 'C1_consulta_nutric1_gest'),
        (c24, 'Cons. Nutr. MEF 1', 'C1_cons_mef1'),
        (c24, 'Cons. Nutr. MEF 2', 'C1_cons_mef2'),
        (c24, 'Cons. Nutr. Adolescente 1', 'C1_cons_nutri1_12_17'),
        (c24, 'Cons. Nutr. Adolescente 2', 'C1_cons_nutri2_12_17'),
        (c24, 'Cons. Nutr. Adolescente 3', 'C1_cons_nutri3_12_17'),
    ]
    sup_secciones.append(sec('7. CONSULTA NUTRICIONAL', con_items))

    # 5. Consejerï¿½a Nutricional (from cred2024_4)
    cn_items = []
    for suf in ['bpn', '4_5m', '1_6_11m', '2_6_11m', '3_6_11m', '4_6_11m',
                '1_1a', '2_1a', '3_1a', '4_1a', '5_1a', '6_1a',
                '1_2a', '2_2a', '3_2a', '4_2a', '5_2a', '6_2a',
                '1_3a', '2_3a', '3_3a', '4_3a',
                '1_4a', '2_4a', '3_4a', '4_4a',
                '1_5_11a', '2_5_11a', '3_5_11a', '4_5_11a', '5_5_11a', '6_5_11a']:
        col = f'C1_cons_nutric_{suf}'
        label = f'Cons. Nutr. {suf}'
        if v(c24, col):
            cn_items.append((c24, label, col))
    if cn_items:
        sup_secciones.append(sec('5. CONSEJER\u00cdA NUTRICIONAL', cn_items))
    sup_sec = sup_secciones if sup_secciones else [{'titulo':'Sin datos','columnas':['INDICADOR','TOTAL'],'filas':[],'total':0}]
    pages.append({
        'id': 'suplementacion', 'titulo': 'SUPLEMENTACION PREVENTIVA',
        'tabla_html': build_suplementacion_html(sup_sec),
        'secciones': sup_sec
    })

    # ---- PAGE 3: Tx. ANEMIA ----
    ane_secciones = []

    # 1. Tratamiento Sulfato Ferroso
    ane_edades = ['6_11m', '1a', '2a', '3a', '4a']
    for suf in ane_edades:
        ane_secciones.append(sec(f'Adm. Tx. Sulfato Ferroso {suf}', [
            (c24, f'Suplem 1ra {suf}', f'C1_suplem_1ra_{suf}'),
            (c24, f'Suplem 2da {suf}', f'C1_suplem_2da_{suf}'),
            (c24, f'Suplem 3ra {suf}', f'C1_suplem_3ra_{suf}'),
            (c24, f'Suplem 4ta {suf}', f'C1_suplem_4ta_{suf}'),
            (c24, f'Suplem 5ta {suf}', f'C1_suplem_5ta_{suf}'),
            (c24, f'Suplem 6ta {suf}', f'C1_suplem_6ta_{suf}'),
            (c24, f'TA', f'C1_ta_suplem_{suf}'),
        ]))

    # 2. Dosaje Hemoglobina Control
    ane_secciones.append(sec('2. DOSAJE HEMOGLOBINA CONTROL', [
        (c2, 'HB BPN 1er', 'C2_primer_dosaje_hb_bpn'),
        (c2, 'HB BPN 2do', 'C2_segundo_dosaje_hb_bpn'),
        (c2, 'HB 6-11m 1er', 'C2_hb_6_11m_primer'),
        (c2, 'HB 6-11m 2do', 'C2_hb_6_11m_segundo'),
        (c2, 'HB 12-23m 1er', 'C2_hb_12_23m_primer'),
        (c2, 'HB 12-23m 2do', 'C2_hb_12_23m_segundo'),
        (c2, 'HB 12-23m 3er', 'C2_hb_12_23m_tercer'),
        (c2, 'HB 24-35m 1er', 'C2_hb_24_35m_primer'),
        (c2, 'HB 24-35m 2do', 'C2_hb_24_35m_segundo'),
        (c2, 'HB 36-59m 1er', 'C2_hb_36_59m_primer'),
        (c2, 'HB 36-59m 2do', 'C2_hb_36_59m_segundo'),
        (c2, 'HB 5-11a', 'C2_hb_5_11a'),
        (c2, 'HB Adolescente 1er', 'C2_hb_adolescente_primer'),
        (c2, 'HB Adolescente 2do', 'C2_hb_adolescente_segundo'),
        (c2, 'HB Gestante 1er', 'C2_hb_gestante_primer'),
        (c2, 'HB Gestante 2do', 'C2_hb_gestante_segundo'),
        (c2, 'HB Gestante 3er', 'C2_hb_gestante_tercero'),
        (c2, 'HB MEF', 'C2_hb_mef'),
        (c2, 'HB Puï¿½rpera', 'C2_hb_puerpera'),
    ]))

    # 3. Consulta Mï¿½dica
    ane_secciones.append(sec('3. CONSULTA Mï¿½DICA', [
        (c4, 'Anamnesis y Ex. Fï¿½sico RN', 'C4_anamnesis_y_ex_fisico_rn_normal'),
        (c4, 'Evaluaciï¿½n Mï¿½dica RN', 'C4_evaluacion_medica_rn'),
    ]))

    # 4. Consulta Nutricional (Tx Anemia)
    ane_secciones.append(sec('4. CONSULTA NUTRICIONAL (Tx Anemia)', [
        (c4, 'Consulta Nutricional BPN', 'C4_consulta_nutric_bpn'),
        (c4, 'Consulta Nutricional 4-5m', 'C4_consulta_nutric1_4_5m'),
        (c4, 'Consulta Nutricional 1', 'C4_consulta_nutric_1_1a'),
        (c4, 'Consulta Nutricional 6-11m 1', 'C4_consulta_nutric_1_6_11m'),
        (c4, 'Consulta Nutricional 2a 1', 'C4_consulta_nutric_1_2a'),
        (c4, 'Consulta Nutricional 3a 1', 'C4_consulta_nutric_1_3a'),
        (c4, 'Consulta Nutricional 4a 1', 'C4_consulta_nutric_1_4a'),
        (c4, 'Consulta Nutricional 5-11a 1', 'C4_consulta_nutric_1_5_11a'),
    ]))
    ane_sec = ane_secciones if ane_secciones else [{'titulo':'Sin datos','columnas':['INDICADOR','TOTAL'],'filas':[],'total':0}]
    pages.append({
        'id': 'tx_anemia', 'titulo': 'TRATAMIENTO DE ANEMIA',
        'tabla_html': build_tx_anemia_html(ane_sec),
        'secciones': ane_sec
    })

    return {
        'tipo': 'formato_nino_cred', 'anio': anio, 'filtros': filtros, 'meses': meses,
        'paginas': pages
    }

# Old reporte for non-2024 years (using his_proceso tables)
def _reporte_completo_cred_old(cur, esquema, anio, meses, filtros):
    tabla = _resolve_tabla(anio, 'cred')
    where = _build_where(anio, meses, filtros)
    qt = lambda t: _qtable(esquema, t)
    ace = _build_age_case()
    rn_ace = _build_rn_age_case()

    AGE_ORDER_LOCAL = {'< 6 meses':1,'6-11m':2,'12-23m':3,'24-35m':4,'36-47m':5,'48-59m':6,'5-9 a\u00f1os':7,'10-11 a\u00f1os':8,'Otros':9}
    RN_AGE_ORDER = {'RN 3-6d':1,'RN 7-13d':2,'RN 14-21d':3,'RN 22-28d':4,'< 1 a\u00f1o':5,'1 a\u00f1o':6,'2 a\u00f1os':7,'3 a\u00f1os':8,'4 a\u00f1os':9,'5-9 a\u00f1os':10,'10-11 a\u00f1os':11,'Sin edad':0,'Otros':12}

    pages = []

    def _qflat(codes, name_map, age_case_override=None, age_order_override=None):
        ac = age_case_override or ace
        ao = age_order_override or AGE_ORDER_LOCAL
        cs = "','".join(codes)
        cur.execute(f"""
            SELECT codigo_item, {ac} as grupo_edad, COUNT(*) as total
            FROM {qt(tabla)} t
            WHERE {where} AND codigo_item IN ('{cs}')
            GROUP BY codigo_item, grupo_edad
            ORDER BY codigo_item, grupo_edad
        """)
        rows = cur.fetchall()
        agg = {}
        all_ages = []
        seen_ages = set()
        for code, ge, tot in rows:
            if ge not in seen_ages:
                seen_ages.add(ge)
                all_ages.append(ge)
            if code not in agg:
                agg[code] = {}
            agg[code][ge] = agg[code].get(ge, 0) + tot
        all_ages.sort(key=lambda x: ao.get(x, 99))
        filas = []
        totales = {a:0 for a in all_ages}
        for code in codes:
            name = name_map.get(code, code)
            if code not in agg:
                continue
            row = {'Item': name}
            total = 0
            for a in all_ages:
                v = agg[code].get(a, 0)
                row[a] = v
                totales[a] = totales.get(a, 0) + v
                total += v
            row['Total'] = total
            filas.append(row)
        totales['Total'] = sum(totales.values())
        columnas = ['Item'] + all_ages + ['Total']
        return {'columnas': columnas, 'filas': filas, 'totales': totales}

    def _qval(codes, valor_labels, label_map, age_case_override=None, age_order_override=None):
        ac = age_case_override or ace
        ao = age_order_override or AGE_ORDER_LOCAL
        cs = "','".join(codes)
        vs = "','".join(valor_labels)
        cur.execute(f"""
            SELECT {ac} as grupo_edad, valor_lab, COUNT(*) as total
            FROM {qt(tabla)} t
            WHERE {where} AND codigo_item IN ('{cs}') AND valor_lab IN ('{vs}')
            GROUP BY grupo_edad, valor_lab
            ORDER BY grupo_edad, valor_lab
        """)
        rows = cur.fetchall()
        agg = {}
        for ge, vl, tot in rows:
            if ge not in agg:
                agg[ge] = {}
            agg[ge][vl] = agg[ge].get(vl, 0) + tot
        col_labels = [label_map.get(vl, vl) for vl in valor_labels]
        filas = []
        totales = {l:0 for l in col_labels}
        for ge in sorted(agg.keys(), key=lambda x: ao.get(x, 99)):
            row = {'Grupo Edad': ge}
            total = 0
            for vl in valor_labels:
                lb = label_map.get(vl, vl)
                v = agg[ge].get(vl, 0)
                row[lb] = v
                totales[lb] = totales.get(lb, 0) + v
                total += v
            row['Total'] = total
            filas.append(row)
        totales['Total'] = sum(totales.values())
        columnas = ['Grupo Edad'] + col_labels + ['Total']
        return {'columnas': columnas, 'filas': filas, 'totales': totales}

    # ---- PAGE 1: FORMATO NI\u00d1O ----
    cn = "','".join(CRED_CODES)
    # age_case_cte: uses CTE aliases (edad_dias/edad_anios/edad_meses) - for main query
    age_case_cte = """
        CASE
            WHEN edad_dias BETWEEN 3 AND 6 THEN 'Reci\u00e9n Nacido Sano 3-6d'
            WHEN edad_dias BETWEEN 7 AND 13 THEN 'Reci\u00e9n Nacido Sano 7-13d'
            WHEN edad_dias BETWEEN 14 AND 21 THEN 'Reci\u00e9n Nacido Sano 14-21d'
            WHEN edad_dias >= 22 AND edad_dias < 29 THEN 'Reci\u00e9n Nacido Sano may_22d'
            WHEN edad_anios = 0 AND edad_meses < 12 THEN '< 1 a\u00f1o'
            WHEN edad_anios = 1 THEN '1 a\u00f1o'
            WHEN edad_anios = 2 THEN '2 a\u00f1os'
            WHEN edad_anios = 3 THEN '3 a\u00f1os'
            WHEN edad_anios = 4 THEN '4 a\u00f1os'
            WHEN edad_anios BETWEEN 5 AND 9 THEN '5-9 a\u00f1os'
            WHEN edad_anios BETWEEN 10 AND 11 THEN '10-11 a\u00f1os'
            ELSE 'Otros'
        END"""
    # age_case_direct: uses raw column computation - for _qmonth_pivot (no CTE)
    _ed = '(fecha_atencion::date - fecha_nacimiento::date)'
    _ea = 'EXTRACT(YEAR FROM age(fecha_atencion::date, fecha_nacimiento::date))'
    _em = 'EXTRACT(MONTH FROM age(fecha_atencion::date, fecha_nacimiento::date))'
    age_case_direct = f"""
        CASE
            WHEN {_ed} BETWEEN 3 AND 6 THEN 'Reci\u00e9n Nacido Sano 3-6d'
            WHEN {_ed} BETWEEN 7 AND 13 THEN 'Reci\u00e9n Nacido Sano 7-13d'
            WHEN {_ed} BETWEEN 14 AND 21 THEN 'Reci\u00e9n Nacido Sano 14-21d'
            WHEN {_ed} >= 22 AND {_ed} < 29 THEN 'Reci\u00e9n Nacido Sano may_22d'
            WHEN {_ea} = 0 AND {_em} < 12 THEN '< 1 a\u00f1o'
            WHEN {_ea} = 1 THEN '1 a\u00f1o'
            WHEN {_ea} = 2 THEN '2 a\u00f1os'
            WHEN {_ea} = 3 THEN '3 a\u00f1os'
            WHEN {_ea} = 4 THEN '4 a\u00f1os'
            WHEN {_ea} BETWEEN 5 AND 9 THEN '5-9 a\u00f1os'
            WHEN {_ea} BETWEEN 10 AND 11 THEN '10-11 a\u00f1os'
            ELSE 'Otros'
        END"""
    age_case = age_case_cte
    sql = f"""
    WITH base AS (
        SELECT dni_paciente,
            (fecha_atencion::date - fecha_nacimiento::date) as edad_dias,
            EXTRACT(YEAR FROM age(fecha_atencion::date, fecha_nacimiento::date)) as edad_anios,
            EXTRACT(MONTH FROM age(fecha_atencion::date, fecha_nacimiento::date)) as edad_meses,
            ROW_NUMBER() OVER (PARTITION BY dni_paciente ORDER BY fecha_atencion, id_cita) as nro_control
        FROM {qt(tabla)} t
        WHERE {where} AND codigo_item IN ('{cn}')
    )
    SELECT * FROM (
        SELECT
            {age_case} as grupo_etareo,
            SUM(CASE WHEN nro_control = 1 THEN 1 ELSE 0 END) as c1,
            SUM(CASE WHEN nro_control = 2 THEN 1 ELSE 0 END) as c2,
            SUM(CASE WHEN nro_control = 3 THEN 1 ELSE 0 END) as c3,
            SUM(CASE WHEN nro_control = 4 THEN 1 ELSE 0 END) as c4,
            SUM(CASE WHEN nro_control = 5 THEN 1 ELSE 0 END) as c5,
            SUM(CASE WHEN nro_control = 6 THEN 1 ELSE 0 END) as c6,
            SUM(CASE WHEN nro_control = 7 THEN 1 ELSE 0 END) as c7,
            SUM(CASE WHEN nro_control = 8 THEN 1 ELSE 0 END) as c8,
            SUM(CASE WHEN nro_control > 8 THEN 1 ELSE 0 END) as c9mas,
            COUNT(*) as total_atenciones,
            COUNT(DISTINCT dni_paciente) as total_ninos
        FROM base
        GROUP BY {age_case}
    ) sub
    ORDER BY
        CASE sub.grupo_etareo
            WHEN 'Reci\u00e9n Nacido Sano 3-6d' THEN 1
            WHEN 'Reci\u00e9n Nacido Sano 7-13d' THEN 2
            WHEN 'Reci\u00e9n Nacido Sano 14-21d' THEN 3
            WHEN 'Reci\u00e9n Nacido Sano may_22d' THEN 4
            WHEN '< 1 a\u00f1o' THEN 5
            WHEN '1 a\u00f1o' THEN 6
            WHEN '2 a\u00f1os' THEN 7
            WHEN '3 a\u00f1os' THEN 8
            WHEN '4 a\u00f1os' THEN 9
            WHEN '5-9 a\u00f1os' THEN 10
            WHEN '10-11 a\u00f1os' THEN 11
            ELSE 12
        END
    """
    cur.execute(sql)
    filas_brutas = cur.fetchall()
    pg_cols = [desc[0] for desc in cur.description]
    col_names = ['EDADES','1ER.CONTROL','2DO.CONTROL','3ER.CONTROL','4TO.CONTROL',
                 '5TO.CONTROL','6TO.CONTROL','7MO.CONTROL','8VO.CONTROL',
                 'TOTAL ATENCIONES','TOTAL NI\u00d1OS ATENDIDOS']
    display_to_pg = {
        '1ER.CONTROL': 'c1', '2DO.CONTROL': 'c2', '3ER.CONTROL': 'c3',
        '4TO.CONTROL': 'c4', '5TO.CONTROL': 'c5', '6TO.CONTROL': 'c6',
        '7MO.CONTROL': 'c7', '8VO.CONTROL': 'c8',
        'TOTAL ATENCIONES': 'total_atenciones',
        'TOTAL NI\u00d1OS ATENDIDOS': 'total_ninos',
    }

    filas = []
    totales_main = {cn:0 for cn in col_names[1:]}
    for row in filas_brutas:
        d = dict(zip(pg_cols, row))
        fila = {'EDADES': d.get('grupo_etareo', '')}
        for cname in col_names[1:]:
            pg_key = display_to_pg.get(cname, '')
            val = d.get(pg_key, 0) or 0
            fila[cname] = val
            totales_main[cname] += val
        filas.append(fila)

    secciones = []

    rn_data = _qflat(ATENCION_RN_CODES, ATENCION_RN_NAMES, rn_ace, RN_AGE_ORDER)
    secciones.append({'titulo': 'ATENCI\u00d3N DEL RECI\u00c9N NACIDO', **rn_data})

    ses_data = _qval(SESIONES_CODES, ['1','2','3','4'], SESIONES_LABELS)
    secciones.append({'titulo': 'SESIONES DE ESTIMULACI\u00d3N TEMPRANA', **ses_data})

    lac_data = _qflat(LACTANCIA_CODES, LACTANCIA_NAMES)
    secciones.append({'titulo': 'LACTANCIA MATERNA', **lac_data})

    eval_data = _qval(EVAL_DESARROLLO_CODES, ['LEN','MOT','SOC','COO','COG'], EVAL_DESARROLLO_AREAS)
    secciones.append({'titulo': 'EVALUACI\u00d3N DEL DESARROLLO', **eval_data})

    plan_data = _qflat(PLAN_INTEGRAL_CODES, PLAN_INTEGRAL_NAMES)
    secciones.append({'titulo': 'PLAN INTEGRAL', **plan_data})

    consejeria_names = {c: c for c in CONSEJERIA_CODES}
    cons_data = _qflat(CONSEJERIA_CODES, consejeria_names)
    secciones.append({'titulo': 'CONSEJER\u00cdA', **cons_data})

    bpn_codes = ['P070','P071','P0711','P0712','P0713','P072','P073']
    bpn_cs = "','".join(bpn_codes)
    cur.execute(f"""
        SELECT COUNT(DISTINCT dni_paciente) as total_pacientes
        FROM {qt(tabla)} t
        WHERE {where} AND codigo_item IN ('{bpn_cs}')
    """)
    bpn_total = cur.fetchone()[0] or 0
    secciones.append({'titulo': 'RECI\u00c9N NACIDO BAJO PESO / PREMATURO',
        'columnas': ['INDICADOR', 'TOTAL'],
        'filas': [{'INDICADOR': 'Pacientes con diagn\u00f3stico RN BPN/Prematuro', 'TOTAL': bpn_total}],
        'totales': {'TOTAL': bpn_total}})

    # ---- EVALUACI\u00d3N NUTRICIONAL (sub-secci\u00f3n) ----
    def _qmonth_pivot(age_case_label, age_case_sql, age_order):
        cs = "','".join(CRED_CODES)
        cur.execute(f"""
            WITH age_cte AS (
                SELECT EXTRACT(MONTH FROM fecha_atencion::date) as mes,
                       (fecha_atencion::date - fecha_nacimiento::date) as edad_dias,
                       EXTRACT(YEAR FROM age(fecha_atencion::date, fecha_nacimiento::date)) as edad_anios,
                       EXTRACT(MONTH FROM age(fecha_atencion::date, fecha_nacimiento::date)) as edad_meses,
                       dni_paciente
                FROM {qt(tabla)} t
                WHERE {where} AND codigo_item IN ('{cs}')
            )
            SELECT mes, {age_case_sql} as grupo, COUNT(DISTINCT dni_paciente) as total
            FROM age_cte
            GROUP BY mes, grupo
            ORDER BY mes, grupo
        """)
        rows = cur.fetchall()
        months = [1,2,3,4,5,6]
        all_groups = sorted(set(r[1] for r in rows if r[1]), key=lambda x: age_order.get(x, 99))
        pivot = {}
        for m in months:
            pivot[m] = {g: 0 for g in all_groups}
        for m, g, t in rows:
            if g and m in pivot:
                pivot[int(m)][g] = pivot[int(m)].get(g, 0) + t
        filas = []
        totales = {g: 0 for g in all_groups}
        for m in months:
            row = {'Mes': f'Mes {m}'}
            total = 0
            for g in all_groups:
                v = pivot[m][g]
                row[g] = v
                totales[g] += v
                total += v
            row['Total'] = total
            filas.append(row)
        totales['Total'] = sum(totales.values())
        total_row = {'Mes': 'Total'}
        total_row.update(totales)
        filas.append(total_row)
        columnas = ['Mes'] + all_groups + ['Total']
        return {'columnas': columnas, 'filas': filas, 'totales': totales}

    rn_age_groups = {
        'Reci\u00e9n Nacido Sano 3-6d': 1,
        'Reci\u00e9n Nacido Sano 7-13d': 2,
        'Reci\u00e9n Nacido Sano 14-21d': 3,
        'Reci\u00e9n Nacido Sano may_22d': 4
    }
    eval_nutric_data = _qmonth_pivot('RN', age_case_cte, rn_age_groups)
    secciones.append({'titulo': 'EVALUACI\u00d3N NUTRICIONAL', **eval_nutric_data})

    consulta_nutric_age_case = """
        CASE
            WHEN edad_dias BETWEEN 0 AND 27 THEN 'Reci\u00e9n Nacido'
            WHEN edad_anios = 0 AND edad_meses BETWEEN 4 AND 5 THEN '4-5m'
            WHEN edad_anios = 0 AND edad_meses BETWEEN 6 AND 11 THEN '6-11m'
            WHEN edad_anios = 1 THEN '1 a\u00f1o'
            WHEN edad_anios = 2 THEN '2 a\u00f1os'
            WHEN edad_anios = 3 THEN '3 a\u00f1os'
            WHEN edad_anios = 4 THEN '4 a\u00f1os'
            WHEN edad_anios BETWEEN 5 AND 11 THEN '5-11 a\u00f1os'
            ELSE 'Otros'
        END"""
    consulta_ao = {'Reci\u00e9n Nacido':1,'4-5m':2,'6-11m':3,'1 a\u00f1o':4,'2 a\u00f1os':5,'3 a\u00f1os':6,'4 a\u00f1os':7,'5-11 a\u00f1os':8}
    consulta_nutric_data = _qmonth_pivot('Consulta', consulta_nutric_age_case, consulta_ao)
    secciones.append({'titulo': 'CONSULTA NUTRICIONAL', **consulta_nutric_data})

    pages.append({
        'id': 'formato_nino', 'titulo': 'FORMATO NI\u00d1O - CONTROL DE CRECIMIENTO Y DESARROLLO',
        'columnas': col_names, 'filas': filas, 'totales': totales_main,
        'secciones': secciones
    })

    # ---- PAGE 2: SUPLEMENTACION ----
    sup_secciones = []

    for code, name in [('U1692', 'Sulfato Ferroso'), ('59430', 'Polimaltosado/Hierro Polimaltosado'), ('U140', 'Otros Suplementos')]:
        cur.execute(f"""
            SELECT {ace} as grupo_edad, COUNT(*) as total
            FROM {qt(tabla)} t
            WHERE {where} AND codigo_item = '{code}'
            GROUP BY grupo_edad
            ORDER BY grupo_edad
        """)
        srows = cur.fetchall()
        sitems = []
        stotal = 0
        for ge, tot in srows:
            sitems.append({'label': ge, 'valor': tot})
            stotal += tot
        sup_secciones.append({
            'titulo': name,
            'columnas': ['GRUPO EDAD', 'TOTAL'],
            'filas': sitems,
            'total': stotal
        })

    supl_entrega = [
        ('99199.26', 'SUPLEMENTACI\u00d3N GENERAL', ['1','2','3','4','5','6','7','TA'], {'1':'1ra','2':'2da','3':'3ra','4':'4ta','5':'5ta','6':'6ta','7':'7ma','TA':'TA'}),
        ('99199.17', 'SUPLEMENTACI\u00d3N HIERRO NI\u00d1OS', ['1','2','3','4','5','6','TA'], {'1':'1ra','2':'2da','3':'3ra','4':'4ta','5':'5ta','6':'6ta','TA':'TA'}),
        ('99199.27', 'VITAMINA A', ['VA1','VA2'], {'VA1':'1ra Dosis','VA2':'2da Dosis'}),
        ('99403.01', 'MULTIMICRONUTRIENTES', ['1','2','3','4','5','6'], {'1':'1ra','2':'2da','3':'3ra','4':'4ta','5':'5ta','6':'6ta'}),
    ]
    for code, titulo, vlabels, vmap in supl_entrega:
        data = _qval([code], vlabels, vmap)
        sup_secciones.append({'titulo': titulo, **data})

    pages.append({
        'id': 'suplementacion', 'titulo': 'SUPLEMENTACION PREVENTIVA',
        'secciones': sup_secciones if sup_secciones else [{'titulo':'Sin datos','columnas':['INDICADOR','TOTAL'],'filas':[],'total':0}]
    })

    # ---- PAGE 3: Tx. ANEMIA ----
    ane_secciones = []

    for code, name in [('85018.01', 'Dosaje de Hemoglobina'), ('85018', 'Dosaje de Hemoglobina')]:
        cur.execute(f"""
            SELECT {ace} as grupo_edad, COUNT(*) as total
            FROM {qt(tabla)} t
            WHERE {where} AND codigo_item = '{code}'
            GROUP BY grupo_edad
            ORDER BY grupo_edad
        """)
        arows = cur.fetchall()
        aitems = []
        atotal = 0
        for ge, tot in arows:
            aitems.append({'label': ge, 'valor': tot})
            atotal += tot
        ane_secciones.append({
            'titulo': name,
            'columnas': ['GRUPO EDAD', 'TOTAL'],
            'filas': aitems,
            'total': atotal
        })

    cur.execute(f"""
        SELECT {ace} as grupo_edad, COUNT(*) as total
        FROM {qt(tabla)} t
        WHERE {where} AND codigo_item = 'C0011'
        GROUP BY grupo_edad
        ORDER BY grupo_edad
    """)
    arows = cur.fetchall()
    aitems = []
    atotal = 0
    for ge, tot in arows:
        aitems.append({'label': ge, 'valor': tot})
        atotal += tot
    ane_secciones.append({
        'titulo': 'Tratamiento Anemia/Visita Seguimiento',
        'columnas': ['GRUPO EDAD', 'TOTAL'],
        'filas': aitems,
        'total': atotal
    })

    pages.append({
        'id': 'tx_anemia', 'titulo': 'TRATAMIENTO DE ANEMIA',
        'secciones': ane_secciones if ane_secciones else [{'titulo':'Sin datos','columnas':['INDICADOR','TOTAL'],'filas':[],'total':0}]
    })

    # Add tabla_html for all pages
    for p in pages:
        secs = p.get('secciones', [])
        if secs and not p.get('tabla_html'):
            h = '<style>' + _REPORT_CSS + '</style>'
            h += '<div class="page">'
            h += _sec_header({**filtros, 'anio': str(anio)})
            for s in secs:
                h += _render_seccion_table(s)
            h += '</div>'
            p['tabla_html'] = h

    return {
        'tipo': 'formato_nino_cred', 'anio': anio, 'filtros': filtros, 'meses': meses,
        'paginas': pages
    }

def _reporte_completo_cred(cur, esquema, anio, meses, filtros):
    """Route to appropriate implementation based on year."""
    if str(anio) == '2024':
        try:
            return _reporte_cred_2024(cur, esquema, anio, meses, filtros)
        except Exception as e:
            print(f"cred2024 tables not available: {e}")
            return _reporte_completo_cred_old(cur, esquema, anio, meses, filtros)
    return _reporte_completo_cred_old(cur, esquema, anio, meses, filtros)

# ============ REPORTE IRAS EDAS (2024) ============
def _query_age_groups(cur, anio, codigos, filtros):
    """Query CPT/procedure codes from his_proceso_{anio} grouped by age.

    Returns dict: {code: {'men2m':N, '2_11m':N, '1a':N, '2a_4a':N, '5_11a':N}}
    """
    tbl = f'es_ivan.his_proceso_{anio}'
    where_parts = [f"anio = {anio}"]
    if filtros:
        for col in ['red','microred','nombre_establecimiento','provincia','distrito']:
            val = filtros.get(col, '')
            if val:
                where_parts.append(f"LOWER({col}) LIKE LOWER('%{val.replace(chr(39), chr(39)+chr(39))}%')")
    where = ' AND '.join(where_parts)
    codes_str = ','.join(f"'{c}'" for c in codigos)
    sql = f"""
        SELECT codigo_item,
            CASE
                WHEN tip_edad = 'D' THEN 'men2m'
                WHEN tip_edad = 'M' AND edad <= 11 THEN '2_11m'
                WHEN tip_edad = 'A' AND edad = 1 THEN '1a'
                WHEN tip_edad = 'A' AND edad >= 2 AND edad <= 4 THEN '2a_4a'
                WHEN tip_edad = 'A' AND edad >= 5 AND edad <= 11 THEN '5_11a'
                ELSE 'men2m'
            END as grupo,
            COUNT(*) as cnt
        FROM {tbl}
        WHERE {where} AND codigo_item IN ({codes_str})
        GROUP BY codigo_item, grupo
        ORDER BY codigo_item, grupo
    """
    cur.execute(sql)
    result = {}
    for code in codigos:
        result[code] = {'men2m':0, '2_11m':0, '1a':0, '2a_4a':0, '5_11a':0}
    for row in cur.fetchall():
        code, grupo, cnt = row
        if code in result:
            if grupo in result[code]:
                result[code][grupo] = (result[code][grupo] or 0) + cnt
            else:
                result[code][grupo] = cnt
    return result


def _query_iras_ref(cur, anio, filtros):
    """Query his_proceso_{anio} with exact ref HTML age groups for ALL CIE10 diagnosis codes.

    Age groups: <29d, 29d_59d, 2_11m, 1_4a, 5_11a
    Returns dict: {category: {age_group: count, subtotal: N, grand_total: N}}
    """
    tbl = f'es_ivan.his_proceso_{anio}'
    where_parts = [f"anio = {anio}"]
    if filtros:
        for col in ['red','microred','nombre_establecimiento','provincia','distrito']:
            val = filtros.get(col, '')
            if val:
                where_parts.append(f"LOWER({col}) LIKE LOWER('%{val.replace(chr(39), chr(39)+chr(39))}%')")
    where = ' AND '.join(where_parts)

    # Map of category -> list of CIE10 codes
    CATEGORIES = {
        'ira_no_compl': ['J00X','J040','J041','J042','J060','J068','J069','J209'],
        'faringo': ['J020','J029','J030','J038','J039'],
        'oma': ['H650','H651','H660','H669'],
        'sinusitis': ['J010','J011','J012','J013','J014','J019'],
        'neumonia_sin_compl': ['J129','J159','J189'],
        'iras_con_compl': ['A369','A370','A371','A378','A379','J120','J121','J122','J123','J128','J13X','J14X',
                          'J150','J151','J152','J153','J154','J157','J158','J159','J160','J168'],
        'neumonia_grave_men2m': ['J050','J051','J851','J860','J869','J90X','J939','J100','J110'],
        'neumonia_emg_2m_4a': ['J050','J051','J851','J860','J869','J90X','J939','J100','J110'],
        'sob_asma': ['J210','J211','J218','J219','J440','J441','J448','J449','J450','J451','J458','J459','J4591','J46X'],
    }

    all_codes = list(set(sum(CATEGORIES.values(), [])))
    codes_str = ','.join(f"'{c}'" for c in all_codes)

    AGE_CASE = '''
        CASE
            WHEN tip_edad = 'D' AND edad < 29 THEN 'men29d'
            WHEN tip_edad = 'D' AND edad >= 29 AND edad <= 59 THEN '29d_59d'
            WHEN (tip_edad = 'M' AND edad <= 11) OR (tip_edad = 'D' AND edad > 59) THEN '2_11m'
            WHEN tip_edad = 'A' AND edad >= 1 AND edad <= 4 THEN '1_4a'
            WHEN tip_edad = 'A' AND edad >= 5 AND edad <= 11 THEN '5_11a'
            WHEN tip_edad = 'M' AND edad >= 12 THEN '1_4a'
            ELSE 'men29d'
        END'''

    AGE_CASE_SOB = '''
        CASE
            WHEN tip_edad = 'D' AND edad < 29 THEN 'men29d'
            WHEN tip_edad = 'D' AND edad >= 29 AND edad <= 59 THEN '29d_59d'
            WHEN (tip_edad = 'M' AND edad <= 11) OR (tip_edad = 'D' AND edad > 59) THEN '2_11m'
            WHEN (tip_edad = 'M' AND edad >= 12 AND edad <= 23) OR (tip_edad = 'A' AND edad = 1) THEN '12_23m'
            WHEN tip_edad = 'A' AND edad = 2 THEN '2a'
            WHEN tip_edad = 'A' AND edad >= 3 AND edad <= 4 THEN '3_4a'
            WHEN tip_edad = 'A' AND edad >= 5 AND edad <= 11 THEN '5_11a'
            WHEN tip_edad = 'M' AND edad >= 24 THEN '2a'
            ELSE 'men29d'
        END'''

    # Query IRA/EDA codes with IRA age groups
    sql_ira = f"""
        SELECT codigo_item,
            {AGE_CASE} as grupo,
            COUNT(*) as cnt
        FROM {tbl}
        WHERE {where} AND codigo_item IN ({codes_str})
        GROUP BY codigo_item, grupo
        ORDER BY codigo_item, grupo
    """
    cur.execute(sql_ira)
    ira_rows = {}
    for row in cur.fetchall():
        code, grupo, cnt = row
        if code not in ira_rows:
            ira_rows[code] = {}
        ira_rows[code][grupo] = (ira_rows[code].get(grupo, 0) or 0) + cnt

    # Query SOB codes with SOB age groups
    sob_codes = ','.join(f"'{c}'" for c in CATEGORIES['sob_asma'])
    sql_sob = f"""
        SELECT codigo_item,
            {AGE_CASE_SOB} as grupo,
            COUNT(*) as cnt
        FROM {tbl}
        WHERE {where} AND codigo_item IN ({sob_codes})
        GROUP BY codigo_item, grupo
        ORDER BY codigo_item, grupo
    """
    cur.execute(sql_sob)
    sob_rows = {}
    for row in cur.fetchall():
        code, grupo, cnt = row
        if code not in sob_rows:
            sob_rows[code] = {}
        sob_rows[code][grupo] = (sob_rows[code].get(grupo, 0) or 0) + cnt

    AGE_KEYS = ['men29d', '29d_59d', '2_11m', '1_4a', '5_11a']
    SOB_AGE_KEYS = ['men29d', '29d_59d', '2_11m', '12_23m', '2a', '3_4a', '5_11a']

    def _agg(rows, codes, age_keys):
        totals = {k: 0 for k in age_keys}
        for code in codes:
            for ak in age_keys:
                totals[ak] += rows.get(code, {}).get(ak, 0)
        subtotal = sum(totals.values())
        return {**totals, 'subtotal': subtotal}

    result = {}
    for cat, codes in CATEGORIES.items():
        if cat == 'sob_asma':
            result[cat] = _agg(sob_rows, codes, SOB_AGE_KEYS)
        else:
            result[cat] = _agg(ira_rows, codes, AGE_KEYS)

    # Compute grand total for IRA without complications (sum of 5 sub-items)
    ira_sin_compl_keys = ['ira_no_compl', 'faringo', 'oma', 'sinusitis', 'neumonia_sin_compl']
    result['ira_sin_compl'] = {}
    for k in AGE_KEYS + ['subtotal']:
        result['ira_sin_compl'][k] = sum(result.get(cat, {}).get(k, 0) for cat in ira_sin_compl_keys)

    # Grand total for IRA without complications = sum of all subtotals
    result['ira_sin_compl']['grand_total'] = sum(result.get(cat, {}).get('subtotal', 0) for cat in ira_sin_compl_keys)

    # IRA with complications
    ira_con_compl_keys = ['iras_con_compl', 'neumonia_grave_men2m', 'neumonia_emg_2m_4a']
    result['ira_con_compl'] = {}
    for k in AGE_KEYS + ['subtotal']:
        result['ira_con_compl'][k] = sum(result.get(cat, {}).get(k, 0) for cat in ira_con_compl_keys)
    result['ira_con_compl']['grand_total'] = sum(result.get(cat, {}).get('subtotal', 0) for cat in ira_con_compl_keys)

    # Total de Casos de IRA = ira_sin_compl + ira_con_compl
    result['ira_total'] = {}
    for k in AGE_KEYS + ['subtotal']:
        result['ira_total'][k] = result['ira_sin_compl'].get(k, 0) + result['ira_con_compl'].get(k, 0)
    result['ira_total']['grand_total'] = result['ira_sin_compl']['grand_total'] + result['ira_con_compl']['grand_total']

    return result


def _query_resumen_mensual(cur, anio, filtros):
    """Query monthly summary data for Resumen Acumulado section.

    Returns list of dicts: {mes, eda_acuosa_men1a, eda_acuosa_1a, ...}
    """
    tbl = f'es_ivan.his_proceso_{anio}'
    where_parts = [f"anio = {anio}"]
    if filtros:
        for col in ['red','microred','nombre_establecimiento','provincia','distrito']:
            val = filtros.get(col, '')
            if val:
                where_parts.append(f"LOWER({col}) LIKE LOWER('%{val.replace(chr(39), chr(39)+chr(39))}%')")
    where = ' AND '.join(where_parts)

    # EDA acuosa age groups: <1a, 1a, 2a, 3a, 4a (from the table columns)
    # We'll aggregate by month and age from his_proceso
    # Use simplified monthly counts from iras_edas_2024 by month
    sql = f"""
        SELECT 
            nt.mes,
            SUM(CASE WHEN nt.codigo_item IN ('A009','A000','A001') 
                     AND (nt.tip_edad='D' OR (nt.tip_edad='M' AND nt.edad < 12) OR (nt.tip_edad='A' AND nt.edad = 0))
                THEN 1 ELSE 0 END) as eda_acuosa_men1a,
            SUM(CASE WHEN nt.codigo_item IN ('A009','A000','A001') 
                     AND nt.tip_edad='A' AND nt.edad = 1
                THEN 1 ELSE 0 END) as eda_acuosa_1a,
            SUM(CASE WHEN nt.codigo_item IN ('A009','A000','A001') 
                     AND nt.tip_edad='A' AND nt.edad = 2
                THEN 1 ELSE 0 END) as eda_acuosa_2a,
            SUM(CASE WHEN nt.codigo_item IN ('A009','A000','A001') 
                     AND nt.tip_edad='A' AND nt.edad = 3
                THEN 1 ELSE 0 END) as eda_acuosa_3a,
            SUM(CASE WHEN nt.codigo_item IN ('A009','A000','A001') 
                     AND nt.tip_edad='A' AND nt.edad = 4
                THEN 1 ELSE 0 END) as eda_acuosa_4a,
            SUM(CASE WHEN nt.codigo_item IN ('J00X','J040','J041','J042','J060','J068','J069','J209') 
                     AND nt.tip_edad='A' AND nt.edad < 5
                THEN 1 ELSE 0 END) as ira_no_compl_men5a,
            SUM(CASE WHEN nt.codigo_item IN ('J020','J029','J030','J038','J039') 
                     AND nt.tip_edad='A' AND nt.edad < 5
                THEN 1 ELSE 0 END) as faringo_men5a,
            SUM(CASE WHEN nt.codigo_item IN ('H650','H651','H660','H669') 
                     AND nt.tip_edad='A' AND nt.edad < 5
                THEN 1 ELSE 0 END) as oma_men5a,
            SUM(CASE WHEN nt.codigo_item IN ('J129','J159','J189') 
                     AND nt.tip_edad='A' AND nt.edad < 5
                THEN 1 ELSE 0 END) as neumonia_men5a,
            SUM(CASE WHEN nt.codigo_item IN ('A369','A370','A371','A378','A379','J120','J121','J122','J123','J128','J13X','J14X','J150','J151','J152','J153','J154','J157','J158','J159','J160','J168')
                THEN 1 ELSE 0 END) as iras_compl,
            COUNT(*) as foni
        FROM {tbl} nt
        WHERE {where}
        GROUP BY nt.mes
        ORDER BY nt.mes
    """
    try:
        cur.execute(sql)
        rows = []
        keys = ['eda_acuosa_men1a','eda_acuosa_1a','eda_acuosa_2a','eda_acuosa_3a','eda_acuosa_4a',
                'ira_no_compl_men5a','faringo_men5a','oma_men5a','neumonia_men5a','iras_compl','foni']
        for r in cur.fetchall():
            row = {'mes': r[0]}
            for i, k in enumerate(keys):
                row[k] = r[i+1] or 0
            rows.append(row)
        return rows
    except Exception as e:
        print(f"Resumen query error: {e}")
        return []


def _reporte_iras_edas_2024(cur, esquema, anio, meses, filtros):
    """IRAS EDAS report matching ref HTML exactly using his_proceso_2024."""
    where = _build_cred_where(2024, meses, filtros)
    ie = _qcred_cols(cur, {'IE':'iras_edas_2024'}, where)

    # Query ALL CIE10 diagnosis data with ref age groups
    diag = _query_iras_ref(cur, 2024, filtros)

    # Query CPT procedure data (oxigenoterapia, oximetria, nebulizacion)
    proc_raw = _query_age_groups(cur, 2024, ['94799.02','94760','94664'], filtros)
    def _proc_sum(code, age_map):
        d = proc_raw.get(code, {})
        return {ref_k: d.get(db_k, 0) for ref_k, db_k in age_map.items()}
    oxi_map = {'men29d': 'men2m', '29d_59d': 'men2m', '2_11m': '2_11m', '1_4a': '1a', '5_11a': '5_11a'}
    sob_oxi_map = {'men29d': 'men2m', '29d_59d': 'men2m', '2_11m': '2_11m', '12_23m': '1a', '2a': '2a_4a', '3_4a': '2a_4a', '5_11a': '5_11a'}
    proc = {
        'oxigeno_ira': _proc_sum('94799.02', oxi_map),
        'oximetria_ira': _proc_sum('94760', oxi_map),
        'oxigeno_sob': _proc_sum('94799.02', sob_oxi_map),
        'nebulizacion_sob': _proc_sum('94664', sob_oxi_map),
    }

    # Query Resumen Acumulado
    resumen = _query_resumen_mensual(cur, 2024, filtros)

    from html_report_builder import build_iras_edas_html
    tabla_html = build_iras_edas_html({
        'filtros': {**filtros, 'anio': anio},
        'anio': anio,
        'ie': ie,
        'diag': diag,
        'proc': proc,
        'resumen': resumen,
    })

    return {
        'tipo': 'formato_iras_edas', 'anio': anio, 'filtros': filtros, 'meses': meses,
        'paginas': [
            {
                'id': 'iras_edas', 'titulo': 'FORMATO IRAS - EDAS',
                'tabla_html': tabla_html,
            },
        ]
    }


def _build_cred_suplementacion(cred):
    """Build suplementacion sections from cred2024 data dict (C1/C2/C4 prefixed)."""
    v = lambda k: cred.get(k, 0) or 0
    secciones = []

    def _e(titulo, cols):
        items = []
        total = 0
        for label, col in cols:
            val = v(col)
            items.append({'INDICADOR': label, 'TOTAL': val})
            total += val
        return {'titulo': titulo, 'columnas': ['INDICADOR', 'TOTAL'], 'filas': items, 'total': total}

    secciones.append(_e('1. Sup. Preventiva <6m', [
        ('RN Bajo Peso 1ra', 'C1_ta_suplem_bpn'),
        ('4m Sano', 'C1_suplem_4m_sano'),
        ('5m Sano', 'C1_suplem_5m_sano'),
        ('TA 5-6m Sano', 'C1_ta_suplem_5_6m_sano'),
    ]))

    for grupo, suf in [('6-11m','6_11m'),('1a','1a'),('2a','2a'),('3a','3a'),('4a','4a'),('5-11a','5_11a')]:
        secciones.append(_e(f'Multimicronutrientes {grupo}', [
            (f'1ra Entrega', f'C1_suplem_1ra_{suf}'),
            (f'2da Entrega', f'C1_suplem_2da_{suf}'),
            (f'3ra Entrega', f'C1_suplem_3ra_{suf}'),
            (f'4ta Entrega', f'C1_suplem_4ta_{suf}'),
            (f'5ta Entrega', f'C1_suplem_5ta_{suf}'),
            (f'6ta Entrega', f'C1_suplem_6ta_{suf}'),
            (f'TA', f'C1_ta_suplem_{suf}'),
        ]))

    secciones.append(_e('4. Vitamina A', [
        ('VA1 6-11m', 'C1_va1_6_11m'),
        ('VA1 1a', 'C1_va1_1a'), ('VA2 1a', 'C1_va2_1a'),
        ('VA1 2a', 'C1_va1_2a'), ('VA2 2a', 'C1_va2_2a'),
        ('VA1 3a', 'C1_va1_3a'), ('VA2 3a', 'C1_va2_3a'),
        ('VA1 4a', 'C1_va1_4a'), ('VA2 4a', 'C1_va2_4a'),
    ]))

    secciones.append(_e('9. Sup. Hierro MEF/Gestantes/Puerperas', [
        ('Gestante 1', 'C1_suplem_gest1'), ('Gestante 2', 'C1_suplem_gest2'),
        ('Gestante 3', 'C1_suplem_gest3'), ('Gestante 4', 'C1_suplem_gest4'),
        ('Gestante 5', 'C1_suplem_gest5'), ('Gestante 6', 'C1_suplem_gest6'),
        ('Gestante TA', 'C1_suplem_gest_ta'),
        ('Pu\u00e9rpera 1', 'C1_suplem_puer1'), ('Pu\u00e9rpera 2', 'C1_suplem_puer2'),
        ('Pu\u00e9rpera 3', 'C1_suplem_puer3'), ('Pu\u00e9rpera 4', 'C1_suplem_puer4'),
        ('Pu\u00e9rpera 5', 'C1_suplem_puer5'), ('Pu\u00e9rpera 6', 'C1_suplem_puer6'),
        ('Pu\u00e9rpera 7', 'C1_suplem_puer7'), ('Pu\u00e9rpera TA', 'C1_suple_puer_ta'),
        ('MEF 1', 'C1_suplem_mef1'), ('MEF 2', 'C1_suplem_mef2'),
        ('MEF 3', 'C1_suplem_mef3'), ('MEF TA', 'C1_suplem_mef_ta'),
        ('Adol. 12-17 1', 'C1_suplem1_12_17'), ('Adol. 12-17 2', 'C1_suplem2_12_17'),
        ('Adol. 12-17 3', 'C1_suplem3_12_17'), ('Adol. 12-17 TA', 'C1_suplem4_12_17ta'),
    ]))

    secciones.append(_e('6. DOSAJE DE HEMOGLOBINA', [
        ('1er Dosaje BPN', 'C2_primer_dosaje_hb_bpn'),
        ('2do Dosaje BPN', 'C2_segundo_dosaje_hb_bpn'),
        ('HB 6-11m 1er', 'C2_hb_6_11m_primer'),
        ('HB 6-11m 2do', 'C2_hb_6_11m_segundo'),
        ('HB 12-23m 1er', 'C2_hb_12_23m_primer'),
        ('HB 12-23m 2do', 'C2_hb_12_23m_segundo'),
        ('HB 12-23m 3er', 'C2_hb_12_23m_tercer'),
        ('HB 24-35m 1er', 'C2_hb_24_35m_primer'),
        ('HB 24-35m 2do', 'C2_hb_24_35m_segundo'),
        ('HB 36-59m 1er', 'C2_hb_36_59m_primer'),
        ('HB 36-59m 2do', 'C2_hb_36_59m_segundo'),
        ('HB 5-11a', 'C2_hb_5_11a'),
        ('HB Adolesc. 1er', 'C2_hb_adolescente_primer'),
        ('HB Adolesc. 2do', 'C2_hb_adolescente_segundo'),
        ('HB Gestante 1er', 'C2_hb_gestante_primer'),
        ('HB Gestante 2do', 'C2_hb_gestante_segundo'),
        ('HB Gestante 3er', 'C2_hb_gestante_tercero'),
        ('HB MEF', 'C2_hb_mef'),
        ('HB Pu\u00e9rpera', 'C2_hb_puerpera'),
    ]))

    secciones.append(_e('7. CONSULTA NUTRICIONAL', [
        ('Cons. Nutr. BPN', 'C4_consulta_nutric_bpn'),
        ('Cons. Nutr. 4-5m', 'C4_consulta_nutric1_4_5m'),
        ('Cons. Nutr. 6-11m', 'C4_consulta_nutric_1_6_11m'),
        ('Cons. Nutr. 1a', 'C4_consulta_nutric_1_1a'),
        ('Cons. Nutr. 2a', 'C4_consulta_nutric_1_2a'),
        ('Cons. Nutr. 3a', 'C4_consulta_nutric_1_3a'),
        ('Cons. Nutr. 4a', 'C4_consulta_nutric_1_4a'),
        ('Cons. Nutr. 5-11a', 'C4_consulta_nutric_1_5_11a'),
        ('Cons. Nutr. Gestante 1', 'C1_cons_nutric1_gest'),
        ('Cons. Nutr. Gestante 2', 'C1_cons_nutric2_gest'),
        ('Cons. Nutr. Puerpera 1', 'C1_consulta_nutric1_gest'),
        ('Cons. Nutr. MEF 1', 'C1_cons_mef1'),
        ('Cons. Nutr. MEF 2', 'C1_cons_mef2'),
        ('Cons. Nutr. Adolesc. 1', 'C1_cons_nutri1_12_17'),
        ('Cons. Nutr. Adolesc. 2', 'C1_cons_nutri2_12_17'),
        ('Cons. Nutr. Adolesc. 3', 'C1_cons_nutri3_12_17'),
    ]))

    return secciones


def _build_cred_tx_anemia(cred):
    v = lambda k: cred.get(k, 0) or 0
    secciones = []

    def _e(titulo, cols):
        items = []
        total = 0
        for label, col in cols:
            val = v(col)
            items.append({'INDICADOR': label, 'TOTAL': val})
            total += val
        return {'titulo': titulo, 'columnas': ['INDICADOR', 'TOTAL'], 'filas': items, 'total': total}

    for ane_suf in ['6_11m', '1a', '2a', '3a', '4a']:
        secciones.append(_e(f'Adm. Tx. Sulfato Ferroso {ane_suf}', [
            (f'1ra', f'C1_suplem_1ra_{ane_suf}'),
            (f'2da', f'C1_suplem_2da_{ane_suf}'),
            (f'3ra', f'C1_suplem_3ra_{ane_suf}'),
            (f'4ta', f'C1_suplem_4ta_{ane_suf}'),
            (f'5ta', f'C1_suplem_5ta_{ane_suf}'),
            (f'6ta', f'C1_suplem_6ta_{ane_suf}'),
            (f'TA', f'C1_ta_suplem_{ane_suf}'),
        ]))

    secciones.append(_e('2. DOSAJE HEMOGLOBINA CONTROL', [
        ('1er Dosaje BPN', 'C2_primer_dosaje_hb_bpn'),
        ('2do Dosaje BPN', 'C2_segundo_dosaje_hb_bpn'),
        ('HB 6-11m 1er', 'C2_hb_6_11m_primer'),
        ('HB 6-11m 2do', 'C2_hb_6_11m_segundo'),
        ('HB 12-23m 1er', 'C2_hb_12_23m_primer'),
        ('HB 12-23m 2do', 'C2_hb_12_23m_segundo'),
        ('HB 12-23m 3er', 'C2_hb_12_23m_tercer'),
        ('HB 24-35m 1er', 'C2_hb_24_35m_primer'),
        ('HB 24-35m 2do', 'C2_hb_24_35m_segundo'),
        ('HB 36-59m 1er', 'C2_hb_36_59m_primer'),
        ('HB 36-59m 2do', 'C2_hb_36_59m_segundo'),
        ('HB 5-11a', 'C2_hb_5_11a'),
        ('HB Adolesc. 1er', 'C2_hb_adolescente_primer'),
        ('HB Adolesc. 2do', 'C2_hb_adolescente_segundo'),
        ('HB Gestante 1er', 'C2_hb_gestante_primer'),
        ('HB Gestante 2do', 'C2_hb_gestante_segundo'),
        ('HB Gestante 3er', 'C2_hb_gestante_tercero'),
        ('HB MEF', 'C2_hb_mef'),
        ('HB Pu\u00e9rpera', 'C2_hb_puerpera'),
    ]))

    secciones.append(_e('3. CONSULTA MEDICA', [
        ('Anamnesis y Ex. F\u00edsico RN', 'C4_anamnesis_y_ex_fisico_rn_normal'),
        ('Evaluaci\u00f3n M\u00e9dica RN', 'C4_evaluacion_medica_rn'),
    ]))

    secciones.append(_e('4. CONSULTA NUTRICIONAL (Tx Anemia)', [
        ('Cons. Nutr. BPN', 'C4_consulta_nutric_bpn'),
        ('Cons. Nutr. 4-5m', 'C4_consulta_nutric1_4_5m'),
        ('Cons. Nutr. 6-11m 1', 'C4_consulta_nutric_1_6_11m'),
        ('Cons. Nutr. 1a 1', 'C4_consulta_nutric_1_1a'),
        ('Cons. Nutr. 2a 1', 'C4_consulta_nutric_1_2a'),
        ('Cons. Nutr. 3a 1', 'C4_consulta_nutric_1_3a'),
        ('Cons. Nutr. 4a 1', 'C4_consulta_nutric_1_4a'),
        ('Cons. Nutr. 5-11a 1', 'C4_consulta_nutric_1_5_11a'),
    ]))

    return secciones


# ============ REPORTE IRAS EDAS (dispatch) ============
def _reporte_iras_edas(cur, esquema, anio, meses, filtros):
    """Route to appropriate implementation based on year."""
    if str(anio) == '2024':
        try:
            return _reporte_iras_edas_2024(cur, esquema, anio, meses, filtros)
        except Exception as e:
            print(f"iras_edas_2024 tables not available: {e}")
            import traceback; traceback.print_exc()
            return _reporte_iras_edas_old(cur, esquema, anio, meses, filtros)
    return _reporte_iras_edas_old(cur, esquema, anio, meses, filtros)


def _reporte_iras_edas_old(cur, esquema, anio, meses, filtros):
    tabla = _resolve_tabla(anio, 'iras_edas')
    where = _build_where(anio, meses, filtros)
    qt = lambda t: _qtable(esquema, t)
    ace = _build_age_case()

    def _query_cie(cie_dict):
        rows = []
        for key, cfg in cie_dict.items():
            cs = "','".join(cfg['codes'])
            cur.execute(f"""
                SELECT {ace} as grupo_edad, COUNT(*) as total
                FROM {qt(tabla)} t
                WHERE {where} AND codigo_item IN ('{cs}')
                GROUP BY grupo_edad ORDER BY grupo_edad
            """)
            items = [{'label': r[0], 'valor': r[1]} for r in cur.fetchall()]
            total = sum(it['valor'] for it in items)
            rows.append({'diagnostico': cfg['label'], 'items': items, 'total': total})
        return rows

    rows_ira = _query_cie(CIE_IRAS)
    rows_sob = _query_cie(CIE_SOB_ASMA)
    rows_eda = _query_cie(CIE_EDAS)
    rows_anemia = _query_cie(CIE_ANEMIA)
    rows_parasitos = _query_cie(CIE_PARASITOSIS)
    rows_def = _query_cie(CIE_DEFUNCIONES)
    rows_sal = _query_cie(CIE_SAL_YODADA)

    secciones = [
        {'titulo': 'INFECCION RESPIRATORIA AGUDA (IRA)', 'diagnosticos': rows_ira},
        {'titulo': 'SOB / ASMA', 'diagnosticos': rows_sob},
        {'titulo': 'ENFERMEDAD DIARREICA AGUDA (EDA)', 'diagnosticos': rows_eda},
        {'titulo': 'ANEMIA', 'diagnosticos': rows_anemia},
        {'titulo': 'PARASITOSIS INTESTINAL', 'diagnosticos': rows_parasitos},
        {'titulo': 'DEFUNCIONES', 'diagnosticos': rows_def},
        {'titulo': 'CONSUMO DE SAL YODADA', 'diagnosticos': rows_sal},
    ]

    return {
        'tipo': 'formato_iras_edas', 'anio': anio, 'filtros': filtros, 'meses': meses,
        'paginas': [{
            'id': 'iras_edas', 'titulo': 'FORMATO IRAS - EDAS',
            'secciones': secciones
        }]
    }

# ============ EXPORTAR A EXCEL ============
@app.route('/api/reportes-minsa/exportar', methods=['POST'])
def reportes_minsa_exportar():
    data = request.json or {}
    rd = data.get('data', {})
    from io import BytesIO
    try:
        from openpyxl import Workbook
        from openpyxl.styles import Font, Alignment, Border, Side, PatternFill
    except ImportError:
        return jsonify({'error': 'openpyxl no instalado'}), 500

    wb = Workbook()
    bold = Font(bold=True, size=11)
    bold14 = Font(bold=True, size=14)
    center = Alignment(horizontal='center', vertical='center')
    thin = Border(
        left=Side(style='thin'), right=Side(style='thin'),
        top=Side(style='thin'), bottom=Side(style='thin')
    )
    header_fill = PatternFill(start_color='4472C4', end_color='4472C4', fill_type='solid')
    header_font = Font(bold=True, color='FFFFFF', size=10)
    total_fill = PatternFill(start_color='D9E2F3', end_color='D9E2F3', fill_type='solid')

    def style_header(ws, row, ncols):
        for c in range(1, ncols + 1):
            cell = ws.cell(row=row, column=c)
            cell.font = header_font
            cell.fill = header_fill
            cell.alignment = center
            cell.border = thin

    def style_range(ws, row_start, row_end, ncols):
        for r in range(row_start, row_end + 1):
            for c in range(1, ncols + 1):
                cell = ws.cell(row=r, column=c)
                cell.border = thin
                cell.alignment = center

    for pi, pagina in enumerate(rd.get('paginas', [])):
        ws = wb.create_sheet(title=pagina.get('titulo', f'Pagina{pi+1}')[:31]) if pi > 0 else wb.active
        if pi > 0:
            wb.active = ws
        else:
            ws.title = pagina.get('titulo', 'Reporte')[:31]

        r = 1
        # Title
        ws.cell(row=r, column=1, value=f'{pagina.get("titulo","")} - Aï¿½o {rd.get("anio","")}').font = bold14
        r += 2

        if pagina.get('id') == 'formato_nino':
            cols = pagina['columnas']
            # Header
            for ci, cn in enumerate(cols, 1):
                ws.cell(row=r, column=ci, value=cn)
            style_header(ws, r, len(cols))
            r += 1
            # Data
            for fila in pagina['filas']:
                for ci, cn in enumerate(cols, 1):
                    ws.cell(row=r, column=ci, value=fila.get(cn, ''))
                r += 1
            style_range(ws, 3, r-1, len(cols))
            # Totals
            totes = pagina.get('totales', {})
            for ci, cn in enumerate(cols, 1):
                cell = ws.cell(row=r, column=ci)
                if cn == 'EDADES':
                    cell.value = 'TOTALES'
                else:
                    cell.value = totes.get(cn, 0)
                cell.font = bold
                cell.fill = total_fill
                cell.border = thin
            r += 2
            # Sub-secciones
            for sec in pagina.get('secciones', []):
                if sec.get('tipo') == 'side_by_side':
                    ws.cell(row=r, column=1, value=sec.get('titulo','')).font = bold
                    r += 1
                    izq = sec.get('izquierda', {})
                    der = sec.get('derecha', {})
                    start_r = r
                    # Left panel
                    ws.cell(row=r, column=1, value=izq.get('titulo','')).font = bold
                    if izq.get('columnas') and izq.get('filas'):
                        r += 1
                        cn_i = izq.get('columnas', ['INDICADOR','TOTAL'])
                        for ci, cn in enumerate(cn_i, 1):
                            ws.cell(row=r, column=ci, value=cn)
                        style_header(ws, r, len(cn_i))
                        r += 1
                        ld = r
                        for item in izq.get('filas', []):
                            for ci, cn in enumerate(cn_i, 1):
                                ws.cell(row=r, column=ci, value=item.get(cn, ''))
                            r += 1
                        style_range(ws, ld-1, r-1, len(cn_i))
                    # Right panel  
                    ws.cell(row=r, column=8, value=der.get('titulo','')).font = bold
                    if der.get('columnas') and der.get('filas'):
                        r_col = r
                        cn_d = der.get('columnas', ['INDICADOR','TOTAL'])
                        for ci, cn in enumerate(cn_d, 8):
                            ws.cell(row=r_col, column=ci, value=cn)
                        for ci, cn in enumerate(cn_d, 8):
                            cell = ws.cell(row=r_col, column=ci)
                            cell.font = header_font
                            cell.fill = header_fill
                            cell.alignment = center
                            cell.border = thin
                        r_col += 1
                        for item in der.get('filas', []):
                            for ci, cn in enumerate(cn_d, 8):
                                ws.cell(row=r_col, column=ci, value=item.get(cn, ''))
                            r_col += 1
                        style_range(ws, r+1, r_col-1, 8+len(cn_d)-1)
                        r = max(r, r_col)
                    r += 1
                    continue
                if sec.get('tipo') == 'grid' and sec.get('grid'):
                    g = sec['grid']
                    headers = g.get('headers', [])
                    for ci, cn in enumerate(headers, 1):
                        ws.cell(row=r, column=ci, value=cn)
                    style_header(ws, r, len(headers))
                    r += 1
                    data_start = r
                    for row_data in g.get('rows', []):
                        for ci, val in enumerate(row_data, 1):
                            ws.cell(row=r, column=ci, value=val)
                        r += 1
                    totales = g.get('totales', [])
                    if totales:
                        for ci, val in enumerate(totales, 1):
                            cell = ws.cell(row=r, column=ci, value=val)
                            cell.font = bold
                            cell.fill = total_fill
                            cell.border = thin
                        r += 1
                    style_range(ws, data_start - 1, r - 1, len(headers))
                    r += 1
                    continue
                colnames = sec.get('columnas', [])
                if not colnames:
                    continue
                for ci, cn in enumerate(colnames, 1):
                    ws.cell(row=r, column=ci, value=cn)
                style_header(ws, r, len(colnames))
                r += 1
                data_start = r
                items = sec.get('filas', [])
                for item in items:
                    for ci, cn in enumerate(colnames, 1):
                        ws.cell(row=r, column=ci, value=item.get(cn, ''))
                    r += 1
                totes = sec.get('totales', {})
                if totes:
                    for ci, cn in enumerate(colnames, 1):
                        cell = ws.cell(row=r, column=ci)
                        if cn == colnames[0]:
                            cell.value = 'TOTALES'
                        else:
                            cell.value = totes.get(cn, 0)
                        cell.font = bold
                        cell.fill = total_fill
                        cell.border = thin
                    r += 1
                style_range(ws, data_start - 1, r - 1, len(colnames))
                r += 1

        elif pagina.get('id') in ('suplementacion', 'tx_anemia'):
            for sec in pagina.get('secciones', []):
                ws.cell(row=r, column=1, value=sec.get('titulo','')).font = bold
                r += 1
                if sec.get('tipo') == 'grid' and sec.get('grid'):
                    g = sec['grid']
                    headers = g.get('headers', [])
                    for ci, cn in enumerate(headers, 1):
                        ws.cell(row=r, column=ci, value=cn)
                    style_header(ws, r, len(headers))
                    r += 1
                    data_start = r
                    for row_data in g.get('rows', []):
                        for ci, val in enumerate(row_data, 1):
                            ws.cell(row=r, column=ci, value=val)
                        r += 1
                    totales = g.get('totales', [])
                    if totales:
                        for ci, val in enumerate(totales, 1):
                            cell = ws.cell(row=r, column=ci, value=val)
                            cell.font = bold
                            cell.fill = total_fill
                            cell.border = thin
                        r += 1
                    style_range(ws, data_start - 1, r - 1, len(headers))
                    r += 1
                    continue
                colnames = sec.get('columnas', ['INDICADOR', 'TOTAL'])
                for ci, cn in enumerate(colnames, 1):
                    ws.cell(row=r, column=ci, value=cn)
                style_header(ws, r, len(colnames))
                r += 1
                data_start = r
                items = sec.get('filas', [])
                for item in items:
                    for ci, cn in enumerate(colnames, 1):
                        ws.cell(row=r, column=ci, value=item.get(cn, ''))
                    r += 1
                totes = sec.get('totales', {})
                if sec.get('total') is not None:
                    ws.cell(row=r, column=1, value='TOTAL').font = bold
                    ws.cell(row=r, column=2, value=sec['total']).font = bold
                    ws.cell(row=r, column=1).fill = total_fill
                    ws.cell(row=r, column=2).fill = total_fill
                    r += 1
                elif totes:
                    for ci, cn in enumerate(colnames, 1):
                        cell = ws.cell(row=r, column=ci)
                        if cn == colnames[0]:
                            cell.value = 'TOTALES'
                        else:
                            cell.value = totes.get(cn, 0)
                        cell.font = bold
                        cell.fill = total_fill
                        cell.border = thin
                    r += 1
                style_range(ws, data_start - 1, r - 1, len(colnames))
                r += 1

        elif pagina.get('id') == 'iras_edas':
            for sec in pagina.get('secciones', []):
                ws.cell(row=r, column=1, value=sec.get('titulo','')).font = bold
                r += 1
                for diag in sec.get('diagnosticos', []):
                    ws.cell(row=r, column=1, value=diag['diagnostico']).font = Font(bold=True, italic=True)
                    r += 1
                    if diag.get('items'):
                        ws.cell(row=r, column=2, value='Edad')
                        ws.cell(row=r, column=3, value='Total')
                        style_header(ws, r, 2)
                        r += 1
                        for item in diag['items']:
                            ws.cell(row=r, column=2, value=item.get('label',''))
                            ws.cell(row=r, column=3, value=item.get('valor',0))
                            r += 1
                    ws.cell(row=r, column=2, value=f"Total {diag['diagnostico']}:").font = bold
                    ws.cell(row=r, column=3, value=diag.get('total',0)).font = bold
                    r += 1
                r += 1

    # Remove default sheet if we created a named one
    if 'Reporte' in wb.sheetnames and len(wb.sheetnames) > 1:
        del wb['Reporte']

    buf = BytesIO()
    wb.save(buf)
    buf.seek(0)
    from flask import Response as FlaskResponse
    return FlaskResponse(
        buf.getvalue(),
        mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        headers={'Content-Disposition': 'attachment;filename=reporte_minsa.xlsx'}
    )

# ---------- Filesystem (native dialogs) ----------
@app.route('/api/fs/select-folder', methods=['POST'])
def fs_select_folder():
    """Abre el dialogo nativo del SO en un proceso separado usando selector_carpeta.py."""
    try:
        script = str(SCRIPTS_BI / 'selector_carpeta.py')
        if getattr(sys, 'frozen', False):
            cmd = [sys.executable, '--run-script', script]
        else:
            cmd = [sys.executable, script]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        carpeta = result.stdout.strip()
        if carpeta:
            return jsonify({'path': carpeta})
        return jsonify({'path': ''})
    except subprocess.TimeoutExpired:
        return jsonify({'path': '', 'error': 'timeout'}), 408
    except Exception as e:
        return jsonify({'path': '', 'error': str(e)}), 500

# ---------- Vista Previa (standalone HTML) ----------
@app.route('/api/reportes-minsa/vista-previa', methods=['GET'])
def reportes_minsa_vista_previa():
    """Devuelve el reporte como pÃ¡gina HTML standalone para vista previa directa."""
    try:
        anio = request.args.get('anio', '2024', type=str)
        meses_str = request.args.get('meses', '1,2,3,4,5,6,7,8,9,10,11,12')
        meses = [int(m) for m in meses_str.split(',') if m.strip().isdigit()]
        conn = _db_cursor()
        cur = conn.cursor()
        esquema = _get_esquema()
        try:
            data = _reporte_completo_cred(cur, esquema, anio, meses, {})
        finally:
            cur.close()
            conn.close()
        if not data or 'paginas' not in data:
            return '<h1>Error: No se pudo generar el reporte</h1>', 500, {'Content-Type': 'text/html; charset=utf-8'}
        pages_html = ''
        for i, p in enumerate(data['paginas']):
            if p.get('tabla_html'):
                pages_html += f'<h2 style="text-align:center;margin:10px 0;">{p.get("titulo", f"PÃ¡gina {i+1}")}</h2>'
                pages_html += p['tabla_html']
                if i < len(data['paginas']) - 1:
                    pages_html += '<hr style="margin:20px 0;border:1px dashed #ccc;">'
        full = f'''<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Vista Previa - CRED {anio}</title>
<style>
  body {{ font-family: Arial, sans-serif; margin: 0; padding: 10px; background: #fff; color: #000; }}
</style>
</head>
<body>
{pages_html}
</body>
</html>'''
        return full, 200, {'Content-Type': 'text/html; charset=utf-8'}
    except Exception as e:
        import traceback
        return f'<h1>Error</h1><pre>{traceback.format_exc()}</pre>', 500, {'Content-Type': 'text/html; charset=utf-8'}

# ---------- Main ----------
if __name__ == '__main__':
    debug_mode = os.environ.get('FLASK_DEBUG', '0') == '1'
    app.run(host='0.0.0.0', port=5000, debug=debug_mode, threaded=True)
```

---

## 20. CÓDIGO FUENTE COMPLETO - modules.js (Módulo Formatos MINSA)

```javascript
// ==================== FORMATOS MINSA ====================
var RM_DATA = null;
var RM_TAB_ACTUAL = 0;

async function rmInit() {
    try {
        const r = await fetch('/api/reportes-minsa/filtros');
        const d = await r.json();
        // Cargar aÃ±os
        var anioSel = document.getElementById('rm-anio');
        var anios = d.anios_disponibles || ['2024','2025','2026'];
        anioSel.innerHTML = '';
        anios.forEach(function(a) {
            anioSel.innerHTML += '<option>' + a + '</option>';
        });
        // Cargar selects
        ['red','microred','nombre_establecimiento','provincia','distrito'].forEach(function(k) {
            var sel = document.getElementById(k === 'nombre_establecimiento' ? 'rm-establecimiento' : 'rm-' + k);
            var items = d[k] || [];
            if (items.length > 100 && k === 'nombre_establecimiento') items = items.slice(0, 100);
            sel.innerHTML = '<option value="">-- ' + (k.charAt(0).toUpperCase() + k.slice(1).replace('_',' ')) + ' (Todas) --</option>';
            items.forEach(function(v) {
                sel.innerHTML += '<option value="' + v.replace(/"/g,'&quot;') + '">' + v + '</option>';
            });
            if (items.length > 100 && k === 'nombre_establecimiento') {
                sel.innerHTML += '<option value="__mas__">... (+' + (d[k].length - 100) + ' m&aacute;s)</option>';
            }
        });
    } catch (e) {
        toast('Error cargando filtros: ' + e.message, 'error');
    }
}

function rmTipoChange() {
    document.getElementById('rm-resultado').innerHTML = '<p style="color:var(--text-muted);text-align:center;padding:40px;">Tipo cambiado. Presione <b>PROCESAR</b></p>';
    document.getElementById('rm-exportar').disabled = true;
}

function rmGetMeses() {
    var checked = [];
    document.querySelectorAll('#rm-meses input[type=checkbox]:checked').forEach(function(cb) {
        checked.push(parseInt(cb.value));
    });
    return checked;
}

async function rmEjecutar() {
    var btn = document.getElementById('rm-procesar');
    btn.disabled = true;
    btn.textContent = '\u23f3 Procesando...';
    document.getElementById('rm-exportar').disabled = true;
    var tipo = document.getElementById('rm-tipo').value;
    var anio = document.getElementById('rm-anio').value;
    var meses = rmGetMeses();
    if (meses.length === 0) { toast('Seleccione al menos un mes', 'warning'); btn.disabled = false; btn.textContent = '\u25b6 PROCESAR'; return; }
    var body = { tipo: tipo, anio: anio, meses: meses };
    ['red','microred','nombre_establecimiento','provincia','distrito'].forEach(function(k) {
        var v = document.getElementById(k === 'nombre_establecimiento' ? 'rm-establecimiento' : 'rm-' + k).value;
        if (v && v !== '__mas__') body[k] = v;
    });
    try {
        const r = await fetch('/api/reportes-minsa/ejecutar', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(body)
        });
        const d = await r.json();
        if (d.error) { toast('Error: ' + d.error, 'error'); document.getElementById('rm-resultado').innerHTML = '<p style="color:#E74C3C;">' + d.error + '</p>'; return; }
        RM_DATA = d;
        RM_TAB_ACTUAL = 0;
        rmRender(d);
        document.getElementById('rm-exportar').disabled = false;
        toast('Reporte generado', 'success');
    } catch (e) {
        toast('Error: ' + e.message, 'error');
    } finally {
        btn.disabled = false;
        btn.textContent = '\u25b6 PROCESAR';
    }
}

function rmRender(d) {
    var el = document.getElementById('rm-resultado');
    var html = '<div style="margin-bottom:8px;font-size:11px;color:var(--text-muted);">';
    html += 'Reporte: <b>' + d.tipo + '</b> | A&ntilde;o: ' + d.anio + ' | Meses: ' + (d.meses || []).join(', ');
    var f = d.filtros || {};
    if (Object.keys(f).length) html += ' | Filtros: ' + Object.keys(f).map(function(k){return k + '=' + f[k];}).join(', ');
    html += '</div>';

    var paginas = d.paginas || [];
    if (paginas.length > 1) {
        html += '<div class="rm-tabs" style="display:flex;gap:4px;margin-bottom:8px;border-bottom:2px solid var(--border);padding-bottom:4px;">';
        paginas.forEach(function(p, i) {
            var active = i === RM_TAB_ACTUAL ? ' style="background:var(--accent);color:#fff;border-color:var(--accent);"' : '';
            html += '<button class="rm-tab-btn" data-idx="' + i + '"' + active + ' style="padding:4px 12px;border:1px solid var(--border);border-radius:4px;cursor:pointer;background:var(--bg);font-size:11px;' + (i === RM_TAB_ACTUAL ? 'background:var(--accent);color:#fff;border-color:var(--accent);' : '') + '">' + (p.titulo || p.id || 'P\u00e1gina ' + (i+1)) + '</button>';
        });
        html += '</div>';
    }

    // Inject report CSS into <head> (extract from first page's tabla_html)
    if (paginas.length > 0 && paginas[0].tabla_html) {
        var match = paginas[0].tabla_html.match(/<style>([\s\S]*?)<\/style>/);
        if (match) {
            var cssId = 'rm-report-css';
            if (!document.getElementById(cssId)) {
                var s = document.createElement('style');
                s.id = cssId;
                s.textContent = match[1];
                document.head.appendChild(s);
            }
        }
    }

    // Render active page
    var p = paginas[RM_TAB_ACTUAL];
    if (!p) { el.innerHTML = '<p style="color:var(--text-muted);padding:40px;">Sin datos</p>'; return; }
    html += rmRenderPagina(p);
    el.innerHTML = html;

    // Bind tab events
    document.querySelectorAll('.rm-tab-btn').forEach(function(btn) {
        btn.onclick = function() {
            RM_TAB_ACTUAL = parseInt(this.dataset.idx);
            rmRender(RM_DATA);
        };
    });
}

function rmRenderPagina(p) {
    var h = '<div class="rm-pagina">';
    if (p.tabla_html && p.tabla_html.length > 0) {
        // DEBUG: write raw HTML to console
        console.log('tabla_html exists, length=' + p.tabla_html.length + ', startsWith=' + p.tabla_html.substring(0, 50));
        // Render directly without stripping - use as-is
        h += p.tabla_html;
    } else if (p.id === 'formato_nino') {
        var cols = p.columnas || [];
        h += '<div style="overflow-x:auto;"><table class="data-table" style="font-size:10px;width:100%;white-space:nowrap;"><thead><tr>';
        cols.forEach(function(c) { h += '<th style="text-align:center;">' + c + '</th>'; });
        h += '</tr></thead><tbody>';
        (p.filas || []).forEach(function(fila) {
            h += '<tr>';
            cols.forEach(function(c) {
                var v = fila[c];
                if (v != null && typeof v === 'number') v = v.toLocaleString();
                h += '<td style="text-align:center;">' + (v || '') + '</td>';
            });
            h += '</tr>';
        });
        var totes = p.totales || {};
        h += '<tr style="font-weight:bold;background:var(--accent-light, #f0f4ff);">';
        cols.forEach(function(c) {
            if (c === 'EDADES') { h += '<td style="text-align:center;font-weight:bold;">TOTALES</td>'; }
            else { var v = totes[c]; if (v != null && typeof v === 'number') v = v.toLocaleString(); h += '<td style="text-align:center;font-weight:bold;">' + (v || '0') + '</td>'; }
        });
        h += '</tr></tbody></table></div>';
        // Sub-secciones
        (p.secciones || []).forEach(function(sec) { h += rmRenderSeccion(sec); });
    } else if (p.secciones) {
        p.secciones.forEach(function(sec) { h += rmRenderSeccion(sec); });
    }
    h += '</div>';
    return h;
}

function rmRenderSeccion(sec) {
    var h = '<div class="rm-seccion" style="margin-bottom:12px;"><h3 style="font-size:13px;margin:8px 0 4px;color:var(--accent);">' + (sec.titulo || '') + '</h3>';
    if (sec.tipo === 'side_by_side' && sec.izquierda && sec.derecha) {
        h += '<table style="width:100%;border-collapse:collapse;"><tr>';
        h += '<td style="width:50%;vertical-align:top;padding-right:6px;">' + rmRenderSeccion(sec.izquierda) + '</td>';
        h += '<td style="width:50%;vertical-align:top;padding-left:6px;">' + rmRenderSeccion(sec.derecha) + '</td>';
        h += '</tr></table></div>';
        return h;
    }
    if (sec.tipo === 'grid' && sec.grid) {
        var g = sec.grid;
        h += '<div style="overflow-x:auto;"><table class="data-table" style="font-size:10px;width:auto;white-space:nowrap;"><thead><tr>';
        g.headers.forEach(function(c) { h += '<th style="text-align:center;">' + c + '</th>'; });
        h += '</tr></thead><tbody>';
        g.rows.forEach(function(row) {
            h += '<tr>';
            row.forEach(function(v, i) {
                if (i > 0 && typeof v === 'number') v = v.toLocaleString();
                h += '<td style="text-align:center;">' + (v || '') + '</td>';
            });
            h += '</tr>';
        });
        if (g.totales) {
            h += '<tr style="font-weight:bold;border-top:2px solid var(--border);">';
            g.totales.forEach(function(v, i) {
                if (i > 0 && typeof v === 'number') v = v.toLocaleString();
                h += '<td style="text-align:center;">' + (v || '') + '</td>';
            });
            h += '</tr>';
        }
        h += '</tbody></table></div></div>';
        return h;
    }
    if (sec.columnas && sec.filas) {
        h += '<table class="data-table" style="font-size:11px;width:100%;"><thead><tr>';
        sec.columnas.forEach(function(c) { h += '<th style="text-align:center;">' + c + '</th>'; });
        h += '</tr></thead><tbody>';
        sec.filas.forEach(function(item) {
            h += '<tr>';
            sec.columnas.forEach(function(c, ci) {
                var v = null;
                if (item[c] != null) v = item[c];
                else if (item[c.toLowerCase()] != null) v = item[c.toLowerCase()];
                else if (ci === 0) v = item['label'] != null ? item['label'] : item['nombre'] || '';
                else if (ci === 1) v = item['valor'] != null ? item['valor'] : item['total'] || 0;
                if (v != null && typeof v === 'number') v = v.toLocaleString();
                h += '<td style="text-align:center;">' + (v != null ? v : '') + '</td>';
            });
            h += '</tr>';
        });
        var totes = sec.totales || {};
        if (sec.total != null) {
            h += '<tr style="font-weight:bold;border-top:2px solid var(--border);"><td>TOTAL</td><td style="text-align:center;">' + sec.total.toLocaleString() + '</td></tr>';
        } else if (Object.keys(totes).length) {
            h += '<tr style="font-weight:bold;background:var(--accent-light, #f0f4ff);">';
            sec.columnas.forEach(function(c) {
                if (c === sec.columnas[0]) { h += '<td style="text-align:center;">TOTALES</td>'; }
                else { var v = totes[c]; if (v != null && typeof v === 'number') v = v.toLocaleString(); h += '<td style="text-align:center;">' + (v || '0') + '</td>'; }
            });
            h += '</tr>';
        }
        h += '</tbody></table></div>';
    } else if (sec.diagnosticos) {
        sec.diagnosticos.forEach(function(diag) {
            h += '<div style="margin:6px 0 4px 12px;"><b>' + diag.diagnostico + '</b>';
            if (diag.items && diag.items.length) {
                h += '<table class="data-table" style="font-size:10px;width:auto;margin:2px 0 4px;"><thead><tr><th>Edad</th><th>Total</th></tr></thead><tbody>';
                diag.items.forEach(function(item) { h += '<tr><td>' + item.label + '</td><td style="text-align:center;">' + (item.valor != null ? item.valor.toLocaleString() : '') + '</td></tr>'; });
                h += '</tbody></table>';
            }
            h += '<div style="font-size:11px;font-weight:bold;">Total: ' + (diag.total != null ? diag.total.toLocaleString() : '0') + '</div></div>';
        });
    }
    h += '</div>';
    return h;
}

async function rmExportar() {
    if (!RM_DATA) { toast('No hay datos para exportar', 'warning'); return; }
    try {
        const r = await fetch('/api/reportes-minsa/exportar', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({data: RM_DATA})
        });
        if (!r.ok) { toast('Error al exportar', 'error'); return; }
        var blob = await r.blob();
        var url = URL.createObjectURL(blob);
        var a = document.createElement('a');
        a.href = url;
        a.download = 'reporte_minsa.xlsx';
        a.click();
        URL.revokeObjectURL(url);
        toast('Excel descargado', 'success');
    } catch (e) {
        toast('Error: ' + e.message, 'error');
    }
}

// ==================== NAV HOOKS ====================
document.querySelectorAll('.nav-btn[data-module]').forEach(function(b) {
    b.addEventListener('click', function() {
        var m = this.dataset.module;
        if (m === 'poblacion') { pobSwitchTab('pn'); }
        if (m === 'mapa') { setTimeout(mapaInit, 300); }
        if (m === 'dashboards') { setTimeout(function() { dashCambiar('resumen'); }, 100); }
        if (m === 'reportes-minsa') { setTimeout(rmInit, 100); }
    });
});

window.addEventListener('resize', function() {
    if (MAPA) MAPA.invalidateSize();
});

// ==================== INIT ====================
function initModules() {
    pnRutaCargar();
    cnvRutaCargar();
    document.getElementById('pn-ruta-carpeta').addEventListener('input', pnRutaGuardar);
    document.getElementById('cnv-ruta-carpeta').addEventListener('input', cnvRutaGuardar);
    setTimeout(pnStatus, 500);
    setTimeout(cnvStatus, 700);
    setTimeout(function() { dashCambiar('resumen'); }, 1000);
}
setTimeout(initModules, 1500);
```

---

## 21. CÓDIGO FUENTE COMPLETO - style.css (Estilos Reporte MINSA)

```css
/* ===== CRED / IRAS-EDAS REPORT STYLES (from reference HTML) ===== */
.page {
    width: 100%;
    max-width: 1400px;
    margin: 0 auto;
    padding: 10px;
}
.page {
    width: 100%;
    max-width: 1400px;
    margin: 0 auto;
    padding: 10px;
    overflow: auto;
}
.header { text-align: center; margin-bottom: 6px; }
.header h2 { font-size: 11px; font-weight: bold; text-transform: uppercase; }
.header h3 { font-size: 10px; font-weight: bold; text-transform: uppercase; }
.header h4 { font-size: 11px; font-weight: bold; text-transform: uppercase; color: #2E75B6; margin-top: 2px; }

.filter-row {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 8px;
    font-size: 9px;
    margin-bottom: 6px;
    padding: 4px 0;
    border-top: 1px solid #4472C4;
    border-bottom: 1px solid #4472C4;
}
.filter-row2 {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    gap: 8px;
    font-size: 9px;
    margin-bottom: 6px;
    padding: 4px 0;
    border-bottom: 1px solid #4472C4;
}
.filter-cell { display: flex; flex-direction: column; }
.filter-cell label { font-weight: bold; color: #2E75B6; }
.filter-cell span { border-bottom: 1px solid #9DC3E6; }

.section-title {
    background: #4472C4;
    color: #fff;
    font-weight: bold;
    font-size: 10px;
    padding: 3px 6px;
    text-transform: uppercase;
    margin-bottom: 2px;
}
.sub-section-title {
    background: #D6E4F7;
    font-weight: bold;
    font-size: 9px;
    padding: 2px 6px;
    margin-bottom: 2px;
    border-left: 3px solid #4472C4;
}
.sub2-title {
    background: #F2F2F2;
    font-weight: bold;
    font-size: 9px;
    padding: 2px 6px;
    margin-bottom: 2px;
}

table {
    border-collapse: collapse;
    width: 100%;
    margin-bottom: 6px;
    font-size: 9px;
}
th, td {
    border: 1px solid #000;
    padding: 2px 4px;
    vertical-align: middle;
    text-align: center;
}
th {
    background: #BDD7EE;
    font-weight: bold;
    font-size: 8.5px;
}
.th-dark { background: #2E75B6; color: #fff; }
.th-medium { background: #9DC3E6; }
.th-green { background: #70AD47; color: #fff; }
.th-orange { background: #ED7D31; color: #fff; }

td.label-left { text-align: left; padding-left: 4px; }
td.label-indent { text-align: left; padding-left: 12px; font-size: 8.5px; }
td.nota { font-size: 7.5px; color: #595959; font-style: italic; text-align: left; padding-left: 4px; }
td.num { font-weight: bold; }
td.zero { color: #595959; }

.row-header { background: #DDEBF7; font-weight: bold; }
.row-sub { background: #F2F2F2; }
.row-total { background: #2E75B6; color: #fff; font-weight: bold; }

.dual-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 8px;
    margin-bottom: 6px;
}

td.diag { text-align: left; padding-left: 6px; background: #F2F2F2; font-size: 8.5px; }
td.diag-sub { text-align: left; padding-left: 14px; font-size: 8.5px; }
td.formula { text-align: left; padding-left: 4px; font-size: 7.5px; color: #595959; font-style: italic; }
.note-row td { background: #FFF2CC; font-size: 8px; text-align: left; padding-left: 4px; border: 1px solid #BF9000; }

@media print {
    body { font-size: 8px; }
    .page { max-width: 100%; padding: 5px; }
    @page { size: A3 landscape; margin: 10mm; }
}
```

---

## 22. REFERENCIA HTML - referencia de formato exel cred.txt

```html
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>CRED - Informe Mensual del NiÃ±o(a) 2026 - DIRESA CUSCO</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: Arial, sans-serif; font-size: 10px; background: #fff; color: #000; }
  .page { width: 100%; max-width: 1400px; margin: 0 auto; padding: 10px; }

  .header { text-align: center; margin-bottom: 6px; }
  .header h2 { font-size: 11px; font-weight: bold; text-transform: uppercase; }
  .header h3 { font-size: 10px; font-weight: bold; text-transform: uppercase; }
  .header h4 { font-size: 11px; font-weight: bold; text-transform: uppercase; color: #2E75B6; margin-top: 2px; }

  .filter-row {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 8px;
    font-size: 9px;
    margin-bottom: 6px;
    padding: 4px 0;
    border-top: 1px solid #4472C4;
    border-bottom: 1px solid #4472C4;
  }
  .filter-row2 {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    gap: 8px;
    font-size: 9px;
    margin-bottom: 6px;
    padding: 4px 0;
    border-bottom: 1px solid #4472C4;
  }
  .filter-cell { display: flex; flex-direction: column; }
  .filter-cell label { font-weight: bold; color: #2E75B6; }
  .filter-cell span { border-bottom: 1px solid #9DC3E6; }

  .section-title {
    background: #4472C4;
    color: #fff;
    font-weight: bold;
    font-size: 10px;
    padding: 3px 6px;
    text-transform: uppercase;
    margin-bottom: 2px;
  }
  .sub-section-title {
    background: #D6E4F7;
    font-weight: bold;
    font-size: 9px;
    padding: 2px 6px;
    margin-bottom: 2px;
    border-left: 3px solid #4472C4;
  }
  .sub2-title {
    background: #F2F2F2;
    font-weight: bold;
    font-size: 9px;
    padding: 2px 6px;
    margin-bottom: 2px;
  }

  table {
    border-collapse: collapse;
    width: 100%;
    margin-bottom: 6px;
    font-size: 9px;
  }
  th, td {
    border: 1px solid #000;
    padding: 2px 4px;
    vertical-align: middle;
    text-align: center;
  }
  th {
    background: #BDD7EE;
    font-weight: bold;
    font-size: 8.5px;
  }
  .th-dark { background: #2E75B6; color: #fff; }
  .th-medium { background: #9DC3E6; }
  .th-green { background: #70AD47; color: #fff; }
  .th-orange { background: #ED7D31; color: #fff; }

  td.label-left { text-align: left; padding-left: 4px; }
  td.label-indent { text-align: left; padding-left: 12px; font-size: 8.5px; }
  td.nota { font-size: 7.5px; color: #595959; font-style: italic; text-align: left; padding-left: 4px; }
  td.num { font-weight: bold; }
  td.zero { color: #595959; }

  .row-header { background: #DDEBF7; font-weight: bold; }
  .row-sub { background: #F2F2F2; }
  .row-total { background: #2E75B6; color: #fff; font-weight: bold; }

  /* Two-column grid for parallel sections */
  .dual-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 8px;
    margin-bottom: 6px;
  }

  @media print {
    body { font-size: 8px; }
    .page { max-width: 100%; padding: 5px; }
    @page { size: A3 landscape; margin: 10mm; }
  }
</style>
</head>
<body>
<div class="page">

  <!-- Header -->
  <div class="header">
    <h2>DIRECCIÃ“N REGIONAL DE SALUD CUSCO</h2>
    <h3>DIRECCIÃ“N DE ESTADÃSTICA E INFORMÃTICA Y TELECOMUNICACIÃ“N</h3>
    <h4>INFORME MENSUAL DEL CUIDADO INTEGRAL DEL NIÃ‘O(A)</h4>
  </div>

  <!-- Filters row 1 -->
  <div class="filter-row">
    <div class="filter-cell"><label>RED DE SALUD:</label><span>(Todas)</span></div>
    <div class="filter-cell"><label>MICRO RED:</label><span>(Todas)</span></div>
    <div class="filter-cell"><label>PROVINCIA:</label><span>(Todas)</span></div>
    <div class="filter-cell"><label>AÃ‘O:</label><span>2026</span></div>
  </div>
  <!-- Filters row 2 -->
  <div class="filter-row2">
    <div class="filter-cell"><label>ESTABLECIMIENTO:</label><span>(Todas)</span></div>
    <div class="filter-cell"><label>DISTRITO:</label><span>(Todas)</span></div>
    <div class="filter-cell"><label>MES INICIO:</label><span>1</span></div>
    <div class="filter-cell"><label>MES FIN:</label><span>6</span></div>
    <div class="filter-cell"></div>
  </div>

  <!-- ===== CONTROL CRECIMIENTO Y DESARROLLO ===== -->
  <div class="section-title">CONTROL DE CRECIMIENTO Y DESARROLLO DEL NIÃ‘O(A)</div>
  <div class="sub-section-title">NÂ° de Controles de Crecimiento y Desarrollo de 0 a 11 AÃ±os</div>
  <table>
    <colgroup>
      <col style="width:14%">
      <col style="width:9%">
      <col style="width:7%">
      <col style="width:7%">
      <col style="width:7%">
      <col style="width:7%">
      <col style="width:7%">
      <col style="width:7%">
      <col style="width:7%">
      <col style="width:7%">
      <col style="width:7%">
      <col style="width:7%">
      <col style="width:7%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark">GRUPO ETAREO</th>
        <th class="th-dark">PROGRAMACIÃ“N</th>
        <th class="th-medium">1er Ctrl 29-59d</th>
        <th class="th-medium">2do Ctrl 60-89d</th>
        <th class="th-medium">3er Ctrl 90-119d</th>
        <th class="th-medium">4to Ctrl 120-149d</th>
        <th class="th-medium">5to Ctrl 180-209d</th>
        <th class="th-medium">6to Ctrl 210-239d</th>
        <th class="th-medium">7mo Ctrl 270-299d</th>
        <th class="th-medium">8vo Ctrl</th>
        <th class="th-medium">9no Ctrl</th>
        <th class="th-medium">10mo Ctrl</th>
        <th class="th-medium">11vo Ctrl</th>
      </tr>
    </thead>
    <tbody>
      <tr><td class="label-left">ReciÃ©n Nacido Sano 3-6d</td><td></td><td class="num">5,256</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
      <tr class="row-sub"><td class="label-left">ReciÃ©n Nacido Sano 7-13d</td><td></td><td class="num">278</td><td class="num">5,100</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
      <tr><td class="label-left">ReciÃ©n Nacido Sano 14-21d</td><td></td><td class="num">58</td><td class="num">479</td><td class="num">5,006</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
      <tr class="row-sub"><td class="label-left">ReciÃ©n Nacido Sano may_22d</td><td></td><td></td><td></td><td></td><td class="num">50</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
      <tr><td class="label-left">RN Bajo Peso</td><td></td><td class="num">126</td><td class="num">101</td><td class="num">90</td><td class="num">5</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
      <tr class="row-sub"><td class="label-left">RN Prematuro</td><td></td><td class="num">140</td><td class="num">117</td><td class="num">108</td><td class="num">12</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
      <tr><td class="label-left">&lt; 1 aÃ±o</td><td></td><td class="num">5,349</td><td class="num">4,768</td><td class="num">4,807</td><td class="num">5,126</td><td class="num">4,963</td><td class="num">4,682</td><td class="num">4,737</td><td class="num">84</td><td class="num">111</td><td class="num">88</td><td class="num">124</td></tr>
      <tr class="row-sub"><td class="label-left">1 aÃ±o</td><td></td><td class="num">4,951</td><td class="num">4,067</td><td class="num">3,742</td><td class="num">3,222</td><td class="num">94</td><td class="num">145</td><td></td><td></td><td></td><td></td><td></td></tr>
      <tr><td class="label-left">2 aÃ±os</td><td></td><td class="num">4,570</td><td class="num">3,498</td><td class="num">107</td><td class="num">122</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
      <tr class="row-sub"><td class="label-left">3 aÃ±os</td><td></td><td class="num">4,320</td><td class="num">2,649</td><td class="num">84</td><td class="num">99</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
      <tr><td class="label-left">4 aÃ±os</td><td></td><td class="num">3,693</td><td class="num">1,683</td><td class="num">57</td><td class="num">37</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
      <tr class="row-sub"><td class="label-left">5-9 aÃ±os</td><td></td><td class="num">493</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
      <tr><td class="label-left">10-11 aÃ±os</td><td></td><td class="num">94</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
      <tr class="row-total"><td>TOTAL</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
    </tbody>
  </table>

  <!-- ===== I. ATENCIÃ“N DEL RECIÃ‰N NACIDO ===== -->
  <div class="section-title">I. ATENCIÃ“N DEL RECIÃ‰N NACIDO</div>
  <div class="dual-grid">
    <!-- A) AtenciÃ³n Inmediata -->
    <div>
      <div class="sub2-title">A) AtenciÃ³n Inmediata</div>
      <table>
        <thead>
          <tr><th class="th-dark">ACTIVIDADES</th><th class="th-dark">NÂ°</th></tr>
        </thead>
        <tbody>
          <tr><td class="label-left">AtenciÃ³n Inmediata</td><td class="num">5,360</td></tr>
          <tr class="row-sub"><td class="label-left">Corte tardÃ­o del CordÃ³n Umbilical</td><td class="num">6,967</td></tr>
          <tr><td class="label-left">Contacto Piel a Piel con la madre</td><td class="num">5,246</td></tr>
          <tr class="row-sub"><td class="label-left">Examen fÃ­sico del reciÃ©n nacido normal</td><td class="num">7,929</td></tr>
          <tr><td class="label-left">Lactancia Materna en la 1Âª Hora</td><td class="num">6,967</td></tr>
          <tr class="row-sub"><td class="label-left">BCG MENORES A 1m</td><td class="num">6,352</td></tr>
          <tr><td class="label-left">HVB RN</td><td class="num">6,294</td></tr>
        </tbody>
      </table>

      <div class="sub2-title" style="margin-top:4px;">B) CondiciÃ³n de Nacimiento del ReciÃ©n Nacido</div>
      <table>
        <thead>
          <tr><th class="th-dark">DIAGNÃ“STICOS</th><th class="th-dark">NÂ°</th></tr>
        </thead>
        <tbody>
          <tr><td class="label-left">Extremadamente bajo peso</td><td>14</td></tr>
          <tr class="row-sub"><td class="label-left">Muy bajo peso al nacer</td><td>13</td></tr>
          <tr><td class="label-left">Bajo peso al nacer</td><td>531</td></tr>
          <tr class="row-sub"><td class="label-left">MacrosÃ³mico</td><td>106</td></tr>
          <tr><td class="label-left">Microcefalia</td><td class="zero">0</td></tr>
          <tr class="row-sub"><td class="label-left">ReciÃ©n nacido prematuro</td><td>493</td></tr>
          <tr><td class="label-left">ReciÃ©n Nacido Normal</td><td>45</td></tr>
        </tbody>
      </table>

      <div class="sub2-title" style="margin-top:4px;">B) Resultados del Tamizaje Neonatal</div>
      <table>
        <thead>
          <tr><th class="th-dark">DIAGNÃ“STICOS</th><th class="th-dark">NÂ°</th></tr>
        </thead>
        <tbody>
          <tr><td class="label-left">Hipotiroidismo CongÃ©nito</td><td>4</td></tr>
          <tr class="row-sub"><td class="label-left">Fenilcetonuria ClÃ¡sica</td><td>2</td></tr>
          <tr><td class="label-left">Hiperplasia Suprarrenal CongÃ©nita</td><td>16</td></tr>
          <tr class="row-sub"><td class="label-left">Tamizaje de CardiopatÃ­a CongÃ©nita</td><td class="num">1,676</td></tr>
          <tr><td class="label-left">Fibrosis QuÃ­stica, sin otra especificaciÃ³n</td><td>45</td></tr>
          <tr class="row-sub"><td class="label-left">Catarata CongÃ©nita</td><td>341</td></tr>
          <tr><td class="label-left">CardiopatÃ­a congÃ©nita</td><td class="zero">0</td></tr>
          <tr class="row-sub"><td class="label-left">Hipoacusia conductiva</td><td class="zero">0</td></tr>
        </tbody>
      </table>
    </div>

    <!-- C) Alojamiento Conjunto -->
    <div>
      <div class="sub2-title">C) AtenciÃ³n de ReciÃ©n Nacido en Alojamiento Conjunto</div>
      <table>
        <thead>
          <tr><th class="th-dark">ACTIVIDADES</th><th class="th-dark">NÂ°</th></tr>
        </thead>
        <tbody>
          <tr><td class="label-left">AtenciÃ³n del RN en Alojamiento Conjunto</td><td class="num">7,870</td></tr>
          <tr class="row-sub"><td class="label-left">EvaluaciÃ³n mÃ©dica del reciÃ©n nacido</td><td class="num">1,448</td></tr>
          <tr><td class="label-left">Tamizaje neonatal: toma de muestra</td><td class="num">6,817</td></tr>
          <tr class="row-sub"><td class="label-left">Tamizaje de hipoacusia</td><td>391</td></tr>
          <tr><td class="label-left">Tamizaje de catarata congÃ©nita</td><td>341</td></tr>
          <tr class="row-sub"><td class="label-left">Tamizaje de cardiopatÃ­a congÃ©nita</td><td class="num">1,676</td></tr>
        </tbody>
      </table>

      <div class="sub2-title" style="margin-top:4px;">ConsejerÃ­a en AtenciÃ³n del RN - Alojamiento Conjunto</div>
      <table>
        <thead>
          <tr><th class="th-dark">ACTIVIDADES</th><th class="th-dark">NÂ°</th></tr>
        </thead>
        <tbody>
          <tr><td class="label-left">ConsejerÃ­a en corte y cuidado del cordÃ³n umbilical</td><td class="num">17,204</td></tr>
          <tr class="row-sub"><td class="label-left">ConsejerÃ­a en Lactancia Materna Exclusiva</td><td class="num">33,274</td></tr>
          <tr><td class="label-left">ConsejerÃ­a en importancia del control CRED (4 controles)</td><td class="num">4,751</td></tr>
          <tr class="row-sub"><td class="label-left">ConsejerÃ­a de identificaciÃ³n de signos de alarma</td><td class="num">11,870</td></tr>
          <tr><td class="label-left">ConsejerÃ­a en higiene del RN y cuidado en el hogar</td><td class="zero">0</td></tr>
          <tr class="row-sub"><td class="label-left">ConsejerÃ­a en alimentaciÃ³n con sucedÃ¡neos (neonatos VIH)</td><td>55</td></tr>
        </tbody>
      </table>

      <div class="sub2-title" style="margin-top:4px;">E) AtenciÃ³n del ReciÃ©n Nacido en Visita Domiciliaria</div>
      <table>
        <thead>
          <tr><th class="th-dark">DIAGNÃ“STICOS</th><th class="th-dark">NÂ°</th></tr>
        </thead>
        <tbody>
          <tr><td class="label-left">Visita domiciliaria para el cuidado y evaluaciÃ³n neonatal</td><td class="num">10,705</td></tr>
          <tr class="row-sub"><td class="label-left">Anamnesis y examen fÃ­sico del RN normal</td><td class="num">16,156</td></tr>
          <tr><td class="label-left">ConsejerÃ­a en higiene del RN y cuidado en el hogar</td><td class="num">8,227</td></tr>
          <tr class="row-sub"><td class="label-left">ConsejerÃ­a en cuidado del cordÃ³n umbilical</td><td class="num">28,253</td></tr>
          <tr><td class="label-left">ConsejerÃ­a en importancia del control CRED (4 controles)</td><td class="num">15,367</td></tr>
          <tr class="row-sub"><td class="label-left">ConsejerÃ­a de identificaciÃ³n de signos de alarma</td><td class="num">31,091</td></tr>
          <tr><td class="label-left">ConsejerÃ­a en higiene de manos</td><td class="num">36,676</td></tr>
          <tr class="row-sub"><td class="label-left">ConsejerÃ­a en Lactancia Materna Exclusiva hasta 6 meses</td><td class="num">54,640</td></tr>
        </tbody>
      </table>
    </div>
  </div>

  <!-- ===== IX. EVALUACIÃ“N DEL DESARROLLO ===== -->
  <div class="section-title">IX. EVALUACIÃ“N DEL DESARROLLO</div>
  <table>
    <thead>
      <tr>
        <th class="th-dark" rowspan="3">Edades</th>
        <th class="th-dark" colspan="10">Retardo del Desarrollo</th>
        <th class="th-dark" rowspan="3">Evaluac. Normal</th>
      </tr>
      <tr>
        <th class="th-medium" colspan="2">Lenguaje</th>
        <th class="th-medium" colspan="2">Motora</th>
        <th class="th-medium" colspan="2">Social</th>
        <th class="th-medium" colspan="2">CoordinaciÃ³n</th>
        <th class="th-medium" colspan="2">Cognitiva</th>
      </tr>
      <tr>
        <th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>
        <th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>
        <th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>
        <th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>
        <th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="label-left">&lt; 1 aÃ±o</td>
        <td>3</td><td>2</td><td>18</td><td>5</td><td class="zero">0</td><td class="zero">0</td><td>4</td><td>1</td><td>1</td><td class="zero">0</td>
        <td class="nota">TD=D+DX=Z006+LAB=ED</td>
      </tr>
      <tr class="row-sub">
        <td class="label-left">01 aÃ±o</td>
        <td>16</td><td>2</td><td>35</td><td>1</td><td class="zero">0</td><td class="zero">0</td><td>2</td><td class="zero">0</td><td>3</td><td class="zero">0</td>
        <td class="nota">TD=D+DX=Z006+LAB=ED</td>
      </tr>
      <tr>
        <td class="label-left">02 aÃ±os</td>
        <td>32</td><td>3</td><td>13</td><td class="zero">0</td><td>3</td><td class="zero">0</td><td>2</td><td class="zero">0</td><td>1</td><td class="zero">0</td>
        <td class="nota">TD=D+DX=Z006+LAB=ED</td>
      </tr>
      <tr class="row-sub">
        <td colspan="12" style="text-align:left;padding-left:4px;font-size:8px;">Dx: Diagnosticado &nbsp;&nbsp;&nbsp; Recup: Recuperado</td>
      </tr>
    </tbody>
  </table>

  <!-- Sesiones AtenciÃ³n Temprana -->
  <div class="sub-section-title">II. SESIONES DE ATENCIÃ“N TEMPRANA (99411)</div>
  <table>
    <thead>
      <tr>
        <th class="th-dark">Edad</th>
        <th class="th-medium">1Âª SesiÃ³n</th>
        <th class="th-medium">2Âª SesiÃ³n</th>
        <th class="th-medium">3Âª SesiÃ³n</th>
        <th class="th-medium">4Âª SesiÃ³n</th>
        <th class="th-medium">5Âª SesiÃ³n</th>
        <th class="th-dark">NiÃ±o con sesiones completas (Mensual)</th>
        <th class="th-dark">NiÃ±o con sesiones completas (Acum.)</th>
      </tr>
    </thead>
    <tbody>
      <tr><td class="label-left">RN</td><td class="num">2,560</td><td></td><td></td><td></td><td></td><td class="num">2,560</td><td></td></tr>
    </tbody>
  </table>

  <!-- ===== VI. LACTANCIA MATERNA ===== -->
  <div class="section-title">VI. LACTANCIA MATERNA EXCLUSIVA</div>
  <table style="width:50%">
    <thead>
      <tr><th class="th-dark">CONDICIÃ“N</th><th class="th-dark">NÂ°</th></tr>
    </thead>
    <tbody>
      <tr><td class="label-left">Con lactancia materna exclusiva</td><td></td></tr>
      <tr class="row-sub"><td class="label-left">Con lactancia materna no exclusiva</td><td></td></tr>
      <tr><td class="label-left">Con lactancia artificial</td><td></td></tr>
      <tr class="row-sub"><td class="label-left">Con alimentaciÃ³n mixta</td><td></td></tr>
    </tbody>
  </table>

  <!-- ===== XVI. IRAS / EDAS (desde FORMATO NIÃ‘O) ===== -->
  <div class="section-title">XVI. ATENCIÃ“N DE LAS ENFERMEDADES PREVALENTES DE LA INFANCIA</div>

  <!-- A. IRA -->
  <div class="sub-section-title">A. INFECCIÃ“N RESPIRATORIA AGUDA (IRA)</div>
  <table>
    <colgroup>
      <col style="width:28%">
      <col style="width:10%">
      <col style="width:10%">
      <col style="width:10%">
      <col style="width:10%">
      <col style="width:10%">
      <col style="width:10%">
      <col style="width:12%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" rowspan="2">DIAGNÃ“STICOS</th>
        <th class="th-dark" colspan="6">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">29d a 59 DÃ­as</th>
        <th class="th-medium">02 - 11 Meses</th>
        <th class="th-medium">01 aÃ±o</th>
        <th class="th-medium">2 aÃ±o</th>
        <th class="th-medium">3 aÃ±o</th>
        <th class="th-medium">4 aÃ±o</th>
      </tr>
    </thead>
    <tbody>
      <tr class="row-header">
        <td class="label-left">1. Total de Casos de IRA (1+2+3)</td>
        <td></td><td></td><td></td><td></td><td></td><td></td><td></td>
      </tr>
      <tr class="row-sub">
        <td class="label-left">1.1 NÂ° casos de IRA sin complicaciones (a+b+c+d+e)</td>
        <td class="num">742</td><td class="num">4,019</td><td class="num">4,678</td><td class="num">3,905</td><td class="num">3,903</td><td class="num">3,503</td><td class="num">31,748</td>
      </tr>
      <tr><td class="label-indent">a. IRA no complicada</td><td class="num">737</td><td class="num">4,000</td><td class="num">2,932</td><td class="num">2,177</td><td class="num">2,175</td><td class="num">1,777</td><td class="num">21,033</td></tr>
      <tr class="row-sub"><td class="label-indent">b. Faringoamigdalitis Aguda</td><td></td><td></td><td class="num">1,671</td><td class="num">1,671</td><td class="num">1,671</td><td class="num">1,671</td><td class="num">10,026</td></tr>
      <tr><td class="label-indent">c. Otitis Media Aguda (OMA)</td><td>5</td><td>19</td><td>31</td><td>31</td><td>31</td><td>31</td><td>461</td></tr>
      <tr class="row-sub"><td class="label-indent">d. Sinusitis Aguda</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td>1</td><td>1</td><td>23</td></tr>
      <tr><td class="label-indent">e. NeumonÃ­a sin complicaciones</td><td></td><td></td><td>44</td><td>26</td><td>25</td><td>23</td><td>205</td></tr>
      <tr class="row-sub">
        <td class="label-left">1.2 NÂ° casos IRA con complicaciones (a+b+c)</td>
        <td>3</td><td>5</td><td>4</td><td>4</td><td>5</td><td>3</td><td>30</td>
      </tr>
      <tr><td class="label-indent">a. IRA con complicaciones</td><td>2</td><td>5</td><td>4</td><td>4</td><td>5</td><td>3</td><td>29</td></tr>
      <tr class="row-sub"><td class="label-indent">b. NeumonÃ­a Grave / EMG Menores de 2 Meses</td><td>1</td><td></td><td></td><td></td><td></td><td></td><td>1</td></tr>
      <tr><td class="label-indent">c. NeumonÃ­a y EMG en NiÃ±os de 2 Meses a 4 AÃ±os</td><td></td><td>16</td><td>20</td><td>14</td><td>7</td><td>3</td><td>60</td></tr>
    </tbody>
  </table>

  <!-- B. SOB -->
  <div class="sub-section-title">B. SÃNDROME DE OBSTRUCCIÃ“N BRONQUIAL (SOB) - ASMA</div>
  <table>
    <colgroup>
      <col style="width:28%">
      <col style="width:10%">
      <col style="width:10%">
      <col style="width:10%">
      <col style="width:10%">
      <col style="width:10%">
      <col style="width:10%">
      <col style="width:12%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" rowspan="2">DIAGNÃ“STICOS</th>
        <th class="th-dark" colspan="6">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">02 - 11 Meses</th>
        <th class="th-medium">01 aÃ±o</th>
        <th class="th-medium">2 aÃ±o</th>
        <th class="th-medium">3 aÃ±o</th>
        <th class="th-medium">4 aÃ±o</th>
        <th class="th-medium">05 - 11 AÃ±os</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="label-indent">a. SOB/Asma</td>
        <td class="num">197</td><td>10</td><td>19</td><td>20</td><td>21</td><td class="num">137</td><td class="zero">0</td>
      </tr>
    </tbody>
  </table>

  <!-- C. EDA -->
  <div class="sub-section-title">C. ENFERMEDAD DIARREICA AGUDA (EDA)</div>
  <table>
    <colgroup>
      <col style="width:28%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:12%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" rowspan="2">DIAGNÃ“STICOS</th>
        <th class="th-dark" colspan="6">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 01 AÃ±o</th>
        <th class="th-medium">01 aÃ±o</th>
        <th class="th-medium">2 aÃ±o</th>
        <th class="th-medium">3 aÃ±o</th>
        <th class="th-medium">4 aÃ±o</th>
        <th class="th-medium">05 - 11 AÃ±os</th>
      </tr>
    </thead>
    <tbody>
      <tr class="row-header">
        <td class="label-left">1. Enfermedades Diarreicas sin complicaciones (a+b+c)</td>
        <td class="num">1,236</td><td class="num">1,511</td><td>791</td><td>562</td><td>387</td><td class="num">1,755</td><td class="num">6,242</td>
      </tr>
      <tr><td class="label-indent">a. Diarrea Aguda Acuosa sin deshidrataciÃ³n</td><td>758</td><td>949</td><td>502</td><td>351</td><td>255</td><td class="num">1,178</td><td class="num">3,993</td></tr>
      <tr class="row-sub"><td class="label-indent">b. Diarrea Aguda DisentÃ©rica sin deshidrataciÃ³n</td><td>9</td><td>13</td><td>9</td><td>9</td><td>8</td><td>29</td><td>77</td></tr>
      <tr><td class="label-indent">c. Diarrea Persistente sin deshidrataciÃ³n</td><td>469</td><td>549</td><td>280</td><td>202</td><td>124</td><td>548</td><td class="num">2,172</td></tr>
      <tr class="row-header">
        <td class="label-left">2. Enfermedades Diarreicas con complicaciones (a+b+c+d+e+f)</td>
        <td>24</td><td>64</td><td>7</td><td>6</td><td>5</td><td>18</td><td>124</td>
      </tr>
      <tr><td class="label-indent">a. Diarrea Aguda Acuosa con deshidrataciÃ³n</td><td>12</td><td>36</td><td>5</td><td>2</td><td>3</td><td>12</td><td>70</td></tr>
      <tr class="row-sub"><td class="label-indent">b. Diarrea Aguda DisentÃ©rica con deshidrataciÃ³n</td><td>6</td><td>14</td><td>1</td><td>2</td><td>1</td><td class="zero">0</td><td>24</td></tr>
      <tr><td class="label-indent">c. Diarrea Persistente con deshidrataciÃ³n</td><td>6</td><td>14</td><td>1</td><td>2</td><td>1</td><td>6</td><td>30</td></tr>
      <tr class="row-sub"><td class="label-indent">d. Diarrea Aguda Acuosa con deshidrataciÃ³n con shock</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td></tr>
      <tr><td class="label-indent">e. Diarrea Aguda DisentÃ©rica con deshidrataciÃ³n con shock</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td></tr>
      <tr class="row-sub"><td class="label-indent">f. Diarrea Persistente con deshidrataciÃ³n con shock</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td></tr>
    </tbody>
  </table>

  <!-- Zinc y SRO -->
  <div class="sub-section-title">ADMINISTRACIÃ“N DE ZINC Y SAL DE REHIDRATACIÃ“N ORAL</div>
  <table>
    <colgroup>
      <col style="width:28%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:12%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" rowspan="2">ACTIVIDADES</th>
        <th class="th-dark" colspan="6">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 1 aÃ±o</th>
        <th class="th-medium">01 aÃ±o</th>
        <th class="th-medium">2 aÃ±o</th>
        <th class="th-medium">3 aÃ±o</th>
        <th class="th-medium">4 aÃ±o</th>
        <th class="th-medium">05 - 11 AÃ±os</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="label-left">AdministraciÃ³n de tratamiento - Sales de RehidrataciÃ³n Oral (SRO)</td>
        <td>10</td><td>6</td><td>7</td><td>1</td><td>2</td><td>4</td><td class="zero">0</td>
      </tr>
      <tr class="row-sub">
        <td class="label-left">AdministraciÃ³n de tratamiento - Zinc (ZN)</td>
        <td>71</td><td>107</td><td>70</td><td>33</td><td>20</td><td>27</td><td class="zero">0</td>
      </tr>
    </tbody>
  </table>

  <div style="font-size:8px;color:#595959;margin-top:8px;border-top:1px solid #9DC3E6;padding-top:4px;">
    DIRESA CUSCO &nbsp;|&nbsp; DEIT &nbsp;|&nbsp; Sistema HIS &nbsp;|&nbsp; CRED 2026 &nbsp;|&nbsp; Impreso: <span id="fecha"></span>
  </div>
</div>
<script>
  document.getElementById('fecha').textContent = new Date().toLocaleDateString('es-PE');
</script>
</body>
</html>
```

---

## 23. REFERENCIA HTML - referencia de foramto exel iras_edas.txt

```html
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>FORMATO IRAS EDAS 2026 - DIRESA CUSCO</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: Arial, sans-serif; font-size: 10px; background: #fff; color: #000; }
  .page { width: 100%; max-width: 1400px; margin: 0 auto; padding: 10px; }

  /* Header */
  .header { text-align: center; margin-bottom: 6px; }
  .header h2 { font-size: 11px; font-weight: bold; text-transform: uppercase; }
  .header h3 { font-size: 10px; font-weight: bold; text-transform: uppercase; }

  /* Filters bar */
  .filters { display: flex; gap: 20px; margin-bottom: 6px; font-size: 9px; }
  .filter-group { display: flex; gap: 4px; }
  .filter-label { font-weight: bold; }
  .filter-value { border-bottom: 1px solid #000; min-width: 80px; text-align: center; }

  /* Page number */
  .page-number { text-align: right; font-size: 9px; margin-bottom: 4px; }

  /* Section title */
  .section-title {
    background: #4472C4;
    color: #fff;
    font-weight: bold;
    font-size: 10px;
    padding: 3px 6px;
    text-transform: uppercase;
    margin-bottom: 2px;
  }

  .sub-section-title {
    background: #D6E4F7;
    font-weight: bold;
    font-size: 9px;
    padding: 2px 6px;
    margin-bottom: 2px;
  }

  /* Tables */
  table {
    border-collapse: collapse;
    width: 100%;
    margin-bottom: 6px;
    font-size: 9px;
  }

  th, td {
    border: 1px solid #000;
    padding: 2px 4px;
    vertical-align: middle;
    text-align: center;
  }

  th {
    background: #BDD7EE;
    font-weight: bold;
    font-size: 8.5px;
  }

  .th-dark {
    background: #2E75B6;
    color: #fff;
  }

  .th-medium {
    background: #9DC3E6;
  }

  td.diag {
    text-align: left;
    padding-left: 6px;
    background: #F2F2F2;
    font-size: 8.5px;
  }

  td.diag-sub {
    text-align: left;
    padding-left: 14px;
    font-size: 8.5px;
  }

  td.formula {
    text-align: left;
    padding-left: 4px;
    font-size: 7.5px;
    color: #595959;
    font-style: italic;
  }

  td.zero { color: #595959; }
  td.bold { font-weight: bold; }

  .row-header {
    background: #DDEBF7;
    font-weight: bold;
  }

  .row-sub {
    background: #F2F2F2;
  }

  .note-row td {
    background: #FFF2CC;
    font-size: 8px;
    text-align: left;
    padding-left: 4px;
    border: 1px solid #BF9000;
  }

  /* Inline filter row */
  .filter-row {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 8px;
    font-size: 9px;
    margin-bottom: 6px;
    padding: 4px 0;
    border-top: 1px solid #4472C4;
    border-bottom: 1px solid #4472C4;
  }
  .filter-cell { display: flex; flex-direction: column; }
  .filter-cell label { font-weight: bold; color: #2E75B6; }
  .filter-cell span { border-bottom: 1px solid #9DC3E6; }

  /* Print */
  @media print {
    body { font-size: 8px; }
    .page { max-width: 100%; padding: 5px; }
    @page { size: A3 landscape; margin: 10mm; }
  }
</style>
</head>
<body>
<div class="page">

  <!-- Header -->
  <div class="header">
    <h2>DIRECCIÃ“N REGIONAL DE SALUD CUSCO</h2>
    <h3>DIRECCIÃ“N DE ESTADÃSTICA E INFORMÃTICA Y TELECOMUNICACIÃ“N</h3>
  </div>

  <!-- Filters -->
  <div class="filter-row">
    <div class="filter-cell">
      <label>RED DE SALUD:</label>
      <span>(Todas)</span>
    </div>
    <div class="filter-cell">
      <label>MICRO RED:</label>
      <span>(Todas)</span>
    </div>
    <div class="filter-cell">
      <label>PROVINCIA:</label>
      <span>(Todas)</span>
    </div>
    <div class="filter-cell">
      <label>AÃ‘O:</label>
      <span>2026</span>
    </div>
  </div>
  <div class="filter-row">
    <div class="filter-cell">
      <label>ESTABLECIMIENTO:</label>
      <span>(Todas)</span>
    </div>
    <div class="filter-cell">
      <label>DISTRITO:</label>
      <span>(Todas)</span>
    </div>
    <div class="filter-cell">
      <label>MES INICIO:</label>
      <span>1</span>
    </div>
    <div class="filter-cell">
      <label>MES FIN:</label>
      <span>6</span>
    </div>
  </div>

  <!-- Page title -->
  <div class="page-number">PÃ¡gina 06</div>
  <div class="section-title">XVI. ATENCIÃ“N DE LAS ENFERMEDADES PREVALENTES DE LA INFANCIA</div>

  <!-- ===== A. IRA ===== -->
  <div class="sub-section-title">A. INFECCIÃ“N RESPIRATORIA AGUDA (IRA)</div>
  <table>
    <colgroup>
      <col style="width:5%">
      <col style="width:22%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:10%">
      <col style="width:8%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">DIAGNÃ“STICOS</th>
        <th class="th-dark" colspan="6">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 29 DÃ­as</th>
        <th class="th-medium">29d a 59 DÃ­as</th>
        <th class="th-medium">02 - 11 Meses</th>
        <th class="th-medium">01 - 04 AÃ±os</th>
        <th class="th-medium">05 - 11 AÃ±os</th>
        <th class="th-medium">Total</th>
      </tr>
    </thead>
    <tbody>
      <tr class="row-header">
        <td class="bold" colspan="2" style="text-align:left;padding-left:6px;">1. Total de Casos de IRA (1+2+3)</td>
        <td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td>
      </tr>
      <tr class="row-sub">
        <td class="bold" colspan="2" style="text-align:left;padding-left:6px;">1.1 NÂ° casos de IRA sin complicaciones (a+b+c+d+e)</td>
        <td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">a. InfecciÃ³n Respiratoria Aguda (IRA) no complicada</td>
        <td class="formula">TD=D+DX=J00X, J040, J041, J042, J060, J068, J069, J209</td>
        <td class="formula">TD=D+DX=J00X, J040, J041, J042, J060, J068, J069, J209</td>
        <td class="formula">TD=D+DX=J00X, J040, J041, J042, J060, J068, J069, J209</td>
        <td class="formula">TD=D+DX=J00X, J040, J041, J042, J060, J068, J069, J209</td>
        <td class="formula">TD=D+DX=J00X, J040, J041, J042, J060, J068, J069, J209</td>
        <td>737</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">b. Faringoamigdalitis Aguda</td>
        <td class="formula">TD=D+DX=J020, J029, J030, J038, J039</td>
        <td class="formula">TD=D+DX=J020, J029, J030, J038, J039</td>
        <td class="formula">TD=D+DX=J020, J029, J030, J038, J039</td>
        <td class="formula">TD=D+DX=J020, J029, J030, J038, J039</td>
        <td class="formula">TD=D+DX=J020, J029, J030, J038, J039</td>
        <td class="zero">0</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">c. Otitis Media Aguda (OMA)</td>
        <td class="formula">TD=D+DX=H650, H651, H660, H669</td>
        <td class="formula">TD=D+DX=H650, H651, H660, H669</td>
        <td class="formula">TD=D+DX=H650, H651, H660, H669</td>
        <td class="formula">TD=D+DX=H650, H651, H660, H669</td>
        <td class="formula">TD=D+DX=H650, H651, H660, H669</td>
        <td class="zero">0</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">d. Sinusitis Aguda</td>
        <td class="formula">TD=D+DX=J010, J011, J012, J013, J014, J019</td>
        <td class="formula">TD=D+DX=J010, J011, J012, J013, J014, J019</td>
        <td class="formula">TD=D+DX=J010, J011, J012, J013, J014, J019</td>
        <td class="formula">TD=D+DX=J010, J011, J012, J013, J014, J019</td>
        <td class="formula">TD=D+DX=J010, J011, J012, J013, J014, J019</td>
        <td class="zero">0</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">e. NeumonÃ­a sin complicaciones</td>
        <td class="formula">TD=D+DX=J129, J159, J189</td>
        <td class="formula">TD=D+DX=J129, J159, J189</td>
        <td class="formula">TD=D+DX=J129, J159, J189</td>
        <td class="formula">TD=D+DX=J129, J159, J189</td>
        <td class="formula">TD=D+DX=J129, J159, J189</td>
        <td class="zero">0</td>
        <td class="zero">0</td>
      </tr>
      <tr class="row-sub">
        <td class="bold" colspan="2" style="text-align:left;padding-left:6px;">1.2 NÂ° casos IRA con complicaciones (a+b+c)</td>
        <td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">a. Infecciones Respiratorias Agudas con complicaciones</td>
        <td class="formula">TD=D+DX=A369, A370, A371, A378, A379, J120, J121, J122, J123, J128, J13X, J14X, J150â€¦</td>
        <td class="formula">TD=D+DX=A369, A370, A371, A378, A379, J120, J121, J122, J123, J128â€¦</td>
        <td class="formula">TD=D+DX=A369, A370, A371, A378, A379, J120, J121, J122, J123, J128â€¦</td>
        <td class="formula">TD=D+DX=A369, A370, A371, A378, A379, J120, J121, J122, J123, J128â€¦</td>
        <td class="formula">TD=D+DX=A369, A370, A371, A378, A379, J120, J121, J122, J123, J128â€¦</td>
        <td class="zero">0</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">b. NeumonÃ­a Grave o Enfermedad Muy Grave en NiÃ±os Menores de 2 Meses</td>
        <td class="formula">TD=D+DX=J050, J051, J851, J860, J869, J90X, J939, J100, J110â€¦</td>
        <td class="formula">TD=D+DX=J050, J051, J851, J860, J869, J90X, J939, J100, J110â€¦</td>
        <td></td><td></td><td></td>
        <td class="zero">0</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">c. NeumonÃ­a y Enfermedad Muy Grave en NiÃ±os de 2 Meses a 4 AÃ±os</td>
        <td></td><td></td>
        <td class="formula">TD=D+DX=J050, J051, J851, J860, J869, J90X, J939, J100, J110â€¦</td>
        <td class="formula">TD=D+DX=J050, J051, J851, J860, J869, J90X, J939, J100, J110â€¦</td>
        <td></td>
        <td class="zero">0</td>
        <td class="zero">0</td>
      </tr>
    </tbody>
  </table>

  <!-- Oxigenoterapia -->
  <div class="sub-section-title">OXIGENOTERAPIA / OXIMETRÃA</div>
  <table>
    <colgroup>
      <col style="width:5%">
      <col style="width:22%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:11%">
      <col style="width:10%">
      <col style="width:8%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">ACTIVIDAD</th>
        <th class="th-dark" colspan="6">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 29 DÃ­as</th>
        <th class="th-medium">29d a 59 DÃ­as</th>
        <th class="th-medium">02 - 11 Meses</th>
        <th class="th-medium">01 - 04 AÃ±os</th>
        <th class="th-medium">05 - 11 AÃ±os</th>
        <th class="th-medium">Total</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td></td>
        <td class="diag-sub">Oxigenoterapia</td>
        <td class="formula">(TD=R+DX=(J129,J159,J189)+DX=94799.02)</td>
        <td class="formula">(TD=R+DX=(J129,J159,J189)+DX=94799.02)</td>
        <td class="formula">(TD=R+DX=(J129,J159,J189)+DX=94799.02)</td>
        <td class="formula">(TD=R+DX=(J129,J159,J189)+DX=94799.02)</td>
        <td class="formula">(TD=R+DX=(J129,J159,J189)+DX=94799.02)</td>
        <td class="zero">0</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">OximetrÃ­a</td>
        <td class="formula">(TD=R+DX=(J129,J159,J189)+DX=94760)</td>
        <td class="formula">(TD=R+DX=(J129,J159,J189)+DX=94760)</td>
        <td class="formula">(TD=R+DX=(J129,J159,J189)+DX=94760)</td>
        <td class="formula">(TD=R+DX=(J129,J159,J189)+DX=94760)</td>
        <td class="formula">(TD=R+DX=(J129,J159,J189)+DX=94760)</td>
        <td class="zero">0</td>
        <td class="zero">0</td>
      </tr>
    </tbody>
  </table>

  <!-- ===== B. SOB-ASMA ===== -->
  <div class="sub-section-title">B. SÃNDROME DE OBSTRUCCIÃ“N BRONQUIAL (SOB) - ASMA</div>
  <table>
    <colgroup>
      <col style="width:5%">
      <col style="width:19%">
      <col style="width:9%">
      <col style="width:9%">
      <col style="width:9%">
      <col style="width:9%">
      <col style="width:9%">
      <col style="width:9%">
      <col style="width:9%">
      <col style="width:7%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">DIAGNÃ“STICOS</th>
        <th class="th-dark" colspan="7">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 29 DÃ­as</th>
        <th class="th-medium">29d a 59 DÃ­as</th>
        <th class="th-medium">02 - 11 Meses</th>
        <th class="th-medium">12m - 23m</th>
        <th class="th-medium">02 - 02 AÃ±os 11m</th>
        <th class="th-medium">03 - 04 AÃ±os</th>
        <th class="th-medium">05 - 11 AÃ±os</th>
      </tr>
    </thead>
    <tbody>
      <tr class="row-header">
        <td colspan="2" style="text-align:left;padding-left:6px;font-weight:bold;">SOB/Asma</td>
        <td></td><td></td><td></td><td></td><td></td><td></td><td></td><td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">a. SOB/Asma</td>
        <td class="formula">TD=D+DX=J210,J211,J218,J219,J440,J441,J448,J449,J450,J451,J459,J46X</td>
        <td class="formula">TD=D+DX=J210,J211,J218,J219,J440,J441,J448,J449,J450,J451,J459,J46X</td>
        <td class="formula">TD=D+DX=J210,J211,J218,J219,J440,J441,J448,J449,J450,J451,J459,J46X</td>
        <td class="formula">TD=D+DX=J210,J211,J218,J219,J440,J441,J448,J449,J450,J451,J459,J46X</td>
        <td class="formula">TD=D+DX=J440,J441,J448,J449,J450,J451,J459,J46X</td>
        <td class="formula">TD=D+DX=J440,J441,J448,J449,J450,J451,J459,J46X</td>
        <td class="formula">TD=D+DX=J440,J441,J448,J449,J450,J451,J459,J46X</td>
        <td class="zero">0</td>
      </tr>
    </tbody>
  </table>

  <!-- Oxigenoterapia y NebulizaciÃ³n -->
  <div class="sub-section-title">OXIGENOTERAPIA Y NEBULIZACIÃ“N</div>
  <table>
    <colgroup>
      <col style="width:5%">
      <col style="width:19%">
      <col style="width:9%">
      <col style="width:9%">
      <col style="width:9%">
      <col style="width:9%">
      <col style="width:9%">
      <col style="width:9%">
      <col style="width:9%">
      <col style="width:7%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">ACTIVIDADES</th>
        <th class="th-dark" colspan="7">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 29 DÃ­as</th>
        <th class="th-medium">29d a 59 DÃ­as</th>
        <th class="th-medium">02 - 11 Meses</th>
        <th class="th-medium">12m - 23m</th>
        <th class="th-medium">02 - 02 AÃ±os 11m</th>
        <th class="th-medium">03 - 04 AÃ±os</th>
        <th class="th-medium">05 - 11 AÃ±os</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td></td>
        <td class="diag-sub">Oxigenoterapia</td>
        <td class="formula">(TD=R+DX=(J210â€¦J46X)+DX=94799.02)</td>
        <td class="formula">(TD=R+DX=(J210â€¦J46X)+DX=94799.02)</td>
        <td class="formula">(TD=R+DX=(J210â€¦J46X)+DX=94799.02)</td>
        <td class="formula">(TD=R+DX=(J210â€¦J46X)+DX=94799.02)</td>
        <td class="formula">(TD=R+DX=(J440â€¦J46X)+DX=94799.02)</td>
        <td class="formula">(TD=R+DX=(J440â€¦J46X)+DX=94799.02)</td>
        <td class="formula">(TD=R+DX=(J440â€¦J46X)+DX=94799.02)</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">NebulizaciÃ³n / Inhaloterapia</td>
        <td class="formula">(TD=R+DX=(J210â€¦J46X)+DX=94664)</td>
        <td class="formula">(TD=R+DX=(J210â€¦J46X)+DX=94664)</td>
        <td class="formula">(TD=R+DX=(J210â€¦J46X)+DX=94664)</td>
        <td class="formula">(TD=R+DX=(J210â€¦J46X)+DX=94664)</td>
        <td class="formula">(TD=R+DX=(J440â€¦J46X)+DX=94664)</td>
        <td class="formula">(TD=R+DX=(J440â€¦J46X)+DX=94664)</td>
        <td class="formula">(TD=R+DX=(J440â€¦J46X)+DX=94664)</td>
        <td class="zero">0</td>
      </tr>
      <tr class="note-row">
        <td colspan="10">Fuentes Externas &nbsp;&nbsp;&nbsp; Reporte de Egresos</td>
      </tr>
    </tbody>
  </table>

  <!-- ===== C. EDA ===== -->
  <div class="sub-section-title">C. ENFERMEDAD DIARREICA AGUDA (EDA)</div>
  <table>
    <colgroup>
      <col style="width:5%">
      <col style="width:28%">
      <col style="width:18%">
      <col style="width:18%">
      <col style="width:14%">
      <col style="width:10%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">DIAGNÃ“STICOS</th>
        <th class="th-dark" colspan="3">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 01 AÃ±o</th>
        <th class="th-medium">01 - 04 AÃ±os</th>
        <th class="th-medium">05 - 11 AÃ±os</th>
      </tr>
    </thead>
    <tbody>
      <tr class="row-header">
        <td class="bold" colspan="2" style="text-align:left;padding-left:6px;">1. Enfermedades Diarreicas sin complicaciones (a+b+c)</td>
        <td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">a. Diarrea Aguda Acuosa sin deshidrataciÃ³n</td>
        <td class="formula">TD=D+DX=A00.9,A01.0,A01.1,A01.2,A01.3,A01.4,A02.0,A04.0,A04.1,A04.9,A05.9,A06.2,A07.1,A07.2,A08.0,A08.2,A08.3,A08.4,A09.0,A09.9</td>
        <td class="formula">TD=D+DX=A00.9,A01.0,A01.1,A01.2,A01.3,A01.4,A02.0,A04.0,A04.1,A04.9,A05.9,A06.2,A07.1,A07.2,A08.0,A08.2,A08.3,A08.4,A09.0,A09.9</td>
        <td class="formula">TD=D+DX=A00.9,A01.0,A01.1,A01.2,A01.3,A01.4,A02.0,A04.0,A04.1,A04.9,A05.9,A06.2,A07.1,A07.2,A08.0,A08.2,A08.3,A08.4,A09.0,A09.9</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">b. Diarrea Aguda DisentÃ©rica sin deshidrataciÃ³n</td>
        <td class="formula">TD=D+DX=A03.0,A03.9,A04.2,A04.3,A04.5,A06.0</td>
        <td class="formula">TD=D+DX=A03.0,A03.9,A04.2,A04.3,A04.5,A06.0</td>
        <td class="formula">TD=D+DX=A03.0,A03.9,A04.2,A04.3,A04.5,A06.0</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">c. Diarrea Persistente sin deshidrataciÃ³n</td>
        <td class="formula">TD=D+DX=A09X</td>
        <td class="formula">TD=D+DX=A09X</td>
        <td class="formula">TD=D+DX=A09X</td>
        <td class="zero">0</td>
      </tr>
      <tr class="row-header">
        <td class="bold" colspan="2" style="text-align:left;padding-left:6px;">2. Enfermedades Diarreicas con complicaciones (a+b+c+d+e+f)</td>
        <td class="zero">0</td><td class="zero">0</td><td class="zero">0</td><td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">a. Diarrea Aguda Acuosa con deshidrataciÃ³n</td>
        <td class="formula">TD=D+DX=A00.9+E86X,A01.0+E86X,A01.1+E86X,A01.2+E86X,A01.3+E86X,A01.4+E86X,A02.0+E86X,A04.0+E86X,A04.1+E86X,A049+E86X,A05.9+E86X,A06.2+E86X,A07.1+E86X,A07.2+E86X,A08.0+E86X,A08.2+E86X,A08.3+E86X,A08.4+E86X,A09.0+E86X,A09.9+E86X</td>
        <td class="formula">TD=D+DX=A00.9+E86X,A01.0+E86X,A01.1+E86Xâ€¦A09.9+E86X</td>
        <td class="formula">TD=D+DX=A00.9+E86X,A01.0+E86X,A01.1+E86Xâ€¦A09.9+E86X</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">b. Diarrea Aguda DisentÃ©rica con deshidrataciÃ³n</td>
        <td class="formula">TD=D+DX=A030+E86X,A039+E86X,A042+E86X,A043+E86X,A045+E86X,A060+E86X</td>
        <td class="formula">TD=D+DX=A030+E86X,A039+E86X,A042+E86X,A043+E86X,A045+E86X,A060+E86X</td>
        <td class="formula">TD=D+DX=A030+E86X,A039+E86X,A042+E86X,A043+E86X,A045+E86X,A060+E86X</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">c. Diarrea Persistente con deshidrataciÃ³n</td>
        <td class="formula">TD=D+DX=A09X+E86X</td>
        <td class="formula">TD=D+DX=A09X+E86X</td>
        <td class="formula">TD=D+DX=A09X+E86X</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">d. Diarrea Aguda Acuosa con deshidrataciÃ³n con shock</td>
        <td class="formula">TD=D+DX=A00.9+E86X+R57.1,A01.0+E86X+R57.1â€¦A09.9+E86X+R57.1,A049+E86X+R57.1</td>
        <td class="formula">TD=D+DX=A00.9+E86X+R57.1â€¦A09.9+E86X+R57.1</td>
        <td class="formula">TD=D+DX=A00.9+E86X+R57.1â€¦A09.9+E86X+R57.1</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">e. Diarrea Aguda DisentÃ©rica con deshidrataciÃ³n con shock</td>
        <td class="formula">TD=D+DX=A030+E86X+R57.1,A039+E86X+R57.1,A042+E86X+R57.1,A043+E86X+R57.1,A045+E86X+R57.1,A060+E86X+R57.1</td>
        <td class="formula">TD=D+DX=A030+E86X+R57.1â€¦A060+E86X+R57.1</td>
        <td class="formula">TD=D+DX=A030+E86X+R57.1â€¦A060+E86X+R57.1</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">f. Diarrea Persistente con deshidrataciÃ³n con shock</td>
        <td class="formula">TD=D+DX=A09X+E86X+R57.1</td>
        <td class="formula">TD=D+DX=A09X+E86X+R57.1</td>
        <td class="formula">TD=D+DX=A09X+E86X+R57.1</td>
        <td class="zero">0</td>
      </tr>
    </tbody>
  </table>

  <!-- Zinc y SRO -->
  <div class="sub-section-title">ADMINISTRACIÃ“N DE ZINC Y SAL DE REHIDRATACIÃ“N ORAL</div>
  <table>
    <colgroup>
      <col style="width:5%">
      <col style="width:28%">
      <col style="width:18%">
      <col style="width:18%">
      <col style="width:14%">
      <col style="width:10%">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">ACTIVIDADES</th>
        <th class="th-dark" colspan="3">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 1 aÃ±o</th>
        <th class="th-medium">01 - 04 AÃ±os</th>
        <th class="th-medium">05 - 11 AÃ±os</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td></td>
        <td class="diag-sub">AdministraciÃ³n de tratamiento (Sales de RehidrataciÃ³n Oral - SRO)</td>
        <td class="formula">(EDAD &lt;= 11M) + DX=99199.11 + LAB=SRO</td>
        <td class="formula">(EDAD &gt;=1A y EDAD = 4A) + DX=99199.11 + LAB=SRO</td>
        <td class="formula">(EDAD &gt;=5A y EDAD = 11A) + DX=99199.11 + LAB=SRO</td>
        <td class="zero">0</td>
      </tr>
      <tr>
        <td></td>
        <td class="diag-sub">AdministraciÃ³n de tratamiento (Zinc - ZN)</td>
        <td class="formula">(EDAD &lt;= 11M) + DX=99199.11 + LAB=ZINC</td>
        <td class="formula">(EDAD &gt;=1A y EDAD = 4A) + DX=99199.11 + LAB=ZINC</td>
        <td class="formula">(EDAD &gt;=5A y EDAD = 11A) + DX=99199.11 + LAB=ZINC</td>
        <td class="zero">0</td>
      </tr>
    </tbody>
  </table>

  <!-- Resumen consolidado -->
  <div class="sub-section-title">RESUMEN ACUMULADO (Enero - Junio 2026) - HOJA PROCESO</div>
  <table>
    <thead>
      <tr>
        <th class="th-dark">Mes</th>
        <th class="th-medium">EDA Acuosa &lt;1a</th>
        <th class="th-medium">EDA Acuosa 1a</th>
        <th class="th-medium">EDA Acuosa 2a</th>
        <th class="th-medium">EDA Acuosa 3a</th>
        <th class="th-medium">EDA Acuosa 4a</th>
        <th class="th-medium">IRA no comp &lt;5a</th>
        <th class="th-medium">Faringoamig. &lt;5a</th>
        <th class="th-medium">OMA &lt;5a</th>
        <th class="th-medium">Neumonia &lt;5a</th>
        <th class="th-medium">IRAS comp.</th>
        <th class="th-dark">FONI</th>
      </tr>
    </thead>
    <tbody>
      <tr><td>1 - Enero</td><td>144</td><td>174</td><td>110</td><td>57</td><td>43</td><td>2030</td><td>â€”</td><td>40</td><td>25</td><td>25</td><td>17893</td></tr>
      <tr class="row-sub"><td>2 - Febrero</td><td>134</td><td>155</td><td>67</td><td>59</td><td>41</td><td>1895</td><td>â€”</td><td>34</td><td>28</td><td>28</td><td>17536</td></tr>
      <tr><td>3 - Marzo</td><td>142</td><td>197</td><td>104</td><td>82</td><td>66</td><td>2432</td><td>â€”</td><td>37</td><td>22</td><td>22</td><td>20818</td></tr>
      <tr class="row-sub"><td>4 - Abril</td><td>146</td><td>171</td><td>98</td><td>79</td><td>56</td><td>3611</td><td>â€”</td><td>48</td><td>35</td><td>35</td><td>20866</td></tr>
      <tr><td>5 - Mayo</td><td>160</td><td>216</td><td>104</td><td>66</td><td>42</td><td>4212</td><td>â€”</td><td>69</td><td>52</td><td>52</td><td>21208</td></tr>
      <tr class="row-sub"><td>6 - Junio</td><td>32</td><td>36</td><td>19</td><td>8</td><td>7</td><td>1100</td><td>â€”</td><td>21</td><td>27</td><td>27</td><td>6422</td></tr>
      <tr style="background:#2E75B6;color:#fff;font-weight:bold;">
        <td>TOTAL GENERAL</td><td>758</td><td>949</td><td>502</td><td>351</td><td>255</td><td>15280</td><td>â€”</td><td>249</td><td>189</td><td>189</td><td>104743</td>
      </tr>
    </tbody>
  </table>

  <div style="font-size:8px;color:#595959;margin-top:8px;border-top:1px solid #9DC3E6;padding-top:4px;">
    DIRESA CUSCO &nbsp;|&nbsp; DEIT &nbsp;|&nbsp; Sistema HIS &nbsp;|&nbsp; AÃ±o 2026 &nbsp;|&nbsp; Impreso: <span id="fecha"></span>
  </div>
</div>
<script>
  document.getElementById('fecha').textContent = new Date().toLocaleDateString('es-PE');
</script>
</body>
</html>
```
