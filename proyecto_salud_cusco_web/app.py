import sys, os, json, threading, subprocess, time, platform
from pathlib import Path
from typing import Optional
from flask import Flask, render_template, request, jsonify, session
from flask_cors import CORS

if platform.system() == 'Windows':
    CREATE_NO_WINDOW = 0x08000000
else:
    CREATE_NO_WINDOW = 0
from config import (
    BASE_DIR, PROJECT_ROOT, SCRIPTS_INGESTA, SCRIPTS_BI,
    SCRIPTS_MANTENIMIENTO, SCRIPTS_INSTALACION, SCRIPTS_SQL_REPORTES,
    SCRIPTS_SQL_VACUNAS, SCRIPTS_PADRONES, SCRIPTS_BI_LOAD,
    BOTONES_REPORTE_PREDETERMINADOS,
    SCRIPTS_MAESTROS_EDITABLES, EDITOR_BUTTONS_FILE
)

app = Flask(__name__)
app.secret_key = 'sistema-salud-cusco-web-2026'
CORS(app)

# ---------- Helper Utilities ----------
_scripts_python_dir = str(PROJECT_ROOT / "scripts_python")
if _scripts_python_dir not in sys.path:
    sys.path.insert(0, _scripts_python_dir)
    sys.path.insert(0, str(PROJECT_ROOT))

# ---------- Shared Execution State (Polling-based) ----------
_exec_state = {}
_exec_state_lock = threading.Lock()
_active_process = None
_active_process_lock = threading.Lock()
_next_token = int(time.time() * 1000)

MAX_LINES = 2000

def _nuevo_token():
    global _next_token
    with _exec_state_lock:
        _next_token += 1
        return _next_token

def _init_state(token, nombre):
    with _exec_state_lock:
        _exec_state[token] = {
            'token': token,
            'nombre': nombre,
            'status': 'starting',
            'lines': [],
            'line_count': 0,
            'progress': {'done': 0, 'total': 0, 'porcentaje': 0, 'eta': ''},
            'start_time': time.time(),
            'end_time': None,
            'exit_code': None,
            'error': None,
        }

