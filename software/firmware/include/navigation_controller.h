#pragma once

#include <Arduino.h>
#include "robot_config.h"
#include "sensor_manager.h"
#include "tb6612_driver.h"

enum NavState {
    NAV_STOP,
    NAV_FORWARD,
    NAV_BACKUP,
    NAV_PIVOT_TURN,
    NAV_EMERGENCY
};

/**
 * @class NavigationController
 * @brief Autonomous navigation state machine featuring gyro-stabilized heading hold
 *        and dual ToF obstacle avoidance.
 */
class NavigationController {
public:
    NavigationController(SensorManager& sensors, TB6612Driver& motors);

    /**
     * @brief Initialize controller variables and target heading.
     */
    void begin();

    /**
     * @brief Execute one iteration of the navigation state machine.
     * @param dtSec Elapsed time in seconds since previous step.
     */
    void update(float dtSec);

    /**
     * @brief Start autonomous roaming mode.
     */
    void start();

    /**
     * @brief Stop robot and transition to idle.
     */
    void stop();

    NavState getState() const { return _state; }

private:
    SensorManager& _sensors;
    TB6612Driver& _motors;

    NavState _state;
    float _targetHeading;
    float _headingIntegral;
    uint32_t _stateTimer;

    int16_t _baseForwardSpeed = 160; // Base forward PWM for TT motors (smooth cruise)

    void handleForward(const SensorReadings& readings, float dtSec);
    void handlePivotTurn(const SensorReadings& readings);
    void handleBackup();
};
