// ==============================================================================
// ROBOT MOVIL AUTONOMO 2WD - CARCASA EXTERNA CON SOPORTES PROFESIONALES ToF
// Diseñada para Base Acrílica de 195 x 125 mm y Ruedas d=66mm, w=26mm
//
// CARACTERÍSTICAS INTEGRALMENTE ACTUALIZADAS:
// 1. Cunas dedicadas para 2x módulos láser ToF VL53L0X (GY-530 / VL53L0X V2)
// 2. Troneras ópticas abocinadas a 45° (anti-crosstalk y anti-rebote interno)
// 3. Torretas de fijación con taladros M2.5 espaciados a 20.0 mm
// 4. Ángulo de visión divergente (±20° yaw) con elevación anti-suelo (+3° pitch)
// 5. Canal posterior despejado para cableado I2C (Dupont 5 pines)
// 6. Pasaruedas laterales amplios (R=38mm, holgura 5mm)
// 7. Superficie y anclajes superiores para el Plato Porta-Objetos (4x M3)
// ==============================================================================

$fn = 40;

// Parámetros principales (mm)
L_cuerpo = 190.0;
W_cuerpo = 120.0;
H_cuerpo = 55.0;
t_pared = 2.4;

// Posición del eje motriz
x_eje_motriz = 65.0;

// Parámetros de arcos de rueda (Rueda d=66mm, w=26mm)
r_arco_rueda = 38.0;
w_arco_rueda = 32.0;

// Parámetros del plato superior (Centroide a X = x_eje + 48 = 113 mm)
x_centro_plato = x_eje_motriz + 48.0;

// Parámetros de fijación de sensores ToF VL53L0X
// PCB estándar: 25.0 x 13.0 mm, distancia entre taladros = 20.0 mm
z_tof = 30.0;
pitch_tof = 3.0; // Inclinación hacia arriba (+3°) para evitar reflexiones en el suelo

// Submódulo: Alojamiento y cuna mecánica para sensor ToF (Positivo)
module cuna_tof_positivo() {
    // Bloque macizo donde se mecanizan la cuna, torretas y tronera
    translate([0, 0, 0])
        rotate([0, -pitch_tof, 0])
        cube([14.0, 32.0, 20.0], center=true);
}

// Submódulo: Vaciados ópticos, fijaciones y cables para sensor ToF (Negativo)
module cuna_tof_negativo() {
    rotate([0, -pitch_tof, 0]) {
        // 1. Asiento empotrado para la placa PCB del sensor (25.5 x 13.5 x 2.2 mm)
        translate([1.5, 0, 0])
            cube([2.5, 25.6, 13.6], center=true);
            
        // 2. Tronera óptica frontal abocinada (Anti-Crosstalk cone)
        // Ventana interior mínima (11x6 mm) que se expande hacia afuera a 18x12 mm
        translate([6.0, 0, 0])
            hull() {
                translate([-3.0, 0, 0]) cube([1.0, 10.0, 6.0], center=true);
                translate([4.0, 0, 0]) cube([1.0, 18.0, 12.0], center=true);
            }
            
        // 3. Taladros de fijación para tornillos M2.5 (Separación = 20.0 mm)
        for (sy = [-1, 1]) {
            translate([0, sy * 10.0, 0])
                rotate([0, 90, 0])
                cylinder(d=2.3, h=18.0, center=true); // Taladro guía M2.5
        }
        
        // 4. Canal posterior para conector y cables Dupont (5 pines)
        translate([-6.0, 0, 0])
            cube([12.0, 18.0, 14.0], center=true);
    }
}

