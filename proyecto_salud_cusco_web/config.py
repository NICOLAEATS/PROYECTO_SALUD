import os, sys
from pathlib import Path

if getattr(sys, 'frozen', False):
    BASE_DIR = Path(sys._MEIPASS) / "proyecto_salud_cusco_web"
    PROJECT_ROOT = Path(sys._MEIPASS)
    _APPDATA = Path(os.environ.get('APPDATA', os.path.expanduser('~'))) / "Proyecto_Salud_Cusco" / "data"
    _APPDATA.mkdir(parents=True, exist_ok=True)
    SCRIPTS_SQL_REPORTES = _APPDATA / "scripts_sql" / "reportes"
    SCRIPTS_SQL_REPORTES.mkdir(parents=True, exist_ok=True)
    EDITOR_BUTTONS_FILE = (_APPDATA.parent) / "editor_buttons.json"
else:
    BASE_DIR = Path(__file__).resolve().parent
    PROJECT_ROOT = BASE_DIR.parent
    SCRIPTS_SQL_REPORTES = PROJECT_ROOT / "scripts_sql" / "reportes"
    EDITOR_BUTTONS_FILE = PROJECT_ROOT / "editor_buttons.json"

SCRIPTS_INGESTA = PROJECT_ROOT / "scripts_python" / "ingesta"
SCRIPTS_BI = PROJECT_ROOT / "scripts_python" / "bi"
SCRIPTS_MANTENIMIENTO = PROJECT_ROOT / "scripts_python" / "mantenimiento"
SCRIPTS_INSTALACION = PROJECT_ROOT / "scripts_python" / "instalacion"
SCRIPTS_SQL_VACUNAS = PROJECT_ROOT / "scripts_sql" / "scripst tabla y reportes vacunas-cred"
SCRIPTS_SQL_CORREGIDOS = PROJECT_ROOT / "scripts_sql" / "SCRIPTS CORREGIDOS ULTIMOS"
SCRIPTS_PADRONES = PROJECT_ROOT / "scripts_sql" / "PADRONES"
SCRIPTS_BI_LOAD = PROJECT_ROOT / "scripts_python" / "bi"

BOTONES_REPORTE_PREDETERMINADOS = [
    {"nombre": "1\u20e3 Tabla Vacunas/CRED", "script": "scripts_sql/SCRIPTS CORREGIDOS ULTIMOS/tabla vacunas cred_ivan.sql", "seccion": "vacunas_cred", "color_bg": "#3498DB"},
    {"nombre": "2\u20e3 Tabla Materno", "script": "scripts_sql/SCRIPTS CORREGIDOS ULTIMOS/tabla_materno_ivan.sql", "seccion": "vacunas_cred", "color_bg": "#9B59B6"},
    {"nombre": "3\u20e3 Tabla PAI", "script": "scripts_sql/SCRIPTS CORREGIDOS ULTIMOS/tabla vacunas cred_ivan.sql", "seccion": "vacunas_cred", "color_bg": "#8E44AD"},
    {"nombre": "4\u20e3 Tabla IRAS/EDAS", "script": "scripts_sql/SCRIPTS CORREGIDOS ULTIMOS/tabla_iras_edas_ivan_2026.sql", "seccion": "vacunas_cred", "color_bg": "#1ABC9C"},
    {"nombre": "Reporte CRED", "script": "scripts_sql/SCRIPTS CORREGIDOS ULTIMOS/reporte_cred_ivan_2026.sql", "seccion": "reportes", "color_bg": "#F39C12"},
    {"nombre": "Reporte Vacunas", "script": "scripts_sql/scripst tabla y reportes vacunas-cred/REPORTE_VACUNAS_POR A\u00d1O   moshe.sql", "seccion": "reportes", "color_bg": "#E74C3C"},
    {"nombre": "Reporte IRAS/EDAS", "script": "scripts_sql/SCRIPTS CORREGIDOS ULTIMOS/reporte_iras_edas_2026_ivan.sql", "seccion": "reportes", "color_bg": "#2ECC71"},
]

SCRIPTS_MAESTROS_EDITABLES = [
    {"nombre": "Generar HIS Proceso", "script": "scripts_python/ingesta/generar_his_proceso.py", "sql_editor": "scripts_sql/reportes/generar_his_proceso_editor.sql"},
    {"nombre": "Procesar EESS Principal", "script": "scripts_python/ingesta/procesar_eess_principal.py", "sql_editor": "scripts_sql/scripst tabla y reportes vacunas-cred/EESS_PRINCIPAL_2026     moshe.sql"},
]
