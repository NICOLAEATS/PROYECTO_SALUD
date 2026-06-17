import os
import shutil
import sys
import psycopg2
import subprocess

CREATE_NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))
from db_config import get_db_config

# --- Parámetros de conexión ---
_cfg = get_db_config()
usuario = _cfg.user
password = _cfg.password
host = _cfg.host
puerto = _cfg.port
basedatos = _cfg.database

# --- Rutas ---
ruta_csv = r"D:\PROCESO_POSTGRES2024\import\cnv_padron"
ruta_procesados = r"D:\PROCESO_POSTGRES2024\import\procesados"
psql_path = r"C:\Program Files\PostgreSQL\15\bin\psql.exe"  # 👈 Ajusta si es otra versión

# --- Tabla destino ---
esquema = _cfg.schema or "public"
tabla = "padron_trama"
tabla_destino = f"{esquema}.{tabla}"

print("📂 Buscando archivo...")
archivo_csv = None
for archivo in os.listdir(ruta_csv):
    if archivo.lower().startswith("padronn_trama") and archivo.lower().endswith(".csv"):
        archivo_csv = os.path.join(ruta_csv, archivo)
        break

if not archivo_csv:
    print("❌ No se encontró un archivo que empiece con 'PadronN_Trama' y termine en '.csv'")
    exit()

print(f"📄 Detectado archivo: {archivo_csv}")

# --- Detectar delimitador ---
with open(archivo_csv, "r", encoding="latin1") as f:
    primera_linea = f.readline()
    delimitador = ";" if ";" in primera_linea else ","
print(f"🔎 Delimitador detectado: '{delimitador}'")

try:
    # --- Conexión psycopg2 ---
    print("🔗 Conectando a PostgreSQL con psycopg2...")
    conn = psycopg2.connect(
        dbname=basedatos,
        user=usuario,
        password=password,
        host=host,
        port=puerto
    )
    cur = conn.cursor()

    # Vaciar tabla
    cur.execute(f"TRUNCATE TABLE {tabla_destino} RESTART IDENTITY CASCADE")
    conn.commit()
    print(f"🗑️ Tabla {tabla_destino} vaciada")

    # Cargar CSV
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

    print(f"🚀 Carga completada con psycopg2 en {tabla_destino}")

    # Mover archivo
    destino = os.path.join(ruta_procesados, os.path.basename(archivo_csv))
    shutil.move(archivo_csv, destino)
    print(f"📦 Archivo movido a: {destino}")

except Exception as e:
    print(f"⚠️ Error con psycopg2, intentando con psql \\COPY...\n{e}")
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
        env["PGPASSWORD"] = password  # pasar password de forma segura
        subprocess.run(cmd, env=env, check=True, creationflags=CREATE_NO_WINDOW)

        print(f"🚀 Carga completada con psql en {tabla_destino}")

        # Mover archivo
        destino = os.path.join(ruta_procesados, os.path.basename(archivo_csv))
        shutil.move(archivo_csv, destino)
        print(f"📦 Archivo movido a: {destino}")

    except Exception as e2:
        print(f"❌ Falló también con psql\n{e2}")
