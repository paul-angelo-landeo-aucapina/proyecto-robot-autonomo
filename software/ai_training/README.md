# Módulo de Simulación y Entrenamiento de IA (`software/ai_training/`)

Este módulo contiene el entorno de simulación física en **Gazebo Harmonic 8.11**, integración con **ROS 2 Jazzy**, algoritmos de aprendizaje por refuerzo (**Deep Q-Network / PyTorch**) y herramientas de exportación de políticas para el robot autónomo diferencial.

---

## 📁 Estructura del Directorio

```text
software/ai_training/
├── README.md               <- Índice general del módulo y mapa de carpetas
├── requirements.txt        <- Dependencias de Python (PyTorch con CUDA, TensorBoard, NumPy, SciPy)
│
├── docs/                   <- Documentación técnica y runbooks operacionales
│   ├── comandos_guia_gazebo.md      <- Cheat sheet de comandos CLI para Gazebo y ROS 2
│   ├── guia_resolucion_problemas.md <- Runbook de resolución ("Si ocurre X, corre Y")
│   └── guia_entrenamiento_ia.md     <- Metodología y pipelines de entrenamiento RL
│
├── worlds/                 <- Escenarios de simulación (SDF 1.8 nativo)
│   ├── laberinto_obstaculos.world   <- Recinto cerrado con obstáculos para evasión ToF
│   ├── pista_rampa_y_plano.world    <- Pista con inclinación de 12.7° para tracción y balance
│   └── piso_plano_entrenamiento.world
│
├── models/                 <- Definición cinemática y física del robot
│   └── robot_diferencial.urdf.xacro <- Chasis 2WD + rueda loca, plugins DiffDrive e IMU
│
├── launch/                 <- Scripts de lanzamiento para ROS 2
│   ├── launch_simulacion.launch.py
│   └── launch_rampa_y_plano.launch.py
│
├── training/               <- Algoritmos de aprendizaje por refuerzo y control
│   ├── train_point_to_point_rl.py     <- DQN PyTorch acelerado por GPU (NVIDIA CUDA)
│   ├── train_evasion_rl.py            <- Evasión reactiva ToF mediante nodos ROS 2
│   ├── entrenamiento_gazebo_online.py <- Sintonización de ganancias online en Gazebo
│   ├── entrenar_robot_cmd.py          <- Optimización paramétrica rápida por consola
│   └── controlador_navegacion_y_entrenamiento.py
│
├── tools/                  <- Herramientas visuales y control interactivo
│   ├── simulador_visual_windows.py    <- Simulador gráfico 2D/3D autónomo (Tkinter)
│   ├── enviar_comando.py              <- Emisor de comandos en tiempo real
│   └── comando_activo.json            <- Buffer IPC compartido
│
└── policies/               <- Parámetros entrenados listos para producción
    ├── politica_entrenada_robot.json  <- Parámetros óptimos en formato JSON
    └── politica_optima_esp32.h        <- Header C++ para el firmware del ESP32
```

---

## 🧭 Navegación Portable y Trabajo Colaborativo (Git Safe)

Para garantizar que los scripts y comandos funcionen de forma idéntica en cualquier computadora (Linux, macOS, Windows) sin exponer rutas absolutas locales (`/home/usuario/...` o `C:\Users\usuario\...`) en los commits de Git:

### Regla de Oro: Ejecutar siempre desde la raíz del repositorio o usando rutas relativas

#### 1. En Linux / macOS / WSL (Bash / Zsh):
```bash
# Cambiar al directorio de forma portable
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/software/ai_training"

# O si ya estás en la raíz del proyecto:
cd software/ai_training
```

#### 2. En Windows (PowerShell):
```powershell
# Cambiar al directorio relativo desde la raíz del repositorio:
Set-Location software/ai_training
```

#### 3. En Windows (CMD):
```cmd
cd software\ai_training
```

---

## 🚀 Inicio Rápido de Simulación

| Acción | Comando Linux (Bash) | Comando Windows (PowerShell con Docker) |
| :--- | :--- | :--- |
| **Simulación 3D (GUI)** | `gz sim -r worlds/laberinto_obstaculos.world` | Requiere WSL2 + WSLg: `gz sim -r worlds/laberinto_obstaculos.world` |
| **Servidor Headless (IA / CI)** | `gz sim -s -r worlds/laberinto_obstaculos.world` | `docker run --rm -it -v "${PWD}:/workspace" -w /workspace osrf/ros:jazzy-simulation gz sim -s -r worlds/laberinto_obstaculos.world` |
| **Entrenar DQN (PyTorch GPU)** | `source ../../.venv/bin/activate && python training/train_point_to_point_rl.py` | `..\..\.venv\Scripts\activate; python training\train_point_to_point_rl.py` |
| **Entrenar con ROS 2** | `ros2-python training/train_evasion_rl.py` | `docker run --rm -it --net=host -v "${PWD}:/workspace" -w /workspace osrf/ros:jazzy-simulation python3 training/train_evasion_rl.py` |
| **Simulador Ligero (Sin Docker)**| `python tools/simulador_visual_windows.py` | `python tools\simulador_visual_windows.py` |

---

## 📖 Documentación Relacionada

- [Manual de Instalación y Arquitectura Interna](docs/guia_instalacion_y_arquitectura.md)
- [Cheat Sheet de Comandos CLI](docs/comandos_guia_gazebo.md)
- [Runbook de Resolución de Problemas ("Si ocurre X, corre Y")](docs/guia_resolucion_problemas.md)
- [Guía de Metodología de Inteligencia Artificial](docs/guia_entrenamiento_ia.md)
