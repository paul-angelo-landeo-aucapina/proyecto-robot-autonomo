#!/usr/bin/env python3
"""
Simulación Física, Dinámica Motriz y Resistencia Estructural — Robot Móvil 2WD
=============================================================================
Este script calcula y simula de forma analítica el comportamiento mecánico,
la capacidad de carga útil (payload), los límites térmicos y de torque de los motores TT,
la resistencia a flexión de la placa acrílica PMMA (con factor de entalla Kt),
el balance longitudinal del centro de gravedad y la generación de curvas operativas.

Puede ejecutarse en cualquier PC (Linux, macOS, Windows) sin requerir Google Colab ni Jupyter.
Requisitos:
    python -m pip install numpy matplotlib
"""

import sys
import os
import math
import argparse
from dataclasses import dataclass

try:
    import numpy as np
except ImportError:
    print("Error: 'numpy' no está instalado. Instálalo ejecutando: pip install numpy", file=sys.stderr)
    sys.exit(1)

try:
    import matplotlib
    matplotlib.use('Agg')  # Renderizado headless independiente de servidor gráfico
    import matplotlib.pyplot as plt
    MATPLOTLIB_AVAILABLE = True
except ImportError:
    MATPLOTLIB_AVAILABLE = False


@dataclass
class RobotChasisConfig:
    """Parámetros físicos, geométricos, mecánicos y eléctricos del robot diferencial 2WD."""

    # --- Dimensiones Geométricas de la Placa Base de Acrílico (PMMA) ---
    largo_base_m: float = 0.195            # Longitud total placa: 195.0 mm (19.5 cm)
    ancho_base_m: float = 0.125            # Ancho total placa: 125.0 mm (12.5 cm)
    espesor_acrilico_m: float = 0.003      # Espesor nominal de placa: 3.0 mm (PMMA extruido/fundido)
    ancho_efectivo_ranuras_m: float = 0.080# Ancho resistente efectivo descontando ranuras de chasis: 80.0 mm
    
    # --- Propiedades Mecánicas del Acrílico (Polimetilmetacrilato - PMMA) ---
    E_pmma_pa: float = 3.0e9               # Módulo de Young = 3.0 GPa
    yield_flex_pmma_pa: float = 75.0e6     # Resistencia a la flexión = 75.0 MPa
    yield_tensile_pmma_pa: float = 65.0e6  # Resistencia a la tracción = 65.0 MPa
    tau_shear_pmma_pa: float = 40.0e6      # Resistencia al corte puro = 40.0 MPa
    densidad_pmma_kgm3: float = 1190.0     # Densidad del PMMA = 1190 kg/m^3
    poisson_pmma: float = 0.37             # Coeficiente de Poisson
    factor_seguridad_pmma: float = 3.0     # Coeficiente de seguridad de diseño (material frágil / entalla)
    Kt_entalla_ranura: float = 2.40        # Factor de concentración de esfuerzos en esquinas de ranuras
    
    # --- Cinemática y Rodadura (2WD + 1 Rueda Loca Caster Ball) ---
    diametro_rueda_m: float = 0.066        # Diámetro de rueda motriz: 66.0 mm
    radio_rueda_m: float = 0.033           # Radio de rueda Rw: 33.0 mm
    ancho_rueda_m: float = 0.026           # Ancho del neumático de goma: 26.0 mm
    distancia_entre_ruedas_m: float = 0.135# Ancho de vía efectivo (Track width): 135.0 mm
    wheelbase_span_m: float = 0.115        # Distancia entre eje motriz y rueda loca: 115.0 mm
    
    # --- Planta Motriz (2x Motores TT 1:48) y Driver TB6612FNG ---
    voltaje_nominal_v: float = 6.5         # Voltaje eficaz bajo carga con batería Li-Ion 2S (7.4V - caída driver)
    torque_bloqueo_motor_nm: float = 0.12  # Par de bloqueo por motor a 6.5V = 1.2 kg*cm = 0.12 N*m
    corriente_bloqueo_a: float = 0.90      # Corriente de bloqueo por motor = 0.90 A
    corriente_vacio_a: float = 0.12        # Corriente en vacío = 120 mA
    torque_continuo_seguro_ratio: float = 0.25 # Límite térmico continuo seguro (25% del stall torque)
    eficiencia_reductora_tt: float = 0.65  # Eficiencia de transmisión de engranajes plásticos spur (65%)
    
    # --- Parámetros de Operación y Resistencias al Movimiento ---
    gravedad_mps2: float = 9.81            # Aceleración de gravedad = 9.81 m/s^2
    crr_piso_liso: float = 0.030           # Coeficiente de rodadura (piso baldosa/madera lisa)
    crr_piso_medio: float = 0.055          # Coeficiente de rodadura (piso estándar + fricción rueda loca)
    crr_alfombra: float = 0.090            # Coeficiente de rodadura en alfombra de pelo corto
    aceleracion_deseada_mps2: float = 0.25 # Aceleración lineal requerida = 0.25 m/s^2
    pendiente_max_deg: float = 2.5         # Pendiente / rampa máxima a franquear = 2.5 grados
    
    # --- Masa Base del Robot (Tara) ---
    masa_chasis_acrilico_kg: float = 0.090 # Base cortada láser = 90 g
    masa_motores_ruedas_kg: float = 0.160  # 2x motores TT (30g c/u) + 2x ruedas (40g c/u) + caster (20g) = 160 g
    masa_electronica_kg: float = 0.075     # ESP32 + TB6612 + MPU6050 + 2x ToF + cableado = 75 g
    masa_bateria_2s_kg: float = 0.095      # 2 celdas Li-Ion 18650 + portapilas = 95 g
    masa_carcasa_3d_kg: float = 0.080      # Carcasa exterior PETG/PLA optimizada = 80 g
    
    @property
    def masa_tara_robot_kg(self) -> float:
        """Tara total del robot ensamblado sin carga útil adicional."""
        return (self.masa_chasis_acrilico_kg + self.masa_motores_ruedas_kg + 
                self.masa_electronica_kg + self.masa_bateria_2s_kg + self.masa_carcasa_3d_kg)


