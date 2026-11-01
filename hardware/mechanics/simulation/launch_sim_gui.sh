#!/bin/bash
# ==============================================================================
# Script de Lanzamiento 3D para Robot Sumoso en Gazebo Harmonic
# Utiliza la GPU NVIDIA GeForce RTX 3050 bajo Arch Linux + Hyprland / Xwayland
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORLD="$DIR/sumo_arena.sdf"

echo "======================================================================"
echo "  INICIANDO SIMULACIÓN 3D: ROBOT SUMOSO EN GAZEBO HARMONIC"
echo "  GPU: NVIDIA GeForce RTX 3050 (Aceleración Hardware Activa)"
echo "  Arena: $WORLD"
echo "======================================================================"

# Verificar xhost si estuviera disponible para sockets X11
if command -v xhost &> /dev/null; then
    xhost +local:root 2>/dev/null || true
fi

# Lanzar Gazebo Sim con la escena cargada
gz sim -r "$WORLD" "$@"
