# Guía Maestra: Simulación, Comandos de Movimiento y Entrenamiento en Gazebo

Esta guía contiene la totalidad de los comandos, códigos y procedimientos para operar y entrenar en **Gazebo** el robot móvil diferencial autónomo (2WD + rueda loca posterior, ESP32, MPU6050, 2x VL53L0X y driver TB6612FNG), cumpliendo los requerimientos técnicos del proyecto.

---

## 1. Arquitectura del Escenario de Pruebas

El mundo de simulación [`pista_rampa_y_plano.world`](file:///d:/PROYECTO%20DE%20ROB%C3%93TICA/gazebo/pista_rampa_y_plano.world) incluye:
1. **Zona de Piso Plano Inicial**: Arranque en el **Punto A** $(X=0.0, Y=0.0)$ con obstáculos de prueba para evaluar la detección a $<180\text{ mm}$ y paradas de emergencia a $<80\text{ mm}$.
2. **Rampa de Subida (Incline)**: Pendiente de $12.7^\circ$ ($0.22\text{ rad}$) desde $X=2.0\text{ m}$ hasta $X=4.0\text{ m}$, ascendiendo hasta $Z=0.45\text{ m}$ con fricción ODE realista ($\mu=1.2$).
3. **Meseta Superior con Obstáculo**: Plataforma elevada para evaluar evasión reactiva sobre terreno alto.
4. **Rampa de Bajada (Decline)**: Descenso controlado desde $X=5.2\text{ m}$ hasta $X=7.2\text{ m}$, donde la gravedad tiende a acelerar al robot y generar derrapes.
5. **Zona de Piso Plano Final**: Meta en el **Punto B** $(X=8.2, Y=0.0)$ identificada con un marcador visual azul.

---

## 2. Comandos para Lanzar la Simulación en Gazebo

### Opción A: Lanzamiento Gráfico Completo (Recomendado para visualización)
Abre la consola (WSL2 o Ubuntu nativo) en el directorio de Gazebo y ejecuta:

```bash
cd "D:/PROYECTO DE ROBÓTICA/gazebo"
ros2 launch launch_rampa_y_plano.launch.py
```
*Esto iniciará Gazebo, cargará el mundo con la rampa y el piso plano, spawneará el robot en $(0, 0, 0.05)$ e inicializará los tópicos de los sensores.*

### Opción B: Modo Servidor Headless (Para Entrenamiento Acelerado de IA/RL)
Sin interfaz gráfica, reduce el consumo de CPU/GPU en un 80% y corre la física al máximo factor de tiempo real:

```bash
gzserver pista_rampa_y_plano.world -u --physics-engine ode
```

Para abrir la interfaz gráfica conectándose al servidor en cualquier momento:
```bash
gzclient
```

---

## 3. Comandos de Movimiento Directo del Robot Carrito (`/cmd_vel`)

Puedes enviar comandos de movimiento individuales en tiempo real mediante `ros2 topic pub` para verificar el comportamiento de los actuadores:

### 1. Arrancar y Avanzar Recto en Piso Plano (Heading Hold)
Avanza a $0.25\text{ m/s}$ ($250\text{ mm/s}$):
```bash
ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.25, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}"
```

### 2. Subida de Rampa (Mayor empuje de par motor TT)
Avanza a $0.38\text{ m/s}$ con mayor empuje para vencer la inclinación de $12.7^\circ$:
```bash
ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.38, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}"
```

### 3. Bajada de Rampa Controlada (Retención y Anti-Deslizamiento)
Velocidad controlada a $0.15\text{ m/s}$ para evitar que la gravedad provoque derrapes:
```bash
ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.15, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}"
```

### 4. Giro Pivote Calibrado a la Izquierda ($+90^\circ$ sobre su propio eje)
Gira en su propio eje con $v = 0$ y $\omega = +1.2\text{ rad/s}$:
```bash
ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 1.2}}"
```

### 5. Giro Pivote Calibrado a la Derecha ($-90^\circ$ sobre su propio eje)
Gira en su propio eje con $v = 0$ y $\omega = -1.2\text{ rad/s}$:
```bash
ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: -1.2}}"
```

### 6. Parada Activa de Emergencia (Active Braking TB6612FNG)
Detiene ambos motores en cortocircuito instantáneo ($v=0, \omega=0$):
```bash
ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}"
```

### 7. Retroceso de Seguridad (250 ms según especificación técnica)
Retrocede a $-0.16\text{ m/s}$ para liberar el cono de detección ToF:
```bash
ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist "{linear: {x: -0.16, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}"
```

---

## 4. Comandos de Inspección de Sensores y Telemetría

### 1. Monitorear los Sensores Láser ToF VL53L0X
```bash
# Lectura continua del sensor frontal izquierdo (en metros)
ros2 topic echo /distance/left

# Lectura continua del sensor frontal derecho (en metros)
ros2 topic echo /distance/right

# Verificar frecuencia de muestreo (debe ser aprox. 50 Hz)
ros2 topic hz /distance/left
```

### 2. Monitorear el Giróscopo MPU6050
```bash
# Ver orientación, aceleración lineal y velocidad angular (omega_z)
ros2 topic echo /imu/data

# Verificar frecuencia de muestreo (debe ser 100 Hz según el PDF)
ros2 topic hz /imu/data
```

### 3. Monitorear Posición y Odometría (X, Y)
```bash
ros2 topic echo /odom
```

---

## 5. Comandos para Entrenar y Ejecutar la Navegación Autónoma

### Modo 1: Navegación Autónoma Punto a Punto con FSM y Heading Hold
Ejecuta la máquina de estados completa del PDF (arranca en Punto A, cruza el plano, sube la rampa, esquiva obstáculos a $<180\text{ mm}$, aplica retroceso a $<80\text{ mm}$ y llega al Punto B):

```bash
python3 controlador_navegacion_y_entrenamiento.py --target_x 8.2 --target_y 0.0
```

### Modo 2: Entrenamiento y Optimización Online en Gazebo
Ejecuta episodios sucesivos en el simulador teletransportando el robot automáticamente al origen al finalizar cada intento, sintonizando las ganancias $K_p, K_i$ y las velocidades de rampa:

```bash
python3 entrenamiento_gazebo_online.py
```
*Al finalizar, exporta los parámetros óptimos a `pesos_optimos_entrenamiento.json`.*

### Modo 3: Entrenamiento por Refuerzo Profundo (DQN / PyTorch)
Entrena la red neuronal para aprender la política de navegación y evasión sin colisiones:

```bash
python3 train_point_to_point_rl.py
```

---

## 6. Comandos de Control de la Física de Gazebo

| Acción | Comando |
| :--- | :--- |
| **Pausar la simulación** | `gz world -p 1` |
| **Reanudar la física** | `gz world -p 0` |
| **Reiniciar el tiempo de simulación** | `gz world -r` |
| **Resetear posición de todos los modelos** | `ros2 service call /gazebo/reset_world std_srvs/srv/Empty` |
| **Resetear física del mundo** | `ros2 service call /gazebo/reset_simulation std_srvs/srv/Empty` |