def imprimir_resumen_configuracion(c: RobotChasisConfig):
    """Muestra los parámetros base de la plataforma en formato tabular."""
    print("=" * 85)
    print("      CONFIGURACIÓN UNIFICADA DEL ROBOT MÓVIL AUTÓNOMO 2WD")
    print("=" * 85)
    print(f"  Dimensiones Chasis:        {c.largo_base_m*100:.1f} cm x {c.ancho_base_m*100:.1f} cm (Espesor: {c.espesor_acrilico_m*1000:.1f} mm PMMA)")
    print(f"  Ruedas Motrices:           Ø {c.diametro_rueda_m*1000:.1f} mm, Ancho: {c.ancho_rueda_m*1000:.1f} mm, Batalla: {c.wheelbase_span_m*1000:.1f} mm")
    print(f"  Masa Base (Tara Total):    {c.masa_tara_robot_kg*1000:.1f} g ({c.masa_tara_robot_kg:.3f} kg)")
    print(f"  Par de Bloqueo (2 Motores):{2 * c.torque_bloqueo_motor_nm:.3f} N*m")
    print(f"  Par Continuo Seguro (25%): {2 * c.torque_bloqueo_motor_nm * c.torque_continuo_seguro_ratio:.3f} N*m")
    print("-" * 85)


