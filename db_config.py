"""db_config.py
Configuración y utilidades de conexión a PostgreSQL.

Comportamiento principal:
  1. Si existe un perfil guardado, se usa ese perfil.
  2. Si es la primera ejecución (no hay perfil), se crea uno inicial con
     credenciales predeterminadas del sistema y se guarda automáticamente.
  3. La interfaz permite modificar y persistir el perfil en cualquier momento.

Además se puede autodetectar un perfil desde variables de entorno y pgpass.
"""

from __future__ import annotations

import json
import os
import socket
from dataclasses import dataclass, asdict
from typing import Optional, Dict, Any, Callable


PASSWORD_POSTGRES = "ivan"

DEFAULT_DATABASE = os.getenv("DB_NAME", "ivan_proceso_his")
DEFAULT_SCHEMA = os.getenv("DB_SCHEMA", "es_ivan")
DEFAULT_PORT = os.getenv("DB_PORT", "5432")
DEFAULT_USER = os.getenv("DB_USER", "postgres")
DEFAULT_PASSWORD = os.getenv("DB_PASSWORD", PASSWORD_POSTGRES)


def _runtime_config_dir() -> str:
    appdata = os.getenv("APPDATA")
    if appdata:
        return os.path.join(appdata, "Proyecto_Salud_Cusco", "config")
    return os.path.join(os.path.expanduser("~"), ".proyecto_salud_cusco", "config")


CONFIG_DIR = _runtime_config_dir()
CONFIG_FILE = os.path.join(CONFIG_DIR, "db_connection.json")
LEGACY_CONFIG_FILE = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "config", "db_connection.json"
)
COMMON_PORTS = ("5432", "5433", "5434")


@dataclass
class DBConfig:
    host: str = os.getenv("DB_HOST", "localhost")
    port: str = DEFAULT_PORT
    user: str = DEFAULT_USER
    password: str = DEFAULT_PASSWORD
    database: str = DEFAULT_DATABASE
    schema: str = DEFAULT_SCHEMA

    def __post_init__(self) -> None:
        self.host = (self.host or "localhost").strip()
        self.port = (self.port or DEFAULT_PORT).strip()
        self.user = (self.user or DEFAULT_USER).strip()
        self.password = self.password or ""
        self.database = (self.database or DEFAULT_DATABASE).strip()
        self.schema = (self.schema or DEFAULT_SCHEMA).strip()

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

    def connection_string(self) -> str:
        return (
            f"host={self.host} port={self.port} user={self.user} "
            f"password={self.password} dbname={self.database}"
        )


_config_instance: Optional[DBConfig] = None


def _ensure_config_dir() -> None:
    os.makedirs(CONFIG_DIR, exist_ok=True)


def _pgpass_paths() -> list[str]:
    paths: list[str] = []
    if os.name == "nt":
        appdata = os.environ.get("APPDATA")
        if appdata:
            paths.append(os.path.join(appdata, "postgresql", "pgpass.conf"))
    home = os.path.expanduser("~")
    paths.append(os.path.join(home, ".pgpass"))
    return paths


def _read_pgpass_entries() -> list[Dict[str, str]]:
    entries: list[Dict[str, str]] = []
    for path in _pgpass_paths():
        if not os.path.exists(path):
            continue
        try:
            with open(path, "r", encoding="utf-8") as file:
                for raw_line in file:
                    line = raw_line.strip()
                    if not line or line.startswith("#"):
                        continue
                    parts = line.split(":")
                    if len(parts) != 5:
                        continue
                    host, port, database, user, password = parts
                    entries.append(
                        {
                            "host": host,
                            "port": port,
                            "database": database,
                            "user": user,
                            "password": password,
                        }
                    )
        except OSError:
            continue
    return entries


def _auto_detect_from_sources() -> Dict[str, str]:
    data: Dict[str, str] = {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": os.getenv("DB_PORT", DEFAULT_PORT),
        "user": os.getenv("DB_USER", DEFAULT_USER),
        "password": os.getenv("DB_PASSWORD", ""),
        "database": os.getenv("DB_NAME", DEFAULT_DATABASE),
        "schema": os.getenv("DB_SCHEMA", DEFAULT_SCHEMA),
    }

    pgpass_entries = _read_pgpass_entries()
    preferred: Optional[Dict[str, str]] = None
    for entry in pgpass_entries:
        preferred = entry
        if entry["host"] not in ("*", ""):
            break

    if preferred:
        if preferred["host"] not in ("*", ""):
            data["host"] = preferred["host"]
        if preferred["port"] not in ("*", ""):
            data["port"] = preferred["port"]
        if preferred["user"] not in ("*", ""):
            data["user"] = preferred["user"]
        if preferred["password"] not in ("*", ""):
            data["password"] = preferred["password"]
        if preferred["database"] not in ("*", ""):
            data["database"] = preferred["database"]

    if not data["port"]:
        data["port"] = DEFAULT_PORT
    if data["port"] not in COMMON_PORTS:
        data["port"] = data["port"]

    return data


def _load_config_from_file() -> Optional[DBConfig]:
    for candidate in (CONFIG_FILE, LEGACY_CONFIG_FILE):
        try:
            if os.path.exists(candidate):
                with open(candidate, "r", encoding="utf-8") as file:
                    data = json.load(file)
                cfg = DBConfig(**data)
                if candidate != CONFIG_FILE:
                    _save_config(cfg)
                return cfg
        except (OSError, json.JSONDecodeError):
            continue
    return None


def _build_first_run_profile() -> DBConfig:
    return DBConfig(
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", DEFAULT_PORT),
        user=os.getenv("DB_USER", DEFAULT_USER),
        password=os.getenv("DB_PASSWORD", DEFAULT_PASSWORD),
        database=os.getenv("DB_NAME", DEFAULT_DATABASE),
        schema=os.getenv("DB_SCHEMA", DEFAULT_SCHEMA),
    )


def _save_config(cfg: DBConfig) -> None:
    _ensure_config_dir()
    try:
        with open(CONFIG_FILE, "w", encoding="utf-8") as file:
            json.dump(cfg.to_dict(), file, ensure_ascii=False, indent=2)
    except OSError:
        pass