def _append_line(token, line):
    with _exec_state_lock:
        state = _exec_state.get(token)
        if not state:
            return
        state['lines'].append(line)
        if len(state['lines']) > MAX_LINES:
            state['lines'] = state['lines'][-MAX_LINES//2:]
        state['line_count'] += 1

def _set_progress(token, total=None, done=None, porcentaje=None, eta=None):
    with _exec_state_lock:
        state = _exec_state.get(token)
        if not state:
            return
        p = state['progress']
        if total is not None:
            p['total'] = total
        if done is not None:
            p['done'] = done
        if porcentaje is not None:
            p['porcentaje'] = porcentaje
        if eta is not None:
            p['eta'] = eta

def _set_status(token, status, exit_code=None, error=None):
    with _exec_state_lock:
        state = _exec_state.get(token)
        if not state:
            return
        state['status'] = status
        if exit_code is not None:
            state['exit_code'] = exit_code
        if error is not None:
            state['error'] = error
        if status in ('completed', 'error', 'cancelled'):
            state['end_time'] = time.time()

def _get_state(token):
    with _exec_state_lock:
        s = _exec_state.get(token)
        if s is None:
            return None
        return dict(s)

def _cleanup_old_states():
    now = time.time()
    with _exec_state_lock:
        to_del = [t for t, s in _exec_state.items()
                  if s.get('end_time') and now - s['end_time'] > 300]
        for t in to_del:
            del _exec_state[t]

def _resolver_ruta_script(script_rel):
    return str(PROJECT_ROOT / script_rel)

def _cargar_config_editor():
    path = EDITOR_BUTTONS_FILE
    if path.exists():
        with open(str(path), 'r', encoding='utf-8') as f:
            return json.load(f)
    return {"botones": BOTONES_REPORTE_PREDETERMINADOS}

def _guardar_config_editor(config):
    with open(str(EDITOR_BUTTONS_FILE), 'w', encoding='utf-8') as f:
        json.dump(config, f, ensure_ascii=False, indent=2)

# ---------- Subprocess Execution with Polling ----------
def ejecutar_script(ruta_script, args=None, mostrar_progreso=False):
    global _active_process
    nombre = os.path.basename(ruta_script).replace('.py', '')
    token = _nuevo_token()
    _init_state(token, nombre)
    _set_status(token, 'starting')

    comando = [sys.executable, ruta_script]
    if args:
        comando.extend(args if isinstance(args, list) else [args])

    def hilo():
        global _active_process
        _set_status(token, 'running')
        try:
            _append_line(token, f"Iniciando: {' '.join(comando)}")

            env = os.environ.copy()
            env["PYTHONUTF8"] = "1"

            proc = subprocess.Popen(
                comando,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding='utf-8',
                errors='replace',
                env=env,
                creationflags=CREATE_NO_WINDOW,
            )

            with _active_process_lock:
                _active_process = proc

            total = None
            start_time = time.time()

            for line in iter(proc.stdout.readline, ''):
                if not line:
                    break

                state = _get_state(token)
                if state and state['status'] == 'cancelled':
                    proc.terminate()
                    time.sleep(0.5)
                    if proc.poll() is None:
                        proc.kill()
                    break

                line = line.rstrip('\n\r')
                _append_line(token, line)

                if mostrar_progreso and line.startswith('[PROGRESS]'):
                    payload = line[len('[PROGRESS]'):]
                    if payload.startswith('TOTAL='):
                        total = int(payload.split('=')[1])
                        _set_progress(token, total=total)
                    elif payload.startswith('DONE='):
                        parts = payload.split('|')
                        progress_data = {'token': token}
                        for p in parts:
                            if '=' in p:
                                k, v = p.split('=', 1)
                                progress_data[k.lower()] = v
                        done = int(progress_data.get('done', 0))
                        total_val = total or 100
                        pct = min(done / total_val, 1.0)
                        elapsed = time.time() - start_time
                        eta = ''
                        if done > 0:
                            eta_secs = (elapsed / done) * (total_val - done)
                            if eta_secs > 3600:
                                eta = f"{eta_secs/3600:.1f}h"
                            elif eta_secs > 60:
                                eta = f"{eta_secs/60:.0f}m {eta_secs%60:.0f}s"
                            else:
                                eta = f"{eta_secs:.0f}s"
                        _set_progress(token, done=done, porcentaje=pct, eta=eta)

            proc.wait()
            rc = proc.returncode
            with _active_process_lock:
                _active_process = None

            if rc == 0:
                _set_status(token, 'completed', exit_code=rc)
                _append_line(token, '✅ Completado correctamente')
            else:
                _set_status(token, 'error', exit_code=rc)
                _append_line(token, f'❌ Error (código {rc})')

        except Exception as e:
            with _active_process_lock:
                _active_process = None
            _set_status(token, 'error', error=str(e))
            _append_line(token, f'❌ Error: {e}')

    thread = threading.Thread(target=hilo, daemon=True)
    thread.start()
    return {'token': token, 'mensaje': 'Ejecución iniciada'}

# ---------- ROUTES ----------
@app.route('/')
def index():
    return render_template('index.html')

# ==================== DB CONFIG ====================
@app.route('/api/db/config', methods=['GET', 'POST'])
def db_config():
    try:
        from db_config import get_db_config, update_db_config
    except ImportError:
        return jsonify({'error': 'No se pudo importar db_config'}), 500

    if request.method == 'GET':
        cfg = get_db_config()
        return jsonify({
            'host': cfg.host if hasattr(cfg, 'host') else 'localhost',
            'port': cfg.port if hasattr(cfg, 'port') else 5432,
            'database': cfg.database if hasattr(cfg, 'database') else 'ivan_proceso_his',
            'schema': cfg.schema if hasattr(cfg, 'schema') else 'es_ivan',
            'user': cfg.user if hasattr(cfg, 'user') else 'postgres',
            'password': '********',
            'has_password': bool(cfg.password if hasattr(cfg, 'password') else ''),
        })

    data = request.json
    update_db_config(
        host=data.get('host'),
        port=data.get('port'),
        database=data.get('database'),
        schema=data.get('schema'),
        password=data.get('password'),
    )
    return jsonify({'mensaje': 'Configuración guardada'})

@app.route('/api/db/detect', methods=['POST'])
def db_detect():
    try:
        from db_config import detectar_postgresql_existente
        result = detectar_postgresql_existente()
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e), 'instalado': False}), 500

@app.route('/api/db/verify', methods=['POST'])
def db_verify():
    try:
        from db_config import verificar_bd_esquema, get_db_config
        cfg = get_db_config()
        log_lines = []
        exito = verificar_bd_esquema(
            config=cfg,
            log=lambda m: log_lines.append(m),
            guardar_password=True
        )
        return jsonify({'exito': bool(exito), 'mensaje': 'Verificación completada', 'log': log_lines})
    except Exception as e:
        return jsonify({'exito': False, 'mensaje': str(e), 'log': []}), 500

@app.route('/api/db/install', methods=['POST'])
def db_install():
    ruta = str(SCRIPTS_INSTALACION / 'instalar_postgresql.py')
    result = ejecutar_script(ruta, mostrar_progreso=True)
    return jsonify(result)

@app.route('/api/db/start-service', methods=['POST'])
def db_start_service():
    try:
        import platform
        if platform.system() == "Linux":
            for cmd in [
                ["sudo", "-n", "systemctl", "start", "postgresql"],
                ["systemctl", "start", "postgresql"],
                ["pkexec", "systemctl", "start", "postgresql"],
            ]:
                try:
                    result = subprocess.run(
                        cmd, capture_output=True, text=True, timeout=30,
                    )
                    if result.returncode == 0:
                        time.sleep(2)
                        return jsonify({'exito': True, 'mensaje': "PostgreSQL iniciado correctamente"})
                except Exception:
                    continue
            return jsonify({
                'exito': False,
                'mensaje': "No se pudo iniciar PostgreSQL automáticamente. Ejecute manualmente: sudo systemctl start postgresql"
            })
        sys.path.insert(0, str(SCRIPTS_INSTALACION))
        from instalar_postgresql import iniciar_servicio_postgresql, esperar_servicio_activo
        from db_config import detectar_postgresql_existente
        info = detectar_postgresql_existente()
        exito = iniciar_servicio_postgresql(info.get("servicio_nombre"))
        if exito:
            esperar_servicio_activo(info.get("servicio_nombre"), timeout=30)
        return jsonify({'exito': exito, 'mensaje': "Servicio iniciado" if exito else "No se pudo iniciar"})
    except Exception as e:
        return jsonify({'exito': False, 'mensaje': str(e)}), 500

