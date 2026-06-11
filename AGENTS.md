# Proyecto_Salud_Cusco - Agent Guidelines

## Quick Start
```bash
python main.py
pip install customtkinter psycopg2-binary
```

## Architecture
- **Entry point**: `main.py` - CustomTkinter GUI application
- **DB config**: `db_config.py` - Centralized PostgreSQL connection management
- **Scripts**: `scripts_python/ingesta/*.py` - Data ingestion scripts
- **Key module**: `modulo_maestros.py` - Maestro table processing GUI

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
- `detectar_postgresql_existente()` - Returns dict with installed, version, service status, ruta_bin
- `verificar_bd_esquema()` - Verifies DB and schema exist
- `inicializar_base_datos()` - Creates DB and schema if missing

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