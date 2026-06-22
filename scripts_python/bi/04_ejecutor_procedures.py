import sys
import os
import psycopg2

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from db_config import get_db_config

_db_config = get_db_config()

def _split_statements(sql):
    """Split SQL into individual statements, respecting $$ blocks, /* */ blocks, and -- comments."""
    stmts = []
    buf = []
    in_dollar = False
    in_block_comment = False
    for line in sql.split('\n'):
        stripped = line.strip()

        # Track /* */ block comments
        if not in_block_comment and '/*' in stripped:
            in_block_comment = True
        if in_block_comment:
            if '*/' in stripped:
                in_block_comment = False
            buf.append(line)
            continue

        # Track dollar-quote blocks (stored procs/functions)
        if not in_dollar:
            if '$$' in stripped:
                in_dollar = True
        else:
            if '$$' in stripped:
                in_dollar = False

        buf.append(line)
        if not in_dollar and not in_block_comment and stripped.endswith(';') and not stripped.startswith('--'):
            stmts.append('\n'.join(buf))
            buf = []
    if buf:
        rest = '\n'.join(buf).strip()
        if rest:
            stmts.append(rest)
    return stmts

def ejecutar_procedure(ruta_sql, anio=None):
    try:
        with open(ruta_sql, 'r', encoding='utf-8') as f:
            query = f.read()

        if anio:
            query = query.replace('{ANIO}', str(anio))
            anio_int = int(anio)
            query = query.replace('{ANIO_MENOS_1}', str(anio_int - 1))
            query = query.replace('{ANIO_MAS_1}', str(anio_int + 1))

        conn = psycopg2.connect(
            host=_db_config.host,
            port=_db_config.port,
            database=_db_config.database,
            user=_db_config.user,
            password=_db_config.password
        )
        
        statements = _split_statements(query)
        cur = conn.cursor()
        for stmt in statements:
            # Strip comment-only lines from start/end, keep actual SQL
            lines = [l for l in stmt.split('\n') if l.strip() and not l.strip().startswith('--')]
            if not lines:
                continue
            sql = '\n'.join(lines).strip()
            if not sql:
                continue
            try:
                cur.execute(sql)
            except Exception as e:
                print(f"ERROR en statement: {str(e)[:200]}")
                print(f"SQL: {sql[:100]}...")
                raise
        conn.commit()
        cur.close()
        conn.close()
        
        print("OK: Script ejecutado correctamente")
        print("Archivo: " + os.path.basename(ruta_sql))

    except Exception as e:
        print("ERROR: " + str(e))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Error: No se proporciono la ruta del script SQL")
        sys.exit(1)
    
    anio = sys.argv[2] if len(sys.argv) > 2 else None
    ejecutar_procedure(sys.argv[1], anio)