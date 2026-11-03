#include <Arduino.h>
#include "robot_config.h"
#include "tb6612_driver.h"
#include "sensor_manager.h"
#include "navigation_controller.h"

// Hardware and logic instances
TB6612Driver motors;
SensorManager sensors;
NavigationController nav(sensors, motors);

uint32_t lastLoopTime = 0;
uint32_t lastTelemetryTime = 0;

void printTelemetry() {
    const SensorReadings& r = sensors.getReadings();
    const char* stateStr = "UNKNOWN";
    switch (nav.getState()) {
        case NAV_STOP:       stateStr = "STOP"; break;
        case NAV_FORWARD:    stateStr = "FORWARD"; break;
        case NAV_BACKUP:     stateStr = "BACKUP"; break;
        case NAV_PIVOT_TURN: stateStr = "PIVOT_TURN"; break;
        case NAV_EMERGENCY:  stateStr = "EMERGENCY"; break;
    }

    Serial.printf("[TELEM] State: %-10s | Heading: %6.1f deg | YawRate: %5.1f dps | ToF-L: %4d mm | ToF-R: %4d mm\n",
                  stateStr, r.headingDeg, r.yawRateDps, r.distLeftMm, r.distRightMm);
}

void handleSerialCommands() {
    if (!Serial.available()) return;
    char cmd = (char)Serial.read();

    switch (cmd) {
        case 's':
        case 'S':
            Serial.println("[CMD] Starting Autonomous Mode...");
            nav.start();
            break;

        case 'x':
        case 'X':
            Serial.println("[CMD] Stopping Robot (Brake)...");
            nav.stop();
            break;

        case 'c':
        case 'C':
            nav.stop();
            sensors.calibrateGyro(200);
            break;

        case 'r':
        case 'R':
            sensors.resetHeading();
            Serial.println("[CMD] Heading reset to 0.0 deg");
            break;

        case 'h':
        case 'H':
        case '?':
            Serial.println("\n--- Available Serial Commands ---");
            Serial.println("  s : Start autonomous navigation");
            Serial.println("  x : Emergency stop / Brake");
            Serial.println("  c : Re-calibrate gyro bias");
            Serial.println("  r : Reset current heading to 0");
            Serial.println("---------------------------------\n");
            break;

        default:
            break;
    }
}

void setup() {
    Serial.begin(115200);
    delay(1000);

    Serial.println("\n==============================================");
    Serial.println("   2WD MINI AUTONOMOUS ROBOT - FIRMWARE v2.0  ");
    Serial.println("   ESP32 Unified Architecture (< S/. 100)     ");
    Serial.println("==============================================\n");

    // 1. Initialize Motors (safe standby)
    Serial.println("[BOOT] Initializing TB6612FNG Motor Driver...");
    motors.begin();

    // 2. Initialize Sensors (I2C, ToF XSHUT, MPU6050)
    Serial.println("[BOOT] Initializing I2C & Sensors...");
    if (!sensors.begin()) {
        Serial.println("[FATAL] Sensor bus error. Check 3.3V power and I2C wiring.");
    }

    // 3. Calibrate Gyro Offset
    sensors.calibrateGyro(200);

    // 4. Initialize Navigation Controller
    nav.begin();

    Serial.println("\n[SYSTEM READY] Type 's' + Enter in Serial Monitor to begin.");
    lastLoopTime = millis();
}

void loop() {
    uint32_t now = millis();
    uint32_t dtMs = now - lastLoopTime;

    // Deterministic 50 Hz control loop (every 20 ms)
    if (dtMs >= Config::CONTROL_LOOP_MS) {
        lastLoopTime = now;
        float dtSec = (float)dtMs / 1000.0f;

        // 1. Read sensors and integrate heading
        sensors.update(dtSec);

        // 2. Run navigation state machine
        nav.update(dtSec);

        // 3. Periodic Telemetry (every 250 ms)
        if (now - lastTelemetryTime >= 250) {
            lastTelemetryTime = now;
            printTelemetry();
        }
    }

    // Handle user inputs via Serial
    handleSerialCommands();
}
