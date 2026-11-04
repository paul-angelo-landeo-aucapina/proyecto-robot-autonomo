"""
Launch file para ROS 2 y Gazebo:
Lanza el mundo con obstaculos, spawnea el robot diferencial e inicializa los plugins de MPU6050 y VL53L0X.
"""

import os
from launch import LaunchDescription
from launch.actions import ExecuteProcess, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory

def generate_launch_description():
    pkg_gazebo_ros = get_package_share_directory('gazebo_ros')
    
    # Ruta del mundo
    world_path = os.path.join(os.getcwd(), 'laberinto_obstaculos.world')
    urdf_path = os.path.join(os.getcwd(), 'robot_diferencial.urdf.xacro')

    return LaunchDescription([
        # 1. Iniciar servidor y cliente de Gazebo con el mundo personalizado
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                os.path.join(pkg_gazebo_ros, 'launch', 'gazebo.launch.py')
            ),
            launch_arguments={'world': world_path}.items()
        ),

        # 2. Spawn del robot en Gazebo en la posicion inicial (0, 0, 0.05)
        Node(
            package='gazebo_ros',
            executable='spawn_entity.py',
            arguments=[
                '-file', urdf_path,
                '-entity', 'robot_diferencial_esp32',
                '-x', '0.0',
                '-y', '0.0',
                '-z', '0.05'
            ],
            output='screen'
        ),

        # 3. Lanzar estado de articulaciones
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            parameters=[{'robot_description': open(urdf_path).read()}],
            output='screen'
        )
    ])
