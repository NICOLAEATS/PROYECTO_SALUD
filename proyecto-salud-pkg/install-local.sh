#!/usr/bin/env bash
# Instalador de Proyecto Salud (usuario local, sin sudo)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/proyecto-salud"
DESKTOP_DIR="${HOME}/.local/share/applications"

echo "=== Instalando Proyecto Salud (local) ==="

# Create directories
mkdir -p "$BIN_DIR" "$APP_DIR" "$DESKTOP_DIR"

# Copy app files
echo "-> Copiando archivos..."
cp -r "$PROJECT_DIR/proyecto_salud_cusco_web/"* "$APP_DIR/"
cp -r "$PROJECT_DIR/scripts_python" "$APP_DIR/"
cp -r "$PROJECT_DIR/scripts_sql" "$APP_DIR/"
cp "$PROJECT_DIR/db_config.py" "$APP_DIR/"
cp "$PROJECT_DIR/AGENTS.md" "$APP_DIR/"

# Create virtualenv if not exists
if [ ! -d "$APP_DIR/venv" ]; then
    echo "-> Creando entorno virtual..."
    python -m venv "$APP_DIR/venv"
fi

# Install Python dependencies
echo "-> Instalando dependencias..."
"$APP_DIR/venv/bin/pip" install --upgrade pip -q
"$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt" -q

# Install wrapper script (user version with local path)
echo "-> Instalando comando 'proyecto-salud'..."
cat > "$BIN_DIR/proyecto-salud" << 'WRAPPER'
#!/usr/bin/env bash
set -e
APP_DIR="${HOME}/.local/share/proyecto-salud"
VENV_DIR="${APP_DIR}/venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Error: Entorno virtual no encontrado."
    echo "Ejecute ~/.local/share/proyecto-salud/install-local.sh para instalar."
    exit 1
fi
export PROYECTO_SALUD_ROOT="$APP_DIR"
cd "$APP_DIR"
exec "$VENV_DIR/bin/python" app.py "$@"
WRAPPER
chmod +x "$BIN_DIR/proyecto-salud"

# Install desktop entry (user-local)
echo "-> Instalando entrada de menú..."
cat > "$DESKTOP_DIR/proyecto-salud.desktop" << DESKTOP
[Desktop Entry]
Name=Proyecto Salud
Comment=Sistema de Información Gerencial Geoespacial para vigilancia epidemiológica
Exec=${BIN_DIR}/proyecto-salud
Terminal=true
Type=Application
Categories=Science;Medical;
StartupNotify=true
DESKTOP

echo ""
echo "=== Instalación local completa ==="
echo ""
echo "Asegúrese de tener ${BIN_DIR} en su PATH."
echo "  Agregue esta línea a ~/.bashrc o ~/.config/fish/config.fish:"
echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
echo "Ejecute 'proyecto-salud' para iniciar en http://localhost:5000"
echo "Para actualizar: cd '${PROJECT_DIR}' && git pull && ${APP_DIR}/venv/bin/pip install -r ${APP_DIR}/requirements.txt"
echo ""
