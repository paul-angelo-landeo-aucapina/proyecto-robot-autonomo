## Estructura del Repositorio

El proyecto adopta una arquitectura modular para aislar el desarrollo de hardware físico, el control en tiempo real, el entrenamiento de modelos y las interfaces de usuario. Todo nuevo desarrollo debe integrarse estrictamente en su dominio correspondiente.

```text
/proyecto_robot
├── /docs                 # Documentación global, pinouts, protocolos de comunicación.
├── /hardware
│   ├── /mechanics        # Archivos CAD, STL para impresión 3D, cálculos estructurales.
│   └── /electronics      # Esquemáticos, PCBs, diagramas de conexión.
├── /software
│   ├── /firmware         # Código de microcontroladores (C/C++, FreeRTOS, Arduino).
│   ├── /core_control     # Lógica de alto nivel del robot, ROS2, navegación, inferencia.
│   ├── /simulation       # Entornos 3D y modelos URDF/SDF para pruebas virtuales.
│   └── /ai_training      # Scripts de entrenamiento, datasets y validación de modelos.
└── /app                  # Aplicación Android (Java/Kotlin/Flutter) e interfaces de usuario.
