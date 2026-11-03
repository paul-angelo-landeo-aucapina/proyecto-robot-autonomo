/**
 * ROBOT DIFERENCIAL DE TRANSPORTE - FIRMWARE ESP32 PRINCIPAL
 * Cinemática: W_track = 0.33 m, R_wheel = 0.0325 m
 */

#include <Arduino.h>
#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>

// --- Parámetros Físicos (Memoria Técnica del PDF) ---
const float W_TRACK = 0.330;   // Ancho de vía en metros (330 mm)
const float R_WHEEL = 0.0325;  // Radio de rueda en metros (65 mm / 2)

// --- Asignación de Pines Motores (Driver Dual VNH5019) ---
const int PIN_PWM_RIGHT = 25;
const int PIN_DIR_RIGHT = 26;
const int PIN_PWM_LEFT  = 27;
const int PIN_DIR_LEFT  = 14;

// --- Máquina de Estados (Sección 3.4 del PDF) ---
enum RobotState {
  INICIALIZANDO,
  ESPERA,
  MANUAL,
  VOZ,
  TRANSPORTE,
  OBSTACULO,
  EMERGENCIA
};
RobotState currentState = INICIALIZANDO;

// --- Variables de Telemetría ---
int batteryPercent = 85;
float weightKg = 0.0;
bool obstacleDetected = false;

// Servidor WebSocket en el puerto 81
WebSocketsServer webSocket = WebSocketsServer(81);
HardwareSerial SerialVoice(2); // UART2 (RX2: 16, TX2: 17) hacia ESP32-S3

// --- Función Cinemática Diferencial (Sección 3.2 del PDF) ---
void calculateWheelVelocities(float v, float omega, float &w_right, float &w_left) {
  // v_D = v + (W_track / 2) * omega
  // v_I = v - (W_track / 2) * omega
  float v_right = v + (W_TRACK / 2.0f) * omega;
  float v_left  = v - (W_TRACK / 2.0f) * omega;

  // omega = v_lineal / r
  w_right = v_right / R_WHEEL; // rad/s
  w_left  = v_left  / R_WHEEL; // rad/s
}

void applyMotorPwm(float w_right, float w_left) {
  // Conversión proporcional simple rad/s -> PWM (0 a 255) para motores 300 RPM (aprox 31.4 rad/s)
  const float MAX_W = 31.4f;
  
  int pwm_r = constrain(abs(w_right) * (255.0f / MAX_W), 0, 255);
  int pwm_l = constrain(abs(w_left)  * (255.0f / MAX_W), 0, 255);

  digitalWrite(PIN_DIR_RIGHT, w_right >= 0 ? HIGH : LOW);
  analogWrite(PIN_PWM_RIGHT, pwm_r);

  digitalWrite(PIN_DIR_LEFT, w_left >= 0 ? HIGH : LOW);
  analogWrite(PIN_PWM_LEFT, pwm_l);
}

void stopMotors() {
  analogWrite(PIN_PWM_RIGHT, 0);
  analogWrite(PIN_PWM_LEFT, 0);
}

// --- Manejador del Protocolo WebSocket (Sección 4.4 del PDF) ---
void onWebSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  if (type == WStype_TEXT) {
    StaticJsonDocument<256> doc;
    DeserializationError error = deserializeJson(doc, payload);
    if (error) return;

    const char* msgType = doc["type"];
    if (strcmp(msgType, "movement") == 0) {
      if (currentState == EMERGENCIA || currentState == OBSTACULO) {
        stopMotors();
        return;
      }

      currentState = MANUAL;
      float vx = doc["vx"]; // Velocidad lineal (m/s)
      float w  = doc["w"];  // Velocidad angular (rad/s)

      float wr, wl;
      calculateWheelVelocities(vx, w, wr, wl);
      applyMotorPwm(wr, wl);
    }
  }
}

void sendTelemetry() {
  StaticJsonDocument<192> doc;
  doc["type"]     = "telemetry";
  doc["battery"]  = batteryPercent;
  doc["weight"]   = weightKg;
  doc["obstacle"] = obstacleDetected;
  
  switch(currentState) {
    case ESPERA: doc["state"] = "READY"; break;
    case MANUAL: doc["state"] = "MANUAL"; break;
    case VOZ: doc["state"] = "VOICE"; break;
    case OBSTACULO: doc["state"] = "OBSTACLE"; break;
    case EMERGENCIA: doc["state"] = "EMERGENCY"; break;
    default: doc["state"] = "BUSY"; break;
  }

  String jsonString;
  serializeJson(doc, jsonString);
  webSocket.broadcastTXT(jsonString);
}

void setup() {
  Serial.begin(115200);
  SerialVoice.begin(115200, SERIAL_8N1, 16, 17); // UART con ESP32-S3

  pinMode(PIN_PWM_RIGHT, OUTPUT);
  pinMode(PIN_DIR_RIGHT, OUTPUT);
  pinMode(PIN_PWM_LEFT, OUTPUT);
  pinMode(PIN_DIR_LEFT, OUTPUT);
  stopMotors();

  // Conexión WiFi en modo AP o Estación
  WiFi.softAP("Robot_Transportador", "password123");
  webSocket.begin();
  webSocket.onEvent(onWebSocketEvent);

  currentState = ESPERA;
}

void loop() {
  webSocket.loop();

  // Lectura de comandos por UART desde ESP32-S3 (Voz)
  if (SerialVoice.available()) {
    String voiceCmd = SerialVoice.readStringUntil('\n');
    voiceCmd.trim();
    if (voiceCmd == "CMD_AVANZAR") {
      float wr, wl;
      calculateWheelVelocities(0.3f, 0.0f, wr, wl);
      applyMotorPwm(wr, wl);
      currentState = VOZ;
    } else if (voiceCmd == "CMD_DETENER") {
      stopMotors();
      currentState = ESPERA;
    }
  }

  // Envío periódico de telemetría a la aplicación React (cada 200 ms)
  static unsigned long lastTelemetry = 0;
  if (millis() - lastTelemetry > 200) {
    lastTelemetry = millis();
    sendTelemetry();
  }
}C
