import pandas as pd
from sqlalchemy import create_engine, text
import sys
import os

# Importar configuración flexible de base de datos
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from db_config import get_db_config

# Obtener configuración de base de datos (con valores por defecto para compatibilidad)
_db_config = get_db_config()

# Configuración de conexión flexible
DB = f"postgresql://{_db_config.user}:{_db_config.password}@{_db_config.host}:{_db_config.port}/{_db_config.database}"

def ejecutar_sql():
    if len(sys.argv) < 2:
        print("❌ Error: No se proporcionó la ruta del script SQL.")
        return

    ruta_script = sys.argv[1]
    # Recibir los parámetros de la interfaz (o poner por defecto si no llegan)
    param_anio = sys.argv[2] if len(sys.argv) > 2 else "2024"
    param_mes = sys.argv[3] if len(sys.argv) > 3 else "Todos"
    
    try:
        with open(ruta_script, 'r', encoding='utf-8') as file:
            query = file.read()

        # 🚀 REEMPLAZO DINÁMICO DE VARIABLES
        query = query.replace('{ANIO}', str(param_anio))
        
        # Lógica genial para el mes: Si es "Todos", decimos que el mes "no sea nulo" (ignora el filtro).
        if param_mes == "Todos":
            query = query.replace('{FILTRO_MES}', "IS NOT NULL")
        else:
            query = query.replace('{FILTRO_MES}', f"= {param_mes}")

        engine = create_engine(DB)
        
        # (El resto del código se mantiene igual...)
        query_limpia = ""
        for linea in query.splitlines():
            if not linea.strip().startswith("--") and linea.strip() != "":
                query_limpia += linea.strip() + " "
        
        query_limpia = query_limpia.strip().upper()
        
        if query_limpia.startswith("SELECT") or query_limpia.startswith("WITH"):
            df = pd.read_sql_query(text(query), engine.connect())
            # Replace NaN/None with empty string for display
            df = df.fillna('')
            if df.empty:
                print("No se encontraron resultados para los filtros seleccionados.")
            else:
                print(f"✅ REGISTROS ENCONTRADOS: {len(df)}")
                print("=" * 70)
                pd.set_option('display.max_columns', None)
                pd.set_option('display.width', 1000)
                print(df.to_string(index=False))
                print("=" * 70)
        else:
            with engine.begin() as conn:
                conn.execute(text(query))
            # Mostramos en pantalla qué filtros usamos
            print(f"✅ Operación completada con éxito. [Parámetros usados -> Año: {param_anio} | Mes: {param_mes}]")

    except Exception as e:
        print(f"❌ ERROR de ejecución: {e}")

if __name__ == "__main__":
    ejecutar_sql()