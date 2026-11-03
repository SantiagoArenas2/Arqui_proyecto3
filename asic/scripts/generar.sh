#!/usr/bin/env bash
# generar.sh - Regenera el programa como hardware a partir de sw/game.s.
#
#   asic/gen/            corrida final: reloj de 10 MHz (T = 100 ns)
#   asic/gen_sim/        simulacion RTL del juego completo (tb_game):
#                        decima de 2.500 ciclos, todo 400 veces mas rapido
#   asic/gen_postsint/   simulacion post-sintesis (tb_postsintesis):
#                        decima de 1 ciclo y 2 rondas
#
# Cada carpeta tiene game_rom.v (estrategia 1) y game_ffmem.vh (estrategia 2).
# Uso, desde la raiz del repositorio:  bash asic/scripts/generar.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build asic/gen asic/gen_sim asic/gen_postsint
PY=${PY:-python3}

$PY asm/asm.py sw/game.s -o build/game_asic.hex -l build/game_asic.lst \
    -D FRECUENCIA=10000000 \
    --rom asic/gen/game_rom.v --ffmem asic/gen/game_ffmem.vh

$PY asm/asm.py sw/game.s -o build/game_asic_sim.hex \
    -D FRECUENCIA=10000000 -D CICLOS_DECIMA=2500 \
    --rom asic/gen_sim/game_rom.v --ffmem asic/gen_sim/game_ffmem.vh

$PY asm/asm.py sw/game.s -o build/game_postsint.hex \
    -D FRECUENCIA=10000000 -D CICLOS_DECIMA=1 -D RONDAS=2 \
    --rom asic/gen_postsint/game_rom.v --ffmem asic/gen_postsint/game_ffmem.vh
