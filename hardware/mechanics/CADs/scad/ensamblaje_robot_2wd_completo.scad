// ==============================================================================
// ROBOT MOVIL AUTONOMO 2WD - ENSAMBLAJE PARAMETRICO COMPLETO
// Chasis Acrílico 19.5 x 12.5 cm, Ruedas d=66mm w=26mm, Caster, Carcasa y Plato
// ==============================================================================

use <chasis_base_acrilico_2wd.scad>
use <carcasa_externa_2wd.scad>
use <plato_porta_objetos_2wd.scad>

$fn = 36;

/* [Configuración de Visualización] */
modo_vista = "completo"; // [completo: Robot Completo con Plato, sin_plato: Sin Plato Porta-Objetos, solo_mecanica: Solo Chasis Desnudo y Motores, carcasa_transparente: Carcasa Translúcida de Inspección]
mostrar_suelo = true;

// Cotas globales (mm)
// Suelo Z = 0
// Radio de rueda Rw = 33.0 mm -> Eje motor en Z = 33.0 mm
// Contacto con el suelo en Z = 0 mm
// Placa base acrílica montada con cara inferior a Z = 16.0 mm (Despeje = 16.0 mm)
// Cara superior de placa acrílica a Z = 19.0 mm
z_suelo = 0.0;
r_rueda = 33.0;
w_rueda = 26.0;
z_eje_motriz = 33.0;
x_eje_motriz = 65.0;
W_base = 125.0;
L_base = 195.0;
z_base_inf = 16.0;
z_base_sup = 19.0;
h_carcasa = 55.0;
z_techo_carcasa = z_base_sup + h_carcasa; // 74.0 mm

// 1. RUEDAS MOTRICES AMARILLAS CON NEUMÁTICO NEGRO (d=66mm, w=26mm)
module rueda_motriz() {
    // Neumático de goma negra con dibujo
    color([0.15, 0.15, 0.15])
    rotate([90, 0, 0])
    difference() {
        cylinder(r=r_rueda, h=w_rueda, center=true);
        cylinder(r=25.0, h=w_rueda + 2, center=true);
    }
    // Llanta amarilla característica TT
    color([0.95, 0.85, 0.10])
    rotate([90, 0, 0])
    cylinder(r=25.0, h=w_rueda - 2, center=true);
}

// 2. MOTORES TT AMARILLOS (1:48)
module motor_tt() {
    color([0.95, 0.80, 0.15]) // Carcasa amarilla TT
    cube([64.0, 22.0, 19.0], center=true);
    // Eje de salida plástico blanco
    color([0.95, 0.95, 0.95])
    translate([11.0, 0, 0])
    rotate([90, 0, 0])
    cylinder(d=5.4, h=36.0, center=true);
}

// 3. RUEDA LOCA FRONTAL (CASTER BALL METÁLICO/NYLON)
module rueda_loca_caster() {
    color([0.75, 0.75, 0.75]) // Carcasa metálica
    translate([0, 0, z_base_inf - 6.0])
        cylinder(d=32.0, h=6.0);
    color([0.90, 0.90, 0.95]) // Bola de acero/nylon
    translate([0, 0, 8.0])
        sphere(r=8.0);
}

// 4. BATERÍA LI-ION 2S 18650 Y ELECTRÓNICA
module electronica_y_potencia() {
    // Portapilas 2S con 2 celdas 18650 (Negro/Azul)
    color([0.1, 0.1, 0.1])
    translate([35, W_base/2, z_base_sup + 11])
        cube([78.0, 40.0, 21.0], center=true);
    color([0.2, 0.4, 0.8]) // Celdas 18650
    translate([35, W_base/2 - 10, z_base_sup + 11])
        rotate([0, 90, 0]) cylinder(d=18.0, h=65.0, center=true);
    color([0.2, 0.4, 0.8])
    translate([35, W_base/2 + 10, z_base_sup + 11])
        rotate([0, 90, 0]) cylinder(d=18.0, h=65.0, center=true);
        
    // Placa ESP32 DevKit
    color([0.1, 0.5, 0.2])
    translate([115, W_base/2, z_base_sup + 8])
        cube([52.0, 28.0, 5.0], center=true);
        
    // Driver TB6612FNG (Módulo rojo)
    color([0.8, 0.1, 0.1])
    translate([80, W_base/2, z_base_sup + 6])
        cube([20.0, 20.0, 4.0], center=true);
}

// ==============================================================================
// ENSAMBLAJE MAESTRO
// ==============================================================================

module ensamblaje_completo_2wd() {
    // Suelo de referencia
    if (mostrar_suelo) {
        color([0.92, 0.92, 0.92, 0.35])
        translate([L_base/2, W_base/2, -0.5])
            cube([260.0, 200.0, 1.0], center=true);
    }
    
    // Placa Base Acrílica
    translate([0, 0, z_base_inf])
        placa_base_acrilico_2wd();
        
    // Rueda Motriz Izquierda (Y = -w_rueda/2 + 8)
    translate([x_eje_motriz, 4.0, z_eje_motriz])
        rueda_motriz();
        
    // Rueda Motriz Derecha (Y = W_base + w_rueda/2 - 8)
    translate([x_eje_motriz, W_base - 4.0, z_eje_motriz])
        rueda_motriz();
        
    // Motor TT Izquierdo
    translate([x_eje_motriz + 11.0, 28.0, z_eje_motriz])
        motor_tt();
        
    // Motor TT Derecho
    translate([x_eje_motriz + 11.0, W_base - 28.0, z_eje_motriz])
        rotate([0, 0, 180])
        motor_tt();
        
    // Rueda Loca Frontal (X = 170 mm)
    translate([170.0, W_base/2, 0])
        rueda_loca_caster();
        
    // Electrónica y Baterías
    electronica_y_potencia();
    
    // Carcasa Externa
    if (modo_vista == "completo" || modo_vista == "sin_plato") {
        translate([2.5, 2.5, z_base_sup])
            carcasa_externa_2wd();
    } else if (modo_vista == "carcasa_transparente") {
        color([0.25, 0.55, 0.85, 0.35])
        translate([2.5, 2.5, z_base_sup])
            carcasa_externa_2wd();
    }
    
    // Plato Porta-Objetos Superior
    if (modo_vista == "completo" || modo_vista == "carcasa_transparente") {
        // Centrado longitudinalmente a X = x_eje_motriz + 48 = 113 mm
        translate([113.0 - 65.0, W_base/2 - 47.5, z_techo_carcasa])
            plato_porta_objetos_2wd();
            
        // Objeto de muestra transportado en el plato (Lata / Cilindro de carga = 350g)
        color([0.85, 0.20, 0.20, 0.85])
        translate([113.0, W_base/2, z_techo_carcasa + 2.5])
            cylinder(d=60.0, h=70.0);
    }
}

ensamblaje_completo_2wd();
