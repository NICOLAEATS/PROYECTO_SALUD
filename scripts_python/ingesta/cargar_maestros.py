"""
cargar_maestros.py
Carga uno o todos los archivos CSV de maestros a PostgreSQL.
Uso:
    python cargar_maestros.py <ruta_carpeta_maestros> [nombre_archivo.csv]
    Si no se pasa nombre_archivo, carga TODOS los CSV de la carpeta.
"""
import os
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
import psycopg2

# Importar configuración flexible de base de datos
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
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

ESQUEMA = _db_config.schema

# Mapeo: nombre de archivo (sin extensión, en minúsculas) → nombre de tabla en PostgreSQL
# Los que no están aquí se cargan con el nombre derivado automáticamente del archivo.
MAPA_TABLAS = {
    "11_maestro":                        "maestro_paciente",
    "maestropersonal":                   "maestro_personal",
    "maestro_his_actividad_his":         "maestro_his_actividad",
    "maestro_his_centro_poblado":        "maestro_his_centro_poblado",
    "maestro_his_cie_cpms":              "maestro_his_cie_cpms",
    "maestro_his_colegio":               "maestro_his_colegio",
    "maestro_his_condicion_contrato":    "maestro_his_condicion_contrato",
    "maestro_his_dosis":                 "maestro_his_dosis",
    "maestro_his_establecimiento":       "maestro_his_establecimiento",
    "maestro_his_establecimiento25":     "maestro_his_establecimiento",
    "maestro_his_etnia":                 "maestro_his_etnia",
    "maestro_his_financiador":           "maestro_his_financiador",
    "maestro_his_gruporiesgo_lab":       "maestro_his_gruporiesgo_lab",
    "maestro_his_institucion_educativa": "maestro_his_institucion_edu",
    "maestro_his_lab":                   "maestro_his_lab",
    "maestro_his_otra_condicion":        "maestro_his_otra_condicion",
    "maestro_his_pais":                  "maestro_his_pais",
    "maestro_his_profesion":             "maestro_his_profesion",
    "maestro_his_sistema":               "maestro_his_sistema",
    "maestro_his_tipo_doc":              "maestro_his_tipo_doc",
    "maestro_his_ubigeo_inei_reniec":    "maestro_his_ubigeo",
    "maestro_his_ups":                   "maestro_his_ups",
    "susalud26":                         "maestro_eess_susalud",
    "maestro_his_susalud":               "maestro_eess_susalud",
    "maestro_eess_susalud":              "maestro_eess_susalud",
}

TABLA_A_CLAVES = {}
for clave, tabla in MAPA_TABLAS.items():
    TABLA_A_CLAVES.setdefault(tabla, set()).add(clave)


def conectar():
    return psycopg2.connect(
        dbname=DB["db"], user=DB["user"],
        password=DB["pass"], host=DB["host"], port=DB["port"]
    )


def nombre_tabla(nombre_archivo_sin_ext: str) -> str:
    clave = nombre_archivo_sin_ext.lower().strip()
    return MAPA_TABLAS.get(clave, f"maestro_{clave}")


def buscar_archivo_por_tabla(carpeta: str, tabla_objetivo: str) -> str | None:
    csvs = sorted([f for f in os.listdir(carpeta) if f.lower().endswith(".csv")])
    tabla_objetivo = tabla_objetivo.lower().strip()

    # Intento 1: mapear por la misma lógica de nombre_tabla
    for archivo in csvs:
        nombre = os.path.splitext(archivo)[0]
        if nombre_tabla(nombre) == tabla_objetivo:
            return archivo

    # Intento 2: coincidencia por nombre parcial del archivo
    for archivo in csvs:
        nombre = os.path.splitext(archivo)[0].lower().strip()
        if tabla_objetivo in nombre:
            return archivo

    # Intento 3: usar alias conocidos del mapa
    for alias in TABLA_A_CLAVES.get(tabla_objetivo, set()):
        for archivo in csvs:
            nombre = os.path.splitext(archivo)[0].lower().strip()
            if alias in nombre:
                return archivo

    return None


def resolver_archivos_por_tablas(carpeta: str, tablas_objetivo: list[str]) -> tuple[list[str], list[str]]:
    archivos = []
    faltantes = []
    vistos = set()

    for tabla in tablas_objetivo:
        tabla_norm = (tabla or "").strip().lower()
        if not tabla_norm or tabla_norm in {"todos", "all"}:
            continue

        archivo = buscar_archivo_por_tabla(carpeta, tabla_norm)
        if not archivo:
            faltantes.append(tabla_norm)
            continue

        if archivo not in vistos:
            vistos.add(archivo)
            archivos.append(archivo)

    return archivos, faltantes


