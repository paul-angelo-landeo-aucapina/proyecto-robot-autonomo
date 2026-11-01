# Subconjunto Mecánico, Estructural y Carrocería — Proyecto Robot Autónomo

Este directorio contiene el paquete completo de ingeniería mecánica, diseño paramétrico 3D, planos de fabricación CNC, modelos de simulación física en Gazebo y cálculos estructurales analíticos del **Proyecto Robot Autónomo (`proyecto-robot-autonomo`)**, un robot móvil de asistencia y transporte en interiores.

---

## 1. Resumen de Especificaciones de Ingeniería

- **Configuración Cinemática:** Tracción diferencial pura (2WD con motores DC 37D con reductora metálica y encoder en eje trasero $X = 70.0\text{ mm}$) y 2 ruedas omnidireccionales dobles en eje frontal ($X = 330.0\text{ mm}$, coplanares con eje motriz a $Z = 40.0\text{ mm}$).
- **Geometría Cuadrada:** Wheelbase $L_{wb} = 260.0\text{ mm}$, Ancho de vía $W_{track} = 260.0\text{ mm}$ ($\text{Ratio } L/W = 1.00$, rotación sobre su eje sin arrastre lateral).
- **Dimensiones Exteriores:** $400.0\text{ mm}$ (Largo) $\times 300.0\text{ mm}$ (Ancho) $\times 133.5\text{ mm}$ (Altura total).
- **Despeje Libre al Suelo (Ground Clearance):** **$10.0\text{ mm}$** bajo la placa base inferior, garantizando franqueamiento de juntas, umbrales y alfombras.
- **Ruedas:** Diámetro nominal $d = 80.0\text{ mm}$ ($R_w = 40.0\text{ mm}$), contacto tangencial en $Z = 0.0\text{ mm}$.
- **Masa Total Estimada:** **$2.60\text{ kg}$** de peso base propio ($0.972\text{ kg}$ chasis + $0.818\text{ kg}$ carrocería + electrónica y actuadores).
- **Capacidad de Carga Útil:** **$5.0\text{ kg}$** medidos en tiempo real mediante celda de carga central desacoplada con topes mecánicos de sobrecarga.
- **Grado de Protección Ambiental:** Carcasa estanca con faldón fijo, arcos de rueda estilizados ($R = 46.0\text{ mm}$) con pasaruedas sellados internos, ranura perimetral en $Z = 103.5\text{ mm}$ para cordón de silicona de $\varnothing 2.0\text{ mm}$ y tapa desmontable sujeta por 4 pernos M3 moleteados.
- **Interfaces Frontales Integradas:** 2 displays OLED SH1106 de 1.3" (ojos robóticos con pupila activa circular $\varnothing 14.5\text{ mm}$ enrasada), puerto acústico para micrófono MEMS I2S INMP441, rosette de microperforaciones para parlante dinámico de 3W y 4 ventanas ópticas enrasadas para sensores ToF (+11.59° pitch-up).

---

## 2. Estructura de Directorios

```text
hardware/mechanics/
├── CADs/
│   ├── scad/              # Modelos paramétricos 3D OpenSCAD (.scad)
│   │   ├── ensamblaje_base_completa.scad   # Ensamble maestro con Customizer nativo
│   │   ├── ensamblaje_base_mecanica.scad   # Base rodante desnuda (inspección aislada)
│   │   ├── carroceria_cerramiento_superior.scad # Carcasa, faldón y tapa desmontable
│   │   ├── brackets_robot_sumoso.scad      # Brackets 3D (motor 37D, omniwheel, ToF)
│   │   └── puente_celda_carga.scad         # Puente y soporte de balanza desacoplada
│   ├── stl/               # Mallas sólidas para manufactura FDM / CNC (100% watertight)
│   │   ├── placa_base_chasis.stl           # Placa base de policarbonato 6mm
│   │   ├── bracket_motor_37d.stl           # Bracket L con cuna cilíndrica de apoyo
│   │   ├── bracket_omniwheel_65mm.stl      # Horquilla de omniwheels d=80mm
│   │   ├── tof_sensor_wedge.stl            # Cuña ToF compacta enrasada (+11.59°)
│   │   ├── puente_celda_carga.stl          # Puente elevador de celda de 5 kg
│   │   ├── soporte_bandeja_flotante.stl    # Brazo voladizo de bandeja de carga
│   │   ├── carcasa_faldon_base.stl         # Faldón inferior con arcos y pasaruedas
│   │   └── carcasa_tapa_superior.stl       # Tapa desmontable con laberinto perimetral
│   └── drawings_2d/       # Planos técnicos de corte y mecanizado 2D (AutoCAD / LibreCAD)
│       ├── ChasisBaseRobotSumo.dwg / .dxf           # Placa base y rieles de aluminio
│       ├── PlacaIntermediaRobotSumo.dwg / .dxf      # Placa intermedia y pasacables
│       └── CarroceriaCerramientoSuperior.dwg / .dxf # Carrocería, faldón y rejillas
├── calculations/          # Memoria analítica de cálculo físico-matemático
│   └── CalculosMatematicosyFisicosRobot.ipynb      # Notebook Jupyter (Módulos 0 a 15 certificados)
├── simulation/            # Entorno y modelos de simulación física (Gazebo Harmonic)
│   ├── robot_sumoso.sdf   # Modelo SDF del robot (colisiones, inercias, sensores)
│   ├── sumo_arena.sdf     # Pista de pruebas con piso texturizado
│   ├── autonomous_patrol.py # Demostración autónoma con control cinemático
│   ├── launch_sim_gui.sh  # Script de lanzamiento con interfaz gráfica
│   └── GUIA_SIMULACION_GAZEBO.md # Manual operativo y comandos de simulación
├── docs/                  # Documentación técnica exhaustiva e imágenes
│   ├── MEMORIA_TECNICA.md # Memoria completa de diseño (15 módulos analíticos)
│   └── images/            # Renders e infografías de verificación de ingeniería
└── README.md              # Este archivo guía
```

