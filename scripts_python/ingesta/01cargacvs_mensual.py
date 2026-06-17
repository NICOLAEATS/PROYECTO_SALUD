import os
import sys
import shutil
import psycopg2
import re
import tempfile
from datetime import datetime

# Agregar ruta para importar modulos locales
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extractor_archivos import detectar_extractor_rar, extraer_comprimido

EXTRACTOR_RAR_TIPO, EXTRACTOR_RAR_RUTA = detectar_extractor_rar()

def extraer_mes_desde_nombre(nombre_archivo):
    match = re.match(r"^11_CUSCO_(\d{1,2})(?:\D|$)", nombre_archivo, flags=re.IGNORECASE)
    if not match:
        return None
    try:
        mes = int(match.group(1))
    except ValueError:
        return None
    if 1 <= mes <= 12:
        return f"{mes:02d}"
    return None


def obtener_csv_extraido(carpeta, nombre_base=None, mes_esperado=None):
    csvs = []
    for raiz, _, archivos in os.walk(carpeta):
        for nombre in archivos:
            if nombre.lower().endswith(".csv"):
                csvs.append(os.path.join(raiz, nombre))

    if not csvs:
        return None

    if nombre_base:
        match_base = [
            ruta for ruta in csvs
            if nombre_base.lower() in os.path.basename(ruta).lower()
        ]
        if match_base:
            csvs = match_base

    if mes_esperado:
        match_mes = [
            ruta for ruta in csvs
            if extraer_mes_desde_nombre(os.path.basename(ruta)) == mes_esperado
        ]
        if match_mes:
            csvs = match_mes

    return max(csvs, key=lambda p: (os.path.getsize(p), os.path.getctime(p)))

def verificar_csv_valido(ruta_csv):
    """Verifica si el CSV tiene contenido."""
    try:
        with open(ruta_csv, 'r', encoding='latin1') as f:
            header = f.readline()
            if not header.strip():
                return False, "Archivo vacio"
            tamano = os.path.getsize(ruta_csv)
            if tamano < 100:
                return False, f"Muy pequeno: {tamano} bytes"
            return True, None
    except Exception as e:
        return False, str(e)


def buscar_csv_manual(ruta_crudos_local, nombre_base, mes_esperado=None):
    ruta_csv_raiz = os.path.join(ruta_crudos_local, f"{nombre_base}.csv")
    if os.path.exists(ruta_csv_raiz):
        return ruta_csv_raiz

    ruta_subcarpeta = os.path.join(ruta_crudos_local, nombre_base)
    ruta_csv_subcarpeta = os.path.join(ruta_subcarpeta, f"{nombre_base}.csv")
    if os.path.exists(ruta_csv_subcarpeta):
        return ruta_csv_subcarpeta

    if os.path.isdir(ruta_subcarpeta):
        return obtener_csv_extraido(ruta_subcarpeta, nombre_base, mes_esperado)

    return None


COLUMNAS_LIMPIAR_NULL = {
    "apellidos", "nombres", "hemoglobina", "talla", "peso",
    "perimetro_abdominal", "perimetro_cefalico",
    "departamento", "provincia", "distrito",
    "establecimiento", "tipodianoc", "dx1", "dx2", "dx3",
    "codigo_item", "valor_lab",
}

# ==============================
# CONFIGURACIÓN
# ==============================
# Importar configuración flexible de base de datos
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
from db_config import get_db_config

# Obtener configuración de base de datos (con valores por defecto para compatibilidad)
_db_config = get_db_config()

DB = {
    "user": _db_config.user, 
    "pass": _db_config.password, 
    "host": _db_config.host, 
    "port": _db_config.port, 
    "db":   _db_config.database
}

# Recibe argumentos: Año, Mes y opcionalmente la ruta de crudos
anio_proceso = sys.argv[1] if len(sys.argv) > 1 else "2023"
mes_proceso  = sys.argv[2] if len(sys.argv) > 2 else "01"
try:
    mes_proceso = f"{int(mes_proceso):02d}"
except Exception:
    mes_proceso = str(mes_proceso).zfill(2)
# Si se pasa una ruta personalizada desde la interfaz, se usa esa;
# si no, se calcula automáticamente desde la ubicación del script.
ruta_crudos_custom = sys.argv[3] if len(sys.argv) > 3 else None

base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

if ruta_crudos_custom:
    ruta_crudos = ruta_crudos_custom
