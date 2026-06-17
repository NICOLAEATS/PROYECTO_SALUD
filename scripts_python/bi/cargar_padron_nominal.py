import os, sys, csv, re
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
from db_config import get_db_config
import psycopg2
from psycopg2.extras import execute_values

cfg = get_db_config()
ESQUEMA = cfg.schema or 'es_ivan'
TABLA = 'padron_nominal'

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
RUTA_PADRONES = PROJECT_ROOT / 'scripts_sql' / 'PADRONES'

def detectar_csv():
    for f in os.listdir(str(RUTA_PADRONES)):
        if f.lower().startswith('pn_') and f.lower().endswith('.csv'):
            return RUTA_PADRONES / f
    return None

def conectar():
    return psycopg2.connect(
        dbname=cfg.database, user=cfg.user, password=cfg.password,
        host=cfg.host, port=cfg.port
    )

def crear_tabla(conn):
    cur = conn.cursor()
    cur.execute(f"""
        CREATE TABLE IF NOT EXISTS {ESQUEMA}.{TABLA} (
            anio INTEGER, nro INTEGER, t_doc TEXT, padron TEXT,
            cnv TEXT, cnv_cui_dni TEXT, cnv_dni TEXT,
            esttramdni TEXT, fectramdni TEXT,
            apellido_pat_nino TEXT, apellido_mat_nino TEXT, nombre_nino TEXT,
            codsexo INTEGER, fecnac TEXT, edad_actual TEXT,
            eje_vial TEXT, direccion TEXT, direc_ref TEXT,
            latitud DOUBLE PRECISION, longitud DOUBLE PRECISION,
            ubigeo_pn TEXT, dpto_nino TEXT, prov_nino TEXT, dist_nino TEXT,
            ccpp_nino TEXT, nombre_ccpp TEXT, area_ccpp TEXT,
            menor_visitado TEXT, menor_encontrado TEXT, fec_visita TEXT,
            fuente_datos TEXT, fec_fuente TEXT,
            cod_eess_nacimiento TEXT, nombre_eess_nacimiento TEXT,
            cod_eess TEXT, nombre_eess TEXT, atc_frecuente TEXT,
            cod_eess_adcripcion TEXT, nombre_eess_adcripcion TEXT,
            tip_seguro TEXT, cod_progsocial TEXT, prog_social TEXT,
            nombre_ie TEXT, condicion_fam TEXT,
            tdoc_madre TEXT, doc_madre TEXT,
            apellido_pat_madre TEXT, apellido_mat_madre TEXT, nombre_madre TEXT,
            celular TEXT, direccion_correo_madre TEXT,
            grad_int_madre TEXT, lengua_madre TEXT, condicion_familiar TEXT,
            tip_doc_jefe_fam TEXT, nro_doc_jefe_familia TEXT,
            apellido_pat_jefe TEXT, apellido_mat_jefe TEXT, nombre_jefe_fam TEXT,
            estado_civil TEXT, fech_crea TEXT, usuario_que_creea TEXT,
            fech_modif TEXT, fech_umodif TEXT, entidad TEXT, tip_reg TEXT
        )
    """)
    conn.commit()
    cur.close()

def cargar_csv(conn, ruta_csv):
    cur = conn.cursor()
    cur.execute(f"TRUNCATE TABLE {ESQUEMA}.{TABLA}")
    conn.commit()

    def _sanitize(v):
        return v.replace('\x00', '') if v else v

    with open(str(ruta_csv), 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f, delimiter=';')
        cols = reader.fieldnames
        cols_insert = ','.join(cols)
        insert_sql = f"INSERT INTO {ESQUEMA}.{TABLA} ({cols_insert}) VALUES %s"

        count = 0
        errores = 0
        batch = []
        for row in reader:
            try:
                vals = []
                for c in cols:
                    v = _sanitize(row.get(c, '').strip())
                    if c.upper() in ('LATITUD', 'LONGITUD'):
                        try:
                            v = float(v.replace(',', '.')) if v else None
                        except:
                            v = None
                    vals.append(v)
                batch.append(tuple(vals))
                count += 1
                if len(batch) >= 1000:
                    execute_values(cur, insert_sql, batch, page_size=1000)
                    conn.commit()
                    print(f"[PROGRESS] DONE={count}|total=|porcentaje=|eta=")
                    batch = []
            except Exception as e:
                errores += 1
                if errores <= 5:
                    print(f"[ERROR] Fila {count+1}: {e}")

        if batch:
            try:
                execute_values(cur, insert_sql, batch, page_size=1000)
                conn.commit()
            except Exception as e:
                print(f"[ERROR] Batch final: {e}")

    cur.execute(f"ANALYZE {ESQUEMA}.{TABLA}")
    conn.commit()
    cur.close()
    return count

def main():
    ruta_csv = detectar_csv()
    if not ruta_csv:
        print("[ERROR] No se encontró archivo PN CSV en scripts_sql/PADRONES/")
        print("Buscar archivo que empiece con 'pn_' y termine en '.csv'")
        return 1

    print(f"Archivo PN detectado: {ruta_csv.name}")
    conn = conectar()
    crear_tabla(conn)
    total = cargar_csv(conn, ruta_csv)
    conn.close()
    print(f"Padrón Nominal cargado: {total} registros en {ESQUEMA}.{TABLA}")
    return 0

if __name__ == '__main__':
    sys.exit(main())
