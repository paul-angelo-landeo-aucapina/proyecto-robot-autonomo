# Arquitectura Electrónica y Distribución de Potencia — Robot Autónomo 2WD

Este documento define la arquitectura eléctrica, distribución de potencia, esquemas de conexión y asignación de pines del **Robot Móvil Autónomo 2WD (< S/. 100)** basado en un único **ESP32**, driver **TB6612FNG**, **MPU6050** y 2 sensores **VL53L0X (ToF)**.

---

## 1. Topología del Sistema Eléctrico

El circuito sigue el principio de **segregación estricta de potencia y señal con masa en estrella (*Star Ground*)**:
- La alta corriente de los motores TT pasa directamente desde las baterías hacia el pin `VM` del driver TB6612FNG.
- La electrónica sensible (ESP32 y sensores I2C) se aísla mediante un regulador reductor DC-DC tipo Buck (MP1584EN o LM2596) ajustado a **5.0V**.
- El regulador LDO integrado en la placa ESP32 genera una línea limpia de **3.3V** para alimentar los sensores y la lógica de control.

```mermaid
graph TD
    Bat["Pack Baterías 2S 18650 (7.4V - 8.4V)"] --> SW["Interruptor General ON/OFF"]
    SW --> Fuse["Fusible Rápido (2A - 3A)"]
    
    Fuse -->|VM 7.4V| TB["Driver Dual TB6612FNG"]
    Fuse --> Buck["Módulo Buck DC-DC (Ajustado a 5.0V)"]
    
    Buck -->|5.0V| VIN["ESP32: Pin VIN"]
    ESP32["ESP32 (WROOM-32)"]
    
    ESP32 -->|3.3V Out| BusVCC["Riel Lógico 3.3V"]
    BusVCC --> TB_VCC["TB6612FNG: Pin VCC"]
    BusVCC --> IMU["MPU6050 (IMU 6-DOF)"]
    BusVCC --> ToF1["ToF 1 (VL53L0X Izquierdo)"]
    BusVCC --> ToF2["ToF 2 (VL53L0X Derecho)"]
    
    TB --> MotL["Motor TT Izquierdo"]
    TB --> MotR["Motor TT Derecho"]
    
    ESP32 -->|GPIO 21 (SDA) / 22 (SCL)| BusI2C["Bus I2C Compartido (400 kHz)"]
    BusI2C --> IMU
    BusI2C --> ToF1
    BusI2C --> ToF2
    
    ESP32 -->|GPIO 32| XSHUT1["ToF 1: XSHUT (Reasigna a 0x30)"]
    ESP32 -->|GPIO 33| XSHUT2["ToF 2: XSHUT (Mantiene 0x29)"]
```

---

## 2. Puntos Críticos de Conexión y Hardware

### A. Secuencia de Arranque XSHUT para Dual ToF (VL53L0X)
Ambos sensores VL53L0X vienen de fábrica con la dirección I2C fija `0x29`. Para evitar colisión de bus:
1. El ESP32 arranca con `GPIO 32` y `GPIO 33` en `LOW` (ambos sensores apagados en hardware).
2. Se pone `GPIO 32` en `HIGH` (enciende solo ToF 1).
3. Se inicializa y se reasigna su dirección por software a `0x30` (`_tofLeft.begin(0x30)`).
4. Se pone `GPIO 33` en `HIGH` (enciende ToF 2).
5. Se inicializa ToF 2 en su dirección por defecto `0x29`.

### B. Pin de Standby (`STBY`) del TB6612FNG
El TB6612FNG cuenta con un pin `STBY`. Si se deja flotante o en `LOW`, las salidas de potencia quedan en alta impedancia y los motores no responderán al PWM. Está conectado a `GPIO 25` y el firmware lo activa en `HIGH`.

---

## 3. Matriz de Conexionado (Pinout Completo)

| Pin ESP32 | Dispositivo Destino | Pin Destino | Descripción de Función |
|---|---|---|---|
| **VIN** | Módulo Buck DC-DC | VOUT+ (5.0V) | Alimentación principal del microcontrolador |
| **GND** | Estrella de Tierra | GND Común | Retorno de corriente común |
| **3V3** | MPU6050, ToF 1, ToF 2, TB6612 | VCC | Alimentación lógica regulada (3.3V nativos) |
| **GPIO 21** | MPU6050 / ToF 1 / ToF 2 | SDA | Bus de datos I2C bidireccional |
| **GPIO 22** | MPU6050 / ToF 1 / ToF 2 | SCL | Señal de reloj I2C (400 kHz) |
| **GPIO 32** | ToF 1 (Izquierdo) | XSHUT | Habilitación y cambio de dirección a 0x30 |
| **GPIO 33** | ToF 2 (Derecho) | XSHUT | Habilitación ToF secundario (dirección 0x29) |
| **GPIO 25** | TB6612FNG | STBY | Habilitación del puente H (High = Operativo) |
| **GPIO 18** | TB6612FNG | PWMA | PWM velocidad Motor Izquierdo (20 kHz LEDC) |
| **GPIO 19** | TB6612FNG | AIN1 | Dirección 1 Motor Izquierdo |
| **GPIO 23** | TB6612FNG | AIN2 | Dirección 2 Motor Izquierdo |
| **GPIO 5**  | TB6612FNG | PWMB | PWM velocidad Motor Derecho (20 kHz LEDC) |
| **GPIO 17** | TB6612FNG | BIN1 | Dirección 1 Motor Derecho |
| **GPIO 16** | TB6612FNG | BIN2 | Dirección 2 Motor Derecho |

---

## 4. Presupuesto de Potencia y Autonomía

- **Capacidad de Batería:** 2x 18650 en serie = $7.4\text{ V nominal}$, $2200\text{ mAh}$ ($16.28\text{ Wh}$).
- **Consumo Promedio:**
  - En crucero autónomo: $\sim 380\text{ mA}$ promedio.
  - Autonomía teórica continua: $\frac{2200\text{ mAh}}{380\text{ mA}} \approx 5.7\text{ horas}$.
- **Seguridad:** Fusible rápido de $2\text{ A}$ intercalado tras el interruptor general.