else:
    ruta_crudos = os.path.join(base_dir, "datos", "maestr", anio_proceso)

# ==============================
# LOG DE CSVs SUBIDOS
# ==============================
LOG_DIR = os.path.join(base_dir, "logs")
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, "csvs_subidos.log")

def registrar_csv_subido(nombre_archivo, anio, mes, total_registros, carpeta_origen):
    """Registra la subida de un CSV en el log."""
    fecha_hora = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    linea = f"[{fecha_hora}] | {anio}/{mes} | {total_registros:,} reg | {nombre_archivo} | Origen: {carpeta_origen}\n"
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(linea)

def obtener_resumen_subidos():
    """Retorna un resumen de CSVs subidos por año/mes."""
    if not os.path.exists(LOG_FILE):
        return "Sin registros aún."
    with open(LOG_FILE, "r", encoding="utf-8") as f:
        lineas = f.readlines()
    if not lineas:
        return "Sin registros aún."
    resumen = {}
    for linea in lineas:
        partes = linea.strip().split(" | ")
        if len(partes) >= 3:
            anio_mes = partes[1]
            regs = partes[2]
            resumen[anio_mes] = regs
    return "\n".join([f"{k}: {v}" for k, v in resumen.items()])

# ⚠️ NOMBRE CORRECTO DE LA TABLA (usado por el script SQL de his_proceso)
esquema       = _db_config.schema
tabla_nombre  = "hisminsa24"
tabla_destino = f"{esquema}.{tabla_nombre}"

def conectar_db():
    return psycopg2.connect(
        dbname=DB["db"],
        user=DB["user"],
        password=DB["pass"],
        host=DB["host"],
        port=DB["port"]
    )


def columnas_unicas(columnas):
    vistas = set()
    resultado = []
    for columna in columnas:
        col = (columna or "").strip().lower()
        if not col or col in vistas:
            continue
        vistas.add(col)
        resultado.append(col)
    return resultado


def asegurar_tabla_destino(cur, columnas_csv):
    cur.execute(f"CREATE SCHEMA IF NOT EXISTS {esquema};")
    cur.execute(f"CREATE TABLE IF NOT EXISTS {tabla_destino} (anio TEXT, mes TEXT);")
    cur.execute(
        f"""
        CREATE INDEX IF NOT EXISTS idx_{tabla_nombre}_anio_mes
        ON {tabla_destino} (anio, mes);
        """
    )
    cur.execute(
        f"""
        SELECT column_name FROM information_schema.columns
        WHERE table_schema = '{esquema}' AND table_name = '{tabla_nombre}';
        """
    )
    columnas_db = [row[0].lower() for row in cur.fetchall()]
    columnas_nuevas = [col for col in columnas_csv if col not in columnas_db]

    if columnas_nuevas:
        print(f"[INFO] Agregando {len(columnas_nuevas)} columnas nuevas...")
        for col_nueva in columnas_nuevas:
            cur.execute(f'ALTER TABLE {tabla_destino} ADD COLUMN "{col_nueva}" TEXT;')


def crear_tabla_staging(cur, tabla_staging, columnas_csv):
    col_defs = ", ".join([f'"{c}" TEXT' for c in columnas_csv])
    cur.execute(f"DROP TABLE IF EXISTS {tabla_staging};")
    cur.execute(f"CREATE TEMP TABLE {tabla_staging} ({col_defs}) ON COMMIT DROP;")


def construir_insert_desde_staging(columnas_csv, anio, mes):
    columnas_insertar = list(dict.fromkeys(columnas_csv + ["anio", "mes"]))
    columnas_insert_sql = ", ".join([f'"{c}"' for c in columnas_insertar])
    expresiones = []
    parametros = []

    for columna in columnas_insertar:
        if columna == "anio":
            expresiones.append('%s AS "anio"')
            parametros.append(anio)
        elif columna == "mes":
            expresiones.append('%s AS "mes"')
            parametros.append(mes)
        elif columna in COLUMNAS_LIMPIAR_NULL:
            expresiones.append(f'COALESCE("{columna}", \'\') AS "{columna}"')
        else:
            expresiones.append(f'"{columna}"')

    return columnas_insert_sql, ", ".join(expresiones), parametros

# ==============================
# PROCESO DE CARGA MENSUAL
# ==============================
if not os.path.exists(ruta_crudos):
    print(f"[ERROR] Carpeta no encontrada: {ruta_crudos}")
    sys.exit()

