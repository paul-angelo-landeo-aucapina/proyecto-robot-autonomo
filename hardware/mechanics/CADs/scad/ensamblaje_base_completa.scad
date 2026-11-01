// ==============================================================================
// ROBOT SUMOSO - ENSAMBLAJE PARAMÉTRICO COMPLETO DE LA BASE (3D CAD)
// Incluye: Placa Base PC 6mm, Rieles Al 6061-T6, Brackets 3D, Motores 37D,
// Ruedas d=80mm, Casters Z=0, Cuñas ToF, Standoffs M3 y Placa Intermedia PC 3mm
// ==============================================================================

$fn = 48;

/* [Configuración de Visualización del Ensamble] */
// Selecciona qué nivel de ensamble deseas ver en pantalla:
modo_vista = "completo"; // [completo: Todo con Carrocería Hermética, sin_tapa: Sin Tapa (Electrónica Visible), solo_base: Solo Base Rodante Desnuda, transparente: Carcasa Translúcida de Inspección]
// Mostrar plano de suelo Z=0 para verificar apoyo de ruedas
mostrar_suelo = true;

// Cota de elevación de la base respecto al suelo Z=0
// Rueda radio Rw = 40 mm, eje motor a 24.0 mm de la cara superior de la base
// Suelo Z = 0 -> Despeje libre al suelo = 10.0 mm -> Cara superior base Z = 16.0 mm
z_base_inf = 10.0; // Despeje libre al suelo (Ground Clearance)
t_base_pc = 6.0;
z_base_sup = z_base_inf + t_base_pc; // 16.0 mm
z_shaft = 40.0; // Eje de ruedas motrices y omni a 40 mm de altura coplanar

