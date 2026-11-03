#!/usr/bin/env bash
# versiones.sh - Registra las versiones exactas de la corrida final.
# Correr dentro de nix-shell, desde la raiz del repositorio:
#   bash asic/scripts/versiones.sh        -> asic/resultados/versiones.txt
cd "$(dirname "$0")/../.."
mkdir -p asic/resultados
out=asic/resultados/versiones.txt
{
  echo "Fecha: $(date -Iseconds)"
  echo "Sistema: $(uname -srm)"
  echo
  echo "LibreLane:  $(librelane --version 2>&1 | tail -1)"
  if [ -d "${LIBRELANE_DIR:-$HOME/librelane}/.git" ]; then
    echo "  commit:   $(git -C "${LIBRELANE_DIR:-$HOME/librelane}" describe --tags --always 2>/dev/null) $(git -C "${LIBRELANE_DIR:-$HOME/librelane}" rev-parse HEAD)"
  fi
  r=asic/runs/final/resolved.json
  if [ -f "$r" ]; then
    python3 - "$r" <<'PY'
import json, sys, re
c = json.load(open(sys.argv[1]))
print("PDK:        ", c.get("PDK"))
print("PDK_ROOT:   ", c.get("PDK_ROOT"))
m = re.search(r"versions/([0-9a-f]{40})", str(c.get("PDK_ROOT", "")) + str(c.get("LIB", "")))
print("  revision: ", m.group(1) if m else "(ver PDK_ROOT)")
print("Biblioteca: ", c.get("STD_CELL_LIBRARY"))
print("CLOCK_PERIOD", c.get("CLOCK_PERIOD"), "ns, FP_CORE_UTIL", c.get("FP_CORE_UTIL"), "%")
PY
  fi
  echo
  echo "Yosys:      $(yosys -V 2>&1 | head -1)"
  echo "OpenROAD:   $(openroad -version 2>&1 | head -1)"
  echo "Magic:      $(magic --version 2>&1 | head -1)"
  echo "Netgen:     $(netgen -batch quit 2>&1 | grep -i 'netgen' | head -1)"
  echo "KLayout:    $(klayout -v 2>&1 | head -1)"
  echo "Verilator:  $(verilator --version 2>&1 | head -1)"
  echo "Icarus:     $(iverilog -V 2>&1 | head -1)"
  echo "Python:     $(python3 --version 2>&1)"
} | tee "$out"
echo; echo "Escrito $out"
