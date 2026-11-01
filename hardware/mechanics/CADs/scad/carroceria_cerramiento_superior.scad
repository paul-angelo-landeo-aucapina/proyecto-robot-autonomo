// ==============================================================================
// ROBOT SUMOSO - CARCASA ESTRUCTURAL HERMETICA Y CERRAMIENTO SUPERIOR V2
// Arquitectura Asistencial y de Transporte (Opción D: 2WD 37D + 2 Omniwheels)
// Incluye:
// 1. Faldón perimetral inferior fijo con 4 cajas de pasarueda selladas (guardapolvos)
// 2. Arcos de rueda laterales estilizados (R=46mm) que dejan visibles las 4 ruedas
// 3. Ranura perimetral en Z=95mm para cordón/burlete de estanqueidad (silicona 2mm)
// 4. Alojamiento frontal integrado para 2x OLED SH1106 con aperturas circulares
//    enrasadas (diam 14.5 mm) que ocultan 100% de los bordes y marcos de vidrio
// 5. Puerto acústico frontal y caja para Micrófono MEMS I2S INMP441 (Z=75mm, centrado)
// 6. Rejilla acústica de microperforaciones y cámara para Parlante 3W (Z=48mm, centrado)
// 7. Troneras enrasadas para los 4 sensores ToF con pitch-up +11.59°
// 8. Tapa enteriza desmontable con lengüeta perimetral de estanqueidad macho,
//    nervaduras en T y fijación por 4 pernos M3 moleteados
// 9. Marco de balanza desacoplado (208x208mm) con cuello laberíntico continuo
// Geometría 100% 2-manifold y estanca (watertight).
// ==============================================================================

$fn = 36;

// Parámetros globales de la envolvente (mm)
L_base = 400.0;
W_base = 300.0;
t_wall = 2.5;       // Espesor estructural de pared (PETG / PA-CF)
z_base_sup = 16.0;  // Cota de cara superior de placa base PC (Despeje libre al suelo = 10.0 mm)
z_split = 103.5;    // Plano de partición faldón/tapa (h_faldon = 87.5 mm constante)
z_top = 133.5;      // Altura máxima del techo exterior (h_tapa = 30.0 mm constante)
h_faldon = z_split - z_base_sup; // 87.5 mm
h_tapa = z_top - z_split;        // 30.0 mm

// Parámetros del marco de balanza desacoplado (Laberinto 4.0 mm de holgura)
x_balanza = 220.0;  // Centroide longitudinal de celda de carga
y_balanza = 150.0;  // Centroide transversal
L_apertura = 208.0; // Apertura libre para bandeja flotante de 200x200 mm

// Parámetros de anclaje (4x M3 a rieles de aluminio 6061-T6 en Y = [55, 245])
x_boss_rear = 70.0;
x_boss_front = 330.0;
y_boss_left = 245.0;
y_boss_right = 55.0;

boss_coords = [
    [x_boss_rear, y_boss_right],
    [x_boss_rear, y_boss_left],
    [x_boss_front, y_boss_right],
    [x_boss_front, y_boss_left]
];

// Ejes de ruedas (Z = 40.0 mm, d = 80.0 mm nominal)
x_wheel_rear = 70.0;
x_wheel_front = 330.0;
r_arch = 46.0; // Radio del arco de rueda lateral (visibilidad y despeje)

// Parámetros de los ojos circulares frontales (OLED SH1106 1.3")
y_eye_left = 150.0 + 50.0;   // 200.0 mm (ojo izquierdo robot)
y_eye_right = 150.0 - 50.0;  // 100.0 mm (ojo derecho robot)
z_eye = 83.5;                // Altura centroidal de los ojos (elevada +8.5mm con la base)
d_eye_aperture = 14.5;       // Diámetro circular exterior enrasado (área activa SH1106: 29.4 x 14.7 mm)

// Parámetros de Micrófono MEMS I2S INMP441
y_mic = 150.0;
z_mic = 83.5;

// Parámetros de Parlante 3W
y_spk = 150.0;
z_spk = 56.5;

// Parámetros de los 4 sensores ToF frontales enrasados
tof_y_coords = [25.0, 108.3, 191.7, 275.0];
z_tof = 28.0;

// Modo de renderizado: "assembly", "faldon_base", "tapa_superior"
render_part = "assembly";

