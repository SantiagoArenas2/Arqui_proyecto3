#!/usr/bin/env bash
# postsint.sh - Seccion 3.7: simulacion funcional post-sintesis.
#
# 1. LibreLane sintetiza asic/config_postsint.json (la ROM del programa
#    acortado: decima de 1 ciclo, 2 rondas) y se detiene despues de Yosys.
# 2. Se simula con tb/tb_postsintesis.v el RTL y el netlist de LibreLane
#    (modelos de celdas GF180 sin retardos: -DFUNCTIONAL), con los mismos
#    estimulos.
# 3. Se comparan los logs: deben ser identicos ciclo a ciclo.
#
# Uso, desde la raiz del repositorio y dentro de nix-shell:
#   bash asic/scripts/postsint.sh            (sintetiza y simula)
#   bash asic/scripts/postsint.sh --sin-sintesis   (usa la sintesis ya hecha)
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build

if [ "${1:-}" != "--sin-sintesis" ]; then
  librelane --pdk gf180mcuD --run-tag postsint --overwrite --to Yosys.Synthesis \
      asic/config_postsint.json
fi

NL=$(ls asic/runs/postsint/*-yosys-synthesis/asic_top.nl.v 2>/dev/null | tail -1)
[ -n "$NL" ] || { echo "No encontre el netlist en asic/runs/postsint"; exit 1; }
MODELOS=$(python3 -c "
import json; c = json.load(open('asic/runs/postsint/resolved.json'))
print(' '.join(c['CELL_VERILOG_MODELS']))")
echo "Netlist: $NL"
echo "Modelos: $MODELOS"

RTL="asic/asic_top.v asic/espino_register_file.v asic/pochoco_mem_rom.v \
     asic/gen_postsint/game_rom.v rtl/pochoco_soc.v rtl/pochoco_periph.v \
     rtl/pochoco_cycle_counter.v rtl/pochoco_spi_slave.v rtl/espino_core/*.v"

echo; echo "### RTL"
iverilog -g2012 -o build/postsint_rtl.vvp -s tb_postsintesis $RTL tb/tb_postsintesis.v
vvp -n build/postsint_rtl.vvp | grep -v "VCD info"
cp build/tb_postsintesis.vcd build/postsint_rtl.vcd

echo; echo "### NETLIST de LibreLane"
iverilog -g2012 -DFUNCTIONAL -DNETLIST -o build/postsint_nl.vvp -s tb_postsintesis \
    $MODELOS "$NL" tb/tb_postsintesis.v
vvp -n build/postsint_nl.vvp | grep -v "VCD info"
cp build/tb_postsintesis.vcd build/postsint_nl.vcd

echo; echo "### Comparacion de eventos (LEDs y display, ciclo a ciclo)"
if diff build/postsint_rtl.log build/postsint_nl.log; then
  echo "IGUALES: el netlist reproduce el RTL ciclo a ciclo ($(wc -l < build/postsint_rtl.log) eventos)."
  cat build/postsint_rtl.log
else
  echo "DISTINTOS: revisar las diferencias de arriba."
  exit 1
fi
