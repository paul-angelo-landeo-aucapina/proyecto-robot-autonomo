# Plataforma Robótica Móvil Autónoma 2WD (`proyecto-robot-autonomo`)

<div align="center">

![ESP32](https://img.shields.io/badge/ESP32_WROOM--32-E7352C?style=for-the-badge&logo=espressif&logoColor=white)
![C++17](https://img.shields.io/badge/C%2B%2B17-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white)
![Python 3.12](https://img.shields.io/badge/Python_3.12-3776AB?style=for-the-badge&logo=python&logoColor=white)
![PlatformIO](https://img.shields.io/badge/PlatformIO-FF7800?style=for-the-badge&logo=platformio&logoColor=white)
![ROS 2 Jazzy](https://img.shields.io/badge/ROS_2_Jazzy-22314E?style=for-the-badge&logo=ros&logoColor=white)
![Gazebo Harmonic](https://img.shields.io/badge/Gazebo_Harmonic_8.11-FF6F00?style=for-the-badge&logo=gazebo&logoColor=white)
![PyTorch](https://img.shields.io/badge/PyTorch_2.4-EE4C2C?style=for-the-badge&logo=pytorch&logoColor=white)
![NVIDIA CUDA](https://img.shields.io/badge/NVIDIA_CUDA-76B900?style=for-the-badge&logo=nvidia&logoColor=white)
![FreeCAD](https://img.shields.io/badge/FreeCAD_1.0-CB333B?style=for-the-badge&logo=freecad&logoColor=white)
![OpenSCAD](https://img.shields.io/badge/OpenSCAD-F0D24F?style=for-the-badge&logo=openscad&logoColor=black)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Linux](https://img.shields.io/badge/Linux_Kernel-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)
![Licencia MIT](https://img.shields.io/badge/Licencia-MIT-green?style=for-the-badge)

**Plataforma robótica móvil autónoma con tracción diferencial (2WD + rueda loca), diseñada para navegación en interiores, evasión reactiva milimétrica con sensores ToF, estabilización inercial de rumbo (Heading Hold PI) y aprendizaje por refuerzo en el borde (Edge AI).**

</div>

---

## 1. Visión General y Arquitectura del Sistema

El proyecto implementa un sistema mecatrónico desacoplado de alta eficiencia y bajo costo (< S/. 100), integrando cinemática vehicular, electrónica de potencia MOSFET, percepción óptica infrarroja y control digital de lazo cerrado a $50\text{ Hz}$:

- **Cinemática Diferencial (2WD + Caster Ball):** Dos ruedas motrices traseras ($\varnothing 66.0\text{ mm}$, ancho $26.0\text{ mm}$) impulsadas por motores reductores DC tipo TT ($1:48$), con una distancia entre ejes motrices ($W_{track} = 135.0\text{ mm}$) y una batalla longitudinal ($L_{wb} = 115.0\text{ mm}$) soportadas sobre un chasis acrílico cortado por láser (PMMA $3.0\text{ mm}$).
- **Unidad de Cómputo Embebida Unificada (ESP32):** Microcontrolador dual-core Tensilica Xtensa a $240\text{ MHz}$ que procesa en tiempo real la lectura de sensores I2C, el filtro complementario de orientación, la máquina de estados de navegación autónoma y la generación de consignas PWM por hardware a $20\text{ kHz}$ mediante el periférico LEDC.
- **Estabilización Inercial de Rumbo (*Heading Hold* con MPU6050):** Compensación en lazo cerrado mediante un controlador Proporcional-Integral (PI) sobre la velocidad angular en el eje Z ($\omega_z$), corrigiendo las asimetrías electromecánicas de los motores TT para mantener trayectorias rectas exactas sin requerir encoders en las ruedas.
- **Percepción Láser Dual ToF (VL53L0X):** Detección milimétrica de obstáculos frontal-izquierda y frontal-derecha mediante pulsos de luz infrarroja de $940\text{ nm}$. Incorpora inicialización secuencial por hardware vía líneas `XSHUT` (GPIO 32 y 33) para evitar colisiones de bus I2C (reasignando ToF 1 a `0x30` y manteniendo ToF 2 en `0x29`).
- **Etapa de Potencia MOSFET (TB6612FNG):** Doble puente H que sustituye al obsoleto L298N, ofreciendo alta eficiencia sin caídas de tensión significativas ($< 0.2\text{ V}$), frenado dinámico activo (*active short-braking*) y habilitación por pin `STBY`.
- **Bandeja Superior Porta-Objetos:** Plataforma de carga ($130 \times 95\text{ mm}$) ubicada longitudinalmente a $X = +48\text{ mm}$ del eje motriz para conservar la distribución óptima de peso ($61\%$ motriz para máxima adherencia y $39\%$ en la rueda loca para estabilidad anti-vuelco).

---

## 2. Stack Tecnológico

El proyecto abarca todo el ciclo de desarrollo mecatrónico, desde el modelado analítico y diseño CAD paramétrico, hasta la simulación física con GPU pass-through y el firmware embebido de tiempo real:

| Categoría | SVG Badge | Tecnología | Versión / Detalle | Rol en el Proyecto |
|---|:---:|:---:|:---:|---|
| **Microcontrolador & Cómputo** | ![ESP32](https://img.shields.io/badge/ESP32-E7352C?style=flat-square&logo=espressif&logoColor=white) | Espressif ESP32 | WROOM-32 / ESP32-S3 | Ejecución del firmware a 50 Hz, PWM LEDC a 20 kHz, I2C Fast Mode (400 kHz) |
| **Lenguaje Embebido** | ![C++](https://img.shields.io/badge/C%2B%2B17-00599C?style=flat-square&logo=c%2B%2B&logoColor=white) | C++17 | Arduino Core / FreeRTOS | Lógica de control en tiempo real, máquina de estados y controladores PI |
| **Toolchain de Compilación** | ![PlatformIO](https://img.shields.io/badge/PlatformIO-Core-FF7800?style=flat-square&logo=platformio&logoColor=white) | PlatformIO | Core 6.x | Gestión de compilación, flasheo CLI y monitoreo serial a 115200 baudios |
| **Lenguaje de Simulación** | ![Python](https://img.shields.io/badge/Python-3.12-3776AB?style=flat-square&logo=python&logoColor=white) | Python | 3.12+ | Modelado analítico, scripts de entrenamiento RL y puente de telemetría |
| **Middleware Robótico** | ![ROS 2](https://img.shields.io/badge/ROS_2-Jazzy-22314E?style=flat-square&logo=ros&logoColor=white) | ROS 2 | Jazzy Jalisco | Nodos de odometría, puente de comandos `/cmd_vel` y control distribuido |
| **Simulación Física 3D** | ![Gazebo](https://img.shields.io/badge/Gazebo-Harmonic_8.11-FF6F00?style=flat-square&logo=gazebo&logoColor=white) | Gazebo Sim | Harmonic (SDF 1.8) | Simulación física de contactos, rampa de 12.7°, sensores ToF e IMU virtuales |
| **Deep Learning & Edge AI** | ![PyTorch](https://img.shields.io/badge/PyTorch-2.4-EE4C2C?style=flat-square&logo=pytorch&logoColor=white) | PyTorch | 2.4+ (CUDA 12) | Entrenamiento de agente DQN para navegación y evasión reactiva continua |
| **Aceleración por Hardware** | ![NVIDIA CUDA](https://img.shields.io/badge/CUDA-Enabled-76B900?style=flat-square&logo=nvidia&logoColor=white) | NVIDIA CUDA | Drivers 615+ / RTX | Aceleración por GPU en el host para entrenamiento de redes neuronales |
| **CAD Paramétrico B-Rep** | ![FreeCAD](https://img.shields.io/badge/FreeCAD-1.0-CB333B?style=flat-square&logo=freecad&logoColor=white) | FreeCAD | 1.0+ (PartDesign) | Diseño paramétrico de chasis, carcasa externa, bandeja y exportación STEP |
| **CAD Procedimental** | ![OpenSCAD](https://img.shields.io/badge/OpenSCAD-2021.01-F0D24F?style=flat-square&logo=openscad&logoColor=black) | OpenSCAD | CSG Scripting | Ensamble procedural 3D, validación de holguras de pasaruedas y carga |
| **Virtualización / DevOps** | ![Docker](https://img.shields.io/badge/Docker-Engine-2496ED?style=flat-square&logo=docker&logoColor=white) | Docker | OSRF Simulation | Contenedores reproducibles para Gazebo/ROS 2 con soporte Wayland/X11 |
| **Control de Versiones** | ![Git](https://img.shields.io/badge/Git-SCM-F05032?style=flat-square&logo=git&logoColor=white) | Git | 2.40+ | Versionado semántico y aislamiento de rutas con políticas Git Safe |

---

## 3. Componentes Electrónicos y Distribución de Potencia

### A. Lista de Materiales (BOM) y Presupuesto

| Componente | Especificación Técnica | Función en el Robot | Cantidad | Costo Estimado (PEN) |
|---|---|---|:---:|:---:|
| **ESP32 DevKit v1** | Dual Core 240 MHz, 520 KB SRAM, 3.3V lógico | Unidad Central de Cómputo y Control | 1 | Disponible |
| **Sensor IMU MPU6050** | Acelerómetro + Giróscopo 6-DOF (Bus I2C) | Medición de $\omega_z$ para Heading Hold | 1 | Disponible |
| **Sensores ToF VL53L0X** | Emisor VCSEL 940 nm, rango 30 - 2000 mm | Percepción de distancia milimétrica frontal | 2 | Disponible |
| **Driver TB6612FNG** | Doble puente H MOSFET (1.2A cont., 3.2A pico) | Etapa de potencia de motores con Short-Brake | 1 | Disponible |
| **Kit Chasis 2WD Smart Car** | Base acrílica (PMMA 3 mm) + 2 ruedas + rueda loca | Plataforma mecánica y rodadura | 1 | S/. 28.00 - 32.00 |
| **Motores TT Amarillos** | Reductora spur 1:48, 6.0V, torque 0.12 N*m | Actuación motriz de tracción | 2 | Incluidos en Kit |
| **Baterías 18650 Li-Ion** | Celdas recargables 3.7V (Pack 2S = 7.4V, 2200 mAh) | Fuente de energía primaria | 2 | S/. 24.00 - 28.00 |
| **Portapilas 2x 18650** | Soporte con cables para conexión en serie | Contención mecánica de celdas | 1 | S/. 4.00 - 5.00 |
| **Módulo Buck DC-DC** | Mini MP1584EN o LM2596 (Salida fija 5.00V) | Aislamiento y regulación para pin VIN ESP32 | 1 | S/. 6.00 - 8.00 |
| **Misceláneos** | Switch ON/OFF, fusible 2A, cables, espaciadores M3 | Seguridad eléctrica y cableado de señales | — | Taller / Laboratorio |
| **TOTAL INVERSIÓN NETA**| | | | **S/. 62.00 - 73.00** |

---

### B. Topología Eléctrica y Masa en Estrella (*Star Ground*)

Para evitar que el ruido inductivo y las caídas de tensión de los motores afecten al ESP32 o generen bloqueos en el bus I2C, el circuito implementa una estricta segregación de retorno de corriente:

```mermaid
graph TD
    Bat["Pack 2S Li-Ion 18650 (7.4V - 8.4V)"] --> SW["Interruptor General ON/OFF"]
    SW --> Fuse["Fusible Rápido (2.0 A)"]

    Fuse -->|Línea VM (7.4V Potencia)| TB["Driver Dual TB6612FNG (VM)"]
    Fuse -->|Línea 7.4V| Buck["Módulo Buck DC-DC (Ajustado a 5.00V)"]

    Buck -->|5.00V Limpio| VIN["ESP32: Pin VIN"]
    ESP32["ESP32 WROOM-32"]

    ESP32 -->|3.3V LDO Nativo| BusVCC["Riel Lógico 3.3V"]
    BusVCC --> TB_VCC["TB6612FNG: Pin VCC"]
    BusVCC --> IMU["MPU6050 (VCC)"]
    BusVCC --> ToF1["ToF 1 Izquierdo (VCC)"]
    BusVCC --> ToF2["ToF 2 Derecho (VCC)"]

    TB --> MotL["Motor TT Izquierdo (M1)"]
    TB --> MotR["Motor TT Derecho (M2)"]

    ESP32 -->|GPIO 21 (SDA) / 22 (SCL)| BusI2C["Bus I2C (400 kHz Fast Mode)"]
    BusI2C --> IMU
    BusI2C --> ToF1
    BusI2C --> ToF2

    ESP32 -->|GPIO 32| XSHUT1["ToF 1: XSHUT (Reasigna a 0x30)"]
    ESP32 -->|GPIO 33| XSHUT2["ToF 2: XSHUT (Mantiene 0x29)"]
    ESP32 -->|GPIO 25| STBY["TB6612FNG: STBY (Habilitación)"]

    GND_Point(("PUNTO ESTRELLA DE TIERRA (GND)"))
    Bat -.-> GND_Point
    Buck -.-> GND_Point
    ESP32 -.-> GND_Point
    TB -.-> GND_Point
    IMU -.-> GND_Point
    ToF1 -.-> GND_Point
    ToF2 -.-> GND_Point
```

---

### C. Matriz Completa de Conexionado (Pinout del ESP32)

| Pin ESP32 | Dispositivo Destino | Pin Destino | Nivel Lógico | Función Técnica |
|---|---|---|:---:|---|
| **VIN** | Módulo Buck DC-DC | VOUT+ (5.0V) | 5.0 V DC | Entrada de alimentación principal para el regulador interno del ESP32 |
| **GND** | Estrella de Tierra | GND Común | 0.0 V | Retorno de corriente unificado para lógica y potencia |
| **3V3** | MPU6050, ToFs, TB6612 | VCC | 3.3 V DC | Riel de alimentación lógica regulada para sensores y lógica del driver |
| **GPIO 21** | MPU6050, ToF 1, ToF 2 | SDA | 3.3 V | Línea de datos bidireccional I2C (Fast Mode a 400 kHz con pull-ups) |
| **GPIO 22** | MPU6050, ToF 1, ToF 2 | SCL | 3.3 V | Línea de reloj I2C |
| **GPIO 32** | ToF 1 (Izquierdo) | XSHUT | 3.3 V | Pin de apagado por hardware. Permite reasignar la dirección I2C a `0x30` |
| **GPIO 33** | ToF 2 (Derecho) | XSHUT | 3.3 V | Pin de habilitación secundaria. Inicializa el sensor en su dirección nativa `0x29` |
| **GPIO 25** | TB6612FNG | STBY | 3.3 V | Standby del puente H. Activo en `HIGH` para habilitar salidas de potencia |
| **GPIO 18** | TB6612FNG | PWMA | 3.3 V PWM | Consigna de velocidad del Motor Izquierdo (LEDC canal 0, 20 kHz, 8 bits) |
| **GPIO 19** | TB6612FNG | AIN1 | 3.3 V | Control de dirección 1 del Motor Izquierdo |
| **GPIO 23** | TB6612FNG | AIN2 | 3.3 V | Control de dirección 2 del Motor Izquierdo |
| **GPIO 5**  | TB6612FNG | PWMB | 3.3 V PWM | Consigna de velocidad del Motor Derecho (LEDC canal 1, 20 kHz, 8 bits) |
| **GPIO 17** | TB6612FNG | BIN1 | 3.3 V | Control de dirección 1 del Motor Derecho |
| **GPIO 16** | TB6612FNG | BIN2 | 3.3 V | Control de dirección 2 del Motor Derecho |

---

## 4. Rutas a los Modelos CAD y Fabricación Mecánica

Todos los modelos de ingeniería mecánica se encuentran normalizados bajo [`hardware/mechanics/CADs/`](hardware/mechanics/CADs/):

```
hardware/mechanics/CADs/
├── fcstd/                  # Proyectos paramétricos nativos de FreeCAD 1.0+
├── step/                   # Sólidos B-Rep estándar ISO 10303 para mecanizado o CAD externo
├── scad/                   # Modelos CSG procedimentales para OpenSCAD
├── stl/                    # Mallas trianguladas para impresión 3D FDM
└── generate_freecad_2wd.py # Script de automatización y exportación en FreeCAD headless
```

### Tabla de Rutas a Modelos CAD

| Componente Mecánico | FreeCAD (`.FCStd`) | Estándar STEP (`.step`) | OpenSCAD (`.scad`) | Malla STL (`.stl`) | Descripción de Diseño |
|---|:---:|:---:|:---:|:---:|---|
| **Chasis Base Acrílico** | [`chasis_base_acrilico_195x125.FCStd`](hardware/mechanics/CADs/fcstd/chasis_base_acrilico_195x125.FCStd) | [`chasis_base_acrilico_195x125.step`](hardware/mechanics/CADs/step/chasis_base_acrilico_195x125.step) | [`chasis_base_acrilico_2wd.scad`](hardware/mechanics/CADs/scad/chasis_base_acrilico_2wd.scad) | [`chasis_base_acrilico_195x125.stl`](hardware/mechanics/CADs/stl/chasis_base_acrilico_195x125.stl) | Placa de corte láser PMMA ($195 \times 125 \times 3\text{ mm}$) con ranuras de montaje para motores TT |
| **Carcasa Externa 3D** | [`carcasa_externa_2wd.FCStd`](hardware/mechanics/CADs/fcstd/carcasa_externa_2wd.FCStd) | [`carcasa_externa_2wd.step`](hardware/mechanics/CADs/step/carcasa_externa_2wd.step) | [`carcasa_externa_2wd.scad`](hardware/mechanics/CADs/scad/carcasa_externa_2wd.scad) | [`carcasa_externa_2wd.stl`](hardware/mechanics/CADs/stl/carcasa_externa_2wd.stl) | Envolvente protectora en PETG/PLA con pasaruedas integrados ($R=38\text{ mm}$) y ventanas ToF a $\pm 15^\circ$ |
| **Plato Porta-Objetos** | [`plato_porta_objetos_2wd.FCStd`](hardware/mechanics/CADs/fcstd/plato_porta_objetos_2wd.FCStd) | [`plato_porta_objetos_2wd.step`](hardware/mechanics/CADs/step/plato_porta_objetos_2wd.step) | [`plato_porta_objetos_2wd.scad`](hardware/mechanics/CADs/scad/plato_porta_objetos_2wd.scad) | [`plato_porta_objetos_2wd.stl`](hardware/mechanics/CADs/stl/plato_porta_objetos_2wd.stl) | Bandeja superior ($130 \times 95\text{ mm}$) con reborde perimetral anticaída de $8\text{ mm}$ fijada a $X = +48\text{ mm}$ |
| **Ensamble Completo 2WD** | *N/A (Generado por script)* | *N/A* | [`ensamblaje_robot_2wd_completo.scad`](hardware/mechanics/CADs/scad/ensamblaje_robot_2wd_completo.scad) | [`ensamblaje_completo_2wd.stl`](hardware/mechanics/CADs/stl/ensamblaje_completo_2wd.stl) | Conjunto ensamblado con selector de modos (`completo`, `sin_plato`, `carcasa_transparente`, `solo_mecanica`) |
| **Script Generador** | — | — | — | — | [`generate_freecad_2wd.py`](hardware/mechanics/CADs/generate_freecad_2wd.py): Script en Python para FreeCAD headless que genera y valida los modelos |

---

## 5. Estructura Completa de Directorios

```text
proyecto-robot-autonomo/
├── README.md                           <- Este documento: Arquitectura técnica y guía general
├── LICENSE                             <- Licencia de código abierto MIT
│
├── docs/                               <- Documentación técnica general
│   └── README.md                       <- Memoria descriptiva, objetivos operativos y BOM
│
├── hardware/                           <- Subconjuntos físicos (mecánica, electrónica y CAD)
│   ├── electronics/                    <- Ingeniería eléctrica y hardware
│   │   └── README.md                   <- Esquemáticos, Star Ground, secuencia XSHUT y pinout
│   │
│   └── mechanics/                      <- Ingeniería mecánica, diseño 3D y simulación analítica
│       ├── README.md                   <- Guía de manufactura FDM, especificaciones de carga y CAD
│       ├── CADs/                       <- Paquetes de modelos tridimensionales
│       │   ├── fcstd/                  <- Archivos nativos FreeCAD 1.0 (.FCStd)
│       │   ├── step/                   <- Sólidos normalizados ISO 10303 (.step)
│       │   ├── scad/                   <- Modelos procedimentales OpenSCAD (.scad)
│       │   ├── stl/                    <- Mallas para fabricación aditiva FDM (.stl)
│       │   └── generate_freecad_2wd.py <- Script para regenerar sólidos FreeCAD por consola
│       │
│       └── calculations/               <- Memoria de cálculo físico y dinámica vehicular
│           ├── simulacion_fisica_robot_2wd.py   <- Script Python autónomo de simulación física y límites
│           └── curvas_rendimiento_robot_2wd.png <- Panel gráfico de tracción, corriente, flexión y flecha
│
├── software/                           <- Ecosistema de control embebido y software de alto nivel
│   ├── README.md                       <- Arquitectura de 4 capas, portabilidad Git Safe y dependencias
│   │
│   ├── firmware/                       <- Firmware modular en C++ para ESP32 (PlatformIO)
│   │   ├── platformio.ini              <- Entorno de compilación, microcontrolador y dependencias
│   │   ├── include/                    <- Cabeceras del sistema de control
│   │   │   ├── robot_config.h          <- Constantes físicas, asignación de pines y umbrales
│   │   │   ├── tb6612_driver.h         <- Abstracción del driver de potencia de motores
│   │   │   ├── sensor_manager.h        <- Inicialización secuencial ToF y calibración MPU6050
│   │   │   └── navigation_controller.h <- Máquina de estados y control de rumbo PI
│   │   └── src/                        <- Implementación en C++
│   │       ├── main.cpp                <- Lazo de control a 50 Hz y comandos de telemetría serial
│   │       ├── tb6612_driver.cpp       <- Control de PWM LEDC y frenado activo
│   │       ├── sensor_manager.cpp      <- Rutinas I2C para dual VL53L0X y giroscopio
│   │       └── navigation_controller.cpp <- Lógica de crucero, evasión reactiva y giro sobre eje
│   │
│   ├── ai_training/                    <- Entorno de simulación física, ROS 2 y Deep Q-Learning
│   │   ├── README.md                   <- Índice del módulo de IA y guía de inicio rápido
│   │   ├── requirements.txt            <- Dependencias de Python (PyTorch CUDA, TensorBoard, SciPy)
│   │   ├── docs/                       <- Manuales y runbooks de simulación e IA
│   │   │   ├── guia_instalacion_y_arquitectura.md           <- Guía exhaustiva de arquitectura interna
│   │   │   ├── guia_completa_entrenamiento_y_comandos_gazebo.md <- Flujo integral de simulación y comandos
│   │   │   ├── comandos_guia_gazebo.md                      <- Cheat sheet de comandos CLI Gazebo/ROS 2
│   │   │   ├── guia_resolucion_problemas.md                 <- Runbook de diagnóstico de fallas ("Si X, haz Y")
│   │   │   └── guia_entrenamiento_ia.md                     <- Metodología del agente de refuerzo DQN
│   │   ├── worlds/                     <- Escenarios de física SDF 1.8 (Gazebo Harmonic)
│   │   │   ├── laberinto_obstaculos.world                   <- Recinto para evasión reactiva ToF
│   │   │   ├── pista_rampa_y_plano.world                    <- Pista con pendiente de 12.7° para tracción
│   │   │   └── piso_plano_entrenamiento.world               <- Escenario plano para calibración cinemática
│   │   ├── models/                     <- Modelado cinemático del robot
│   │   │   └── robot_diferencial.urdf.xacro                 <- Modelo 2WD con plugins DiffDrive e IMU
│   │   ├── launch/                     <- Scripts de lanzamiento para ROS 2 Jazzy
│   │   │   ├── launch_simulacion.launch.py
│   │   │   └── launch_rampa_y_plano.launch.py
│   │   ├── training/                   <- Algoritmos de aprendizaje por refuerzo
│   │   │   ├── train_point_to_point_rl.py                   <- Agente DQN acelerado con GPU CUDA
│   │   │   ├── train_evasion_rl.py                          <- Control reactivo mediante tópicos ROS 2
│   │   │   ├── entrenamiento_gazebo_online.py               <- Sintonizador de ganancias en Gazebo
│   │   │   ├── entrenar_robot_cmd.py                        <- Optimización rápida por terminal
│   │   │   └── controlador_navegacion_y_entrenamiento.py   <- Enlace entre física y política entrenada
│   │   ├── tools/                      <- Herramientas visuales e interfaces livianas
│   │   │   ├── simulador_visual_windows.py                  <- Simulador gráfico autónomo 2D (sin Docker)
│   │   │   └── enviar_comando.py                            <- Inyector de consignas por IPC compartido
│   │   └── policies/                   <- Parámetros exportados listos para producción
│   │       ├── politica_entrenada_robot.json                <- Pesos y umbrales en formato JSON
│   │       └── politica_optima_esp32.h                      <- Cabecera C++ lista para el firmware ESP32
│   │
│   ├── core_control/                   <- Lógica de navegación y puentes con ROS 2
│   └── simulation/                     <- Entornos y configuraciones complementarias
│
└── app/                                <- Aplicación de supervisión e interfaz de usuario
    └── README.md                       <- Especificación de telemetría WebSockets JSON y app móvil
```

---

## 6. Rutas a las Guías y Documentación Técnica

El repositorio incluye guías especializadas para cada subsistema del robot:

| Guía / Documento | Ruta Relativa | Contenido y Propósito Técnico |
|---|---|---|
| **Arquitectura Interna e Instalación** | [`software/ai_training/docs/guia_instalacion_y_arquitectura.md`](software/ai_training/docs/guia_instalacion_y_arquitectura.md) | Ecuaciones cinemáticas diferenciales, diagrama de secuencia de control y flujo de simulación en Gazebo |
| **Guía Completa Gazebo & IA** | [`software/ai_training/docs/guia_completa_entrenamiento_y_comandos_gazebo.md`](software/ai_training/docs/guia_completa_entrenamiento_y_comandos_gazebo.md) | Flujo paso a paso para lanzar mundos SDF, teleoperar con ROS 2 y entrenar políticas RL |
| **Cheat Sheet de Comandos CLI** | [`software/ai_training/docs/comandos_guia_gazebo.md`](software/ai_training/docs/comandos_guia_gazebo.md) | Comandos de consola indispensables para Gazebo Harmonic, tópicos ROS 2 y variables de entorno |
| **Runbook de Resolución de Fallas** | [`software/ai_training/docs/guia_resolucion_problemas.md`](software/ai_training/docs/guia_resolucion_problemas.md) | Matriz operacional de fallas ("Si ocurre X, corre Y"): gráficos Docker, Wayland, bus I2C y colisiones |
| **Metodología de Inteligencia Artificial** | [`software/ai_training/docs/guia_entrenamiento_ia.md`](software/ai_training/docs/guia_entrenamiento_ia.md) | Formulación de recompensas del agente DQN, espacio de estados sensoriales y exportación a C++ |
| **Manual de Electrónica y Potencia** | [`hardware/electronics/README.md`](hardware/electronics/README.md) | Circuito Star Ground, secuencia de hardware XSHUT para dual ToF, consumo y pinout completo |
| **Manual Mecánico, CAD y Manufactura** | [`hardware/mechanics/README.md`](hardware/mechanics/README.md) | Especificaciones de carga del chasis, parámetros de impresión 3D FDM y uso de herramientas CAD |
| **Ecosistema de Software y Portabilidad**| [`software/README.md`](software/README.md) | Arquitectura desacoplada en 4 niveles, directrices Git Safe y configuración de entornos virtuales |
| **Módulo de Entrenamiento de IA** | [`software/ai_training/README.md`](software/ai_training/README.md) | Mapa de carpetas de simulación, inicio rápido de mundos SDF y entrenamiento por consola |
| **Interfaz y Aplicación Móvil** | [`app/README.md`](app/README.md) | Protocolo de telemetría WebSockets JSON bidireccional a 20 Hz y panel de control web/móvil |
| **Memoria de Objetivos y Presupuesto** | [`docs/README.md`](docs/README.md) | Justificación técnica de componentes, análisis de costos y objetivos de navegación |

---

## 7. Guía de Inicio Rápido y Simulación

### A. Simulación Física y Dinámica Analítica en Python (Sin Colab ni Jupyter)

Para calcular la capacidad de tracción, el límite térmico de motores TT, la resistencia del chasis de acrílico y regenerar las curvas operativas en cualquier PC:

```bash
# 1. Instalar dependencias numéricas y gráficas estándar
python3 -m pip install numpy matplotlib

# 2. Ejecutar la simulación con una carga de prueba de 1.0 kg en el plato
python3 hardware/mechanics/calculations/simulacion_fisica_robot_2wd.py --payload 1.0
```

> 📊 El script imprimirá el informe completo en la consola y generará automáticamente el panel de gráficas en [`hardware/mechanics/calculations/curvas_rendimiento_robot_2wd.png`](hardware/mechanics/calculations/curvas_rendimiento_robot_2wd.png).

---

### B. Compilación y Carga del Firmware en el ESP32

Con **PlatformIO** (recomendado):

```bash
cd software/firmware

# Compilar el firmware en C++
pio run

# Flashear el microcontrolador vía USB y abrir el monitor serial
pio run --target upload
pio device monitor -b 115200
```

Con **Arduino IDE**:
1. Abrir `software/firmware/src/main.cpp`.
2. Instalar desde el Gestor de Bibliotecas: `Adafruit_VL53L0X`.
3. Seleccionar la placa **ESP32 Dev Module** y el puerto serial correspondiente.
4. Compilar y transferir.

---

### C. Calibración y Operación por Monitor Serial (115200 Baudios)

1. **Al energizar el robot**, mantenerlo estático sobre una superficie plana durante 2 segundos mientras se calcula el offset de deriva del giróscopo MPU6050.
2. Comandos disponibles por consola serial:
   - `s`: Inicia la navegación autónoma con evasión reactiva y control Heading Hold PI.
   - `x`: Parada de emergencia inmediata (frenado activo por puente H).
   - `c`: Recalibra el giróscopo en reposo.
   - `r`: Reinicia la orientación de rumbo actual a 0°.

---

### D. Simulación 3D en Gazebo Harmonic (Opcional)

Para validar el modelo en simulación física con soporte ROS 2:

```bash
# Lanzar el escenario de laberinto con visualización 3D
gz sim -r software/ai_training/worlds/laberinto_obstaculos.world

# O correr el simulador liviano 2D autónomo sin dependencias pesadas
python3 software/ai_training/tools/simulador_visual_windows.py
```