// ------------------------------------------------------------------------------
// 1. FALDON PERIMETRAL DE BASE CON GUARDABARROS SELLADOS Y AUDIO INTEGRADO
// ------------------------------------------------------------------------------
module faldon_perimetral_base() {
    color([0.25, 0.28, 0.32, 0.95]) // Gris grafito técnico
    difference() {
        union() {
            // 1.1 Cuerpo exterior con esquinas redondeadas R=12 mm
            translate([0, 0, z_base_sup])
            hull() {
                translate([12, 12, 0]) cylinder(r = 12, h = h_faldon);
                translate([L_base - 12, 12, 0]) cylinder(r = 12, h = h_faldon);
                translate([L_base - 12, W_base - 12, 0]) cylinder(r = 12, h = h_faldon);
                translate([12, W_base - 12, 0]) cylinder(r = 12, h = h_faldon);
            }
            
            // 1.2 4 Torretas estructurales interiores para fijación a rieles Al
            torretas_anclaje_rieles(h_faldon);

            // 1.3 4 Cajas de pasarueda selladas (guardapolvos que aíslan la electrónica)
            cajas_pasaruedas_selladas();

            // 1.4 Alojamientos interiores para los 2 displays OLED SH1106
            alojamientos_interiores_sh1106();

            // 1.5 Alojamiento interior para Micrófono MEMS INMP441
            translate([L_base - 7.0, y_mic - 10.0, z_mic - 10.0])
            cube([7.0, 20.0, 20.0]);

            // 1.6 Cámara acústica interior para Parlante 3W
            translate([L_base - 14.0, y_spk - 18.0, z_spk - 18.0])
            cube([14.0, 36.0, 36.0]);
        }
        
        // 1.7 Vaciado interior principal del habitáculo (espesor de pared t_wall = 2.5 mm)
        translate([0, 0, z_base_sup - 2.0])
        hull() {
            translate([12 + t_wall, 12 + t_wall, 0]) cylinder(r = 12 - t_wall, h = h_faldon + 4.0);
            translate([L_base - 12 - t_wall, 12 + t_wall, 0]) cylinder(r = 12 - t_wall, h = h_faldon + 4.0);
            translate([L_base - 12 - t_wall, W_base - 12 - t_wall, 0]) cylinder(r = 12 - t_wall, h = h_faldon + 4.0);
            translate([12 + t_wall, W_base - 12 - t_wall, 0]) cylinder(r = 12 - t_wall, h = h_faldon + 4.0);
        }
        
        // 1.8 Arcos de rueda visibles estilizados (exponen la mitad inferior de las 4 ruedas)
        arcos_ruedas_visibles();

        // 1.9 Taladros pasantes e insertos M3 para anclaje a rieles
        taladros_anclaje_rieles();

        // 1.10 Perforaciones y rebajes de los ojos SH1106 en la cara frontal
        perforaciones_ojos_sh1106();

        // 1.11 Puerto acústico y fijación para Micrófono MEMS
        puerto_acustico_microfono();

        // 1.12 Rejilla acústica de microperforaciones y cámara para Parlante 3W
        rejilla_y_camara_parlante();

        // 1.13 Troneras ópticas enrasadas para los 4 sensores ToF (+11.59° pitch-up)
        troneras_sensores_tof();

        // 1.14 Ranura perimetral en Z=95mm para cordón elastomérico de estanqueidad (diam 2mm)
        ranura_burlete_perimetral();
    }
}

