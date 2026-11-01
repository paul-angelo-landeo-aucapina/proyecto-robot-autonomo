// ==============================================================================
// ROBOT SUMOSO - BRACKETS PARAMÉTRICOS 3D (PETG / PA-CF)
// Piezas Mecánicas FDM: Bracket Motor 37D, Espaciador Caster 4xM5, Cuña ToF +11.6°
// Geometría 100% 2-Manifold para Impresión 3D y Slicing FDM
// ==============================================================================

$fn = 64; // Alta resolución geométrica
eps = 0.05; // Margen anti-coincidencia para uniones booleanas de kernel CGAL

// Selector de pieza: "all", "motor", "omni", "tof"
PART = "all";

// ------------------------------------------------------------------------------
// 1. BRACKET EN L PARA MOTOR DC 37D CON NERVADURAS Y CUNA CILINDRICA (z_shaft = 24.0 mm)
// Proporciona 10.0 mm de despeje libre al suelo con ruedas d=80mm (Rw=40mm)
// ------------------------------------------------------------------------------
module bracket_motor_37d() {
    w_bracket = 46.0;      // Ancho total en Y
    h_face = 44.0;         // Altura cara vertical en Z
    t_face = 5.0;          // Espesor cara vertical
    l_base = 42.0;         // Longitud base en X
    t_base = 6.0;          // Espesor base
    z_shaft = 24.0;        // Altura eje de motor respecto a base (Rw=40mm -> Despeje al suelo = 10.0mm)
    t_gusset = 4.0;        // Espesor de cada nervadura
    l_gusset = 32.0;       // Longitud horizontal nervadura
    h_gusset = 24.0;       // Altura vertical nervadura
    r_motor = 18.5;        // Radio exterior motor 37D
    
    difference() {
        union() {
            // Cara vertical (apoyo motor)
            cube([t_face, w_bracket, h_face]);
            
            // Base horizontal (fijación a riel/chasis)
            cube([l_base, w_bracket, t_base]);
            
            // Nervadura triangular izquierda (Y = 0 a 4 mm)
            translate([t_face - eps, 0, t_base - eps])
            rotate([90, 0, 90])
            linear_extrude(height = t_gusset)
            polygon([[-eps, -eps], [-eps, h_gusset], [l_gusset, -eps]]);
            
            // Nervadura triangular derecha (Y = 42 a 46 mm)
            translate([t_face - eps, w_bracket - t_gusset, t_base - eps])
            rotate([90, 0, 90])
            linear_extrude(height = t_gusset)
            polygon([[-eps, -eps], [-eps, h_gusset], [l_gusset, -eps]]);
            
            // Filete interior de refuerzo anti-entalla (R = 4 mm)
            translate([t_face - eps, 0, t_base - eps])
            difference() {
                cube([4 + eps, w_bracket, 4 + eps]);
                translate([4 + eps, -1, 4 + eps])
                rotate([-90, 0, 0])
                cylinder(r = 4, h = w_bracket + 2);
            }
        }
        
        // Barreno central para cuello/eje motor 37D (diam 12.5 mm)
        translate([-1, w_bracket / 2, z_shaft])
        rotate([0, 90, 0])
        cylinder(d = 12.5, h = t_face + 2);
        
        // 6x Barrenos M3 para cara frontal del motor 37D (PCD = 31.0 mm)
        for (a = [0 : 60 : 300]) {
            translate([-1, w_bracket / 2 + 15.5 * cos(a), z_shaft + 15.5 * sin(a)])
            rotate([0, 90, 0])
            cylinder(d = 3.4, h = t_face + 2);
        }
        
        // Cuna cilíndrica de alivio para el cuerpo del motor 37D (R=19.0 mm a Z=24 mm)
        // Crea un asiento de apoyo que estabiliza el motor y evita interferencia
        translate([t_face - 1, w_bracket / 2, z_shaft])
        rotate([0, 90, 0])
        cylinder(r = r_motor + 0.5, h = l_base + 2);
        
        // 4x Barrenos M3 en base con cajera avellanada DIN 912
        for (xb = [16.0, 32.0]) {
            for (yb = [6.5, w_bracket - 6.5]) {
                // Pasante M3 (diam 3.4 mm)
                translate([xb, yb, -1])
                cylinder(d = 3.4, h = t_base + 2);
                // Cajera cabeza tornillo (diam 6.2 mm, prof 3.5 mm)
                translate([xb, yb, t_base - 3.5])
                cylinder(d = 6.2, h = 4.0);
            }
        }
        
        // Chaflanes superiores de aligeramiento en cara vertical
        translate([-1, -1, h_face - 4])
        rotate([45, 0, 0])
        cube([t_face + 2, 6, 6]);
        
        translate([-1, w_bracket + 1, h_face - 4])
        rotate([45, 0, 0])
        cube([t_face + 2, 6, 6]);
    }
}

