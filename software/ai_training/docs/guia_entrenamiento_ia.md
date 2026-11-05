# Guía de Entrenamiento de Inteligencia Artificial y Aprendizaje por Refuerzo

Esta guía detalla el flujo de trabajo para entrenar las políticas de control del robot autónomo diferencial, tanto en simulador local como en Gazebo Harmonic.

---

## 1. Arquitectura de las Políticas de Control

El robot cuenta con dos mecanismos de toma de decisiones:
1. **Control Reactivo Milimétrico**: Reglas deterministas para evasión rápida ante obstáculos a $<180\text{ mm}$ (zona de frenado) y $<80\text{ mm}$ (parada activa y retroceso durante 250 ms con TB6612FNG).
2. **Navegación Estabilizada (Heading Hold / DQN)**: Redes neuronales y control PI asistido por sensor inercial MPU6050 para evitar derivas angulares y corregir rumbo en rampas con pendiente de $12.7^\circ$.

---

## 2. Modalidad A: Entrenamiento DQN con PyTorch y CUDA (Punto a Punto)

Utiliza la red neuronal Deep Q-Network definida en [`train_point_to_point_rl.py`](file:///home/paul/Documents/workfiles/proyecto-robot-autonomo/software/ai_training/train_point_to_point_rl.py). Corre acelerada por GPU sobre el entorno virtual local.

### Comandos de Ejecución

1. **Activar el entorno virtual**:
   - En Linux:
     ```bash
     source .venv/bin/activate
     ```
   - En Windows:
     ```cmd
     .venv\Scripts\activate
     ```

3. **Lanzar el entrenamiento**:
   ```bash
   python software/ai_training/training/train_point_to_point_rl.py
   ```

4. **Monitoreo en vivo**:
   ```bash
   tensorboard --logdir ./runs/
   ```
   Abrir `http://localhost:6006` en el navegador.

---

## 3. Modalidad B: Entrenamiento Online en Gazebo Sim con ROS 2

Utiliza el simulador de física ODE para interactuar con sensores reales simulados (2x ToF VL53L0X a 50 Hz y MPU6050 a 100 Hz).

### Comandos de Ejecución

1. **Lanzar Gazebo en modo servidor Headless (ahorra 80% de recursos)**:
   - En Linux:
     ```bash
     gz sim -s -r software/ai_training/worlds/laberinto_obstaculos.world &
     ```
   - En Windows (PowerShell con Docker Desktop):
     ```powershell
     Start-Process docker -ArgumentList "run --rm --net=host -v ${PWD}:/workspace -w /workspace osrf/ros:jazzy-simulation gz sim -s -r software/ai_training/worlds/laberinto_obstaculos.world" -NoNewWindow
     ```

2. **Ejecutar el nodo de entrenamiento**:
   - En Linux (usando el wrapper de ROS 2):
     ```bash
     ros2-python software/ai_training/training/train_evasion_rl.py --episodes 1000 --timesteps 500
     ```
   - En Windows (PowerShell):
     ```powershell
     docker run --rm -it --net=host -v "${PWD}:/workspace" -w /workspace osrf/ros:jazzy-simulation python3 software/ai_training/training/train_evasion_rl.py --episodes 1000 --timesteps 500
     ```

3. **Finalizar simulación al concluir**:
   - En Linux:
     ```bash
     pkill -f "gz sim"
     ```
   - En Windows:
     ```powershell
     docker stop $(docker ps -q --filter ancestor=osrf/ros:jazzy-simulation)
     ```

---

## 4. Exportación y Despliegue al Microcontrolador ESP32

Una vez completado el entrenamiento:
1. El script genera las ganancias óptimas y la tabla de pesos en [`politica_entrenada_robot.json`](../policies/politica_entrenada_robot.json).
2. Se compila directamente en la cabecera C++ [`politica_optima_esp32.h`](../policies/politica_optima_esp32.h).
3. Este header es consumido por el firmware de producción en [`firmware/`](file:///home/paul/Documents/workfiles/proyecto-robot-autonomo/firmware/) para ejecutarse en tiempo real sin latencia en el ESP32.
