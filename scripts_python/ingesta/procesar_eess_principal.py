import os
import re
import sys

import psycopg2
from psycopg2 import sql


sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))
from db_config import CONFIG_DIR, get_db_config


CFG = get_db_config()
DB = {
    "user": CFG.user,
    "pass": CFG.password,
    "host": CFG.host,
    "port": CFG.port,
    "db": CFG.database,
}
ESQUEMA = CFG.schema

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
EDITOR_RUNTIME_DIR = os.path.join(CONFIG_DIR, "editable")
SQL_REL_PATH = os.path.join(
    "scripts_sql",
    "scripst tabla y reportes vacunas-cred",
    "EESS_PRINCIPAL_2026     moshe.sql",
)


def conectar():
    return psycopg2.connect(
        dbname=DB["db"],
        user=DB["user"],
        password=DB["pass"],
        host=DB["host"],
        port=DB["port"],
    )


def limpiar_sql(contenido: str, esquema: str) -> str:
    texto = contenido

    # Quitar bloques comentados largos.
    texto = re.sub(r"/\*.*?\*/", "", texto, flags=re.S)

    # Quitar call opcional que no existe en todos los entornos.
    texto = re.sub(
        r"(?im)^\s*CALL\s+es_ivan\.sp_generar_eess2025\(\);\s*$",
        "",
        texto,
    )

    # Corregir referencias legacy que aparecen en el SQL original.
    texto = re.sub(
        r"\bmaestro_eess_susalud2025\b",
        "maestro_eess_susalud",
        texto,
        flags=re.I,
    )
    texto = re.sub(
        r"\bmaestro_his_establecimiento25\b",
        "maestro_his_establecimiento",
        texto,
        flags=re.I,
    )

    # Normalizar listas NOT IN de id_establecimiento (columna TEXT en maestros cargados).
    def _normalizar_not_in_id_establecimiento(match: re.Match) -> str:
        prefijo = match.group(1)
        lista_raw = match.group(2)
        items = [x.strip() for x in lista_raw.split(",") if x.strip()]
        normalizados = []
        for item in items:
            if re.fullmatch(r"'[^']*'", item):
                normalizados.append(item)
            elif re.fullmatch(r"-?\d+", item):
                normalizados.append(f"'{item}'")
            else:
                normalizados.append(item)
        return f"{prefijo}NOT IN ({','.join(normalizados)})"

    texto = re.sub(
        r"(?is)((?:\b\w+\.)?id_establecimiento\s+)NOT\s+IN\s*\(([^)]*)\)",
        _normalizar_not_in_id_establecimiento,
        texto,
    )

    # Forzar id_eess entero para que coincida con RETURNS TABLE(id_eess INT, ...).
    texto = re.sub(
        r"(?i)\be\.id_establecimiento\s+AS\s+id_eess\b",
        "CASE WHEN e.id_establecimiento ~ '^[0-9]+$' THEN e.id_establecimiento::INT ELSE 0 END AS id_eess",
        texto,
    )

    # Ajustar esquema dinámico del sistema.
    texto = re.sub(r"\bes_ivan\.", f"{esquema}.", texto, flags=re.I)

    lineas = []
    for linea in texto.splitlines():
        if linea.strip() in {"/*", "*/"}:
            continue
        lineas.append(linea)

    return "\n".join(lineas).strip()


def validar_tablas_base(cur, esquema: str) -> None:
    # Compatibilidad: algunos entornos antiguos guardan SUSALUD como maestro_his_susalud.
    cur.execute(
        """
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = %s
          AND table_name = %s;
        """,
        (esquema, "maestro_his_susalud"),
    )
    existe_susalud_legacy = cur.fetchone() is not None

    cur.execute(
        """
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = %s
          AND table_name = %s;
        """,
        (esquema, "maestro_eess_susalud"),
    )
    existe_susalud_objetivo = cur.fetchone() is not None

    if (not existe_susalud_objetivo) and existe_susalud_legacy:
        cur.execute(
            sql.SQL(
                "CREATE OR REPLACE VIEW {} AS SELECT * FROM {};"
            ).format(
                sql.Identifier(esquema, "maestro_eess_susalud"),
                sql.Identifier(esquema, "maestro_his_susalud"),
            )
        )
        print("[INFO] Se creó vista de compatibilidad: maestro_eess_susalud -> maestro_his_susalud")

    requeridas = {"maestro_his_establecimiento", "maestro_eess_susalud"}
    cur.execute(
        """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = %s
          AND table_name = ANY(%s);
        """,
        (esquema, list(requeridas)),
    )
    encontradas = {r[0] for r in cur.fetchall()}
    faltantes = sorted(requeridas - encontradas)
    if faltantes:
        raise Exception(
            "Faltan tablas maestras para ejecutar EESS principal: "
            + ", ".join(faltantes)
        )


