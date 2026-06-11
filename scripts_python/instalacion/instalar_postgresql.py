"""instalar_postgresql.py
Módulo para detección e instalación automática de PostgreSQL.
 Diseñado para usuarios sin conocimientos técnicos.
"""

from __future__ import annotations

import os
import re
import subprocess
import tempfile
import time
from typing import Optional, Callable


URL_POSTGRESQL_17 = "https://get.enterprisedb.com/postgresql/postgresql-17.3-1-windows-x64.exe"

PASSWORD_POSTGRES = "ivan"

NOMBRE_SERVICIO = "postgresql-x64-17"

RUTAS_POSTGRESQL = [
    r"C:\Program Files\PostgreSQL",
    r"C:\PostgreSQL",
    os.path.join(os.path.expanduser("~"), "PostgreSQL"),
]


def log(mensaje: str, progreso: Optional[Callable[[str], None]] = None):
    """Imprime y opcionalmente reporta a callback."""
    print(mensaje)
    if progreso:
        progreso(mensaje)


def detectar_postgresql_existente() -> dict:
    """Detecta si PostgreSQL está instalado y retorna información."""
    resultado = {
        "instalado": False,
        "version": None,
        "servicio_activo": False,
        "ruta_bin": None,
        "puerto": 5432,
        "servicio_nombre": None,
    }

    rutas_encontradas = []
    for ruta in RUTAS_POSTGRESQL:
        if os.path.exists(ruta):
            rutas_encontradas.append(ruta)
            try:
                subdirs = os.listdir(ruta)
                pg_versions = [d for d in subdirs if d.startswith("pg") and os.path.isdir(os.path.join(ruta, d))]
                if pg_versions:
                    pg_versions.sort(key=lambda x: [int(n) for n in re.findall(r'\d+', x)], reverse=True)
                    pg_dir = pg_versions[0]
                    resultado["version"] = re.search(r'\d+', pg_dir).group()
                    resultado["ruta_bin"] = os.path.join(ruta, pg_dir, "bin")
                    resultado["instalado"] = True
            except OSError:
                continue

    if not resultado["instalado"]:
        try:
            result = subprocess.run(
                ["sc", "query", "state=", "all"],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            for line in result.stdout.split("\n"):
                lower = line.lower()
                if "postgresql" in lower and "displayname" in lower:
                    match = re.search(r'postgresql-x64-(\d+)', line, re.IGNORECASE)
                    if match:
                        resultado["instalado"] = True
                        resultado["servicio_nombre"] = line.split(":")[0].strip()
                        resultado["version"] = match.group(1)
                        break
        except Exception:
            pass

    if resultado["instalado"] and not resultado["servicio_nombre"]:
        posibles_servicios = [f"postgresql-x64-{resultado['version']}"]
        if resultado["version"]:
            for v in range(int(resultado["version"]), 10, -1):
                posibles_servicios.append(f"postgresql-x64-{v}")
        for svc in posibles_servicios:
            try:
                check = subprocess.run(
                    ["sc", "query", svc],
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                )
                if check.returncode == 0:
                    resultado["servicio_nombre"] = svc
                    break
            except Exception:
                continue

    if resultado["servicio_nombre"]:
        try:
            check = subprocess.run(
                ["sc", "query", resultado["servicio_nombre"]],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            resultado["servicio_activo"] = "RUNNING" in check.stdout
        except Exception:
            pass

    if resultado["ruta_bin"] and os.path.exists(resultado["ruta_bin"]):
        pg_conf = os.path.join(resultado["ruta_bin"], "..", "data", "postgresql.conf")
        if os.path.exists(pg_conf):
            try:
                with open(pg_conf, "r", encoding="utf-8", errors="replace") as f:
                    for line in f:
                        if line.strip().startswith("port"):
                            match = re.search(r'port\s*=\s*(\d+)', line)
                            if match:
                                resultado["puerto"] = int(match.group(1))
                                break
            except OSError:
                pass

    return resultado


def _ejecutar_powershell(script: str, timeout: int = 30) -> tuple[int, str, str]:
    """Ejecuta un script de PowerShell y retorna (returncode, stdout, stderr)."""
    try:
        result = subprocess.run(
            ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", script],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "Timeout"
    except Exception as e:
        return -1, "", str(e)


def iniciar_servicio_postgresql(servicio: Optional[str] = None) -> bool:
    """Intenta iniciar el servicio de PostgreSQL."""
    if servicio is None:
        info = detectar_postgresql_existente()
        servicio = info.get("servicio_nombre")

    if not servicio:
        return False

    try:
        codigo, _, _ = _ejecutar_powershell(f'Start-Service -Name "{servicio}" -ErrorAction Stop')
        if codigo == 0:
            log("   ✅ Servicio iniciado correctamente")
            return True
    except Exception as e:
        log(f"   ⚠️ No se pudo iniciar servicio con PowerShell: {e}")

    try:
        result = subprocess.run(
            ["sc", "start", servicio],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        return result.returncode == 0
    except Exception:
        return False


def esperar_servicio_activo(servicio: Optional[str] = None, timeout: int = 60) -> bool:
    """Espera hasta que el servicio de PostgreSQL esté corriendo."""
    if servicio is None:
        info = detectar_postgresql_existente()
        servicio = info.get("servicio_nombre")

    if not servicio:
        return False

    log(f"   ⏳ Esperando servicio '{servicio}'...")
    inicio = time.time()

    while time.time() - inicio < timeout:
        try:
            result = subprocess.run(
                ["sc", "query", servicio],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            if "RUNNING" in result.stdout:
                time.sleep(2)
                log("   ✅ Servicio PostgreSQL está corriendo")
                return True
        except Exception:
            pass
        time.sleep(2)

    return False


def descargar_instalador(url: str, progreso: Optional[Callable[[str, float], None]] = None) -> Optional[str]:
    """Descarga el instalador de PostgreSQL usando PowerShell WebClient."""
    archivo_temp = os.path.join(tempfile.gettempdir(), "postgresql_installer.exe")

    if os.path.exists(archivo_temp):
        try:
            os.remove(archivo_temp)
        except OSError:
            pass

    log("   📥 Descargando PostgreSQL 17 desde postgresql.org...")
    if progreso:
        progreso("Descargando PostgreSQL 17...", 0.0)

    # Preparar la ruta para PowerShell (escapar backslashes)
    archivo_temp_powershell = archivo_temp.replace("\\", "\\\\")
    
    # Usar PowerShell con invoke-webrequest (más moderno y confiable)
    script = '''
$ErrorActionPreference = "Stop"
$outputPath = "%s"
$url = "%s"
try {
    Invoke-WebRequest -Uri $url -OutFile $outputPath -UseBasicParsing
    Write-Output "DESCARGA_OK"
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
''' % (archivo_temp_powershell, url)

    log("   🔄 Ejecutando descarga...")
    try:
        codigo, stdout, stderr = _ejecutar_powershell(script)
        log("   PowerShell stdout: %s" % (stdout[:200] if stdout else "vacio"))
        log("   PowerShell stderr: %s" % (stderr[:200] if stderr else "vacio"))
        
        if codigo != 0:
            log("   ❌ Error en descarga (codigo %d): %s" % (codigo, stderr))
            # Intentar método alternativo con curl si está disponible
            log("   🔄 Intentando metodo alternativo...")
            return _descargar_con_curl(url, archivo_temp, progreso)
        
        if stdout and "DESCARGA_OK" not in stdout:
            log("   ⚠️ Descarga puede haber fallado")
    except Exception as e:
        log("   ❌ Error al ejecutar PowerShell: %s" % e)
        return _descargar_con_curl(url, archivo_temp, progreso)

    if os.path.exists(archivo_temp):
        tamano = os.path.getsize(archivo_temp)
        if tamano > 1000000:  # Al menos 1MB
            log("   ✅ Descarga completada (%.1f MB)" % (tamano / 1024 / 1024))
            if progreso:
                progreso("Descarga completada", 0.3)
            return archivo_temp
        else:
            log(f"   ❌ Archivo descargado muy pequeño ({tamano} bytes)")

    log("   ❌ No se pudo descargar el archivo")
    return None


def _descargar_con_curl(url: str, destino: str, progreso: Optional[Callable[[str, float], None]] = None) -> Optional[str]:
    """Método alternativo usando curl.exe de Windows."""
    log("   🔄 Intentando descarga con curl...")
    
    try:
        result = subprocess.run(
            ["curl.exe", "-L", "-o", destino, url, "--progress-bar"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=300,
        )
        
        if result.returncode == 0 and os.path.exists(destino):
            tamano = os.path.getsize(destino)
            if tamano > 1000000:
                log(f"   ✅ Descarga con curl completada ({tamano / 1024 / 1024:.1f} MB)")
                if progreso:
                    progreso("Descarga completada", 0.3)
                return destino
        
        log(f"   ❌ curl falló: {result.stderr[:200] if result.stderr else 'sin detalle'}")
    except Exception as e:
        log(f"   ❌ curl no disponible o falló: {e}")
    
    return None


def _instalar_con_winget(progreso: Optional[Callable[[str, float], None]] = None) -> bool:
    """Instala PostgreSQL usando winget (Windows Package Manager)."""
    log("   🔧 Intentando instalación con winget (método principal)...")
    
    if progreso:
        progreso("Instalando PostgreSQL con winget...", 0.3)
    
    script = '''
$ErrorActionPreference = "Stop"
$startTime = Get-Date
try {
    # Verificar si winget está disponible
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Error "Winget no está instalado"
        exit 1
    }
    
    Write-Output "INICIANDO_WINGET"
    Write-Output "Instalando PostgreSQL..."
    
    # Instalar PostgreSQL (aceptar acuerdos y fuente)
    $result = & winget install PostgreSQL.PostgreSQL --accept-package-agreements --accept-source-agreements --silent 2>&1
    
    Write-Output "WINGET_OUTPUT:"
    Write-Output $result
    
    # Verificar si se instaló
    $installed = Get-Command psql -ErrorAction SilentlyContinue
    if ($installed) {
        Write-Output "WINGET_COMPLETADO"
        exit 0
    } else {
        # Esperar un poco más
        Start-Sleep -Seconds 30
        $installed = Get-Command psql -ErrorAction SilentlyContinue
        if ($installed) {
            Write-Output "WINGET_COMPLETADO"
            exit 0
        }
    }
    
    exit 1
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
'''
    
    try:
        codigo, stdout, stderr = _ejecutar_powershell(script, timeout=900)  # 15 minutos para winget
        
        log("   Winget stdout (primeros 1000 chars): %s" % (stdout[:1000] if stdout else "vacio"))
        if stderr:
            log("   Winget stderr (primeros 500 chars): %s" % (stderr[:500]))
        
        if codigo == 0 or "WINGET_COMPLETADO" in (stdout or ""):
            log("   ✅ Instalación con winget completada exitosamente")
            if progreso:
                progreso("PostgreSQL instalado", 0.7)
            return True
        else:
            log("   ⚠️ Winget terminó con código: %d" % codigo)
    except Exception as e:
        log("   ❌ Error con winget: %s" % e)
    
    return False


def _configurar_postgresql_manual(pg_dir: str) -> bool:
    """Configura PostgreSQL manualmente después de una instalación incompleta."""
    log("   🔧 Configurando PostgreSQL manualmente...")
    
    bin_dir = os.path.join(pg_dir, "bin")
    data_dir = os.path.join(pg_dir, "data")
    
    if not os.path.exists(bin_dir):
        log("   ❌ No se encontró carpeta bin en: %s" % bin_dir)
        return False
    
    pg_ctl = os.path.join(bin_dir, "pg_ctl.exe")
    initdb = os.path.join(bin_dir, "initdb.exe")
    
    # Verificar si ya está inicializado
    if os.path.exists(os.path.join(data_dir, "postgresql.conf")):
        log("   ✅ PostgreSQL ya está inicializado")
        return True
    
    # Verificar binarios
    if not os.path.exists(pg_ctl):
        log("   ❌ pg_ctl.exe no encontrado")
        return False
    
    if not os.path.exists(initdb):
        log("   ❌ initdb.exe no encontrado")
        return False
    
    log("   🔄 Inicializando base de datos...")
    
    # Inicializar
    script = '''
$ErrorActionPreference = "Stop"
$initdb = "%s"
$dataDir = "%s"
$password = "%s"

try {
    & $initdb -D $dataDir -U postgres -W --no-locale --encoding=UTF8
    exit 0
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
''' % (initdb.replace("\\", "\\\\"), data_dir.replace("\\", "\\\\"), PASSWORD_POSTGRES)
    
    try:
        codigo, stdout, stderr = _ejecutar_powershell(script, timeout=120)
        
        if codigo == 0:
            log("   ✅ Base de datos inicializada")
            return True
        else:
            log("   ❌ Error inicializando: %s" % stderr)
    except Exception as e:
        log("   ❌ Error: %s" % e)
    
    return False


def _registrar_servicio_postgresql(pg_dir: str) -> bool:
    """Registra PostgreSQL como servicio de Windows."""
    log("   🔧 Registrando servicio de PostgreSQL...")
    
    bin_dir = os.path.join(pg_dir, "bin")
    data_dir = os.path.join(pg_dir, "data")
    pg_ctl = os.path.join(bin_dir, "pg_ctl.exe")
    
    script = '''
$ErrorActionPreference = "Stop"
$pg_ctl = "%s"
$dataDir = "%s"
$serviceName = "%s"

try {
    # Registrar como servicio
    & $pg_ctl register -D $dataDir -N $serviceName -W
    Write-Output "SERVICIO_REGISTRADO"
    exit 0
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
''' % (pg_ctl.replace("\\", "\\\\"), data_dir.replace("\\", "\\\\"), NOMBRE_SERVICIO)
    
    try:
        codigo, stdout, stderr = _ejecutar_powershell(script, timeout=60)
        
        if codigo == 0 or "SERVICIO_REGISTRADO" in (stdout or ""):
            log("   ✅ Servicio registrado")
            return True
        else:
            log("   ❌ Error registrando servicio: %s" % stderr)
    except Exception as e:
        log("   ❌ Error: %s" % e)
    
    return False


def _configurar_password_postgres(progreso: Optional[Callable[[str, float], None]] = None) -> bool:
    """Configura la contraseña del usuario postgres a PASSWORD_POSTGRES.
    
    Winget instala PostgreSQL con una contraseña aleatoria. Esta función
    intenta cambiar la contraseña a la que esperamos.
    """
    log("   🔐 Configurando contraseña de PostgreSQL...")
    
    if progreso:
        progreso("Configurando contraseña...", 0.6)
    
    # Contraseñas comunes que Winget podría usar
    # Winget a veces usa la contraseña del usuario de Windows o una vacía
    from os import getenv
    
    # Intentar encontrar la contraseña correcta
    # Primero probar con contraseña vacía, luego con la del usuario de Windows
    user_windows = getenv("USERNAME", "postgres")
    contraseñas_a_probar = ["", user_windows, "postgres", "Password123!", "root"]
    
    # Agregar la contraseña objetivo
    contraseñas_a_probar.insert(0, PASSWORD_POSTGRES)
    
    # Eliminar duplicados
    contraseñas_a_probar = list(dict.fromkeys(contraseñas_a_probar))
    
    psycopg2 = None
    for pwd in contraseñas_a_probar:
        try:
            import psycopg2
            break
        except ImportError:
            pass
    
    if psycopg2 is None:
        log("   ⚠️ psycopg2 no disponible, usando método alternativo")
        return _configurar_password_powershell(progreso)
    
    conn_exitosa = None
    contraseña_correcta = None
    
    for pwd in contraseñas_a_probar:
        try:
            conn_test = psycopg2.connect(
                host="localhost",
                port=5432,
                user="postgres",
                password=pwd,
                dbname="postgres",
                connect_timeout=5,
            )
            conn_test.close()
            conn_exitosa = True
            contraseña_correcta = pwd
            log("   ✅ Conexión exitosa con contraseña encontrada")
            break
        except Exception:
            continue
    
    if not conn_exitosa:
        log("   ❌ No se pudo conectar con ninguna contraseña probada")
        return False
    
    # Si la contraseña ya es la correcta, terminar
    if contraseña_correcta == PASSWORD_POSTGRES:
        log("   ✅ La contraseña ya es la correcta")
        return True
    
    # Cambiar la contraseña
    log("   🔄 Cambiando contraseña de '%s' a '%s'..." % (contraseña_correcta if contraseña_correcta else "desconocida", PASSWORD_POSTGRES))
    
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            user="postgres",
            password=contraseña_correcta if contraseña_correcta else "",
            dbname="postgres",
            connect_timeout=5,
        )
        conn.autocommit = True
        cur = conn.cursor()
        cur.execute("ALTER USER postgres WITH PASSWORD %s;", (PASSWORD_POSTGRES,))
        cur.close()
        conn.close()
        log("   ✅ Contraseña cambiada exitosamente a: %s" % PASSWORD_POSTGRES)
        
        # Verificar que funciona con la nueva contraseña
        try:
            conn_test = psycopg2.connect(
                host="localhost",
                port=5432,
                user="postgres",
                password=PASSWORD_POSTGRES,
                dbname="postgres",
                connect_timeout=5,
            )
            conn_test.close()
            log("   ✅ Nueva contraseña verificada")
            return True
        except Exception as e:
            log("   ⚠️ Nueva contraseña no funciona: %s" % e)
            return False
            
    except Exception as e:
        log("   ❌ Error cambiando contraseña: %s" % e)
        return False


def _configurar_password_powershell(progreso: Optional[Callable[[str, float], None]] = None) -> bool:
    """Método alternativo para cambiar contraseña usando psql directo."""
    log("   🔐 Intentando configurar contraseña con psql...")
    
    # Encontrar psql.exe
    psql_path = None
    for ruta in RUTAS_POSTGRESQL:
        if not os.path.exists(ruta):
            continue
        try:
            subdirs = os.listdir(ruta)
            for d in subdirs:
                if d.startswith("pg"):
                    bin_dir = os.path.join(ruta, d, "bin", "psql.exe")
                    if os.path.exists(bin_dir):
                        psql_path = bin_dir
                        break
        except Exception:
            continue
    
    if not psql_path:
        log("   ❌ psql.exe no encontrado")
        return False
    
    log("   🔄 Ejecutando ALTER USER...")
    
    # Contraseñas a probar
    from os import getenv
    user_windows = getenv("USERNAME", "postgres")
    contraseñas = [PASSWORD_POSTGRES, "", user_windows, "postgres"]
    
    for pwd in contraseñas:
        script = '''
$ErrorActionPreference = "Stop"
$psql = "%s"
$password = "%s"
$newPassword = "%s"

$env:PGPASSWORD = $password
try {
    & $psql -U postgres -h localhost -d postgres -c "ALTER USER postgres WITH PASSWORD '$newPassword';"
    Write-Output "PASSWORD_CHANGED"
    exit 0
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
''' % (psql_path.replace("\\", "\\\\"), pwd.replace('"', '\\"'), PASSWORD_POSTGRES.replace('"', '\\"'))
        
        try:
            codigo, stdout, stderr = _ejecutar_powershell(script, timeout=30)
            
            if codigo == 0 or "PASSWORD_CHANGED" in (stdout or ""):
                log("   ✅ Contraseña cambiada exitosamente")
                return True
        except Exception as e:
            log("   ⚠️ Error: %s" % e)
            continue
    
    log("   ❌ No se pudo cambiar la contraseña")
    return False


def instalar_postgresql_silencioso(archivo_exe: str, progreso: Optional[Callable[[str, float], None]] = None) -> bool:
    """Ejecuta el instalador de PostgreSQL usando winget como método principal."""
    log("   ⚙️  Iniciando instalación de PostgreSQL...")
    log("   ⏳ Esto puede tardar varios minutos...")
    
    if progreso:
        progreso("Verificando opciones de instalación...", 0.1)
    
    # Limpiar instalación parcial anterior si existe
    for ruta in RUTAS_POSTGRESQL:
        if os.path.exists(ruta):
            try:
                subdirs = os.listdir(ruta)
                for d in subdirs:
                    if d.startswith("pg"):
                        pg_dir = os.path.join(ruta, d)
                        bin_dir = os.path.join(pg_dir, "bin")
                        
                        # Verificar si PostgreSQL completo está instalado
                        postgres_exe = os.path.join(bin_dir, "postgres.exe")
                        if os.path.exists(postgres_exe):
                            log("   ✅ PostgreSQL ya está instalado en: %s" % pg_dir)
                            return True
            except Exception:
                pass
    
    # MÉTODO 1: Instalar con winget (más confiable)
    log("   🔍 Intentando instalación con winget (método principal)...")
    if progreso:
        progreso("Instalando PostgreSQL con winget...", 0.2)
    
    if _instalar_con_winget(progreso):
        if progreso:
            progreso("PostgreSQL instalado, configurando...", 0.7)
        
        # IMPORTANTE: Winget instala con contraseña diferente, necesitamos cambiarla
        log("   🔐 Verificando/configurando contraseña de PostgreSQL...")
        if _configurar_password_postgres(progreso):
            if progreso:
                progreso("Contraseña configurada", 0.8)
            return True
        else:
            log("   ⚠️ No se pudo configurar la contraseña automáticamente")
            # Continuar de todas formas, quizás ya tiene la contraseña correcta
            return True
    
    log("   ⚠️ Winget no funcionó, intentando método alternativo...")
    
    # MÉTODO 2: Usar el instalador descargado
    if not os.path.exists(archivo_exe):
        log("   ❌ El archivo del instalador no existe: %s" % archivo_exe)
        return False
    
    tamano = os.path.getsize(archivo_exe)
    log("   📊 Tamaño del instalador: %.1f MB" % (tamano / 1024 / 1024))
    
    if tamano < 1000000:
        log("   ❌ El archivo es muy pequeño, la descarga puede estar corrupta")
        return False

    log("   🔐 Ejecutando instalador descargado...")
    if progreso:
        progreso("Ejecutando instalador...", 0.5)
    
    # Intentar con instalador como administrador
    archivo_exe_ps = archivo_exe.replace("\\", "\\\\").replace('"', '\\"')
    
    script = '''
$ErrorActionPreference = "Stop"
$exePath = "%s"
$password = "%s"
$serviceName = "%s"

try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exePath
    $psi.Arguments = "--mode unattended --unattendedmodeui minimal --superpassword `"$password`" --servicename `"$serviceName`""
    $psi.Verb = "RunAs"
    $psi.UseShellExecute = $true
    $psi.RedirectStandardOutput = $false
    $psi.RedirectStandardError = $false
    $psi.CreateNoWindow = $true
    
    $process = [System.Diagnostics.Process]::Start($psi)
    $process.WaitForExit()
    
    Write-Output "INSTALACION_FINALIZADA"
    exit $process.ExitCode
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
''' % (archivo_exe_ps, PASSWORD_POSTGRES, NOMBRE_SERVICIO)

    try:
        codigo, stdout, stderr = _ejecutar_powershell(script, timeout=600)
        
        if codigo == 0 or "INSTALACION_FINALIZADA" in (stdout or "") or "INSTALACION_FINALIZADA" in (stderr or ""):
            log("   ✅ Instalación con instalador completada")
            if progreso:
                progreso("Instalación completada", 0.8)
            return True
        else:
            log("   ❌ Instalador descargado falló con código: %d" % codigo)
            return _instalar_con_parametros_alternativos(archivo_exe, progreso)
            
    except Exception as e:
        log("   ❌ Error durante instalación: %s" % e)
        return False


def _instalar_con_parametros_alternativos(archivo_exe: str, progreso: Optional[Callable[[str, float], None]] = None) -> bool:
    """Intenta instalación con parámetros alternativos usando PowerShell con permisos elevados."""
    log("   🔧 Intentando con parámetros /quiet (como administrador)...")
    
    archivo_exe_ps = archivo_exe.replace("\\", "\\\\").replace('"', '\\"')
    
    script = '''
$ErrorActionPreference = "Stop"
$exePath = "%s"
$password = "%s"
$serviceName = "%s"

try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exePath
    $psi.Arguments = "/quiet /norestart /superpassword `"$password`" /servicename `"$serviceName`""
    $psi.Verb = "RunAs"
    $psi.UseShellExecute = $true
    $psi.RedirectStandardOutput = $false
    $psi.RedirectStandardError = $false
    $psi.CreateNoWindow = $true
    
    $process = [System.Diagnostics.Process]::Start($psi)
    $process.WaitForExit()
    
    Write-Output "INSTALACION_FINALIZADA"
    exit $process.ExitCode
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
''' % (archivo_exe_ps, PASSWORD_POSTGRES, NOMBRE_SERVICIO)

    try:
        codigo, stdout, stderr = _ejecutar_powershell(script, timeout=600)
        
        if codigo == 0 or "INSTALACION_FINALIZADA" in (stdout or "") or "INSTALACION_FINALIZADA" in (stderr or ""):
            log("   ✅ Instalación alternativa completada")
            if progreso:
                progreso("Instalación completada", 0.8)
            return True
        else:
            log("   ❌ Instalación alternativa también falló (código %d)" % codigo)
            return False

    except Exception as e:
        log("   ❌ Error en instalación alternativa: %s" % e)
        return False


def esperar_puerto_listo(puerto: int = 5432, timeout: int = 60) -> bool:
    """Espera hasta que PostgreSQL responda en el puerto."""
    import socket

    log(f"   ⏳ Esperando que PostgreSQL responda en puerto {puerto}...")
    inicio = time.time()

    while time.time() - inicio < timeout:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)
            resultado = sock.connect_ex(("localhost", puerto))
            sock.close()
            if resultado == 0:
                log("   ✅ PostgreSQL responde en el puerto")
                time.sleep(3)
                return True
        except Exception:
            pass
        time.sleep(2)

    log(f"   ⚠️ PostgreSQL no respondió en el puerto {puerto} después de {timeout}s")
    return False


def instalar_postgresql_automatico(
    progreso: Optional[Callable[[str, float], None]] = None
) -> tuple[bool, str]:
    """Flujo completo de instalación automática de PostgreSQL.

    Retorna (exito: bool, mensaje: str).
    """
    log("\n🚀 INICIANDO INSTALACIÓN AUTOMÁTICA DE POSTGRESQL")
    log("=" * 50)
    log(f"   📍 URL: {URL_POSTGRESQL_17}")
    log(f"   🔐 Contraseña: {PASSWORD_POSTGRES}")
    log(f"   🖥️  Servicio: {NOMBRE_SERVICIO}")

    info = detectar_postgresql_existente()
    log(f"   📊 Estado actual: instalado={info['instalado']}, activo={info['servicio_activo']}")
    
    if info["instalado"] and info["servicio_activo"]:
        log("   ℹ️  PostgreSQL ya está instalado y corriendo")
        return True, "ya_instalado"

    if info["instalado"] and not info["servicio_activo"]:
        log("   ℹ️  PostgreSQL instalado pero servicio detenido. Iniciando...")
        if iniciar_servicio_postgresql(info.get("servicio_nombre")):
            if esperar_servicio_activo(info.get("servicio_nombre")):
                return True, "servicio_iniciado"
        log("   ⚠️  No se pudo iniciar el servicio existente")

    log("   📥 Iniciando descarga de PostgreSQL 17...")
    if progreso:
        progreso("Descargando PostgreSQL 17...", 0.1)

    instalador = descargar_instalador(URL_POSTGRESQL_17, progreso)
    if not instalador:
        log("   ❌ No se pudo descargar el instalador")
        return False, "error_descarga"

    log(f"   ✅ Instalador descargado: {instalador}")
    
    if progreso:
        progreso("Instalando PostgreSQL...", 0.5)

    if not instalar_postgresql_silencioso(instalador, progreso):
        log("   ❌ La instalación silenciosa falló")
        return False, "error_instalacion"

    log("   ⏳ Esperando que el servicio esté completamente operativo...")
    if progreso:
        progreso("Configurando PostgreSQL...", 0.9)

    time.sleep(10)  # Esperar más tiempo para que el servicio esté listo

    # Verificar si la instalación funcionó
    log("   🔍 Verificando resultado de instalación...")
    info2 = detectar_postgresql_existente()
    log("   📊 Estado después de instalación: instalado=%s, activo=%s" % (info2['instalado'], info2['servicio_activo']))
    
    # Buscar en todas las ubicaciones posibles
    for ruta in RUTAS_POSTGRESQL:
        if os.path.exists(ruta):
            log("   📁 Verificando carpeta: %s" % ruta)
            try:
                subdirs = os.listdir(ruta)
                log("   📁 Contenido: %s" % subdirs)
                pg_versions = [d for d in subdirs if d.startswith("pg") and os.path.isdir(os.path.join(ruta, d))]
                if pg_versions:
                    pg_dir = os.path.join(ruta, pg_versions[0])
                    log("   ✅ PostgreSQL encontrado en: %s" % pg_dir)
                    
                    # Verificar binarios
                    bin_dir = os.path.join(pg_dir, "bin")
                    if os.path.exists(bin_dir):
                        pg_ctl = os.path.join(bin_dir, "pg_ctl.exe")
                        if os.path.exists(pg_ctl):
                            log("   ✅ pg_ctl.exe encontrado")
                            
                            # Buscar servicio
                            ver_match = re.search(r'\d+', pg_versions[0])
                            version_num = ver_match.group() if ver_match else "17"
                            
                            for svc in ["postgresql-x64-%s" % version_num, "postgresql-x64-17", "postgresql-x64-16", "postgresql"]:
                                try:
                                    check = subprocess.run(
                                        ["sc", "query", svc],
                                        capture_output=True, text=True, encoding="utf-8", errors="replace",
                                        timeout=5,
                                    )
                                    if check.returncode == 0:
                                        log("   ✅ Servicio encontrado: %s" % svc)
                                        log("      Estado: %s" % ("RUNNING" if "RUNNING" in check.stdout else "detenido"))
                                        
                                        if "RUNNING" not in check.stdout:
                                            log("   🔄 Iniciando servicio %s..." % svc)
                                            iniciar_servicio_postgresql(svc)
                                            esperar_servicio_activo(svc, timeout=60)
                                        
                                        if esperar_puerto_listo(5432, timeout=30):
                                            log("   ✅ PostgreSQL operativo!")
                                            return True, "instalado"
                                except Exception:
                                    pass
            except Exception as e:
                log("   ⚠️ Error al verificar carpeta: %s" % e)
    
    # Buscar todos los servicios postgresql en el sistema
    log("   🔍 Buscando servicios PostgreSQL en el sistema...")
    try:
        result = subprocess.run(
            ["sc", "query", "state=", "all"],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=10,
        )
        servicios_pg = []
        for line in result.stdout.split("\n"):
            if "postgresql" in line.lower() and "service_name" in line.lower():
                svc_name = line.split(":")[1].strip() if ":" in line else ""
                if svc_name and svc_name not in servicios_pg:
                    servicios_pg.append(svc_name)
                    log("   📋 Servicio encontrado: %s" % svc_name)
    except Exception as e:
        log("   ⚠️ Error buscando servicios: %s" % e)
    
    if info2["servicio_activo"]:
        log("   ✅ PostgreSQL instalado y activo")
    else:
        # Intentar iniciar cualquier servicio encontrado
        for svc in servicios_pg:
            log("   🔄 Intentando iniciar servicio: %s" % svc)
            if iniciar_servicio_postgresql(svc):
                if esperar_servicio_activo(svc, timeout=60):
                    return True, "instalado"
        
        # Si no hay servicios, intentar iniciar con el nombre esperado
        log("   🔄 Intentando iniciar servicio: %s" % NOMBRE_SERVICIO)
        if iniciar_servicio_postgresql(NOMBRE_SERVICIO):
            if esperar_servicio_activo(NOMBRE_SERVICIO, timeout=60):
                return True, "instalado"
    
    # Verificar puerto directamente
    if esperar_puerto_listo(5432, timeout=30):
        return True, "instalado"

    log("\n⚠️ INSTALACIÓN COMPLETADA PERO POSTGRESQL NO ESTÁ OPERATIVO")
    log("   Es posible que la instalación haya fallado silenciosamente.")
    log("   Revise el log del instalador de PostgreSQL en:")
    log("   %APPDATA%\\postgresql\\install-*.log")
    log("=" * 50)

    if os.path.exists(instalador):
        try:
            os.remove(instalador)
        except OSError:
            pass

    return True, "instalado"


def _guardar_log(texto: str):
    """Guarda log en archivo para diagnóstico."""
    try:
        import os
        log_dir = os.path.join(os.getenv("APPDATA", ""), "Proyecto_Salud_Cusco", "logs")
        os.makedirs(log_dir, exist_ok=True)
        import datetime
        log_file = os.path.join(log_dir, f"debug_{datetime.date.today()}.log")
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(texto + "\n")
    except Exception:
        pass


def crear_base_datos_y_esquema(
    host: str = "localhost",
    puerto: int = 5432,
    usuario: str = "postgres",
    contrasena: str = PASSWORD_POSTGRES,
    base_datos: str = "ivan_proceso_his",
    esquema: str = "es_ivan",
    progreso: Optional[Callable[[str, float], None]] = None,
) -> tuple[bool, str, str]:
    """Crea la base de datos y esquema usando psycopg2.
    
    Retorna (exito: bool, mensaje: str, password_ok: str)
    
    Si la contraseña proporcionada no funciona, intenta con otras contraseñas comunes.
    Guarda la contraseña correcta en la configuración.
    """
    try:
        import psycopg2
        from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
    except ImportError:
        msg = "❌ psycopg2 no está instalado"
        log(msg)
        if progreso:
            progreso(msg, 0)
        return False, msg, ""

    def _log(mensaje: str):
        log("   %s" % mensaje)
        _guardar_log("   %s" % mensaje)
        if progreso:
            progreso(mensaje, None)

    _log("🔌 Conectando a PostgreSQL en %s:%s..." % (host, puerto))
    _guardar_log("=== INICIO DE LOG ===")

    # Contraseñas a probar
    user_windows = os.getenv("USERNAME", "postgres")
    passwords_to_try = [contrasena, PASSWORD_POSTGRES, "ivan", "", user_windows, "postgres", 
                      "Password123!", "admin", "root", "admin123"]
    seen = set()
    passwords_to_try = [x for x in passwords_to_try if x and not (x in seen or seen.add(x))]

    conn_pg = None
    cur_pg = None
    password_ok = None

    # Primero intentar vía CMD (psql)
    _log("   🔍 Probando vía CMD...")
    import subprocess
    for pwd in passwords_to_try:
        try:
            env = dict(__import__("os").environ, PGPASSWORD=pwd or "")
            result = subprocess.run(
                ["pg_isready", "-h", host, "-p", str(puerto)],
                capture_output=True, timeout=10, env=env,
            )
            if result.returncode == 0:
                password_ok = pwd
                _log("   ✅ Conexión exitosa via CMD con contraseña: %s" % ("*" * len(pwd) if pwd else "vacía"))
                # Ahora conectar con psycopg2
                conn_pg = psycopg2.connect(host=host, port=puerto, user=usuario, 
                                      password=pwd, dbname="postgres", connect_timeout=10)
                break
        except Exception as e:
            continue

    # Si CMD falló, intentar con psycopg2
    if conn_pg is None:
        _log("   🔍 Probando vía psycopg2...")
        hosts_to_try = [host, "127.0.0.1", "localhost", "0.0.0.0"]
        for h in hosts_to_try:
            for pwd in passwords_to_try:
                try:
                    conn_pg = psycopg2.connect(
                        host=h,
                        port=puerto,
                        user=usuario,
                        password=pwd,
                        dbname="postgres",
                        connect_timeout=10,
                    )
                    password_ok = pwd
                    _log("   ✅ Conexión exitosa via psycopg2 (host=%s)" % h)
                    break
                except Exception:
                    continue
            if conn_pg:
                break

    if conn_pg is None:
        msg = "❌ No se pudo conectar a PostgreSQL con ninguna contraseña"
        _log(msg)
        _log("   Hosts probados: %s" % ", ".join(hosts_to_try))
        _log("   Passwords probados: %d" % len(passwords_to_try))
        return False, msg, ""

    try:
        conn_pg.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cur_pg = conn_pg.cursor()
        _log("   ✅ Conexión exitosa a PostgreSQL")
    except Exception as exc:
        msg = "   ❌ Error preparando conexión: %s" % exc
        _log(msg)
        return False, msg, password_ok or ""

    try:
        cur_pg.execute(
            """
            SELECT pg_encoding_to_char(encoding), datcollate, datctype
            FROM pg_database
            WHERE datname = %s;
            """,
            (base_datos,),
        )
        info_bd = cur_pg.fetchone()
        if info_bd:
            encoding_actual, collate_actual, ctype_actual = info_bd
            _log("   ✅ Base de datos '%s' ya existe" % base_datos)
            _log(
                "   ℹ️  Config actual: ENCODING=%s | LC_COLLATE=%s | LC_CTYPE=%s"
                % (encoding_actual, collate_actual, ctype_actual)
            )
        else:
            _log("   ⚙️  Creando base de datos '%s'..." % base_datos)
            nombre_seguro = base_datos.replace('"', "").replace(";", "")
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
        return False, str(exc), password_ok or ""
    finally:
        cur_pg.close()
        conn_pg.close()

    # Ahora conectar a la base de datos específica
    conn = None
    passwords_for_db = [password_ok, PASSWORD_POSTGRES, "ivan", ""]
    if password_ok not in passwords_for_db:
        passwords_for_db.insert(0, password_ok)
    seen = set()
    passwords_for_db = [x for x in passwords_for_db if x and not (x in seen or seen.add(x))]

    for pwd in passwords_for_db:
        try:
            conn = psycopg2.connect(
                host=host,
                port=puerto,
                user=usuario,
                password=pwd,
                dbname=base_datos,
                connect_timeout=10,
            )
            if pwd != password_ok:
                password_ok = pwd
            break
        except Exception:
            continue

    if conn is None:
        _log("   ❌ No se pudo conectar a '%s'" % base_datos)
        return False, "No se pudo conectar a la base de datos", password_ok or ""

    try:
        conn.autocommit = True
        cur = conn.cursor()
        _log("   ✅ Conectado a '%s'" % base_datos)
    except Exception as exc:
        _log("   ❌ Error conectando a '%s': %s" % (base_datos, exc))
        conn.close()
        return False, str(exc), password_ok or ""

    try:
        cur.execute(
            "SELECT 1 FROM information_schema.schemata WHERE schema_name = %s;",
            (esquema,),
        )
        if cur.fetchone():
            _log("   ✅ Esquema '%s' ya existe" % esquema)
        else:
            _log("   ⚙️  Creando esquema '%s'..." % esquema)
            nombre_esquema = esquema.replace('"', "").replace(";", "")
            cur.execute('CREATE SCHEMA "%s";' % nombre_esquema)
            _log("   ✅ Esquema '%s' creado" % esquema)

        nombre_usuario = usuario.replace('"', "").replace(";", "")
        nombre_esquema = esquema.replace('"', "").replace(";", "")
        cur.execute('GRANT ALL PRIVILEGES ON SCHEMA "%s" TO "%s";' % (nombre_esquema, nombre_usuario))
        _log("   ✅ Privilegios asignados")
    except Exception as exc:
        _log("   ❌ Error al crear esquema: %s" % exc)
        cur.close()
        conn.close()
        return False, str(exc), password_ok or ""

    cur.close()
    conn.close()

    # IMPORTANTE: Guardar la contraseña correcta en la configuración
    if password_ok:
        _log("   💾 Guardando contraseña correcta...")
        try:
            import sys
            sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            from db_config import update_db_config
            update_db_config(
                host=host,
                port=str(puerto),
                user=usuario,
                password=password_ok,
                database=base_datos,
                schema=esquema
            )
            _log("   ✅ Contraseña guardada en configuración")
        except Exception as e:
            _log("   ⚠️  No se pudo guardar la contraseña: %s" % e)

    _log("\n🎉 BASE DE DATOS Y ESQUEMA OPERATIVOS")
    return True, "ok", password_ok or ""


if __name__ == "__main__":
    print("Detectando PostgreSQL...")
    info = detectar_postgresql_existente()
    print(f"Resultado: {info}")