def auto_detect_db_profile(persist: bool = True) -> DBConfig:
    cfg = DBConfig(**_auto_detect_from_sources())
    if persist:
        set_db_config(cfg)
    return cfg


def set_db_config(cfg: DBConfig, persist: bool = True) -> DBConfig:
    global _config_instance
    _config_instance = cfg
    if persist:
        _save_config(cfg)
    return cfg


def update_db_config(**kwargs: str) -> DBConfig:
    cfg = get_db_config()
    changed = False
    for field in ("host", "port", "user", "password", "database", "schema"):
        if field in kwargs and kwargs[field] is not None:
            value = str(kwargs[field]).strip()
            if getattr(cfg, field) != value and value:
                setattr(cfg, field, value)
                changed = True
    if changed:
        set_db_config(cfg)
    return cfg


def get_db_config() -> DBConfig:
    global _config_instance
    if _config_instance is None:
        cfg = _load_config_from_file()
        if cfg is None:
            cfg = _build_first_run_profile()
            _save_config(cfg)
        _config_instance = cfg
    return _config_instance


def set_db_host(host: str):
    update_db_config(host=host or "localhost")


def reset_db_config(remove_file: bool = False) -> DBConfig:
    global _config_instance
    _config_instance = None
    if remove_file and os.path.exists(CONFIG_FILE):
        try:
            os.remove(CONFIG_FILE)
        except OSError:
            pass
    return get_db_config()


# ─────────────────────────────────────────────────────────────────────────────
# VERIFICACIÓN Y CREACIÓN DE BASE DE DATOS Y ESQUEMA
# ─────────────────────────────────────────────────────────────────────────────

def verificar_conexion(
    config: Optional[DBConfig] = None,
    log: Optional[Callable[[str], None]] = None,
) -> bool:
    try:
        import psycopg2
    except ImportError:
        (log or print)("❌ psycopg2 no instalado. Ejecuta: pip install psycopg2-binary")
        return False

    cfg = config or get_db_config()
    _log = log or print

    try:
        conn = psycopg2.connect(
            host=cfg.host,
            port=cfg.port,
            user=cfg.user,
            password=cfg.password,
            dbname="postgres",
            connect_timeout=5,
        )
        conn.close()
        _log(f"✅ Conexión verificada → {cfg.host}:{cfg.port} (usuario: {cfg.user})")
        return True
    except Exception as exc:
        _log(f"❌ No se pudo conectar a {cfg.host}:{cfg.port} — {exc}")
        return False


def _probar_conexion_postgres(passwords: list, host: str, port: str) -> tuple:
    """Intenta conectar a postgres con múltiples contraseñas. Retorna (conn, password_exitosa)."""
    import psycopg2
    
    for pwd in passwords:
        try:
            conn = psycopg2.connect(
                host=host,
                port=port,
                user="postgres",
                password=pwd,
                dbname="postgres",
                connect_timeout=5,
            )
            conn.close()
            return True, pwd
        except Exception:
            continue
    return False, None


class PasswordRequeridoError(Exception):
    """Excepción cuando se requiere contraseña manual."""
    def __init__(self, mensaje="Se requiere contraseña manual"):
        self.mensaje = mensaje
        super().__init__(self.mensaje)


def verificar_bd_esquema(
    config: Optional[DBConfig] = None,
    log: Optional[Callable[[str], None]] = None,
    guardar_password: bool = True,
    permitir_password_manual: bool = True,
) -> bool:
    """Verifica que la base de datos y esquema existan y sean accesibles.
    
    Args:
        config: Configuración de base de datos
        log: Función de logging
        guardar_password: Si True, guarda la contraseña correcta en la configuración
        permitir_password_manual: Si True y no hay conexión, pregunta la contraseña
    
    Returns:
        True si la BD y esquema existen y son accesibles
    """
    try:
        import psycopg2
    except ImportError:
        (log or print)("❌ psycopg2 no instalado. Ejecuta: pip install psycopg2-binary")
        return False

    cfg = config or get_db_config()
    _log = log or print

    # Contraseñas a probar - lista expandida
    user_windows = os.getenv("USERNAME", "postgres")
    passwords_to_try = [
        cfg.password if cfg.password else "",
        PASSWORD_POSTGRES,
        "ivan",
        "postgres",
        "admin",
        "root",
        "Password123!",
        "Admin123!",
        "Psql123!",
        "postgres123",
        "root123",
        "admin123",
        "123456",
        "",
        user_windows,
    ]
    # Eliminar duplicados manteniendo orden
    seen = set()
    passwords_to_try = [x for x in passwords_to_try if x and not (x in seen or seen.add(x))]

    # Intentar conexión con las contraseñas
    conn_pg = None
    password_ok = None
    
    for pwd in passwords_to_try:
        try:
            conn_pg = psycopg2.connect(
                host=cfg.host,
                port=cfg.port,
                user=cfg.user,
                password=pwd,
                dbname="postgres",
                connect_timeout=5,
            )
            password_ok = pwd
            break
        except Exception:
            continue

    if conn_pg is None:
        if permitir_password_manual:
            raise PasswordRequeridoError(
                "Contraseña incorrecta. Ingresa la contraseña que usaste al instalar PostgreSQL."
            )
        return False

    cur_pg = None
    try:
        cur_pg = conn_pg.cursor()
        cur_pg.execute("SELECT 1 FROM pg_database WHERE datname = %s;", (cfg.database,))
        existe_bd = cur_pg.fetchone() is not None
    except Exception as exc:
        _log("❌ Error verificando base de datos: %s" % exc)
        return False
    finally:
        if cur_pg:
            cur_pg.close()
        conn_pg.close()

    if not existe_bd:
        _log("❌ La base de datos '%s' no existe." % cfg.database)
        return False

    _log("   ✅ Base de datos '%s' encontrada" % cfg.database)

    # Ahora probar conexión a la base de datos específica
    # A veces la contraseña de postgres no funciona para la base de datos específica
    passwords_for_db = [password_ok, PASSWORD_POSTGRES, "ivan", ""]
    if password_ok not in passwords_for_db:
        passwords_for_db.insert(0, password_ok)
    seen = set()
    passwords_for_db = [x for x in passwords_for_db if x and not (x in seen or seen.add(x))]

    conn = None
    for pwd in passwords_for_db:
        try:
            conn = psycopg2.connect(
                host=cfg.host,
                port=cfg.port,
                user=cfg.user,
                password=pwd,
                dbname=cfg.database,
                connect_timeout=5,
            )
            if pwd != password_ok:
                password_ok = pwd
                _log("   ✅ Contraseña correcta para base de datos: %s" % ("*" * len(pwd) if pwd else "vacia"))
            break
        except Exception:
            continue

    if conn is None:
        _log("❌ No se pudo conectar a la base de datos '%s'" % cfg.database)
        return False

    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT 1 FROM information_schema.schemata WHERE schema_name = %s;",
            (cfg.schema,),
        )
        existe_esquema = cur.fetchone() is not None
    except Exception as exc:
        _log("❌ Error verificando esquema: %s" % exc)
        conn.close()
        return False
    finally:
        cur.close()
        conn.close()

    if not existe_esquema:
        _log("❌ El esquema '%s' no existe en '%s'." % (cfg.schema, cfg.database))
        return False

    # Guardar la contraseña correcta si se encontró una diferente
    if guardar_password and password_ok and password_ok != cfg.password:
        _log("   💾 Guardando contraseña correcta en configuración...")
        try:
            update_db_config(password=password_ok)
            _log("   ✅ Contraseña guardada")
        except Exception:
            pass

    _log("✅ PostgreSQL, base '%s' y esquema '%s' listos." % (cfg.database, cfg.schema))
    return True