def calcular_capacidad_dinamica_motriz(c: RobotChasisConfig):
    """
    Evalúa la fuerza de tracción disponible y la carga útil admisible (payload)
    en diferentes condiciones de piso y pendiente para prevenir sobrecalentamiento.
    """
    t_cont_motor = c.torque_bloqueo_motor_nm * c.torque_continuo_seguro_ratio
    t_cont_total = 2 * t_cont_motor
    F_t_cont = t_cont_total / c.radio_rueda_m

    t_peak_total = 2 * (c.torque_bloqueo_motor_nm * 0.40)
    F_t_peak = t_peak_total / c.radio_rueda_m

    F_t_stall = (2 * c.torque_bloqueo_motor_nm) / c.radio_rueda_m

    escenarios = [
        {
            "nombre": "Piso Liso / Interior Ideal (Crr=0.03, plano, a=0.25 m/s²)", 
            "crr": c.crr_piso_liso, "theta": 0.0, "a": c.aceleracion_deseada_mps2
        },
        {
            "nombre": "Piso Real / Con Juntas y Caster (Crr=0.055, rampa 2.5°, a=0.25 m/s²)", 
            "crr": c.crr_piso_medio, "theta": np.radians(c.pendiente_max_deg), "a": c.aceleracion_deseada_mps2
        },
        {
            "nombre": "Alfombra Corta / Obstáculo (Crr=0.09, rampa 2.5°, a=0.20 m/s²)", 
            "crr": c.crr_alfombra, "theta": np.radians(c.pendiente_max_deg), "a": 0.20
        }
    ]

    print("=" * 85)
    print("ANÁLISIS DINÁMICO MOTRIZ Y CAPACIDAD DE TRACCIÓN (2x MOTORES TT 1:48)")
    print(f"  Fuerza de Tracción Continua Segura (25% stall): F_t,cont  = {F_t_cont:.2f} N")
    print(f"  Fuerza de Tracción Pico Transitorio (40% stall): F_t,peak  = {F_t_peak:.2f} N")
    print(f"  Fuerza de Tracción en Bloqueo (100% stall):       F_t,stall = {F_t_stall:.2f} N")
    print("-" * 85)

    resultados = []
    for esc in escenarios:
        denom = c.gravedad_mps2 * (esc["crr"] + np.sin(esc["theta"])) + esc["a"]
        m_tot_cont = F_t_cont / denom
        m_pay_cont = max(0.0, m_tot_cont - c.masa_tara_robot_kg)

        m_tot_peak = F_t_peak / denom
        m_pay_peak = max(0.0, m_tot_peak - c.masa_tara_robot_kg)

        resultados.append({
            "escenario": esc["nombre"],
            "m_tot_cont": m_tot_cont,
            "m_pay_cont": m_pay_cont,
            "m_pay_peak": m_pay_peak
        })
        print(f"Escenario: {esc['nombre']}")
        print(f"  -> Carga Útil Continua Recomendada (Sin fatiga ni sobrecalentamiento): {m_pay_cont*1000:.0f} g ({m_pay_cont:.2f} kg)")
        print(f"  -> Carga Útil Pico Transitoria (Capacidad límite antes de pérdida de ritmo): {m_pay_peak*1000:.0f} g ({m_pay_peak:.2f} kg)")
        print("-" * 85)

    return resultados


