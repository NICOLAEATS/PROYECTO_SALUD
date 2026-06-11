import os
import sys
import shutil
import psycopg2
import re
import tempfile
import time
from datetime import datetime

# Agregar ruta para importar modulos locales
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extractor_archivos import detectar_extractor_rar, extraer_comprimido

# Detectar al cargar el script
EXTRACTOR_RAR_TIPO, EXTRACTOR_RAR_RUTA = detectar_extractor_rar()

def obtener_csv_extraido(carpeta, nombre_base=None, mes_esperado=None):
    """Busca el CSV más probable dentro de una carpeta (incluye subcarpetas)."""
    csvs = []
    for raiz, _, archivos in os.walk(carpeta):
        for nombre in archivos:
            if nombre.lower().endswith(".csv"):
                csvs.append(os.path.join(raiz, nombre))

    if not csvs:
        return None

    candidatos = list(csvs)

    if nombre_base:
        match_base = [
            ruta for ruta in candidatos
            if nombre_base.lower() in os.path.basename(ruta).lower()
        ]
        if match_base:
            candidatos = match_base

    if mes_esperado:
        match_mes = [
            ruta for ruta in candidatos
            if extraer_mes_desde_nombre(os.path.basename(ruta)) == mes_esperado
        ]
        if match_mes:
            candidatos = match_mes

    # Preferir el archivo más "pesado" y reciente (evita seleccionar headers vacíos)
    return max(candidatos, key=lambda p: (os.path.getsize(p), os.path.getctime(p)))

def verificar_csv_valido(ruta_csv):
    """Verifica si el CSV tiene contenido válido."""
    try:
        # Leer primeras líneas para verificar
        with open(ruta_csv, 'r', encoding='latin1') as f:
            header = f.readline()
            if not header.strip():
                return False, "Archivo CSV vacio o solo tiene saltos de linea"
            
            # Leer algunas líneas más para verificar
            lineas_muestra = []
            for _ in range(5):
                linea = f.readline()
                if not linea:
                    break
                lineas_muestra.append(linea)
            
            if len(lineas_muestra) == 0:
                return False, "CSV solo tiene encabezado, sin datos"
            
            # Verificar tamaño del archivo
            tamano = os.path.getsize(ruta_csv)
            if tamano < 100:
                return False, f"Archivo muy pequeno: {tamano} bytes"
            
            return True, None
    except Exception as e:
        return False, str(e)


EXTENSIONES_SOPORTADAS = (".rar", ".zip", ".7z", ".tar.gz", ".tar", ".tgz", ".csv")
COLUMNAS_LIMPIAR_NULL = {
    "apellidos", "nombres", "hemoglobina", "talla", "peso",
    "perimetro_abdominal", "perimetro_cefalico",
    "departamento", "provincia", "distrito",
    "establecimiento", "tipodianoc", "dx1", "dx2", "dx3",
    "codigo_item", "valor_lab",
}


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


def extension_soportada(nombre_archivo):
    nombre = nombre_archivo.lower()
    for ext in EXTENSIONES_SOPORTADAS:
        if nombre.endswith(ext):
            return ext
    return None


def prioridad_archivo_por_extension(ext):
    # Preferir CSV ya extraidos sobre comprimidos
    return 0 if ext == ".csv" else 1


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