// 1. PLACA BASE DE POLICARBONATO (400 x 300 x 6.0 mm) CON 4 RANURAS DE RUEDAS
module placa_base_pc() {
    color([0.85, 0.92, 0.98, 0.45]) // Policarbonato transparente/ahumado
    translate([0, 0, z_base_inf])
    difference() {
        // Placa exterior con filetes R=12 mm
        hull() {
            translate([12, 12, 0]) cylinder(r = 12, h = t_base_pc);
            translate([400 - 12, 12, 0]) cylinder(r = 12, h = t_base_pc);
            translate([400 - 12, 300 - 12, 0]) cylinder(r = 12, h = t_base_pc);
            translate([12, 300 - 12, 0]) cylinder(r = 12, h = t_base_pc);
        }
        
        // 4 Vaciados perimetrales simétricos (80 x 40 mm con filetes R=12 mm)
        // 1. Rueda trasera izquierda (X: 30 a 110 mm, Y: 0 a 40 mm)
        hull() {
            translate([30 + 12, 40 - 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([110 - 12, 40 - 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([30 - 5, -5, -1]) cube([85, 10, t_base_pc + 2]);
        }
        // 2. Rueda trasera derecha (X: 30 a 110 mm, Y: 260 a 300 mm)
        hull() {
            translate([30 + 12, 260 + 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([110 - 12, 260 + 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([30 - 5, 295, -1]) cube([85, 10, t_base_pc + 2]);
        }
        // 3. Rueda delantera izquierda / Omni (X: 290 a 370 mm, Y: 0 a 40 mm)
        hull() {
            translate([290 + 12, 40 - 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([370 - 12, 40 - 12, -1]) cylinder(r = 12, h = t_base_pc + 2);
            translate([290 - 5, -5, -1]) cube([85, 10, t_base_pc + 2]);
        }
        // 4. Rueda delantera derecha / Omni (X: 290 a 370 mm, Y: 260 a 300 mm)
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

// 2. RIELES TUBULARES DE ALUMINIO 6061-T6 (15 x 15 x 1.5 mm, Largo 320 mm)
module rieles_aluminio() {
    color([0.80, 0.82, 0.85, 1.0]) // Aluminio anodizado satinado
    for (y_pos = [55.0, 245.0]) {
        translate([40.0, y_pos - 7.5, z_base_sup])
        difference() {
            cube([320.0, 15.0, 15.0]);
            // Hueco tubular interior 12 x 12 mm
            translate([-1, 1.5, 1.5])
            cube([322.0, 12.0, 12.0]);
        }
    }
}

// 3. BRACKETS EN L PARA MOTOR 37D CON NERVADURAS GUSSET (EJE EN X = 70.0 mm)
module brackets_motores() {
    color([0.15, 0.15, 0.16, 1.0]) // PETG Negro de alta resistencia
    {
        // Bracket motor izquierdo (X = 70 mm, cara hacia Y = 40 mm)
        translate([70 - 22, 40 + 5, z_base_sup])
        rotate([0, 0, 90])
        import("bracket_motor_37d.stl");
        
        // Bracket motor derecho (X = 70 mm, cara hacia Y = 260 mm)
        translate([70 + 22, 260 - 5, z_base_sup])
        rotate([0, 0, -90])
        import("bracket_motor_37d.stl");
    }
}

// 4. MOTORES DC 37D Y RUEDAS MOTRICES TRASERAS (Eje X = 70.0 mm)
module motores_y_ruedas() {
    x_mot = 70.0;
    
    // --- Lado Izquierdo ---
    color([0.75, 0.75, 0.78, 1.0]) // Cuerpo metálico 37D
    translate([x_mot, 45, z_shaft])
    rotate([-90, 0, 0])
    cylinder(d = 37.0, h = 65.0);
    
    color([0.9, 0.8, 0.4, 1.0]) // Eje motor
    translate([x_mot, 45, z_shaft])
    rotate([90, 0, 0])
    cylinder(d = 6.0, h = 25.0);
    
    // Rueda motriz izquierda (d=80mm x ancho 30mm en Y=20mm, contacto Z=0)
    translate([x_mot, 35, z_shaft])
    rotate([90, 0, 0]) {
        color([0.3, 0.3, 0.35, 1.0]) cylinder(d = 66.0, h = 30.0);
        color([0.05, 0.05, 0.05, 1.0])
        difference() {
            cylinder(d = 80.0, h = 30.0);
            translate([0, 0, -1]) cylinder(d = 66.0, h = 32.0);
        }
    }
    
    // --- Lado Derecho ---
    color([0.75, 0.75, 0.78, 1.0])
    translate([x_mot, 255, z_shaft])
    rotate([90, 0, 0])
    cylinder(d = 37.0, h = 65.0);
    
    color([0.9, 0.8, 0.4, 1.0])
    translate([x_mot, 255, z_shaft])
    rotate([-90, 0, 0])
    cylinder(d = 6.0, h = 25.0);
    
    // Rueda motriz derecha (d=80mm, centro en Y=280mm, contacto Z=0)
    translate([x_mot, 265, z_shaft])
    rotate([-90, 0, 0]) {
        color([0.3, 0.3, 0.35, 1.0]) cylinder(d = 66.0, h = 30.0);
        color([0.05, 0.05, 0.05, 1.0])
        difference() {
            cylinder(d = 80.0, h = 30.0);
            translate([0, 0, -1]) cylinder(d = 66.0, h = 32.0);
        }
    }
}

// 5. RUEDAS OMNIDIRECCIONALES FRONTALES (Eje X = 330.0 mm, d=75 mm)
module ruedas_omniwheels_frontales() {
    x_omni = 330.0;
    
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

// 6. MATRIZ FRONTAL DE 4 SENSORES ToF (+11.59° Pitch-Up, 100% ENRASADOS AL INTERIOR)
module cunas_sensores_tof() {
    color([0.15, 0.15, 0.16, 1.0])
    for (yt = [25.0, 108.3, 191.7, 275.0]) {
        translate([372.5, yt - 12.0, z_base_sup])
        import("tof_sensor_wedge.stl");
    }
}

// 7. SEPARADORES M3 HEXAGONALES DE LATÓN (Altura 44.0 mm)
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

// 8. PLACA INTERMEDIA DE ELECTRÓNICA Y RUTEO DE ARNES (320 x 210 x 3.0 mm en Z = 60.0 mm)
module placa_intermedia_pc() {
    z_inter = z_base_sup + 44.0; // 60.0 mm (sobre separadores M3 de latón)
    
    // 8.1 Placa de Policarbonato Compacto 3.0 mm con Pasacables y Taladros CNC
    color([0.85, 0.92, 0.98, 0.45]) // PC Translúcido técnico
    translate([60.0, 45.0, z_inter])
    difference() {
        // Contorno exterior 320 x 210 mm con esquinas redondeadas R=10 mm
        hull() {
            translate([10, 10, 0]) cylinder(r = 10, h = 3.0);
            translate([320 - 10, 10, 0]) cylinder(r = 10, h = 3.0);
            translate([320 - 10, 210 - 10, 0]) cylinder(r = 10, h = 3.0);
            translate([10, 210 - 10, 0]) cylinder(r = 10, h = 3.0);
        }
        
        // --- A. 8x Barrenos Pasantes para Separadores M3 (diam 3.4 mm) ---
        for (pt = [[15, 10], [305, 10], [15, 200], [305, 200],
                   [120, 30], [200, 30], [120, 180], [200, 180]]) {
            translate([pt[0], pt[1], -1])
            cylinder(d = 3.4, h = 5.0);
        }
        
        // --- B. 4x Barrenos Pasantes para Patas del Puente de Balanza M3 (paso 180x180 mm) ---
        for (pt = [[70, 15], [250, 15], [70, 195], [250, 195]]) {
            translate([pt[0], pt[1], -1])
            cylinder(d = 3.4, h = 5.0);
        }
        
        // --- C. 4x Barrenos Pasantes para Driver Dual VNH5019 M3 (57 x 32 mm) ---
        for (dx = [-28.5, 28.5]) {
            for (dy = [-16.0, 16.0]) {
                translate([80 + dx, 105 + dy, -1])
                cylinder(d = 3.2, h = 5.0);
            }
        }
        
        // --- D. 8x Barrenos Pasantes para ESP32 y ESP32-S3 M2.5 (44 x 24 mm) ---
        for (yc = [65.0, 145.0]) {
            for (dx = [-22.0, 22.0]) {
                for (dy = [-12.0, 12.0]) {
                    translate([230 + dx, yc + dy, -1])
                    cylinder(d = 2.8, h = 5.0);
                }
            }
        }
        
        // --- E. Pasacables Laterales para Potencia de Motores 12V (AWG 18) ---
        // Izquierdo: centro en (35, 15), ranura oblonga 35 x 12 mm con R=4 mm
        hull() {
            translate([35 - 13.5, 15, -1]) cylinder(r = 4.0, h = 5.0);
            translate([35 + 13.5, 15, -1]) cylinder(r = 4.0, h = 5.0);
        }
        // Derecho: centro en (35, 195), ranura oblonga 35 x 12 mm con R=4 mm
        hull() {
            translate([35 - 13.5, 195, -1]) cylinder(r = 4.0, h = 5.0);
            translate([35 + 13.5, 195, -1]) cylinder(r = 4.0, h = 5.0);
        }
        
        // 4x Ranuras para Bridas de Motor (Zip-Ties 4.0 x 1.6 mm)
        for (xb = [18, 52]) {
            translate([xb - 2.0, 15 - 0.8, -1]) cube([4.0, 1.6, 5.0]);
            translate([xb - 2.0, 195 - 0.8, -1]) cube([4.0, 1.6, 5.0]);
        }
        
        // --- F. 4x Ranuras para Correas de Velcro de Batería 3S (25.0 x 4.5 mm) ---
        for (xb = [115.0, 205.0]) {
            for (yb = [78.0, 132.0]) {
                hull() {
                    translate([xb - 10.5, yb, -1]) cylinder(r = 2.0, h = 5.0);
                    translate([xb + 10.5, yb, -1]) cylinder(r = 2.0, h = 5.0);
                }
            }
        }
        
        // --- G. Pasacables Central-Frontal para Periféricos y ToF (45 x 14 mm, R=5 mm) ---
        hull() {
            translate([290 - 17.5, 105, -1]) cylinder(r = 5.0, h = 5.0);
            translate([290 + 17.5, 105, -1]) cylinder(r = 5.0, h = 5.0);
        }
        // 4x Ranuras de Bridas Frontales (Zip-Ties 4.0 x 1.6 mm)
        for (dy = [-18, 18]) {
            translate([268 - 2.0, 105 + dy - 0.8, -1]) cube([4.0, 1.6, 5.0]);
            translate([312 - 2.0, 105 + dy - 0.8, -1]) cube([4.0, 1.6, 5.0]);
        }
        
        // --- H. Pasacables Apantallado para Celda de Carga / ADC (20 x 10 mm, R=3.5 mm) ---
        hull() {
            translate([160 - 6.5, 70, -1]) cylinder(r = 3.5, h = 5.0);
            translate([160 + 6.5, 70, -1]) cylinder(r = 3.5, h = 5.0);
        }
    }
    
    // 8.2 Virolas de Goma Protectoras (Grommets de Neopreno en Pasacables)
    color([0.15, 0.15, 0.15, 1.0]) {
        // Virolas de motor izquierda y derecha
        for (y_pos = [60.0, 240.0]) {
            translate([95.0, y_pos, z_inter - 0.5])
            difference() {
                hull() {
                    translate([-15, 0, 0]) cylinder(r = 6.0, h = 4.0);
                    translate([15, 0, 0]) cylinder(r = 6.0, h = 4.0);
                }
                translate([0, 0, -1])
                hull() {
                    translate([-13.5, 0, 0]) cylinder(r = 4.0, h = 6.0);
                    translate([13.5, 0, 0]) cylinder(r = 4.0, h = 6.0);
                }
            }
        }
        // Virola pasacables frontal
        translate([350.0, 150.0, z_inter - 0.5])
        difference() {
            hull() {
                translate([-19, 0, 0]) cylinder(r = 7.0, h = 4.0);
                translate([19, 0, 0]) cylinder(r = 7.0, h = 4.0);
            }
            translate([0, 0, -1])
            hull() {
                translate([-17.5, 0, 0]) cylinder(r = 5.0, h = 6.0);
                translate([17.5, 0, 0]) cylinder(r = 5.0, h = 6.0);
            }
        }
    }
    
    // 8.3 Componentes Electrónicos de Referencia:
    // Batería 3S LiPo 2200mAh en el CoM (X=220, Y=150)
    color([0.1, 0.35, 0.75, 0.95]) // Pack azul LiPo
    translate([220 - 67.5, 150 - 22.0, z_inter + 3.0])
    cube([135.0, 44.0, 25.0]);
    
    // 2x Correas de Velcro Negras asegurando la batería
    color([0.08, 0.08, 0.08, 1.0]) {
        for (xb = [175.0, 265.0]) {
            translate([xb - 10.0, 150 - 23.0, z_inter + 2.5])
            difference() {
                cube([20.0, 46.0, 27.0]);
                translate([-1, 2.0, -1]) cube([22.0, 42.0, 26.0]);
            }
        }
    }
    
    // Driver Dual VNH5019 en X=140, Y=150
    color([0.8, 0.1, 0.1, 1.0]) // PCB roja
    translate([140 - 32.5, 150 - 20.0, z_inter + 3.0]) {
        cube([65.0, 40.0, 2.0]);
        // Disipadores de aluminio
        color([0.2, 0.2, 0.2, 1.0])
        translate([15, 10, 2.0]) cube([35.0, 20.0, 12.0]);
    }
    
    // Controladores ESP32 y ESP32-S3 en X=290
    color([0.1, 0.1, 0.1, 1.0]) {
        translate([290 - 25.0, 110 - 14.0, z_inter + 3.0]) cube([50.0, 28.0, 4.0]);
        translate([290 - 25.0, 190 - 14.0, z_inter + 3.0]) cube([50.0, 28.0, 4.0]);
    }

    // 8.4 Ruteo Tridimensional del Arnés Eléctrico Normalizado:
    // Líneas de Potencia 12V Motores (Rojo + Negro AWG 18)
    color([0.85, 0.1, 0.1, 1.0]) { // Rojo +12V
        // Driver a Pasacables Izquierdo
        translate([130, 140, z_inter + 4.0]) rotate([0, 0, 140]) cube([95, 2.0, 2.0]);
        // Driver a Pasacables Derecho
        translate([130, 160, z_inter + 4.0]) rotate([0, 0, -140]) cube([95, 2.0, 2.0]);
    }
    color([0.1, 0.1, 0.1, 1.0]) { // Negro GND Potencia
        translate([128, 138, z_inter + 4.0]) rotate([0, 0, 140]) cube([95, 2.0, 2.0]);
        translate([128, 162, z_inter + 4.0]) rotate([0, 0, -140]) cube([95, 2.0, 2.0]);
    }
    // Bajada vertical de cables de potencia a través de los pasacables hacia los motores
    color([0.85, 0.1, 0.1, 1.0]) {
        translate([94.0, 60.0, z_base_sup + 8.0]) cylinder(d = 2.2, h = 48.0);
        translate([94.0, 240.0, z_base_sup + 8.0]) cylinder(d = 2.2, h = 48.0);
    }
    color([0.1, 0.1, 0.1, 1.0]) {
        translate([96.0, 60.0, z_base_sup + 8.0]) cylinder(d = 2.2, h = 48.0);
        translate([96.0, 240.0, z_base_sup + 8.0]) cylinder(d = 2.2, h = 48.0);
    }

    // Mazo Central de Señal y Buses I2C/I2S (Cian + Verde AWG 24)
    color([0.0, 0.75, 0.95, 1.0]) { // Bus I2C / I2S Datos
        translate([315.0, 148.0, z_inter + 4.0]) cube([35.0, 1.8, 1.8]);
        translate([350.0, 148.0, z_base_sup + 10.0]) cylinder(d = 3.5, h = 46.0);
    }
    color([0.95, 0.65, 0.1, 1.0]) { // Alimentación Lógica 5V / 3.3V
        translate([315.0, 152.0, z_inter + 4.0]) cube([35.0, 1.8, 1.8]);
        translate([350.0, 152.0, z_base_sup + 10.0]) cylinder(d = 3.0, h = 46.0);
    }
}

// 9. MECANISMO DE PESAJE SUPERIOR (PUENTE ESTRUCTURAL + CELDA 5kg + BANDEJA FLOTANTE)
module mecanismo_pesaje_superior() {
    z_inter_sup = z_base_sup + 44.0 + 3.0; // 54.5 mm (cara superior placa intermedia)
    
    translate([220.0, 150.0, z_inter_sup]) {
        // Puente Estructural PETG (4 apoyos a 180x180 mm)
        color([0.22, 0.22, 0.25, 1.0])
        import("puente_celda_carga.stl");
        
        // Celda de Carga Dummy 5 kg (YZC-133 / TAL220 en Aluminio)
        color([0.85, 0.85, 0.88, 1.0])
        translate([0, 0, 32.0 + 10.0]) {
            difference() {
                translate([-40.0, -6.35, 0]) cube([80.0, 12.7, 12.7]);
                // Vaciados del paralelogramo deformable
                translate([-10.0, 0, -1]) cylinder(d = 10.7, h = 14.7);
                translate([10.0, 0, -1]) cylinder(d = 10.7, h = 14.7);
                translate([-10.0, -5.35, -1]) cube([20.0, 10.7, 14.7]);
            }
        }
        
        // Soporte Cantilever PETG de la Bandeja Flotante
        color([0.15, 0.35, 0.65, 1.0])
        translate([0, 0, 32.0 + 10.0 + 12.7])
        import("soporte_bandeja_flotante.stl");
        
        // 4x Pernos de Tope de Sobrecarga M3 con Contratuerca (dx=+-60, dy=+-60)
        color([0.88, 0.75, 0.30, 1.0]) {
            for (dx = [-60.0, 60.0]) {
                for (dy = [-60.0, 60.0]) {
                    // Perno roscado regulado a 0.50 mm bajo la bandeja flotante
                    translate([dx, dy, 32.0 + 6.0])
                    cylinder(d = 3.0, h = 28.2);
                    // Tuerca hexagonal M3
                    translate([dx, dy, 32.0 + 6.0 + 15.0])
                    cylinder(d = 6.0, h = 2.4, $fn = 6);
                }
            }
        }
        
        // Bandeja Superior Flotante de Carga (PC 3.0 mm, 200 x 160 mm)
        // Elevación Z = 32.0 + 10.0 + 12.7 + 12.0 = 66.7 mm sobre placa intermedia
        color([0.85, 0.92, 0.98, 0.50]) // Policarbonato transparente
        translate([-100.0, -80.0, 32.0 + 10.0 + 12.7 + 12.0])
        difference() {
            // Bandeja con bordes redondeados R=8 mm
            hull() {
                translate([8, 8, 0]) cylinder(r = 8, h = 3.0);
                translate([200 - 8, 8, 0]) cylinder(r = 8, h = 3.0);
                translate([200 - 8, 160 - 8, 0]) cylinder(r = 8, h = 3.0);
                translate([8, 160 - 8, 0]) cylinder(r = 8, h = 3.0);
            }
            // 4x Barrenos de fijación al soporte en T (X = 35 local al soporte)
            for (dy = [-40.0, -15.0, 15.0, 40.0]) {
                translate([100.0 + 35.0, 80.0 + dy, -1])
                cylinder(d = 3.2, h = 5.0);
            }
        }
    }
}

// ------------------------------------------------------------------------------
// 10. CARCASA ESTRUCTURAL EXTERIOR Y CERRAMIENTO SUPERIOR DESMONTABLE
// ------------------------------------------------------------------------------
use <carroceria_cerramiento_superior.scad>;

module cerramiento_carroceria_exterior(ver_faldon = true, ver_tapa = true) {
    if (ver_faldon) {
        faldon_perimetral_base();
    }
    if (ver_tapa) {
        tapa_enteriza_desmontable();
    }
}

// ------------------------------------------------------------------------------
// 11. OJOS ROBÓTICOS SH1106 (DISPLAYS OLED 1.3" CON PUPILAS CIRCULARES ACTIVAS)
// ------------------------------------------------------------------------------
module displays_oled_ojos_sh1106() {
    for (ye = [100.0, 200.0]) {
        // PCB del módulo SH1106 (35.4 x 33.5 mm)
        color([0.10, 0.15, 0.35, 1.0])
        translate([400.0 - 5.5, ye - 17.7, 83.5 - 16.7])
        cube([1.6, 35.4, 33.5]);

        // Marco y vidrio del OLED (negro brillante, 34.5 x 23.0 mm)
        color([0.05, 0.05, 0.05, 1.0])
        translate([400.0 - 3.9, ye - 17.25, 83.5 - 11.5])
        cube([1.4, 34.5, 23.0]);

        // Matriz activa con pupila circular animada (Cyan brillante luminiscente)
        color([0.0, 0.85, 1.0, 1.0])
        translate([400.0 - 2.4, ye, 83.5])
        rotate([0, 90, 0])
        cylinder(d = 14.0, h = 0.5);

        // Brillo especular de la pupila (blanco)
        color([1.0, 1.0, 1.0, 1.0])
        translate([400.0 - 1.8, ye - 2.5, 83.5 + 2.5])
        rotate([0, 90, 0])
        cylinder(d = 4.0, h = 0.5);
    }
}

// ------------------------------------------------------------------------------
// 12. MÓDULO DE AUDIO FRONTAL: MICRÓFONO MEMS INMP441 Y PARLANTE 3W
// ------------------------------------------------------------------------------
module modulo_audio_frontal() {
    // 12.1 Micrófono MEMS I2S INMP441 (centrado en X=400, Y=150, Z=83.5)
    // PCB 14 x 14 mm
    color([0.15, 0.15, 0.15, 1.0])
    translate([400.0 - 4.5, 150.0 - 7.0, 83.5 - 7.0])
    cube([1.2, 14.0, 14.0]);
    // Puerto acústico metálico dorado MEMS
    color([0.85, 0.75, 0.30, 1.0])
    translate([400.0 - 3.3, 150.0, 83.5])
    rotate([0, 90, 0])
    cylinder(d = 2.0, h = 1.0);

    // 12.2 Parlante Dinámico 3W (centrado en X=400, Y=150, Z=56.5)
    // Marco exterior metálico negro (32 x 32 x 10 mm)
    color([0.1, 0.1, 0.1, 1.0])
    translate([400.0 - 10.0, 150.0 - 15.0, 56.5 - 15.0])
    cube([8.0, 30.0, 30.0]);
    // Cono acústico de polipropileno plateado
    color([0.7, 0.7, 0.75, 1.0])
    translate([400.0 - 3.5, 150.0, 56.5])
    rotate([0, 90, 0])
    cylinder(d1 = 12.0, d2 = 24.0, h = 2.0);
    // Domo central guardapolvo
    color([0.05, 0.05, 0.05, 1.0])
    translate([400.0 - 2.5, 150.0, 56.5])
    rotate([0, 90, 0])
    cylinder(d = 8.0, h = 0.8);
}

// ------------------------------------------------------------------------------
// SUELO DE REFERENCIA (Z = 0)
// ------------------------------------------------------------------------------
module plano_suelo() {
    color([0.2, 0.22, 0.25, 0.20])
    translate([-30, -30, -0.2])
    cube([460, 360, 0.2]);
}

// ------------------------------------------------------------------------------
// CONTROL DE VISIBILIDAD Y ENSAMBLAJE TOTAL
// ------------------------------------------------------------------------------
mostrar_carcasa_faldon = (modo_vista == "completo" || modo_vista == "sin_tapa" || modo_vista == "transparente");
mostrar_carcasa_tapa   = (modo_vista == "completo");
mostrar_perifericos    = (modo_vista != "solo_base");

// 1. Suelo de referencia
if (mostrar_suelo) {
    plano_suelo();
}

// 2. Base mecánica motriz
placa_base_pc();
rieles_aluminio();
brackets_motores();
motores_y_ruedas();
ruedas_omniwheels_frontales();
cunas_sensores_tof();
standoffs_laton();
placa_intermedia_pc();
mecanismo_pesaje_superior();

// 3. Periféricos frontales integrados (Displays OLED, Micrófono y Parlante)
if (mostrar_perifericos) {
    displays_oled_ojos_sh1106();
    modulo_audio_frontal();
}

// 4. Carcasa estructural exterior
if (modo_vista == "transparente") {
    %cerramiento_carroceria_exterior(true, true);
} else {
    cerramiento_carroceria_exterior(mostrar_carcasa_faldon, mostrar_carcasa_tapa);
}




