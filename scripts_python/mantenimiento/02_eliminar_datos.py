import sys
import os
import psycopg2

# Importar configuración flexible de base de datos
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from db_config import get_db_config

# Obtener configuración de base de datos (con valores por defecto para compatibilidad)
_db_config = get_db_config()

# ==============================
# CONFIGURACIÓN
# ==============================
DB = {
    "user": _db_config.user, 
    "pass": _db_config.password, 
    "host": _db_config.host, 
    "port": _db_config.port, 
    "db":   _db_config.database
}

# Argumentos que vienen desde el main.py
modo = sys.argv[1] if len(sys.argv) > 1 else "todo"
anio = sys.argv[2] if len(sys.argv) > 2 else None
mes = sys.argv[3] if len(sys.argv) > 3 else None

# Nombre de tu nueva tabla central (usando esquema configurable)
tabla_destino = f"{_db_config.schema}.hisminsa_consolidado"

def conectar_db():
    return psycopg2.connect(
        dbname=DB["db"], user=DB["user"], password=DB["pass"], 
        host=DB["host"], port=DB["port"]
    )

def ejecutar_borrado():
    conn = None
    try:
        conn = conectar_db()
        cur = conn.cursor()
        
        if modo == "todo":
            print(f"⚠️ Vaciando TODA la tabla {tabla_destino}...")
            cur.execute(f"TRUNCATE TABLE {tabla_destino};")
            print("✅ Tabla vaciada completamente.")
            
        elif modo == "anio":
            print(f"🧹 Eliminando datos del año {anio}...")
            cur.execute(f"DELETE FROM {tabla_destino} WHERE anio = %s;", (anio,))
            print(f"✅ Año {anio} eliminado de la base de datos.")
            
        elif modo == "mes":
            print(f"🧹 Eliminando datos de {anio} - Mes {mes}...")
            cur.execute(f"DELETE FROM {tabla_destino} WHERE anio = %s AND mes = %s;", (anio, mes))
            print(f"✅ Mes {mes} del año {anio} eliminado.")
            
        conn.commit()
        cur.close()
    except Exception as e:
        print(f"❌ Error al borrar: {e}")
    finally:
        if conn: conn.close()

if __name__ == "__main__":
    ejecutar_borrado()