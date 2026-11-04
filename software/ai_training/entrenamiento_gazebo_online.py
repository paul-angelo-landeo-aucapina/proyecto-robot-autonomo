#!/usr/bin/env python3
"""
=========================================================================================
ENTRENAMIENTO Y OPTIMIZACION ONLINE EN GAZEBO (PISO PLANO + SUBIDA/BAJADA DE RAMPA)
Proyecto: Robot Movil Autonomo con Estabilizacion Inercial y Evasion Reactiva

Este script interactua directamente con la instancia en ejecucion de Gazebo mediante
topicos ROS 2 y servicios del simulador. Entrena y ajusta:
  1. Ganancias del controlador Heading Hold (Kp, Ki) con retroalimentacion de MPU6050.
  2. Deteccion milimetrica de obstaculos con 2x VL53L0X (< 180 mm y < 80 mm).
  3. Desempeño en pendientes (traccion y control de deslizamiento en subida y bajada).
  4. Tiempo y precision de navegacion de Punto A (0,0) a Punto B (8.2, 0).
=========================================================================================
"""

import sys
import os
import time
import math
import json
import random
import numpy as np

try:
    import rclpy
    from rclpy.node import Node
    from geometry_msgs.msg import Twist
    from sensor_msgs.msg import Imu, Range
    from nav_msgs.msg import Odometry
    from gazebo_msgs.srv import SetModelState
    from gazebo_msgs.msg import ModelState
    ROS2_AVAILABLE = True
except ImportError:
    ROS2_AVAILABLE = False

class GazeboOnlineTrainer(Node):
    def __init__(self, max_episodes=50):
        super().__init__('entrenador_online_gazebo')
        self.max_episodes = max_episodes
        self.current_episode = 0

        # Parametros de prueba
        self.target_x = 8.2
        self.target_y = 0.0
        self.goal_radius = 0.20

        # Estado del robot
        self.x = 0.0
        self.y = 0.0
        self.yaw = 0.0
        self.pitch = 0.0
        self.omega_z = 0.0
        self.dist_left = 2.0
        self.dist_right = 2.0

        # Publicadores y suscripciones
        self.pub_cmd_vel = self.create_publisher(Twist, '/cmd_vel', 10)
        self.sub_imu = self.create_subscription(Imu, '/imu/data', self.cb_imu, 10)
        self.sub_tof_l = self.create_subscription(Range, '/distance/left', self.cb_tof_l, 10)
        self.sub_tof_r = self.create_subscription(Range, '/distance/right', self.cb_tof_r, 10)
        self.sub_odom = self.create_subscription(Odometry, '/odom', self.cb_odom, 10)

        # Cliente para resetear robot
        self.cli_reset = self.create_client(SetModelState, '/gazebo/set_model_state')

        # Hiperparametros a optimizar (poblacion de candidatos)
        self.best_score = -float('inf')
        self.best_params = {}

        self.get_logger().info("Entrenador Online Gazebo inicializado. Esperando sensores...")

    def cb_imu(self, msg: Imu):
        self.omega_z = msg.angular_velocity.z
        q = msg.orientation
        siny_cosp = 2.0 * (q.w * q.z + q.x * q.y)
        cosy_cosp = 1.0 - 2.0 * (q.y * q.y + q.z * q.z)
        self.yaw = math.atan2(siny_cosp, cosy_cosp)
        sinp = 2.0 * (q.w * q.y - q.z * q.x)
        self.pitch = math.asin(sinp) if abs(sinp) < 1.0 else math.copysign(math.pi / 2, sinp)

    def cb_tof_l(self, msg: Range):
        self.dist_left = msg.range

    def cb_tof_r(self, msg: Range):
        self.dist_right = msg.range

    def cb_odom(self, msg: Odometry):
        self.x = msg.pose.pose.position.x
        self.y = msg.pose.pose.position.y

    def reset_simulation(self):
        """Teletransporta el robot al Punto A (0,0) en Gazebo."""
        if self.cli_reset.wait_for_service(timeout_sec=2.0):
            req = SetModelState.Request()
            req.model_state.model_name = 'robot_diferencial_esp32'
            req.model_state.pose.position.x = 0.0
            req.model_state.pose.position.y = 0.0
            req.model_state.pose.position.z = 0.05
            req.model_state.pose.orientation.w = 1.0
            future = self.cli_reset.call_async(req)
            rclpy.spin_until_future_complete(self, future, timeout_sec=2.0)
            time.sleep(0.5)

    def run_episode(self, kp, ki, v_ramp):
        """Ejecuta una corrida completa de entrenamiento con un juego de parametros."""
        self.reset_simulation()
        
        start_t = time.time()
        timeout = 45.0 # Segundos maximos por episodio
        accumulated_yaw_err = 0.0
        critical_stops = 0
        integral_err = 0.0
        steps = 0
        success = False

        twist = Twist()

        while (time.time() - start_t) < timeout:
            rclpy.spin_once(self, timeout_sec=0.02)
            steps += 1

            dist_to_goal = math.hypot(self.target_x - self.x, self.target_y - self.y)
            min_tof = min(self.dist_left, self.dist_right)

            # Meta alcanzada
            if dist_to_goal < self.goal_radius:
                success = True
                break

            # 1. Parada de emergencia (< 80 mm)
            if min_tof < 0.080:
                critical_stops += 1
                twist.linear.x = 0.0
                twist.angular.z = 0.0
                self.pub_cmd_vel.publish(twist)
                time.sleep(0.05)
                # Retroceso 250 ms
                twist.linear.x = -0.16
                self.pub_cmd_vel.publish(twist)
                time.sleep(0.25)
                # Giro escape
                twist.linear.x = 0.0
                twist.angular.z = 1.4 if self.dist_left > self.dist_right else -1.4
                self.pub_cmd_vel.publish(twist)
                time.sleep(1.0)
                continue

            # 2. Frenado reactivo (< 180 mm)
            elif min_tof < 0.180:
                twist.linear.x = 0.0
                twist.angular.z = 1.2 if self.dist_left > self.dist_right else -1.2
                self.pub_cmd_vel.publish(twist)
                time.sleep(0.6) # Giro pivote
                continue

            # 3. Heading Hold hacia el objetivo
            target_heading = math.atan2(self.target_y - self.y, self.target_x - self.x)
            heading_err = math.atan2(math.sin(target_heading - self.yaw), math.cos(target_heading - self.yaw))
            accumulated_yaw_err += abs(heading_err)

            integral_err = max(-1.0, min(1.0, integral_err + heading_err * 0.02))
            w_cmd = (kp * heading_err) + (ki * integral_err)
            w_cmd = max(-1.5, min(1.5, w_cmd))

            # Ajuste de velocidad lineal segun terreno (inclinacion pitch de MPU6050)
            if self.pitch > 0.08: # Subiendo rampa
                v_cmd = v_ramp
            elif self.pitch < -0.08: # Bajando rampa
                v_cmd = 0.15
            else: # Piso plano
                v_cmd = 0.28

            twist.linear.x = v_cmd
            twist.angular.z = w_cmd
            self.pub_cmd_vel.publish(twist)

        # Detener motores al final del episodio
        twist.linear.x = 0.0
        twist.angular.z = 0.0
        self.pub_cmd_vel.publish(twist)

        elapsed = time.time() - start_t
        # Calculo de Recompensa / Funcion de Aptitud
        score = 0.0
        if success:
            score += 200.0 - (elapsed * 2.0)
        else:
            score -= (dist_to_goal * 25.0)

        score -= (accumulated_yaw_err / max(steps, 1)) * 50.0
        score -= (critical_stops * 35.0)

        return score, success, elapsed, critical_stops

