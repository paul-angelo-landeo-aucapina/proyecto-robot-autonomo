#pragma once

#include <Arduino.h>

/**
 * @file robot_config.h
 * @brief Hardware pinout, physical parameters, and system thresholds for 2WD Mini Robot.
 */

namespace Config {

// --- Physical & Kinematic Parameters (2WD Acrylic Kit) ---
constexpr float WHEEL_RADIUS   = 0.0325f;  // Meters (65 mm diameter / 2)
constexpr float TRACK_WIDTH    = 0.1450f;  // Meters (145 mm track width)
constexpr float MAX_LINEAR_VEL = 0.35f;    // Max speed approx 0.35 m/s at 6V TT motor

// --- Motor Driver Pins (TB6612FNG) ---
constexpr int PIN_STBY = 25;  // Standby pin (HIGH = Active)

// Left Motor (Motor A)
constexpr int PIN_PWMA = 18;  // PWM speed control (LEDC)
constexpr int PIN_AIN1 = 19;  // Direction logic 1
constexpr int PIN_AIN2 = 23;  // Direction logic 2

// Right Motor (Motor B)
constexpr int PIN_PWMB = 5;   // PWM speed control (LEDC)
constexpr int PIN_BIN1 = 17;  // Direction logic 1
constexpr int PIN_BIN2 = 16;  // Direction logic 2

// PWM Configuration (LEDC Timer)
constexpr int PWM_FREQ       = 20000; // 20 kHz (inaudible frequency, no motor hum)
constexpr int PWM_RESOLUTION = 8;     // 8-bit resolution (0 - 255)
constexpr int PWM_CH_A       = 0;     // LEDC Channel for Left Motor
constexpr int PWM_CH_B       = 1;     // LEDC Channel for Right Motor

// --- I2C Bus Configuration ---
constexpr int PIN_I2C_SDA = 21;
constexpr int PIN_I2C_SCL = 22;
constexpr uint32_t I2C_FREQ = 400000; // 400 kHz Fast-Mode I2C

// --- I2C Device Addresses ---
constexpr uint8_t ADDR_MPU6050   = 0x68; // Default address (AD0 to GND)
constexpr uint8_t ADDR_TOF_LEFT  = 0x30; // Reassigned dynamically via XSHUT
constexpr uint8_t ADDR_TOF_RIGHT = 0x29; // Kept at default VL53L0X address

// --- ToF XSHUT Hardware Control Pins ---
constexpr int PIN_XSHUT_LEFT  = 32; // Active high enable for Left ToF
constexpr int PIN_XSHUT_RIGHT = 33; // Active high enable for Right ToF

// --- Navigation & Control Thresholds ---
constexpr uint16_t TOF_OBSTACLE_DIST_MM = 180; // Trigger obstacle stop at 180 mm (18 cm)
constexpr uint16_t TOF_CRITICAL_DIST_MM = 80;  // Emergency reverse trigger at 80 mm (8 cm)
constexpr float HEADING_KP              = 2.2f; // Proportional gain for gyro straight-line hold
constexpr float HEADING_KI              = 0.05f;// Integral gain
constexpr float ROTATION_SPEED_PWM      = 140.0f; // PWM speed for 90-degree pivot turns

// --- Timing Loop ---
constexpr uint32_t CONTROL_LOOP_MS = 20; // 50 Hz control loop frequency

} // namespace Config
