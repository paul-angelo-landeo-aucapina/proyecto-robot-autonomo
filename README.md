# Proyecto Robot Autónomo 2WD (`proyecto-robot-autonomo`)

Plataforma robótica móvil autónoma con tracción diferencial (2WD + rueda loca) de bajo costo (< S/. 100), diseñada para navegación en interiores, evasión reactiva de obstáculos en tiempo real y estabilización de rumbo mediante fusión sensorial inercial (IMU) y óptica (ToF).

---

## 1. Visión General del Sistema

El robot adopta una arquitectura compacta y eficiente orientada a validar conceptos fundamentales de mecatrónica y robótica móvil con hardware accesible:

- **Cinemática Diferencial (2WD + Caster Ball):** Dos ruedas motrices ($R_{wheel} = 32.5\text{ mm}$) impulsadas por motores reductores TT amarillos ($1:48$) con ancho de vía ($W_{track} = 145\text{ mm}$) montados en un chasis acrílico liviano.
- **Unidad de Cómputo Unificada (Single ESP32):** Un único microcontrolador gestiona en lazo cerrado ($50\text{ Hz}$) la lectura I2C, el filtro de rumbo inercial, la máquina de estados de navegación y la generación de señales PWM a $20\text{ kHz}$.
- **Percepción Dual ToF (VL53L0X):** Medición de distancia milimétrica en sectores frontales izquierdo y derecho con inicialización secuencial por hardware (`XSHUT`) para resolver colisiones de bus I2C.
- **Estabilización de Rumbo (MPU6050):** Control PI sobre el giróscopo del eje Z (*heading hold*) que compensa dinámicamente las tolerancias mecánicas de los motores para mantener trayectoria recta exacta sin necesidad de encoders de rueda.
- **Etapa de Potencia de Alta Eficiencia (TB6612FNG):** Puente H con transistores MOSFET que optimizan el rendimiento de la batería Li-Ion 2S ($7.4\text{ V}$) frente a drivers bipolares tradicionales.

---

## 2. Presupuesto de Construcción (BOM en Soles)

El proyecto se construyó reutilizando sensores y microcontroladores ya disponibles en el laboratorio, con una inversión neta de **S/. 62 a S/. 73**:

| Componente | Especificación Técnica | Cantidad | Costo Estimado (PEN) |
|---|---|:---:|:---:|
| **Kit Chasis 2WD Smart Car** | Plataforma acrílica + 2 motores TT (1:48) + 2 ruedas (65 mm) + 1 rueda loca | 1 | S/. 28.00 - 32.00 |
| **Baterías 18650 Li-Ion** | Celdas 3.7V recargables (2S = 7.4V nominal) | 2 | S/. 24.00 - 28.00 |
| **Portapilas 2x 18650** | Soporte para montaje | 1 | S/. 4.00 - 5.00 |
| **Módulo Buck DC-DC** | Mini MP1584EN o LM2596 (reductor a 5.0V para el ESP32) | 1 | S/. 6.00 - 8.00 |
| **ESP32 + MPU6050 + 2x ToF + TB6612** | Disponibles previamente en el laboratorio | — | S/. 0.00 |
| **TOTAL MÓDULOS Y MECÁNICA** | | | **S/. 62.00 - 73.00** |

---

## 3. Estructura del Repositorio

```text
proyecto-robot-autonomo/
├── docs/                     # Diagramas de flujo y arquitectura
├── hardware/
│   ├── electronics/          # Esquemáticos, distribución de potencia y pinout (README.md)
│   └── mechanics/            # Planos mecánicos y especificaciones de chasis
├── software/
│   └── firmware/             # Firmware modular para ESP32 (Arduino / PlatformIO)
│       ├── platformio.ini    # Configuración de compilación y dependencias
│       ├── include/
│       │   ├── robot_config.h           # Constantes físicas, umbrales y asignación de pines
│       │   ├── tb6612_driver.h          # Abstracción del driver de motores
│       │   ├── sensor_manager.h         # Inicialización XSHUT ToF y filtro MPU6050
│       │   └── navigation_controller.h  # Máquina de estados y control de rumbo PI
│       └── src/
│           ├── main.cpp                 # Loop de control a 50 Hz y comandos Serial
│           ├── tb6612_driver.cpp
│           ├── sensor_manager.cpp
│           └── navigation_controller.cpp
└── legacy/                   # Archivos históricos de audio TinyML y simulación pesada
```

---

## 4. Guía de Inicio Rápido

### A. Preparación Eléctrica
1. Conectar las baterías 18650 al módulo Buck.
2. **Antes de conectar el ESP32**, girar el potenciómetro del módulo Buck hasta medir exactamente **5.00V** en la salida con un multímetro.
3. Conectar la salida del Buck al pin **VIN** del ESP32 y asegurar la masa común (*Star Ground*).

### B. Compilación y Flasheo del Firmware
Con **PlatformIO** (CLI o extensión en VS Code / Cursor):
```bash
cd software/firmware
pio run --target upload
pio device monitor -b 115200
```
O desde el **Arduino IDE**:
1. Abrir `software/firmware/src/main.cpp` (o renombrar la carpeta para abrirlo como sketch).
2. Instalar desde el gestor de bibliotecas: `Adafruit_VL53L0X`.
3. Seleccionar placa **ESP32 Dev Module** y puerto correspondiente.
4. Compilar y subir.

### C. Calibración y Operación
1. Al encender el robot, **mantenerlo quieto sobre una superficie plana durante 2 segundos** mientras calibra el offset del giroscopio MPU6050.
2. En el Monitor Serial (115200 baudios):
   - Enviar `s` para iniciar la navegación autónoma.
   - Enviar `x` para frenado inmediato.
   - Enviar `c` para recalibrar el giróscopo.
   - Enviar `r` para reiniciar el rumbo actual a 0°.
