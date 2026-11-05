"""
Launch file para ROS 2 y Gazebo:
Carga el mundo de entrenamiento mixto (Piso Plano + Rampa de Subida y Bajada con Obstaculos),
spawnea el robot diferencial 2WD en el Punto A (0, 0, 0.05) y activa los sensores MPU6050 y VL53L0X.
"""

import os
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription, DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory

def generate_launch_description():
    pkg_gazebo_ros = get_package_share_directory('gazebo_ros')
    
    # Directorio actual y rutas relativas portables
    launch_dir = os.path.dirname(os.path.realpath(__file__))
    base_dir = os.path.dirname(launch_dir)
    world_path = os.path.join(base_dir, 'worlds', 'pista_rampa_y_plano.world')
    urdf_path = os.path.join(base_dir, 'models', 'robot_diferencial.urdf.xacro')

    return LaunchDescription([
        # 1. Servidor y GUI de Gazebo con la pista de entrenamiento
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                os.path.join(pkg_gazebo_ros, 'launch', 'gazebo.launch.py')
            ),
            launch_arguments={'world': world_path, 'verbose': 'true'}.items()
        ),

        # 2. Spawner del robot en el Punto A de inicio
        Node(
            package='gazebo_ros',
            executable='spawn_entity.py',
            name='spawn_robot_diferencial',
            arguments=[
                '-file', urdf_path,
                '-entity', 'robot_diferencial_esp32',
                '-x', '0.0',
                '-y', '0.0',
                '-z', '0.05',
                '-Y', '0.0' # Orientacion mirando hacia el eje +X
            ],
            output='screen'
        ),

        # 3. Publicador de estados de articulaciones del modelo
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            name='robot_state_publisher',
            parameters=[{'robot_description': open(urdf_path).read()}],
            output='screen'
        )
    ])
