# Runbook de Diagnóstico y Resolución de Problemas (Troubleshooting)

Este documento es una guía operacional directa. Si encuentras un fallo o código de error, busca el síntoma y ejecuta el comando de solución correspondiente.

---

## Matriz Rápida de Diagnóstico ("Si ocurre X, corre Y")

| Error / Mensaje en Terminal | Causa Raíz | Comando de Diagnóstico | Comando de Solución Inmediata |
| :--- | :--- | :--- | :--- |
| `dial unix /var/run/docker.sock: connect: no such file or directory` | Socket de Docker inactivo en el host. | `systemctl is-active docker` | `sudo systemctl enable --now docker.socket` |
| `Unable to find uri[model://sun]` o `[model://ground_plane]` | Mundo con sintaxis vieja de Gazebo Classic. | `gz sdf -k <archivo.world>` | Usar el mundo migrado a SDF 1.8 nativo (`laberinto_obstaculos.world`) |
| `ModuleNotFoundError: No module named 'rclpy'` | Script de ROS 2 ejecutado con el Python del host. | `which ros2-python` | `ros2-python <script.py>` |
| `command not found: tensorboard` | Entorno virtual de IA no activado en la shell. | `which tensorboard` | `source .venv/bin/activate` (o `~/.local/bin/tensorboard`) |
| `ModuleNotFoundError: No module named 'torch'` | PyTorch no cargado en la sesión de terminal. | `python -c "import torch"` | `source .venv/bin/activate` |
| Simulación consume 100% CPU o pantalla negra en Wayland | Interfaz gráfica intentando abrir en compositor no compatible. | `echo $XDG_SESSION_TYPE` | Usar modo servidor headless: `gz sim -s -r <archivo.world>` |
| Procesos zombis de Gazebo corriendo de fondo | Instancias previas no cerradas limpiamente. | `pgrep -a "gz sim"` | `pkill -f "gz sim"` |
| `command not found: gazebo` | Intento de invocar binario deprecado de Gazebo Classic. | `which gz` | Usar la CLI moderna: `gz sim -r <archivo.world>` |

---

## Procedimientos Detallados Paso a Paso

### 1. Error de Socket Docker (`/var/run/docker.sock`)
- **Síntoma**:
  ```text
  failed to connect to the docker API at unix:///var/run/docker.sock; check if the path is correct and if the daemon is running
  ```
- **Paso 1 (Comprobar estado)**:
  ```bash
  systemctl status docker.socket
  ```
- **Paso 2 (Solución en Linux)**:
  ```bash
  sudo systemctl enable --now docker.socket
  ```
- **Paso 3 (Solución en Windows)**:
  Asegúrate de que **Docker Desktop** esté abierto y el motor WSL2 iniciado.

---

### 2. Error de Modelos Faltantes (`model://sun` / `model://ground_plane`)
- **Síntoma**:
  ```text
  [Err] [Server.cc:86] Error Code 14: Msg: Unable to find uri[model://sun]
  [Err] [Server.cc:86] Error Code 14: Msg: Unable to find uri[model://ground_plane]
  ```
- **Causa**: Gazebo Harmonic no incluye modelos de Gazebo Classic por defecto si no hay conexión a Fuel.
- **Solución**:
  Verifica que el archivo `.world` utilice etiquetas nativas de SDF 1.8:
  ```bash
  gz sdf -k worlds/laberinto_obstaculos.world
  ```
  *Salida esperada:*
  ```text
  Valid.
  ```

---

### 3. Error `No module named 'rclpy'`
- **Síntoma**:
  ```text
  Traceback (most recent call last):
    File "train_evasion_rl.py", line 16, in <module>
      import rclpy
  ModuleNotFoundError: No module named 'rclpy'
  ```
- **Causa**: `rclpy` está instalado dentro del contenedor `osrf/ros:jazzy-simulation`, no en el Python base de tu sistema operativo.
- **Solución en Linux**:
  Ejecutar el script usando el wrapper preconfigurado:
  ```bash
  ros2-python train_evasion_rl.py --episodes 1000 --timesteps 500
  ```
- **Solución en Windows (PowerShell)**:
  ```powershell
  docker run --rm -it --net=host -v "${PWD}:/workspace" -w /workspace osrf/ros:jazzy-simulation python3 train_evasion_rl.py --episodes 1000 --timesteps 500
  ```

---

### 4. Error `command not found: tensorboard` o `No module named 'torch'`
- **Síntoma**: La consola indica que no reconoce el comando o falla al importar PyTorch.
- **Causa**: Las dependencias de aprendizaje profundo están encapsuladas en el entorno virtual `.venv` para no contaminar el sistema.
- **Solución en Linux**:
  ```bash
  # 1. Activar el entorno virtual del proyecto
  source .venv/bin/activate

  # 2. Verificar disponibilidad de PyTorch y GPU
  python -c "import torch; print('CUDA disponible:', torch.cuda.is_available())"

  # 3. Lanzar TensorBoard
  tensorboard --logdir ./runs/
  ```
- **Solución en Windows**:
  ```cmd
  # En CMD / PowerShell
  .venv\Scripts\activate
  tensorboard --logdir ./runs/
  ```

---

### 5. Detención de Procesos Colgados o Zombis
- **Síntoma**: Gazebo indica que el puerto o la simulación ya están en uso, o la GPU no libera memoria.
- **Solución en Linux**:
  ```bash
  pkill -9 -f "gz sim"
  ```
- **Solución en Windows (PowerShell)**:
  ```powershell
  Get-Process | Where-Object {$_.ProcessName -like "*gz*"} | Stop-Process -Force
  docker stop $(docker ps -q --filter ancestor=osrf/ros:jazzy-simulation)
  ```
