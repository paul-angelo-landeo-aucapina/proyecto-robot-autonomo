"""
=========================================================================================
SCRIPT DE ENTRENAMIENTO Y CONTROL EN GAZEBO / ROS 2
Proyecto: Robot Movil Autonomo con Estabilizacion Inercial y Evasion Reactiva

Objetivo:
  Entrenar o ejecutar el bucle de navegacion y control en el simulador Gazebo.
  Monitorea:
    - /distance/left y /distance/right (sensores VL53L0X)
    - /imu/data (sensor MPU6050 a 100 Hz)
  Publica:
    - /cmd_vel (velocidad lineal y angular a las ruedas)
=========================================================================================
"""

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from sensor_msgs.msg import Range, Imu
import math
import time

class GazeboRobotTrainer(Node):
    def __init__(self):
        super().__init__('gazebo_robot_trainer')
        
        # Publicador de velocidad hacia el plugin diff_drive de Gazebo
        self.cmd_pub = self.create_publisher(Twist, '/cmd_vel', 10)
        
        # Suscriptores a los sensores simulados
        self.sub_dist_l = self.create_subscription(Range, '/distance/left', self.cb_dist_left, 10)
        self.sub_dist_r = self.create_subscription(Range, '/distance/right', self.cb_dist_right, 10)
        self.sub_imu = self.create_subscription(Imu, '/imu/data', self.cb_imu, 10)
        
        # Variables de estado
        self.dist_left_m = 2.0
        self.dist_right_m = 2.0
        self.yaw = 0.0
        self.omega_z = 0.0
        self.last_imu_time = time.time()
        
        # Parametros de navegacion segun especificaciones del PDF
        self.DIST_CRITICAL_M = 0.080 # 80 mm (Parada de emergencia)
        self.DIST_BRAKE_M = 0.180    # 180 mm (Zona de frenado reactivo)
        
        self.state = "FORWARD_HOLD"
        self.target_heading = 0.0
        self.target_turn_angle = 0.0
        self.state_start_time = time.time()
        
        # Bucle de control a 50 Hz
        self.timer = self.create_timer(0.02, self.control_loop)
        self.get_logger().info("=== Nodo de Entrenamiento y Control en Gazebo Iniciado ===")

    def cb_dist_left(self, msg):
        self.dist_left_m = msg.range

    def cb_dist_right(self, msg):
        self.dist_right_m = msg.range

    def cb_imu(self, msg):
        now = time.time()
        dt = now - self.last_imu_time
        self.last_imu_time = now
        
        self.omega_z = msg.angular_velocity.z
        self.yaw += self.omega_z * dt

    def publish_twist(self, linear_x, angular_z):
        tw = Twist()
        tw.linear.x = float(linear_x)
        tw.angular.z = float(angular_z)
        self.cmd_pub.publish(tw)

    def control_loop(self):
        now = time.time()
        
        # -------------------------------------------------------------
        # Logica FSM exacta del proyecto
        # -------------------------------------------------------------
        if self.state == "FORWARD_HOLD":
            # 1. Chequeo de seguridad critica (< 80 mm)
            if self.dist_left_m < self.DIST_CRITICAL_M or self.dist_right_m < self.DIST_CRITICAL_M:
                self.publish_twist(0.0, 0.0) # Active brake
                self.state = "SAFETY_REVERSE"
                self.state_start_time = now
                self.get_logger().warn("[EMERGENCIA] Barrera critica a < 80mm. Iniciando retroceso.")
                return

            # 2. Chequeo de zona de frenado reactivo (< 180 mm)
            if self.dist_left_m < self.DIST_BRAKE_M or self.dist_right_m < self.DIST_BRAKE_M:
                self.publish_twist(0.0, 0.0)
                self.state = "DECIDE_TURN"
                return

            # 3. Heading Hold (Avance rectilineo estabilizado con correccion de rumbo)
            err_heading = self.target_heading - self.yaw
            correction_w = 2.5 * err_heading # Ganancia proporcional
            
            # Velocidad de avance de 0.22 m/s
            self.publish_twist(0.22, correction_w)

        elif self.state == "SAFETY_REVERSE":
            # Retroceso exacto por 250 ms
            self.publish_twist(-0.15, 0.0)
            if now - self.state_start_time >= 0.250:
                self.publish_twist(0.0, 0.0)
                self.state = "DECIDE_TURN"

        elif self.state == "DECIDE_TURN":
            self.publish_twist(0.0, 0.0)
            turn_left = (self.dist_left_m > self.dist_right_m)
            delta_rad = math.radians(90.0) if turn_left else math.radians(-90.0)
            self.target_turn_angle = self.yaw + delta_rad
            self.state = "PIVOT_TURN"
            self.state_start_time = now
            self.get_logger().info(f"[EVASION] Girando hacia {'Izquierda' if turn_left else 'Derecha'}")

        elif self.state == "PIVOT_TURN":
            turn_err = self.target_turn_angle - self.yaw
            w_turn = 1.8 if turn_err > 0 else -1.8
            self.publish_twist(0.0, w_turn)

            if abs(turn_err) <= math.radians(3.0) or (now - self.state_start_time > 2.5):
                self.publish_twist(0.0, 0.0)
                self.target_heading = self.yaw
                self.state = "FORWARD_HOLD"
                self.get_logger().info("[NAVEGACION] Rumbo reanudado.")

def main(args=None):
    rclpy.init(args=args)
    node = GazeboRobotTrainer()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        node.publish_twist(0.0, 0.0)
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
