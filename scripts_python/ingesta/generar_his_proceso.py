"""
generar_his_proceso.py

Genera y carga la tabla particionada es_ivan.his_proceso con estructura fija.
Mantiene compatibilidad con la llamada histórica del sistema:

    python generar_his_proceso.py <anio> <maestros_json> [mes]

También acepta:

    python generar_his_proceso.py <anio> [mes]
"""

from __future__ import annotations

import json
import os
import sys
import io
import re
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

import psycopg2


sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))
from db_config import CONFIG_DIR, get_db_config


_db_config = get_db_config()

DB = {
    "user": _db_config.user,
    "pass": _db_config.password,
    "host": _db_config.host,
    "port": _db_config.port,
    "db": _db_config.database,
}

ESQUEMA = _db_config.schema
ANIOS_SOPORTADOS = [2021, 2022, 2023, 2024, 2025, 2026]
PASOS_PROCESO_POR_PERIODO = 6
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SQL_TEMPLATE_REL = os.path.join("scripts_sql", "reportes", "generar_his_proceso_editor.sql")
EDITOR_RUNTIME_DIR = os.path.join(CONFIG_DIR, "editable")
LOCK_HIS_PROCESO = "proyecto_salud_cusco_his_proceso"
_SQL_SECTIONS_CACHE: dict[str, str] | None = None

COLUMNAS_HIS_PROCESO = [
    "id_cita",
    "lote",
    "fg_tipo",
    "dni_paciente",
    "apellido_paterno_paciente",
    "apellido_materno_paciente",
    "nombres_paciente",
    "fecha_nacimiento",
    "id_tipo_documento",
    "genero",
    "id_etnia",
    "anio",
    "mes",
    "dia",
    "id_establecimiento",
    "fecha_atencion",
    "edad",
    "tip_edad",
    "fi",
    "establec",
    "servicio",
    "condicion_gestante",
    "peso_pregestacional",
    "tipo_diagnostico",
    "codigo_item",
    "valor_lab",
    "id_correlativo",
    "id_correlativo_lab",
    "cod_2000",
    "codigo_red",
    "red",
    "desc_ue",
    "codigo_microred",
    "microred",
    "departamento",
    "provincia",
    "distrito",
    "nombre_establecimiento",
    "dni_personal",
    "dni_registrador",
    "id_colegio",
    "descripcion_colegio",
    "id_ups",
    "descripcion_etnia",
    "fecha_registro",
    "fecha_modificacion",
]

EESS_DEFAULTS = {
    "cod_2000": "''::varchar(10)",
    "codigo_red": "''::varchar(10)",
    "red": "''::text",
    "desc_ue": "''::text",
    "codigo_microred": "''::varchar(10)",
    "microred": "''::text",
    "departamento": "''::text",
    "provincia": "''::text",
    "distrito": "''::text",
    "nombre_establecimiento": "''::text",
}

EESS_TARGETS = {
    "cod_2000": (["cod_eess", "codigo_unico", "id_eess", "id_establecimiento"], "varchar(10)"),
    "codigo_red": (["cod_red", "codigo_red"], "varchar(10)"),
    "red": (["red"], "text"),
    "desc_ue": (["desc_ue", "descripcion_sector", "disa"], "text"),
    "codigo_microred": (["cod_mred", "codigo_microred"], "varchar(10)"),
    "microred": (["microred"], "text"),
    "departamento": (["dpto", "departamento"], "text"),
    "provincia": (["provincia"], "text"),
    "distrito": (["distrito"], "text"),
    "nombre_establecimiento": (["nombre_eess", "nombre_establecimiento"], "text"),
}


def resolver_ruta_sql_editor() -> str:
    ruta_editable = os.path.join(EDITOR_RUNTIME_DIR, SQL_TEMPLATE_REL)
    if os.path.exists(ruta_editable):
        return ruta_editable
    return os.path.join(BASE_DIR, SQL_TEMPLATE_REL)


def cargar_secciones_sql_editor() -> dict[str, str]:
    global _SQL_SECTIONS_CACHE

    if _SQL_SECTIONS_CACHE is not None:
        return _SQL_SECTIONS_CACHE

    ruta = resolver_ruta_sql_editor()
    if not os.path.exists(ruta):
        raise Exception(f"No se encontró plantilla SQL editable: {ruta}")

    with open(ruta, "r", encoding="utf-8") as file:
        contenido = file.read()

    secciones: dict[str, str] = {}
    actual = None
    buffer: list[str] = []

    for linea in contenido.splitlines():
        match = re.match(r"\s*--\s*@SECTION:\s*([a-zA-Z0-9_]+)\s*$", linea)
        if match:
            if actual:
                secciones[actual] = "\n".join(buffer).strip()
            actual = match.group(1)
            buffer = []
            continue

        if actual is not None:
            buffer.append(linea)

    if actual:
        secciones[actual] = "\n".join(buffer).strip()

    requeridas = {
        "estructura",
        "particion",
        "limpiar_periodo_todos",
        "limpiar_periodo_mes",
        "crear_staging",
        "cargar_particion_final",
        "eliminar_staging",
    }
    faltantes = sorted(requeridas - set(secciones))
    if faltantes:
        raise Exception(
            "La plantilla SQL editable de HIS Proceso no tiene todas las secciones requeridas: "
            + ", ".join(faltantes)
        )

    _SQL_SECTIONS_CACHE = secciones
    return secciones


