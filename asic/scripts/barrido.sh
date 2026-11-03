#!/usr/bin/env bash
# barrido.sh - Corre LibreLane varias veces cambiando un parametro.
#
#   bash asic/scripts/barrido.sh periodo 100 50 30 20     CLOCK_PERIOD en ns
#   bash asic/scripts/barrido.sh util 40 55 70 85         FP_CORE_UTIL en %
#   bash asic/scripts/barrido.sh die 600 500 450          DIE_AREA cuadrado de L x L um
#
# Cada corrida queda en asic/runs/<tipo>_<valor> y su salida en
# asic/runs_logs/<tipo>_<valor>.log. Una corrida que falla no detiene el
# barrido: queda registrada como que no cierra. Al final imprime la tabla
# de asic/scripts/resumen.py.
#
# Opcional: CONFIG=asic/config_ff.json para barrer la otra estrategia.
set -u
cd "$(dirname "$0")/../.."
CONFIG=${CONFIG:-asic/config.json}
tipo=${1:?uso: barrido.sh periodo|util|die valores...}; shift
mkdir -p asic/runs_logs

for v in "$@"; do
  case $tipo in
    periodo) tag=periodo_$v; extra=(-c "CLOCK_PERIOD=$v") ;;
    util)    tag=util_$v;    extra=(-c "FP_CORE_UTIL=$v") ;;
    die)     tag=die_$v;     extra=(-c 'FP_SIZING="absolute"' -c "DIE_AREA=[0, 0, $v, $v]") ;;
    *) echo "tipo desconocido: $tipo (periodo, util o die)"; exit 1 ;;
  esac
  [ "$CONFIG" != asic/config.json ] && tag="$(basename "$CONFIG" .json)_$tag"
  echo "=== $tag  ($(date +%H:%M)) ==="
  if librelane --pdk gf180mcuD --run-tag "$tag" --overwrite "${extra[@]}" "$CONFIG" \
       > "asic/runs_logs/$tag.log" 2>&1; then
    echo "    termino el flujo"
  else
    echo "    el flujo se detuvo (ver asic/runs_logs/$tag.log)"
  fi
done

python3 asic/scripts/resumen.py --csv
