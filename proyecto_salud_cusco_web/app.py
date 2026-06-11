import sys
import os
import json
import threading
import subprocess
import time
from pathlib import Path
from flask import Flask, render_template, request, jsonify, session
from flask_cors import CORS
from config import (
    BASE_DIR, PROJECT_ROOT, SCRIPTS_INGESTA, SCRIPTS_BI,
    SCRIPTS_MANTENIMIENTO, SCRIPTS_INSTALACION, SCRIPTS_SQL_REPORTES,
    SCRIPTS_SQL_VACUNAS, BOTONES_REPORTE_PREDETERMINADOS,
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

            proc = subprocess.Popen(
                comando,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding='utf-8',
                errors='replace'
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
        sys.path.insert(0, str(SCRIPTS_INSTALACION))
        from instalar_postgresql import iniciar_servicio_postgresql, esperar_servicio_activo
        exito, mensaje = iniciar_servicio_postgresql()
        if exito:
            esperar_servicio_activo(timeout=30)
        return jsonify({'exito': exito, 'mensaje': mensaje})
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
@app.route('/api/ingesta/import', methods=['POST'])
def ingesta_import():
    data = request.json
    anio = data.get('anio', '2024')
    meses = data.get('meses', [])
    ruta_crudos = data.get('ruta_crudos', '')

    if not meses or len(meses) == 12:
        script = str(SCRIPTS_INGESTA / '01cargacvs_universal.py')
        args = [anio]
    else:
        script = str(SCRIPTS_INGESTA / '01cargacvs_mensual.py')
        args = [anio] + [str(m) for m in meses]

    env = os.environ.copy()
    if ruta_crudos:
        env['RUTA_CRUDOS'] = ruta_crudos

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
    ruta = str(PROJECT_ROOT / script)
    return jsonify(ejecutar_script(ruta, mostrar_progreso=True))

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

# ---------- Main ----------
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)