def renderizar_sql_editor(nombre_seccion: str, **contexto) -> str:
    secciones = cargar_secciones_sql_editor()
    plantilla = secciones.get(nombre_seccion)
    if not plantilla:
        raise Exception(f"No existe la sección SQL requerida: {nombre_seccion}")

    try:
        return plantilla.format(**contexto).strip()
    except KeyError as exc:
        raise Exception(
            f"Falta placeholder '{exc.args[0]}' en la sección SQL '{nombre_seccion}'."
        ) from exc


def conectar():
    return psycopg2.connect(
        dbname=DB["db"],
        user=DB["user"],
        password=DB["pass"],
        host=DB["host"],
        port=DB["port"],
    )


def adquirir_bloqueo_his_proceso(cur):
    cur.execute("SELECT pg_try_advisory_lock(hashtext(%s)::bigint);", (LOCK_HIS_PROCESO,))
    if not cur.fetchone()[0]:
        raise Exception(
            "HIS Proceso ya se está generando en otra ventana. Cancela o espera a que termine antes de volver a ejecutarlo."
        )


def liberar_bloqueo_his_proceso(cur):
    cur.execute("SELECT pg_advisory_unlock(hashtext(%s)::bigint);", (LOCK_HIS_PROCESO,))


def configurar_sesion_his_proceso(cur):
    cur.execute("SET synchronous_commit = off;")
    cur.execute("SET work_mem = '512MB';")
    cur.execute("SET temp_buffers = '256MB';")
    cur.execute("SET maintenance_work_mem = '1GB';")
    cur.execute("SET jit = off;")


def resolver_tabla(cur, nombre_tabla: str, esquemas_preferidos: list[str]) -> str:
    for esquema in esquemas_preferidos:
        cur.execute(
            """
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = %s AND table_name = %s
            LIMIT 1;
            """,
            (esquema, nombre_tabla),
        )
        if cur.fetchone():
            return f"{esquema}.{nombre_tabla}"

    raise Exception(
        f"No se encontró la tabla '{nombre_tabla}' en esquemas: {', '.join(esquemas_preferidos)}"
    )


def resolver_tabla_opcional(
    cur,
    nombres_tabla: list[str],
    esquemas_preferidos: list[str],
) -> tuple[str, str, str] | None:
    for nombre in nombres_tabla:
        for esquema in esquemas_preferidos:
            cur.execute(
                """
                SELECT 1
                FROM information_schema.tables
                WHERE table_schema = %s AND table_name = %s
                LIMIT 1;
                """,
                (esquema, nombre),
            )
            if cur.fetchone():
                return f"{esquema}.{nombre}", esquema, nombre

    return None


def obtener_columnas_tabla(cur, esquema: str, tabla: str) -> set[str]:
    cur.execute(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = %s AND table_name = %s;
        """,
        (esquema, tabla),
    )
    return {r[0].lower() for r in cur.fetchall()}


def obtener_columnas_tabla_ordenadas(cur, esquema: str, tabla: str) -> list[str]:
    cur.execute(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = %s AND table_name = %s
        ORDER BY ordinal_position;
        """,
        (esquema, tabla),
    )
    return [r[0] for r in cur.fetchall()]


def obtener_columnas_tabla_info(cur, esquema: str, tabla: str) -> list[dict[str, object]]:
    cur.execute(
        """
        SELECT
            column_name,
            data_type,
            character_maximum_length,
            numeric_precision,
            numeric_scale,
            datetime_precision
        FROM information_schema.columns
        WHERE table_schema = %s AND table_name = %s
        ORDER BY ordinal_position;
        """,
        (esquema, tabla),
    )
    return [
        {
            "column_name": r[0],
            "data_type": r[1],
            "character_maximum_length": r[2],
            "numeric_precision": r[3],
            "numeric_scale": r[4],
            "datetime_precision": r[5],
        }
        for r in cur.fetchall()
    ]


def ident_sql(nombre: str) -> str:
    return '"' + str(nombre).replace('"', '""') + '"'


def tabla_sql(esquema: str, tabla: str) -> str:
    return f"{ident_sql(esquema)}.{ident_sql(tabla)}"


def tipo_sql_columna(columna: dict[str, object]) -> str:
    data_type = str(columna["data_type"])
    char_len = columna.get("character_maximum_length")
    num_precision = columna.get("numeric_precision")
    num_scale = columna.get("numeric_scale")

    if data_type == "character varying":
        return f"varchar({char_len})" if char_len else "varchar"
    if data_type == "character":
        return f"char({char_len})" if char_len else "char"
    if data_type == "numeric":
        if num_precision is not None and num_scale is not None:
            return f"numeric({num_precision},{num_scale})"
        if num_precision is not None:
            return f"numeric({num_precision})"
        return "numeric"
    if data_type == "timestamp without time zone":
        return "timestamp"

    return data_type


