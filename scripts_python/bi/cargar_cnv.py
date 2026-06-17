import os, sys, csv
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
from db_config import get_db_config
import psycopg2
from psycopg2.extras import execute_values

cfg = get_db_config()
ESQUEMA = cfg.schema or 'es_ivan'
TABLA = 'cnv_cusco'

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
RUTA_PADRONES = PROJECT_ROOT / 'scripts_sql' / 'PADRONES'

def detectar_csv():
    for f in os.listdir(str(RUTA_PADRONES)):
        if f.upper().startswith('CNV_') and f.lower().endswith('.csv'):
            return RUTA_PADRONES / f
    return None

def conectar():
    return psycopg2.connect(
        dbname=cfg.database, user=cfg.user, password=cfg.password,
        host=cfg.host, port=cfg.port
    )

def _col_name(raw):
    return raw.strip().lower()

def crear_tabla(conn, cols):
    cur = conn.cursor()
    col_defs = ', '.join(f'{_col_name(c)} TEXT' for c in cols)
    sql = f"CREATE TABLE IF NOT EXISTS {ESQUEMA}.{TABLA} ({col_defs})"
    cur.execute(sql)
    conn.commit()
    cur.close()

def cargar_csv(conn, ruta_csv, cols_orig):
    cur = conn.cursor()
    cur.execute(f"TRUNCATE TABLE {ESQUEMA}.{TABLA}")
    conn.commit()

    cols_db = [_col_name(c) for c in cols_orig]
    cols_insert = ','.join(cols_db)
    insert_sql = f"INSERT INTO {ESQUEMA}.{TABLA} ({cols_insert}) VALUES %s"

    def _sanitize(v):
        return v.replace('\x00', '') if v else v

    count = 0
    errores = 0
    batch = []
    with open(str(ruta_csv), 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f, delimiter=',')
        for row in reader:
            try:
                vals = tuple(_sanitize(row.get(c, '').strip()) for c in cols_orig)
                batch.append(vals)
                count += 1
                if len(batch) >= 5000:
                    execute_values(cur, insert_sql, batch, page_size=5000)
                    batch = []
                    print(f"[PROGRESS] DONE={count}|total=|porcentaje=|eta=")
            except Exception as e:
                errores += 1
                if errores <= 5:
                    print(f"[ERROR] Fila {count+1}: {e}")

    if batch:
        try:
            execute_values(cur, insert_sql, batch, page_size=5000)
        except Exception as e:
            print(f"[ERROR] Batch final: {e}")

    conn.commit()
    cur.execute(f"ANALYZE {ESQUEMA}.{TABLA}")
    conn.commit()
    cur.close()
    return count

def main():
    ruta_csv = detectar_csv()
    if not ruta_csv:
        print("[ERROR] No se encontró archivo CNV CSV en scripts_sql/PADRONES/")
        print("Buscar archivo que empiece con 'CNV_' y termine en '.csv'")
        return 1

    print(f"Archivo CNV detectado: {ruta_csv.name}")

    with open(str(ruta_csv), 'r', encoding='utf-8-sig') as f:
        reader = csv.reader(f, delimiter=',')
        cols_orig = next(reader)

    conn = conectar()
    crear_tabla(conn, cols_orig)
    total = cargar_csv(conn, ruta_csv, cols_orig)
    conn.close()
    print(f"CNV cargado: {total} registros en {ESQUEMA}.{TABLA}")
    return 0

if __name__ == '__main__':
    sys.exit(main())
