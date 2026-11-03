#!/usr/bin/env bash
# recolectar.sh - Copia a asic/resultados/ lo que se entrega de una corrida.
#
# asic/runs/ pesa cientos de MB y no se sube al repositorio (.gitignore).
# Este script copia solo lo necesario para el informe y la revision:
#
#   bash asic/scripts/recolectar.sh final        -> asic/resultados/final/
#   bash asic/scripts/recolectar.sh ff           -> asic/resultados/ff/
#
# Copia: el GDS final, el netlist final, las metricas, la configuracion
# resuelta, el reporte de sintesis, el resumen de STA de cada corner, los
# reportes de DRC/LVS/antena y la imagen del layout que genera KLayout.
set -euo pipefail
cd "$(dirname "$0")/../.."
tag=${1:?uso: recolectar.sh <corrida>}
run=asic/runs/$tag
dst=asic/resultados/$tag
[ -d "$run" ] || { echo "No existe $run"; exit 1; }
mkdir -p "$dst"

copiar() {   # copiar <patron> <destino>: copia el ultimo archivo que coincide
  local f
  f=$(ls -d $1 2>/dev/null | tail -1 || true)
  if [ -n "$f" ]; then cp -r "$f" "$dst/$2"; echo "  $2  <- $f"; else echo "  (no esta: $1)"; fi
}

echo "Corrida $run -> $dst"
copiar "$run/resolved.json"                                   resolved.json
copiar "$run/final/metrics.json"                              metrics.json
copiar "$run/final/metrics.csv"                               metrics.csv
copiar "$run/final/gds/asic_top.gds"                          asic_top.gds
copiar "$run/final/nl/asic_top.nl.v"                          asic_top.nl.v
copiar "$run/*-yosys-synthesis/reports/stat.rpt"              sintesis_stat.rpt
copiar "$run/*-yosys-synthesis/reports/stat.json"             sintesis_stat.json
copiar "$run/*-openroad-stapostpnr/summary.rpt"               sta_resumen.rpt
copiar "$run/*-openroad-stapostpnr/max_ss_125C_4v50/max.rpt"  ruta_critica_max_ss.rpt
copiar "$run/*-openroad-stapostpnr/nom_tt_025C_5v00/max.rpt"  ruta_critica_nom_tt.rpt
copiar "$run/*-magic-drc/reports/drc.magic.rpt"              drc_magic.rpt
copiar "$run/*-klayout-drc/reports/drc.klayout.json"         drc_klayout.json
copiar "$run/*-netgen-lvs/reports/lvs.netgen.rpt"             lvs.rpt
copiar "$run/*-openroad-checkantennas/reports/antenna_summary.rpt" antena.rpt
copiar "$run/*-klayout-render/*.png"                       layout.png
copiar "$run/flow.log"                                        flow.log
python3 asic/scripts/resumen.py --corrida "$tag" > "$dst/resumen.txt" || true
echo "  resumen.txt"
du -sh "$dst"
