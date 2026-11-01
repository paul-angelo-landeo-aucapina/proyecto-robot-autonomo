# Proyecto Robot Autónomo (`proyecto-robot-autonomo`)

Plataforma robótica móvil autónoma para interiores, diseñada para navegación diferencial, transporte de cargas ligeras con supervisión metrológica en tiempo real, interacción natural mediante reconocimiento de voz en el borde (Edge AI / TinyML) y telemetría bidireccional inalámbrica.

---

## 1. Visión General del Sistema

El robot integra un chasis de alta rigidez estructural en policarbonato y perfiles de aluminio, carrocería perimetral hermética desmontable y una arquitectura mecatrónica modular dividida en hardware, software embebido y aplicaciones de control:

- **Cinemática Diferencial Cuadrada (2WD + 2 Omniwheels):** Eje motriz trasero con 2 motores DC 37D con reducción metálica y encoders en cuadratura, combinado con 2 ruedas omnidireccionales frontales dobles coplanares. Wheelbase ($L_{wb} = 260\text{ mm}$) y ancho de vía ($W_{track} = 260\text{ mm}$) en relación $1:1$ para rotación sobre el centro de masa sin arrastre lateral.
- **Balanza de Carga Útil Desacoplada (5.0 kg):** Bandeja superior de carga vinculada a una celda de carga central tipo paralelogramo con conversor ADC de 24 bits (HX711) y topes mecánicos de sobrecarga.
- **Procesamiento Embebido e Inteligencia Artificial:**
  - **ESP32 Principal:** Control cinemático en lazo cerrado (PID), odometría en tiempo real, máquina de estados y servidor WebSockets para control remoto.
  - **ESP32-S3 (Edge AI):** Pipeline de audio digital I2S (micrófono INMP441 y amplificador MAX98357A) ejecutando un modelo TinyML convolucional para reconocimiento local de comandos de voz en menos de 200 ms.
- **Percepción y Expresión:** Matriz frontal de 4 sensores de distancia por tiempo de vuelo (ToF) con orientación angular optimizada (+11.59° pitch-up) y 2 pantallas OLED SH1106 de 1.3" para visualización de estados y pupilas robóticas interactivas.

---

## 2. Estructura del Repositorio

El proyecto adopta una arquitectura modular donde cada dominio técnico se encuentra aislado y documentado con su propia guía de ejecución:

```text
proyecto-robot-autonomo/
├── docs/                     # Documentación global, diagramas de arquitectura y protocolos
│   └── README.md             # Guía de documentación del sistema
├── hardware/
│   ├── mechanics/            # Ingeniería mecánica, CADs 3D, planos 2D, cálculos y simulación
│   │   ├── CADs/             # Modelos OpenSCAD (.scad), mallas STL y planos CNC (.dwg/.dxf)
│   │   ├── calculations/     # Cuaderno Jupyter con 15 módulos analíticos certificados
│   │   ├── simulation/       # Entorno de simulación física en Gazebo Harmonic (SDF)
│   │   ├── docs/             # Memoria técnica completa y renders de inspección
│   │   └── README.md         # Guía de manufactura, CAD y simulación mecánica
│   └── electronics/          # Esquemáticos, distribución de potencia y conexionado
│       └── README.md         # Guía de hardware electrónico y distribución eléctrica
├── software/
│   ├── README.md             # Arquitectura global de software y flujos de datos
│   ├── firmware/             # Control de bajo nivel para microcontroladores
│   ├── core_control/         # Lógica de navegación y control de alto nivel
│   ├── simulation/           # Enlaces a modelos y plugins de simulación
│   └── ai_training/          # Firmwares, scripts TinyML de audio y dashboard de telemetría
│       └── README.md         # Guía de entrenamiento de IA, firmwares y dashboard WebSockets
└── app/                      # Interfaces de usuario y aplicaciones móviles
    └── README.md             # Guía del panel de control web y aplicación móvil
```

---