def construir_plan_archivos(ruta_crudos_local):
    candidatos = []
    for nombre in os.listdir(ruta_crudos_local):
        if not nombre.upper().startswith("11_CUSCO_"):
            continue

        ext = extension_soportada(nombre)
        if not ext:
            continue

        mes = extraer_mes_desde_nombre(nombre)
        if not mes:
            continue

        ruta = os.path.join(ruta_crudos_local, nombre)
        candidatos.append(
            {
                "nombre": nombre,
                "ruta": ruta,
                "mes": mes,
                "ext": ext,
                "mtime": os.path.getmtime(ruta),
                "prioridad": prioridad_archivo_por_extension(ext),
            }
        )

    por_mes = {}
    for item in candidatos:
        por_mes.setdefault(item["mes"], []).append(item)

    plan = []
    for mes, items in por_mes.items():
        # Menor prioridad = mejor (csv antes que comprimido); luego más reciente
        elegido = sorted(items, key=lambda x: (x["prioridad"], -x["mtime"], x["nombre"]))[0]
        plan.append(elegido)

        if len(items) > 1:
            nombres = ", ".join(x["nombre"] for x in sorted(items, key=lambda x: x["nombre"]))
            print(f"[WARN] Mes {mes}: múltiples archivos detectados. Se usará '{elegido['nombre']}'.")
            print(f"       Candidatos: {nombres}")

    return sorted(plan, key=lambda x: int(x["mes"]))

# ==============================
# 1. CONFIGURACIÓN
# ==============================
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
from db_config import get_db_config

_db_config = get_db_config()

DB = {
    "user": _db_config.user,
    "pass": _db_config.password,
    "host": _db_config.host,
    "port": _db_config.port,
    "db":   _db_config.database
}

anio_proceso       = sys.argv[1] if len(sys.argv) > 1 else "2022"
ruta_crudos_custom = sys.argv[2] if len(sys.argv) > 2 else None

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

# ⚠️ NOMBRE CORRECTO DE LA TABLA
esquema       = _db_config.schema
tabla_nombre  = "hisminsa24"
tabla_destino = f"{esquema}.{tabla_nombre}"

