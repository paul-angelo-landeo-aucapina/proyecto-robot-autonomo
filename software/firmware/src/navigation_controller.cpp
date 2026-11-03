#include "navigation_controller.h"

NavigationController::NavigationController(SensorManager& sensors, TB6612Driver& motors)
    : _sensors(sensors), _motors(motors), _state(NAV_STOP), 
      _targetHeading(0.0f), _headingIntegral(0.0f), _stateTimer(0) {}

void NavigationController::begin() {
    _state = NAV_STOP;
    _targetHeading = 0.0f;
    _headingIntegral = 0.0f;
    _motors.stop();
}

void NavigationController::start() {
    _targetHeading = _sensors.getReadings().headingDeg;
    _headingIntegral = 0.0f;
    _state = NAV_FORWARD;
    _motors.enable();
    Serial.println("[NAV] Autonomous Navigation Started - Moving FORWARD");
}

void NavigationController::stop() {
    _state = NAV_STOP;
    _motors.stop();
    Serial.println("[NAV] Autonomous Navigation Stopped");
}

void NavigationController::update(float dtSec) {
    const SensorReadings& readings = _sensors.getReadings();

    switch (_state) {
        case NAV_STOP:
            _motors.stop();
            break;

        case NAV_FORWARD:
            handleForward(readings, dtSec);
            break;

        case NAV_BACKUP:
            handleBackup();
            break;

        case NAV_PIVOT_TURN:
            handlePivotTurn(readings);
            break;

        case NAV_EMERGENCY:
            _motors.brake();
            break;
    }
}

void NavigationController::handleForward(const SensorReadings& readings, float dtSec) {
    // 1. Critical proximity check -> Emergency reverse
    if (readings.distLeftMm < Config::TOF_CRITICAL_DIST_MM || 
        readings.distRightMm < Config::TOF_CRITICAL_DIST_MM) {
        Serial.printf("[NAV] Critical distance detected (L:%d, R:%d mm) -> BACKUP\n",
                      readings.distLeftMm, readings.distRightMm);
        _motors.brake();
        _state = NAV_BACKUP;
        _stateTimer = millis();
        return;
    }

    // 2. Obstacle threshold check -> Prepare pivot turn
    if (readings.distLeftMm < Config::TOF_OBSTACLE_DIST_MM || 
        readings.distRightMm < Config::TOF_OBSTACLE_DIST_MM) {
        _motors.brake();
        _state = NAV_PIVOT_TURN;

        // Turn away from the closer obstacle (compare left vs right clearance)
        if (readings.distLeftMm < readings.distRightMm) {
            // Left is blocked -> Turn Right (+90 degrees)
            _targetHeading = readings.headingDeg + 90.0f;
            Serial.printf("[NAV] Obstacle on Left (%d mm). Turning RIGHT to target %.1f deg\n", 
                          readings.distLeftMm, _targetHeading);
        } else {
            // Right is blocked -> Turn Left (-90 degrees)
            _targetHeading = readings.headingDeg - 90.0f;
            Serial.printf("[NAV] Obstacle on Right (%d mm). Turning LEFT to target %.1f deg\n", 
                          readings.distRightMm, _targetHeading);
        }
        _stateTimer = millis();
        return;
    }

    // 3. Gyro-assisted Heading Hold Control (Straight line stabilization)
    float headingError = _targetHeading - readings.headingDeg;
    _headingIntegral += headingError * dtSec;
    _headingIntegral = constrain(_headingIntegral, -20.0f, 20.0f); // Anti-windup

    float correction = (Config::HEADING_KP * headingError) + (Config::HEADING_KI * _headingIntegral);
    correction = constrain(correction, -60.0f, 60.0f);

    int16_t speedLeft  = (int16_t)(_baseForwardSpeed - correction);
    int16_t speedRight = (int16_t)(_baseForwardSpeed + correction);

    _motors.setMotors(speedLeft, speedRight);
}

void NavigationController::handleBackup() {
    // Reverse for 250 ms to clear obstacle clearance cone
    if (millis() - _stateTimer < 250) {
        _motors.setMotors(-150, -150);
    } else {
        _motors.brake();
        const SensorReadings& readings = _sensors.getReadings();
        _state = NAV_PIVOT_TURN;
        // Turn 90 degrees away
        _targetHeading = readings.headingDeg + (readings.distLeftMm < readings.distRightMm ? 90.0f : -90.0f);
        _stateTimer = millis();
    }
}

void NavigationController::handlePivotTurn(const SensorReadings& readings) {
    float error = _targetHeading - readings.headingDeg;

    // Check if target angle is reached within 3 degrees tolerance
    if (fabs(error) <= 3.0f || (millis() - _stateTimer > 2500)) {
        // Turn completed or timeout safeguard reached
        _motors.brake();
        _targetHeading = readings.headingDeg;
        _headingIntegral = 0.0f;
        _state = NAV_FORWARD;
        Serial.printf("[NAV] Turn complete. Resuming FORWARD at heading %.1f deg\n", _targetHeading);
        return;
    }

    // Rotate in place (differential opposite wheel directions)
    if (error > 0) {
        // Clockwise turn (Left motor forward, Right motor reverse)
        _motors.setMotors((int16_t)Config::ROTATION_SPEED_PWM, -(int16_t)Config::ROTATION_SPEED_PWM);
    } else {
        // Counter-clockwise turn (Left motor reverse, Right motor forward)
        _motors.setMotors(-(int16_t)Config::ROTATION_SPEED_PWM, (int16_t)Config::ROTATION_SPEED_PWM);
    }
}
