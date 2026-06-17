@echo off
title [DEV] Sistema de Monitoreo de Salud - Web
cd /d "%~dp0proyecto_salud_cusco_web"
if not exist "venv" (
    echo [1/2] Creando entorno virtual...
    py -3 -m venv venv
    echo [2/2] Instalando dependencias...
    call venv\Scripts\activate.bat
    pip install -q -r requirements.txt
) else (
    call venv\Scripts\activate.bat
)
echo.
echo === Modo Desarrollo ===
set FLASK_DEBUG=1
echo Servidor en http://localhost:5000
echo El servidor se recarga automaticamente al editar .py
echo (para CSS/JS/HTML solo recarga el navegador)
echo Ctrl+C para detener
echo.
python app.py
pause