@app.route('/api/db/init', methods=['POST'])
def db_init():
    try:
        sys.path.insert(0, str(SCRIPTS_INSTALACION))
        from db_config import get_db_config, verificar_bd_esquema
        from instalar_postgresql import crear_base_datos_y_esquema
        cfg = get_db_config()
        log_lines = []
        exito = crear_base_datos_y_esquema(
            cfg.host, cfg.port, cfg.user, cfg.password,
            cfg.database, cfg.schema,
            log=lambda m: log_lines.append(m)
        )
        return jsonify({'exito': exito, 'log': log_lines})
    except Exception as e:
        return jsonify({'exito': False, 'mensaje': str(e)}), 500

@app.route('/api/db/recover-password', methods=['POST'])
def db_recover_password():
    try:
        from db_config import inicializar_base_datos, get_db_config
        cfg = get_db_config()
        log_lines = []
        exito = inicializar_base_datos(log=lambda m: log_lines.append(m))
        return jsonify({'exito': exito, 'log': log_lines})
    except Exception as e:
        return jsonify({'exito': False, 'mensaje': str(e)}), 500

# ==================== EJECUCION STATUS / CANCEL (Polling) ====================
@app.route('/api/ejecucion/status/<int:token>')
def ejecucion_status(token):
    state = _get_state(token)
    if state is None:
        return jsonify({'error': 'Ejecución no encontrada', 'status': 'unknown'}), 404
    return jsonify(state)

@app.route('/api/ejecucion/cancel', methods=['POST'])
def ejecucion_cancel():
    global _active_process
    data = request.json
    token = data.get('token', 0)

    if token:
        state = _get_state(token)
        if state and state['status'] in ('running', 'starting'):
            _set_status(token, 'cancelled')
            _append_line(token, '🛑 Proceso cancelado por el usuario')

    with _active_process_lock:
        if _active_process:
            try:
                _active_process.terminate()
                time.sleep(0.5)
                if _active_process.poll() is None:
                    _active_process.kill()
            except Exception:
                pass
            _active_process = None

    return jsonify({'mensaje': 'Proceso cancelado'})

# ==================== INGESTA ====================
def _meses_con_datos(anio):
    """Retorna lista de meses (int) que ya tienen datos en BD para el año."""
    try:
        from db_config import get_db_config
        import psycopg2
        cfg = get_db_config()
        conn = psycopg2.connect(
            dbname=cfg.database, user=cfg.user, password=cfg.password,
            host=cfg.host, port=cfg.port, connect_timeout=5
        )
        cur = conn.cursor()
        cur.execute(f"SELECT DISTINCT mes FROM {cfg.schema}.hisminsa24 WHERE anio = %s AND mes ~ '^[0-9]+$'", (anio,))
        meses = sorted(set(int(row[0]) for row in cur.fetchall() if row[0].isdigit()))
        cur.close(); conn.close()
        return meses
    except Exception:
        return []

def _borrar_anio_bd(anio):
    """Borra todos los registros de un año antes de importar."""
    from db_config import get_db_config
    import psycopg2
    cfg = get_db_config()
    conn = psycopg2.connect(
        dbname=cfg.database, user=cfg.user, password=cfg.password,
        host=cfg.host, port=cfg.port, connect_timeout=5
    )
    cur = conn.cursor()
    cur.execute(f"DELETE FROM {cfg.schema}.hisminsa24 WHERE anio = %s", (anio,))
    borrados = cur.rowcount
    conn.commit()
    cur.close(); conn.close()
    return borrados

@app.route('/api/ingesta/check', methods=['POST'])
def ingesta_check():
    """Verifica qué meses del año ya tienen datos en BD."""
    data = request.json
    anio = data.get('anio', '2024')
    meses_bd = _meses_con_datos(anio)
    return jsonify({'anio': anio, 'meses_con_datos': meses_bd, 'tiene_datos': len(meses_bd) > 0})

@app.route('/api/ingesta/import', methods=['POST'])
def ingesta_import():
    data = request.json
    anio = data.get('anio', '2024')
    meses = data.get('meses', [])
    ruta_crudos = data.get('ruta_crudos', '')
    modo = data.get('modo', 'reemplazar')  # 'reemplazar' o 'completar'

    # Si modo es completar, filtrar meses que ya tienen datos
    if modo == 'completar':
        meses_bd = _meses_con_datos(anio)
        meses = [m for m in meses if m not in meses_bd]
        if not meses:
            return jsonify({'error': 'Todos los meses ya tienen datos', 'skip': True}), 200

    # Si modo es reemplazar, borrar datos del año antes de importar
    if modo == 'reemplazar':
        try:
            borrados = _borrar_anio_bd(anio)
        except Exception:
            pass  # si falla el borrado, el script internamente limpia mes x mes

    # Igual que el desktop: si hay ruta personalizada,
    # primero prueba ruta/anio, si no existe usa ruta tal cual
    if ruta_crudos:
        carpeta_con_anio = os.path.join(ruta_crudos, anio)
        ruta_final = carpeta_con_anio if os.path.isdir(carpeta_con_anio) else ruta_crudos
    else:
        ruta_final = ''

    if not meses or len(meses) == 12:
        script = str(SCRIPTS_INGESTA / '01cargacvs_universal.py')
        args = [anio]
        if ruta_final:
            args.append(ruta_final)
    else:
        script = str(SCRIPTS_INGESTA / '01cargacvs_mensual.py')
        args = [anio] + [str(m) for m in meses]
        if ruta_final:
            args.append(ruta_final)

    return jsonify(ejecutar_script(script, args=args, mostrar_progreso=True))

