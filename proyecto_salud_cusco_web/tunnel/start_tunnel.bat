@echo off
title Proyecto Salud - Tunnel Cloudflare
cd /d "%~dp0.."

echo ============================================
echo  Proyecto Salud - Tunnel Publico
echo ============================================
echo.
echo  PASO 1: Iniciando servidor Flask...
echo.

:: Verificar si el servidor ya esta corriendo
curl -s http://127.0.0.1:5000 >nul 2>&1
if %errorlevel% equ 0 (
    echo  [OK] Servidor Flask ya esta corriendo
) else (
    echo  Iniciando servidor Flask...
    start /B "" "%CD%\venv\Scripts\python.exe" app.py
    timeout /t 5 /nobreak >nul
)

echo.
echo  PASO 2: Descargando cloudflared (si es necesario)...
echo.

if not exist "%CD%\tunnel\cloudflared.exe" (
    echo  Descargando cloudflared...
    curl -sL -o "%CD%\tunnel\cloudflared.exe" "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
    if !errorlevel! neq 0 (
        echo  [ERROR] No se pudo descargar cloudflared
        echo  Descargalo manualmente de: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/
        pause
        exit /b 1
    )
    echo  [OK] cloudflared descargado
)

echo.
echo  PASO 3: Creando tunnel publico...
echo.
echo  Esperando URL publica (esto puede tomar unos segundos)...
echo.

"%CD%\tunnel\cloudflared.exe" tunnel --url http://127.0.0.1:5000

if %errorlevel% neq 0 (
    echo.
    echo  [ERROR] El tunnel se cerro inesperadamente
    pause
)