def sincronizar_columnas_his_proceso_desde_staging(cur, staging_tabla: str) -> None:
    columnas_staging = obtener_columnas_tabla_info(cur, ESQUEMA, staging_tabla)
    columnas_destino = obtener_columnas_tabla(cur, ESQUEMA, "his_proceso")

    for columna in columnas_staging:
        nombre = str(columna["column_name"])
        if nombre.lower() in columnas_destino:
            continue

        tipo_sql = tipo_sql_columna(columna)
        cur.execute(
            f"ALTER TABLE {tabla_sql(ESQUEMA, 'his_proceso')} "
            f"ADD COLUMN IF NOT EXISTS {ident_sql(nombre)} {tipo_sql};"
        )
        columnas_destino.add(nombre.lower())
        print(f"   ➕ Columna nueva agregada a his_proceso: {nombre} ({tipo_sql})")


def columnas_carga_final(cur, staging_tabla: str) -> list[str]:
    columnas_staging = obtener_columnas_tabla_ordenadas(cur, ESQUEMA, staging_tabla)
    columnas_staging_set = {c.lower() for c in columnas_staging}
    columnas_destino = obtener_columnas_tabla(cur, ESQUEMA, "his_proceso")

    faltantes_base = [c for c in COLUMNAS_HIS_PROCESO if c.lower() not in columnas_staging_set]
    if faltantes_base:
        raise Exception(
            "La plantilla SQL de HIS Proceso no genera columnas base requeridas: "
            + ", ".join(faltantes_base)
        )

    columnas_base = [c for c in COLUMNAS_HIS_PROCESO if c.lower() in columnas_destino]
    columnas_extra = [
        c
        for c in columnas_staging
        if c.lower() not in {base.lower() for base in columnas_base}
        and c.lower() in columnas_destino
    ]
    return columnas_base + columnas_extra


def resolver_tablas_fuente(cur) -> dict[str, str]:
    tablas = {
        "hisminsa24": resolver_tabla(cur, "hisminsa24", [ESQUEMA]),
        "maestro_paciente": resolver_tabla(cur, "maestro_paciente", [ESQUEMA, "maestros"]),
        "maestro_personal": resolver_tabla(cur, "maestro_personal", [ESQUEMA, "maestros"]),
        "maestro_his_cie_cpms": resolver_tabla(
            cur, "maestro_his_cie_cpms", ["maestros", ESQUEMA]
        ),
        "maestro_his_etnia": resolver_tabla(cur, "maestro_his_etnia", ["maestros", ESQUEMA]),
        "maestro_his_ups": resolver_tabla(cur, "maestro_his_ups", ["maestros", ESQUEMA]),
        "maestro_his_colegio": resolver_tabla(
            cur, "maestro_his_colegio", ["maestros", ESQUEMA]
        ),
    }

    eess_info = resolver_tabla_opcional(cur, ["eess2025"], [ESQUEMA, "maestros"])

    if eess_info:
        tabla_full, esquema_eess, nombre_eess = eess_info
        tablas["eess"] = tabla_full
        tablas["eess_cols"] = obtener_columnas_tabla(cur, esquema_eess, nombre_eess)
        tablas["eess_nombre"] = nombre_eess
    else:
        tablas["eess"] = None
        tablas["eess_cols"] = set()
        tablas["eess_nombre"] = None

    eess_maestro_info = resolver_tabla_opcional(
        cur,
        ["maestro_his_establecimiento", "maestro_his_establecimiento25"],
        [ESQUEMA, "maestros"],
    )

    if eess_maestro_info:
        tabla_full, esquema_eess, nombre_eess = eess_maestro_info
        tablas["eess_maestro"] = tabla_full
        tablas["eess_maestro_cols"] = obtener_columnas_tabla(cur, esquema_eess, nombre_eess)
        tablas["eess_maestro_nombre"] = nombre_eess
    else:
        tablas["eess_maestro"] = None
        tablas["eess_maestro_cols"] = set()
        tablas["eess_maestro_nombre"] = None

    return tablas


def _slug_indice(texto: str) -> str:
    limpio = re.sub(r"[^a-zA-Z0-9_]+", "_", texto.strip().lower())
    return limpio.strip("_") or "tabla"


def crear_indice_si_no_existe(cur, tabla_full: str, sufijo: str, columnas_sql: str):
    nombre_idx = f"idx_{_slug_indice(tabla_full)}_{sufijo}"
    if len(nombre_idx) > 60:
        nombre_idx = nombre_idx[:60]
    cur.execute(f"CREATE INDEX IF NOT EXISTS {nombre_idx} ON {tabla_full} {columnas_sql};")


def asegurar_indices_fuente(cur, tablas: dict[str, str]):
    crear_indice_si_no_existe(cur, tablas["hisminsa24"], "anio_mes", "(anio, mes)")
    crear_indice_si_no_existe(cur, tablas["maestro_paciente"], "id_paciente", "(id_paciente)")
    crear_indice_si_no_existe(cur, tablas["maestro_personal"], "id_personal", "(id_personal)")
    crear_indice_si_no_existe(cur, tablas["maestro_his_cie_cpms"], "codigo_item", "(codigo_item)")
    crear_indice_si_no_existe(cur, tablas["maestro_his_etnia"], "id_etnia", "(id_etnia)")
    crear_indice_si_no_existe(cur, tablas["maestro_his_ups"], "id_ups", "(id_ups)")
    crear_indice_si_no_existe(cur, tablas["maestro_his_colegio"], "id_colegio", "(id_colegio)")


def expr_eess(
    alias: str,
    columnas: set[str],
    candidatos: list[str],
    cast_sql: str,
):
    for col in candidatos:
        if col in columnas:
            return f"NULLIF(TRIM({alias}.{col}::text), '')::{cast_sql}"
    return None


