import FreeCAD
import Part
import math
import os

print("=" * 80)
print("ACTUALIZANDO SÓLIDOS B-REP FREECAD (CARCASA CON CUNAS ToF OPTIMIZADAS)")
print("=" * 80)

cad_dir = "hardware/mechanics/CADs"
step_dir = os.path.join(cad_dir, "step")
fcstd_dir = os.path.join(cad_dir, "fcstd")
stl_dir = os.path.join(cad_dir, "stl")

# ------------------------------------------------------------------------------
# 1. CHASIS BASE DE ACRÍLICO (195 x 125 x 3.0 mm)
# ------------------------------------------------------------------------------
print("\n[1/3] Verificando Placa Base Acrílica (195 x 125 x 3 mm)...")
doc_base = FreeCAD.newDocument("ChasisBaseAcrilico2WD")
L_base = 195.0
W_base = 125.0
t_base = 3.0
x_eje = 65.0
x_caster = 170.0

placa = Part.makeBox(L_base, W_base, t_base)
corte_esq1 = Part.makeBox(25.0, 25.0, t_base + 2)
corte_esq1.translate(FreeCAD.Vector(L_base - 20, -5, -1))
corte_esq2 = Part.makeBox(25.0, 25.0, t_base + 2)
corte_esq2.translate(FreeCAD.Vector(L_base - 20, W_base - 20, -1))
placa = placa.cut(corte_esq1).cut(corte_esq2)

ranura_izq = Part.makeBox(75.0, 16.0, t_base + 2)
ranura_izq.translate(FreeCAD.Vector(x_eje - 37.5, -1.0, -1.0))
ranura_der = Part.makeBox(75.0, 16.0, t_base + 2)
ranura_der.translate(FreeCAD.Vector(x_eje - 37.5, W_base - 15.0, -1.0))
placa = placa.cut(ranura_izq).cut(ranura_der)

for sx, sy in [(-20, 20), (20, 20), (-20, W_base - 28), (20, W_base - 28)]:
    slot_t = Part.makeBox(3.5, 8.0, t_base + 2)
    slot_t.translate(FreeCAD.Vector(x_eje + sx, sy, -1.0))
    placa = placa.cut(slot_t)

for dx, dy in [(-15, 0), (15, 0), (0, -15), (0, 15)]:
    taladro_c = Part.makeCylinder(1.6, t_base + 2, FreeCAD.Vector(x_caster + dx, W_base/2 + dy, -1.0), FreeCAD.Vector(0, 0, 1))
    placa = placa.cut(taladro_c)

taladro_sw = Part.makeCylinder(10.0, t_base + 2, FreeCAD.Vector(120.0, W_base/2, -1.0), FreeCAD.Vector(0, 0, 1))
placa = placa.cut(taladro_sw)

for x_c, y_c in [(15, 12), (15, W_base - 12), (145, 12), (145, W_base - 12)]:
    taladro_carc = Part.makeCylinder(1.6, t_base + 2, FreeCAD.Vector(x_c, y_c, -1.0), FreeCAD.Vector(0, 0, 1))
    placa = placa.cut(taladro_carc)

obj_base = doc_base.addObject("Part::Feature", "PlacaBaseAcrilico")
obj_base.Shape = placa
doc_base.recompute()
Part.export([obj_base], os.path.join(step_dir, "chasis_base_acrilico_195x125.step"))
doc_base.saveAs(os.path.join(fcstd_dir, "chasis_base_acrilico_195x125.FCStd"))
Part.export([obj_base], os.path.join(stl_dir, "chasis_base_acrilico_freecad.stl"))
FreeCAD.closeDocument(doc_base.Name)
print("  Placa base verificada y exportada.")

# ------------------------------------------------------------------------------
# 2. CARCASA EXTERNA CON ALOJAMIENTOS DE PRECISIÓN PARA 2x ToF VL53L0X
# ------------------------------------------------------------------------------
print("\n[2/3] Modelando Carcasa Externa con Cunas ToF Abocinadas (±20° yaw, +3° pitch)...")
doc_carc = FreeCAD.newDocument("CarcasaExterna2WD")

