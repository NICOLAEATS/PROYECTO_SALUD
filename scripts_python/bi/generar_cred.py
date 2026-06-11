import os
import sys
import psycopg2

ESQUEMA = 'es_ivan'

CODIGOS_CRED = [
    '99199.26','99403','99403.01','99436','99381.01','99401.03','99411.01','99431',
    'J00X','P599','J029','99381','99382','99383','C8002','Z001',
    '99401.05','99401.07','99401.08','99401.09','99401.12','99401.16','99401.24','99401.25',
    'P929','99211','99199.17','R620','R628','E440',
    'E669','E6690','E45X','E43X','E344',
    'B680','B681','B689','B700','B701','B760','B761','B8769','B779','B780','B79X','B820','B829',
    'A070','A071','A06','B663','B664','87178','B80X',
    '99199.28','C0011','85018.01',
    'P070','P071','P0711','P0712','P0713','P072','P073',
    'U1692','59430','U140','R456',
    'Z720','Z721','Z722','Z133',
    'H351','H579','Z010','H538','H509','H530','H559',
    'H179','H029','H028','H527','67228','67229','92390',
    '99499.01','99499.02','99499.03','99499.04','99499.05',
    '99499.06','99499.07','99499.08','99499.09','99499.10'
]

def get_db():
    return psycopg2.connect(host='localhost', port='5432', dbname='ivan_proceso_his', user='postgres', password='ivan')

def crear_cred(anio=None):
    conn = get_db()
    cur = conn.cursor()
    
    anio_filter = f"anio = {anio}" if anio else "anio IS NOT NULL"
    anio_target = anio if anio else 2026
    
    print(f"[INFO] Creando cred_{anio_target}...")
    
    codigos_str = "', '".join(CODIGOS_CRED)
    
    sql = f"""
    DROP TABLE IF EXISTS {ESQUEMA}.cred{anio_target};
    
    CREATE TABLE {ESQUEMA}.cred{anio_target} AS
    SELECT * FROM {ESQUEMA}.tabla_vacunas
    WHERE codigo_item IN ('{codigos_str}');
    """
    
    cur.execute(sql)
    conn.commit()
    
    cur.execute(f"SELECT COUNT(*) FROM {ESQUEMA}.cred{anio_target}")
    total = cur.fetchone()[0]
    
    print(f"[OK] cred{anio_target} creada: {total:,} registros")
    
    cur.close()
    conn.close()
    return total

def main():
    if len(sys.argv) > 1:
        anio = int(sys.argv[1])
    else:
        anio = 2026
    
    crear_cred(anio)

if __name__ == "__main__":
    main()