import sys
import os
import psycopg2

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from db_config import get_db_config

_db_config = get_db_config()

def ejecutar_procedure(ruta_sql, anio=None):
    try:
        with open(ruta_sql, 'r', encoding='utf-8') as f:
            query = f.read()

        if anio:
            query = query.replace('{ANIO}', str(anio))

        conn = psycopg2.connect(
            host=_db_config.host,
            port=_db_config.port,
            database=_db_config.database,
            user=_db_config.user,
            password=_db_config.password
        )
        
        cur = conn.cursor()
        cur.execute(query)
        conn.commit()
        cur.close()
        conn.close()
        
        print("OK: Script ejecutado correctamente")
        print("Archivo: " + os.path.basename(ruta_sql))

    except Exception as e:
        print("ERROR: " + str(e))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Error: No se proporciono la ruta del script SQL")
        sys.exit(1)
    
    anio = sys.argv[2] if len(sys.argv) > 2 else None
    ejecutar_procedure(sys.argv[1], anio)