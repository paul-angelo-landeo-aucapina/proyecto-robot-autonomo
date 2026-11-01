# Guía Operativa de Simulación en Gazebo Harmonic — Proyecto Robot Autónomo

Guía rápida y referencia técnica para ejecutar, visualizar y teleoperar la simulación física del **Proyecto Robot Autónomo (`proyecto-robot-autonomo`)** (tracción diferencial 2WD + 2 Omniwheels) en **Gazebo Harmonic (`gz-sim` $\ge 8.0$)** con soporte de aceleración por hardware bajo Linux.

---

## 1. Quick Path (Arranque Rápido)

1. **Ingresar a la Carpeta de Simulación y Lanzar la GUI:**
   ```bash
   cd hardware/mechanics/simulation
   ./launch_sim_gui.sh
   ```
2. **Ejecutar la Rutina de Patrullaje Autónomo (en otra terminal):**
   ```bash
   cd hardware/mechanics/simulation
   python3 autonomous_patrol.py
   ```
3. **Detener la Simulación:**
   ```bash
   pkill -f "gz sim"
   ```

---

## 2. Modos de Ejecución

| Modo | Comando | Caso de Uso |
|---|---|---|
| **A. Monolítico con GUI (Recomendado)** | `./launch_sim_gui.sh` | Visualización 3D interactiva en escritorio con aceleración GPU |
| **B. Servidor Desacoplado (Headless)** | `gz sim -s -r sumo_arena.sdf &` | Pruebas automatizadas, CI o control en segundo plano |
| **C. Visor 3D Cliente** | `gz sim -g` | Conectar o desconectar la ventana 3D al servidor activo en cualquier momento |
| **D. Rutina Autónoma** | `python3 autonomous_patrol.py` | Patrullaje en bucle continuo, negociación de obstáculos y giro de radio cero ($180^\circ$) |

---

## 3. Control Manual y Teleoperación por Tópicos

La simulación expone la interfaz estándar de robótica móvil a través de la capa de transporte de Gazebo (`gz-transport`):

| Acción | Comando de Terminal | Efecto en el Robot |
|---|---|---|
| **Avanzar recto** | `gz topic -t /cmd_vel -m gz.msgs.Twist -p "linear: {x: 0.35}"` | Marcha hacia adelante a $0.35\text{ m/s}$ ($1.26\text{ km/h}$) |
| **Giro en radio cero** | `gz topic -t /cmd_vel -m gz.msgs.Twist -p "angular: {z: 2.0}"` | Spin puro en el sitio sobre el centro de masa a $2.0\text{ rad/s}$ ($115^\circ\text{/s}$) |
| **Retroceder** | `gz topic -t /cmd_vel -m gz.msgs.Twist -p "linear: {x: -0.25}"` | Maniobra de retroceso a $0.25\text{ m/s}$ |
| **Parada de emergencia** | `gz topic -t /cmd_vel -m gz.msgs.Twist -p "linear: {x: 0.0}, angular: {z: 0.0}"` | Frenado inmediato de los motores |
| **Ver telemetría viva** | `gz topic -e -t /odometry` | Flujo continuo de posición ($X, Y, Z$) y orientación ($Q_w, Q_x, Q_y, Q_z$) |

---

## 4. Detalles del Modelo y Física Simulada

| Subsistema | Implementación | Parámetro Clave |
|---|---|---|
| **Tren Motriz Trasero** | 2 Motores DC 37D ($300\text{ RPM}$) con reductora metálica | $R = 32.5\text{ mm}$, trocha $260.0\text{ mm}$, fricción $\mu = 0.90$ |
| **Dirección Frontal** | 2 Omniwheels dobles de rodillos coplanares | $R = 32.5\text{ mm}$, batalla $L_{wb} = 260.0\text{ mm}$, fricción lateral reducida $\mu_2 = 0.02$ |
| **Mecanismo de Pesaje** | Junta prismática desacoplada en $Z$ (celda 5 kg) | Rigidez elástica $k = 50\text{ kN/m}$, amortiguamiento $c = 150\text{ N}\cdot\text{s/m}$ |
| **Carcasa Estructural** | Faldón perimetral + Tapa enteriza desmontable ($0.818\text{ kg}$) | Link `carcass_link` fijado a `base_link`, mallas STL y colisiones perimetrales |
| **Masa e Inercia** | $4.22\text{ kg}$ total con carrocería ($X_{CoM} = +11.8\text{ mm}$, $Z_{CoM} = 23.5\text{ mm}$) | Inercias calculadas: $I_{xx} = 0.0300, I_{yy} = 0.0458, I_{zz} = 0.0710\text{ kg}\cdot\text{m}^2$ |
| **Entorno de Pruebas** | [`sumo_arena.sdf`](sumo_arena.sdf) | Arena circular con obstáculos dinámicos calibrados (cilindro 1.2 kg y cubo 1.8 kg) |

---

## 5. Checklist de Verificación de Entorno

- [x] **Integridad SDFormat:** Los modelos [`robot_sumoso.sdf`](robot_sumoso.sdf) y [`sumo_arena.sdf`](sumo_arena.sdf) cumplen la especificación SDFormat 1.9+.
- [x] **Apoyo Coplanar:** Las 4 ruedas descansan de forma tangencial sobre el suelo en $Z=0$ sin oscilaciones numéricas.
- [x] **Plugin DiffDrive:** El plugin `gz::sim::systems::DiffDrive` responde a comandos en `/cmd_vel` y publica odometría en `/odometry`.
- [x] **Resolución de Recursos Portátil:** La variable de entorno `GZ_SIM_RESOURCE_PATH` configurada en `launch_sim_gui.sh` permite cargar las mallas STL y los submodelos de forma relativa.