def asegurar_tabla_eess(cur, esquema: str) -> None:
    tabla = sql.Identifier(esquema, "eess2025")
    cur.execute(
        sql.SQL(
            """
            CREATE TABLE IF NOT EXISTS {} (
                id_eess INT,
                cod_eess TEXT,
                cod_ipress TEXT,
                nombre_eess TEXT,
                desc_eess TEXT,
                cat TEXT,
                ubigueo_eess TEXT,
                red_mred TEXT,
                cod_red TEXT,
                red TEXT,
                cod_mred TEXT,
                microred TEXT,
                cod_dpto TEXT,
                dpto TEXT,
                cod_prov TEXT,
                provincia TEXT,
                cod_dist TEXT,
                distrito TEXT,
                cod_ue INT,
                desc_ue TEXT,
                sector TEXT
            );
            """
        ).format(tabla)
    )


def resolver_ruta_sql() -> str:
    if len(sys.argv) > 1:
        candidato = sys.argv[1]
        if os.path.isabs(candidato):
            return candidato
        ruta_editable = os.path.join(EDITOR_RUNTIME_DIR, candidato)
        if os.path.exists(ruta_editable):
            return ruta_editable
        return os.path.join(BASE_DIR, candidato)

    ruta_editable = os.path.join(EDITOR_RUNTIME_DIR, SQL_REL_PATH)
    if os.path.exists(ruta_editable):
        return ruta_editable

    ruta_por_defecto = os.path.join(BASE_DIR, SQL_REL_PATH)
    if os.path.exists(ruta_por_defecto):
        return ruta_por_defecto

    carpeta = os.path.join(BASE_DIR, "scripts_sql", "scripst tabla y reportes vacunas-cred")
    if os.path.isdir(carpeta):
        candidatos = sorted(
            f for f in os.listdir(carpeta)
            if f.upper().startswith("EESS_PRINCIPAL_2026") and f.lower().endswith("moshe.sql")
        )
        if candidatos:
            return os.path.join(carpeta, candidatos[0])

    return ruta_por_defecto


def main() -> None:
    ruta_sql = resolver_ruta_sql()

    if not os.path.exists(ruta_sql):
        print(f"[ERROR] No se encontro script SQL: {ruta_sql}")
        sys.exit(1)

    print("====================================")
    print("[EESS PRINCIPAL] Normalizacion y reconstruccion")
    print(f"[ESQUEMA] {ESQUEMA}")
    print(f"[SQL] {ruta_sql}")
    print("====================================")

    with open(ruta_sql, "r", encoding="utf-8") as f:
        sql_original = f.read()

    sql_limpio = limpiar_sql(sql_original, ESQUEMA)
    if not sql_limpio:
        print("[ERROR] El SQL quedo vacio tras limpieza.")
        sys.exit(1)

    conn = None
    cur = None
    try:
        conn = conectar()
        cur = conn.cursor()

        cur.execute(sql.SQL("CREATE SCHEMA IF NOT EXISTS {};").format(sql.Identifier(ESQUEMA)))
        validar_tablas_base(cur, ESQUEMA)
        asegurar_tabla_eess(cur, ESQUEMA)

        print("[INFO] Ejecutando script de EESS principal...")
        cur.execute(sql_limpio)

        cur.execute(sql.SQL("SELECT COUNT(*) FROM {};").format(sql.Identifier(ESQUEMA, "eess2025")))
        total = cur.fetchone()[0]

        conn.commit()
        print(f"[OK] Proceso completado. Filas en {ESQUEMA}.eess2025: {total:,}")

    except Exception as e:
        if conn:
            conn.rollback()
        print(f"[ERROR] Fallo procesamiento EESS principal: {e}")
        sys.exit(1)

    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()


if __name__ == "__main__":
    main()