## 3. Requisitos de Software y Herramientas

Para abrir, compilar y ejecutar los diversos subsistemas del proyecto se recomiendan las siguientes herramientas:

| Subsistema | Herramienta | Versión Recomendada | Caso de Uso |
|---|---|---|---|
| **CAD 3D** | [OpenSCAD](https://openscad.org/) | $\ge 2021.01$ | Inspección y parametrización de piezas con el Customizer |
| **Planos 2D** | [LibreCAD](https://librecad.org/) / [QCAD](https://www.qcad.org/) | Reciente | Apertura de archivos `.dxf` y `.dwg` para mecanizado CNC |
| **Simulación 3D** | [Gazebo Harmonic](https://gazebosim.org/) | `gz-sim` $\ge 8.0$ (o vía Docker) | Validación física, colisiones y dinámica de sensores |
| **Cálculos Analíticos** | [Jupyter Notebook](https://jupyter.org/) / Python | Python $\ge 3.10$ | Auditoría de ecuaciones estructurales y térmicas |
| **Firmware Embebido** | [Arduino IDE](https://www.arduino.cc/) o [PlatformIO](https://platformio.org/) | Reciente (ESP32 core $\ge 2.0$) | Compilación y flasheo de microcontroladores |
| **Edge AI / TinyML** | Python ([TensorFlow](https://www.tensorflow.org/), Librosa) | TensorFlow $\ge 2.10$ | Entrenamiento del modelo de voz y exportación a C-array |
| **Panel Web** | [Node.js](https://nodejs.org/) & npm | Node $\ge 18$ | Ejecución del componente React de monitoreo |

---

## 4. Guía de Inicio Rápido (Quick Path)

### A. Inspeccionar el Modelo Mecánico 3D
1. Instalar y abrir **OpenSCAD**.
2. Abrir el archivo maestro:
   ```bash
   openscad hardware/mechanics/CADs/scad/ensamblaje_base_completa.scad
   ```
3. En el panel lateral derecho (**Window $\rightarrow$ Customizer**), seleccionar entre los modos de visualización: `completo`, `sin_tapa`, `solo_base` o `transparente`.

### B. Ejecutar la Simulación Física en Gazebo Harmonic
1. Ingresar a la carpeta de simulación y ejecutar el script interactivo:
   ```bash
   cd hardware/mechanics/simulation
   ./launch_sim_gui.sh
   ```
2. (Opcional) En otra terminal, iniciar la rutina de patrullaje autónomo:
   ```bash
   cd hardware/mechanics/simulation
   python3 autonomous_patrol.py
   ```

### C. Auditar los Cálculos Analíticos de Ingeniería
1. Iniciar el servidor Jupyter:
   ```bash
   cd hardware/mechanics/calculations
   jupyter notebook CalculosMatematicosyFisicosRobot.ipynb
   ```
2. Ejecutar las celdas para validar factores de seguridad ($FS > 20$), rigidez compuesta, flexión y análisis de vibraciones.

### D. Entrenar y Desplegar el Modelo de Reconocimiento de Voz
1. Crear un entorno virtual e instalar dependencias:
   ```bash
   cd software/ai_training
   python3 -m venv .venv
   source .venv/bin/activate
   pip install tensorflow librosa numpy scipy
   ```
2. Ejecutar el script de entrenamiento para generar la cabecera `model_data.h`:
   ```bash
   python3 "Red neuronal de audio.py"
   ```

### E. Flashear los Microcontroladores
1. Abrir Arduino IDE o VS Code con PlatformIO.
2. Cargar `software/ai_training/Control de movimiento, cinemática y telemetría.ino` en la placa ESP32 Dev Module.
3. Cargar `software/ai_training/Captura de audio por IS2 y Pipeline de voz.ino` en la placa ESP32-S3.

---

## 5. Licencia

Este proyecto está distribuido bajo la licencia MIT. Consultar el archivo [LICENSE](LICENSE) para más detalles.
