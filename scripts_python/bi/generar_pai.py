import os
import sys
import psycopg2

ESQUEMA = 'es_ivan'
CODIGOS_PAI = [
    '90585','90633.01','90648','90649','90657','90658','90669','90670',
    '90681','90687','90688','90701','90702','90707','90712','90713','90714',
    '90715','90716','90717','90722','90723','90744','90746','Z238','Z2511'
]

def get_db():
    return psycopg2.connect(host='localhost', port='5432', dbname='ivan_proceso_his', user='postgres', password='ivan')

def crear_pai(anio=None):
    conn = get_db()
    cur = conn.cursor()
    
    anio_filter = f"anio = {anio}" if anio else "anio IS NOT NULL"
    
    print(f"[INFO] Creando pai_2026...")
    
    codigos_str = "', '".join(CODIGOS_PAI)
    donde = f"WHERE {anio_filter} AND codigo_item IN ('{codigos_str}')"
    
    sql = f"""
    DROP TABLE IF EXISTS {ESQUEMA}.pai_2026;
    
    CREATE TABLE {ESQUEMA}.pai_2026 AS
    SELECT 
        id_cita,
        anio,
        mes,
        codigo_item,
        valor_lab,
        tip_edad,
        edad,
        cod_2000,
        red,
        desc_ue,
        microred,
        provincia,
        distrito,
        dni_paciente,
        fecha_atencion,
        fecha_nacimiento,
        nombre_establecimiento,
        tipo_diagnostico,
        fg_tipo,
        id_etnia,
        genero,
        (fecha_atencion::date - fecha_nacimiento::date) AS edad_dias,
        (
            EXTRACT(YEAR FROM age(fecha_atencion, fecha_nacimiento)) * 12 +
            EXTRACT(MONTH FROM age(fecha_atencion, fecha_nacimiento))
        )::int AS edad_meses
    FROM {ESQUEMA}.tabla_vacunas
    {donde};
    """
    
    cur.execute(sql)
    conn.commit()
    
    cur.execute(f"SELECT COUNT(*) FROM {ESQUEMA}.pai_2026")
    total = cur.fetchone()[0]
    
    print(f"[OK] pai_2026 creada: {total:,} registros")
    
    cur.close()
    conn.close()
    return total

def main():
    if len(sys.argv) > 1:
        anio = int(sys.argv[1])
    else:
        anio = None
    
    crear_pai(anio)

if __name__ == "__main__":
    main()