def combinar_expr(default_expr: str, *exprs) -> str:
    validas = [expr for expr in exprs if expr]
    if not validas:
        return default_expr
    return "COALESCE(" + ", ".join(validas + [default_expr]) + ")"


def resolver_columna_join_eess(columnas: set[str]) -> str | None:
    if "id_eess" in columnas:
        return "id_eess"
    if "id_establecimiento" in columnas:
        return "id_establecimiento"
    return None


def expr_clave_eess(alias: str, columna: str) -> str:
    return (
        "CASE "
        f"WHEN TRIM({alias}.{columna}::text) ~ '^[0-9]+$' THEN COALESCE(NULLIF(LTRIM(TRIM({alias}.{columna}::text), '0'), ''), '0') "
        f"ELSE TRIM({alias}.{columna}::text) "
        "END"
    )


def expr_fuente_eess(alias: str, columnas: set[str], objetivo: str) -> str:
    candidatos, cast_sql = EESS_TARGETS[objetivo]
    for col in candidatos:
        if col in columnas:
            return f"NULLIF(TRIM({alias}.{col}::text), '')::{cast_sql}"
    return EESS_DEFAULTS[objetivo]


def construir_select_lookup_eess(
    tabla_full: str,
    alias: str,
    columnas: set[str],
    join_col: str,
    prioridad: int,
) -> str:
    campos = [
        f"{expr_clave_eess(alias, join_col)} AS join_key",
        f"{prioridad} AS prioridad",
    ]
    for objetivo in EESS_TARGETS:
        campos.append(f"{expr_fuente_eess(alias, columnas, objetivo)} AS {objetivo}")

    return (
        "SELECT\n        "
        + ",\n        ".join(campos)
        + f"\n    FROM {tabla_full} {alias}"
    )


def preparar_lookup_eess(cur, tablas: dict[str, str]) -> bool:
    consultas = []

    tabla_eess = tablas.get("eess")
    columnas_eess = tablas.get("eess_cols") or set()
    if tabla_eess:
        col_join_eess = resolver_columna_join_eess(columnas_eess)
        if col_join_eess:
            consultas.append(
                construir_select_lookup_eess(tabla_eess, "src_eess", columnas_eess, col_join_eess, 1)
            )

    tabla_maestro = tablas.get("eess_maestro")
    columnas_maestro = tablas.get("eess_maestro_cols") or set()
    if tabla_maestro and tabla_maestro != tabla_eess:
        col_join_maestro = resolver_columna_join_eess(columnas_maestro)
        if col_join_maestro:
            consultas.append(
                construir_select_lookup_eess(
                    tabla_maestro,
                    "src_eess_alt",
                    columnas_maestro,
                    col_join_maestro,
                    2,
                )
            )

    cur.execute("DROP TABLE IF EXISTS tmp_eess_lookup;")
    if not consultas:
        return False

    union_sql = "\n    UNION ALL\n    ".join(consultas)
    cur.execute(
        f"""
        CREATE TEMP TABLE tmp_eess_lookup AS
        SELECT DISTINCT ON (join_key)
            join_key,
            cod_2000,
            codigo_red,
            red,
            desc_ue,
            codigo_microred,
            microred,
            departamento,
            provincia,
            distrito,
            nombre_establecimiento
        FROM (
            {union_sql}
        ) src
        WHERE join_key IS NOT NULL
          AND join_key <> ''
        ORDER BY join_key, prioridad;
        """
    )
    cur.execute("CREATE INDEX idx_tmp_eess_lookup_join_key ON tmp_eess_lookup (join_key);")
    return True


def enriquecer_staging_eess(cur, staging_tabla: str) -> None:
    enriquecer_staging_eess_desde(cur, staging_tabla, "tmp_eess_lookup")


def enriquecer_staging_eess_desde(cur, staging_tabla: str, lookup_table: str) -> None:
    cur.execute(
        f"""
        UPDATE {ESQUEMA}.{staging_tabla} stg
        SET
            cod_2000 = lk.cod_2000,
            codigo_red = lk.codigo_red,
            red = lk.red,
            desc_ue = lk.desc_ue,
            codigo_microred = lk.codigo_microred,
            microred = lk.microred,
            departamento = lk.departamento,
            provincia = lk.provincia,
            distrito = lk.distrito,
            nombre_establecimiento = lk.nombre_establecimiento
        FROM {lookup_table} lk
        WHERE stg.id_establecimiento::text = lk.join_key;
        """
    )


