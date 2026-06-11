import os
import sys
import psycopg2

# Importar configuración flexible de base de datos
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from db_config import get_db_config

# Obtener configuración de base de datos (con valores por defecto para compatibilidad)
_db_config = get_db_config()

# --- Parámetros de conexión ---
usuario = _db_config.user
password = _db_config.password
host = _db_config.host
puerto = _db_config.port
basedatos = _db_config.database

base_path = r"C:\Users\Nouch\Desktop\Proyecto_Salud_Cusco\datos\crudos"
ruta_maestros = os.path.join(base_path, "maestros")

def cargar_maestro_exacto(archivo_buscado, tabla_final):
    archivo_encontrado = None
    for archivo in os.listdir(ruta_maestros):
        if archivo_buscado.lower() in archivo.lower() and archivo.endswith(".csv"):
            archivo_encontrado = os.path.join(ruta_maestros, archivo)
            break

    if not archivo_encontrado:
        print(f"⚠️ No se encontró: {archivo_buscado}")
        return

    print(f"📄 Procesando: {os.path.basename(archivo_encontrado)}")

    try:
        conn = psycopg2.connect(dbname=basedatos, user=usuario, password=password, host=host, port=puerto)
        cur = conn.cursor()
        cur.execute("CREATE SCHEMA IF NOT EXISTS es_ivan;")

        with open(archivo_encontrado, "r", encoding="latin1") as f:
            header = f.readline().strip()
            # Detectamos si es coma o punto y coma
            delimitador = ";" if ";" in header else ","
            # Limpiamos nombres de columnas para que SQL no de errores (quitamos espacios o puntos)
            columnas = [c.strip().replace(".", "_").replace(" ", "_") for c in header.split(delimitador)]

        # 1. Crear la tabla FINAL con todos los campos del CSV
        # Definimos todas como TEXT para evitar errores de formato al inicio
        column_defs = ", ".join([f"{col} TEXT" for col in columnas])
        
        tabla_full = f"es_ivan.{tabla_final}"
        cur.execute(f"DROP TABLE IF EXISTS {tabla_full} CASCADE;")
        cur.execute(f"CREATE TABLE {tabla_full} ({column_defs});")

        # 2. Cargar el CSV directamente a la tabla nueva
        with open(archivo_encontrado, "r", encoding="latin1") as f:
            cur.copy_expert(f"COPY {tabla_full} FROM STDIN WITH CSV HEADER DELIMITER '{delimitador}' ENCODING 'LATIN1'", f)

        cur.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = '{tabla_final}' AND table_schema = 'es_ivan'")
        columnas_todas = [r[0] for r in cur.fetchall()]
        for col in columnas_todas:
            cur.execute(f"UPDATE {tabla_full} SET {col} = '' WHERE {col} IS NULL")

        conn.commit()
        cur.close()
        conn.close()
        print(f"✅ {tabla_final} cargado con las {len(columnas)} columnas originales.")

    except Exception as e:
        print(f"❌ Error en {tabla_final}: {e}")

if __name__ == "__main__":
    # Cargamos 11_MAESTRO (Pacientes)
    cargar_maestro_exacto("11_MAESTRO", "maestro_paciente")
    
    # Cargamos MaestroPersonal con todas sus columnas (Id_Personal, Numero_Documento, etc.)
    cargar_maestro_exacto("MaestroPersonal", "maestro_personal")