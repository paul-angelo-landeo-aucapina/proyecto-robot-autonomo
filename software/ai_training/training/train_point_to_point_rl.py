"""
=========================================================================================
ENTRENAMIENTO POR APRENDIZAJE POR REFUERZO (REINFORCEMENT LEARNING - DQN / PYTORCH)
Proyecto: Robot Movil Autonomo con Estabilizacion Inercial y Evasion Reactiva

Especificaciones del PDF implementadas en la Recompensa:
  1. Desplazamiento Rectilineo hacia el objetivo (Punto A -> Punto B en piso plano).
  2. Heading Hold: Penalizacion de deriva angular innecesaria en el eje Z.
  3. Zona de frenado reactivo: Penalizacion si ingresa a < 180 mm de un obstaculo.
  4. Frenado de emergencia y retroceso: Castigo critico (-100) si ingresa a < 80 mm.
  5. Recompensa terminal (+200) al alcanzar el objetivo con tolerancia < 60 mm.
=========================================================================================
"""

import math
import random
import time
from collections import deque
import numpy as np

import torch
import torch.nn as nn
import torch.optim as optim

# =========================================================================================
# 1. ARQUITECTURA DE LA RED NEURONAL (DEEP Q-NETWORK)
# =========================================================================================
class RobotDQN(nn.Module):
    def __init__(self, state_dim=5, action_dim=5):
        super(RobotDQN, self).__init__()
        self.net = nn.Sequential(
            nn.Linear(state_dim, 64),
            nn.ReLU(),
            nn.Linear(64, 64),
            nn.ReLU(),
            nn.Linear(64, action_dim)
        )

    def forward(self, x):
        return self.net(x)

# =========================================================================================
# 2. ENTORNO DE SIMULACION EN PISO PLANO (GYM-LIKE ENVIRONMENT)
# =========================================================================================
class RobotPointToPointEnv:
    def __init__(self):
        # Limites del piso plano (metros)
        self.arena_size = 4.0
        self.goal_x = 1.50
        self.goal_y = 0.80
        
        # Umbrales segun PDF
        self.DIST_CRITICAL_M = 0.080 # 80 mm
        self.DIST_BRAKE_M    = 0.180 # 180 mm
        self.GOAL_TOL_M      = 0.060 # 60 mm
        
        # Acciones discretas para motores TT con TB6612FNG:
        # 0: AVANZAR_RECTO (Heading Hold)
        # 1: GIRO_PIVOTE_IZQ (+90 deg/s)
        # 2: GIRO_PIVOTE_DER (-90 deg/s)
        # 3: FRENADO_ACTIVO (Active Brake)
        # 4: RETROCESO_SEGURIDAD (250 ms)
        self.action_space_n = 5
        self.reset()

    def reset(self):
        self.x = 0.0
        self.y = 0.0
        self.yaw = 0.0 # Radianes
        self.omega_z = 0.0
        
        # Obstaculos estaticos en el piso plano: [(x, y, radio)]
        self.obstacles = [
            (0.8, 0.2, 0.15),
            (1.0, 0.7, 0.12),
            (0.5, 0.6, 0.10)
        ]
        
        self.steps = 0
        self.prev_dist_to_goal = math.hypot(self.goal_x - self.x, self.goal_y - self.y)
        return self._get_observation()

    def _get_distance_to_obstacles(self, ray_angle_offset):
        """Simula lectura ToF VL53L0X en cono frontal a 940 nm."""
        ray_angle = self.yaw + ray_angle_offset
        min_dist = 2.0 # Maximo 2.0 metros de alcance VL53L0X
        
        # Ray-casting simple contra obstaculos circulares y paredes
        for ox, oy, r in self.obstacles:
            dx = ox - self.x
            dy = oy - self.y
            dist_center = math.hypot(dx, dy)
            angle_to_obs = math.atan2(dy, dx)
            diff_ang = abs(math.atan2(math.sin(angle_to_obs - ray_angle), math.cos(angle_to_obs - ray_angle)))
            
            if diff_ang < 0.25: # Dentro del cono del sensor
                d = dist_center - r
                if 0.0 < d < min_dist:
                    min_dist = d
        return min_dist

    def _get_observation(self):
        dx = self.goal_x - self.x
        dy = self.goal_y - self.y
        dist_to_goal = math.hypot(dx, dy)
        target_heading = math.atan2(dy, dx)
        heading_error = math.atan2(math.sin(target_heading - self.yaw), math.cos(target_heading - self.yaw))
        
        # Sensores ToF (Izquierdo +10 deg, Derecho -10 deg)
        dist_left = self._get_distance_to_obstacles(math.radians(10.0))
        dist_right = self._get_distance_to_obstacles(math.radians(-10.0))
        
        # Vector de estado normalizado de 5 dimensiones
        obs = np.array([
            min(dist_to_goal / 4.0, 1.0),
            heading_error / math.pi,
            min(dist_left / 2.0, 1.0),
            min(dist_right / 2.0, 1.0),
            self.omega_z / 3.0
        ], dtype=np.float32)
        return obs

    def step(self, action):
        self.steps += 1
        dt = 0.05 # 50 ms por paso (20 Hz)
        
        v = 0.0
        w = 0.0
        
        if action == 0:   # Avanzar recto
            v = 0.22      # 220 mm/s
            w = 0.0
        elif action == 1: # Pivote izquierda
            v = 0.0
            w = 1.6       # ~90 deg/s
        elif action == 2: # Pivote derecha
            v = 0.0
            w = -1.6
        elif action == 3: # Active brake
            v = 0.0
            w = 0.0
        elif action == 4: # Retroceso 250 ms
            v = -0.15
            w = 0.0

        # Actualizar cinemagica en piso plano
        self.omega_z = w
        self.yaw += w * dt
        self.yaw = math.atan2(math.sin(self.yaw), math.cos(self.yaw))
        self.x += v * math.cos(self.yaw) * dt
        self.y += v * math.sin(self.yaw) * dt

        # Evaluacion de sensores
        dist_l = self._get_distance_to_obstacles(math.radians(10.0))
        dist_r = self._get_distance_to_obstacles(math.radians(-10.0))
        min_tof = min(dist_l, dist_r)
        
        cur_dist_to_goal = math.hypot(self.goal_x - self.x, self.goal_y - self.y)
        
        # =================================================================================
        # FUNCION DE RECOMPENSA BASADA EN EL PDF
        # =================================================================================
        # 1. Progreso hacia el objetivo
        reward = (self.prev_dist_to_goal - cur_dist_to_goal) * 20.0
        self.prev_dist_to_goal = cur_dist_to_goal
        
        # 2. Recompensa por mantener el rumbo recto (Heading Hold)
        target_heading = math.atan2(self.goal_y - self.y, self.goal_x - self.x)
        heading_err = abs(math.atan2(math.sin(target_heading - self.yaw), math.cos(target_heading - self.yaw)))
        reward += 0.2 * math.cos(heading_err)
        
        done = False
        
        # 3. Penalizacion zona de frenado reactivo (< 180 mm)
        if min_tof < self.DIST_BRAKE_M:
            reward -= 2.0
            
        # 4. Parada de emergencia y choque critico (< 80 mm)
        if min_tof < self.DIST_CRITICAL_M:
            reward -= 100.0 # Castigo critico
            done = True
            
        # 5. Llegada al objetivo (Tolerancia < 60 mm)
        if cur_dist_to_goal <= self.GOAL_TOL_M:
            reward += 200.0 # Maxima recompensa
            done = True

        if self.steps >= 400: # Limite de tiempo
            done = True
            
        return self._get_observation(), reward, done, {}