@app.route('/api/ingesta/refresh', methods=['POST'])
def ingesta_refresh():
    script = str(SCRIPTS_INGESTA / 'actualizar_his_proceso_maestros.py')
    return jsonify(ejecutar_script(script, mostrar_progreso=True))

@app.route('/api/ingesta/delete', methods=['POST'])
def ingesta_delete():
    data = request.json
    modo = data.get('modo', 'todo')
    anio = data.get('anio', '')
    mes = data.get('mes', '')
    script = str(SCRIPTS_MANTENIMIENTO / '02_eliminar_datos.py')
    args = [f'modo={modo}']
    if modo == 'anio' and anio:
        args.append(f'anio={anio}')
    if modo == 'mes' and anio and mes:
        args.append(f'anio={anio}')
        args.append(f'mes={mes}')
    return jsonify(ejecutar_script(script, args=args, mostrar_progreso=True))

# ==================== REPORTES ====================
@app.route('/api/reportes/config', methods=['GET'])
def reportes_config():
    config = _cargar_config_editor()
    return jsonify(config)

@app.route('/api/reportes/run', methods=['POST'])
def reportes_run():
    data = request.json
    ruta_script = data.get('script', '')
    anio = data.get('anio', '2024')

    ruta_abs = str(PROJECT_ROOT / ruta_script)
    ext = Path(ruta_script).suffix.lower()

    if ext == '.sql':
        from db_config import get_db_config
        cfg = get_db_config()

        with open(ruta_abs, 'r', encoding='utf-8', errors='replace') as f:
            sql_content = f.read()

        sql_upper = sql_content.strip().upper()
        if any(sql_upper.startswith(kw) for kw in ('CREATE', 'INSERT', 'DROP', 'UPDATE', 'DELETE', 'ALTER', 'TRUNCATE')):
            executor = str(SCRIPTS_BI / '04_ejecutor_procedures.py')
        else:
            executor = str(SCRIPTS_BI / '04_generador_reportes.py')

        result = ejecutar_script(executor, args=[ruta_abs, anio])
    else:
        result = ejecutar_script(ruta_abs, args=[anio])

    return jsonify(result)

@app.route('/api/reportes/save-config', methods=['POST'])
def reportes_save_config():
    data = request.json
    _guardar_config_editor(data)
    return jsonify({'mensaje': 'Configuración guardada'})

@app.route('/api/reportes/new', methods=['POST'])
def reportes_new():
    data = request.json
    nombre = data.get('nombre', '')
    seccion = data.get('seccion', 'reportes')
    color = data.get('color', '#3498DB')

    safe_name = nombre.lower().replace(' ', '_').replace('\u20e3', '').strip()
    sql_path = SCRIPTS_SQL_REPORTES / f"{safe_name}.sql"
    with open(str(sql_path), 'w', encoding='utf-8') as f:
        f.write(f"-- {nombre}\n-- GERESA Cusco - Sistema de Monitoreo de Salud\n\nSELECT 1;\n")

    config = _cargar_config_editor()
    config['botones'].append({
        'nombre': nombre,
        'script': f"scripts_sql/reportes/{safe_name}.sql",
        'seccion': seccion,
        'color_bg': color,
        'custom': True,
    })
    _guardar_config_editor(config)
    return jsonify({'mensaje': f'Reporte "{nombre}" creado', 'ruta': str(sql_path)})

@app.route('/api/reportes/delete', methods=['POST'])
def reportes_delete():
    data = request.json
    idx = data.get('index', -1)
    config = _cargar_config_editor()
    if 0 <= idx < len(config['botones']):
        boton = config['botones'].pop(idx)
        if boton.get('custom'):
            ruta = str(PROJECT_ROOT / boton['script'])
            if os.path.exists(ruta):
                os.remove(ruta)
        _guardar_config_editor(config)
        return jsonify({'mensaje': f'Reporte "{boton["nombre"]}" eliminado'})
    return jsonify({'error': 'Índice inválido'}), 400

# ==================== MAESTROS ====================
@app.route('/api/maestros/tablas', methods=['GET'])
def maestros_tablas():
    try:
        import psycopg2
        from db_config import get_db_config
        cfg = get_db_config()
        conn = psycopg2.connect(
            host=cfg.host, port=cfg.port, user=cfg.user,
            password=cfg.password, dbname=cfg.database
        )
        cur = conn.cursor()
        cur.execute("""
            SELECT table_name, table_schema
            FROM information_schema.tables
            WHERE table_schema = %s
            ORDER BY table_name
        """, (cfg.schema,))
        tablas = [{'nombre': r[0], 'esquema': r[1]} for r in cur.fetchall()]
        cur.close()
        conn.close()
        return jsonify(tablas)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/maestros/ejecutar', methods=['POST'])