# Buscar el archivo del mes (Ej: 11_CUSCO_01.rar, 11_CUSCO_01.csv o 11_CUSCO_01/11_CUSCO_01.csv)
nombre_base = f"11_CUSCO_{mes_proceso}"
archivo_encontrado = None
ruta_full = None
archivo_csv_temp = None
es_comprimido = False

csv_manual = buscar_csv_manual(ruta_crudos, nombre_base, mes_proceso)
if csv_manual and os.path.exists(csv_manual):
    archivo_encontrado = os.path.basename(csv_manual)
    ruta_full = csv_manual
    archivo_csv_temp = csv_manual
else:
    extensiones = (".rar", ".zip", ".7z", ".tar", ".tgz", ".tar.gz", ".csv")
    candidatos = [
        f for f in os.listdir(ruta_crudos)
        if f.upper().startswith(nombre_base.upper()) and any(f.lower().endswith(ext) for ext in extensiones)
    ]

    if not candidatos:
        print(f"[WARN] No se encontro archivo del mes {mes_proceso} en {ruta_crudos}")
        sys.exit()

    def _prioridad(nombre):
        return 0 if nombre.lower().endswith(".csv") else 1

    candidatos.sort(
        key=lambda nombre: (
            _prioridad(nombre),
            -os.path.getmtime(os.path.join(ruta_crudos, nombre)),
            nombre.lower(),
        )
    )
    archivo_encontrado = candidatos[0]
    ruta_full = os.path.join(ruta_crudos, archivo_encontrado)

print(f"\n[INICIO] CARGA MENSUAL: {anio_proceso} - MES {mes_proceso}")
print(f"[CARPETA] {ruta_crudos}")
print("[PROGRESS] TOTAL=1")
if EXTRACTOR_RAR_TIPO:
    print(f"[INFO] Usando extractor: {EXTRACTOR_RAR_TIPO} ({EXTRACTOR_RAR_RUTA})")
else:
    print("[WARN] No se detecto extractor externo para RAR (.rar)")

# --- DESCOMPRESIÓN ---
carpeta_temp = None
if archivo_csv_temp is None and archivo_encontrado.lower().endswith((".rar", ".zip", ".7z", ".tar", ".tgz", ".tar.gz")):
    nombre_base_archivo = os.path.splitext(archivo_encontrado)[0]
    csv_manual = buscar_csv_manual(ruta_crudos, nombre_base_archivo, mes_proceso)
    if csv_manual and os.path.exists(csv_manual):
        print(f"[INFO] Usando CSV ya extraido: {os.path.basename(csv_manual)}")
        archivo_csv_temp = csv_manual
    else:
        print(f"[INFO] Descomprimiendo: {archivo_encontrado}...")
        carpeta_temp = tempfile.mkdtemp(prefix=f"tmp_ingesta_{mes_proceso}_", dir=ruta_crudos)
        exito, error = extraer_comprimido(ruta_full, carpeta_temp)
        if not exito:
            print(f"[ERROR] No se pudo extraer: {error or 'desconocido'}")
            print("[INFO] Si ya lo extrajiste manualmente, valida 11_CUSCO_MM/11_CUSCO_MM.csv")
            print(f"[PROGRESS] DONE=1/1|mes={mes_proceso}|estado=error|archivo={archivo_encontrado}")
            shutil.rmtree(carpeta_temp, ignore_errors=True)
            sys.exit()
        es_comprimido = True
        archivo_csv_temp = obtener_csv_extraido(carpeta_temp, nombre_base_archivo, mes_proceso)
elif archivo_csv_temp is None:
    archivo_csv_temp = ruta_full

# --- VERIFICACIÓN DE CSV ---
if not archivo_csv_temp or not os.path.exists(archivo_csv_temp):
    print(f"[ERROR] No se encontro CSV para: {archivo_encontrado}")
    print(f"[PROGRESS] DONE=1/1|mes={mes_proceso}|estado=error|archivo={archivo_encontrado}")
    if carpeta_temp:
        shutil.rmtree(carpeta_temp, ignore_errors=True)
    sys.exit()

