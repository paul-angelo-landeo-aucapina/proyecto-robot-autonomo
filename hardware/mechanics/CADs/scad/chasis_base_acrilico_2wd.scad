// ==============================================================================
// ROBOT MOVIL AUTONOMO 2WD - PLACA BASE DE ACRILICO 19.5 x 12.5 cm
// Dimensiones: 195.0 x 125.0 x 3.0 mm (PMMA Cortado Laser)
// Configuración: 2 Ruedas Motrices (d=66mm, w=26mm) + 1 Rueda Loca (Caster)
// ==============================================================================

$fn = 40;

// Parámetros principales (mm)
L_base = 195.0;
W_base = 125.0;
t_base = 3.0;

// Posición del eje motriz respecto a la parte trasera
x_eje_motriz = 65.0;
y_semivia = W_base / 2; // 62.5 mm

// Dimensiones de ranuras de ruedas
largo_corte_rueda = 75.0;
ancho_corte_rueda = 16.0;

// Rueda loca frontal
x_caster = 170.0;

module placa_base_acrilico_2wd() {
    color([0.85, 0.90, 0.95, 0.60]) // Acrílico translúcido
    difference() {
        // Cuerpo principal con frente redondeado
        hull() {
            // Esquinas traseras redondeadas R=8
            translate([8, 8, 0]) cylinder(r=8, h=t_base);
            translate([8, W_base - 8, 0]) cylinder(r=8, h=t_base);
            // Parte media recta
            translate([150, 8, 0]) cylinder(r=8, h=t_base);
            translate([150, W_base - 8, 0]) cylinder(r=8, h=t_base);
            // Proa delantera arqueada
            translate([L_base - 15, W_base / 2, 0]) cylinder(r=15, h=t_base);
        }
        
        // 1. Ranura lateral para rueda izquierda
        translate([x_eje_motriz - largo_corte_rueda/2, -1, -1])
            cube([largo_corte_rueda, ancho_corte_rueda + 1, t_base + 2]);
            
        // 2. Ranura lateral para rueda derecha
        translate([x_eje_motriz - largo_corte_rueda/2, W_base - ancho_corte_rueda, -1])
            cube([largo_corte_rueda, ancho_corte_rueda + 1, t_base + 2]);
            
        // 3. Ranuras de fijación para brackets de motor TT (T-brackets de acrílico)
        // Motor izquierdo
        translate([x_eje_motriz - 20, ancho_corte_rueda + 4, -1])
            cube([3.5, 8.0, t_base + 2]);
        translate([x_eje_motriz + 20, ancho_corte_rueda + 4, -1])
            cube([3.5, 8.0, t_base + 2]);
            
        // Motor derecho
        translate([x_eje_motriz - 20, W_base - ancho_corte_rueda - 12, -1])
            cube([3.5, 8.0, t_base + 2]);
        translate([x_eje_motriz + 20, W_base - ancho_corte_rueda - 12, -1])
            cube([3.5, 8.0, t_base + 2]);
            
        // 4. Taladros para pernos de fijación de motores TT (M3 pasantes)
        translate([x_eje_motriz - 10, ancho_corte_rueda + 15, -1]) cylinder(d=3.2, h=t_base+2);
        translate([x_eje_motriz + 10, ancho_corte_rueda + 15, -1]) cylinder(d=3.2, h=t_base+2);
        translate([x_eje_motriz - 10, W_base - ancho_corte_rueda - 15, -1]) cylinder(d=3.2, h=t_base+2);
        translate([x_eje_motriz + 10, W_base - ancho_corte_rueda - 15, -1]) cylinder(d=3.2, h=t_base+2);
        
        // 5. Patrón de fijación de la rueda loca (Caster ball 4 tornillos M3)
        translate([x_caster, W_base/2 - 15, -1]) cylinder(d=3.2, h=t_base+2);
        translate([x_caster, W_base/2 + 15, -1]) cylinder(d=3.2, h=t_base+2);
        translate([x_caster - 15, W_base/2, -1]) cylinder(d=3.2, h=t_base+2);
        translate([x_caster + 15, W_base/2, -1]) cylinder(d=3.2, h=t_base+2);
        
        // 6. Taladros de anclaje para la carcasa superior (4x M3 en esquinas)
        translate([15, 12, -1]) cylinder(d=3.2, h=t_base+2);
        translate([15, W_base - 12, -1]) cylinder(d=3.2, h=t_base+2);
        translate([145, 12, -1]) cylinder(d=3.2, h=t_base+2);
        translate([145, W_base - 12, -1]) cylinder(d=3.2, h=t_base+2);
        
        // 7. Apertura circular para switch rocker ON/OFF (diam 20mm)
        translate([120, W_base/2, -1]) cylinder(d=20.0, h=t_base+2);
        
        // 8. Pasacables centrales
        translate([35, W_base/2, -1]) cylinder(d=12.0, h=t_base+2);
    }
}

placa_base_acrilico_2wd();
