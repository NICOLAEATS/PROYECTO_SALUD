#!/usr/bin/env bash
# Desinstalador de Proyecto Salud
# Ejecutar: sudo bash uninstall.sh
set -e

echo "=== Desinstalando Proyecto Salud ==="

rm -rf /usr/share/proyecto-salud
rm -f /usr/bin/proyecto-salud
rm -f /usr/bin/proyecto-salud-update
rm -f /usr/share/applications/proyecto-salud.desktop

echo "=== Desinstalación completa ==="
