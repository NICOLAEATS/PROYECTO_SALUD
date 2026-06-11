
#import pandas as pd
import os
import shutil
import sys
from sqlalchemy import create_engine, text

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))
from db_config import get_db_config

# ==============================
# Parámetros de conexión
# ==============================
_cfg = get_db_config()
usuario = _cfg.user
password = _cfg.password
host = _cfg.host
puerto = _cfg.port
basedatos = _cfg.database

# ==============================
# Rutas
# ==============================
ruta_csv = r"D:\PROCESO_POSTGRES2024\import\BASESCVS"
ruta_procesados = r"D:\PROCESO_POSTGRES2024\import\procesados"

# Crear carpeta procesados si no existe
os.makedirs(ruta_procesados, exist_ok=True)

# ==============================
# Tabla destino
# ==============================
esquema = _cfg.schema or "public"
tabla = "hisminsa24"
tabla_destino = f"{esquema}.{tabla}"

# ==============================
# Crear conexión
# ==============================
engine = create_engine(
    f"postgresql+psycopg2://{usuario}:{password}@{host}:{puerto}/{basedatos}"
)

# ==============================
# Eliminar datos 2023
# ==============================
with engine.begin() as conn:
    print("🗑️ Eliminando datos del año 2023...")
    conn.execute(text(f"DELETE FROM {tabla_destino} WHERE anio = 2023;"))
    print("✅ Datos eliminados.")

# ==============================
# Procesar archivos
# ==============================
for archivo in os.listdir(ruta_csv):

    if "2023" in archivo and archivo.lower().endswith(".csv"):

        ruta_archivo = os.path.join(ruta_csv, archivo)
        conn = None
        cursor = None

        try:
            print(f"📂 Cargando archivo: {archivo} ...")

            # Conexión RAW para COPY
            conn = engine.raw_connection()
            cursor = conn.cursor()

            with open(ruta_archivo, "r", encoding="latin1") as f:
                cursor.copy_expert(
                    f"""
                    COPY {tabla_destino}
                    FROM STDIN
                    WITH (
                        FORMAT CSV,
                        HEADER TRUE,
                        DELIMITER ',',
                        ENCODING 'LATIN1'
                    )
                    """,
                    f
                )

            conn.commit()

            cursor.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = '{tabla_nombre}' AND table_schema = 'es_ivan'")
            columnas_todas = [r[0] for r in cursor.fetchall()]
            for col in columnas_todas:
                cursor.execute(f"UPDATE {tabla_destino} SET {col} = '' WHERE {col} IS NULL")

            conn.commit()
            print(f"✅ Archivo {archivo} cargado con éxito.")

            # Mover archivo procesado
            shutil.move(ruta_archivo, os.path.join(ruta_procesados, archivo))
            print(f"📦 Archivo {archivo} movido a procesados.")

        except Exception as e:
            if conn:
                conn.rollback()
            print(f"❌ Error al cargar {archivo}: {e}")

        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()

print("🎯 Proceso finalizado.")
