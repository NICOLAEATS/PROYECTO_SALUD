import sys
import os
import psycopg2

# Importar configuración flexible de base de datos
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from db_config import get_db_config

# Obtener configuración de base de datos (con valores por defecto para compatibilidad)
_db_config = get_db_config()

DB = {"user": _db_config.user, "pass": _db_config.password, "host": _db_config.host, "port": _db_config.port, "db": _db_config.database}
ESQUEMA = _db_config.schema

anio = sys.argv[1]
mes = sys.argv[2]

def consolidar():
    conn = psycopg2.connect(dbname=DB["db"], user=DB["user"], password=DB["pass"], host=DB["host"], port=DB["port"])
    cur = conn.cursor()
    
    try:
        # 1. Crear o actualizar la tabla destino con los nuevos campos
        # Agregamos: dni_paciente e id_etnia
        cur.execute(f"""
            CREATE TABLE IF NOT EXISTS {ESQUEMA}.hisminsa_consolidado_full AS 
            SELECT h.*, 
                    CAST('' AS TEXT) as nombre_completo_paciente, 
                    CAST('' AS TEXT) as dni_paciente,
                    CAST('' AS TEXT) as id_etnia,
                    CAST('' AS TEXT) as nombre_completo_personal 
            FROM {ESQUEMA}.hisminsa_consolidado h LIMIT 0;
        """)
        
        # Verificar si las columnas nuevas existen (por si la tabla ya estaba creada de antes)
        cur.execute(f"""
            DO $$ 
            BEGIN 
                BEGIN ALTER TABLE {ESQUEMA}.hisminsa_consolidado_full ADD COLUMN dni_paciente TEXT; EXCEPTION WHEN duplicate_column THEN END;
                BEGIN ALTER TABLE {ESQUEMA}.hisminsa_consolidado_full ADD COLUMN id_etnia TEXT; EXCEPTION WHEN duplicate_column THEN END;
            END $$;
        """)

        if mes == "Todos los meses":
            print(f"🔄 Consolidando TODO el año {anio}...")
            cur.execute(f"DELETE FROM {ESQUEMA}.hisminsa_consolidado_full WHERE anio = %s", (anio,))
            condicion_mes = ""
        else:
            print(f"🔄 Consolidando {anio} - Mes {mes}...")
            cur.execute(f"DELETE FROM {ESQUEMA}.hisminsa_consolidado_full WHERE anio = %s AND mes = %s", (anio, mes))
            condicion_mes = f"AND h.mes = '{mes}'"

        # 2. EL CRUCE (JOIN) INCLUYENDO DNI Y ETNIA
        # Usamos numero_documento e id_etnia del maestro_paciente
        sql = f"""
            INSERT INTO {ESQUEMA}.hisminsa_consolidado_full
            SELECT h.*, 
                    (p.apellido_paterno_paciente || ' ' || p.apellido_materno_paciente || ', ' || p.nombres_paciente) as nombre_completo_paciente,
                    p.numero_documento as dni_paciente,
                    p.id_etnia as id_etnia,
                    (m.apellido_paterno_personal || ' ' || m.apellido_materno_personal || ', ' || m.nombres_personal) as nombre_completo_personal
            FROM {ESQUEMA}.hisminsa_consolidado h
            LEFT JOIN {ESQUEMA}.maestro_paciente p ON h.id_paciente = p.id_paciente
            LEFT JOIN {ESQUEMA}.maestro_personal m ON h.id_personal = m.id_personal
            WHERE h.anio = %s {condicion_mes};
        """
        
        cur.execute(sql, (anio,))
        conn.commit()
        
        # Limpiar todos los NULL
        columnas_limpiar = [
            "apellido_paterno_paciente", "apellido_materno_paciente", "nombres_paciente",
            "numero_documento", "id_etnia",
            "apellido_paterno_personal", "apellido_materno_personal", "nombres_personal",
            "hemoglobina", "talla", "peso", "perimetro_abdominal", "perimetro_cefalico",
            "codigo_item", "valor_lab"
        ]
        for col in columnas_limpiar:
            cur.execute(f"""UPDATE {ESQUEMA}.hisminsa_consolidado_full SET "{col}" = '' WHERE "{col}" IS NULL AND anio = %s AND mes = %s;""", (anio, mes))
        conn.commit()
        
        print("✅ Consolidación completada con éxito.")
        print("💡 Se han vinculado Nombres, DNI y Etnia del paciente.")
        
    except Exception as e:
        print(f"❌ Error en la consolidación: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    consolidar()