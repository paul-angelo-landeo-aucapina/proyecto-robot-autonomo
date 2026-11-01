// ==============================================================================
// ROBOT SUMOSO - ENSAMBLAJE DE BASE MECÁNICA RODANTE (CHASIS DESNUDO)
// Arquitectura Asistencial y de Transporte (Opción D: 2WD 37D + 2 Omniwheels)
// Archivo independiente 100% libre de carrocería, faldón ni tapas.
// Muestra exclusivamente la base motriz, suspensión, rieles, brackets y rodadura.
// ==============================================================================

$fn = 48;

/* [Configuración de Visualización de Base] */
// Mostrar suelo de referencia Z=0
mostrar_plano_suelo = true;
// Mostrar placa intermedia de electrónica
mostrar_placa_intermedia = true;
// Mostrar componentes sobre la placa intermedia
mostrar_componentes_intermedios = false;

// ------------------------------------------------------------------------------
// PARÁMETROS GEOMÉTRICOS Y FÍSICOS
// ------------------------------------------------------------------------------
// Suelo Z = 0
// Eje de ruedas motrices y omnidireccionales en Z = 40.0 mm
// Radio de ruedas Rw = 40.0 mm (Diámetro nominal d = 80.0 mm)
// Contacto exacto con el suelo en Z = 40.0 - 40.0 = 0.0 mm
z_shaft = 40.0;
d_rueda = 80.0;
r_rueda = d_rueda / 2; // 40.0 mm

// Placa Base de Policarbonato
t_base_pc = 6.0;
z_base_inf = 10.0; // Despeje libre al suelo = 10.0 mm (Ground Clearance)
z_base_sup = z_base_inf + t_base_pc; // 16.0 mm

// Rieles de Aluminio 6061-T6
y_riel_der = 55.0;
y_riel_izq = 245.0;

// Ejes longitudinales
x_mot = 70.0;   // Eje de tracción trasero
x_omni = 330.0; // Eje de dirección delantero
l_wheelbase = x_omni - x_mot; // 260.0 mm
w_track = 260.0; // Ancho de vía entre ruedas motrices

