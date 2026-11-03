# resaltar.tcl
# Proyecto 3, secciones 3.3 y 3.6 - Trazabilidad en el layout.
#
# Marca en el layout las celdas del register file, la ALU y el contador de
# ciclos, y suma el area de las celdas de cada bloque.
#
# El metodo: la sintesis conserva tres modulos como jerarquia propia
# (SYNTH_KEEP_HIERARCHY_MODULES en asic/config.json). Al leer el netlist,
# OpenROAD aplana la jerarquia y cada celda queda con el nombre de su
# instancia como prefijo:
#   u_pochoco.u_core.u_rf/...                 register file
#   u_pochoco.u_core.u_id.u_alu/...           ALU
#   u_pochoco.u_periph.u_cycle_counter/...    contador de ciclos
# Los buffers que agrega OpenROAD despues (resizer, CTS) no tienen ese
# prefijo y no se cuentan.
#
# Uso con la interfaz grafica (desde la raiz del repositorio, en nix-shell):
#   librelane --pdk gf180mcuD --last-run --flow OpenInOpenROAD asic/config.json
#   y en la consola Tcl de OpenROAD (abajo):   source asic/scripts/resaltar.tcl
#   Guarda asic/resultados/layout_bloques.png.
#
# Sin interfaz (solo las areas):
#   ODB=asic/runs/<corrida>/final/odb/asic_top.odb openroad -exit -no_init asic/scripts/resaltar.tcl

set block [ord::get_db_block]
if {$block == "NULL" || $block == ""} {
  read_db $::env(ODB)
  set block [ord::get_db_block]
}
set dbu [$block getDbUnitsPerMicron]

# nombre del bloque, patron de instancias, grupo de color de la GUI
set bloques {
  {"register file"       "*u_rf/*"             0}
  {"ALU"                 "*u_alu/*"            1}
  {"contador de ciclos"  "*u_cycle_counter/*"  2}
}

set area_total 0.0
set cuenta_total 0
foreach inst [$block getInsts] {
  set m [$inst getMaster]
  set mn [$m getName]
  if {[string match "*__fill*" $mn] || [string match "*__endcap*" $mn] || [string match "*__filltie*" $mn]} {
    continue
  }
  set area_total [expr {$area_total + double([$m getWidth]) * [$m getHeight] / ($dbu * $dbu)}]
  incr cuenta_total
}

puts ""
puts [format "%-20s %8s %14s %8s" "bloque" "celdas" "area (um2)" "% total"]
foreach b $bloques {
  lassign $b nombre patron grupo
  set n 0
  set area 0.0
  foreach inst [$block getInsts] {
    if {[string match $patron [$inst getName]]} {
      set m [$inst getMaster]
      set area [expr {$area + double([$m getWidth]) * [$m getHeight] / ($dbu * $dbu)}]
      incr n
    }
  }
  puts [format "%-20s %8d %14.1f %7.1f%%" $nombre $n $area [expr {100.0 * $area / $area_total}]]
}
puts [format "%-20s %8d %14.1f %7.1f%%" "todas las celdas" $cuenta_total $area_total 100.0]
puts "(sin fillers, tapcells ni endcaps)"

if {[gui::enabled]} {
  gui::clear_highlights -1
  foreach b $bloques {
    lassign $b nombre patron grupo
    select -type Inst -name $patron -highlight $grupo
  }
  gui::clear_selections
  puts ""
  puts "Colores: grupo 0 = register file, 1 = ALU, 2 = contador de ciclos"
  puts "(se ven mejor ocultando las capas de metal en el panel Display Control)"
  file mkdir asic/resultados
  # gui::save_image archivo x0 y0 x1 y1 ancho_px  (area 0 0 0 0 = todo el die)
  gui::save_image asic/resultados/layout_bloques.png 0 0 0 0 2000
  puts "Imagen guardada: asic/resultados/layout_bloques.png"
}
