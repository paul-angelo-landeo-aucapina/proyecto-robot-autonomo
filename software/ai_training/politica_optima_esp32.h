// ==========================================================
// PARAMETROS DE CONTROL OPTIMIZADOS PARA ESP32 (ENTRENADOS)
// Proyecto Robotica: Heading Hold + Evasion Reactiva ToF
// ==========================================================

#ifndef POLITICA_OPTIMA_ESP32_H
#define POLITICA_OPTIMA_ESP32_H

#define KP_HEADING_HOLD        2.844f
#define KI_HEADING_HOLD        0.365f
#define DIST_FRENADO_MM        180
#define DIST_CRITICA_MM        80
#define TIEMPO_RETROCESO_MS    250
#define VELOCIDAD_AVANCE_PWM   180
#define VELOCIDAD_GIRO_PWM     160

#endif // POLITICA_OPTIMA_ESP32_H