csv_valido, error_csv = verificar_csv_valido(archivo_csv_temp)
if not csv_valido:
    print(f"[ERROR] CSV invalido: {error_csv}")
    print(f"[PROGRESS] DONE=1/1|mes={mes_proceso}|estado=error|archivo={archivo_encontrado}")
    if carpeta_temp:
        shutil.rmtree(carpeta_temp, ignore_errors=True)
    sys.exit()

tamano = os.path.getsize(archivo_csv_temp)
print(f"[INFO] CSV: {os.path.basename(archivo_csv_temp)} ({tamano:,} bytes)")

# --- INYECCIÓN ---
if archivo_csv_temp and os.path.exists(archivo_csv_temp):
    conn = None
    cur  = None
    try:
        conn = conectar_db()
        cur  = conn.cursor()

        # 1. Leer columnas del CSV
        with open(archivo_csv_temp, "r", encoding="latin1") as f:
            header     = f.readline().lstrip("\ufeff").strip()
            delimitador = '|' if '|' in header else ','
            columnas_csv = [
                c.strip().replace(".", "_").replace(" ", "_").lower()
                for c in header.split(delimitador)
            ]
            columnas_csv = columnas_unicas(columnas_csv)

        cur.execute("SET synchronous_commit = off;")

        # 2. Asegurar esquema y tabla base
        asegurar_tabla_destino(cur, columnas_csv)

        tabla_staging = "tmp_hisminsa24_staging"
        crear_tabla_staging(cur, tabla_staging, columnas_csv)

        # 3. Carga a tabla staging
        columnas_sql = ", ".join([f'"{c.lower()}"' for c in columnas_csv])
        print("[TRANSFER] Transfiriendo datos a PostgreSQL...")
        with open(archivo_csv_temp, "r", encoding="latin1") as f:
            cur.copy_expert(f"""
                COPY {tabla_staging} ({columnas_sql})
                FROM STDIN WITH (FORMAT CSV, HEADER TRUE,
                DELIMITER '{delimitador}', ENCODING 'LATIN1')
            """, f)

        # 4. Borrar datos previos del mismo mes (antiduplicados 03 y 3)
        mes_sin_cero = str(int(mes_proceso))
        print(f"[CLEAN] Eliminando registros previos de {anio_proceso}-{mes_proceso}...")
        cur.execute(
            f"""
            DELETE FROM {tabla_destino}
            WHERE anio = %s
              AND mes IN (%s, %s);
            """,
            (anio_proceso, mes_proceso, mes_sin_cero)
        )

        # 5. Insertar desde staging usando constantes para anio/mes
        columnas_insert_sql, columnas_select_sql, parametros_insert = construir_insert_desde_staging(
            columnas_csv,
            anio_proceso,
            mes_proceso,
        )
        cur.execute(
            f"""
            INSERT INTO {tabla_destino} ({columnas_insert_sql})
            SELECT {columnas_select_sql}
            FROM {tabla_staging};
            """,
            tuple(parametros_insert)
        )
        total_registros = cur.rowcount
        if total_registros is None or total_registros < 0:
            cur.execute(f"SELECT COUNT(*) FROM {tabla_staging};")
            total_registros = cur.fetchone()[0]
        
        conn.commit()
        
        print(f"[OK] Mes {mes_proceso} inyectado ({total_registros:,} registros).")

        # 7. Registrar en log y limpiar descomprimido temporal
        registrar_csv_subido(archivo_encontrado, anio_proceso, mes_proceso, total_registros, ruta_crudos)
        print(f"   [LOG] Registrado en: {LOG_FILE}")
        print(f"[PROGRESS] DONE=1/1|mes={mes_proceso}|estado=ok|archivo={archivo_encontrado}")

        if carpeta_temp:
            shutil.rmtree(carpeta_temp, ignore_errors=True)
            print("[CLEAN] Carpeta temporal eliminada.")

        print(f"\n[RESUMEN] DE SUBIDAS:")
        print(obtener_resumen_subidos())

    except Exception as e:
        if conn:
            conn.rollback()
        print(f"[ERROR] En carga: {e}")
        print(f"[PROGRESS] DONE=1/1|mes={mes_proceso}|estado=error|archivo={archivo_encontrado}")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()
        if carpeta_temp and os.path.exists(carpeta_temp):
            shutil.rmtree(carpeta_temp, ignore_errors=True)
else:
    print("[ERROR] No se encontro el archivo CSV para procesar.")
    print(f"[PROGRESS] DONE=1/1|mes={mes_proceso}|estado=error|archivo={archivo_encontrado}")