// ------------------------------------------------------------------------------
// 1. PLACA BASE DE POLICARBONATO (400 x 300 x 6.0 mm) CON 4 VACIADOS DE RUEDAS
// ------------------------------------------------------------------------------
module placa_base_pc() {
    color([0.85, 0.92, 0.98, 0.50]) // Policarbonato transparente técnico
    translate([0, 0, z_base_inf])
    difference() {
        // Placa exterior con filetes R=12 mm
        hull() {
            translate([12, 12, 0]) cylinder(r = 12, h = t_base_pc);
            translate([400 - 12, 12, 0]) cylinder(r = 12, h = t_base_pc);
            translate([400 - 12, 300 - 12, 0]) cylinder(r = 12, h = t_base_pc);
            translate([12, 300 - 12, 0]) cylinder(r = 12, h = t_base_pc);
        }
        
        // 4 Vaciados perimetrales simétricos (80 x 40 mm con filetes anti-entalla R=12 mm)
        // 1. Rueda trasera derecha (X: 30 a 110 mm, Y: 0 a 40 mm)
        hull() {
            translate([30 + 12, 40 - 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([110 - 12, 40 - 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([30 - 5, -5, -1]) cube([85, 10, t_base_pc + 2]);
        }
        // 2. Rueda trasera izquierda (X: 30 a 110 mm, Y: 260 a 300 mm)
        hull() {
            translate([30 + 12, 260 + 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([110 - 12, 260 + 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([30 - 5, 295, -1]) cube([85, 10, t_base_pc + 2]);
        }
        // 3. Rueda omni delantera derecha (X: 290 a 370 mm, Y: 0 a 40 mm)
        hull() {
            translate([290 + 12, 40 - 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([370 - 12, 40 - 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([290 - 5, -5, -1]) cube([85, 10, t_base_pc + 2]);
        }
        // 4. Rueda omni delantera izquierda (X: 290 a 370 mm, Y: 260 a 300 mm)
        hull() {
            translate([290 + 12, 260 + 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([370 - 12, 260 + 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([290 - 5, 295, -1]) cube([85, 10, t_base_pc + 2]);
        }
        
        // Vaciado central de alivio de masa bajo batería (120 x 70 mm)
        translate([220 - 60, 150 - 35, -1])
        hull() {
            translate([10, 10, 0]) cylinder(r = 10, h = t_base_pc + 2);
            translate([110, 10, 0]) cylinder(r = 10, h = t_base_pc + 2);
            translate([110, 60, 0]) cylinder(r = 10, h = t_base_pc + 2);
            translate([10, 60, 0]) cylinder(r = 10, h = t_base_pc + 2);
        }
    }
}

// ------------------------------------------------------------------------------
// 2. RIELES TUBULARES DE ALUMINIO 6061-T6 (15 x 15 x 1.5 mm, Largo 320 mm)
// ------------------------------------------------------------------------------
module rieles_aluminio() {
    color([0.80, 0.82, 0.85, 1.0]) // Aluminio anodizado satinado
    for (y_pos = [y_riel_der, y_riel_izq]) {
        translate([40.0, y_pos - 7.5, z_base_sup])
        difference() {
            cube([320.0, 15.0, 15.0]);
            translate([-1, 1.5, 1.5])
            cube([322.0, 12.0, 12.0]);
        }
    }
}

// ------------------------------------------------------------------------------
// 3. BRACKETS EN L PARA MOTORES 37D (EJE EN X = 70.0 mm)
// ------------------------------------------------------------------------------
module brackets_motores() {
    color([0.15, 0.15, 0.16, 1.0]) // PETG Negro de alta resistencia
    {
        // Bracket motor derecho (X = 70 mm, cara hacia Y = 40 mm)
        translate([70 - 22, 40 + 5, z_base_sup])
        rotate([0, 0, 90])
        import("bracket_motor_37d.stl");
        
        // Bracket motor izquierdo (X = 70 mm, cara hacia Y = 260 mm)
        translate([70 + 22, 260 - 5, z_base_sup])
        rotate([0, 0, -90])
        import("bracket_motor_37d.stl");
    }
}

// ------------------------------------------------------------------------------
// 4. MOTORES DC 37D Y RUEDAS MOTRICES (d=80mm, CONTACTO EN Z=0)
// ------------------------------------------------------------------------------
module motores_y_ruedas() {
    // --- Lado Derecho ---
    color([0.75, 0.75, 0.78, 1.0]) // Cuerpo metálico 37D
    translate([x_mot, 45, z_shaft])
    rotate([-90, 0, 0])
    cylinder(d = 37.0, h = 65.0);
    
    color([0.9, 0.8, 0.4, 1.0]) // Eje motor
    translate([x_mot, 45, z_shaft])
    rotate([90, 0, 0])
    cylinder(d = 6.0, h = 25.0);
    
    // Rueda motriz derecha (d=80mm x ancho 30mm en Y=20mm, contacto Z=0)
    translate([x_mot, 35, z_shaft])
    rotate([90, 0, 0]) {
        color([0.3, 0.3, 0.35, 1.0]) cylinder(d = 66.0, h = 30.0);
        color([0.05, 0.05, 0.05, 1.0]) // Neumático de goma
        difference() {
            cylinder(d = d_rueda, h = 30.0);
            translate([0, 0, -1]) cylinder(d = 66.0, h = 32.0);
        }
    }
    
    // --- Lado Izquierdo ---
    color([0.75, 0.75, 0.78, 1.0])
    translate([x_mot, 255, z_shaft])
    rotate([90, 0, 0])
    cylinder(d = 37.0, h = 65.0);
    
    color([0.9, 0.8, 0.4, 1.0])
    translate([x_mot, 255, z_shaft])
    rotate([-90, 0, 0])
    cylinder(d = 6.0, h = 25.0);
    
    // Rueda motriz izquierda (d=80mm, centro en Y=280mm, contacto Z=0)
    translate([x_mot, 265, z_shaft])
    rotate([-90, 0, 0]) {
        color([0.3, 0.3, 0.35, 1.0]) cylinder(d = 66.0, h = 30.0);
        color([0.05, 0.05, 0.05, 1.0])
        difference() {
            cylinder(d = d_rueda, h = 30.0);
            translate([0, 0, -1]) cylinder(d = 66.0, h = 32.0);
        }
    }
}

// ------------------------------------------------------------------------------
// 5. RUEDAS OMNIDIRECCIONALES FRONTALES (Eje X = 330.0 mm, d=80 mm)
// ------------------------------------------------------------------------------
module ruedas_omniwheels_frontales() {
    for (yo = [20.0, 280.0]) {
        y_bracket_origin = (yo == 20.0) ? (40.0 + 5.0) : (260.0 - 5.0);
        rot_angle = (yo == 20.0) ? 90 : -90;
        dx_bracket = (yo == 20.0) ? -22 : 22;
        
        // Bracket horquilla 3D para Omniwheel
        color([0.18, 0.45, 0.25, 1.0]) // PETG Verde técnico
        translate([x_omni + dx_bracket, y_bracket_origin, z_base_sup])
        rotate([0, 0, rot_angle])
        import("bracket_omniwheel_65mm.stl");
        
        // Eje rectificado de acero d=6.0 mm
        color([0.88, 0.88, 0.90, 1.0])
        translate([x_omni, yo - 18.0, z_shaft])
        rotate([-90, 0, 0])
        cylinder(d = 6.0, h = 36.0);
        
        // Rueda Omniwheel doble fila con rodillos perimetrales (d=80mm, contacto Z=0)
        translate([x_omni, yo + 14.0, z_shaft])
        rotate([90, 0, 0]) {
            // Núcleo central
            color([0.25, 0.65, 0.35, 1.0])
            cylinder(d = 52.0, h = 28.0);
            
            // Rodillos de goma perimetrales (radio exterior = 40.0 mm -> d=80 mm)
            color([0.1, 0.1, 0.1, 1.0])
            for (ang = [0 : 45 : 315]) {
                rotate([0, 0, ang])
                translate([32.0, 0, 7.0])
                rotate([90, 0, 0])
                cylinder(d = 16.0, h = 10.0, center = true);
                
                rotate([0, 0, ang + 22.5])
                translate([32.0, 0, 21.0])
                rotate([90, 0, 0])
                cylinder(d = 16.0, h = 10.0, center = true);
            }
        }
    }
}

// ------------------------------------------------------------------------------
// 6. MATRIZ FRONTAL DE 4 SENSORES ToF (+11.59° Pitch-Up, 100% ENRASADOS AL INTERIOR)
// ------------------------------------------------------------------------------
module cunas_sensores_tof() {
    color([0.15, 0.15, 0.16, 1.0])
    for (yt = [25.0, 108.3, 191.7, 275.0]) {
        translate([372.5, yt - 12.0, z_base_sup])
        import("tof_sensor_wedge.stl");
    }
}

// ------------------------------------------------------------------------------
// 7. SEPARADORES M3 HEXAGONALES DE LATÓN (Altura 44.0 mm)
// ------------------------------------------------------------------------------
module standoffs_laton() {
    standoff_coords = [
        [75.0, 55.0], [365.0, 55.0], [75.0, 245.0], [365.0, 245.0],
        [180.0, 75.0], [260.0, 75.0], [180.0, 225.0], [260.0, 225.0]
    ];
    color([0.88, 0.75, 0.30, 1.0]) {
        for (pt = standoff_coords) {
            translate([pt[0], pt[1], z_base_sup])
            cylinder(d = 6.0, h = 44.0, $fn = 6); // Hexagonal M3
        }
    }
}

// ------------------------------------------------------------------------------
// 8. PLACA INTERMEDIA DE POLICARBONATO 3mm CON PASACABLES Y TALADROS CNC
// ------------------------------------------------------------------------------
module placa_intermedia_pc(con_componentes = false) {
    z_inter = z_base_sup + 44.0; // 60.0 mm
    color([0.85, 0.92, 0.98, 0.45]) // PC Translúcido 3mm
    translate([60.0, 45.0, z_inter])
    difference() {
        hull() {
            translate([10, 10, 0]) cylinder(r = 10, h = 3.0);
            translate([320 - 10, 10, 0]) cylinder(r = 10, h = 3.0);
            translate([320 - 10, 210 - 10, 0]) cylinder(r = 10, h = 3.0);
            translate([10, 210 - 10, 0]) cylinder(r = 10, h = 3.0);
        }
        
        // 8x Barrenos Pasantes para Separadores M3 (diam 3.4 mm)
        for (pt = [[15, 10], [305, 10], [15, 200], [305, 200],
                   [120, 30], [200, 30], [120, 180], [200, 180]]) {
            translate([pt[0], pt[1], -1]) cylinder(d = 3.4, h = 5.0);
        }
        
        // 4x Barrenos Pasantes para Patas del Puente de Balanza M3 (paso 180x180 mm)
        for (pt = [[70, 15], [250, 15], [70, 195], [250, 195]]) {
            translate([pt[0], pt[1], -1]) cylinder(d = 3.4, h = 5.0);
        }
        
        // 4x Barrenos Pasantes para Driver VNH5019 M3
        for (dx = [-28.5, 28.5]) {
            for (dy = [-16.0, 16.0]) {
                translate([80 + dx, 105 + dy, -1]) cylinder(d = 3.2, h = 5.0);
            }
        }
        
        // 8x Barrenos Pasantes para ESP32s
        for (yc = [65.0, 145.0]) {
            for (dx = [-22.0, 22.0]) {
                for (dy = [-12.0, 12.0]) {
                    translate([230 + dx, yc + dy, -1]) cylinder(d = 2.8, h = 5.0);
                }
            }
        }
        
        // Pasacables Laterales para Motores 12V (35 x 12 mm con R=4 mm)
        hull() {
            translate([35 - 13.5, 15, -1]) cylinder(r = 4.0, h = 5.0);
            translate([35 + 13.5, 15, -1]) cylinder(r = 4.0, h = 5.0);
        }
        hull() {
            translate([35 - 13.5, 195, -1]) cylinder(r = 4.0, h = 5.0);
            translate([35 + 13.5, 195, -1]) cylinder(r = 4.0, h = 5.0);
        }
        
        // 4x Ranuras para Bridas de Motor (Zip-Ties 4.0 x 1.6 mm)
        for (xb = [18, 52]) {
            translate([xb - 2.0, 15 - 0.8, -1]) cube([4.0, 1.6, 5.0]);
            translate([xb - 2.0, 195 - 0.8, -1]) cube([4.0, 1.6, 5.0]);
        }
        
        // 4x Ranuras para Correas de Velcro de Batería 3S (25.0 x 4.5 mm)
        for (xb = [115.0, 205.0]) {
            for (yb = [78.0, 132.0]) {
                hull() {
                    translate([xb - 10.5, yb, -1]) cylinder(r = 2.0, h = 5.0);
                    translate([xb + 10.5, yb, -1]) cylinder(r = 2.0, h = 5.0);
                }
            }
        }
        
        // Pasacables Central-Frontal para Periféricos y ToF (45 x 14 mm, R=5 mm)
        hull() {
            translate([290 - 17.5, 105, -1]) cylinder(r = 5.0, h = 5.0);
            translate([290 + 17.5, 105, -1]) cylinder(r = 5.0, h = 5.0);
        }
        // 4x Ranuras de Bridas Frontales (Zip-Ties 4.0 x 1.6 mm)
        for (dy = [-18, 18]) {
            translate([268 - 2.0, 105 + dy - 0.8, -1]) cube([4.0, 1.6, 5.0]);
            translate([312 - 2.0, 105 + dy - 0.8, -1]) cube([4.0, 1.6, 5.0]);
        }
        
        // Pasacables Celda de Carga / ADC (20 x 10 mm, R=3.5 mm)
        hull() {
            translate([160 - 6.5, 70, -1]) cylinder(r = 3.5, h = 5.0);
            translate([160 + 6.5, 70, -1]) cylinder(r = 3.5, h = 5.0);
        }
    }
    
    if (con_componentes) {
        // Batería 3S LiPo 2200mAh en CoM (X=220, Y=150)
        color([0.1, 0.35, 0.75, 0.95])
        translate([220 - 67.5, 150 - 22.0, z_inter + 3.0])
        cube([135.0, 44.0, 25.0]);
        // Driver VNH5019
        color([0.8, 0.1, 0.1, 1.0])
        translate([140 - 32.5, 150 - 20.0, z_inter + 3.0])
        cube([65.0, 40.0, 2.0]);
    }
}

// ------------------------------------------------------------------------------
// SUELO DE REFERENCIA (Z = 0)
// ------------------------------------------------------------------------------
module plano_suelo() {
    color([0.2, 0.22, 0.25, 0.20]) // Malla translúcida de suelo
    translate([-30, -30, -0.2])
    cube([460, 360, 0.2]);
}

// ------------------------------------------------------------------------------
// ENSAMBLAJE DE BASE MECÁNICA
// ------------------------------------------------------------------------------
if (mostrar_plano_suelo) {
    plano_suelo();
}

placa_base_pc();
rieles_aluminio();
brackets_motores();
motores_y_ruedas();
ruedas_omniwheels_frontales();
cunas_sensores_tof();
standoffs_laton();

if (mostrar_placa_intermedia) {
    placa_intermedia_pc(mostrar_componentes_intermedios);
}