def maestros_ejecutar():
    data = request.json
    script = data.get('script', '')
    args = data.get('args', [])
    ruta = str(PROJECT_ROOT / script)
    return jsonify(ejecutar_script(ruta, args=args, mostrar_progreso=True))

@app.route('/api/maestros/csv-list', methods=['POST'])
def maestros_csv_list():
    data = request.json
    folder = data.get('folder', '')
    if not folder or not os.path.isdir(folder):
        return jsonify({'error': 'Carpeta inválida'}), 400
    try:
        csvs = sorted([f for f in os.listdir(folder) if f.lower().endswith('.csv')])
        return jsonify({'csvs': csvs, 'folder': folder})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/maestros/eliminar', methods=['POST'])
def maestros_eliminar():
    data = request.json
    tablas = data.get('tablas', [])
    if not tablas:
        return jsonify({'error': 'No se especificaron tablas'}), 400
    try:
        import psycopg2
        from db_config import get_db_config
        cfg = get_db_config()
        conn = psycopg2.connect(host=cfg.host, port=cfg.port, user=cfg.user, password=cfg.password, dbname=cfg.database)
        cur = conn.cursor()
        resultados = []
        for t in tablas:
            try:
                cur.execute(f'DROP TABLE IF EXISTS "{cfg.schema}"."{t}" CASCADE;')
                conn.commit()
                resultados.append({'tabla': t, 'ok': True})
            except Exception as e:
                resultados.append({'tabla': t, 'ok': False, 'error': str(e)})
        cur.close()
        conn.close()
        return jsonify({'resultados': resultados})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/maestros/eliminar-todos', methods=['POST'])
def maestros_eliminar_todos():
    try:
        import psycopg2
        from db_config import get_db_config
        cfg = get_db_config()
        conn = psycopg2.connect(host=cfg.host, port=cfg.port, user=cfg.user, password=cfg.password, dbname=cfg.database)
        cur = conn.cursor()
        cur.execute(f"""
            SELECT table_name FROM information_schema.tables
            WHERE table_schema = '{cfg.schema}'
            AND (table_name LIKE 'maestro%%' OR table_name = 'eess2025' OR table_name LIKE '%%susalud%%')
        """)
        tablas = [r[0] for r in cur.fetchall()]
        for t in tablas:
            cur.execute(f'DROP TABLE IF EXISTS "{cfg.schema}"."{t}" CASCADE;')
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'ok': True, 'eliminadas': len(tablas)})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/maestros/descriptions', methods=['GET'])
def maestros_descriptions():
    descs = {
        "maestro_paciente": "Paciente (DNI, nombre, fecha nac., género, etnia)",
        "maestro_personal": "Personal de salud (colegio profesional)",
        "eess2025": "Establecimiento (red, microred, provincia, distrito)",
        "maestro_his_establecimiento": "Establecimientos crudos HIS (fuente para reconstruir eess2025)",
        "maestro_his_cie_cpms": "Diagnósticos CIE / Procedimientos CPT",
        "maestro_his_etnia": "Etnias (descripción)",
        "maestro_his_ups": "Unidades Productoras de Servicios (UPS)",
        "maestro_his_colegio": "Colegios profesionales",
        "maestro_his_actividad": "Actividades HIS",
        "maestro_his_centro_poblado": "Centros poblados",
        "maestro_his_condicion_contrato": "Condición de contrato del personal",
        "maestro_his_dosis": "Dosis de vacunas",
        "maestro_his_financiador": "Financiadores (SIS, ESSALUD, etc.)",
        "maestro_his_gruporiesgo_lab": "Grupos de riesgo (lab)",
        "maestro_his_institucion_edu": "Instituciones educativas",
        "maestro_his_lab": "Laboratorio (parámetros)",
        "maestro_his_otra_condicion": "Otra condición clínica",
        "maestro_his_pais": "Países (código y nombre)",
        "maestro_his_profesion": "Profesiones del personal",
        "maestro_his_sistema": "Sistemas de salud",
        "maestro_his_tipo_doc": "Tipos de documento de identidad",
        "maestro_his_ubigeo": "Ubigeos INEI / RENIEC",
        "maestro_his_susalud": "SUSALUD (establecimientos supervisados)",
        "maestro_eess_susalud": "SUSALUD crudo (fuente para reconstruir eess2025)",
    }
    return jsonify(descs)

# ==================== PADRON NOMINAL ====================
def _db_cursor():
    from db_config import get_db_config
    import psycopg2
    cfg = get_db_config()
    conn = psycopg2.connect(host=cfg.host, port=cfg.port, user=cfg.user, password=cfg.password, dbname=cfg.database)
    return conn

def _tabla_existe(nombre_tabla):
    try:
        conn = _db_cursor()
        cur = conn.cursor()
        from db_config import get_db_config
        cfg = get_db_config()
        cur.execute("SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema=%s AND table_name=%s)", (cfg.schema, nombre_tabla))
        res = cur.fetchone()[0]
        cur.close(); conn.close()
        return res
    except:
        return False

