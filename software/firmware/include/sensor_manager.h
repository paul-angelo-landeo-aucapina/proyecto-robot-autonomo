#pragma once

#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_VL53L0X.h>
#include "robot_config.h"

/**
 * @struct SensorReadings
 * @brief Aggregated readings from perception and inertial sensors.
 */
struct SensorReadings {
    uint16_t distLeftMm;   // Distance measured by Left ToF (0 - 2000 mm)
    uint16_t distRightMm;  // Distance measured by Right ToF (0 - 2000 mm)
    float yawRateDps;      // Angular velocity around Z axis (degrees/sec)
    float headingDeg;      // Integrated heading angle (degrees)
    bool leftValid;        // True if left reading is valid
    bool rightValid;       // True if right reading is valid
};

/**
 * @class SensorManager
 * @brief Orchestrates I2C initialization, sequential ToF XSHUT address assignment,
 *        and MPU6050 gyro drift calibration.
 */
class SensorManager {
public:
    SensorManager();

    /**
     * @brief Initialize I2C bus, boot ToF sensors sequentially, and wake MPU6050.
     * @return true if all devices initialized successfully.
     */
    bool begin();

    /**
     * @brief Calibrate gyro bias while robot is stationary (runs in setup).
     * @param samples Number of samples to average (default: 200).
     */
    void calibrateGyro(uint16_t samples = 200);

    /**
     * @brief Update sensor readings and integrate heading. Call at periodic interval (e.g. 50Hz).
     * @param dtSec Time delta since last update in seconds.
     */
    void update(float dtSec);

    /**
     * @brief Reset integrated heading angle to zero.
     */
    void resetHeading();

    /**
     * @brief Get the latest aggregated sensor readings.
     */
    const SensorReadings& getReadings() const { return _readings; }

private:
    Adafruit_VL53L0X _tofLeft;
    Adafruit_VL53L0X _tofRight;
    SensorReadings _readings;

    float _gyroZOffset;
    float _currentHeading;

    bool initMPU6050();
    float readRawGyroZ();
};