def preparar_fuentes_periodo(cur, anio: int, mes: int | None, tablas: dict[str, str]) -> dict[str, str]:
    mes_filtro = ""
    if mes is not None:
        mes_texto = f"{mes:02d}"
        mes_filtro = f"AND nt.mes IN ('{mes_texto}', '{mes}')"

    cur.execute("DROP TABLE IF EXISTS tmp_nt_base;")
    cur.execute(
        f"""
        CREATE TEMP TABLE tmp_nt_base AS
        SELECT *
        FROM {tablas['hisminsa24']} nt
        WHERE nt.anio = '{anio}'
          {mes_filtro}
          AND nt.id_cita::text ~ '^[0-9]+$';
        """
    )
    cur.execute("ANALYZE tmp_nt_base;")

    cur.execute("DROP TABLE IF EXISTS tmp_maestro_paciente_periodo;")
    cur.execute(
        f"""
        CREATE TEMP TABLE tmp_maestro_paciente_periodo AS
        SELECT mp.*
        FROM {tablas['maestro_paciente']} mp
        JOIN (
            SELECT DISTINCT TRIM(id_paciente::text) AS id_paciente
            FROM tmp_nt_base
            WHERE COALESCE(TRIM(id_paciente::text), '') <> ''
        ) ids ON mp.id_paciente::text = ids.id_paciente;
        """
    )
    cur.execute("ANALYZE tmp_maestro_paciente_periodo;")

    cur.execute("DROP TABLE IF EXISTS tmp_maestro_personal_periodo;")
    cur.execute(
        f"""
        CREATE TEMP TABLE tmp_maestro_personal_periodo AS
        SELECT mp.*
        FROM {tablas['maestro_personal']} mp
        JOIN (
            SELECT DISTINCT TRIM(id_personal::text) AS clave
            FROM tmp_nt_base
            WHERE COALESCE(TRIM(id_personal::text), '') <> ''
        ) ids ON mp.id_personal::text = ids.clave;
        """
    )
    cur.execute("ANALYZE tmp_maestro_personal_periodo;")

    cur.execute("DROP TABLE IF EXISTS tmp_cie_periodo;")
    cur.execute(
        f"""
        CREATE TEMP TABLE tmp_cie_periodo AS
        SELECT cie.*
        FROM {tablas['maestro_his_cie_cpms']} cie
        JOIN (
            SELECT DISTINCT TRIM(codigo_item::text) AS codigo_item
            FROM tmp_nt_base
            WHERE COALESCE(TRIM(codigo_item::text), '') <> ''
        ) ids ON cie.codigo_item::text = ids.codigo_item;
        """
    )
    cur.execute("ANALYZE tmp_cie_periodo;")

    cur.execute("DROP TABLE IF EXISTS tmp_ups_periodo;")
    cur.execute(
        f"""
        CREATE TEMP TABLE tmp_ups_periodo AS
        SELECT ups.*
        FROM {tablas['maestro_his_ups']} ups
        JOIN (
            SELECT DISTINCT TRIM(id_ups::text) AS id_ups
            FROM tmp_nt_base
            WHERE COALESCE(TRIM(id_ups::text), '') <> ''
        ) ids ON ups.id_ups::text = ids.id_ups;
        """
    )
    cur.execute("ANALYZE tmp_ups_periodo;")

    cur.execute("DROP TABLE IF EXISTS tmp_etnia_periodo;")
    cur.execute(
        f"""
        CREATE TEMP TABLE tmp_etnia_periodo AS
        SELECT et.*
        FROM {tablas['maestro_his_etnia']} et
        JOIN (
            SELECT DISTINCT TRIM(id_etnia::text) AS id_etnia
            FROM tmp_maestro_paciente_periodo
            WHERE COALESCE(TRIM(id_etnia::text), '') <> ''
        ) ids ON et.id_etnia::text = ids.id_etnia;
        """
    )
    cur.execute("ANALYZE tmp_etnia_periodo;")

    cur.execute("DROP TABLE IF EXISTS tmp_colegio_periodo;")
    cur.execute(
        f"""
        CREATE TEMP TABLE tmp_colegio_periodo AS
        SELECT col.*
        FROM {tablas['maestro_his_colegio']} col
        JOIN (
            SELECT DISTINCT TRIM(id_colegio::text) AS id_colegio
            FROM tmp_maestro_personal_periodo
            WHERE COALESCE(TRIM(id_colegio::text), '') <> ''
        ) ids ON col.id_colegio::text = ids.id_colegio;
        """
    )
    cur.execute("ANALYZE tmp_colegio_periodo;")

    tablas_periodo = {
        **tablas,
        "hisminsa24": "tmp_nt_base",
        "maestro_paciente": "tmp_maestro_paciente_periodo",
        "maestro_personal": "tmp_maestro_personal_periodo",
        "maestro_his_cie_cpms": "tmp_cie_periodo",
        "maestro_his_etnia": "tmp_etnia_periodo",
        "maestro_his_ups": "tmp_ups_periodo",
        "maestro_his_colegio": "tmp_colegio_periodo",
        "eess_lookup_periodo": None,
    }

    if tablas.get("eess_lookup_ready"):
        cur.execute("DROP TABLE IF EXISTS tmp_eess_lookup_periodo;")
        cur.execute(
            f"""
            CREATE TEMP TABLE tmp_eess_lookup_periodo AS
            SELECT lk.*
            FROM tmp_eess_lookup lk
            JOIN (
                SELECT DISTINCT {expr_clave_eess('nt', 'id_establecimiento')} AS join_key
                FROM tmp_nt_base nt
                WHERE COALESCE(TRIM(nt.id_establecimiento::text), '') <> ''
            ) ids ON lk.join_key = ids.join_key;
            """
        )
        cur.execute("CREATE INDEX idx_tmp_eess_lookup_periodo_join_key ON tmp_eess_lookup_periodo (join_key);")
        cur.execute("ANALYZE tmp_eess_lookup_periodo;")
        tablas_periodo["eess_lookup_periodo"] = "tmp_eess_lookup_periodo"

    return tablas_periodo


