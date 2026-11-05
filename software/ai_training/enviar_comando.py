"""
=========================================================================================
CLIENTE DE COMANDOS CMD PARA EL ROBOT EN TIEMPO REAL
Proyecto: Robot Movil Autonomo con Estabilizacion Inercial y Evasion Reactiva
=========================================================================================
Uso desde la terminal:
  python enviar_comando.py heading_hold    -> Ejecuta avance rectilineo estabilizado
  python enviar_comando.py evasion         -> Demuestra evasion reactiva a <180mm con giro 90 deg
  python enviar_comando.py emergencia      -> Demuestra frenado activo y retroceso 250ms a <80mm
  python enviar_comando.py ir 3.5 2.0      -> Envia el robot al punto (X=3.5, Y=2.0)
  python enviar_comando.py entrenar        -> Ejecuta entrenamiento acelerado de trayectoria
  python enviar_comando.py reiniciar       -> Reinicia posicion al punto A
=========================================================================================
"""

import sys
import os
import json

CMD_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "comando_activo.json")

def enviar(comando, param=None):
    data = {"cmd": comando, "param": param, "time": os.times()[4]}
    with open(CMD_FILE, "w") as f:
        json.dump(data, f)
    print(f"\n[ENVIADO A SIMULADOR] Comando: '{comando.upper()}' {param if param else ''}")
    print("[OK] Mira la ventana del simulador: el robot esta ejecutando el movimiento ahora mismo.\n")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("\n" + "="*60)
        print("  CONSOLA DE CONTROL Y ENTRENAMIENTO DEL ROBOT (CMD)")
        print("="*60)
        print("Comandos disponibles:")
        print("  python enviar_comando.py heading_hold")
        print("  python enviar_comando.py evasion")
        print("  python enviar_comando.py emergencia")
        print("  python enviar_comando.py ir <X> <Y>")
        print("  python enviar_comando.py entrenar")
        print("  python enviar_comando.py reiniciar")
        print("="*60 + "\n")
        sys.exit(0)

    cmd = sys.argv[1].lower()
    param = None
    if cmd == "ir" and len(sys.argv) >= 4:
        param = [float(sys.argv[2]), float(sys.argv[3])]
    enviar(cmd, param)
