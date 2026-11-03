#include "sensor_manager.h"

SensorManager::SensorManager() 
    : _gyroZOffset(0.0f), _currentHeading(0.0f) {
    _readings = {2000, 2000, 0.0f, 0.0f, false, false};
}

bool SensorManager::begin() {
    // 1. Initialize I2C Bus at 400 kHz
    Wire.begin(Config::PIN_I2C_SDA, Config::PIN_I2C_SCL, Config::I2C_FREQ);
    delay(50);

    // 2. Hardware reset of both ToF sensors via XSHUT pins
    pinMode(Config::PIN_XSHUT_LEFT, OUTPUT);
    pinMode(Config::PIN_XSHUT_RIGHT, OUTPUT);
    digitalWrite(Config::PIN_XSHUT_LEFT, LOW);
    digitalWrite(Config::PIN_XSHUT_RIGHT, LOW);
    delay(20);

    // 3. Initialize MPU6050
    bool mpuOk = initMPU6050();
    if (!mpuOk) {
        Serial.println("[ERROR] MPU6050 initialization failed at 0x68");
    } else {
        Serial.println("[OK] MPU6050 detected and configured");
    }

    // 4. Sequential Boot of Left ToF (Reassign address to 0x30)
    digitalWrite(Config::PIN_XSHUT_LEFT, HIGH);
    delay(15);
    bool tofLeftOk = _tofLeft.begin(Config::ADDR_TOF_LEFT, false, &Wire);
    if (!tofLeftOk) {
        Serial.printf("[ERROR] Left ToF failed to initialize at 0x%02X\n", Config::ADDR_TOF_LEFT);
    } else {
        Serial.printf("[OK] Left ToF initialized and reassigned to 0x%02X\n", Config::ADDR_TOF_LEFT);
    }

    // 5. Sequential Boot of Right ToF (Keep default address 0x29)
    digitalWrite(Config::PIN_XSHUT_RIGHT, HIGH);
    delay(15);
    bool tofRightOk = _tofRight.begin(Config::ADDR_TOF_RIGHT, false, &Wire);
    if (!tofRightOk) {
        Serial.printf("[ERROR] Right ToF failed to initialize at 0x%02X\n", Config::ADDR_TOF_RIGHT);
    } else {
        Serial.printf("[OK] Right ToF initialized at default 0x%02X\n", Config::ADDR_TOF_RIGHT);
    }

    return mpuOk && tofLeftOk && tofRightOk;
}

bool SensorManager::initMPU6050() {
    // Check communication with WHO_AM_I register (0x75)
    Wire.beginTransmission(Config::ADDR_MPU6050);
    Wire.write(0x75);
    if (Wire.endTransmission(false) != 0) return false;

    Wire.requestFrom(Config::ADDR_MPU6050, (uint8_t)1);
    if (!Wire.available()) return false;
    uint8_t whoAmI = Wire.read();
    if (whoAmI != 0x68 && whoAmI != 0x70 && whoAmI != 0x72) {
        Serial.printf("[WARN] Unexpected MPU6050 WHO_AM_I: 0x%02X\n", whoAmI);
    }

    // Wake up MPU6050 (PWR_MGMT_1 = 0x00)
    Wire.beginTransmission(Config::ADDR_MPU6050);
    Wire.write(0x6B);
    Wire.write(0x00);
    Wire.endTransmission();
    delay(10);

    // Set Digital Low Pass Filter to ~42 Hz (CONFIG = 0x03)
    Wire.beginTransmission(Config::ADDR_MPU6050);
    Wire.write(0x1A);
    Wire.write(0x03);
    Wire.endTransmission();

    // Set Gyro Range to +/- 500 deg/s (GYRO_CONFIG = 0x08 -> 65.5 LSB / deg/s)
    Wire.beginTransmission(Config::ADDR_MPU6050);
    Wire.write(0x1B);
    Wire.write(0x08);
    Wire.endTransmission();

    return true;
}

float SensorManager::readRawGyroZ() {
    Wire.beginTransmission(Config::ADDR_MPU6050);
    Wire.write(0x47); // GYRO_ZOUT_H register
    if (Wire.endTransmission(false) != 0) return 0.0f;

    Wire.requestFrom(Config::ADDR_MPU6050, (uint8_t)2);
    if (Wire.available() < 2) return 0.0f;

    int16_t rawZ = (Wire.read() << 8) | Wire.read();
    return ((float)rawZ) / 65.5f; // Convert LSB to degrees/sec
}

void SensorManager::calibrateGyro(uint16_t samples) {
    Serial.println("[INFO] Calibrating MPU6050 gyro bias... KEEP ROBOT STILL");
    float sum = 0.0f;
    for (uint16_t i = 0; i < samples; ++i) {
        sum += readRawGyroZ();
        delay(5);
    }
    _gyroZOffset = sum / (float)samples;
    _currentHeading = 0.0f;
    Serial.printf("[OK] Gyro Z offset calibrated: %.3f deg/s\n", _gyroZOffset);
}

void SensorManager::update(float dtSec) {
    // 1. Gyroscope reading & integration
    float rawRate = readRawGyroZ();
    float correctedRate = rawRate - _gyroZOffset;

    // Small deadband to reject micro noise during standstill
    if (fabs(correctedRate) < 0.25f) {
        correctedRate = 0.0f;
    }

    _readings.yawRateDps = correctedRate;
    _currentHeading += correctedRate * dtSec;
    _readings.headingDeg = _currentHeading;

    // 2. Read Left ToF (VL53L0X)
    VL53L0X_RangingMeasurementData_t measureLeft;
    _tofLeft.rangingTest(&measureLeft, false);
    if (measureLeft.RangeStatus != 4) { // 4 = out of range / phase fail
        _readings.distLeftMm = measureLeft.RangeMilliMeter;
        _readings.leftValid = true;
    } else {
        _readings.distLeftMm = 2000;
        _readings.leftValid = false;
    }

    // 3. Read Right ToF (VL53L0X)
    VL53L0X_RangingMeasurementData_t measureRight;
    _tofRight.rangingTest(&measureRight, false);
    if (measureRight.RangeStatus != 4) {
        _readings.distRightMm = measureRight.RangeMilliMeter;
        _readings.rightValid = true;
    } else {
        _readings.distRightMm = 2000;
        _readings.rightValid = false;
    }
}

void SensorManager::resetHeading() {
    _currentHeading = 0.0f;
    _readings.headingDeg = 0.0f;
}
