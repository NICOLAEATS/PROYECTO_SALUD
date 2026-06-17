#!/usr/bin/env bash
# Instalador de Proyecto Salud
# Ejecutar: sudo bash install.sh
set -e

APP_DIR="/usr/share/proyecto-salud"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Instalando Proyecto Salud ==="

# 1. Create directories
install -d "$APP_DIR"
install -d /usr/bin

# 2. Copy app files
echo "-> Copiando archivos..."
cp -r "$PROJECT_DIR/proyecto_salud_cusco_web/"* "$APP_DIR/"
cp -r "$PROJECT_DIR/scripts_python" "$APP_DIR/"
cp -r "$PROJECT_DIR/scripts_sql" "$APP_DIR/"
cp "$PROJECT_DIR/db_config.py" "$APP_DIR/"
cp "$PROJECT_DIR/AGENTS.md" "$APP_DIR/"

# 3. Create virtualenv if not exists
if [ ! -d "$APP_DIR/venv" ]; then
    echo "-> Creando entorno virtual..."
    python -m venv "$APP_DIR/venv"
fi

# 4. Install Python dependencies
echo "-> Instalando dependencias..."
"$APP_DIR/venv/bin/pip" install --upgrade pip -q
"$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt" -q

# 5. Install wrapper scripts
echo "-> Instalando comandos..."
install -Dm755 "$SCRIPT_DIR/proyecto-salud" /usr/bin/proyecto-salud
install -Dm755 "$SCRIPT_DIR/proyecto-salud-update" /usr/bin/proyecto-salud-update

# 6. Install desktop entry
echo "-> Instalando entrada de menú..."
install -Dm644 "$SCRIPT_DIR/proyecto-salud.desktop" \
    /usr/share/applications/proyecto-salud.desktop

# 7. Set permissions
chown -R root:root "$APP_DIR"
chmod -R o+rX "$APP_DIR"

echo ""
echo "=== Instalación completa ==="
echo "Ejecute 'proyecto-salud' para iniciar en http://localhost:5000"
echo "Ejecute 'sudo proyecto-salud-update' para actualizar"
echo ""
