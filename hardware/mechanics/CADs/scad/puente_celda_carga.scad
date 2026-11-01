// ==============================================================================
// ROBOT SUMOSO - PUENTE ESTRUCTURAL DEL SISTEMA DE PESAJE (CELDA 5 kg)
// Pieza Estructural FDM (PETG / PA-CF) para Desacoplo y Fijación de Balanza
// Conecta la placa intermedia con la celda paralelogramo y topes de sobrecarga
// ==============================================================================

$fn = 48;
eps = 0.05;

// Selector de visualización: "puente", "soporte_bandeja", "celda_dummy", "all"
PART = "all";

// ------------------------------------------------------------------------------
// 1. PUENTE ESTRUCTURAL PRINCIPAL (VINCULADO A LA PLACA INTERMEDIA)
// ------------------------------------------------------------------------------
// 4 apoyos en: (130, 60), (310, 60), (130, 240), (310, 240) mm
// Centro del puente: X = 220 mm, Y = 150 mm
module puente_celda_carga() {
    w_bridge = 196.0;   // Ancho total en Y (cubre de 52 a 248 mm)
    l_bridge = 196.0;   // Largo total en X (cubre de 122 a 318 mm)
    h_leg = 32.0;       // Altura de patas para librar batería LiPo 3S (25 mm)
    t_shelf = 6.0;      // Espesor de la plataforma del puente
    
    // Coordenadas locales relativas al centro (X=220, Y=150):
    // Apoyos a dx = +/- 90 mm, dy = +/- 90 mm
    difference() {
        union() {
            // 4 Columnas / Patas de apoyo esquineras
            for (dx = [-90.0, 90.0]) {
                for (dy = [-90.0, 90.0]) {
                    translate([dx, dy, 0])
                    cylinder(r = 9.0, h = h_leg + t_shelf);
                }
            }
            
            // Vigas longitudinales de enlace (X: -90 a +90)
            for (dy = [-90.0, 90.0]) {
                translate([-90.0, dy - 6.0, h_leg])
                cube([180.0, 12.0, t_shelf]);
            }
            
            // Vigas transversales de enlace (Y: -90 a +90)
            for (dx = [-90.0, 90.0]) {
                translate([dx - 6.0, -90.0, h_leg])
                cube([12.0, 180.0, t_shelf]);
            }
            
            // Travesaño central rígido de soporte para extremo fijo de la celda
            translate([-50.0, -18.0, h_leg])
            cube([45.0, 36.0, t_shelf + 4.0]); // Refuerzo espesor 10 mm
            
            // 4 Torretas para Pernos de Tope de Sobrecarga M3
            for (dx = [-60.0, 60.0]) {
                for (dy = [-60.0, 60.0]) {
                    translate([dx, dy, h_leg])
                    cylinder(r = 6.5, h = t_shelf + 3.0);
                }
            }
        }
        
        // 4x Taladros de fijación M3 a la placa intermedia (paso 180x180 mm)
        for (dx = [-90.0, 90.0]) {
            for (dy = [-90.0, 90.0]) {
                translate([dx, dy, -1])
                cylinder(d = 3.4, h = h_leg + t_shelf + 2);
                // Cajera para cabeza M3 en la parte superior
                translate([dx, dy, h_leg + t_shelf - 4.0])
                cylinder(d = 6.5, h = 6.0);
            }
        }
        
        // 2x Taladros M5 para anclaje de base fija de la celda 5 kg (paso 15.0 mm)
        // Celda centrada en Y=0, extremo fijo entre X=-45 y X=-30
        translate([-42.5, 0, h_leg - 1])
        cylinder(d = 5.2, h = t_shelf + 6.0);
        translate([-27.5, 0, h_leg - 1])
        cylinder(d = 5.2, h = t_shelf + 6.0);
        
        // 4x Taladros roscados M3 para pernos de tope de sobrecarga
        for (dx = [-60.0, 60.0]) {
            for (dy = [-60.0, 60.0]) {
                translate([dx, dy, h_leg - 1])
                cylinder(d = 3.0, h = t_shelf + 6.0);
            }
        }
        
        // Vaciado central inferior para garantizar 2.0 mm de holgura bajo la celda móvil
        translate([-15.0, -10.0, h_leg + 1.0])
        cube([60.0, 20.0, t_shelf + 5.0]);
    }
}

