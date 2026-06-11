"""
actualizar_his_proceso_maestros.py

Refresca columnas de es_ivan.his_proceso relacionadas a:
  - maestro_paciente
  - maestro_personal

Uso:
    python actualizar_his_proceso_maestros.py <anio> [mes] [objetivo]

Donde:
  - anio: 2021..2026 (o "Todos")
  - mes:  1..12 (o "Todos")
  - objetivo: "maestro_paciente", "maestro_personal" o "todos"
"""

from __future__ import annotations

import os
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

import psycopg2


sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))
from db_config import get_db_config


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


def conectar():
    return psycopg2.connect(
        dbname=DB["db"],
        user=DB["user"],
        password=DB["pass"],
        host=DB["host"],
        port=DB["port"],
    )


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


def existe_tabla(cur, esquema: str, tabla: str) -> bool:
    cur.execute(
        """
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = %s AND table_name = %s
        LIMIT 1;
        """,
        (esquema, tabla),
    )
    return cur.fetchone() is not None


def asegurar_columnas_his_proceso(cur) -> None:
    cur.execute(
        f"ALTER TABLE {ESQUEMA}.his_proceso ADD COLUMN IF NOT EXISTS dni_personal varchar(50);"
    )
    cur.execute(
        f"ALTER TABLE {ESQUEMA}.his_proceso ADD COLUMN IF NOT EXISTS dni_registrador varchar(50);"
    )


def resolver_tablas_fuente(cur) -> dict[str, str]:
    return {
        "hisminsa24": resolver_tabla(cur, "hisminsa24", [ESQUEMA]),
        "maestro_paciente": resolver_tabla(cur, "maestro_paciente", [ESQUEMA, "maestros"]),
        "maestro_personal": resolver_tabla(cur, "maestro_personal", [ESQUEMA, "maestros"]),
        "maestro_his_etnia": resolver_tabla(cur, "maestro_his_etnia", ["maestros", ESQUEMA]),
        "maestro_his_colegio": resolver_tabla(
            cur, "maestro_his_colegio", ["maestros", ESQUEMA]
        ),
    }


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


def parsear_objetivo(objetivo_raw: str) -> str:
    valor = (objetivo_raw or "todos").strip().lower()
    permitidos = {"todos", "all", "maestro_paciente", "maestro_personal"}
    if valor not in permitidos:
        raise Exception(
            "Objetivo no válido. Usa: maestro_paciente, maestro_personal o todos"
        )
    return "todos" if valor == "all" else valor


def actualizar_paciente(cur, anio: int, mes: int | None, tablas: dict[str, str]) -> int:
    filtro_mes_nt = ""
    filtro_mes_hp = ""
    if mes is not None:
        filtro_mes_nt = f"AND nt.mes::text ~ '^[0-9]+$' AND nt.mes::int = {mes}"
        filtro_mes_hp = f"AND hp.mes = {mes}"

    sql = f"""
    WITH nt_base AS (
        SELECT
            CASE WHEN nt.id_cita::text ~ '^[0-9]+$' THEN nt.id_cita::int ELSE 0 END AS id_cita,
            CASE WHEN nt.anio::text ~ '^[0-9]+$' THEN nt.anio::int ELSE 0 END AS anio,
            nt.id_paciente
        FROM {tablas['hisminsa24']} nt
        WHERE nt.anio::text ~ '^[0-9]+$'
          AND nt.id_cita::text ~ '^[0-9]+$'
          AND nt.anio::int = {anio}
          {filtro_mes_nt}
    )
    UPDATE {ESQUEMA}.his_proceso hp
    SET
        dni_paciente = COALESCE(TRIM(mp.numero_documento::text), '')::varchar(50),
        apellido_paterno_paciente = COALESCE(TRIM(mp.apellido_paterno_paciente::text), '')::text,
        apellido_materno_paciente = COALESCE(TRIM(mp.apellido_materno_paciente::text), '')::text,
        nombres_paciente = COALESCE(TRIM(mp.nombres_paciente::text), '')::text,
        fecha_nacimiento = COALESCE(TRIM(mp.fecha_nacimiento::text), '')::date,
        id_tipo_documento = CASE
            WHEN mp.id_tipo_documento::text ~ '^[0-9]+$' THEN mp.id_tipo_documento::int
            ELSE 0
        END,
        genero = COALESCE(TRIM(mp.genero::text), '')::varchar(1),
        id_etnia = CASE
            WHEN mp.id_etnia::text ~ '^[0-9]+$' THEN mp.id_etnia::int
            ELSE 0
        END,
        descripcion_etnia = COALESCE(TRIM(et.descripcion_etnia::text), '')::text
    FROM nt_base nt
    LEFT JOIN {tablas['maestro_paciente']} mp
           ON nt.id_paciente::text = mp.id_paciente::text
    LEFT JOIN {tablas['maestro_his_etnia']} et
           ON mp.id_etnia::text = et.id_etnia::text
    WHERE hp.anio = nt.anio
      AND hp.id_cita = nt.id_cita
      {filtro_mes_hp};
    """
    cur.execute(sql)
    return cur.rowcount


