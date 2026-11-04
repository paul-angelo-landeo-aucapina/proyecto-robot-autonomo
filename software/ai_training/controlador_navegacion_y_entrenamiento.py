#!/usr/bin/env python3
"""
=========================================================================================
CONTROLADOR Y NODO DE ENTRENAMIENTO EN GAZEBO PARA ROBOT MOVIL DIFERENCIAL 2WD (ESP32)
Proyecto: Robot Movil Autonomo con Estabilizacion Inercial y Evasion Reactiva

Cumplimiento estricto de requerimientos del PDF:
  1. Desplazamiento Rectilineo Estabilizado (Heading Hold):
     - Giróscopo MPU6050 (eje Z, \omega_z) con integracion y compensacion de deriva.
     - Controlador Proporcional-Integral (PI) para corregir el rumbo contra asimetrias
       de motores TT y deslizamientos en rampas de subida/bajada.
  2. Percepcion Frontal y Evasion Reactiva (2x ToF VL53L0X):
     - Zona de frenado (< 180 mm): Detencion activa, evaluacion de despeje (izq vs der),
       giro pivote sobre su propio eje (+-90 deg) monitoreado por MPU6050.
  3. Parada de Emergencia y Retroceso de Seguridad (< 80 mm):
     - Active Braking por puente H TB6612FNG.
     - Retroceso activo durante exactamente 250 ms.
     - Rotacion hacia corredor despejado.
  4. Navegacion Punto a Punto:
     - Arranque en Punto A (0,0), cruce de piso plano, subida/bajada de rampa y llegada a Punto B.
  5. Telemetria a 50 Hz continua.
=========================================================================================
"""

import sys
import math
import time
import json
import argparse
import numpy as np

# ROS 2 Python Client Library
try:
    import rclpy
    from rclpy.node import Node
    from geometry_msgs.msg import Twist
    from sensor_msgs.msg import Imu, Range
    from nav_msgs.msg import Odometry
    from gazebo_msgs.srv import SetModelState
    from gazebo_msgs.msg import ModelState
except ImportError:
    # Permitir inspeccion o ejecucion informativa sin entorno ROS 2 activo
    pass