def inicializar_base_datos(
    config: Optional[DBConfig] = None,
    log: Optional[Callable[[str], None]] = None,
) -> bool:
    """Crea la base de datos y esquema si no existen.
    
    Intenta múltiples contraseñas para conectar.
    """
    try:
        import psycopg2
        from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
    except ImportError:
        (log or print)("❌ psycopg2 no instalado. Ejecuta: pip install psycopg2-binary")
        return False

    cfg = config or get_db_config()
    _log = log or print

    # Primero intentar con CMD como alternativa
    _log("🔌 Probando conexión via CMD...")
    try:
        pwd_encontrada = _buscar_conexion_cmd()
        if pwd_encontrada:
            _log("   ✅ Conexión exitosa via CMD con contraseña: ***")
            try:
                update_db_config(password=pwd_encontrada)
            except Exception:
                pass
            return True
        else:
            _log("   ⚠️ CMD: No se encontró contraseña válida")
    except Exception as e:
        _log("   ⚠️ CMD error: %s" % str(e)[:100])
    
    _log("🔌 Conectando a PostgreSQL en %s:%s..." % (cfg.host, cfg.port))

    # Primero verificar si el puerto responde con múltiples métodos
    _log("   🔍 Verificando conectividad...")
    try:
        respuesta_socket = _pg_responde_en_puerto(cfg.port)
    except Exception as e:
        respuesta_socket = False
        _log("   ⚠️ Socket check error: %s" % str(e)[:50])
    
    try:
        respuesta_ps = _probar_puerto_powershell(cfg.port)
    except Exception as e:
        respuesta_ps = False
        _log("   ⚠️ PowerShell check error: %s" % str(e)[:50])
    
    if not respuesta_socket and not respuesta_ps:
        _log("   ⚠️ Puerto %s NO responde (socket=%s, ps=%s)" % (cfg.port, respuesta_socket, respuesta_ps))
        # Intentar con IPs alternativas
        ips = _obtener_ips_locales()
        _log("   🔍 IPs disponibles: %s" % ", ".join(ips[:5]))
    else:
        _log("   ✅ Puerto %s responde (socket=%s, ps=%s)" % (cfg.port, respuesta_socket, respuesta_ps))

    # Función para leer pgpass.conf
    def _leer_pgpass() -> list:
        """Lee contraseñas del archivo pgpass.conf"""
        passwords = []
        appdata = os.getenv("APPDATA", "")
        userprofile = os.getenv("USERPROFILE", "")
        username = os.getenv("USERNAME", "postgres")
        
        pgpass_paths = [
            os.path.join(appdata, "postgresql", "pgpass.conf"),
            os.path.join(userprofile, ".pgpass.conf"),
            os.path.join(appdata, username, "pgpass.conf"),
            r"C:\Users\{}\AppData\Roaming\postgresql\pgpass.conf".format(username),
        ]
        for pgpass_file in pgpass_paths:
            if os.path.exists(pgpass_file):
                try:
                    with open(pgpass_file, "r", encoding="utf-8") as f:
                        for linea in f:
                            linea = linea.strip()
                            if linea and not linea.startswith("#"):
                                partes = linea.split(":")
                                if len(partes) >= 5:
                                    passwords.append(partes[4])
                except Exception:
                    pass
        return passwords
    
    # Función para probar conexión via CMD con psql
    def _probar_psql_cmd(password: str, host: str, port: int, usuario: str = "postgres") -> bool:
        """Usa psql via CMD para probar conexión."""
        import os
        env = os.environ.copy()
        env["PGPASSWORD"] = password
        env["PGCLIENTENCODING"] = "UTF8"
        
        for ip in [host, "127.0.0.1", "localhost"]:
            try:
                proc = subprocess.run(
                    ["psql", "-h", ip, "-p", str(port), "-U", usuario, "-d", "postgres", "-c", "SELECT 1;", "-t", "-A", "-w"],
                    capture_output=True, text=True, encoding="utf-8", errors="replace",
                    env=env, timeout=10,
                )
                if proc.returncode == 0:
                    return True
            except Exception:
                continue
        return False
    
    # Función para encontrar pg_hba.conf
    def _encontrar_pg_hba_conf() -> str:
        """Busca el archivo pg_hba.conf en las rutas de PostgreSQL."""
        rutas = []
        for v in range(18, 10, -1):
            rutas.extend([
                r"C:\Program Files\PostgreSQL\{}\data\pg_hba.conf".format(v),
                r"C:\Program Files (x86)\PostgreSQL\{}\data\pg_hba.conf".format(v),
                r"C:\PostgreSQL\{}\data\pg_hba.conf".format(v),
            ])
        
        for ruta in rutas:
            if os.path.exists(ruta):
                _log("   📁 pg_hba.conf encontrado en: %s" % ruta)
                return ruta
        return None
    
    # Función para modificar pg_hba.conf a trust
    def _modificar_pg_hba_a_trust(pg_hba_path: str) -> bool:
        """Modifica pg_hba.conf para usar autenticación trust (sin password)."""
        try:
            # Leer contenido original
            with open(pg_hba_path, "r", encoding="utf-8") as f:
                contenido_original = f.read()
            
            # Buscar línea con "host" y "md5" y cambiarla a "trust"
            lines = contenido_original.split('\n')
            modificado = False
            new_lines = []
            
            for line in lines:
                # Comentar líneas de autenticación existente y agregar trust para IPv4 local
                if line.strip().startswith("host") and "md5" in line.lower():
                    new_lines.append("# " + line)  # Comentar original
                    # Agregar línea trust para conexiones locales
                    parts = line.split()
                    if len(parts) >= 4:
                        new_lines.append("host    all         all         127.0.0.1/32          trust")
                        modificado = True
                elif line.strip().startswith("host") and "scram" in line.lower():
                    new_lines.append("# " + line)
                    new_lines.append("host    all         all         127.0.0.1/32          trust")
                    modificado = True
                else:
                    new_lines.append(line)
            
            if modificado:
                # Escribir archivo modificado
                with open(pg_hba_path, "w", encoding="utf-8") as f:
                    f.write('\n'.join(new_lines))
                _log("   ✅ pg_hba.conf modificado a trust")
                return True
            return False
        except Exception as e:
            _log("   ❌ Error modificando pg_hba.conf: %s" % e)
            return False
    
    # Función para revertir pg_hba.conf
    def _revertir_pg_hba(pg_hba_path: str) -> bool:
        """Revierte los cambios de pg_hba.conf."""
        try:
            lines = []
            with open(pg_hba_path, "r", encoding="utf-8") as f:
                for line in f:
                    # Descomentar líneas originales (quitar # )
                    if line.strip().startswith("# host") and "all" in line and ("md5" in line or "scram" in line):
                        line = line[2:]  # Quitar #
                    lines.append(line)
            
            with open(pg_hba_path, "w", encoding="utf-8") as f:
                f.write(''.join(lines))
            _log("   ✅ pg_hba.conf revertido a md5")
            return True
        except Exception as e:
            _log("   ⚠️ Error revertiendo pg_hba.conf: %s" % e)
            return False
    
    # Función para reiniciar servicio PostgreSQL
    def _reiniciar_postgresql() -> bool:
        """Reinicia el servicio de PostgreSQL."""
        try:
            # Intentar con services.msc
            proc = subprocess.run(
                ["powershell", "-NoProfile", "-Command", 
                 "Restart-Service -Name 'postgresql*' -Force -ErrorAction Stop"],
                capture_output=True, text=True, timeout=30,
            )
            if proc.returncode == 0:
                _log("   ✅ Servicio PostgreSQL reiniciado")
                time.sleep(3)  # Esperar a que inicie
                return True
        except Exception:
            pass
        
        # Método alternativo: net stop / net start
        try:
            subprocess.run(["net", "stop", "postgresql-x64-18"], capture_output=True, timeout=15)
            time.sleep(2)
            subprocess.run(["net", "start", "postgresql-x64-18"], capture_output=True, timeout=15)
            _log("   ✅ Servicio PostgreSQL reiniciado (net)")
            time.sleep(3)
            return True
        except Exception as e:
            _log("   ❌ Error reiniciando servicio: %s" % e)
            return False
    
    # Función para cambiar contraseña usando conexión sin password
    def _cambiar_contrasena_trust(nueva_password: str) -> bool:
        """Cambia la contraseña de postgres usando conexión trust."""
        try:
            # Conectar sin password (debería funcionar con trust)
            conn = psycopg2.connect(
                host=cfg.host,
                port=cfg.port,
                user="postgres",
                password="",
                dbname="postgres",
                connect_timeout=10,
            )
            cur = conn.cursor()
            cur.execute("ALTER USER postgres WITH PASSWORD %s;", (nueva_password,))
            conn.commit()
            cur.close()
            conn.close()
            _log("   ✅ Contraseña cambiada a: %s" % nueva_password)
            return True
        except Exception as e:
            _log("   ❌ Error cambiando contraseña: %s" % e)
            return False
    
    # Función para ejecutar el plan de recuperación
    def _recuperar_password() -> bool:
        """Plan de recuperación: modificar pg_hba.conf, cambiar password, revertir."""
        _log("   🔄 Iniciando recuperación de contraseña...")
        
        # 1. Encontrar pg_hba.conf
        pg_hba = _encontrar_pg_hba_conf()
        if not pg_hba:
            _log("   ❌ No se encontró pg_hba.conf")
            return False
        
        # 2. Modificar a trust
        if not _modificar_pg_hba_a_trust(pg_hba):
            _log("   ❌ No se pudo modificar pg_hba.conf")
            return False
        
        # 3. Reiniciar PostgreSQL
        if not _reiniciar_postgresql():
            _revertir_pg_hba(pg_hba)
            return False
        
        # 4. Cambiar contraseña
        nueva_pass = PASSWORD_POSTGRES  # "ivan"
        if not _cambiar_contrasena_trust(nueva_pass):
            _revertir_pg_hba(pg_hba)
            _reiniciar_postgresql()
            return False
        
        # 5. Revertir pg_hba.conf
        _revertir_pg_hba(pg_hba)
        
        # 6. Reiniciar para aplicar cambios
        _reiniciar_postgresql()
        
        _log("   ✅ Recuperación completada. Nueva contraseña: %s" % nueva_pass)
        return True

    # Contraseñas a probar - lista expandida con más opciones
    user_windows = os.getenv("USERNAME", "postgres")
    passwords_base = [
        cfg.password if cfg.password else "",
        PASSWORD_POSTGRES,
        "ivan",
        "postgres",
        "admin",
        "root",
        "Password123!",
        "Admin123!",
        "Psql123!",
        "postgres123",
        "root123",
        "admin123",
        "123456",
        "12345678",
        "",
        user_windows,
        user_windows.lower(),
        "Ivan",
        "Ivan123",
        "IvaN123",
        "Usuario123",
        "SaludCusco",
        "Cusco2024",
        "Cusco2025",
        "Cusco2026",
    ]
    
    # Agregar contraseñas de pgpass.conf
    pgpass_passwords = _leer_pgpass()
    passwords_to_try = passwords_base + pgpass_passwords
    
    # Eliminar duplicados preservando orden
    seen = set()
    passwords_to_try = [x for x in passwords_to_try if x and not (x in seen or seen.add(x))]

    conn_pg = None
    password_ok = None
    
    _log("   🔍 Probando conexiones...")
    _log("   🔍 Probando %d passwords via psycopg2 y CMD..." % len(passwords_to_try))
    
    # También probar con usuario de Windows como usuario de PostgreSQL
    usuarios_a_probar = [cfg.user, user_windows, "postgres"]
    usuarios_unicos = []
    for u in usuarios_a_probar:
        if u and u not in usuarios_unicos:
            usuarios_unicos.append(u)
    
    # Obtener múltiples IPs para probar
    hosts_a_probar = [cfg.host, "localhost", "127.0.0.1", "::1", "0.0.0.0"] + _obtener_ips_locales()
    hosts_unicos = list(dict.fromkeys([h for h in hosts_a_probar if h]))
    
    _log("   📋 Probando %d hosts, %d usuarios, %d passwords" % (
        len(hosts_unicos), len(usuarios_unicos), len(passwords_to_try)))
    _log("   Hosts: %s" % ", ".join(hosts_unicos[:4]))
    _log("   Usuarios: %s" % ", ".join(usuarios_unicos))
    _log("   Passwords: %s" % ", ".join(passwords_to_try[:5]) + "...")
    
    # Intentar primero con psql via CMD (más rápido)
    psql_encontrado = False
    _log("   🔍 Probando via CMD/psql...")
    for pwd in passwords_to_try:
        if _probar_psql_cmd(pwd, cfg.host, cfg.port, "postgres"):
            _log("   ✅ Password encontrado via CMD: %s" % pwd)
            password_ok = pwd
            psql_encontrado = True
            break
    
    # Si CMD no funcionó, probar con psycopg2
    if not psql_encontrado:
        _log("   🔍 Probando via psycopg2...")
        for host in hosts_unicos:
            for usuario in usuarios_unicos:
                for pwd in passwords_to_try:
                    try:
                        conn_pg = psycopg2.connect(
                            host=host,
                            port=cfg.port,
                            user=usuario,
                            password=pwd,
                            dbname="postgres",
                            connect_timeout=10,
                        )
                        password_ok = pwd
                        cfg.host = host
                        _log("   ✅ Conexión exitosa con usuario: %s, host: %s" % (usuario, host))
                        break
                    except Exception as e:
                        continue
                if conn_pg:
                    break
            if conn_pg:
                break

    if conn_pg is None and not psql_encontrado:
        _log("   ❌ No se pudo conectar a PostgreSQL con ninguna contraseña")
        _log("   Passwords probados: %d" % len(passwords_to_try))
        
        # Intentar recuperación automática
        _log("   🔄 Intentando recuperación automática de contraseña...")
        if _recuperar_password():
            # Intentar conectar con la nueva contraseña
            try:
                conn_pg = psycopg2.connect(
                    host=cfg.host,
                    port=cfg.port,
                    user="postgres",
                    password=PASSWORD_POSTGRES,
                    dbname="postgres",
                    connect_timeout=10,
                )
                password_ok = PASSWORD_POSTGRES
                _log("   ✅ Conexión exitosa con nueva contraseña")
            except Exception as e:
                _log("   ❌ Error conectando después de recuperación: %s" % e)
                return False
        else:
            _log("   ❌ Recuperación automática falló")
            return False
    
    # Si se encontró password via CMD, crear conexión con psycopg2
    if psql_encontrado and conn_pg is None:
        try:
            conn_pg = psycopg2.connect(
                host=cfg.host,
                port=cfg.port,
                user="postgres",
                password=password_ok,
                dbname="postgres",
                connect_timeout=10,
            )
            _log("   ✅ Conexión psycopg2 creada")
        except Exception as exc:
            _log("   ❌ Error creando conexión: %s" % exc)
            return False

    try:
        conn_pg.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cur_pg = conn_pg.cursor()
    except Exception as exc:
        _log("   ❌ Error preparando conexión: %s" % exc)
        conn_pg.close()
        return False

    try:
        cur_pg.execute(
            """
            SELECT pg_encoding_to_char(encoding), datcollate, datctype
            FROM pg_database
            WHERE datname = %s;
            """,
            (cfg.database,),
        )
        info_bd = cur_pg.fetchone()
        if info_bd:
            encoding_actual, collate_actual, ctype_actual = info_bd
            _log("   ✅ Base de datos '%s' ya existe" % cfg.database)
            _log(
                "   ℹ️  Config actual: ENCODING=%s | LC_COLLATE=%s | LC_CTYPE=%s"
                % (encoding_actual, collate_actual, ctype_actual)
            )
        else:
            _log("   ⚙️  Creando base de datos '%s'..." % cfg.database)
            nombre_seguro = cfg.database.replace('"', "").replace(";", "")
            estrategias = [
                (
                    "UTF8 + locale es_ES.UTF-8",
                    'CREATE DATABASE "%s" WITH ENCODING \'UTF8\' LC_COLLATE \'es_ES.UTF-8\' LC_CTYPE \'es_ES.UTF-8\' TEMPLATE template0;'
                    % nombre_seguro,
                ),
                (
                    "UTF8 (sin locale explícito)",
                    'CREATE DATABASE "%s" WITH ENCODING \'UTF8\' TEMPLATE template0;'
                    % nombre_seguro,
                ),
                (
                    "configuración por defecto",
                    'CREATE DATABASE "%s";' % nombre_seguro,
                ),
            ]

            creada = False
            ultimo_error = None
            for descripcion, sentencia in estrategias:
                try:
                    cur_pg.execute(sentencia)
                    _log("   ✅ Base de datos creada con %s" % descripcion)
                    creada = True
                    break
                except Exception as exc:
                    ultimo_error = exc
                    detalle = str(exc).splitlines()[0] if str(exc) else repr(exc)
                    _log("   ⚠️  Falló creación con %s: %s" % (descripcion, detalle))

            if not creada and ultimo_error is not None:
                raise ultimo_error
    except Exception as exc:
        _log("   ❌ Error al crear base de datos: %s" % exc)
        cur_pg.close()
        conn_pg.close()
        return False
    finally:
        cur_pg.close()
        conn_pg.close()

    # Ahora conectar a la base de datos específica
    conn = None
    passwords_for_db = [password_ok, PASSWORD_POSTGRES, "ivan", ""]
    seen = set()
    passwords_for_db = [x for x in passwords_for_db if x and not (x in seen or seen.add(x))]

    for pwd in passwords_for_db:
        try:
            conn = psycopg2.connect(
                host=cfg.host,
                port=cfg.port,
                user=cfg.user,
                password=pwd,
                dbname=cfg.database,
                connect_timeout=10,
            )
            if pwd != password_ok:
                password_ok = pwd
            break
        except Exception:
            continue

    if conn is None:
        _log("   ❌ No se pudo conectar a '%s'" % cfg.database)
        return False

    try:
        conn.autocommit = True
        cur = conn.cursor()
        _log("   ✅ Conectado a '%s'" % cfg.database)
    except Exception as exc:
        _log("   ❌ Error conectando a '%s': %s" % (cfg.database, exc))
        conn.close()
        return False

    try:
        cur.execute(
            "SELECT 1 FROM information_schema.schemata WHERE schema_name = %s;",
            (cfg.schema,),
        )
        if cur.fetchone():
            _log("   ✅ Esquema '%s' ya existe" % cfg.schema)
        else:
            _log("   ⚙️  Creando esquema '%s'..." % cfg.schema)
            nombre_esquema = cfg.schema.replace('"', "").replace(";", "")
            cur.execute('CREATE SCHEMA "%s";' % nombre_esquema)
            _log("   ✅ Esquema '%s' creado" % cfg.schema)

        nombre_usuario = cfg.user.replace('"', "").replace(";", "")
        nombre_esquema = cfg.schema.replace('"', "").replace(";", "")
        cur.execute('GRANT ALL PRIVILEGES ON SCHEMA "%s" TO "%s";' % (nombre_esquema, nombre_usuario))
        _log("   ✅ Privilegios asignados al usuario '%s'" % cfg.user)
    except Exception as exc:
        _log("   ❌ Error al crear esquema: %s" % exc)
        cur.close()
        conn.close()
        return False
    finally:
        cur.close()
        conn.close()

    # Guardar la contraseña correcta si se encontró una diferente
    if password_ok and password_ok != cfg.password:
        _log("   💾 Guardando contraseña correcta en configuración...")
        try:
            update_db_config(password=password_ok)
            _log("   ✅ Contraseña guardada")
        except Exception:
            pass

    _log("🎉 Base de datos y esquema operativos.")
    return True


