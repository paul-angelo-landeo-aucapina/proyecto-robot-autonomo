# Robot Móvil Autónomo con Estabilización Inercial y Evasión Reactiva de Obstáculos

---

## 1. Descripción del Proyecto

El proyecto consiste en el diseño, desarrollo e integración de una plataforma robótica móvil autónoma de configuración diferencial (2WD + rueda loca posterior) orientada a la navegación en interiores. El robot opera de forma completamente autónoma en tiempo real, ejecutando tareas de exploración de entornos, mantenimiento de rumbo y evasión dinámica de obstáculos.

### Objetivos Operativos y Funcionales
1. **Desplazamiento Rectilíneo Estabilizado (*Heading Hold*):** Los motores reductores de bajo costo (tipo TT amarillos) presentan asimetrías mecánicas que desvían al vehículo. El robot emplea el giróscopo del sensor inercial **MPU6050 (eje Z)** para computar el error angular acumulado respecto al rumbo deseado y corregir el PWM diferencial en tiempo real mediante un controlador Proporcional-Integral (PI), garantizando trayectorias rectas precisas sin requerir encoders mecánicos de rueda.
2. **Percepción Frontal y Evasión Reactiva:** Mediante dos sensores de tiempo de vuelo **VL53L0X (ToF)**, el robot mide la distancia milimétrica hacia obstáculos en los sectores frontales izquierdo y derecho. Si un obstáculo ingresa en la zona de frenado ($< 180\text{ mm}$), la máquina de estados detiene la marcha, evalúa cuál lado tiene mayor espacio libre, y ejecuta un giro pivote calibrado sobre su propio eje (ej. $\pm 90^\circ$) monitoreado por el giróscopo antes de reanudar el avance.
3. **Parada de Emergencia y Retroceso de Seguridad:** En caso de detectar una barrera crítica imprevista a menos de $80\text{ mm}$, el robot ejecuta un frenado electrónico activo (*active braking*) por puente H, retrocede $250\text{ ms}$ para liberar el cono de detección y rota en búsqueda de un corredor despejado.
4. **Telemetría y Control Bidireccional:** El microcontrolador emite diagnósticos continuos a $50\text{ Hz}$ por puerto serial (y expandible a WebSockets/Wi-Fi nativo del ESP32), informando el ángulo de orientación, velocidad angular, lecturas de distancia y estado de la máquina de navegación.

---

## 2. Componentes a Usar

La selección de partes aprovecha los sensores, módulos de potencia lógica y microcontroladores disponibles en el inventario del equipo, requiriendo únicamente la incorporación de la planta motriz y la fuente de energía:

### Lista de Materiales (BOM)

| Categoría | Componente y Especificación | Estado |
|---|---|:---:|
| **Cómputo** | Tarjeta de desarrollo ESP32 / ESP32-S3 (lógica 3.3V) | **Disponible** |
| **Sensórica** | Módulo MPU6050 (Acelerómetro + Giróscopo 6-DOF) | **Disponible** |
| **Percepción** | 2x Sensores de distancia Láser ToF VL53L0X | **Disponible** |
| **Driver** | Módulo TB6612FNG (Doble puente H MOSFET 1.2A cont.) | **Disponible** |
| **Mecánica / Actuación** | Kit Chasis 2WD (Base acrílica + 2 ruedas 65 mm + rueda loca + 2 motores TT 1:48) | Por adquirir |
| **Potencia** | Celdas Li-Ion 18650 recargables (Pack 2S = 7.4V nominal) | Por adquirir |
| **Potencia** | Portapilas 2S para 18650 con terminales | Por adquirir |
| **Regulación** | Módulo Buck Step-Down DC-DC Mini MP1584EN o LM2596 | Por adquirir |
| **Misceláneos** | Cables dupont, switch ON/OFF, espaciadores M3 | Por adquirir / Taller |

### Justificación Técnica de los Componentes Principales
- **ESP32 / ESP32-S3 (Microcontrolador Unificado):** Microcontrolador dual-core Tensilica Xtensa 32-bit a $240\text{ MHz}$ con $520\text{ KB}$ de SRAM. Trabaja a nivel lógico de $3.3\text{ V}$ nativo, lo que coincide exactamente con los sensores MPU6050 y VL53L0X sin necesidad de adaptadores de nivel (*level shifters*). El periférico LEDC provee PWM por hardware a $20\text{ kHz}$ eliminando zumbidos audibles en los motores.
- **Driver TB6612FNG:** Reemplaza al obsoleto L298N. Al estar basado en MOSFETs de baja resistencia $R_{DS(on)}$, no genera caídas de voltaje de $2\text{ V}$ típicas de los transistores bipolares, no requiere disipadores de calor y soporta hasta $1.2\text{ A}$ continuos por canal ($3.2\text{ A}$ pico), más que suficiente para los motores TT.
- **Sensores Láser ToF VL53L0X:** A diferencia de los sensores ultrasónicos HC-SR04 (que sufren rebotes acústicos, ecos fantasmas y un cono de apertura muy ancho), la tecnología Time-of-Flight emite pulsos de luz infrarroja de $940\text{ nm}$, midiendo la distancia con precisión milimétrica independiente del color o textura del obstáculo.
- **Sensor Inercial MPU6050:** Aporta la lectura de velocidad angular ($\omega_z$) a $100\text{ Hz}$. Tras un proceso de calibración en reposo durante los primeros 2 segundos de encendido, permite compensar la deriva (*drift*) y estabilizar el avance rectilíneo.
- **Kit Chasis 2WD con Motores TT:** Provee el soporte estructural acrílico, las ruedas motrices de goma ($65\text{ mm}$), la rueda loca de apoyo y los dos motores reductores TT con relación $1:48$ que deben adquirirse para completar la motricidad del robot.
