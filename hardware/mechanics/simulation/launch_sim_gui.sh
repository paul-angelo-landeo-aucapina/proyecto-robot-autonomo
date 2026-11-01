#!/bin/bash
# ==============================================================================
# Script de Lanzamiento 3D — Proyecto Robot Autónomo en Gazebo Harmonic
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORLD="$DIR/sumo_arena.sdf"

# Exportar la ruta del directorio local para que Gazebo resuelva modelos SDF y mallas
export GZ_SIM_RESOURCE_PATH="$DIR:$GZ_SIM_RESOURCE_PATH"

echo "======================================================================"
echo "  INICIANDO SIMULACIÓN 3D: PROYECTO ROBOT AUTÓNOMO EN GAZEBO HARMONIC"
echo "  Directorio de Simulación: $DIR"
echo "  Mundo: $WORLD"
echo "======================================================================"

# Habilitar xhost si estuviera disponible para sockets X11 / Xwayland
if command -v xhost &> /dev/null; then
    xhost +local:root 2>/dev/null || true
fi

# Lanzar Gazebo Sim con la escena cargada
gz sim -r "$WORLD" "$@"