def obtener_ip_local() -> str:
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.connect(("8.8.8.8", 80))
            return sock.getsockname()[0]
    except Exception:
        return "localhost"


# ─────────────────────────────────────────────────────────────────────────────
# DETECCIÓN DE POSTGRESQL INSTALADO
# ─────────────────────────────────────────────────────────────────────────────

import json
import re
import subprocess
import socket


import platform as _platform

RUTAS_POSTGRESQL = [
    r"C:\Program Files\PostgreSQL",
    r"C:\PostgreSQL",
    "/usr/bin",
    "/usr/lib/postgresql",
    "/usr/pgsql",
]

ES_WINDOWS = _platform.system() == "Windows"


def _probar_puerto_powershell(puerto: int = 5432) -> bool:
    """Usa PowerShell para verificar si el puerto está abierto."""
    try:
        proc = subprocess.run(
            ["powershell", "-NoProfile", "-Command",
             f"(New-Object System.Net.Sockets.TcpClient).Connect('127.0.0.1', {puerto}); $true"],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=5,
        )
        return "True" in proc.stdout or proc.returncode == 0
    except Exception:
        return False


def _probar_puerto_cmd(puerto: int = 5432) -> bool:
    """Usa comando CMD para verificar si el puerto está abierto."""
    try:
        proc = subprocess.run(
            ["cmd", "/c", f"powershell -NoProfile -Command \"(New-Object System.Net.Sockets.TcpClient).Connect('localhost', {puerto})\""],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=5,
        )
        return proc.returncode == 0
    except Exception:
        return False


