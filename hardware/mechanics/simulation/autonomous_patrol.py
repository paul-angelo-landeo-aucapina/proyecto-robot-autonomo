#!/usr/bin/env python3
"""
Autonomous Patrol & Obstacle Negotiation Routine for Robot Sumoso
Demonstrates Option D differential kinematics:
- Forward advance & obstacle push
- Smooth deceleration and reverse
- Zero-radius turn in place (spin about chassis centroid)
- Trajectory cycling
"""

import time
import subprocess
import signal
import sys

RUNNING = True

def signal_handler(sig, frame):
    global RUNNING
    print("\n[Autonomous Patrol] Deteniendo rutina y frenando robot...")
    RUNNING = False
    send_cmd_vel(0.0, 0.0)
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

def send_cmd_vel(linear_x: float, angular_z: float):
    payload = f"linear: {{x: {linear_x:.3f}}}, angular: {{z: {angular_z:.3f}}}"
    cmd = ["gz", "topic", "-t", "/cmd_vel", "-m", "gz.msgs.Twist", "-p", payload]
    try:
        subprocess.run(cmd, capture_output=True, timeout=2)
    except Exception as e:
        print(f"[Warn] Error publicando cmd_vel: {e}")

def main():
    print("=" * 60)
    print("  ROBOT SUMOSO - RUTINA AUTÓNOMA DE PATRULLAJE Y GIRO EN SITIO")
    print("  Arquitectura: 2WD 37D Traseras + 2 Omniwheels Delanteras")
    print("=" * 60)
    
    # Wait for simulation clock to be ready
    time.sleep(2)
    
    pattern = [
        {"action": "Avanzar recto hacia el tatami", "v": 0.40, "w": 0.0, "duration": 4.0},
        {"action": "Giro en radio cero (Spin 90° horario)", "v": 0.0, "w": -1.5, "duration": 2.2},
        {"action": "Avanzar hacia obstáculo lateral", "v": 0.35, "w": 0.0, "duration": 3.5},
        {"action": "Frenado y retroceso de seguridad", "v": -0.25, "w": 0.0, "duration": 2.0},
        {"action": "Giro en radio cero (Spin 180° anti-horario)", "v": 0.0, "w": 1.8, "duration": 3.2},
        {"action": "Patrulla en curva amplia (arco)", "v": 0.30, "w": 0.6, "duration": 4.5},
        {"action": "Pivoteo rápido de orientación", "v": 0.0, "w": -2.0, "duration": 1.8},
    ]

    loop_count = 1
    while RUNNING:
        print(f"\n--- [Ciclo de Patrullaje #{loop_count}] ---")
        for step in pattern:
            if not RUNNING:
                break
            print(f" -> Ejecutando: {step['action']} (v={step['v']} m/s, w={step['w']} rad/s, t={step['duration']}s)")
            
            # Publish commands continuously at ~10 Hz during the step duration
            t_end = time.time() + step["duration"]
            while time.time() < t_end and RUNNING:
                send_cmd_vel(step["v"], step["w"])
                time.sleep(0.1)
                
        loop_count += 1

if __name__ == "__main__":
    main()