def conectar_db():
    return psycopg2.connect(
        dbname=DB["db"],
        user=DB["user"],
        password=DB["pass"],
        host=DB["host"],
        port=DB["port"],
        connect_timeout=10
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
        print(f"   [INFO] Agregando {len(columnas_nuevas)} columnas nuevas...")
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
# 2. PROCESO DE CARGA ANUAL
# ==============================
print("====================================")
print(f"[CARGA UNIVERSAL] ANO: {anio_proceso}")
print(f"[CARPETA] {ruta_crudos}")
print("====================================")

if not os.path.exists(ruta_crudos):
    print(f"[ERROR] Carpeta no encontrada: {ruta_crudos}")
    sys.exit()

plan_archivos = construir_plan_archivos(ruta_crudos)

if not plan_archivos:
    print(f"[WARN] No se encontraron archivos validos 11_CUSCO_* en: {ruta_crudos}")
    sys.exit()

print(f"[INFO] Meses planificados para carga: {len(plan_archivos)}")
print(f"[PROGRESS] TOTAL={len(plan_archivos)}")

# Mostrar extractor detectado
if EXTRACTOR_RAR_TIPO:
    print(f"[INFO] Usando extractor: {EXTRACTOR_RAR_TIPO} ({EXTRACTOR_RAR_RUTA})")
else:
    print("[WARN] No se detecto extractor externo para RAR (.rar)")

errores = []
procesados_ok = []

for indice, item in enumerate(plan_archivos, start=1):
    nombre_archivo = item["nombre"]
    ruta_full = item["ruta"]
    mes_archivo = item["mes"]
    inicio_item = time.monotonic()
    archivo_csv_temp = None
    es_comprimido = False
    carpeta_temporal = None

    # Extraer nombre base sin extensión para buscar el CSV correcto
    nombre_base = os.path.splitext(nombre_archivo)[0]

    # --- DESCOMPRESION ---
    if nombre_archivo.lower().endswith(".csv"):
        print(f"\n[PROCESANDO] Mes {mes_archivo} - {nombre_archivo}...")
        archivo_csv_temp = ruta_full
        es_comprimido = False
    elif nombre_archivo.lower().endswith((".rar", ".zip", ".7z", ".tar", ".tgz", ".tar.gz")):
        csv_manual = buscar_csv_manual(ruta_crudos, nombre_base, mes_archivo)
        if csv_manual and os.path.exists(csv_manual):
            print(f"\n[PROCESANDO] Mes {mes_archivo} - {os.path.basename(csv_manual)} (ya extraido)...")
            archivo_csv_temp = csv_manual
            es_comprimido = False
        else:
            print(f"\n[PROCESANDO] Mes {mes_archivo} - {nombre_archivo}...")
            carpeta_temporal = tempfile.mkdtemp(prefix=f"tmp_ingesta_{mes_archivo}_", dir=ruta_crudos)
            exito, error = extraer_comprimido(ruta_full, carpeta_temporal)
            if not exito:
                print(f"[ERROR] No se pudo extraer: {error or 'desconocido'}")
                print("[INFO] Si ya lo extrajiste manualmente, verifica carpeta 11_CUSCO_MM/11_CUSCO_MM.csv")
                errores.append((mes_archivo, nombre_archivo, f"Extraccion fallida: {error or 'desconocido'}"))
                print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=error|archivo={nombre_archivo}")
                shutil.rmtree(carpeta_temporal, ignore_errors=True)
                continue
            es_comprimido = True
            archivo_csv_temp = obtener_csv_extraido(carpeta_temporal, nombre_base, mes_archivo)
    else:
        continue

    # --- VERIFICACIÓN DE CSV ---
    if not archivo_csv_temp or not os.path.exists(archivo_csv_temp):
        print(f"[WARN] No se encontro CSV para: {nombre_archivo}")
        errores.append((mes_archivo, nombre_archivo, "CSV no encontrado tras extracción"))
        print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=error|archivo={nombre_archivo}")
        if carpeta_temporal:
            shutil.rmtree(carpeta_temporal, ignore_errors=True)
        continue
    
    # Verificar si el CSV es válido
    csv_valido, error_csv = verificar_csv_valido(archivo_csv_temp)
    if not csv_valido:
        print(f"[ERROR] CSV invalido: {error_csv} - {os.path.basename(archivo_csv_temp)}")
        errores.append((mes_archivo, nombre_archivo, f"CSV inválido: {error_csv}"))
        print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=error|archivo={nombre_archivo}")
        if carpeta_temporal:
            shutil.rmtree(carpeta_temporal, ignore_errors=True)
        continue
    
    tamano = os.path.getsize(archivo_csv_temp)
    print(f"[INFO] CSV: {os.path.basename(archivo_csv_temp)} ({tamano:,} bytes)")

    # Leer header y detectar delimitador
    try:
        with open(archivo_csv_temp, "r", encoding="latin1") as f:
            header = f.readline().lstrip("\ufeff").strip()
            
        # Ver qué delimitador tiene el archivo
        tiene_pipe = '|' in header
        tiene_coma = ',' in header
        delimitador = '|' if tiene_pipe else (',' if tiene_coma else '\t')
        
        print(f"   [DEBUG] Header (primeros 200 chars): {header[:200]}")
        print(f"   [DEBUG] Delimitador detectado: '{delimitador}' (pipe={tiene_pipe}, coma={tiene_coma})")
        
        columnas_csv = [
            c.strip().replace(".", "_").replace(" ", "_").lower()
            for c in header.split(delimitador)
        ]
        columnas_csv = columnas_unicas(columnas_csv)
        print(f"   [DEBUG] Columnas detectadas: {len(columnas_csv)}")
        
    except Exception as e:
        print(f"   [ERROR] Leyendo header CSV: {e}")
        errores.append((mes_archivo, nombre_archivo, f"Error leyendo header CSV: {e}"))
        print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=error|archivo={nombre_archivo}")
        if carpeta_temporal:
            shutil.rmtree(carpeta_temporal, ignore_errors=True)
        continue

    conn = None
    cur = None
    try:
        conn = conectar_db()
        cur = conn.cursor()
        cur.execute("SET synchronous_commit = off;")
        
        # 1. Asegurar esquema y tabla base
        asegurar_tabla_destino(cur, columnas_csv)

        # 2. Crear staging liviana solo con columnas del CSV
        tabla_staging = "tmp_hisminsa24_staging"
        crear_tabla_staging(cur, tabla_staging, columnas_csv)

        # 3. Carga de datos en staging usando COPY
        columnas_sql = ", ".join([f'"{c.lower()}"' for c in columnas_csv])
        print(f"   [TRANSFER] Transfiriendo datos...")
        
        try:
             with open(archivo_csv_temp, "r", encoding="latin1") as f:
                 cur.copy_expert(f"""
COPY {tabla_staging} ({columnas_sql})
                      FROM STDIN WITH (FORMAT CSV, HEADER TRUE,
                      DELIMITER '{delimitador}', ENCODING 'LATIN1')
                 """, f)
             print(f"   [DEBUG] COPY completado sin errores")
        except Exception as copy_err:
            print(f"   [ERROR COPY] {copy_err}")
            conn.rollback()
            errores.append((mes_archivo, nombre_archivo, f"Error COPY: {copy_err}"))
            print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=error|archivo={nombre_archivo}")
            continue

        # 4. Antiduplicados - borrar datos previos del mismo mes/anio (03 y 3)
        mes_sin_cero = str(int(mes_archivo))
        print(f"   [CLEAN] Limpiando {anio_proceso}-{mes_archivo}...")
        cur.execute(
            f"""
            DELETE FROM {tabla_destino}
            WHERE anio = %s
              AND mes IN (%s, %s);
            """,
            (anio_proceso, mes_archivo, mes_sin_cero),
        )

        # 5. Insertar desde staging usando constantes para anio/mes
        columnas_insert_sql, columnas_select_sql, parametros_insert = construir_insert_desde_staging(
            columnas_csv,
            anio_proceso,
            mes_archivo,
        )
        cur.execute(
            f"""
            INSERT INTO {tabla_destino} ({columnas_insert_sql})
            SELECT {columnas_select_sql}
            FROM {tabla_staging};
            """,
            tuple(parametros_insert),
        )
        total_registros = cur.rowcount
        if total_registros is None or total_registros < 0:
            cur.execute(
                f"SELECT COUNT(*) FROM {tabla_staging};"
            )
            total_registros = cur.fetchone()[0]
        
        conn.commit()

        print(f"   [OK] Inyectado ({total_registros:,} registros).")
        procesados_ok.append((mes_archivo, nombre_archivo, total_registros))

        # 7. Registrar en log y limpiar descomprimido temporal
        registrar_csv_subido(nombre_archivo, anio_proceso, mes_archivo, total_registros, ruta_crudos)
        print(f"   [LOG] Registrado en: {LOG_FILE}")
        print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=ok|archivo={nombre_archivo}")

    except Exception as e:
        print(f"[ERROR] Procesando {nombre_archivo}: {e}")
        errores.append((mes_archivo, nombre_archivo, str(e)))
        print(f"[PROGRESS] DONE={indice}/{len(plan_archivos)}|mes={mes_archivo}|estado=error|archivo={nombre_archivo}")
        try:
            if conn:
                conn.rollback()
        except Exception:
            pass
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()
        if carpeta_temporal:
            shutil.rmtree(carpeta_temporal, ignore_errors=True)

    duracion_item = time.monotonic() - inicio_item
    print(f"   [TIME] Mes {mes_archivo}: {duracion_item:.1f}s")

print(f"\n[FINALIZADO] PROCESO ANUAL {anio_proceso}")
print(f"[RESUMEN] OK: {len(procesados_ok)} | ERRORES: {len(errores)}")

if procesados_ok:
    total_general = sum(x[2] for x in procesados_ok)
    print(f"[RESUMEN] Registros insertados: {total_general:,}")

if errores:
    print("\n[DETALLE_ERRORES]")
    for mes, archivo, motivo in errores:
        print(f" - Mes {mes} | {archivo} -> {motivo}")

    print(f"\n[RESUMEN] DE SUBIDAS:")
    print(obtener_resumen_subidos())

    if errores:
        sys.exit(1)
