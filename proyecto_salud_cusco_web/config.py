import os
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = BASE_DIR.parent

SCRIPTS_INGESTA = PROJECT_ROOT / "scripts_python" / "ingesta"
SCRIPTS_BI = PROJECT_ROOT / "scripts_python" / "bi"
SCRIPTS_MANTENIMIENTO = PROJECT_ROOT / "scripts_python" / "mantenimiento"
SCRIPTS_INSTALACION = PROJECT_ROOT / "scripts_python" / "instalacion"
SCRIPTS_SQL_REPORTES = PROJECT_ROOT / "scripts_sql" / "reportes"
SCRIPTS_SQL_VACUNAS = PROJECT_ROOT / "scripts_sql" / "scripst tabla y reportes vacunas-cred"

EDITOR_BUTTONS_FILE = PROJECT_ROOT / "editor_buttons.json"

BOTONES_REPORTE_PREDETERMINADOS = [
    {"nombre": "1\u20e3 Tabla Vacunas/CRED", "script": "scripts_python/bi/generar_tabla_vacunas.py", "seccion": "vacunas_cred", "color_bg": "#3498DB"},
    {"nombre": "2\u20e3 Tabla Materno", "script": "scripts_sql/scripst tabla y reportes vacunas-cred/tabla materno.sql", "seccion": "vacunas_cred", "color_bg": "#9B59B6"},
    {"nombre": "3\u20e3 Tabla PAI", "script": "scripts_sql/scripst tabla y reportes vacunas-cred/Script-136 moshe vacunas.sql", "seccion": "vacunas_cred", "color_bg": "#8E44AD"},
    {"nombre": "Reporte CRED", "script": "scripts_sql/scripst tabla y reportes vacunas-cred/cred2026_clean.sql", "seccion": "reportes", "color_bg": "#F39C12"},
    {"nombre": "Reporte Vacunas", "script": "scripts_sql/scripst tabla y reportes vacunas-cred/REPORTE_VACUNAS_POR A\u00d1O   moshe.sql", "seccion": "reportes", "color_bg": "#E74C3C"},
    {"nombre": "Reporte IRAS/EDAS", "script": "scripts_sql/scripst tabla y reportes vacunas-cred/REPORTE_IRAS_EDAS_POR_A\u00d1O   moshe.sql", "seccion": "reportes", "color_bg": "#2ECC71"},
]

SCRIPTS_MAESTROS_EDITABLES = [
    {"nombre": "Generar HIS Proceso", "script": "scripts_python/ingesta/generar_his_proceso.py", "sql_editor": "scripts_sql/reportes/generar_his_proceso_editor.sql"},
    {"nombre": "Procesar EESS Principal", "script": "scripts_python/ingesta/procesar_eess_principal.py", "sql_editor": "scripts_sql/scripst tabla y reportes vacunas-cred/EESS_PRINCIPAL_2026     moshe.sql"},
]