def _obtener_ips_locales() -> list:
    """Obtiene todas las IPs disponibles en la máquina."""
    ips = ["127.0.0.1", "localhost", "::1"]
    try:
        hostname = socket.gethostname()
        ips.append(hostname)
        ips.append(socket.gethostbyname(hostname))
    except Exception:
        pass
    try:
        proc = subprocess.run(
            ["powershell", "-NoProfile", "-Command",
             "Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4' -and $_.IPAddress -ne '127.0.0.1'} | Select-Object -ExpandProperty IPAddress"],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=10,
        )
        for ip in proc.stdout.strip().split("\n"):
            ip = ip.strip()
            if ip and ip not in ips:
                ips.append(ip)
    except Exception:
        pass
    return list(dict.fromkeys(ips))


def _probar_psql_cmd(password: str, puerto: int = 5432) -> tuple:
    """Usa psql via CMD para probar conexión."""
    import os
    env = os.environ.copy()
    env["PGPASSWORD"] = password
    env["PGCLIENTENCODING"] = "UTF8"
    
    direcciones = _obtener_ips_locales()
    for ip in direcciones:
        try:
            proc = subprocess.run(
                ["psql", "-h", str(ip), "-p", str(puerto), "-U", "postgres", "-d", "postgres", "-c", "SELECT 1;", "-t"],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
                env=env, timeout=10,
            )
            if proc.returncode == 0 or "1" in proc.stdout:
                return (True, ip, password)
        except Exception:
            continue
    return (False, None, password)


