# Guía Operativa de Simulación en Gazebo Harmonic (Robot Sumoso)

Guía rápida y referencia técnica para ejecutar, visualizar y teleoperar la simulación física del **Robot Sumoso** (Opción D: 2WD + 2 Omniwheels) en **Gazebo Harmonic (gz-sim 8.11.0)** con aceleración por hardware **NVIDIA GeForce RTX 3050** bajo **Arch Linux y Hyprland (Wayland / Xwayland)**.

---

## Quick Path (Arranque Rápido)

1. **Lanzar Simulación 3D Directa:**
   ```bash
   cd /home/paul/Documents/workfiles/RobotSumoso && ./launch_sim_gui.sh
   ```
2. **Ejecutar Rutina Autónoma (Opcional, en otra terminal):**
   ```bash
   /home/paul/Documents/workfiles/RobotSumoso/autonomous_patrol.py
   ```
3. **Detener Todo:**
   ```bash
   pkill -f "gz sim"
   ```

---

## Modos de Ejecución

| Modo | Comando | Caso de Uso |
|---|---|---|
| **A. Monolítico con GUI (Recomendado)** | `./launch_sim_gui.sh` | Visualización 3D interactiva en escritorio Hyprland con aceleración GPU |
| **B. Servidor Desacoplado (Headless)** | `gz sim -s -r sumo_arena.sdf &` | Pruebas automatizadas, CI o control en segundo plano por agentes IA |
| **C. Visor 3D Cliente** | `gz sim -g` | Conectar o desconectar la ventana 3D al servidor activo en cualquier momento |
| **D. Rutina Autónoma** | `./autonomous_patrol.py` | Patrullaje en bucle continuo, empuje de obstáculos y giro de radio cero ($180^\circ$) |

---

## Control Manual y Teleoperación

| Acción | Comando de Terminal | Efecto en el Robot |
|---|---|---|
| **Avanzar recto** | `gz topic -t /cmd_vel -m gz.msgs.Twist -p "linear: {x: 0.35}"` | Marcha hacia adelante a $0.35\text{ m/s}$ ($1.26\text{ km/h}$) |
| **Giro en radio cero** | `gz topic -t /cmd_vel -m gz.msgs.Twist -p "angular: {z: 2.0}"` | Spin puro en el sitio sobre el CoM a $2.0\text{ rad/s}$ ($115^\circ\text{/s}$) |
| **Retroceder** | `gz topic -t /cmd_vel -m gz.msgs.Twist -p "linear: {x: -0.25}"` | Maniobra de retroceso a $0.25\text{ m/s}$ |
| **Parada de emergencia** | `gz topic -t /cmd_vel -m gz.msgs.Twist -p "linear: {x: 0.0}, angular: {z: 0.0}"` | Frenado inmediato de motores 37D |
| **Ver telemetría viva** | `gz topic -e -t /odometry` | Flujo continuo de posición ($X, Y, Z$) y orientación ($Q_w, Q_x, Q_y, Q_z$) |

---

## Detalles del Modelo y Hardware

| Subsistema | Implementación | Parámetro Clave |
|---|---|---|
| **GPU Acceleration** | NVIDIA Container Toolkit + CDI (`/etc/cdi/nvidia.yaml`) | Driver 615+, CUDA 13.4, `--gpus all`, PRIME offloading activo |
| **Tren Motriz Trasero** | 2 Motores DC 37D ($300\text{ RPM}$) con reductora metálica | $R = 32.5\text{ mm}$, trocha $260.0\text{ mm}$, fricción $\mu = 0.90$ |
| **Dirección Frontal** | 2 Omniwheels dobles de rodillos coplanares | $R = 32.5\text{ mm}$, batalla $L_{wb} = 260.0\text{ mm}$, fricción lateral $\mu_2 = 0.02$ |
| **Mecanismo de Pesaje** | Junta prismática desacoplada en $Z$ (celda 5 kg) | Rigidez elástica $k = 50\text{ kN/m}$, amortiguamiento $c = 150\text{ N}\cdot\text{s/m}$ |
| **Carcasa Estructural** | Faldón perimetral + Tapa enteriza desmontable ($0.818\text{ kg}$) | Link `carcass_link` fijado a `base_link`, mallas STL y colisiones perimetrales |
| **Masa e Inercia** | $4.22\text{ kg}$ total con carrocería ($X_{CoM} = +11.8\text{ mm}$, $Z_{CoM} = 23.5\text{ mm}$) | Inercias efectivas certificadas en Módulo 14 |
| **Entorno / Arena** | [`sumo_arena.sdf`](file:///home/paul/Documents/workfiles/RobotSumoso/sumo_arena.sdf) | Dohyo $\varnothing 2.2\text{ m}$, obstáculo cilindro $1.2\text{ kg}$, obstáculo cubo $1.8\text{ kg}$ |

---

## Checklist de Verificación

- [x] **Detección GPU:** `nvidia-smi` reporta la GPU NVIDIA GeForce RTX 3050 Laptop activa.
- [x] **CLI Wrapper:** `/home/paul/.local/bin/gz` ejecuta Gazebo Harmonic 8.11.0 con acceso a GPU y sockets de Hyprland.
- [x] **Integridad SDFormat:** `gz sdf -k sumo_arena.sdf` y `robot_sumoso.sdf` devuelven `Valid.` sin errores.
- [x] **Apoyo Coplanar:** Las 4 ruedas descansan de forma estable sobre el tatami en $Z=0$ sin vibraciones numéricas.
- [x] **Canal de Control:** El plugin `gz::sim::systems::DiffDrive` responde a comandos en `/cmd_vel` y publica odometría en `/odometry`.

---

## Siguiente Paso

- Para continuar el proyecto, avanzar hacia el **Chasis Superior y Cerramiento** (carcasa protectora, fijación de pantallas OLED SSD1306 y micrófonos MEMS) o consultar la memoria técnica unificada en [`walkthrough.md`](file:///home/paul/Documents/workfiles/RobotSumoso/walkthrough.md).
