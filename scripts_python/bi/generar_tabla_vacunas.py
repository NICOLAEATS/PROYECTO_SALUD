import os
import sys

import psycopg2


BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from db_config import CONFIG_DIR, get_db_config, update_db_config


CODIGOS_VACUNAS = [
    "90585", "90633.01", "90648", "90649", "90657", "90658", "90669", "90670",
    "90681", "90687", "90688", "90701", "90702", "90707", "90712", "90713", "90714",
    "90715", "90716", "90717", "90722", "90723", "90744", "90746", "Z238", "Z2511",
    "P070", "P071", "P0711", "P0712", "P0713", "P072", "P073",
    "99436", "99381.01", "99401.03", "99411.01", "99431", "P599",
    "99381", "99382", "99383", "99401.05", "99401.07", "99401.08",
    "99401", "99401.16", "99401.24", "99401.25", "99403.01",
    "99401.09", "99401.12",
    "P929", "99211", "99209", "99199.17", "99199.27",
    "R620", "D500", "D501", "D508", "D509",
    "B700", "B701", "B760", "B761", "B8769", "B779", "B780",
    "B680", "B681", "B689", "B79X", "B820", "B829",
    "A070", "A071", "A06", "B663", "B664", "87178", "B80X",
    "99199.28", "C0011", "Z001", "C8002", "R628",
    "E440", "E45X", "E6690", "E669", "E344",
    "U140", "R456", "Z720", "Z721", "Z722", "Z133",
    "H351", "H579", "Z010", "H538", "H509", "H530", "H559",
    "H179", "H029", "H028", "H527", "67228", "67229", "92390",
    "99499.01", "99499.02", "99499.03", "99499.04", "99499.05",
    "99499.06", "99499.07", "99499.08", "99499.09", "99499.10",
    "96150.02", "96150.03", "96150.06", "96150.08",
    "92226", "92250", "67043", "99173",
    "H520", "H521", "H522", "H523",
    "1330", "D1286", "D1110", "D1351",
]
SQL_TEMPLATE_REL = os.path.join("scripts_sql", "reportes", "tabla_vacunas_editor.sql")
EDITOR_RUNTIME_DIR = os.path.join(CONFIG_DIR, "editable")


def _nombre_seguro(nombre: str) -> str:
    return (nombre or "").replace('"', "").replace(";", "").strip()


def _cargar_sql_tabla_vacunas(esquema: str, filtro_anio: str) -> str:
    ruta = os.path.join(EDITOR_RUNTIME_DIR, SQL_TEMPLATE_REL)
    if not os.path.exists(ruta):
        ruta = os.path.join(BASE_DIR, SQL_TEMPLATE_REL)
    if not os.path.exists(ruta):
        raise RuntimeError(f"No se encontró plantilla SQL: {ruta}")

    with open(ruta, "r", encoding="utf-8") as file:
        plantilla = file.read()

    try:
        return plantilla.format(ESQUEMA=esquema, FILTRO_ANIO=filtro_anio).strip()
    except KeyError as exc:
        raise RuntimeError(
            f"Falta placeholder '{exc.args[0]}' en la plantilla SQL de tabla_vacunas."
        ) from exc


def get_db() -> tuple:
    cfg = get_db_config()
    passwords = [
        cfg.password,
        os.getenv("DB_PASSWORD", ""),
        "ivan",
        "postgres",
        os.getenv("USERNAME", ""),
        "",
    ]

    vistos = set()
    ultimo_error = None

    for pwd in passwords:
        pwd = "" if pwd is None else str(pwd)
        if pwd in vistos:
            continue
        vistos.add(pwd)

        try:
            conn = psycopg2.connect(
                host=cfg.host,
                port=cfg.port,
                dbname=cfg.database,
                user=cfg.user,
                password=pwd,
                connect_timeout=10,
            )

            if pwd != (cfg.password or ""):
                try:
                    update_db_config(password=pwd)
                except Exception:
                    pass

            return conn, _nombre_seguro(cfg.schema)
        except UnicodeDecodeError as exc:
            ultimo_error = exc
            continue
        except Exception as exc:
            ultimo_error = exc
            continue

    raise RuntimeError(
        "No se pudo conectar a PostgreSQL para generar tabla_vacunas. "
        f"Revisa la contraseña en Configurar BD. Último error: {ultimo_error}"
    )


def crear_tabla_vacunas(anio: int | None = None):
    conn, esquema = get_db()
    cur = conn.cursor()

    print(f"[INFO] Creando tabla_vacunas para {anio if anio else 'todos los anos'}...")

    try:
        cur.execute(f"DROP TABLE IF EXISTS {esquema}.tabla_vacunas;")

        filtro_anio = "hp.anio IS NOT NULL"
        parametros = [CODIGOS_VACUNAS]
        if anio is not None:
            filtro_anio = "hp.anio = %s"
            parametros = [anio, CODIGOS_VACUNAS]

        sql = _cargar_sql_tabla_vacunas(esquema, filtro_anio)
        cur.execute(
            sql,
            tuple(parametros),
        )
        conn.commit()

        cur.execute(f"SELECT COUNT(*) FROM {esquema}.tabla_vacunas;")
        total = cur.fetchone()[0]
        print(f"[OK] tabla_vacunas creada: {total:,} registros")
        return total
    finally:
        cur.close()
        conn.close()


def main():
    anio = None
    if len(sys.argv) > 1:
        anio = int(sys.argv[1])
    crear_tabla_vacunas(anio)


if __name__ == "__main__":
    main()