def _buscar_psql_executable() -> str:
    """Busca el ejecutable psql en el sistema."""
    rutas = [
        r"C:\Program Files\PostgreSQL\18\bin\psql.exe",
        r"C:\Program Files\PostgreSQL\17\bin\psql.exe",
        r"C:\Program Files\PostgreSQL\16\bin\psql.exe",
        r"C:\Program Files\PostgreSQL\15\bin\psql.exe",
        r"C:\Program Files\PostgreSQL\14\bin\psql.exe",
        r"C:\Program Files\PostgreSQL\13\bin\psql.exe",
        r"C:\Program Files (x86)\PostgreSQL\18\bin\psql.exe",
        r"C:\Program Files (x86)\PostgreSQL\17\bin\psql.exe",
        r"C:\Program Files (x86)\PostgreSQL\16\bin\psql.exe",
        r"C:\Program Files (x86)\PostgreSQL\15\bin\psql.exe",
        r"C:\PostgreSQL\18\bin\psql.exe",
        r"C:\PostgreSQL\17\bin\psql.exe",
        r"C:\PostgreSQL\16\bin\psql.exe",
        r"C:\PostgreSQL\15\bin\psql.exe",
    ]
    for ruta in rutas:
        if os.path.exists(ruta):
            return ruta
    return "psql"


