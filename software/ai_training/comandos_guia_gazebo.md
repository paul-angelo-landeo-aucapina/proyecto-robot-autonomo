# Guía Maestra de Comandos y Flujo de Trabajo en Gazebo (Simulación y Entrenamiento)

Esta guía contiene todos los comandos, herramientas y procedimientos necesarios para trabajar con **Gazebo** (el entorno estándar de simulación en robótica física y entrenamiento de algoritmos de navegación para el robot móvil de este proyecto).

---

## 1. Instalación y Preparación del Entorno

En robótica profesional, Gazebo se ejecuta habitualmente sobre **Ubuntu (nativo o WSL2 en Windows)** junto con **ROS 2 (Humble / Iron)**:

```bash
# 1. Actualizar repositorios del sistema
sudo apt update && sudo apt upgrade -y

# 2. Instalar paquetes de Gazebo Classic y dependencias de ROS 2
sudo apt install ros-humble-gazebo-ros-pkgs ros-humble-gazebo-ros2-control -y

# 3. (Opcional) Instalar la nueva versión Gazebo Sim (anteriormente Ignition Gazebo)
sudo apt install ros-humble-ros-gz -y

# 4. Instalar herramientas de teleoperación y utilidades de sensores
sudo apt install ros-humble-teleop-twist-keyboard ros-humble-joint-state-publisher -y
```

---

## 2. Comandos Esenciales de la Línea de Comandos (CLI)

### A. Lanzamiento y Control de Gazebo (Classic)

| Acción | Comando | Descripción |
| :--- | :--- | :--- |
| **Iniciar Completo** | `gazebo` | Lanza el servidor de física (`gzserver`) + la interfaz gráfica (`gzclient`). |
| **Cargar Mundo Específico** | `gazebo laberinto_obstaculos.world` | Abre el simulador directamente con el escenario de prueba. |
| **Modo Headless (Sin GUI)** | `gzserver laberinto_obstaculos.world` | **Clave para entrenamiento de IA / RL**. Ahorra 80% de GPU/CPU y corre a máxima velocidad. |
| **Abrir solo la GUI** | `gzclient` | Se conecta a un servidor `gzserver` que ya esté corriendo en segundo plano. |
| **Pausar la Física** | `gz world -p 1` | Pausa la simulación física (útil en pasos discretos de entrenamiento). |
| **Reanudar la Física** | `gz world -p 0` | Reanuda el cálculo de física en tiempo real. |
| **Reiniciar Tiempo del Mundo** | `gz world -r` | Reinicia el reloj de simulación a `00:00:00`. |

---

### B. Comandos en la Nueva Generación (Gazebo Sim / Ignition)

```bash
# Ejecutar simulación interactiva con mundo
gz sim -r laberinto_obstaculos.sdf

# Ejecutar en modo servidor headless sin interfaz (para entrenamiento masivo)
gz sim -s -r laberinto_obstaculos.sdf

# Listar tópicos activos en Gazebo Sim
gz topic -l

# Ver datos de un sensor en tiempo real
gz topic -e -t /imu/data

# Ver información detallada de un tópico
gz topic -i -t /cmd_vel
```

---

## 3. Comandos de Inspección e Interacción con ROS 2

Cuando el robot diferencial está corriendo en el simulador:

### 1. Listar tópicos publicados por los sensores simulados:
```bash
ros2 topic list
```
*Salida esperada:*
```
/cmd_vel
/imu/data
/distance/left
/distance/right
/odom
/tf
```

### 2. Monitorear los sensores ToF (VL53L0X simulados):
```bash
# Ver lecturas de distancia frontal izquierda
ros2 topic echo /distance/left

# Ver lecturas de distancia frontal derecha
ros2 topic echo /distance/right

# Comprobar la frecuencia de publicación (debe ser >= 30-50 Hz)
ros2 topic hz /distance/left
```

### 3. Monitorear el sensor inercial MPU6050:
```bash
# Leer velocidad angular en eje Z y aceleración
ros2 topic echo /imu/data

# Comprobar que publique a 100 Hz (según la especificación técnica)
ros2 topic hz /imu/data
```

### 4. Teleoperar el robot manualmente con el teclado:
```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```
*Teclas de control:*
- `i`: Avanzar
- `j`: Girar izquierda sobre su propio eje (pivote)
- `l`: Girar derecha sobre su propio eje (pivote)
- `,`: Retroceder
- `k`: Parada de emergencia activa

---

## 4. Flujo de Entrenamiento (Reinforcement Learning / Machine Learning)

Para entrenar una política neuronal o un controlador difuso en Gazebo:

1. **Paso 1 - Lanzar en segundo plano (Headless)**:
   ```bash
   gzserver laberinto_obstaculos.world -u --physics-engine ode &
   ```
2. **Paso 2 - Ejecutar el script de entrenamiento en Python**:
   ```bash
   python3 train_evasion_rl.py --episodes 1000 --timesteps 500
   ```
3. **Paso 3 - Visualizar el progreso**:
   ```bash
   tensorboard --logdir ./runs/
   ```
4. **Paso 4 - Exportar la política entrenada**:
   Los pesos o ganancias óptimas ($K_p, K_i$, umbrales de evasión) se transfieren directamente a los scripts de producción en el ESP32 (`robot_autonomo.ino` o `main.py`).