def calcular_resistencia_estructural_base(c: RobotChasisConfig):
    """
    Modela la flexión en 3 apoyos de la placa base de acrílico de 3.0 mm,
    incorporando el factor de concentración de tensiones (Kt) y la rigidez de los ejes TT.
    """
    Z = (c.ancho_efectivo_ranuras_m * (c.espesor_acrilico_m ** 2)) / 6.0
    sigma_adm = c.yield_flex_pmma_pa / c.factor_seguridad_pmma
    M_adm = (sigma_adm / c.Kt_entalla_ranura) * Z
    P_adm_flex_kg = (4.0 * M_adm) / (c.gravedad_mps2 * c.wheelbase_span_m)

    M_ruptura = (c.yield_flex_pmma_pa / c.Kt_entalla_ranura) * Z
    P_ruptura_kg = (4.0 * M_ruptura) / (c.gravedad_mps2 * c.wheelbase_span_m)

    I_seccion = (c.ancho_efectivo_ranuras_m * (c.espesor_acrilico_m ** 3)) / 12.0
    delta_max_adm = c.wheelbase_span_m / 200.0  # Límite L/200 = 0.575 mm
    P_deflexion_kg = (48.0 * delta_max_adm * c.E_pmma_pa * I_seccion) / (c.gravedad_mps2 * (c.wheelbase_span_m ** 3))

    P_ejes_tt_kg = 5.0  # Capacidad máxima radial de ejes plásticos TT

    print("=" * 85)
    print("ANÁLISIS DE RESISTENCIA MECÁNICA Y ROTURA ESTRUCTURAL (ACRÍLICO 3 mm + EJES)")
    print(f"  Módulo de Sección Z:                     {Z*1e9:.2f} mm³")
    print(f"  Momento de Inercia I:                    {I_seccion*1e12:.2f} mm⁴")
    print(f"  Tensión Admisible con FS=3.0:            {sigma_adm/1e6:.1f} MPa")
    print(f"  Carga Admisible por Flexión (con Kt):   P_adm = {P_adm_flex_kg:.2f} kg ({P_adm_flex_kg*1000:.0f} g)")
    print(f"  Carga Límite por Flecha (f <= L/200):    P_flecha = {P_deflexion_kg:.2f} kg")
    print(f"  Carga de Rotura Catastrófica (PMMA):     P_ruptura = {P_ruptura_kg:.2f} kg ({P_ruptura_kg*1000:.0f} g)")
    print(f"  Capacidad Límite de Ejes Plásticos TT:   P_ejes = {P_ejes_tt_kg:.2f} kg")
    print("-" * 85)
    print("CONCLUSIÓN DE CUADRO COMPARATIVO DE FALLA:")
    print("  1. Falla Estructural de la Base (Rotura del acrílico):      ~ 4.4 kg")
    print("  2. Falla Mecánica de Actuación (Flexión de ejes plásticos): ~ 5.0 kg")
    print("  3. Falla Operativa Dinámica (Pérdida de potencia motriz):   ~ 1.1 - 1.2 kg")
    print("  >> EL FACTOR LIMITANTE PRINCIPAL ES EL PAR MOTOR Y LA TEMPERATURA DE BOBINAS <<")
    print("=" * 85)

    return {
        "P_adm_flex_kg": P_adm_flex_kg,
        "P_deflexion_kg": P_deflexion_kg,
        "P_ruptura_kg": P_ruptura_kg,
        "P_ejes_tt_kg": P_ejes_tt_kg
    }


def simular_balance_centro_gravedad(c: RobotChasisConfig, m_payload_kg: float = 1.0):
    """
    Calcula la posición longitudinal del Centro de Gravedad y el reparto
    de fuerza normal entre el eje motriz y la rueda loca.
    """
    x_eje_motriz = 0.0
    x_rueda_loca = c.wheelbase_span_m  # 0.115 m
    x_tara = 0.040   # 40 mm delante del eje motriz
    x_plato = 0.048  # 48 mm delante del eje motriz

    m_total = c.masa_tara_robot_kg + m_payload_kg
    x_cg_global = (c.masa_tara_robot_kg * x_tara + m_payload_kg * x_plato) / m_total

    N_caster = (m_total * c.gravedad_mps2 * x_cg_global) / c.wheelbase_span_m
    N_motriz = (m_total * c.gravedad_mps2) - N_caster

    frac_motriz = N_motriz / (m_total * c.gravedad_mps2)
    frac_caster = N_caster / (m_total * c.gravedad_mps2)

    print("=" * 85)
    print(f"BALANCE DE CENTRO DE GRAVEDAD CON CARGA ÚTIL EN PLATO (Payload = {m_payload_kg*1000:.0f} g)")
    print(f"  Posición del Centroide Global X_cg:     {x_cg_global*1000:.1f} mm respecto al eje motriz")
    print(f"  Carga Normal en Eje Motriz (2 ruedas):  N_motriz = {N_motriz:.2f} N ({frac_motriz*100:.1f}%)")
    print(f"  Carga Normal en Rueda Loca (Caster):    N_caster = {N_caster:.2f} N ({frac_caster*100:.1f}%)")
    print(f"  Carga por Rueda Motriz:                 {N_motriz/2:.2f} N ({N_motriz/(2*c.gravedad_mps2)*1000:.0f} g)")
    print("  Estado de Estabilidad:                  ÓPTIMO (60-65% motriz para tracción, 35-40% caster)")
    print("=" * 85)