def cargar_csv(ruta_csv: str, conn) -> bool:
    nombre_archivo = os.path.splitext(os.path.basename(ruta_csv))[0]
    tabla          = nombre_tabla(nombre_archivo)
    tabla_full     = f"{ESQUEMA}.{tabla}"

    print(f"\n📄 Procesando: {os.path.basename(ruta_csv)}")
    print(f"   → Tabla destino: {tabla_full}")

    cur = conn.cursor()
    try:
        # Leer encabezado para detectar columnas y delimitador
        with open(ruta_csv, "r", encoding="latin1") as f:
            header     = f.readline().strip()
            delimitador = "|" if "|" in header else (";" if ";" in header else ",")
            columnas   = [
                c.strip().replace(".", "_").replace(" ", "_").lower()
                for c in header.split(delimitador)
            ]

        # Crear esquema si no existe
        cur.execute(f"CREATE SCHEMA IF NOT EXISTS {ESQUEMA};")

        # Crear tabla si no existe (todo TEXT para evitar errores de tipo)
        col_defs = ", ".join([f'"{c}" TEXT' for c in columnas])
        cur.execute(f"CREATE TABLE IF NOT EXISTS {tabla_full} ({col_defs});")
        conn.commit()

        # Agregar columnas nuevas si el CSV evolucionó
        cur.execute(f"""
            SELECT column_name FROM information_schema.columns
            WHERE table_schema = '{ESQUEMA}' AND table_name = '{tabla}';
        """)
        cols_existentes = {r[0].lower() for r in cur.fetchall()}
        for col in columnas:
            if col not in cols_existentes:
                cur.execute(f'ALTER TABLE {tabla_full} ADD COLUMN "{col}" TEXT;')
                print(f"   ➕ Columna nueva: {col}")
        conn.commit()

        # Vaciar y recargar (truncate para velocidad)
        cur.execute(f"TRUNCATE TABLE {tabla_full};")

        col_sql = ", ".join([f'"{c}"' for c in columnas])
        with open(ruta_csv, "r", encoding="latin1") as f:
            cur.copy_expert(f"""
                COPY {tabla_full} ({col_sql})
                FROM STDIN WITH (FORMAT CSV, HEADER TRUE,
                DELIMITER '{delimitador}', ENCODING 'LATIN1')
            """, f)

        conn.commit()
        cur.close()
        print(f"   [OK] Cargado correctamente.")
        return True

    except Exception as e:
        conn.rollback()
        cur.close()
        print(f"   [ERROR] {e}")
        return False


def main():
    if len(sys.argv) < 2:
        print("[ERROR] Uso: python cargar_maestros.py <carpeta> [archivo.csv]")
        print("   o:  python cargar_maestros.py <carpeta> --tabla <tabla_destino>")
        print("   o:  python cargar_maestros.py <carpeta> --tablas <tabla_a> <tabla_b> ...")
        print("   o:  python cargar_maestros.py <carpeta> --archivos <a.csv> <b.csv> ...")
        sys.exit(1)

    carpeta = sys.argv[1]
    archivo_filtro = None
    tabla_filtro = None
    tablas_filtro = None
    archivos_explicitos = None

    if len(sys.argv) > 2:
        if sys.argv[2] == "--tabla":
            if len(sys.argv) < 4:
                print("[ERROR] Falta indicar la tabla despues de --tabla")
                sys.exit(1)
            tabla_filtro = sys.argv[3].lower().strip()
        elif sys.argv[2] == "--tablas":
            if len(sys.argv) < 4:
                print("[ERROR] Debes indicar al menos una tabla despues de --tablas")
                sys.exit(1)
            tablas_filtro = [t.strip().lower() for t in sys.argv[3:] if t.strip()]
            if not tablas_filtro:
                print("[ERROR] Lista de tablas vacia en --tablas")
                sys.exit(1)
        elif sys.argv[2] == "--archivos":
            if len(sys.argv) < 4:
                print("[ERROR] Debes indicar al menos un archivo despues de --archivos")
                sys.exit(1)
            archivos_explicitos = [a.strip() for a in sys.argv[3:] if a.strip()]
            if not archivos_explicitos:
                print("[ERROR] Lista de archivos vacia en --archivos")
                sys.exit(1)
        else:
            archivo_filtro = sys.argv[2]

    if not os.path.isdir(carpeta):
        print(f"[ERROR] Carpeta no encontrada: {carpeta}")
        sys.exit(1)

    if archivos_explicitos is not None:
        archivos = archivos_explicitos
    elif tablas_filtro is not None:
        archivos, faltantes = resolver_archivos_por_tablas(carpeta, tablas_filtro)
        if faltantes:
            print(f"[ERROR] No se encontraron CSVs para: {', '.join(faltantes)}")
            sys.exit(1)
    elif tabla_filtro and tabla_filtro not in ("todos", "all"):
        archivo_encontrado = buscar_archivo_por_tabla(carpeta, tabla_filtro)
        if not archivo_encontrado:
            print(f"[ERROR] No se encontro CSV para la tabla '{tabla_filtro}' en {carpeta}")
            sys.exit(1)
        archivos = [archivo_encontrado]
    elif archivo_filtro:
        archivos = [archivo_filtro]
    else:
        archivos = sorted([
            f for f in os.listdir(carpeta)
            if f.lower().endswith(".csv")
        ])

    if not archivos:
        print("[WARN] No se encontraron archivos CSV en la carpeta.")
        sys.exit(0)

    if tabla_filtro and tabla_filtro not in ("todos", "all"):
        print(f"[INFO] Modo actualizacion por tabla: {tabla_filtro}")
    elif tablas_filtro is not None:
        print(f"[INFO] Modo actualizacion por tablas: {', '.join(tablas_filtro)}")

    print(f"====================================")
    print(f"[CARGA] DE MAESTROS - {len(archivos)} archivo(s)")
    print(f"[CARPETA] {carpeta}")
    print(f"====================================")
    print(f"[PROGRESS] TOTAL={len(archivos)}")

    conn = conectar()
    errores = 0
    for indice, archivo in enumerate(archivos, start=1):
        ruta_csv = os.path.join(carpeta, archivo)
        estado = "ok"
        if os.path.isfile(ruta_csv):
            ok = cargar_csv(ruta_csv, conn)
            if not ok:
                estado = "error"
                errores += 1
        else:
            print(f"[WARN] No encontrado: {archivo}")
            estado = "error"
            errores += 1

        print(f"[PROGRESS] DONE={indice}/{len(archivos)}|mes=--|estado={estado}|archivo={archivo}")

    conn.close()

    print(f"\n[FINALIZADO] PROCESO DE MAESTROS.")
    if errores:
        print(f"[RESUMEN] Errores: {errores}")
        sys.exit(1)


if __name__ == "__main__":
    main()