def actualizar_personal(cur, anio: int, mes: int | None, tablas: dict[str, str]) -> int:
    filtro_mes_nt = ""
    filtro_mes_hp = ""
    if mes is not None:
        filtro_mes_nt = f"AND nt.mes::text ~ '^[0-9]+$' AND nt.mes::int = {mes}"
        filtro_mes_hp = f"AND hp.mes = {mes}"

    sql = f"""
    WITH nt_base AS (
        SELECT
            CASE WHEN nt.id_cita::text ~ '^[0-9]+$' THEN nt.id_cita::int ELSE 0 END AS id_cita,
            CASE WHEN nt.anio::text ~ '^[0-9]+$' THEN nt.anio::int ELSE 0 END AS anio,
            nt.id_personal,
            nt.id_registrador
        FROM {tablas['hisminsa24']} nt
        WHERE nt.anio::text ~ '^[0-9]+$'
          AND nt.id_cita::text ~ '^[0-9]+$'
          AND nt.anio::int = {anio}
          {filtro_mes_nt}
    )
    UPDATE {ESQUEMA}.his_proceso hp
    SET
        dni_personal = COALESCE(TRIM(mp2.numero_documento::text), '')::varchar(50),
        dni_registrador = COALESCE(TRIM(nt.id_registrador::text), '')::varchar(50),
        id_colegio = COALESCE(TRIM(mp2.id_colegio::text), '')::varchar(10),
        descripcion_colegio = COALESCE(TRIM(mhc.descripcion_colegio::text), '')::text
    FROM nt_base nt
    LEFT JOIN {tablas['maestro_personal']} mp2
           ON nt.id_personal::text = mp2.id_personal::text
    LEFT JOIN {tablas['maestro_his_colegio']} mhc
           ON mp2.id_colegio::text = mhc.id_colegio::text
    WHERE hp.anio = nt.anio
      AND hp.id_cita = nt.id_cita
      {filtro_mes_hp};
    """
    cur.execute(sql)
    return cur.rowcount


def main():
    if len(sys.argv) < 2:
        print("❌ Uso: python actualizar_his_proceso_maestros.py <anio> [mes] [objetivo]")
        raise Exception("Argumentos insuficientes")

    anio_raw = sys.argv[1].strip()
    mes_raw = sys.argv[2].strip() if len(sys.argv) > 2 else "Todos"
    objetivo_raw = sys.argv[3].strip() if len(sys.argv) > 3 else "todos"

    anios = parsear_anios(anio_raw)
    mes = parsear_mes(mes_raw)
    objetivo = parsear_objetivo(objetivo_raw)

    print("====================================")
    print("♻️ REFRESCO DE MAESTROS EN HIS_PROCESO")
    print(f"Años: {', '.join(str(a) for a in anios)}")
    print(f"Mes: {'Todos' if mes is None else mes}")
    print(f"Objetivo: {objetivo}")
    print("====================================")

    pasos_por_anio = 1
    if objetivo in {"todos", "maestro_paciente"}:
        pasos_por_anio += 1
    if objetivo in {"todos", "maestro_personal"}:
        pasos_por_anio += 1

    total_pasos = max(1, len(anios) * pasos_por_anio)
    paso_actual = 0
    mes_label = "Todos" if mes is None else f"{mes:02d}"
    print(f"[PROGRESS] TOTAL={total_pasos}")

    conn = conectar()
    cur = conn.cursor()

    try:
        if not existe_tabla(cur, ESQUEMA, "his_proceso"):
            raise Exception(
                f"La tabla {ESQUEMA}.his_proceso no existe. Primero genera HIS Proceso y luego refresca maestros."
            )

        asegurar_columnas_his_proceso(cur)

        tablas = resolver_tablas_fuente(cur)

        for anio in anios:
            print(f"\n🔄 Actualizando año {anio}...")
            total_paciente = 0
            total_personal = 0

            if objetivo in {"todos", "maestro_paciente"}:
                total_paciente = actualizar_paciente(cur, anio, mes, tablas)
                print(f"   👤 maestro_paciente aplicado en {total_paciente:,} fila(s).")
                paso_actual += 1
                print(
                    f"[PROGRESS] DONE={paso_actual}/{total_pasos}|mes={mes_label}|estado=ok|archivo={anio}-maestro_paciente"
                )

            if objetivo in {"todos", "maestro_personal"}:
                total_personal = actualizar_personal(cur, anio, mes, tablas)
                print(f"   🩺 maestro_personal aplicado en {total_personal:,} fila(s).")
                paso_actual += 1
                print(
                    f"[PROGRESS] DONE={paso_actual}/{total_pasos}|mes={mes_label}|estado=ok|archivo={anio}-maestro_personal"
                )

            conn.commit()
            paso_actual += 1
            print(
                f"[PROGRESS] DONE={paso_actual}/{total_pasos}|mes={mes_label}|estado=ok|archivo={anio}-commit"
            )

        print("\n✅ Refresco de maestros en his_proceso completado.")

    except Exception as e:
        conn.rollback()
        if paso_actual < total_pasos:
            paso_actual += 1
            print(
                f"[PROGRESS] DONE={paso_actual}/{total_pasos}|mes={mes_label}|estado=error|archivo=error"
            )
        print(f"\n❌ Error: {e}")
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