def construir_condicion_join(alias: str, col_join: str) -> str:
    return (
        "("
        f"(TRIM(nt.id_establecimiento::text) ~ '^[0-9]+$' "
        f"AND TRIM({alias}.{col_join}::text) ~ '^[0-9]+$' "
        f"AND TRIM(nt.id_establecimiento::text)::bigint = TRIM({alias}.{col_join}::text)::bigint) "
        "OR "
        f"TRIM(nt.id_establecimiento::text) = TRIM({alias}.{col_join}::text)"
        ")"
    )


def construir_contexto_eess(tablas: dict[str, str]) -> tuple[str, dict[str, str]]:
    columnas_eess = tablas.get("eess_cols") or set()
    tabla_eess = tablas.get("eess")
    columnas_maestro = tablas.get("eess_maestro_cols") or set()
    tabla_maestro = tablas.get("eess_maestro")

    defaults = {
        "cod_2000": "''::varchar(10)",
        "codigo_red": "''::varchar(10)",
        "red": "''::text",
        "desc_ue": "''::text",
        "codigo_microred": "''::varchar(10)",
        "microred": "''::text",
        "departamento": "''::text",
        "provincia": "''::text",
        "distrito": "''::text",
        "nombre_establecimiento": "''::text",
    }

    if not tabla_eess and not tabla_maestro:
        return "", defaults

    joins = []
    alias_eess = None
    alias_maestro = None

    if tabla_eess:
        col_join_eess = resolver_columna_join_eess(columnas_eess)
        if col_join_eess:
            alias_eess = "mhe"
            joins.append(
                f"LEFT JOIN {tabla_eess} {alias_eess} "
                f"ON {construir_condicion_join(alias_eess, col_join_eess)}"
            )

    if tabla_maestro and tabla_maestro != tabla_eess:
        col_join_maestro = resolver_columna_join_eess(columnas_maestro)
        if col_join_maestro:
            alias_maestro = "mhe_alt"
            joins.append(
                f"LEFT JOIN {tabla_maestro} {alias_maestro} "
                f"ON {construir_condicion_join(alias_maestro, col_join_maestro)}"
            )

    if not joins:
        return "", defaults

    exprs = {
        "cod_2000": combinar_expr(
            defaults["cod_2000"],
            expr_eess(alias_eess, columnas_eess, ["cod_eess", "codigo_unico", "id_eess", "id_establecimiento"], "varchar(10)") if alias_eess else None,
            expr_eess(alias_maestro, columnas_maestro, ["codigo_unico", "cod_eess", "id_establecimiento", "id_eess"], "varchar(10)") if alias_maestro else None,
        ),
        "codigo_red": combinar_expr(
            defaults["codigo_red"],
            expr_eess(alias_eess, columnas_eess, ["cod_red", "codigo_red"], "varchar(10)") if alias_eess else None,
            expr_eess(alias_maestro, columnas_maestro, ["codigo_red", "cod_red"], "varchar(10)") if alias_maestro else None,
        ),
        "red": combinar_expr(
            defaults["red"],
            expr_eess(alias_eess, columnas_eess, ["red"], "text") if alias_eess else None,
            expr_eess(alias_maestro, columnas_maestro, ["red"], "text") if alias_maestro else None,
        ),
        "desc_ue": combinar_expr(
            defaults["desc_ue"],
            expr_eess(alias_eess, columnas_eess, ["desc_ue", "descripcion_sector", "disa"], "text") if alias_eess else None,
            expr_eess(alias_maestro, columnas_maestro, ["desc_ue", "disa", "descripcion_sector"], "text") if alias_maestro else None,
        ),
        "codigo_microred": combinar_expr(
            defaults["codigo_microred"],
            expr_eess(alias_eess, columnas_eess, ["cod_mred", "codigo_microred"], "varchar(10)") if alias_eess else None,
            expr_eess(alias_maestro, columnas_maestro, ["codigo_microred", "cod_mred"], "varchar(10)") if alias_maestro else None,
        ),
        "microred": combinar_expr(
            defaults["microred"],
            expr_eess(alias_eess, columnas_eess, ["microred"], "text") if alias_eess else None,
            expr_eess(alias_maestro, columnas_maestro, ["microred"], "text") if alias_maestro else None,
        ),
        "departamento": combinar_expr(
            defaults["departamento"],
            expr_eess(alias_eess, columnas_eess, ["dpto", "departamento"], "text") if alias_eess else None,
            expr_eess(alias_maestro, columnas_maestro, ["departamento", "dpto"], "text") if alias_maestro else None,
        ),
        "provincia": combinar_expr(
            defaults["provincia"],
            expr_eess(alias_eess, columnas_eess, ["provincia"], "text") if alias_eess else None,
            expr_eess(alias_maestro, columnas_maestro, ["provincia"], "text") if alias_maestro else None,
        ),
        "distrito": combinar_expr(
            defaults["distrito"],
            expr_eess(alias_eess, columnas_eess, ["distrito"], "text") if alias_eess else None,
            expr_eess(alias_maestro, columnas_maestro, ["distrito"], "text") if alias_maestro else None,
        ),
        "nombre_establecimiento": combinar_expr(
            defaults["nombre_establecimiento"],
            expr_eess(alias_eess, columnas_eess, ["nombre_eess", "nombre_establecimiento"], "text") if alias_eess else None,
            expr_eess(alias_maestro, columnas_maestro, ["nombre_establecimiento", "nombre_eess"], "text") if alias_maestro else None,
        ),
    }

    return "\n    ".join(joins), exprs