@app.route('/api/padron/status', methods=['GET'])
def padron_status():
    existe = _tabla_existe('padron_nominal')
    total = 0
    if existe:
        try:
            conn = _db_cursor()
            cur = conn.cursor()
            from db_config import get_db_config
            cfg = get_db_config()
            cur.execute(f"SELECT COUNT(*) FROM {cfg.schema}.padron_nominal")
            total = cur.fetchone()[0]
            cur.close(); conn.close()
        except:
            pass
    return jsonify({'existe': existe, 'total': total})

@app.route('/api/padron/cargar', methods=['POST'])
def padron_cargar():
    script = str(SCRIPTS_BI / 'cargar_padron_nominal.py')
    return jsonify(ejecutar_script(script, mostrar_progreso=True))

@app.route('/api/padron/consulta', methods=['POST'])
def padron_consulta():
    data = request.json
    pagina = data.get('pagina', 1)
    por_pagina = data.get('por_pagina', 50)
    busqueda = data.get('busqueda', '')
    offset = (pagina - 1) * por_pagina

    try:
        conn = _db_cursor()
        cur = conn.cursor()
        from db_config import get_db_config
        cfg = get_db_config()
        tabla = f"{cfg.schema}.padron_nominal"

        if busqueda:
            filtro = f"WHERE (nombre_nino ILIKE %s OR apellido_pat_nino ILIKE %s OR apellido_mat_nino ILIKE %s OR doc_madre ILIKE %s)"
            param = f'%{busqueda}%'
            params = [param, param, param, param]
            cur.execute(f"SELECT COUNT(*) FROM {tabla} {filtro}", params)
            total = cur.fetchone()[0]
            cur.execute(f"SELECT * FROM {tabla} {filtro} ORDER BY anio DESC, nro LIMIT %s OFFSET %s", params + [por_pagina, offset])
        else:
            cur.execute(f"SELECT COUNT(*) FROM {tabla}")
            total = cur.fetchone()[0]
            cur.execute(f"SELECT * FROM {tabla} ORDER BY anio DESC, nro LIMIT %s OFFSET %s", [por_pagina, offset])

        cols = [desc[0] for desc in cur.description]
        filas = [dict(zip(cols, row)) for row in cur.fetchall()]
        cur.close(); conn.close()
        return jsonify({'filas': filas, 'total': total, 'pagina': pagina, 'por_pagina': por_pagina})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/padron/geojson', methods=['GET'])
def padron_geojson():
    try:
        conn = _db_cursor()
        cur = conn.cursor()
        from db_config import get_db_config
        cfg = get_db_config()
        cur.execute(f"""
            SELECT latitud, longitud, nombre_nino, apellido_pat_nino,
                   apellido_mat_nino, direccion, dist_nino, ubigeo_pn
            FROM {cfg.schema}.padron_nominal
            WHERE latitud IS NOT NULL AND longitud IS NOT NULL
            AND latitud BETWEEN -14 AND -12
            AND longitud BETWEEN -73 AND -70
            LIMIT 5000
        """)
        features = []
        for row in cur.fetchall():
            lat, lng, nombre, apat, amat, dir, dist, ubigeo = row
            if lat and lng:
                features.append({
                    'type': 'Feature',
                    'geometry': {'type': 'Point', 'coordinates': [lng, lat]},
                    'properties': {
                        'nombre': f"{nombre or ''} {apat or ''} {amat or ''}",
                        'direccion': dir or '',
                        'distrito': dist or '',
                        'ubigeo': ubigeo or '',
                    }
                })
        cur.close(); conn.close()
        return jsonify({'type': 'FeatureCollection', 'features': features})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ==================== CNV ====================
@app.route('/api/cnv/status', methods=['GET'])
def cnv_status():
    existe = _tabla_existe('cnv_cusco')
    total = 0
    if existe:
        try:
            conn = _db_cursor()
            cur = conn.cursor()
            from db_config import get_db_config
            cfg = get_db_config()
            cur.execute(f"SELECT COUNT(*) FROM {cfg.schema}.cnv_cusco")
            total = cur.fetchone()[0]
            cur.close(); conn.close()
        except:
            pass
    return jsonify({'existe': existe, 'total': total})

@app.route('/api/cnv/cargar', methods=['POST'])
def cnv_cargar():
    script = str(SCRIPTS_BI / 'cargar_cnv.py')
    return jsonify(ejecutar_script(script, mostrar_progreso=True))