// ------------------------------------------------------------------------------
// 2. BRACKET HORQUILLA PARA RUEDA OMNIDIRECCIONAL (d=80 mm, EJE ACERO 6 mm)
// Proporciona eje a Z=24.0 mm para apoyo coplanar en Z=0 y despeje de 10.0 mm
// ------------------------------------------------------------------------------
module bracket_omniwheel_65mm() {
    w_bracket = 46.0;      // Ancho total en Y
    l_base = 42.0;         // Largo base en X
    t_base = 6.0;          // Espesor base
    h_upright = 36.0;      // Altura orejas en Z
    t_wall = 6.0;          // Espesor de paredes de la horquilla
    z_shaft = 24.0;        // Eje de rueda a Z=24.0 mm (coplanar con motores 37D)
    x_shaft = 21.0;        // Eje centrado en la base
    d_pin = 6.1;           // Barreno pasante para eje rectificado de acero d=6.0 mm
    
    difference() {
        union() {
            // Base horizontal de apoyo sobre riel Al y placa PC
            cube([l_base, w_bracket, t_base]);
            
            // Oreja izquierda de la horquilla (Y: 0 a 6 mm)
            cube([l_base, t_wall, h_upright]);
            
            // Oreja derecha de la horquilla (Y: 40 a 46 mm)
            translate([0, w_bracket - t_wall, 0])
            cube([l_base, t_wall, h_upright]);
            
            // Nervaduras de rigidización en las caras exteriores
            translate([l_base, 0, t_base - eps])
            rotate([0, -90, 0])
            linear_extrude(height = l_base)
            polygon([[0, 0], [h_upright - t_base, 0], [0, t_wall]]);
            
            translate([l_base, w_bracket, t_base - eps])
            rotate([0, -90, 0])
            linear_extrude(height = l_base)
            polygon([[0, 0], [h_upright - t_base, 0], [0, -t_wall]]);
        }
        
        // Vaciado interior pasante hasta el fondo para que la rueda d=80mm baje libremente
        // Luz interior = 34.0 mm (rueda omni = 28.0 mm)
        translate([-1, t_wall, -1])
        cube([l_base + 2, w_bracket - 2 * t_wall, h_upright + 4]);
        
        // Taladro pasante horizontal para eje de acero d=6.0 mm
        translate([x_shaft, -1, z_shaft])
        rotate([-90, 0, 0])
        cylinder(d = d_pin, h = w_bracket + 2);
        
        // 4x Taladros M3 pasantes en la base (en las pestañas laterales de 6mm)
        for (xb = [6.0, 36.0]) {
            for (yb = [t_wall / 2, w_bracket - t_wall / 2]) {
                translate([xb, yb, -1])
                cylinder(d = 3.4, h = t_base + 2);
                
                // Cajera avellanada para cabeza M3 DIN 912
                translate([xb, yb, t_base - 3.5])
                cylinder(d = 6.2, h = 4.0);
            }
        }
        
        // Redondeo ergonómico superior de las orejas de la horquilla (R = 10 mm)
        for (yb = [-1, w_bracket - t_wall - 1]) {
            translate([0, yb, h_upright])
            rotate([0, 90, 0])
            difference() {
                translate([-15, 0, -1]) cube([30, t_wall + 2, l_base + 2]);
                translate([0, t_wall/2 + 1, -1]) cylinder(r = 10, h = l_base + 4);
            }
        }
    }
}