def parsear_argumentos() -> tuple[str, str]:
    if len(sys.argv) < 2:
        print("❌ Uso: python generar_his_proceso.py <anio> <maestros_json> [mes]")
        print("   o:  python generar_his_proceso.py <anio> [mes]")
        raise Exception("Argumentos insuficientes")

    anio_raw = sys.argv[1].strip()
    mes_raw = "Todos"

    if len(sys.argv) >= 3:
        segundo = sys.argv[2].strip()

        # Compatibilidad con llamada antigua: <anio> <maestros_json> [mes]
        if segundo.startswith("[") or segundo.startswith("{"):
            try:
                json.loads(segundo)
            except Exception:
                pass
            mes_raw = sys.argv[3].strip() if len(sys.argv) >= 4 else "Todos"
        else:
            mes_raw = segundo

    return anio_raw, mes_raw


def normalizar_mensaje_mes(mes: int | None) -> str:
    return "Todos" if mes is None else str(mes)


def parsear_mes(mes_raw: str) -> int | None:
    valor = (mes_raw or "").strip().lower()
    if valor in {"", "todos", "all", "todos los meses", "todos_los_meses"}:
        return None

    if not valor.isdigit():
        raise Exception(f"Mes no válido: {mes_raw}")

    mes = int(valor)
    if mes < 1 or mes > 12:
        raise Exception(f"Mes fuera de rango: {mes}")

    return mes


def parsear_anios(anio_raw: str) -> list[int]:
    valor = anio_raw.strip().lower()
    if valor in {"todos", "all"}:
        return list(ANIOS_SOPORTADOS)

    if not valor.isdigit():
        raise Exception(f"Año no válido: {anio_raw}")

    anio = int(valor)
    if anio not in ANIOS_SOPORTADOS:
        raise Exception(
            f"Año fuera de rango ({anio}). Usa uno entre {ANIOS_SOPORTADOS[0]} y {ANIOS_SOPORTADOS[-1]}."
        )

    return [anio]


def crear_estructura_his_proceso(cur):
    cur.execute(renderizar_sql_editor("estructura", ESQUEMA=ESQUEMA))
    cur.execute(
        f"ALTER TABLE {ESQUEMA}.his_proceso ADD COLUMN IF NOT EXISTS dni_personal varchar(50);"
    )
    cur.execute(
        f"ALTER TABLE {ESQUEMA}.his_proceso ADD COLUMN IF NOT EXISTS dni_registrador varchar(50);"
    )

    for anio in ANIOS_SOPORTADOS:
        nombre_particion = f"his_proceso_{anio}"
        cur.execute("SELECT to_regclass(%s);", (f"{ESQUEMA}.{nombre_particion}",))
        existe_particion = cur.fetchone()[0] is not None
        if existe_particion:
            continue

        cur.execute(
            renderizar_sql_editor(
                "particion",
                ESQUEMA=ESQUEMA,
                NOMBRE_PARTICION=nombre_particion,
                ANIO=anio,
                ANIO_SIGUIENTE=anio + 1,
            )
        )


def limpiar_periodo_his_proceso(cur, anio: int, mes: int | None):
    if mes is None:
        cur.execute(renderizar_sql_editor("limpiar_periodo_todos", ESQUEMA=ESQUEMA, ANIO=anio))
    else:
        cur.execute(
            renderizar_sql_editor(
                "limpiar_periodo_mes",
                ESQUEMA=ESQUEMA,
                ANIO=anio,
                MES=mes,
            )
        )


def crear_staging_his_proceso(
    cur,
    anio: int,
    mes: int | None,
    tablas: dict[str, str],
    staging_tabla: str,
):
    filtro_mes = ""
    if mes is not None:
        mes_texto = f"{mes:02d}"
        filtro_mes = f"AND nt.mes IN ('{mes_texto}', '{mes}')"

    join_eess = ""
    eess_expr = dict(EESS_DEFAULTS)

    sql = renderizar_sql_editor(
        "crear_staging",
        ESQUEMA=ESQUEMA,
        STAGING_TABLA=staging_tabla,
        ANIO=anio,
        FILTRO_MES=filtro_mes,
        TABLA_HISMINSA24=tablas["hisminsa24"],
        TABLA_MAESTRO_HIS_CIE_CPMS=tablas["maestro_his_cie_cpms"],
        TABLA_MAESTRO_PACIENTE=tablas["maestro_paciente"],
        TABLA_MAESTRO_HIS_ETNIA=tablas["maestro_his_etnia"],
        TABLA_MAESTRO_PERSONAL=tablas["maestro_personal"],
        TABLA_MAESTRO_HIS_UPS=tablas["maestro_his_ups"],
        TABLA_MAESTRO_HIS_COLEGIO=tablas["maestro_his_colegio"],
        JOIN_EESS=join_eess,
        EESS_COD_2000=eess_expr["cod_2000"],
        EESS_CODIGO_RED=eess_expr["codigo_red"],
        EESS_RED=eess_expr["red"],
        EESS_DESC_UE=eess_expr["desc_ue"],
        EESS_CODIGO_MICRORED=eess_expr["codigo_microred"],
        EESS_MICRORED=eess_expr["microred"],
        EESS_DEPARTAMENTO=eess_expr["departamento"],
        EESS_PROVINCIA=eess_expr["provincia"],
        EESS_DISTRITO=eess_expr["distrito"],
        EESS_NOMBRE_ESTABLECIMIENTO=eess_expr["nombre_establecimiento"],
    )
    cur.execute(sql)
    if tablas.get("eess_lookup_ready"):
        enriquecer_staging_eess(cur, staging_tabla)