@app.route('/api/cnv/consulta', methods=['POST'])
def cnv_consulta():
    data = request.json
    pagina = data.get('pagina', 1)
    por_pagina = data.get('por_pagina', 50)
    busqueda = data.get('busqueda', '')
    offset = (pagina - 1) * por_pagina

    try:
        conn = _db_cursor()
        cur = conn.cursor()
        from db_config import get_db_config
        cfg = get_db_config()
        tabla = f"{cfg.schema}.cnv_cusco"

        if busqueda:
            filtro = "WHERE (pri_ape_madre ILIKE %s OR seg_ape_madre ILIKE %s OR prenom_madre ILIKE %s OR nu_doc_madre ILIKE %s OR nu_cnv ILIKE %s)"
            param = f'%{busqueda}%'
            params = [param]*5
            cur.execute(f"SELECT COUNT(*) FROM {tabla} {filtro}", params)
            total = cur.fetchone()[0]
            cur.execute(f"SELECT * FROM {tabla} {filtro} ORDER BY fe_crea DESC LIMIT %s OFFSET %s", params + [por_pagina, offset])
        else:
            cur.execute(f"SELECT COUNT(*) FROM {tabla}")
            total = cur.fetchone()[0]
            cur.execute(f"SELECT * FROM {tabla} ORDER BY fe_crea DESC LIMIT %s OFFSET %s", [por_pagina, offset])

        cols = [desc[0] for desc in cur.description]
        filas = [dict(zip(cols, row)) for row in cur.fetchall()]
        cur.close(); conn.close()
        return jsonify({'filas': filas, 'total': total, 'pagina': pagina, 'por_pagina': por_pagina})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ==================== MAPA / GEOLOCALIZACION ====================
