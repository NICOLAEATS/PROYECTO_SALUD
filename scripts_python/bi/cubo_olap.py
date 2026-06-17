# ==========================================
# IMPORTS
# ==========================================
import pandas as pd
from sqlalchemy import create_engine
import sys
import os

# Importar configuración flexible de base de datos
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from db_config import get_db_config

# Obtener configuración de base de datos (con valores por defecto para compatibilidad)
_db_config = get_db_config()

# ==========================================
# PARÁMETROS DE CONEXIÓN (POSTGRESQL)
# ==========================================
usuario = _db_config.user
password = _db_config.password
host = _db_config.host
puerto = _db_config.port
basedatos = _db_config.database

# ==========================================
# CONEXIÓN A LA BASE DE DATOS
# ==========================================
engine = create_engine(
    f"postgresql+psycopg2://{usuario}:{password}@{host}:{puerto}/{basedatos}",
    pool_pre_ping=True
)

# ==========================================
# CARGA DE LA TABLA BASE
# ==========================================
query = """
SELECT *
FROM es_ivan.cred2025
"""

df = pd.read_sql(query, engine)

# Replace NaN/None with empty string for string columns and 0 for numeric columns
for col in df.columns:
    if df[col].dtype == object:
        df[col] = df[col].fillna('')
    else:
        # For numeric columns, fill NaN with 0 to avoid issues in sums
        df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)

print("Tabla cargada correctamente")
print("Filas, Columnas:", df.shape)

# ==========================================
# DEFINICIÓN DE DIMENSIONES
# ==========================================
dimensiones = [
    "anio", "mes",
    "red", "microred",
    "provincia", "distrito",
    "cod_2000", "nombre_establecimiento",
    "desc_ue"
]

# Convertir dimensiones a tipo categórico (optimización OLAP)
for col in dimensiones:
    if col in df.columns:
        df[col] = df[col].astype("category")

# ==========================================
# IDENTIFICAR MEDIDAS (HECHOS)
# ==========================================
medidas = df.select_dtypes(include=["int64", "float64"]).columns.tolist()

print("Número de medidas:", len(medidas))

# ==========================================
# CUBO OLAP 1: CRED MENOR DE 1 AÑO
# ==========================================
cubo_cred_men1a = pd.pivot_table(
    df,
    values=[
        "cred1_men1a", "cred2_men1a", "cred3_men1a",
        "cred4_men1a", "cred5_men1a", "cred6_men1a"
    ],
    index=["anio", "mes"],
    columns=["red"],
    aggfunc="sum",
    fill_value=0
)

# ==========================================
# CUBO OLAP 2: DESNUTRICIÓN MENOR DE 1 AÑO
# ==========================================
cubo_desnutricion = pd.pivot_table(
    df,
    values=[
        "desnutric_aguda_men1a",
        "desnutric_cronica_men1a",
        "desnutric_severa_men1a",
        "desnutric_global_men1a"
    ],
    index=["anio"],
    columns=["provincia"],
    aggfunc="sum",
    fill_value=0
)

# ==========================================
# CUBO OLAP 3: SUPLEMENTACIÓN POR RED
# ==========================================
cubo_suplementacion = pd.pivot_table(
    df,
    values=[
        "suplem_1ra_6_11m",
        "suplem_2da_6_11m",
        "suplem_3ra_6_11m",
        "suplem_4ta_6_11m"
    ],
    index=["anio", "mes"],
    columns=["red"],
    aggfunc="sum",
    fill_value=0
)

# ==========================================
# CUBO OLAP GENERAL (TODAS LAS MEDIDAS)
# ⚠️ USAR SOLO PARA EXPORTACIÓN
# ==========================================
cubo_general = pd.pivot_table(
    df,
    values=medidas,
    index=["anio", "mes"],
    columns=["red"],
    aggfunc="sum",
    fill_value=0
)

# ==========================================
# DRILL-DOWN (EJEMPLOS OLAP)
# ==========================================

# Drill-down por red
drill_red = (
    df[df["red"] == "CUSCO"]
    .groupby(["anio", "mes"])["cred1_men1a"]
    .sum()
)

# Slice por establecimiento
drill_establecimiento = (
    df[df["cod_2000"] == "12345"]
    .groupby("anio")[["cred1_men1a", "cred2_men1a"]]
    .sum()
)

# ==========================================
# EXPORTACIÓN A EXCEL (BI / POWER BI)
# ==========================================
with pd.ExcelWriter ("D:\PROCESO_POSTGRES2024\import\cubos_olap_cred2025.xlsx", engine="openpyxl") as writer:
    cubo_cred_men1a.to_excel(writer, sheet_name="CRED_MEN1A")
    cubo_desnutricion.to_excel(writer, sheet_name="DESNUTRICION")
    cubo_suplementacion.to_excel(writer, sheet_name="SUPLEMENTACION")
    cubo_general.to_excel(writer, sheet_name="CUBO_GENERAL")

print("Cubos OLAP generados y exportados correctamente")