---

## 3. Instrucciones de Uso y Apertura de Documentos

### A. Inspección del Modelo 3D Paramétrico (OpenSCAD)
Para visualizar o parametrizar el chasis y la carrocería:
1. Abrir [OpenSCAD](https://openscad.org/).
2. Cargar el ensamble maestro: [`CADs/scad/ensamblaje_base_completa.scad`](CADs/scad/ensamblaje_base_completa.scad).
3. Habilitar la ventana del **Customizer** en el menú superior (**Window $\rightarrow$ Customizer**).
4. En el selector desplegable `modo_vista`, alternar entre las siguientes opciones:
   - `completo`: Robot completo con carrocería exterior hermética, tapa desmontable y bandeja superior.
   - `sin_tapa`: Tapa superior removida para inspeccionar la placa intermedia, el arnés eléctrico segregado y la batería.
   - `solo_base`: Chasis rodante desnudo (motores, ruedas, rieles de aluminio y standoffs) sin la carrocería.
   - `transparente`: Carrocería en modo translúcido para evaluar holguras cinemáticas e interferencias internas.

---

### B. Apertura y Edición de Planos Técnicos 2D (Corte CNC y Láser)
Los archivos ubicados en [`CADs/drawings_2d/`](CADs/drawings_2d/) están normalizados bajo formato DXF y DWG (compatibles con AutoCAD 2018+, LibreCAD y QCAD):
- **Software recomendado:** [LibreCAD](https://librecad.org/) (código abierto) o [QCAD](https://www.qcad.org/).
- **Procedimiento de mecanizado:**
  - `ChasisBaseRobotSumo.dxf`: Corte de la placa base en Policarbonato (PC) de $6.0\text{ mm}$ con fresa de $\varnothing 3.0\text{ mm}$ y chaflanes en orificios avellanados para pernos M3.
  - `PlacaIntermediaRobotSumo.dxf`: Corte de la bandeja de segregación electrónica en Policarbonato de $3.0\text{ mm}$ o acrílico antiestático.
  - `CarroceriaCerramientoSuperior.dxf`: Patrón de desarrollo para plegado o referencia dimensional de carcasas termoformadas.

---

### C. Manufactura Aditiva (Impresión 3D de Archivos STL)
Todas las piezas en [`CADs/stl/`](CADs/stl/) son sólidas cerradas (100% 2-manifold / *watertight*):
- **Laminadores recomendados:** PrusaSlicer, OrcaSlicer, Bambu Studio o Cura.
- **Parámetros de impresión certificados:**
  - **Soportes de Motor y Brackets (`bracket_motor_37d.stl`, `bracket_omniwheel_65mm.stl`):**
    - Material: **PETG** o **PA-CF** (Nylon con fibra de carbono) para resistir torsión motriz ($0.54\text{ N}\cdot\text{m}$).
    - Perímetros de pared: 5 (mínimo $2.0\text{ mm}$).
    - Relleno: $40\%-50\%$ Giroide o Cúbico.
  - **Puente de Celda de Carga (`puente_celda_carga.stl`):**
    - Material: PETG o PC. Relleno $60\%$ para garantizar rigidez flexional bajo carga de 5 kg.
  - **Carrocería y Tapa (`carcasa_faldon_base.stl`, `carcasa_tapa_superior.stl`):**
    - Material: PETG o PLA+. Altura de capa $0.20\text{ mm}$, 3 perímetros, relleno $20\%$.

---

### D. Ejecución de la Simulación Física en Gazebo Harmonic
Para validar la dinámica diferencial, despeje al suelo y respuesta de sensores:
```bash
cd simulation
./launch_sim_gui.sh
```
Para consultar los comandos de teleoperación manual por tópicos `/cmd_vel` y rutinas autónomas, consultar la [Guía Operativa de Simulación en Gazebo](simulation/GUIA_SIMULACION_GAZEBO.md).

---

### E. Inspección de Cálculos Analíticos (Jupyter Notebook)
Para auditar las ecuaciones analíticas de flexión, torsión, tiro térmico, pesaje y caídas de tensión eléctrica (Módulos 0 a 15):
```bash
cd calculations
jupyter notebook CalculosMatematicosyFisicosRobot.ipynb
```

---

## 4. Documentación Detallada

Para consultar el desarrollo matemático completo, diagramas de cuerpo libre, cálculo de pernos, análisis de pandeo y dimensionamiento térmico, dirigirse a la **[`Memoria Técnica Completa`](docs/MEMORIA_TECNICA.md)**.