// ------------------------------------------------------------------------------
// 3. CUÑA ANGULAR ToF INTERIOR COMPACTA (+11.59° PITCH-UP, MONTAJE AL RAS)
// Queda 100% confinada dentro del faldón hermético, acoplando al ras con las troneras
// ------------------------------------------------------------------------------
module tof_sensor_wedge() {
    pitch_angle = 11.59;   // Ángulo de inclinación ascendente
    w_wedge = 24.0;        // Ancho en Y
    l_wedge = 18.0;        // Largo en X (compacto para no sobresalir de X=397.5 mm)
    t_base = 3.5;          // Espesor de la base
    snout_depth = 5.0;     // Campana óptica enrasada a la cara interna de la carrocería
    
    difference() {
        union() {
            // Base horizontal de apoyo al chasis (longitud total 25.0 mm)
            cube([25.0, w_wedge, t_base]);
            
            // Cuerpo de cuña angulada a +11.59°
            translate([3, 0, t_base - eps])
            rotate([0, -pitch_angle, 0])
            difference() {
                // Bloque inclinado
                cube([l_wedge, w_wedge, 12]);
                
                // Cajera para módulo PCB VL53L0X / VL53L1X (18 x 13 mm)
                translate([2, (w_wedge - 13.5)/2, 5.5])
                cube([15, 13.5, 7.5]);
            }
            
            // Campana óptica enrasada con tabique separador anti-crosstalk
            translate([3 + 2, w_wedge/2, t_base + 5.5])
            rotate([0, -pitch_angle, 0])
            difference() {
                // Campana exterior
                translate([-eps, -5.5, 0])
                cube([snout_depth + eps, 11.0, 7.5]);
                
                // Cavidad emisor VCSEL
                translate([-1, -4.5, 1.2])
                cube([snout_depth + 2, 4.0, 5.0]);
                
                // Cavidad receptor SPAD
                translate([-1, 0.5, 1.2])
                cube([snout_depth + 2, 4.0, 5.0]);
            }
        }
        
        // 2x Barrenos M3 en base para sujeción al chasis frontal (paso 18 mm)
        translate([l_wedge + 3.0, 3.5, -1])
        cylinder(d = 3.4, h = t_base + 2);
        translate([l_wedge + 3.0, w_wedge - 3.5, -1])
        cylinder(d = 3.4, h = t_base + 2);
        
        // 2x Taladros para insertos roscados M2.5 de fijación de PCB ToF
        translate([3, 0, t_base - eps])
        rotate([0, -pitch_angle, 0]) {
            translate([11, 2.5, -1])
            cylinder(d = 3.6, h = 12);
            translate([11, w_wedge - 2.5, -1])
            cylinder(d = 3.6, h = 12);
        }
        
        // Corte inferior rasante para asegurar base perfectamente plana Z=0
        translate([-5, -5, -10])
        cube([35.0, w_wedge + 10, 10]);
    }
}

// ------------------------------------------------------------------------------
// RENDERIZADO SEGÚN PARÁMETRO
// ------------------------------------------------------------------------------
if (PART == "motor") {
    bracket_motor_37d();
} else if (PART == "omni") {
    bracket_omniwheel_65mm();
} else if (PART == "tof") {
    tof_sensor_wedge();
} else {
    // Escena completa con las 3 piezas dispuestas para impresión/inspección
    translate([0, 0, 0]) bracket_motor_37d();
    translate([60, 0, 0]) bracket_omniwheel_65mm();
    translate([120, 0, 0]) tof_sensor_wedge();
}