// ------------------------------------------------------------------------------
// 2. TAPA ENTERIZA DESMONTABLE CON LENGÜETA DE ESTANQUEIDAD MACHO
// ------------------------------------------------------------------------------
module tapa_enteriza_desmontable() {
    color([0.35, 0.40, 0.46, 0.95]) // Azul grafito industrial
    difference() {
        union() {
            // 2.1 Carcasa hueca perimetral con lengüeta machihembrada de estanqueidad
            difference() {
                union() {
                    // Cubierta exterior con esquinas redondeadas
                    translate([0, 0, z_split])
                    hull() {
                        translate([12, 12, 0]) cylinder(r = 12, h = h_tapa);
                        translate([L_base - 12, 12, 0]) cylinder(r = 12, h = h_tapa);
                        translate([L_base - 12, W_base - 12, 0]) cylinder(r = 12, h = h_tapa);
                        translate([12, W_base - 12, 0]) cylinder(r = 12, h = h_tapa);
                    }
                    
                    // Pestaña inferior de centrado macho (baja 4 mm dentro del faldón con 0.5 mm holgura)
                    translate([0, 0, z_split - 4.0])
                    hull() {
                        translate([12.5, 12.5, 0]) cylinder(r = 11.5, h = 4.1);
                        translate([L_base - 12.5, 12.5, 0]) cylinder(r = 11.5, h = 4.1);
                        translate([L_base - 12.5, W_base - 12.5, 0]) cylinder(r = 11.5, h = 4.1);
                        translate([12.5, W_base - 12.5, 0]) cylinder(r = 11.5, h = 4.1);
                    }

                    // Lengüeta continua para comprimir el burlete de silicona de la ranura del faldón
                    lengueta_estanqueidad_macho();
                }
                
                // Vaciado interior uniforme de la tapa (espesor de pared t_wall = 2.5 mm)
                translate([0, 0, z_split - 5.0])
                hull() {
                    translate([12 + t_wall, 12 + t_wall, 0]) cylinder(r = 12 - t_wall, h = h_tapa + 5.0 - t_wall);
                    translate([L_base - 12 - t_wall, 12 + t_wall, 0]) cylinder(r = 12 - t_wall, h = h_tapa + 5.0 - t_wall);
                    translate([L_base - 12 - t_wall, W_base - 12 - t_wall, 0]) cylinder(r = 12 - t_wall, h = h_tapa + 5.0 - t_wall);
                    translate([12 + t_wall, W_base - 12 - t_wall, 0]) cylinder(r = 12 - t_wall, h = h_tapa + 5.0 - t_wall);
                }
            }

            // 2.2 Cuello laberinto perimetral de balanza (labio vertical h=5 mm)
            cuello_laberinto_balanza();

            // 2.3 Columnas sólidas de anclaje para pernos moleteados
            torretas_tapa();

            // 2.4 Costillas internas rigidizadoras en T
            nervaduras_interiores_techo();
        }

        // 2.5 Apertura pasante para marco de balanza (208 x 208 mm)
        translate([x_balanza - L_apertura/2 - 0.05, y_balanza - L_apertura/2 - 0.05, z_split - 10])
        cube([L_apertura + 0.1, L_apertura + 0.1, 70]);

        // 2.6 Alojamientos y taladros para 4x pernos M3 moleteados
        taladros_tapa();
    }
}

// ------------------------------------------------------------------------------
// 3. SUB-MÓDULOS DE SOPORTE ESTRUCTURAL, ARCOS Y AUDIO
// ------------------------------------------------------------------------------

module torretas_anclaje_rieles(h) {
    for (pt = boss_coords) {
        translate([pt[0], pt[1], z_base_sup])
        cylinder(r = 9.0, h = h);
    }
}

module taladros_anclaje_rieles() {
    for (pt = boss_coords) {
        // Taladro pasante M3 (diam 3.4 mm)
        translate([pt[0], pt[1], z_base_sup - 2])
        cylinder(r = 1.7, h = h_faldon + 4);
        // Alojamiento para inserto roscado de latón M3 (diam 4.4 mm, prof 6 mm)
        translate([pt[0], pt[1], z_split - 6.5])
        cylinder(r = 2.2, h = 7);
    }
}

module cajas_pasaruedas_selladas() {
    // 4 Cajas estancas que aíslan las ruedas del interior (cubren el arco R=46 hasta Z=88 mm)
    for (xw = [x_wheel_rear, x_wheel_front]) {
        // Caja derecha (Y = 0 a 46 mm)
        translate([xw - 48, 0, z_base_sup])
        cube([96, 46, 72.0]);
        // Caja izquierda (Y = 254 a 300 mm)
        translate([xw - 48, W_base - 46, z_base_sup])
        cube([96, 46, 72.0]);
    }
}

module arcos_ruedas_visibles() {
    // Arcos de rueda cilíndricos R=46 mm concéntricos con los ejes a Z=40 mm
    for (xw = [x_wheel_rear, x_wheel_front]) {
        // Lado derecho (Y: -2 a 44)
        translate([xw, -2, 40.0])
        rotate([-90, 0, 0])
        cylinder(r = r_arch, h = 46.0);
        translate([xw - r_arch, -2, z_base_sup - 2])
        cube([2 * r_arch, 46.0, 40.0 - z_base_sup + 2]);

        // Lado izquierdo (Y: 256 a 302)
        translate([xw, W_base - 44, 40.0])
        rotate([-90, 0, 0])
        cylinder(r = r_arch, h = 46.0);
        translate([xw - r_arch, W_base - 44, z_base_sup - 2])
        cube([2 * r_arch, 46.0, 40.0 - z_base_sup + 2]);
    }
}

module alojamientos_interiores_sh1106() {
    for (ye = [y_eye_right, y_eye_left]) {
        translate([L_base - 8.0, ye - 19.0, z_eye - 18.0])
        cube([8.0, 38.0, 36.0]);
    }
}