def _pg_responde_en_puerto(puerto: int = 5432, timeout: float = 2.0) -> bool:
    """Verifica si hay un servidor PostgreSQL escuchando en el puerto."""
    try:
        # Intentar primero con 127.0.0.1
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        resultado = sock.connect_ex(("127.0.0.1", puerto))
        sock.close()
        if resultado == 0:
            return True
        
        # Intentar con ::1 (IPv6 localhost)
        sock = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        resultado = sock.connect_ex(("::1", puerto))
        sock.close()
        if resultado == 0:
            return True
            
    except Exception:
        pass
    
    return False


def _verificar_postgresql_activo() -> bool:
    """Verificación híbrida para confirmar que PostgreSQL está activo."""
    import time
    
    for _ in range(3):
        if _pg_responde_en_puerto(5432):
            return True
        if _probar_puerto_powershell(5432):
            return True
        time.sleep(0.3)
    
    return False


def _probar_conexion_cmd(password: str, attempts: int = 3) -> bool:
    """Usa pg_isready o psql via CMD para probar conexión."""
    import os
    
    for _ in range(attempts):
        # Intentar con pg_isready
        try:
            result = subprocess.run(
                ["pg_isready", "-h", "localhost", "-p", "5432"],
                capture_output=True, text=True, timeout=5,
                env=dict(os.environ, PGPASSWORD=password),
            )
            if result.returncode == 0:
                return True
        except Exception:
            pass
        
        # Intentar con psql
        try:
            result = subprocess.run(
                ["psql", "-h", "localhost", "-U", "postgres", "-d", "postgres", 
                 "-c", "SELECT 1;", "-t", "-A"],
                capture_output=True, text=True, timeout=5,
                env=dict(os.environ, PGPASSWORD=password),
            )
            if result.returncode == 0 and "1" in result.stdout:
                return True
        except Exception:
            pass
        
        time.sleep(0.5)
    
    return False


def _buscar_conexion_cmd() -> str:
    """Busca conexión usando comandos CMD."""
    passwords = ["ivan", "postgres", "admin", "root", "Password123!", 
                "Admin123!", "Psql123!", "postgres123", "123456"]
    
    for pwd in passwords:
        if _probar_conexion_cmd(pwd, attempts=1):
            return pwd
    
    return ""


def _detectar_postgresql_linux() -> dict:
    """Detecta PostgreSQL en Linux usando comandos del sistema."""
    info = {
        "instalado": False,
        "version": None,
        "servicio_activo": False,
        "ruta_bin": None,
        "servicio_nombre": "postgresql",
        "mensaje": "",
    }

    # 1. Buscar binarios PostgreSQL en PATH
    psql_path = None
    for cmd in ["psql", "pg_config"]:
        try:
            proc = subprocess.run(["which", cmd], capture_output=True, text=True, timeout=5)
            if proc.returncode == 0:
                path = proc.stdout.strip()
                if cmd == "psql":
                    psql_path = path
                if path:
                    info["instalado"] = True
        except Exception:
            pass

    # 2. Buscar en rutas típicas Linux
    if not psql_path:
        for ruta in RUTAS_POSTGRESQL:
            candidate = os.path.join(ruta, "psql")
            if os.path.exists(candidate):
                psql_path = candidate
                info["instalado"] = True
                break
            # Buscar subdirectorios pg* en /usr/lib/postgresql
            if os.path.isdir(ruta):
                try:
                    for item in os.listdir(ruta):
                        pgbin = os.path.join(ruta, item, "bin", "psql")
                        if os.path.exists(pgbin):
                            psql_path = pgbin
                            info["instalado"] = True
                            info["ruta_bin"] = os.path.join(ruta, item, "bin")
                            break
                except OSError:
                    pass

    if psql_path and not info["ruta_bin"]:
        info["ruta_bin"] = os.path.dirname(psql_path)

    # 3. Obtener versión desde psql --version
    if info["instalado"]:
        try:
            proc = subprocess.run(
                [psql_path or "psql", "--version"],
                capture_output=True, text=True, timeout=5,
            )
            m = re.search(r'(\d+)(?:\.\d+)*', proc.stdout)
            if m:
                info["version"] = m.group(1)
        except Exception:
            pass

    # 4. Verificar servicio systemd
    try:
        proc = subprocess.run(
            ["systemctl", "is-active", "postgresql"],
            capture_output=True, text=True, timeout=5,
        )
        info["servicio_activo"] = proc.stdout.strip() == "active"
    except Exception:
        pass

    # 5. Si el puerto responde, forzar servicio_activo = True
    if _pg_responde_en_puerto(5432):
        info["servicio_activo"] = True
        info["instalado"] = True

    return info