@app.route('/api/mapa/kde', methods=['POST'])
def mapa_kde():
    """Genera datos KDE a partir de coordenadas del Padron Nominal + IRAS desde his_proceso."""
    try:
        data = request.json or {}
        anio = data.get('anio', '2026')
        microred = data.get('microred', '')

        conn = _db_cursor()
        cur = conn.cursor()
        from db_config import get_db_config
        cfg = get_db_config()

        query = f"""
            SELECT pn.latitud, pn.longitud
            FROM {cfg.schema}.padron_nominal pn
            WHERE pn.latitud IS NOT NULL AND pn.longitud IS NOT NULL
            AND pn.latitud BETWEEN -14 AND -12
            AND pn.longitud BETWEEN -73 AND -70
        """

        cur.execute(query)
        coords = [(float(r[0]), float(r[1])) for r in cur.fetchall() if r[0] and r[1]]
        cur.close(); conn.close()

        if len(coords) < 5:
            return jsonify({'error': 'Muy pocas coordenadas disponibles para KDE', 'coords_count': len(coords)}), 400

        return jsonify({
            'coords_count': len(coords),
            'coordenadas': [[lat, lng] for lat, lng in coords[:2000]],
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/mapa/pacientes-por-distrito', methods=['GET'])
def mapa_pacientes_por_distrito():
    try:
        conn = _db_cursor()
        cur = conn.cursor()
        from db_config import get_db_config
        cfg = get_db_config()
        cur.execute(f"""
            SELECT dist_nino, COUNT(*) as total,
                   COUNT(*) FILTER (WHERE latitud IS NOT NULL) as con_coord
            FROM {cfg.schema}.padron_nominal
            GROUP BY dist_nino
            ORDER BY total DESC
        """)
        rows = [{'distrito': r[0], 'total': r[1], 'con_coord': r[2]} for r in cur.fetchall()]
        cur.close(); conn.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ==================== DASHBOARDS ====================
@app.route('/api/dashboards/resumen', methods=['GET'])
def dashboards_resumen():
    try:
        conn = _db_cursor()
        cur = conn.cursor()
        from db_config import get_db_config
        cfg = get_db_config()
        esquema = cfg.schema

        resumen = {}

        for tabla, nombre in [('padron_nominal', 'Padron Nominal'),
                              ('cnv_cusco', 'CNV'),
                              ('tabla_vacunas', 'Vacunas'),
                              ('tabla_materno', 'Materno'),
                              ('tabla_iras_edas', 'IRAS/EDAS')]:
            try:
                cur.execute(f"SELECT COUNT(*) FROM {esquema}.{tabla}")
                resumen[nombre] = cur.fetchone()[0]
            except:
                resumen[nombre] = -1

        cur.close(); conn.close()
        return jsonify(resumen)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ==================== EDITOR ====================
EDITOR_CREDENTIALS = {'usuario': 'ivan', 'password': 'ivanar'}

@app.route('/api/editor/login', methods=['POST'])
def editor_login():
    data = request.json
    if data.get('usuario') == EDITOR_CREDENTIALS['usuario'] and data.get('password') == EDITOR_CREDENTIALS['password']:
        session['editor'] = True
        return jsonify({'exito': True})
    return jsonify({'exito': False, 'mensaje': 'Credenciales inválidas'}), 401

@app.route('/api/editor/check', methods=['GET'])
def editor_check():
    return jsonify({'activo': session.get('editor', False)})

@app.route('/api/editor/logout', methods=['POST'])
def editor_logout():
    session.pop('editor', None)
    return jsonify({'exito': True})

@app.route('/api/editor/scripts', methods=['GET'])
def editor_scripts():
    config = _cargar_config_editor()
    return jsonify({
        'reportes': config.get('botones', []),
        'maestros': SCRIPTS_MAESTROS_EDITABLES,
    })

@app.route('/api/editor/script-content', methods=['POST'])
def editor_script_content():
    data = request.json
    ruta = data.get('ruta', '')
    ruta_abs = str(PROJECT_ROOT / ruta)
    if not os.path.exists(ruta_abs):
        return jsonify({'error': 'Archivo no encontrado'}), 404
    with open(ruta_abs, 'r', encoding='utf-8', errors='replace') as f:
        contenido = f.read()
    return jsonify({'contenido': contenido, 'ruta': ruta})

@app.route('/api/editor/script-save', methods=['POST'])
def editor_script_save():
    data = request.json
    ruta = data.get('ruta', '')
    contenido = data.get('contenido', '')
    ruta_abs = str(PROJECT_ROOT / ruta)
    with open(ruta_abs, 'w', encoding='utf-8') as f:
        f.write(contenido)
    return jsonify({'mensaje': 'Guardado correctamente'})

@app.route('/api/editor/restore', methods=['POST'])
def editor_restore():
    config = {'botones': BOTONES_REPORTE_PREDETERMINADOS}
    _guardar_config_editor(config)
    return jsonify({'mensaje': 'Scripts restaurados a valores originales'})

# ==================== TUNNEL (Cloudflare) ====================
_tunnel_proc: Optional[subprocess.Popen] = None
_tunnel_url: str = ""

@app.route('/api/tunnel/start', methods=['POST'])
def tunnel_start():
    global _tunnel_proc, _tunnel_url
    if _tunnel_proc and _tunnel_proc.poll() is None:
        return jsonify({'exito': True, 'url': _tunnel_url, 'mensaje': 'Tunnel ya activo'})
    try:
        import shutil, platform as _plt
        if _plt.system() == "Windows":
            cf_bin = shutil.which("cloudflared") or str(PROJECT_ROOT / "tunnel" / "cloudflared.exe")
        else:
            cf_bin = shutil.which("cloudflared") or "/tmp/cloudflared"
        if not os.path.exists(cf_bin):
            return jsonify({'exito': False, 'mensaje': 'cloudflared no encontrado. Descargalo de https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/'})
        logfile = str(BASE_DIR / "tunnel" / "tunnel.log")
        os.makedirs(os.path.dirname(logfile), exist_ok=True)
        _tunnel_proc = subprocess.Popen(
            [cf_bin, "tunnel", "--url", "http://127.0.0.1:5000", "--logfile", logfile],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        _tunnel_url = ""
        return jsonify({'exito': True, 'mensaje': 'Tunnel iniciando...'})
    except Exception as e:
        return jsonify({'exito': False, 'mensaje': str(e)})

@app.route('/api/tunnel/url', methods=['GET'])
def tunnel_url():
    global _tunnel_proc, _tunnel_url
    if _tunnel_url:
        return jsonify({'url': _tunnel_url, 'listo': True})
    if _tunnel_proc is None or _tunnel_proc.poll() is not None:
        return jsonify({'url': '', 'listo': False, 'mensaje': 'Tunnel no activo'})
    logfile = str(PROJECT_ROOT / "tunnel" / "tunnel.log")
    if os.path.exists(logfile):
        try:
            with open(logfile, 'r') as f:
                content = f.read()
            m = re.search(r'https://[a-z0-9.-]+\.trycloudflare\.com', content)
            if m:
                _tunnel_url = m.group()
                return jsonify({'url': _tunnel_url, 'listo': True})
        except Exception:
            pass
    return jsonify({'url': '', 'listo': False, 'mensaje': 'Esperando URL...'})

@app.route('/api/tunnel/stop', methods=['POST'])
def tunnel_stop():
    global _tunnel_proc
    if _tunnel_proc and _tunnel_proc.poll() is None:
        _tunnel_proc.terminate()
        _tunnel_proc.wait(timeout=5)
        _tunnel_proc = None
        return jsonify({'exito': True, 'mensaje': 'Tunnel detenido'})
    return jsonify({'exito': True, 'mensaje': 'No hay tunnel activo'})

@app.route('/api/tunnel/status', methods=['GET'])
def tunnel_status():
    global _tunnel_proc, _tunnel_url
    activo = _tunnel_proc is not None and _tunnel_proc.poll() is None
    return jsonify({'activo': activo, 'url': _tunnel_url if activo else ''})

# ---------- Filesystem (native dialogs) ----------
@app.route('/api/fs/select-folder', methods=['POST'])
def fs_select_folder():
    """Abre el dialogo nativo del SO en un proceso separado."""
    try:
        code = (
            "import tkinter as tk; from tkinter import filedialog; "
            "root = tk.Tk(); root.withdraw(); root.attributes('-topmost', True); "
            "path = filedialog.askdirectory(title='Seleccionar carpeta de atenciones'); "
            "root.destroy(); print(path, end='')"
        )
        result = subprocess.run(
            [sys.executable, '-c', code],
            capture_output=True, text=True, timeout=120
        )
        carpeta = result.stdout.strip()
        if carpeta:
            return jsonify({'path': carpeta})
        return jsonify({'path': ''})
    except subprocess.TimeoutExpired:
        return jsonify({'path': '', 'error': 'timeout'}), 408
    except Exception as e:
        return jsonify({'path': '', 'error': str(e)}), 500

# ---------- Main ----------
if __name__ == '__main__':
    debug_mode = os.environ.get('FLASK_DEBUG', '0') == '1'
    app.run(host='0.0.0.0', port=5000, debug=debug_mode, threaded=True)
