#include "tb6612_driver.h"

TB6612Driver::TB6612Driver() : _enabled(false) {}

void TB6612Driver::begin() {
    // Configure control and direction GPIOs
    pinMode(Config::PIN_STBY, OUTPUT);
    pinMode(Config::PIN_AIN1, OUTPUT);
    pinMode(Config::PIN_AIN2, OUTPUT);
    pinMode(Config::PIN_BIN1, OUTPUT);
    pinMode(Config::PIN_BIN2, OUTPUT);

    // Initial state: Standby, zero outputs
    standby();
    stop();

    // Configure PWM channels
#if defined(ESP_ARDUINO_VERSION_MAJOR) && (ESP_ARDUINO_VERSION_MAJOR >= 3)
    ledcAttach(Config::PIN_PWMA, Config::PWM_FREQ, Config::PWM_RESOLUTION);
    ledcAttach(Config::PIN_PWMB, Config::PWM_FREQ, Config::PWM_RESOLUTION);
#else
    ledcSetup(Config::PWM_CH_A, Config::PWM_FREQ, Config::PWM_RESOLUTION);
    ledcAttachPin(Config::PIN_PWMA, Config::PWM_CH_A);

    ledcSetup(Config::PWM_CH_B, Config::PWM_FREQ, Config::PWM_RESOLUTION);
    ledcAttachPin(Config::PIN_PWMB, Config::PWM_CH_B);
#endif
}

void TB6612Driver::enable() {
    _enabled = true;
    digitalWrite(Config::PIN_STBY, HIGH);
}

void TB6612Driver::standby() {
    _enabled = false;
    digitalWrite(Config::PIN_STBY, LOW);
}

void TB6612Driver::writePwm(uint8_t channel, int pin, uint8_t value) {
#if defined(ESP_ARDUINO_VERSION_MAJOR) && (ESP_ARDUINO_VERSION_MAJOR >= 3)
    ledcWrite(pin, value);
#else
    ledcWrite(channel, value);
#endif
}

void TB6612Driver::setLeftMotor(int16_t speed) {
    if (!_enabled) return;

    speed = constrain(speed, -255, 255);

    if (abs(speed) > 0 && abs(speed) < _deadband) {
        speed = (speed > 0) ? _deadband : -_deadband;
    }

    if (speed > 0) {
        // Forward
        digitalWrite(Config::PIN_AIN1, HIGH);
        digitalWrite(Config::PIN_AIN2, LOW);
        writePwm(Config::PWM_CH_A, Config::PIN_PWMA, (uint8_t)speed);
    } else if (speed < 0) {
        // Reverse
        digitalWrite(Config::PIN_AIN1, LOW);
        digitalWrite(Config::PIN_AIN2, HIGH);
        writePwm(Config::PWM_CH_A, Config::PIN_PWMA, (uint8_t)(-speed));
    } else {
        // Coast stop
        digitalWrite(Config::PIN_AIN1, LOW);
        digitalWrite(Config::PIN_AIN2, LOW);
        writePwm(Config::PWM_CH_A, Config::PIN_PWMA, 0);
    }
}

void TB6612Driver::setRightMotor(int16_t speed) {
    if (!_enabled) return;

    speed = constrain(speed, -255, 255);

    if (abs(speed) > 0 && abs(speed) < _deadband) {
        speed = (speed > 0) ? _deadband : -_deadband;
    }

    if (speed > 0) {
        // Forward
        digitalWrite(Config::PIN_BIN1, HIGH);
        digitalWrite(Config::PIN_BIN2, LOW);
        writePwm(Config::PWM_CH_B, Config::PIN_PWMB, (uint8_t)speed);
    } else if (speed < 0) {
        // Reverse
        digitalWrite(Config::PIN_BIN1, LOW);
        digitalWrite(Config::PIN_BIN2, HIGH);
        writePwm(Config::PWM_CH_B, Config::PIN_PWMB, (uint8_t)(-speed));
    } else {
        // Coast stop
        digitalWrite(Config::PIN_BIN1, LOW);
        digitalWrite(Config::PIN_BIN2, LOW);
        writePwm(Config::PWM_CH_B, Config::PIN_PWMB, 0);
    }
}

void TB6612Driver::setMotors(int16_t speedLeft, int16_t speedRight) {
    setLeftMotor(speedLeft);
    setRightMotor(speedRight);
}

void TB6612Driver::brake() {
    if (!_enabled) return;
    // TB6612 Active Braking: IN1=HIGH, IN2=HIGH, PWM=255
    digitalWrite(Config::PIN_AIN1, HIGH);
    digitalWrite(Config::PIN_AIN2, HIGH);
    digitalWrite(Config::PIN_BIN1, HIGH);
    digitalWrite(Config::PIN_BIN2, HIGH);
    writePwm(Config::PWM_CH_A, Config::PIN_PWMA, 255);
    writePwm(Config::PWM_CH_B, Config::PIN_PWMB, 255);
}

void TB6612Driver::stop() {
    digitalWrite(Config::PIN_AIN1, LOW);
    digitalWrite(Config::PIN_AIN2, LOW);
    digitalWrite(Config::PIN_BIN1, LOW);
    digitalWrite(Config::PIN_BIN2, LOW);
    writePwm(Config::PWM_CH_A, Config::PIN_PWMA, 0);
    writePwm(Config::PWM_CH_B, Config::PIN_PWMB, 0);
}