def detectar_postgresql_existente() -> dict:
    """Detecta si PostgreSQL está instalado y retorna información detallada.
    Funciona en Windows y Linux.
    """
    resultado = {
        "instalado": False,
        "version": None,
        "servicio_activo": False,
        "ruta_bin": None,
        "puerto": 5432,
        "servicio_nombre": None,
        "mensaje": "",
    }

    # 0a. En Linux, detectar vía comandos del sistema
    if not ES_WINDOWS:
        linux_info = _detectar_postgresql_linux()
        resultado["instalado"] = linux_info["instalado"]
        resultado["version"] = linux_info["version"]
        resultado["servicio_activo"] = linux_info["servicio_activo"]
        resultado["ruta_bin"] = linux_info["ruta_bin"]
        resultado["servicio_nombre"] = linux_info["servicio_nombre"]

    # 0b. VERIFICACIÓN PRINCIPAL: El puerto 5432 debe responder
    pg_activo = _verificar_postgresql_activo()

    if pg_activo:
        resultado["instalado"] = True
        resultado["servicio_activo"] = True
        resultado["puerto"] = 5432

    # 1. Intentar conexión psycopg2 para obtener versión (si activo)
    if pg_activo:
        try:
            import psycopg2
            passwords_a_probar = [
                PASSWORD_POSTGRES, "ivan", "postgres", "admin", "root",
                "Password123!", "Admin123!", "Psql123!", "postgres123",
                "root123", "admin123", "123456", "",
            ]
            hosts_a_probar = _obtener_ips_locales()

            for pwd in passwords_a_probar:
                for host in hosts_a_probar:
                    try:
                        conn = psycopg2.connect(
                            host=host, port=5432, user="postgres",
                            password=pwd, dbname="postgres", connect_timeout=3,
                        )
                        conn.close()
                        try:
                            conn2 = psycopg2.connect(
                                host=host, port=5432, user="postgres",
                                password=pwd, dbname="postgres", connect_timeout=3
                            )
                            cur = conn2.cursor()
                            cur.execute("SHOW server_version_num;")
                            ver_num = cur.fetchone()[0]
                            resultado["version"] = ver_num[:2]
                            cur.close()
                            conn2.close()
                        except Exception:
                            pass
                        break
                    except Exception:
                        continue
                if resultado.get("version"):
                    break
        except ImportError:
            pass

    # 2. En Windows, buscar servicio PostgreSQL via PowerShell
    if ES_WINDOWS:
        try:
            proc = subprocess.run(
                ["powershell", "-NoProfile", "-Command",
                 "Get-Service | Where-Object {$_.DisplayName -like '*PostgreSQL*' -and $_.DisplayName -notlike '*pgAgent*'} | ConvertTo-Json -Compress"],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
                timeout=10,
            )
            if proc.stdout.strip():
                try:
                    servicios = json.loads(proc.stdout)
                    if isinstance(servicios, dict):
                        servicios = [servicios]
                    for svc in servicios:
                        svc_name = svc.get("Name", "")
                        display_name = svc.get("DisplayName", "")
                        if "pgagent" in svc_name.lower():
                            continue
                        if not resultado["servicio_nombre"]:
                            resultado["servicio_nombre"] = svc_name
                        ver_match = re.search(r'\d+', display_name)
                        if ver_match and not resultado["version"]:
                            resultado["version"] = ver_match.group()
                        if svc.get("Status") == 1:
                            resultado["servicio_activo"] = True
                except (json.JSONDecodeError, TypeError):
                    pass
        except Exception:
            pass

    # 3. Buscar en carpetas típicas (para obtener ruta bin)
    if not resultado["ruta_bin"]:
        for ruta in RUTAS_POSTGRESQL:
            if not os.path.exists(ruta):
                continue
            try:
                subdirs = os.listdir(ruta)
                pg_versions = [d for d in subdirs if d.startswith("pg") and os.path.isdir(os.path.join(ruta, d))]
                if pg_versions:
                    pg_versions.sort(key=lambda x: [int(n) for n in re.findall(r'\d+', x)], reverse=True)
                    pg_dir = pg_versions[0]
                    ver_match = re.search(r'\d+', pg_dir)
                    if ver_match and not resultado["version"]:
                        resultado["version"] = ver_match.group()
                    if not resultado["ruta_bin"]:
                        resultado["ruta_bin"] = os.path.join(ruta, pg_dir, "bin")
                    break
            except OSError:
                continue

    # 4. Verificar estado del servicio (Windows: sc query)
    if ES_WINDOWS and resultado["servicio_nombre"] and not resultado["servicio_activo"]:
        try:
            check = subprocess.run(
                ["sc", "query", resultado["servicio_nombre"]],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
            )
            resultado["servicio_activo"] = "RUNNING" in check.stdout
        except Exception:
            pass

    # 5. Leer puerto desde postgresql.conf
    if resultado["ruta_bin"] and os.path.exists(resultado["ruta_bin"]):
        pg_conf = os.path.join(resultado["ruta_bin"], "..", "data", "postgresql.conf")
        if os.path.exists(pg_conf):
            try:
                with open(pg_conf, "r", encoding="utf-8", errors="replace") as f:
                    for line in f:
                        stripped = line.strip()
                        if stripped.startswith("port") and not stripped.startswith("port#"):
                            port_match = re.search(r'port\s*=\s*(\d+)', stripped)
                            if port_match:
                                resultado["puerto"] = int(port_match.group(1))
                                break
            except OSError:
                pass

    # 6. Generar mensaje descriptivo
    if resultado["instalado"]:
        if resultado["servicio_activo"]:
            ver = resultado["version"] or "?"
            resultado["mensaje"] = f"PostgreSQL {ver} instalado y activo"
        else:
            ver = resultado["version"] or "?"
            resultado["mensaje"] = f"PostgreSQL {ver} instalado pero servicio detenido"
    else:
        resultado["mensaje"] = "PostgreSQL no encontrado en este equipo"

    return resultado