def cargar_particion_final(cur, anio: int, staging_tabla: str):
    sincronizar_columnas_his_proceso_desde_staging(cur, staging_tabla)
    columnas = columnas_carga_final(cur, staging_tabla)
    columnas_sql = ", ".join([ident_sql(c) for c in columnas])
    cur.execute(
        renderizar_sql_editor(
            "cargar_particion_final",
            ESQUEMA=ESQUEMA,
            ANIO=anio,
            STAGING_TABLA=staging_tabla,
            COLUMNAS_SQL=columnas_sql,
        )
    )


def eliminar_staging(cur, staging_tabla: str):
    cur.execute(
        renderizar_sql_editor(
            "eliminar_staging",
            ESQUEMA=ESQUEMA,
            STAGING_TABLA=staging_tabla,
        )
    )


def ejecutar_periodo(
    conn,
    cur,
    anio: int,
    mes: int | None,
    tablas: dict[str, str],
    progreso_estado: dict[str, int],
    total_pasos: int,
):
    staging = f"his_proceso_stg_{anio}"
    texto_mes = normalizar_mensaje_mes(mes)

    print(f"\n🚀 Procesando HIS Proceso - Año: {anio} | Mes: {texto_mes}")

    def reportar_paso(etapa: str, estado: str = "ok"):
        progreso_estado["done"] += 1
        done = progreso_estado["done"]
        print(
            f"[PROGRESS] DONE={done}/{total_pasos}|mes={texto_mes}|estado={estado}|archivo={anio}-{etapa}"
        )

    try:
        crear_estructura_his_proceso(cur)
        reportar_paso("estructura")
        limpiar_periodo_his_proceso(cur, anio, mes)
        reportar_paso("limpieza")
        crear_staging_his_proceso(cur, anio, mes, tablas, staging)
        reportar_paso("staging")

        cur.execute(f"SELECT COUNT(*) FROM {ESQUEMA}.{staging};")
        filas_staging = cur.fetchone()[0]
        print(f"   📦 Filas en staging: {filas_staging:,}")
        reportar_paso("conteo")

        cargar_particion_final(cur, anio, staging)
        reportar_paso("carga_final")
        eliminar_staging(cur, staging)
        conn.commit()
        reportar_paso("final")

        print(f"✅ Carga finalizada para {anio} ({texto_mes}).")

    except Exception as e:
        conn.rollback()
        try:
            eliminar_staging(cur, staging)
            conn.commit()
        except Exception:
            conn.rollback()

        if progreso_estado["done"] < total_pasos:
            reportar_paso("error", "error")
        raise Exception(f"Error en periodo {anio}-{texto_mes}: {e}")


def main():
    anio_raw, mes_raw = parsear_argumentos()
    anios = parsear_anios(anio_raw)
    mes = parsear_mes(mes_raw)

    print("====================================")
    print("🧩 GENERACIÓN FIJA DE HIS_PROCESO")
    print(f"Años: {', '.join(str(a) for a in anios)}")
    print(f"Mes: {normalizar_mensaje_mes(mes)}")
    print("====================================")

    total_pasos = max(1, len(anios) * PASOS_PROCESO_POR_PERIODO)
    progreso_estado = {"done": 0}
    print(f"[PROGRESS] TOTAL={total_pasos}")

    conn = conectar()
    cur = conn.cursor()
    bloqueo_adquirido = False

    try:
        adquirir_bloqueo_his_proceso(cur)
        bloqueo_adquirido = True
        configurar_sesion_his_proceso(cur)
        tablas = resolver_tablas_fuente(cur)
        print("⚡ Verificando índices para acelerar el proceso...")
        asegurar_indices_fuente(cur, tablas)
        tablas["eess_lookup_ready"] = preparar_lookup_eess(cur, tablas)
        conn.commit()
        print("📚 Tablas fuente detectadas:")
        for nombre in [
            "hisminsa24",
            "maestro_paciente",
            "maestro_personal",
            "maestro_his_cie_cpms",
            "maestro_his_etnia",
            "maestro_his_ups",
            "maestro_his_colegio",
        ]:
            print(f"   - {nombre}: {tablas[nombre]}")

        if tablas.get("eess"):
            print(f"   - eess2025: {tablas['eess']}")
        else:
            print("   - eess2025: no encontrada")

        if tablas.get("eess_maestro"):
            print(f"   - respaldo_eess: {tablas['eess_maestro']}")
        else:
            print("   - respaldo_eess: no encontrado")

        for anio in anios:
            ejecutar_periodo(conn, cur, anio, mes, tablas, progreso_estado, total_pasos)

        print("\n✅ HIS Proceso generado correctamente.")

    except Exception as e:
        print(f"\n❌ Error: {e}")
        raise
    finally:
        if bloqueo_adquirido:
            try:
                conn.rollback()
                liberar_bloqueo_his_proceso(cur)
            except Exception:
                pass
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