# =========================================================================================
# 3. ALGORITMO DE ENTRENAMIENTO DQN
# =========================================================================================
def train_robot_dqn(episodes=600):
    print("=================================================================")
    print("INICIANDO ENTRENAMIENTO DQN DEL ROBOT (PUNTO A PUNTO + EVASION)")
    print("=================================================================")
    
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"[TRAINING] Dispositivo de computo: {device}")
    
    env = RobotPointToPointEnv()
    policy_net = RobotDQN().to(device)
    target_net = RobotDQN().to(device)
    target_net.load_state_dict(policy_net.state_dict())
    target_net.eval()
    
    optimizer = optim.Adam(policy_net.parameters(), lr=0.001)
    memory = deque(maxlen=20000)
    
    batch_size = 64
    gamma = 0.98
    epsilon = 1.0
    epsilon_min = 0.05
    epsilon_decay = 0.995
    
    success_count = 0
    
    for ep in range(1, episodes + 1):
        state = env.reset()
        total_reward = 0.0
        
        while True:
            # Seleccion de accion epsilon-greedy
            if random.random() < epsilon:
                action = random.randint(0, env.action_space_n - 1)
            else:
                with torch.no_grad():
                    st_tensor = torch.FloatTensor(state).unsqueeze(0).to(device)
                    q_vals = policy_net(st_tensor)
                    action = q_vals.argmax().item()
                    
            next_state, reward, done, _ = env.step(action)
            total_reward += reward
            memory.append((state, action, reward, next_state, done))
            state = next_state
            
            # Actualizacion de la red neuronal
            if len(memory) >= batch_size:
                batch = random.sample(memory, batch_size)
                b_s, b_a, b_r, b_ns, b_d = zip(*batch)
                
                b_s = torch.FloatTensor(np.array(b_s)).to(device)
                b_a = torch.LongTensor(b_a).unsqueeze(1).to(device)
                b_r = torch.FloatTensor(b_r).unsqueeze(1).to(device)
                b_ns = torch.FloatTensor(np.array(b_ns)).to(device)
                b_d = torch.FloatTensor(b_d).unsqueeze(1).to(device)
                
                cur_q = policy_net(b_s).gather(1, b_a)
                with torch.no_grad():
                    max_next_q = target_net(b_ns).max(1)[0].unsqueeze(1)
                    target_q = b_r + (1.0 - b_d) * gamma * max_next_q
                    
                loss = nn.MSELoss()(cur_q, target_q)
                optimizer.zero_grad()
                loss.backward()
                optimizer.step()
                
            if done:
                break
                
        if epsilon > epsilon_min:
            epsilon *= epsilon_decay
            
        if ep % 10 == 0:
            target_net.load_state_dict(policy_net.state_dict())
            
        if reward >= 100.0:
            success_count += 1

        if ep % 20 == 0:
            print(f"Episodio {ep:3d}/{episodes} | Recompensa: {total_reward:7.1f} | Epsilon: {epsilon:.3f} | Exitos: {success_count}")
            
    # Guardar modelo entrenado
    model_path = "d:/PROYECTO DE ROBÓTICA/gazebo/policy_robot_p2p.pt"
    torch.save(policy_net.state_dict(), model_path)
    print(f"\n[OK] Modelo entrenado guardado con exito en: {model_path}")

if __name__ == '__main__':
    train_robot_dqn(episodes=300)
