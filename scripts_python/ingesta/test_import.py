import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

print('[1] Imports done')
from db_config import get_db_config
print('[2] db_config imported')

_db_config = get_db_config()
print('[3] Config obtained')

DB = {
    "user": _db_config.user,
    "pass": _db_config.password,
    "host": _db_config.host,
    "port": _db_config.port,
    "db":   _db_config.database
}
print('[4] DB dict created')

esquema = _db_config.schema
tabla_nombre = "hisminsa24"
tabla_destino = f"{esquema}.{tabla_nombre}"
print(f'[5] Tabla destino: {tabla_destino}')

import psycopg2
print('[6] psycopg2 ready')

def conectar_db():
    return psycopg2.connect(
        dbname=DB["db"],
        user=DB["user"],
        password=DB["pass"],
        host=DB["host"],
        port=DB["port"],
        connect_timeout=10
    )

print('[7] Intentar conectar...')
conn = conectar_db()
print('[8] Conexion exitosa!')
conn.close()
print('[9] Done!')
