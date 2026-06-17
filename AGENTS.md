# Proyecto_Salud_Cusco - Agent Guidelines (v2 - Web + Cloud)

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

### Blocked / Paused
- **Oracle Cloud Free Tier**: El usuario pagó $1 USD de verificación pero la creación de cuenta falla con error genérico ("Lo sentimos, se ha producido un error al crear su cuenta"). Sugerencias: esperar 24h, probar otro navegador en incógnito, verificar que la dirección de facturación coincida exactamente con la tarjeta, no usar VPN.
- **Alternativa**: Hetzner CX22 (€3.99/mes con PayPal) como plan B si Oracle no funciona.

### Next Steps (when resume)
1. Probar Oracle Cloud de nuevo (esperar 24h o probar otro navegador/PC).
2. Si Oracle sigue fallando, crear cuenta en Hetzner y desplegar VM CX22 con PayPal.
3. Configurar VM con script cloud-init: PostgreSQL + Flask + clonar repo de GitHub.
4. Probar acceso público desde cualquier PC sin PostgreSQL ni Git instalados.
5. Agregar protección CSRF y manejo de sesiones para producción.

## Key Decisions
- SocketIO → polling REST para eliminar errores de protocolo.
- `config.py` usa auto-detección de `PROJECT_ROOT` + env var override.
- PostgreSQL detection cross-platform con `ES_WINDOWS` branching.
- Cloudflare Tunnel para acceso remoto temporal gratuito (sin cuenta).
- Oracle Cloud Free Tier (gratis siempre) o Hetzner (€3.99/mes PayPal) como destino de despliegue.

## Relevant Paths
- `proyecto_salud_cusco_web/app.py` - Flask REST API + polling + tunnel (~654 líneas)
- `proyecto_salud_cusco_web/templates/index.html` - SPA frontend (~285 líneas)
- `proyecto_salud_cusco_web/static/js/app.js` - Frontend JS polling + Fetch (~880 líneas)
- `proyecto_salud_cusco_web/static/css/style.css` - Temas claro/oscuro (~781 líneas)
- `proyecto_salud_cusco_web/config.py` - Auto-detección PROJECT_ROOT
- `proyecto_salud_cusco_web/tunnel/` - Scripts tunnel (Windows)
- `db_config.py` - PostgreSQL detection cross-platform (Linux + Windows)
- `proyecto-salud-pkg/` - Paquete pacman (PKGBUILD, scripts install/uninstall)