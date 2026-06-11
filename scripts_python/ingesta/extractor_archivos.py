import os
import shutil
import subprocess
import tarfile
import zipfile

try:
    import py7zr  # type: ignore
except Exception:
    py7zr = None


CREATE_NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)
_EXTRACTORES_CACHE = None


def _ruta_valida(ruta):
    return bool(ruta) and os.path.exists(ruta)


def _agregar_candidato(candidatos, vistos, tipo, ruta):
    if not _ruta_valida(ruta):
        return
    ruta_abs = os.path.abspath(ruta)
    clave = (tipo, os.path.normcase(ruta_abs))
    if clave in vistos:
        return
    vistos.add(clave)
    candidatos.append((tipo, ruta_abs))


def _detectar_extractores():
    candidatos = []
    vistos = set()

    rutas_winrar = [
        r"C:\Program Files\WinRAR\WinRAR.exe",
        r"C:\Program Files (x86)\WinRAR\WinRAR.exe",
        os.path.join(os.environ.get("PROGRAMFILES", ""), "WinRAR", "WinRAR.exe"),
        os.path.join(os.environ.get("PROGRAMFILES(X86)", ""), "WinRAR", "WinRAR.exe"),
    ]
    for ruta in rutas_winrar:
        _agregar_candidato(candidatos, vistos, "winrar", ruta)

    for cmd in ("WinRAR.exe", "winrar", "rar", "unrar"):
        _agregar_candidato(candidatos, vistos, "winrar", shutil.which(cmd))

    rutas_7z = [
        r"C:\Program Files\7-Zip\7z.exe",
        r"C:\Program Files\7-Zip\7zz.exe",
        r"C:\Program Files (x86)\7-Zip\7z.exe",
        r"C:\Program Files (x86)\7-Zip\7zz.exe",
        os.path.join(os.environ.get("PROGRAMFILES", ""), "7-Zip", "7z.exe"),
        os.path.join(os.environ.get("PROGRAMFILES(X86)", ""), "7-Zip", "7z.exe"),
    ]
    for ruta in rutas_7z:
        _agregar_candidato(candidatos, vistos, "7z", ruta)

    for cmd in ("7z", "7za", "7zr", "7zz", "7z.exe", "NanaZipC", "NanaZipC.exe"):
        _agregar_candidato(candidatos, vistos, "7z", shutil.which(cmd))

    # Windows 10/11 usually include bsdtar (C:\Windows\System32\tar.exe)
    for cmd in ("tar", "tar.exe"):
        _agregar_candidato(candidatos, vistos, "tar", shutil.which(cmd))
    _agregar_candidato(candidatos, vistos, "tar", r"C:\Windows\System32\tar.exe")

    return candidatos


def obtener_extractores():
    global _EXTRACTORES_CACHE
    if _EXTRACTORES_CACHE is None:
        _EXTRACTORES_CACHE = _detectar_extractores()
    return list(_EXTRACTORES_CACHE)


def detectar_extractor_rar():
    for tipo, ruta in obtener_extractores():
        if tipo in {"winrar", "7z", "tar"}:
            return tipo, ruta
    return (None, None)


def _ejecutar_comando(comando, timeout=180):
    try:
        resultado = subprocess.run(
            comando,
            capture_output=True,
            text=True,
            timeout=timeout,
            creationflags=CREATE_NO_WINDOW,
        )
    except subprocess.TimeoutExpired:
        return False, "timeout"
    except Exception as e:
        return False, str(e)

    if resultado.returncode == 0:
        return True, None

    salida = (resultado.stderr or resultado.stdout or "").strip()
    if salida:
        salida = salida.replace("\n", " ")
        return False, f"codigo {resultado.returncode}: {salida[:280]}"
    return False, f"codigo {resultado.returncode}"


def _extraer_con_herramienta(tipo, ejecutable, ruta_completa, carpeta_destino):
    destino = os.path.abspath(carpeta_destino)
    if tipo == "winrar":
        cmd = [ejecutable, "x", "-y", ruta_completa, destino + os.sep]
    elif tipo == "7z":
        cmd = [ejecutable, "x", "-y", f"-o{destino}", ruta_completa]
    elif tipo == "tar":
        cmd = [ejecutable, "-xf", ruta_completa, "-C", destino]
    else:
        return False, f"tipo no soportado: {tipo}"
    return _ejecutar_comando(cmd, timeout=300)


def _intentar_con_extractores(ruta_completa, carpeta_destino, tipos_permitidos):
    intentos = []
    for tipo, ejecutable in obtener_extractores():
        if tipo not in tipos_permitidos:
            continue
        ok, error = _extraer_con_herramienta(tipo, ejecutable, ruta_completa, carpeta_destino)
        if ok:
            return True, None
        intentos.append(f"{tipo} ({os.path.basename(ejecutable)}): {error}")

    if not intentos:
        tipos = ", ".join(sorted(tipos_permitidos))
        return False, f"No se detecto extractor compatible ({tipos})"

    return False, " ; ".join(intentos)


def _extraer_zip_nativo(ruta_completa, carpeta_destino):
    try:
        with zipfile.ZipFile(ruta_completa, "r") as zf:
            zf.extractall(carpeta_destino)
        return True, None
    except Exception as e:
        return False, f"zipfile: {e}"


def _extraer_tar_nativo(ruta_completa, carpeta_destino):
    try:
        with tarfile.open(ruta_completa, "r:*") as tar:
            tar.extractall(path=carpeta_destino)
        return True, None
    except Exception as e:
        return False, f"tarfile: {e}"


def extraer_comprimido(ruta_completa, carpeta_destino):
    if not _ruta_valida(ruta_completa):
        return False, "archivo no existe"

    os.makedirs(carpeta_destino, exist_ok=True)
    ruta_lower = ruta_completa.lower()

    if ruta_lower.endswith(".zip"):
        ok, error = _extraer_zip_nativo(ruta_completa, carpeta_destino)
        if ok:
            return True, None
        ok, error_ext = _intentar_con_extractores(ruta_completa, carpeta_destino, {"7z", "winrar", "tar"})
        if ok:
            return True, None
        if error_ext:
            return False, f"{error} ; {error_ext}"
        return False, error

    if ruta_lower.endswith(".7z"):
        errores = []
        if py7zr is not None:
            try:
                with py7zr.SevenZipFile(ruta_completa, mode="r") as z:
                    z.extractall(path=carpeta_destino)
                return True, None
            except Exception as e:
                errores.append(f"py7zr: {e}")

        ok, error = _intentar_con_extractores(ruta_completa, carpeta_destino, {"7z", "winrar", "tar"})
        if ok:
            return True, None
        if error:
            errores.append(error)
        return False, " ; ".join(errores) if errores else "No fue posible extraer 7z"

    if ruta_lower.endswith(".rar"):
        ok, error = _intentar_con_extractores(ruta_completa, carpeta_destino, {"winrar", "7z", "tar"})
        if ok:
            return True, None
        return False, error or "No fue posible extraer RAR"

    if ruta_lower.endswith(".tar") or ruta_lower.endswith(".tgz") or ruta_lower.endswith(".tar.gz"):
        ok, error = _extraer_tar_nativo(ruta_completa, carpeta_destino)
        if ok:
            return True, None
        ok, error_ext = _intentar_con_extractores(ruta_completa, carpeta_destino, {"tar", "7z", "winrar"})
        if ok:
            return True, None
        if error_ext:
            return False, f"{error} ; {error_ext}"
        return False, error

    return False, "Formato no soportado"