def main():
    if not ROS2_AVAILABLE:
        print("[ERROR] ROS 2 no esta detectado en el entorno de ejecucion actual.")
        print("Asegurate de ejecutar este script dentro de tu terminal con ROS 2 cargado.")
        sys.exit(1)

    rclpy.init()
    trainer = GazeboOnlineTrainer(max_episodes=20)

    print("\n" + "="*70)
    print(" INICIO DE ENTRENAMIENTO EN GAZEBO: PISO PLANO + RAMPA SUBIDA/BAJADA")
    print("="*70)

    # Espacio de busqueda de hiperparametros
    kp_candidates = [1.8, 2.2, 2.6, 3.0]
    ki_candidates = [0.15, 0.30, 0.45]
    v_ramp_candidates = [0.32, 0.38, 0.44]

    best_score = -9999.0
    best_config = {}

    for ep in range(1, trainer.max_episodes + 1):
        kp = random.choice(kp_candidates)
        ki = random.choice(ki_candidates)
        v_ramp = random.choice(v_ramp_candidates)

        print(f"\n[Episodio {ep}/{trainer.max_episodes}] Probando: Kp={kp:.2f}, Ki={ki:.2f}, V_Rampa={v_ramp:.2f} m/s")
        score, success, duration, stops = trainer.run_episode(kp, ki, v_ramp)

        print(f"  --> Resultado: {'¡EXITO!' if success else 'FALLIDO'} | Score: {score:.1f} | Tiempo: {duration:.1f}s | Paradas Criticas: {stops}")

        if score > best_score:
            best_score = score
            best_config = {"Kp": kp, "Ki": ki, "v_ramp_up": v_ramp, "score": score}
            print(f"  --> [NUEVO RECORD] ¡Mejor configuracion guardada!")

    print("\n" + "="*70)
    print(" ENTRENAMIENTO FINALIZADO CON EXITO EN GAZEBO")
    print(f" Mejor Score Obtenido: {best_score:.2f}")
    print(f" Parametros Optimizados: {best_config}")
    print("="*70)

    with open("pesos_optimos_entrenamiento.json", "w") as f:
        json.dump(best_config, f, indent=4)
    print("Guardado en: pesos_optimos_entrenamiento.json")

    trainer.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
