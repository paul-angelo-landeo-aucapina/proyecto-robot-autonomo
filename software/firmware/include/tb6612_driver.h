#pragma once

#include <Arduino.h>
#include "robot_config.h"

/**
 * @class TB6612Driver
 * @brief Hardware abstraction layer for the TB6612FNG dual DC motor driver on ESP32.
 */
class TB6612Driver {
public:
    TB6612Driver();

    /**
     * @brief Configure GPIOs, initialize LEDC PWM channels, and place driver in standby.
     */
    void begin();

    /**
     * @brief Enable the H-bridges (takes driver out of standby mode).
     */
    void enable();

    /**
     * @brief Put the driver in standby (high-impedance outputs, saves battery).
     */
    void standby();

    /**
     * @brief Set speeds for both differential motors.
     * @param speedLeft  Value between -255 (full reverse) and +255 (full forward).
     * @param speedRight Value between -255 (full reverse) and +255 (full forward).
     */
    void setMotors(int16_t speedLeft, int16_t speedRight);

    /**
     * @brief Active electronic brake on both motors (shorts motor terminals to GND).
     */
    void brake();

    /**
     * @brief Coast both motors to a stop (PWM = 0).
     */
    void stop();

private:
    bool _enabled;
    const int16_t _deadband = 45; // Minimum PWM required to overcome static gearbox friction

    void setLeftMotor(int16_t speed);
    void setRightMotor(int16_t speed);
    void writePwm(uint8_t channel, int pin, uint8_t value);
};