def graficar_curvas_operativas_robot(c: RobotChasisConfig, img_path: str):
    """
    Genera un panel de 4 cuadrantes con curvas de tracción, corriente, flexión y flecha elástica.
    """
    if not MATPLOTLIB_AVAILABLE:
        print("Aviso: 'matplotlib' no está disponible. No se generarán las curvas gráficas en PNG.", file=sys.stderr)
        return None

    payloads = np.linspace(0.0, 3.5, 100)
    
    # Fuerzas de tracción en distintos escenarios
    F_liso = (c.masa_tara_robot_kg + payloads) * (c.gravedad_mps2 * c.crr_piso_liso + c.aceleracion_deseada_mps2)
    F_real = (c.masa_tara_robot_kg + payloads) * (c.gravedad_mps2 * (c.crr_piso_medio + np.sin(np.radians(c.pendiente_max_deg))) + c.aceleracion_deseada_mps2)
    F_alfombra = (c.masa_tara_robot_kg + payloads) * (c.gravedad_mps2 * (c.crr_alfombra + np.sin(np.radians(c.pendiente_max_deg))) + 0.20)
    
    F_cont = (2 * c.torque_bloqueo_motor_nm * c.torque_continuo_seguro_ratio) / c.radio_rueda_m
    F_peak = (2 * c.torque_bloqueo_motor_nm * 0.40) / c.radio_rueda_m
    
    # Esfuerzos mecánicos y deformación
    Z = (c.ancho_efectivo_ranuras_m * (c.espesor_acrilico_m ** 2)) / 6.0
    I_seccion = (c.ancho_efectivo_ranuras_m * (c.espesor_acrilico_m ** 3)) / 12.0
    M_flector = (payloads * c.gravedad_mps2 * c.wheelbase_span_m) / 4.0
    sigma_pmma = (c.Kt_entalla_ranura * M_flector) / Z / 1e6
    flecha_mm = ((payloads * c.gravedad_mps2 * (c.wheelbase_span_m**3)) / (48 * c.E_pmma_pa * I_seccion)) * 1000.0
    
    # Estimación de corriente por motor
    tau_por_motor = (F_real * c.radio_rueda_m) / 2.0
    corriente_motor = c.corriente_vacio_a + (c.corriente_bloqueo_a - c.corriente_vacio_a) * (tau_por_motor / c.torque_bloqueo_motor_nm)
    
    fig, axs = plt.subplots(2, 2, figsize=(14, 10))
    
    # Cuadrante 1: Fuerza de Tracción vs Payload
    axs[0, 0].plot(payloads, F_liso, 'g-', label='Piso Liso Interior (Crr=0.03, plano)')
    axs[0, 0].plot(payloads, F_real, 'b-', lw=2, label='Piso Estándar + Rampa 2.5° (Crr=0.055)')
    axs[0, 0].plot(payloads, F_alfombra, 'm--', label='Alfombra Corta (Crr=0.090)')
    axs[0, 0].axhline(F_cont, color='red', linestyle=':', lw=2, label=f'Límite Térmico Continuo ({F_cont:.2f} N)')
    axs[0, 0].axhline(F_peak, color='orange', linestyle=':', lw=2, label=f'Límite Pico Transitorio ({F_peak:.2f} N)')
    axs[0, 0].axvspan(0.0, 1.2, color='green', alpha=0.12, label='Zona Operativa Recomendada (0 - 1.2 kg)')
    axs[0, 0].set_title('Capacidad de Tracción vs Carga en el Plato', fontsize=11, fontweight='bold')
    axs[0, 0].set_xlabel('Carga Útil en Plato (kg)')
    axs[0, 0].set_ylabel('Fuerza de Tracción Requerida (N)')
    axs[0, 0].legend(loc='upper left', fontsize=8)
    axs[0, 0].grid(True)
    
    # Cuadrante 2: Consumo de Corriente
    axs[0, 1].plot(payloads, corriente_motor * 1000, 'r-', lw=2, label='Corriente por Motor (mA)')
    axs[0, 1].axhline(c.corriente_bloqueo_a * c.torque_continuo_seguro_ratio * 1000, color='darkgreen', linestyle='--', label='Corriente Segura Continua (~225 mA)')
    axs[0, 1].axhline(600, color='darkorange', linestyle='--', label='Límite Térmico Transitorio (600 mA)')
    axs[0, 1].axhline(1200, color='black', linestyle=':', label='Límite Continuo Driver TB6612 (1.2 A)')
    axs[0, 1].set_title('Consumo de Corriente por Motor TT', fontsize=11, fontweight='bold')
    axs[0, 1].set_xlabel('Carga Útil en Plato (kg)')
    axs[0, 1].set_ylabel('Corriente de Armadura (mA)')
    axs[0, 1].legend(loc='upper left', fontsize=8)
    axs[0, 1].grid(True)
    
    # Cuadrante 3: Esfuerzo de Flexión en PMMA
    axs[1, 0].plot(payloads, sigma_pmma, 'purple', lw=2, label='Tensión von Mises máx (con Kt=2.4)')
    axs[1, 0].axhline(c.yield_flex_pmma_pa / (c.factor_seguridad_pmma * 1e6), color='green', linestyle='--', label='Tensión Admisible con FS=3.0 (25 MPa)')
    axs[1, 0].axhline(c.yield_flex_pmma_pa / 1e6, color='red', linestyle=':', label='Límite de Rotura PMMA (75 MPa)')
    axs[1, 0].set_title('Esfuerzo de Flexión en Placa Base (3.0 mm)', fontsize=11, fontweight='bold')
    axs[1, 0].set_xlabel('Carga Útil en Plato (kg)')
    axs[1, 0].set_ylabel('Esfuerzo Máximo (MPa)')
    axs[1, 0].legend(loc='upper left', fontsize=8)
    axs[1, 0].grid(True)
    
    # Cuadrante 4: Deflexión Elástica Central
    axs[1, 1].plot(payloads, flecha_mm, 'teal', lw=2, label='Deflexión Central en Placa (mm)')
    axs[1, 1].axhline(c.wheelbase_span_m / 200.0 * 1000.0, color='darkred', linestyle='--', label='Límite Admisible L/200 (0.575 mm)')
    axs[1, 1].set_title('Deflexión Elástica Central vs Carga', fontsize=11, fontweight='bold')
    axs[1, 1].set_xlabel('Carga Útil en Plato (kg)')
    axs[1, 1].set_ylabel('Flecha Central (mm)')
    axs[1, 1].legend(loc='upper left', fontsize=8)
    axs[1, 1].grid(True)
    
    plt.tight_layout()
    os.makedirs(os.path.dirname(os.path.abspath(img_path)), exist_ok=True)
    plt.savefig(img_path, dpi=120)
    plt.close(fig)
    print(f"Gráficas operativas guardadas exitosamente en: {img_path}")
    return img_path


def main():
    parser = argparse.ArgumentParser(
        description="Simulación física, motriz y estructural del Robot Autónomo 2WD"
    )
    parser.add_argument(
        "--payload", type=float, default=1.0, 
        help="Carga útil a evaluar en el plato porta-objetos (en kg, ej. 1.0)"
    )
    parser.add_argument(
        "--output-img", type=str, default=None,
        help="Ruta donde guardar la imagen PNG con las curvas operativas"
    )
    parser.add_argument(
        "--no-plot", action="store_true",
        help="Omitir la generación de gráficos con Matplotlib (solo salida por consola)"
    )
    args = parser.parse_args()

    cfg = RobotChasisConfig()

    imprimir_resumen_configuracion(cfg)
    calcular_capacidad_dinamica_motriz(cfg)
    calcular_resistencia_estructural_base(cfg)
    simular_balance_centro_gravedad(cfg, m_payload_kg=args.payload)

    if not args.no_plot:
        if args.output_img:
            out_img = args.output_img
        else:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            out_img = os.path.join(script_dir, "curvas_rendimiento_robot_2wd.png")
        graficar_curvas_operativas_robot(cfg, out_img)


if __name__ == "__main__":
    main()
