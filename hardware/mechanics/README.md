# Subconjunto Mecánico, Estructural y Carrocería — Proyecto Robot Autónomo 2WD

Este directorio contiene el paquete completo de ingeniería mecánica, diseño paramétrico 3D (FreeCAD y OpenSCAD), mallas para impresión 3D (STL), modelos normalizados STEP, simulación física y cálculos estructurales analíticos del **Proyecto Robot Autónomo 2WD**, basado en el chasis comercial de acrílico con motores TT, estabilización inercial (ESP32 + MPU6050 + TB6612FNG) y bandeja superior porta-objetos.

---

## 1. Especificaciones de Ingeniería del Robot 2WD con Plato

- **Plataforma Mecánica:** Chasis de acrílico cortado láser (PMMA $3.0\text{ mm}$), dimensiones $195.0\text{ mm} \times 125.0\text{ mm}$ ($19.5 \times 12.5\text{ cm}$).
- **Configuración Cinemática:** Tracción diferencial (2WD) con 2 ruedas motrices traseras ($\varnothing 66.0\text{ mm}$, ancho $26.0\text{ mm}$) y 1 rueda loca frontal (caster ball de apoyo).
- **Wheelbase y Vía:** Batalla (distancia entre ejes) $L_{wb} = 115.0\text{ mm}$, Ancho de vía efectivo $W_{track} = 135.0\text{ mm}$.
- **Despeje Libre al Suelo (Ground Clearance):** **$16.0\text{ mm}$** bajo la placa base acrílica.
- **Tara del Robot:** **$0.50\text{ kg}$** ($500\text{ g}$ total incluyendo base acrílica, motores TT, ruedas, caster, batería Li-Ion 2S 18650, driver TB6612FNG, ESP32, sensores ToF y carcasa 3D).
- **Capacidad de Carga Útil (Payload en el Plato):**
  - **Carga Nominal Continua Recomendada:** **$1.0\text{ a }1.2\text{ kg}$** (operación sin fatiga térmica de motores, sin sobrecarga en puente H y con plena capacidad de control angular PI).
  - **Carga Límite Transitoria Dinámica:** **$1.5\text{ kg}$** (rampas breves $\le 2.5^\circ$, alfombra baja).
  - **Límite de Rotura Estructural:** **$4.4\text{ kg}$** (límite de flexión del acrílico con factor de concentración de tensiones $K_t = 2.4$ en ranuras) y **$5.0\text{ kg}$** (flexión de ejes plásticos TT).
  - *Conclusión:* El factor limitante es el **par motriz y calentamiento de bobinas**, no la rotura física del chasis.
- **Carcasa Externa Protectora:** Envolvente modular en PETG/PLA ($190 \times 120 \times 55\text{ mm}$) con pasaruedas integrados ($R = 38\text{ mm}$, holgura $5\text{ mm}$), ventanas frontales para 2x sensores láser ToF VL53L0X a $\pm 15^\circ$ y anclajes para el plato.
- **Plato Porta-Objetos Superior:** Bandeja de transporte de $130.0 \times 95.0\text{ mm}$ con reborde perimetral anticaída de $8.0\text{ mm}$, nervaduras antideslizantes y 4 puntos de fijación M3 ubicados a $X = +48\text{ mm}$ del eje motriz (reparto óptimo de peso: $61\%$ en ruedas motrices para tracción, $39\%$ en caster).

---

## 2. Estructura de Modelos CAD y Cálculos

```text
hardware/mechanics/
├── CADs/
│   ├── step/              # Sólidos B-Rep estándar ISO 10303 (FreeCAD)
│   │   ├── chasis_base_acrilico_195x125.step
│   │   ├── carcasa_externa_2wd.step
│   │   └── plato_porta_objetos_2wd.step
│   ├── fcstd/             # Documentos paramétricos nativos de FreeCAD
│   │   ├── chasis_base_acrilico_195x125.FCStd
│   │   ├── carcasa_externa_2wd.FCStd
│   │   └── plato_porta_objetos_2wd.FCStd
│   ├── scad/              # Modelos procedimentales OpenSCAD (.scad)
│   │   ├── chasis_base_acrilico_2wd.scad
│   │   ├── carcasa_externa_2wd.scad
│   │   ├── plato_porta_objetos_2wd.scad
│   │   └── ensamblaje_robot_2wd_completo.scad
│   ├── stl/               # Mallas para fabricación aditiva (FDM / 3D Print)
│   │   ├── chasis_base_acrilico_195x125.stl
│   │   ├── carcasa_externa_2wd.stl
│   │   ├── plato_porta_objetos_2wd.stl
│   │   └── ensamblaje_completo_2wd.stl
│   └── generate_freecad_2wd.py # Script de generación y validación FreeCAD
├── calculations/
│   ├── CalculosMatematicosyFisicosRobot.ipynb # Memoria interactiva Jupyter con gráficos
│   └── curvas_rendimiento_robot_2wd.png       # Curvas de tracción, corriente y flexión
└── README.md
```

---

## 3. Guía de Uso de Herramientas CAD

### A. Inspección y Renderizado en OpenSCAD
Para abrir el ensamble completo en [OpenSCAD](https://openscad.org/):
1. Abrir `hardware/mechanics/CADs/scad/ensamblaje_robot_2wd_completo.scad`.
2. Utilizar el selector `modo_vista`:
   - `completo`: Visualiza el chasis, ruedas, motores, caster, electrónica, carcasa externa, plato y carga de prueba.
   - `sin_plato`: Muestra el robot cerrado sin el plato de carga.
   - `carcasa_transparente`: Carcasa translúcida para verificar holguras internas.
   - `solo_mecanica`: Chasis base desnudo con rodadura y actuadores.

### B. Apertura y Edición en FreeCAD
Los modelos paramétricos nativos están en `hardware/mechanics/CADs/fcstd/` y los intercambiables en `step/`:
1. Abrir con **FreeCAD 1.0+** (`flatpak run org.freecad.FreeCAD`).
2. Para regenerar o exportar los sólidos desde línea de comandos:
```bash
flatpak run --filesystem=/home/paul --command=FreeCADCmd org.freecad.FreeCAD hardware/mechanics/CADs/generate_freecad_2wd.py
```

### C. Parámetros de Impresión 3D (Laminado FDM)
- **Carcasa Externa (`carcasa_externa_2wd.stl`):**
  - Material: PETG o PLA+.
  - Altura de capa: $0.20\text{ mm}$, 3 perímetros de pared ($1.2\text{ mm}$), relleno $20\%$ Giroide.
- **Plato Porta-Objetos (`plato_porta_objetos_2wd.stl`):**
  - Material: PETG o ABS (resistente a impactos).
  - 4 perímetros de pared, relleno $25\%$, orientación plana sobre la base del plato (no requiere soportes).