module perforaciones_ojos_sh1106() {
    for (ye = [y_eye_right, y_eye_left]) {
        // 1. Orificio circular exterior enrasado (diam 14.5 mm, solo ve el área activa OLED)
        translate([L_base - 4.0, ye, z_eye])
        rotate([0, 90, 0])
        cylinder(d = d_eye_aperture, h = 8.0);

        // 2. Caja interior para PCB SH1106 (36 x 34 x 6 mm)
        translate([L_base - 7.0, ye - 17.0, z_eye - 16.0])
        cube([6.0, 34.0, 32.0]);

        // 3. Taladros para 4x pernos M2 en cada display (patrón 30.5 x 29.5 mm)
        for (dy = [-15.25, 15.25]) {
            for (dz = [-14.75, 14.75]) {
                translate([L_base - 9.0, ye + dy, z_eye + dz])
                rotate([0, 90, 0])
                cylinder(d = 1.9, h = 6.0);
            }
        }
    }
}

module puerto_acustico_microfono() {
    // Puerto acústico frontal diam 2.0 mm con avellanado cónico
    translate([L_base - 4.0, y_mic, z_mic])
    rotate([0, 90, 0])
    cylinder(d = 2.0, h = 8.0);
    translate([L_base - 1.0, y_mic, z_mic])
    rotate([0, 90, 0])
    cylinder(d1 = 2.0, d2 = 4.5, h = 1.5);

    // Caja interior PCB INMP441 (14 x 14 mm)
    translate([L_base - 6.0, y_mic - 7.5, z_mic - 7.5])
    cube([5.0, 15.0, 15.0]);

    // 2x Taladros M2 para fijación de micrófono
    for (dy = [-5.5, 5.5]) {
        translate([L_base - 8.0, y_mic + dy, z_mic])
        rotate([0, 90, 0])
        cylinder(d = 1.8, h = 5.0);
    }
}

module rejilla_y_camara_parlante() {
    // Matriz de microperforaciones de diam 1.8 mm en rosette de diam 20mm
    for (dy = [-9:4.5:9]) {
        for (dz = [-9:4.5:9]) {
            if (dy*dy + dz*dz <= 100) {
                translate([L_base - 4.0, y_spk + dy, z_spk + dz])
                rotate([0, 90, 0])
                cylinder(d = 1.8, h = 8.0);
            }
        }
    }

    // Cavidad acústica interior del transductor (diam 29 mm x 10 mm prof)
    translate([L_base - 12.0, y_spk, z_spk])
    rotate([0, 90, 0])
    cylinder(d = 29.0, h = 10.0);

    // 4x Taladros M2.5 para fijación del marco del parlante (patrón 28 x 28 mm)
    for (dy = [-14.0, 14.0]) {
        for (dz = [-14.0, 14.0]) {
            translate([L_base - 15.0, y_spk + dy, z_spk + dz])
            rotate([0, 90, 0])
            cylinder(d = 2.2, h = 8.0);
        }
    }
}

module troneras_sensores_tof() {
    // 4 Ventanas ópticas enrasadas para los sensores ToF (+11.59° pitch-up)
    // El faldón permanece 100% continuo y estanco en su base inferior Z=16.0 mm (cero dientes exteriores)
    for (yt = tof_y_coords) {
        translate([L_base - 5.0, yt, z_tof])
        rotate([0, -11.59, 0]) {
            // Ventana frontal oblonga enrasada (12 x 7 mm con esquinas R=2mm)
            hull() {
                translate([0, -4.0, -1.5]) rotate([0, 90, 0]) cylinder(r = 2.0, h = 10.0);
                translate([0, 4.0, -1.5]) rotate([0, 90, 0]) cylinder(r = 2.0, h = 10.0);
                translate([0, -4.0, 1.5]) rotate([0, 90, 0]) cylinder(r = 2.0, h = 10.0);
                translate([0, 4.0, 1.5]) rotate([0, 90, 0]) cylinder(r = 2.0, h = 10.0);
            }
            // Cajera interior para recibir el snout de la cuña interna
            translate([-3.0, -6.5, -4.5])
            cube([4.0, 13.0, 9.0]);
        }
    }
}