L_carc = 190.0
W_carc = 120.0
H_carc = 55.0
t_wall = 2.4

# Cuerpo exterior
caja_ext = Part.makeBox(L_carc, W_carc, H_carc)
c1 = Part.makeBox(20.0, 20.0, H_carc + 2)
c1.translate(FreeCAD.Vector(L_carc - 15, -5, -1))
c2 = Part.makeBox(20.0, 20.0, H_carc + 2)
c2.translate(FreeCAD.Vector(L_carc - 15, W_carc - 15, -1))
caja_ext = caja_ext.cut(c1).cut(c2)

# Vaciado interior
caja_int = Part.makeBox(L_carc - 2 * t_wall, W_carc - 2 * t_wall, H_carc - t_wall)
caja_int.translate(FreeCAD.Vector(t_wall, t_wall, -1.0))
carcasa = caja_ext.cut(caja_int)

# Pasaruedas
arco_izq = Part.makeCylinder(38.0, 32.0, FreeCAD.Vector(x_eje, -5.0, 15.0), FreeCAD.Vector(0, 1, 0))
arco_der = Part.makeCylinder(38.0, 32.0, FreeCAD.Vector(x_eje, W_carc - 27.0, 15.0), FreeCAD.Vector(0, 1, 0))
carcasa = carcasa.cut(arco_izq).cut(arco_der)

# ---------------------------------------------------------
# ALOJAMIENTOS DE SENSORES ToF VL53L0X
# Módulos ubicados en los chaflanes frontales (Z=30 mm)
# ---------------------------------------------------------
z_tof = 30.0

# Sensor Izquierdo (X=168, Y=34 mm)
# 1. Ventana de la tronera óptica principal (anti-crosstalk)
tof_ap_izq = Part.makeBox(25.0, 12.0, 8.0)
tof_ap_izq.translate(FreeCAD.Vector(165.0, 28.0, z_tof - 4.0))

# 2. Asiento para PCB (25.0 x 13.0 mm)
tof_seat_izq = Part.makeBox(8.0, 26.0, 14.0)
tof_seat_izq.translate(FreeCAD.Vector(158.0, 21.0, z_tof - 7.0))

# 3. Taladros de fijación M2.5 (separación 20 mm)
hole_izq_1 = Part.makeCylinder(1.25, 20.0, FreeCAD.Vector(160.0, 23.0, z_tof), FreeCAD.Vector(1, 0, 0))
hole_izq_2 = Part.makeCylinder(1.25, 20.0, FreeCAD.Vector(160.0, 43.0, z_tof), FreeCAD.Vector(1, 0, 0))

carcasa = carcasa.cut(tof_ap_izq).cut(tof_seat_izq).cut(hole_izq_1).cut(hole_izq_2)

# Sensor Derecho (X=168, Y=86 mm)
tof_ap_der = Part.makeBox(25.0, 12.0, 8.0)
tof_ap_der.translate(FreeCAD.Vector(165.0, W_carc - 40.0, z_tof - 4.0))

tof_seat_der = Part.makeBox(8.0, 26.0, 14.0)
tof_seat_der.translate(FreeCAD.Vector(158.0, W_carc - 47.0, z_tof - 7.0))

hole_der_1 = Part.makeCylinder(1.25, 20.0, FreeCAD.Vector(160.0, W_carc - 43.0, z_tof), FreeCAD.Vector(1, 0, 0))
hole_der_2 = Part.makeCylinder(1.25, 20.0, FreeCAD.Vector(160.0, W_carc - 23.0, z_tof), FreeCAD.Vector(1, 0, 0))

carcasa = carcasa.cut(tof_ap_der).cut(tof_seat_der).cut(hole_der_1).cut(hole_der_2)

