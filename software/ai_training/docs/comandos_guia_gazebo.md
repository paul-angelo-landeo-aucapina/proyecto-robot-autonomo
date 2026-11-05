# Guía Maestra de Simulación y Comandos Gazebo (Linux y Windows)

Esta guía centraliza la operación del entorno de simulación física (Gazebo Harmonic 8.11) y control robótico (ROS 2 Jazzy).

---

## 🗺️ Índice de Documentación Modular

Para mantener máxima precisión y evitar sobrecarga cognitiva, la documentación está dividida por objetivos:

1. **[Runbook de Diagnóstico y Resolución de Problemas](guia_resolucion_problemas.md)**:
   *Matriz de solución inmediata: "Si ocurre el error X, ejecuta el comando Y" (Docker socket, rclpy, tensorboard, modelos).*
2. **[Guía de Entrenamiento de IA y Reinforcement Learning](guia_entrenamiento_ia.md)**:
   *Flujo de Deep Q-Network con PyTorch + CUDA, entrenamiento online en Gazebo y exportación al ESP32.*
3. **[Simulador Visual Autónomo para Windows](../tools/simulador_visual_windows.py)**:
   *Script nativo en Python (sin Docker ni WSL) para validar evasión ToF y frenado en Windows.*

---

## 🚀 Inicio Rápido (Quickstart)

### En Linux (Arch / Ubuntu)
```bash
# 1. Asegurar socket de Docker activo (se activa solo una vez)
sudo systemctl enable --now docker.socket

# 2. Navegar al directorio de forma portable
cd software/ai_training

# 3. Lanzar simulación gráfica 3D
gz sim -r worlds/laberinto_obstaculos.world

# 4. O lanzar en modo servidor sin GUI para pruebas automáticas
gz sim -s -r worlds/laberinto_obstaculos.world
```

### En Windows 10 / 11 (WSL2 con WSLg - Recomendado)
```bash
# Abrir terminal WSL2 y ejecutar directamente:
cd software/ai_training
gz sim -r worlds/laberinto_obstaculos.world
```

### En Windows (PowerShell con Docker Desktop - Modo Headless)
```powershell
Set-Location software/ai_training
docker run --rm -it -v "${PWD}:/workspace" -w /workspace osrf/ros:jazzy-simulation gz sim -s -r worlds/laberinto_obstaculos.world
```

---

## 📋 Comandos Esenciales de Teleoperación y Movimiento

Con la simulación en marcha, interactúa desde otra terminal:

### 1. Inyectar Comandos de Velocidad Directos (`/cmd_vel`)

| Maniobra | Comando `gz topic` |
| :--- | :--- |
| **Avanzar recto (0.20 m/s)** | `gz topic -t "/cmd_vel" -m gz.msgs.Twist -p "linear: {x: 0.2, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}"` |
| **Giro en el eje (+90°/s)** | `gz topic -t "/cmd_vel" -m gz.msgs.Twist -p "linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 1.57}"` |
| **Giro en el eje (-90°/s)** | `gz topic -t "/cmd_vel" -m gz.msgs.Twist -p "linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: -1.57}"` |
| **Parada activa de emergencia** | `gz topic -t "/cmd_vel" -m gz.msgs.Twist -p "linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}"` |

### 2. Monitoreo de Sensores
```bash
# Ver lectura inercial MPU6050
gz topic -e -t /imu

# Listar todos los canales activos
gz topic -l
```

### 3. Control Manual por Teclado (Teleop ROS 2)
- En Linux:
  ```bash
  ros2 run teleop_twist_keyboard teleop_twist_keyboard
  ```
- En Windows (PowerShell):
  ```powershell
  docker run --rm -it --net=host osrf/ros:jazzy-simulation ros2 run teleop_twist_keyboard teleop_twist_keyboard
  ```

---

## 🛠️ Si ocurre un Problema

Consulta directamente el runbook:
👉 **[Runbook de Diagnóstico y Resolución de Problemas](guia_resolucion_problemas.md)**
Contiene la tabla de decisión rápida y los comandos exactos de reparación para fallos de sockets, dependencias de Python, display y procesos bloqueados.