// ------------------------------------------------------------------------------
// 2. PIEZA DE INTERFAZ CANTILEVER PARA BANDEJA FLOTANTE (VOLADIZO CELDA)
// ------------------------------------------------------------------------------
// Se atornilla al extremo libre de la celda de 5 kg (X=+27.5 y X=+42.5)
// y proporciona los anclajes para la bandeja superior de pesaje
module soporte_bandeja_flotante() {
    h_block = 12.0;
    
    difference() {
        union() {
            // Bloque de acoplamiento a extremo móvil de la celda
            translate([20.0, -15.0, 0])
            cube([30.0, 30.0, h_block]);
            
            // Brazos de apoyo en T para bandeja superior
            translate([35.0 - 5.0, -50.0, h_block - 4.0])
            cube([10.0, 100.0, 4.0]);
        }
        
        // 2x Barrenos M5 pasantes para fijar a la celda (paso 15.0 mm)
        translate([27.5, 0, -1])
        cylinder(d = 5.2, h = h_block + 2);
        translate([42.5, 0, -1])
        cylinder(d = 5.2, h = h_block + 2);
        
        // Cajeras para pernos M5
        translate([27.5, 0, h_block - 5.0])
        cylinder(d = 10.0, h = 6.0);
        translate([42.5, 0, h_block - 5.0])
        cylinder(d = 10.0, h = 6.0);
        
        // 4x Taladros M3 para atornillar la bandeja superior de carga
        for (dy = [-40.0, -15.0, 15.0, 40.0]) {
            translate([35.0, dy, h_block - 5.0])
            cylinder(d = 3.2, h = 6.0);
        }
    }
}

// ------------------------------------------------------------------------------
// 3. MODELO DUMMY DE LA CELDA DE CARGA 5 kg (YZC-133 / TAL220)
// ------------------------------------------------------------------------------
module celda_carga_dummy_5kg() {
    color([0.85, 0.85, 0.88, 1.0]) // Aluminio aeroespacial
    difference() {
        // Bloque 80 x 12.7 x 12.7 mm
        translate([-40.0, -6.35, 0])
        cube([80.0, 12.7, 12.7]);
        
        // Vaciados del paralelogramo deformable
        translate([-10.0, 0, -1]) cylinder(d = 10.7, h = 14.7);
        translate([10.0, 0, -1]) cylinder(d = 10.7, h = 14.7);
        translate([-10.0, -5.35, -1]) cube([20.0, 10.7, 14.7]);
        
        // 2x Barrenos M5 extremo fijo (X = -35 y X = -20)
        translate([-35.0, 0, -1]) cylinder(d = 5.0, h = 14.7);
        translate([-20.0, 0, -1]) cylinder(d = 5.0, h = 14.7);
        
        // 2x Barrenos M5 extremo móvil (X = +20 y X = +35)
        translate([20.0, 0, -1]) cylinder(d = 5.0, h = 14.7);
        translate([35.0, 0, -1]) cylinder(d = 5.0, h = 14.7);
    }
}

// ------------------------------------------------------------------------------
// RENDERIZADO SEGÚN PARÁMETRO
// ------------------------------------------------------------------------------
if (PART == "puente") {
    puente_celda_carga();
} else if (PART == "soporte_bandeja") {
    soporte_bandeja_flotante();
} else if (PART == "celda_dummy") {
    celda_carga_dummy_5kg();
} else {
    // Ensamblaje completo del mecanismo de pesaje
    color([0.2, 0.2, 0.22, 1.0]) puente_celda_carga();
    
    // Celda de carga 5 kg montada en el travesaño central (Z = h_leg + 10 mm)
    translate([0, 0, 32.0 + 10.0])
    celda_carga_dummy_5kg();
    
    // Soporte cantilever de la bandeja flotante
    color([0.15, 0.35, 0.65, 1.0])
    translate([0, 0, 32.0 + 10.0 + 12.7])
    soporte_bandeja_flotante();
}