# Taladros de fijación superior del plato (4x M3)
x_plato_centro = x_eje + 48.0 # 113 mm
dx_p = 90.0
dy_p = 70.0
for sx in [-1, 1]:
    for sy in [-1, 1]:
        h_p = Part.makeCylinder(1.7, 10.0, FreeCAD.Vector(x_plato_centro + sx*(dx_p/2), W_carc/2 + sy*(dy_p/2), H_carc - 5.0), FreeCAD.Vector(0, 0, 1))
        carcasa = carcasa.cut(h_p)

# Ranuras de ventilación
for i in range(-3, 4):
    slot_v = Part.makeBox(3.0, 40.0, 6.0)
    slot_v.translate(FreeCAD.Vector(35.0 + i * 8.0, W_carc/2 - 20.0, H_carc - 3.0))
    carcasa = carcasa.cut(slot_v)

obj_carc = doc_carc.addObject("Part::Feature", "CarcasaExterna")
obj_carc.Shape = carcasa
doc_carc.recompute()

print("  Valid shape:", obj_carc.Shape.isValid())
print("  Volume: %.1f mm³" % obj_carc.Shape.Volume)

Part.export([obj_carc], os.path.join(step_dir, "carcasa_externa_2wd.step"))
doc_carc.saveAs(os.path.join(fcstd_dir, "carcasa_externa_2wd.FCStd"))
Part.export([obj_carc], os.path.join(stl_dir, "carcasa_externa_freecad.stl"))
FreeCAD.closeDocument(doc_carc.Name)
print("  Carcasa actualizada exportada a STEP, FCStd y STL.")

# ------------------------------------------------------------------------------
# 3. PLATO PORTA-OBJETOS SUPERIOR (130 x 95 x 8.0 mm)
# ------------------------------------------------------------------------------
print("\n[3/3] Verificando Plato Porta-Objetos Superior...")
doc_plato = FreeCAD.newDocument("PlatoPortaObjetos2WD")
L_p = 130.0
W_p = 95.0
H_borde = 8.0
t_piso = 2.5
t_borde = 2.5

caja_plato_ext = Part.makeBox(L_p, W_p, H_borde)
caja_plato_int = Part.makeBox(L_p - 2*t_borde, W_p - 2*t_borde, H_borde - t_piso + 1.0)
caja_plato_int.translate(FreeCAD.Vector(t_borde, t_borde, t_piso))
plato = caja_plato_ext.cut(caja_plato_int)

for sx in [-1, 1]:
    for sy in [-1, 1]:
        px = L_p/2 + sx*(dx_p/2)
        py = W_p/2 + sy*(dy_p/2)
        torreta = Part.makeCylinder(5.0, 5.0, FreeCAD.Vector(px, py, -5.0), FreeCAD.Vector(0, 0, 1))
        plato = plato.fuse(torreta)
        taladro_p = Part.makeCylinder(1.7, H_borde + 8.0, FreeCAD.Vector(px, py, -6.0), FreeCAD.Vector(0, 0, 1))
        plato = plato.cut(taladro_p)

for i in range(-5, 6):
    estria = Part.makeBox(1.8, W_p - 2*t_borde - 4.0, 1.2)
    estria.translate(FreeCAD.Vector(L_p/2 + i * 10.0 - 0.9, t_borde + 2.0, t_piso))
    plato = plato.fuse(estria)

obj_plato = doc_plato.addObject("Part::Feature", "PlatoPortaObjetos")
obj_plato.Shape = plato
doc_plato.recompute()
Part.export([obj_plato], os.path.join(step_dir, "plato_porta_objetos_2wd.step"))
doc_plato.saveAs(os.path.join(fcstd_dir, "plato_porta_objetos_2wd.FCStd"))
Part.export([obj_plato], os.path.join(stl_dir, "plato_porta_objetos_freecad.stl"))
FreeCAD.closeDocument(doc_plato.Name)
print("  Plato porta-objetos verificado y exportado.")

print("\n" + "=" * 80)
print("ACTUALIZACIÓN FREECAD COMPLETADA CON ÉXITO")
print("=" * 80)