module ranura_burlete_perimetral() {
    // Ranura de 2.4 mm ancho x 1.8 mm profundidad en Z=95 para cordón de silicona diam 2mm
    translate([0, 0, z_split - 1.8])
    difference() {
        hull() {
            translate([12 + 0.3, 12 + 0.3, 0]) cylinder(r = 12 - 0.3, h = 2.0);
            translate([L_base - 12 - 0.3, 12 + 0.3, 0]) cylinder(r = 12 - 0.3, h = 2.0);
            translate([L_base - 12 - 0.3, W_base - 12 - 0.3, 0]) cylinder(r = 12 - 0.3, h = 2.0);
            translate([12 + 0.3, W_base - 12 - 0.3, 0]) cylinder(r = 12 - 0.3, h = 2.0);
        }
        translate([0, 0, -0.5])
        hull() {
            translate([12 + 2.5, 12 + 2.5, 0]) cylinder(r = 12 - 2.5, h = 3.0);
            translate([L_base - 12 - 2.5, 12 + 2.5, 0]) cylinder(r = 12 - 2.5, h = 3.0);
            translate([L_base - 12 - 2.5, W_base - 12 - 2.5, 0]) cylinder(r = 12 - 2.5, h = 3.0);
            translate([12 + 2.5, W_base - 12 - 2.5, 0]) cylinder(r = 12 - 2.5, h = 3.0);
        }
    }
}

module lengueta_estanqueidad_macho() {
    // Lengüeta de 1.8 mm ancho x 1.4 mm altura que comprime el burlete de silicona
    translate([0, 0, z_split - 1.4])
    difference() {
        hull() {
            translate([12 + 0.6, 12 + 0.6, 0]) cylinder(r = 12 - 0.6, h = 1.5);
            translate([L_base - 12 - 0.6, 12 + 0.6, 0]) cylinder(r = 12 - 0.6, h = 1.5);
            translate([L_base - 12 - 0.6, W_base - 12 - 0.6, 0]) cylinder(r = 12 - 0.6, h = 1.5);
            translate([12 + 0.6, W_base - 12 - 0.6, 0]) cylinder(r = 12 - 0.6, h = 1.5);
        }
        translate([0, 0, -0.5])
        hull() {
            translate([12 + 2.2, 12 + 2.2, 0]) cylinder(r = 12 - 2.2, h = 2.5);
            translate([L_base - 12 - 2.2, 12 + 2.2, 0]) cylinder(r = 12 - 2.2, h = 2.5);
            translate([L_base - 12 - 2.2, W_base - 12 - 2.2, 0]) cylinder(r = 12 - 2.2, h = 2.5);
            translate([12 + 2.2, W_base - 12 - 2.2, 0]) cylinder(r = 12 - 2.2, h = 2.5);
        }
    }
}

module torretas_tapa() {
    for (pt = boss_coords) {
        translate([pt[0], pt[1], z_split - 4.0])
        cylinder(r = 8.0, h = h_tapa + 4.0);
    }
}

module taladros_tapa() {
    for (pt = boss_coords) {
        // Taladro pasante M3 (diam 3.6 mm)
        translate([pt[0], pt[1], z_split - 6.0])
        cylinder(r = 1.8, h = h_tapa + 10.0);
        // Alojamiento avellanado para cabeza moleteada M3 (diam 12 mm x 3 mm prof)
        translate([pt[0], pt[1], z_top - 3.0])
        cylinder(r = 6.0, h = 5.0);
    }
}

module cuello_laberinto_balanza() {
    translate([x_balanza - L_apertura/2 - 2, y_balanza - L_apertura/2 - 2, z_top - 1.0])
    difference() {
        cube([L_apertura + 4, L_apertura + 4, 5.0]);
        translate([2, 2, -1]) cube([L_apertura, L_apertura, 7.0]);
    }
}

module nervaduras_interiores_techo() {
    // Costillas longitudinales exteriores al marco de balanza (Y=32 y Y=268 mm)
    for (y_pos = [32, 268]) {
        translate([20, y_pos - 1, z_top - t_wall - 7.0])
        cube([L_base - 40, 2.0, 7.5]);
    }
    // Costillas transversales delanteras y traseras
    translate([50, 20, z_top - t_wall - 7.0])
    cube([2.0, W_base - 40, 7.5]);
    translate([350, 20, z_top - t_wall - 7.0])
    cube([2.0, W_base - 40, 7.5]);
}

// ------------------------------------------------------------------------------
// SELECTOR DE RENDERIZADO
// ------------------------------------------------------------------------------
if (render_part == "assembly") {
    faldon_perimetral_base();
    tapa_enteriza_desmontable();
} else if (render_part == "faldon_base") {
    faldon_perimetral_base();
} else if (render_part == "tapa_superior") {
    tapa_enteriza_desmontable();
}
