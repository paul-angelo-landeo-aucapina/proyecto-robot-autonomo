// ==============================================================================
// ROBOT MOVIL AUTONOMO 2WD - PLATO PORTA-OBJETOS SUPERIOR (BANDEJA DE CARGA)
// Dimensiones Útiles: 130.0 x 95.0 mm con Reborde Anticaída de 8.0 mm
// Capacidad de Carga de Diseño: 1.0 a 1.2 kg nominal (sin pérdida de potencia)
// Incluye:
// 1. Bandeja perimetral redondeada con reborde de contención anticaída (h = 8.0 mm)
// 2. Nervaduras / estrías antideslizantes integradas en la superficie de apoyo
// 3. 4x Orejetas inferiores con taladros avellanados M3 para anclaje a la carcasa
// 4. Geometría 100% imprimible en FDM sin soportes (PETG / PLA / ABS)
// ==============================================================================

$fn = 36;

// Parámetros principales del plato (mm)
L_plato = 130.0;
W_plato = 95.0;
H_borde = 8.0;
t_piso = 2.5;
t_borde = 2.5;
r_esquina = 10.0;

// Espaciado de pernos de anclaje (coincidente con el techo de la carcasa)
dx_anclaje = 90.0;
dy_anclaje = 70.0;

module plato_porta_objetos_2wd() {
    color([0.20, 0.75, 0.45]) // Verde funcional / bandeja de carga
    difference() {
        union() {
            // 1. CUERPO EXTERIOR DE LA BANDEJA CON ESQUINAS REDONDEADAS
            hull() {
                translate([r_esquina, r_esquina, 0]) cylinder(r=r_esquina, h=H_borde);
                translate([L_plato - r_esquina, r_esquina, 0]) cylinder(r=r_esquina, h=H_borde);
                translate([r_esquina, W_plato - r_esquina, 0]) cylinder(r=r_esquina, h=H_borde);
                translate([L_plato - r_esquina, W_plato - r_esquina, 0]) cylinder(r=r_esquina, h=H_borde);
            }
            
            // 2. OREJETAS / TORRETAS INFERIORES DE ANCLAJE A CARCASA (Hacia abajo en Z=-5)
            for (sx = [-1, 1]) {
                for (sy = [-1, 1]) {
                    translate([L_plato/2 + sx * (dx_anclaje/2), W_plato/2 + sy * (dy_anclaje/2), -5])
                        cylinder(d=10.0, h=5.0);
                }
            }
            
            // 3. ESTRÍAS / NERVADURAS ANTIDESLIZANTES EN EL PISO INTERNO
            for (i = [-5:5]) {
                translate([L_plato/2 + i * 10, W_plato/2, t_piso])
                    cube([2.0, W_plato - 2 * (r_esquina + t_borde), 1.2], center=true);
            }
        }
        
        // 4. VACIADO INTERIOR PARA FORMAR LA BANDEJA CON REBORDE
        translate([0, 0, t_piso])
        hull() {
            translate([r_esquina + t_borde, r_esquina + t_borde, 0]) cylinder(r=r_esquina - t_borde, h=H_borde);
            translate([L_plato - r_esquina - t_borde, r_esquina + t_borde, 0]) cylinder(r=r_esquina - t_borde, h=H_borde);
            translate([r_esquina + t_borde, W_plato - r_esquina - t_borde, 0]) cylinder(r=r_esquina - t_borde, h=H_borde);
            translate([L_plato - r_esquina - t_borde, W_plato - r_esquina - t_borde, 0]) cylinder(r=r_esquina - t_borde, h=H_borde);
        }
        
        // 5. TALADROS AVELLANADOS M3 PARA FIJACIÓN A CARCASA (4x)
        for (sx = [-1, 1]) {
            for (sy = [-1, 1]) {
                // Taladro pasante M3
                translate([L_plato/2 + sx * (dx_anclaje/2), W_plato/2 + sy * (dy_anclaje/2), -6])
                    cylinder(d=3.4, h=15.0);
                // Avellanado superior para cabeza cónica DIN 7991 M3
                translate([L_plato/2 + sx * (dx_anclaje/2), W_plato/2 + sy * (dy_anclaje/2), t_piso + 0.5])
                    cylinder(d1=3.4, d2=6.8, h=2.5);
            }
        }
    }
}

plato_porta_objetos_2wd();