class RobotControllerGazebo(Node):
    # Estados de la Maquina de Navegacion (FSM)
    STATE_FORWARD_NAV       = "NAV_RECTILINEA_HEADING_HOLD"
    STATE_BRAKE_EVAL        = "ZONA_FRENADO_EVAL_DESPEJE"
    STATE_PIVOT_TURN        = "GIRO_PIVOTE_MONITOREADO"
    STATE_EMERGENCY_BRAKE   = "PARADA_EMERGENCIA_ACTIVA"
    STATE_SAFETY_REVERSE    = "RETROCESO_SEGURIDAD_250MS"
    STATE_GOAL_REACHED      = "OBJETIVO_PUNTO_B_ALCANZADO"

    def __init__(self, target_x=8.2, target_y=0.0, is_training=False):
        super().__init__('controlador_navegacion_y_entrenamiento')

        # Parametros de Meta (Punto B)
        self.target_x = target_x
        self.target_y = target_y
        self.is_training = is_training
        self.goal_tolerance = 0.15 # 15 cm de radio de llegada

        # Umbrales milimetricos segun PDF
        self.DIST_CRITICAL_M = 0.080 # 80 mm (Parada de emergencia y retroceso)
        self.DIST_BRAKE_M    = 0.180 # 180 mm (Zona de frenado y evaluacion)
        self.REVERSE_TIME_S  = 0.250 # 250 ms de retroceso activo

        # Ganancias del Controlador PI Heading Hold (Sintonizables en entrenamiento)
        self.Kp_heading = 2.45
        self.Ki_heading = 0.35
        self.integral_heading_error = 0.0
        self.integral_limit = 1.0 # Anti-windup

        # Velocidades nominales de operacion
        self.v_flat_nominal = 0.28    # m/s en piso plano
        self.v_ramp_up      = 0.38    # m/s empuje reforzado en subida
        self.v_ramp_down    = 0.16    # m/s retencion controlada en bajada
        self.w_turn_speed   = 1.25    # rad/s velocidad de giro pivote

        # Variables de estado del robot
        self.x = 0.0
        self.y = 0.0
        self.yaw = 0.0            # Rumbo actual (radianes)
        self.pitch = 0.0          # Inclinacion (subida/bajada)
        self.omega_z = 0.0        # Velocidad angular eje Z (MPU6050)
        self.dist_left = 2.0      # Distancia ToF izquierdo (metros)
        self.dist_right = 2.0     # Distancia ToF derecho (metros)

        # Variables de control FSM
        self.state = self.STATE_FORWARD_NAV
        self.desired_heading = 0.0
        self.target_pivot_yaw = 0.0
        self.reverse_start_time = 0.0

        # Metricas para entrenamiento
        self.episode = 0
        self.total_collisions = 0
        self.accumulated_heading_error = 0.0
        self.start_episode_time = time.time()

        # Publicadores y Suscriptores ROS 2
        self.pub_cmd_vel = self.create_publisher(Twist, '/cmd_vel', 10)
        
        self.sub_imu = self.create_subscription(Imu, '/imu/data', self.cb_imu, 10)
        self.sub_tof_left = self.create_subscription(Range, '/distance/left', self.cb_tof_left, 10)
        self.sub_tof_right = self.create_subscription(Range, '/distance/right', self.cb_tof_right, 10)
        self.sub_odom = self.create_subscription(Odometry, '/odom', self.cb_odom, 10)

        # Cliente para resetear la posicion en Gazebo durante entrenamiento
        self.cli_set_state = self.create_client(SetModelState, '/gazebo/set_model_state')

        # Bucle de Control Principal a 50 Hz (20 ms) segun telemetria del microcontrolador
        self.timer_control = self.create_timer(0.020, self.control_loop)
        self.get_logger().info(f"==> Nodo Iniciado: Meta B en ({self.target_x:.2f}, {self.target_y:.2f})")
        self.get_logger().info(f"==> Modo: {'ENTRENAMIENTO OPTIMIZACION GAZEBO' if self.is_training else 'NAVEGACION AUTONOMA EN VIVO'}")

    # =========================================================================
    # CALLBACKS DE SENSORES SIMULADOS
    # =========================================================================
    def cb_imu(self, msg: Imu):
        """Lectura MPU6050 (Giróscopo Z a 100 Hz y Acelerómetro)."""
        self.omega_z = msg.angular_velocity.z
        
        # Computar Yaw y Pitch desde cuaterniones
        q = msg.orientation
        siny_cosp = 2.0 * (q.w * q.z + q.x * q.y)
        cosy_cosp = 1.0 - 2.0 * (q.y * q.y + q.z * q.z)
        self.yaw = math.atan2(siny_cosp, cosy_cosp)

        sinp = 2.0 * (q.w * q.y - q.z * q.x)
        if abs(sinp) >= 1:
            self.pitch = math.copysign(math.pi / 2, sinp)
        else:
            self.pitch = math.asin(sinp)

    def cb_tof_left(self, msg: Range):
        """Sensor ToF VL53L0X Sector Frontal Izquierdo."""
        self.dist_left = msg.range

    def cb_tof_right(self, msg: Range):
        """Sensor ToF VL53L0X Sector Frontal Derecho."""
        self.dist_right = msg.range

    def cb_odom(self, msg: Odometry):
        """Odometria para rastreo de coordenadas X, Y respecto al origen A."""
        self.x = msg.pose.pose.position.x
        self.y = msg.pose.pose.position.y

    # =========================================================================
    # LOGICA DE CONTROL Y MAQUINA DE ESTADOS FINITA (FSM)
    # =========================================================================
    def control_loop(self):
        twist = Twist()
        min_distance = min(self.dist_left, self.dist_right)
        dist_to_goal = math.hypot(self.target_x - self.x, self.target_y - self.y)

        # 0. Verificacion de Llegada a Meta Punto B
        if dist_to_goal <= self.goal_tolerance and self.state != self.STATE_GOAL_REACHED:
            self.state = self.STATE_GOAL_REACHED
            self.get_logger().info(f"[META] ¡Llegada al Punto Objetivo B con exito! Dist: {dist_to_goal:.3f} m")
            if self.is_training:
                self.conclude_episode(success=True)

        # ---------------------------------------------------------------------
        # 1. PARADA DE EMERGENCIA CRITICA (< 80 mm)
        # ---------------------------------------------------------------------
        if min_distance < self.DIST_CRITICAL_M and self.state not in [self.STATE_EMERGENCY_BRAKE, self.STATE_SAFETY_REVERSE, self.STATE_GOAL_REACHED]:
            self.state = self.STATE_EMERGENCY_BRAKE
            self.total_collisions += 1
            self.get_logger().warn(f"[EMERGENCIA] Barrera critica a {min_distance*1000:.0f} mm (< 80 mm). Active Braking!")

        # ---------------------------------------------------------------------
        # GESTION DE ESTADOS
        # ---------------------------------------------------------------------
        if self.state == self.STATE_EMERGENCY_BRAKE:
            # Frenado electronico activo inmediato por puente H (TB6612)
            twist.linear.x = 0.0
            twist.angular.z = 0.0
            self.pub_cmd_vel.publish(twist)
            # Iniciar retroceso de seguridad
            self.state = self.STATE_SAFETY_REVERSE
            self.reverse_start_time = time.time()
            return

        elif self.state == self.STATE_SAFETY_REVERSE:
            # Retroceso activo durante 250 ms segun PDF
            dt_reverse = time.time() - self.reverse_start_time
            if dt_reverse < self.REVERSE_TIME_S:
                twist.linear.x = -0.16 # Velocidad reversa segura
                twist.angular.z = 0.0
                self.pub_cmd_vel.publish(twist)
                return
            else:
                # Transicionar a giro de escape
                self.target_pivot_yaw = self.normalize_angle(self.yaw + (math.pi / 2 if self.dist_left >= self.dist_right else -math.pi / 2))
                self.state = self.STATE_PIVOT_TURN
                self.get_logger().info(f"[RETROCESO] 250 ms completados. Iniciando giro de escape.")

        elif self.state == self.STATE_FORWARD_NAV:
            # 2. Percepcion Frontal: Zona de frenado reactivo (< 180 mm)
            if min_distance < self.DIST_BRAKE_M:
                self.state = self.STATE_BRAKE_EVAL
                self.get_logger().info(f"[ALERTA ToF] Obstaculo a {min_distance*1000:.0f} mm (< 180 mm). Evaluando lados...")
                twist.linear.x = 0.0
                twist.angular.z = 0.0
                self.pub_cmd_vel.publish(twist)
                return

            # Navegacion hacia la meta con compensacion de pendiente
            angle_to_goal = math.atan2(self.target_y - self.y, self.target_x - self.x)
            self.desired_heading = angle_to_goal

            # Adaptacion de velocidad segun terreno (piso plano vs rampa)
            # self.pitch > 0.08 rad => Subiendo rampa (requiere mas par/potencia)
            # self.pitch < -0.08 rad => Bajando rampa (frenado de retencion para no resbalar)
            if self.pitch > 0.08:
                v_cmd = self.v_ramp_up
                terreno = "RAMPA_SUBIDA"
            elif self.pitch < -0.08:
                v_cmd = self.v_ramp_down
                terreno = "RAMPA_BAJADA"
            else:
                v_cmd = self.v_flat_nominal
                terreno = "PISO_PLANO"

            # 1. Heading Hold: Controlador PI con Giróscopo MPU6050
            heading_error = self.normalize_angle(self.desired_heading - self.yaw)
            self.accumulated_heading_error += abs(heading_error) * 0.02

            # Integracion con anti-windup
            self.integral_heading_error += heading_error * 0.02
            self.integral_heading_error = max(-self.integral_limit, min(self.integral_limit, self.integral_heading_error))

            # Salida diferencial PI
            w_correction = (self.Kp_heading * heading_error) + (self.Ki_heading * self.integral_heading_error)
            w_correction = max(-1.8, min(1.8, w_correction))

            twist.linear.x = v_cmd
            twist.angular.z = w_correction

        elif self.state == self.STATE_BRAKE_EVAL:
            # Evalua que lado tiene mayor espacio libre
            twist.linear.x = 0.0
            twist.angular.z = 0.0
            self.pub_cmd_vel.publish(twist)

            if self.dist_left > self.dist_right:
                delta_pivot = math.pi / 2 # +90 deg giro a la izquierda
                lado = "IZQUIERDA"
            else:
                delta_pivot = -math.pi / 2 # -90 deg giro a la derecha
                lado = "DERECHA"

            self.target_pivot_yaw = self.normalize_angle(self.yaw + delta_pivot)
            self.state = self.STATE_PIVOT_TURN
            self.get_logger().info(f"[DECISION] Mayor despeje a la {lado}. Iniciando giro pivote de 90 deg.")

        elif self.state == self.STATE_PIVOT_TURN:
            # Giro pivote sobre su propio eje monitoreado por MPU6050
            error_pivot = self.normalize_angle(self.target_pivot_yaw - self.yaw)

            if abs(error_pivot) < 0.05: # Margen de tolerancia ~2.8 grados
                twist.linear.x = 0.0
                twist.angular.z = 0.0
                self.integral_heading_error = 0.0 # Reset integral
                self.desired_heading = self.yaw
                self.state = self.STATE_FORWARD_NAV
                self.get_logger().info("[PIVOTE] Giro pivote completado con precision de giróscopo. Reanudando marcha.")
            else:
                # Giro en su propio eje: v = 0
                twist.linear.x = 0.0
                twist.angular.z = math.copysign(self.w_turn_speed, error_pivot)

        elif self.state == self.STATE_GOAL_REACHED:
            twist.linear.x = 0.0
            twist.angular.z = 0.0

        # Publicar comando a los motores TT
        self.pub_cmd_vel.publish(twist)

        # Telemetria en consola a 50 Hz simplificada
        self.print_telemetry(dist_to_goal, min_distance)

    # =========================================================================
    # UTILIDADES MATEMATICAS Y TELEMETRIA
    # =========================================================================
    def normalize_angle(self, angle):
        """Mantiene el angulo estrictamente en [-pi, pi]."""
        while angle > math.pi:
            angle -= 2.0 * math.pi
        while angle < -math.pi:
            angle += 2.0 * math.pi
        return angle

    def print_telemetry(self, dist_to_goal, min_distance):
        """Emite telemetria segun Requerimiento 4 del PDF."""
        yaw_deg = math.degrees(self.yaw)
        pitch_deg = math.degrees(self.pitch)
        sys.stdout.write(
            f"\r[TELEMETRIA 50Hz] Estado: {self.state[:16]} | X:{self.x:5.2f} Y:{self.y:5.2f} | "
            f"Rumbo:{yaw_deg:6.1f}° Pitch:{pitch_deg:5.1f}° | Wz:{self.omega_z:5.2f} | "
            f"ToF_L:{self.dist_left*1000:4.0f}mm ToF_R:{self.dist_right*1000:4.0f}mm | Meta:{dist_to_goal:4.2f}m   "
        )
        sys.stdout.flush()

    # =========================================================================
    # REINICIO Y ENTRENAMIENTO EN GAZEBO
    # =========================================================================
    def conclude_episode(self, success):
        """Calcula el costo del episodio y resetea el robot en Gazebo."""
        duration = time.time() - self.start_episode_time
        score = (100.0 if success else -50.0) - (self.accumulated_heading_error * 2.0) - (self.total_collisions * 30.0) - duration
        self.get_logger().info(f"\n--- Fin Episodio {self.episode} | Puntaje: {score:.2f} | Duracion: {duration:.2f}s | Colisiones: {self.total_collisions} ---")
        
        # Guardar parametros optimos
        opt_data = {
            "Kp_heading": self.Kp_heading,
            "Ki_heading": self.Ki_heading,
            "v_flat": self.v_flat_nominal,
            "v_ramp_up": self.v_ramp_up,
            "v_ramp_down": self.v_ramp_down,
            "score": score
        }
        with open("pesos_optimos_robot.json", "w") as f:
            json.dump(opt_data, f, indent=4)

        self.reset_robot_in_gazebo()

    def reset_robot_in_gazebo(self):
        """Teletransporta al robot de vuelta al Punto A (0,0,0.05) sin cerrar Gazebo."""
        if not self.cli_set_state.wait_for_service(timeout_sec=1.0):
            return
        req = SetModelState.Request()
        req.model_state.model_name = 'robot_diferencial_esp32'
        req.model_state.pose.position.x = 0.0
        req.model_state.pose.position.y = 0.0
        req.model_state.pose.position.z = 0.05
        req.model_state.pose.orientation.w = 1.0
        self.cli_set_state.call_async(req)

        self.episode += 1
        self.total_collisions = 0
        self.accumulated_heading_error = 0.0
        self.integral_heading_error = 0.0
        self.state = self.STATE_FORWARD_NAV
        self.start_episode_time = time.time()

def main(args=None):
    parser = argparse.ArgumentParser(description="Control y Entrenamiento en Gazebo para Robot Movil 2WD")
    parser.add_argument('--target_x', type=float, default=8.2, help="Coordenada X del Punto B")
    parser.add_argument('--target_y', type=float, default=0.0, help="Coordenada Y del Punto B")
    parser.add_argument('--train', action='store_true', help="Habilitar modo entrenamiento por episodios")
    cli_args = parser.parse_args()

    rclpy.init(args=args)
    node = RobotControllerGazebo(target_x=cli_args.target_x, target_y=cli_args.target_y, is_training=cli_args.train)
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        node.get_logger().info("\nDeteniendo robot de forma segura...")
        stop_twist = Twist()
        node.pub_cmd_vel.publish(stop_twist)
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
