# Módulo de Entrenamiento IA, Firmwares y Telemetría — Proyecto Robot Autónomo

Este directorio concentra los firmwares embebidos de tiempo real para microcontroladores ESP32 y ESP32-S3, los scripts de entrenamiento de redes neuronales convolucionales para reconocimiento de voz en el borde (TinyML / Edge AI) y el panel web de supervisión y telemetría por WebSockets del **Proyecto Robot Autónomo (`proyecto-robot-autonomo`)**.

---

## 1. Índice de Archivos y Componentes

| Archivo | Plataforma / Lenguaje | Función Principal |
|---|---|---|
| [`Control de movimiento, cinemática y telemetría.ino`](Control%20de%20movimiento,%20cinemática%20y%20telemetría.ino) | Arduino C++ / ESP32 | Firmware principal: cinemática diferencial, driver VNH5019, máquina de estados y servidor WebSockets |
| [`Captura de audio por IS2 y Pipeline de voz.ino`](Captura%20de%20audio%20por%20IS2%20y%20Pipeline%20de%20voz.ino) | ESP-IDF C / ESP32-S3 | Firmware de audio: captura I2S mono (INMP441) y reproducción I2S (MAX98357A) bajo FreeRTOS |
| [`Entrenamiento del carrito.py`](Entrenamiento%20del%20carrito.py) | Python 3 / TensorFlow | Generación de dataset sintético de audio y entrenamiento de red convolucional para comandos de voz |
| [`Red neuronal de audio.py`](Red%20neuronal%20de%20audio.py) | Python 3 / Librosa & Keras | Extracción de matrices MFCC, entrenamiento del modelo TinyML y exportación automática a cabecera C (`model_data.h`) |
| [`script entrenamiento.js`](script%20entrenamiento.js) | React (JavaScript / JSX) | Componente frontend de panel de control y telemetría en tiempo real mediante cliente WebSocket |

---

## 2. Guía de Ejecución y Entrenamiento de Inteligencia Artificial

### A. Preparación del Entorno Virtual de Python
Para entrenar las redes neuronales de audio y generar el modelo embebido para ESP32-S3:
```bash
# Crear entorno virtual
python3 -m venv .venv

# Activar entorno virtual
source .venv/bin/activate

# Instalar dependencias científicas y de Deep Learning
pip install tensorflow librosa numpy scipy
```

---

### B. Entrenamiento del Modelo TinyML y Exportación a C (`model_data.h`)
El script [`Red neuronal de audio.py`](Red%20neuronal%20de%20audio.py) procesa muestras de audio mono a $16\text{ kHz}$ durante ventanas de $1.0\text{ s}$, extrayendo $40$ coeficientes MFCC ($N_{fft} = 512$, $hop\_length = 256$):
1. **Comandos clasificados:** `["silencio", "avanzar", "retroceder", "girar", "detener"]`.
2. **Ejecutar el script:**
   ```bash
   python3 "Red neuronal de audio.py"
   ```
3. **Salida generada:**
   El script compila la arquitectura convolucional 2D, convierte el modelo a formato TensorFlow Lite (`.tflite`) y exporta el archivo de cabecera `model_data.h` que contiene el arreglo de bytes en C listo para ser incrustado en el proyecto ESP-IDF del ESP32-S3.

---

### C. Generación y Validación de Comandos de Voz
Para ejecutar el pipeline ampliado con ruido ambiente y palabras fuera de vocabulario:
```bash
python3 "Entrenamiento del carrito.py"
```
Este script entrena una red neuronal con $6$ clases oficiales (`_silencio_`, `_desconocido_`, `avanzar`, `retroceder`, `girar`, `detener`) y valida la convergencia de la función de pérdida categórica.

---

## 3. Compilación y Carga de Firmwares Embebidos

### A. Firmware Principal de Control (`Control de movimiento, cinemática y telemetría.ino`)
- **Microcontrolador Destino:** Placa de desarrollo ESP32 (NodeMCU-32S, ESP32 DevKit v1 o similar).
- **Parámetros Cinemáticos Configurados:**
  - Ancho de vía: $W_{track} = 0.330\text{ m}$ ($330\text{ mm}$).
  - Radio de rueda: $R_w = 0.0325\text{ m}$ ($32.5\text{ mm}$, diámetro $65\text{ mm}$).
- **Pines del Driver de Motores (VNH5019):**
  - Motor Derecho: PWM en `GPIO 25`, DIR en `GPIO 26`.
  - Motor Izquierdo: PWM en `GPIO 27`, DIR en `GPIO 14`.
- **Librerías Arduino Requeridas:**
  - `WiFi` (integrada en el ESP32 core).
  - `WebSockets` de Markus Sattler (`arduinoWebSockets`).
  - `ArduinoJson` (versión $\ge 6.19$ o v7).
- **Procedimiento:**
  1. Abrir el archivo en Arduino IDE.
  2. Seleccionar placa **ESP32 Dev Module**.
  3. Compilar y flashear a través del puerto serie USB (`/dev/ttyUSB0` o `COMx`).
  4. El ESP32 creará un Punto de Acceso WiFi con IP `192.168.4.1` e iniciará el servidor WebSockets en el puerto `81`.

---

### B. Firmware de Audio I2S y FreeRTOS (`Captura de audio por IS2 y Pipeline de voz.ino`)
- **Microcontrolador Destino:** Placa ESP32-S3 (soporta instrucciones vectoriales para aceleración de inferencia TinyML).
- **Pines del Bus I2S:**
  - **Micrófono INMP441 (Entrada RX):** `BCLK` $\rightarrow$ `GPIO 4`, `WS` $\rightarrow$ `GPIO 5`, `DIN` $\rightarrow$ `GPIO 6`.
  - **Amplificador MAX98357A (Salida TX):** `BCLK` $\rightarrow$ `GPIO 15`, `WS` $\rightarrow$ `GPIO 16`, `DOUT` $\rightarrow$ `GPIO 7`.
- **Procedimiento:**
  1. Compilar con ESP-IDF (v5.x) o Arduino-ESP32 configurado para ESP32-S3.
  2. Verificar en el monitor serie a 115200 baudios que las tareas FreeRTOS de captura y reproducción de audio inicien correctamente sin pérdida de paquetes DMA.

---

## 4. Uso del Dashboard de Telemetría (`script entrenamiento.js`)

El archivo [`script entrenamiento.js`](script%20entrenamiento.js) es un componente React listo para integrarse en cualquier aplicación web de monitoreo:

### Integración en un Proyecto React (Vite / Next.js / Create React App):
1. Copiar el archivo como `RobotDashboard.jsx` en la carpeta `src/components/` de la aplicación web.
2. Asegurar que la máquina host esté conectada a la red WiFi del robot (`192.168.4.x`).
3. El componente se conectará automáticamente a `ws://192.168.4.1:81/` y reflejará en vivo:
   - Estado de la conexión (Conectado / Desconectado).
   - Porcentaje de batería en tiempo real.
   - Peso de carga útil en la balanza superior (en kg).
   - Alerta visual de obstáculo frontal.
   - Estado operativo de la máquina (`ESPERA`, `MANUAL`, `AUTONOMO`, `EMERGENCIA`).
