import os
import sys

import psycopg2


BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from db_config import CONFIG_DIR, get_db_config


SQL_TEMPLATE_REL = os.path.join("scripts_sql", "reportes", "reporte_vacunas_editor.sql")
EDITOR_RUNTIME_DIR = os.path.join(CONFIG_DIR, "editable")


def _nombre_seguro(nombre: str) -> str:
    return (nombre or "").replace('"', "").replace(";", "").strip()


def get_db() -> tuple:
    cfg = get_db_config()
    conn = psycopg2.connect(
        host=cfg.host,
        port=cfg.port,
        dbname=cfg.database,
        user=cfg.user,
        password=cfg.password,
    )
    return conn, _nombre_seguro(cfg.schema or "es_ivan")


def _cargar_sql_reporte_vacunas(esquema: str, anio: int) -> str:
    ruta = os.path.join(EDITOR_RUNTIME_DIR, SQL_TEMPLATE_REL)
    if not os.path.exists(ruta):
        ruta = os.path.join(BASE_DIR, SQL_TEMPLATE_REL)
    if not os.path.exists(ruta):
        raise RuntimeError(f"No se encontró plantilla SQL: {ruta}")

    with open(ruta, "r", encoding="utf-8") as file:
        plantilla = file.read()

    try:
        return plantilla.format(ESQUEMA=esquema, ANIO=anio).strip()
    except KeyError as exc:
        raise RuntimeError(
            f"Falta placeholder '{exc.args[0]}' en la plantilla SQL de reporte_vacunas."
        ) from exc


def crear_reporte_vacunas(anio=2026):
    conn, esquema = get_db()
    cur = conn.cursor()

    print(f"[INFO] Creando VACUNAS_{anio}...")

    try:
        cur.execute(f"DROP TABLE IF EXISTS {esquema}.VACUNAS_{anio}")
        cur.execute(_cargar_sql_reporte_vacunas(esquema, anio))
        conn.commit()

        cur.execute(f"SELECT COUNT(*) FROM {esquema}.VACUNAS_{anio}")
        total = cur.fetchone()[0]

        print(f"[OK] VACUNAS_{anio} creada: {total:,} registros")
        return total
    finally:
        cur.close()
        conn.close()


def main():
    anio = int(sys.argv[1]) if len(sys.argv) > 1 else 2026
    crear_reporte_vacunas(anio)


if __name__ == "__main__":
    main()