module carcasa_externa_2wd() {
    color([0.25, 0.55, 0.85]) // Azul técnico robótico
    difference() {
        // 1. SÓLIDO EXTERIOR PRINCIPAL + CUNAS ToF
        union() {
            // Cuerpo aerodinámico con chaflanes y frente estilizado
            hull() {
                // Base inferior
                translate([10, 10, 0]) cylinder(r=10, h=5);
                translate([10, W_cuerpo - 10, 0]) cylinder(r=10, h=5);
                translate([140, 10, 0]) cylinder(r=10, h=5);
                translate([140, W_cuerpo - 10, 0]) cylinder(r=10, h=5);
                translate([L_cuerpo - 15, W_cuerpo / 2, 0]) cylinder(r=15, h=5);
                
                // Techo superior
                translate([12, 12, H_cuerpo - 4]) cylinder(r=8, h=4);
                translate([12, W_cuerpo - 12, H_cuerpo - 4]) cylinder(r=8, h=4);
                translate([138, 12, H_cuerpo - 4]) cylinder(r=8, h=4);
                translate([138, W_cuerpo - 12, H_cuerpo - 4]) cylinder(r=8, h=4);
                translate([L_cuerpo - 18, W_cuerpo / 2, H_cuerpo - 4]) cylinder(r=12, h=4);
            }
            
            // Cuna ToF Izquierda (Positivo integrado a la pared)
            translate([L_cuerpo - 22.0, W_cuerpo/2 - 26.0, z_tof])
                rotate([0, 0, -20])
                cuna_tof_positivo();
                
            // Cuna ToF Derecha (Positivo integrado a la pared)
            translate([L_cuerpo - 22.0, W_cuerpo/2 + 26.0, z_tof])
                rotate([0, 0, 20])
                cuna_tof_positivo();
        }
        
        // 2. VACIADO INTERIOR (Cavidad para electrónica y baterías)
        translate([0, 0, -1])
        hull() {
            translate([10 + t_pared, 10 + t_pared, 0]) cylinder(r=10 - t_pared, h=H_cuerpo - t_pared);
            translate([10 + t_pared, W_cuerpo - 10 - t_pared, 0]) cylinder(r=10 - t_pared, h=H_cuerpo - t_pared);
            translate([140 - t_pared, 10 + t_pared, 0]) cylinder(r=10 - t_pared, h=H_cuerpo - t_pared);
            translate([140 - t_pared, W_cuerpo - 10 - t_pared, 0]) cylinder(r=10 - t_pared, h=H_cuerpo - t_pared);
            translate([L_cuerpo - 15 - t_pared, W_cuerpo / 2, 0]) cylinder(r=15 - t_pared, h=H_cuerpo - t_pared);
        }
        
        // 3. PASARUEDAS LATERALES (Cilindros de radio 38 mm)
        // Rueda Izquierda
        translate([x_eje_motriz, -5, 15])
            rotate([-90, 0, 0])
            cylinder(r=r_arco_rueda, h=w_arco_rueda);
            
        // Rueda Derecha
        translate([x_eje_motriz, W_cuerpo - w_arco_rueda + 5, 15])
            rotate([-90, 0, 0])
            cylinder(r=r_arco_rueda, h=w_arco_rueda);
            
        // 4. VACIADOS FUNCIONALES DE LOS SENSORES ToF (Troneras, Asientos, Fijaciones)
        // Sensor ToF Izquierdo (-20° yaw)
        translate([L_cuerpo - 22.0, W_cuerpo/2 - 26.0, z_tof])
            rotate([0, 0, -20])
            cuna_tof_negativo();
            
        // Sensor ToF Derecho (+20° yaw)
        translate([L_cuerpo - 22.0, W_cuerpo/2 + 26.0, z_tof])
            rotate([0, 0, 20])
            cuna_tof_negativo();
            
        // 5. APERTURAS SUPERIORES PARA ANCLAJE DEL PLATO (4x M3)
        translate([x_centro_plato - 45, W_cuerpo/2 - 35, H_cuerpo - 10]) cylinder(d=3.4, h=15);
        translate([x_centro_plato - 45, W_cuerpo/2 + 35, H_cuerpo - 10]) cylinder(d=3.4, h=15);
        translate([x_centro_plato + 45, W_cuerpo/2 - 35, H_cuerpo - 10]) cylinder(d=3.4, h=15);
        translate([x_centro_plato + 45, W_cuerpo/2 + 35, H_cuerpo - 10]) cylinder(d=3.4, h=15);
        
        // 6. REJILLAS DE VENTILACIÓN TRASERAS Y SUPERIORES
        for (i = [-3:3]) {
            translate([35 + i * 8, W_cuerpo/2, H_cuerpo - 5])
                cube([3.5, 40, 10], center=true);
        }
    }
    
    // TORRETAS INTERIORES DE FIJACIÓN A LA BASE ACRÍLICA (4x M3)
    difference() {
        union() {
            translate([15, 12, 0]) cylinder(d=8, h=15);
            translate([15, W_cuerpo - 12, 0]) cylinder(d=8, h=15);
            translate([145, 12, 0]) cylinder(d=8, h=15);
            translate([145, W_cuerpo - 12, 0]) cylinder(d=8, h=15);
        }
        translate([15, 12, -1]) cylinder(d=2.8, h=17);
        translate([15, W_cuerpo - 12, -1]) cylinder(d=2.8, h=17);
        translate([145, 12, -1]) cylinder(d=2.8, h=17);
        translate([145, W_cuerpo - 12, -1]) cylinder(d=2.8, h=17);
    }
}

carcasa_externa_2wd();
