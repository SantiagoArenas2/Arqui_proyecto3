# Copyright 2026 Universidad de los Andes.
# Licensed under the Solderpad Hardware License, Version 0.51 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: SHL-0.51
#
# Course: Arquitectura de Computadores (2026)
#
# Authors:
# - Nicolás Villegas <navillegas@miuandes.cl>   (flujo original del Pochoco)
#
# Proyectos 2 y 3 del grupo: el mismo SoC (rtl/) con dos destinos.
#
# FPGA (Proyecto 2, Go Board). En Windows, build.bat y sim.bat hacen lo mismo.
#   make            ensambla, sintetiza, rutea y graba la FPGA
#   make bin        todo menos grabar
#   make test       pruebas del ensamblador y simulaciones de la FPGA
#   make sim TB=tb_game
#
# ASIC (Proyecto 3, LibreLane + GF180MCU). En Linux/WSL, dentro de nix-shell.
#   make gen             regenera asic/gen*/ desde sw/game.s
#   make sim-asic        juego completo en el RTL del ASIC (ROM y flip-flops)
#   make asic            corrida final de LibreLane (asic/runs/final)
#   make asic-ff         corrida de la estrategia 2 (asic/runs/ff)
#   make evidencia       corridas del RTL del Proyecto 2 (seccion 3.1)
#   make barrido-reloj   CLOCK_PERIOD = $(PERIODOS)
#   make barrido-util    FP_CORE_UTIL = $(UTILS)
#   make postsint        simulacion post-sintesis RTL vs netlist (seccion 3.7)
#   make resumen         tabla de todas las corridas (asic/resultados/corridas.csv)
#   make todo            TODAS las corridas, una tras otra (varias horas):
#                        final, evidencia, postsint, ff, barridos, resumen
#   make versiones       versiones de herramientas, PDK y biblioteca
#   make recolectar      copia lo que se entrega de asic/runs/final a asic/resultados/
#
#   make clean

ifeq ($(OS),Windows_NT)
PY    ?= python
else
PY    ?= python3
endif
BUILD := build

# =====================================================================
#  FPGA
# =====================================================================
TOP   := game_top
PCF   := fpga/goboard.pcf

# RTL comun + lo propio de la FPGA (fpga/)
RTL   := $(wildcard rtl/*.v rtl/espino_core/*.v)
SRC   := $(RTL) $(wildcard fpga/*.v)

HEX  := sw/game.hex
JSON := $(BUILD)/$(TOP).json
ASC  := $(BUILD)/$(TOP).asc
BIN  := $(BUILD)/$(TOP).bin

SIM_SRC := $(SRC) tb/sb_ram40_4k.v

.PHONY: all hex bin prog test sim clean gen sim-asic asic asic-ff evidencia \
        barrido-reloj barrido-util postsint resumen versiones recolectar todo

all: prog

$(BUILD):
	$(PY) -c "import os; os.makedirs('$(BUILD)', exist_ok=True)"

hex: $(HEX)
$(HEX): sw/game.s asm/asm.py | $(BUILD)
	$(PY) asm/asm.py sw/game.s -o $(HEX) -l $(BUILD)/game.lst

$(JSON): $(SRC) $(HEX) | $(BUILD)
	yosys -p "read_verilog $(SRC); synth_ice40 -top $(TOP) -dffe_min_ce_use 4 -json $(JSON); stat"

$(ASC): $(JSON) $(PCF)
	nextpnr-ice40 --hx1k --package vq100 --freq 25 --json $(JSON) --pcf $(PCF) --asc $(ASC)

bin: $(BIN)
$(BIN): $(ASC)
	icepack $(ASC) $(BIN)

prog: $(BIN)
	iceprog $(BIN)

$(BUILD)/prueba_cpu.hex: sw/prueba_cpu.s asm/asm.py | $(BUILD)
	$(PY) asm/asm.py sw/prueba_cpu.s -o $@
$(BUILD)/game_sim.hex: sw/game.s asm/asm.py | $(BUILD)
	$(PY) asm/asm.py sw/game.s -o $@ -D CICLOS_DECIMA=2500

TB ?= tb_game
sim: $(BUILD)/prueba_cpu.hex $(BUILD)/game_sim.hex
	iverilog -g2012 -o $(BUILD)/$(TB).vvp -s $(TB) $(SIM_SRC) tb/$(TB).v
	vvp -n $(BUILD)/$(TB).vvp

test: $(BUILD)/prueba_cpu.hex $(BUILD)/game_sim.hex
	$(PY) asm/pruebas/probar_asm.py
	$(MAKE) --no-print-directory sim TB=tb_periph
	$(MAKE) --no-print-directory sim TB=tb_soc
	$(MAKE) --no-print-directory sim TB=tb_game

# =====================================================================
#  ASIC
# =====================================================================
LIBRELANE ?= librelane --pdk gf180mcuD
ASIC_SRC  := asic/asic_top.v asic/espino_register_file.v $(RTL)
PERIODOS  ?= 100 50 35 30 25 20
UTILS     ?= 40 55 70 85

gen: | $(BUILD)
	bash asic/scripts/generar.sh

# Juego completo (tb_game) con el RTL del ASIC, una vez por estrategia
sim-asic: gen
	iverilog -g2012 -DASIC -o $(BUILD)/tb_game_rom.vvp -s tb_game $(ASIC_SRC) \
	    asic/pochoco_mem_rom.v asic/gen_sim/game_rom.v tb/tb_game.v
	vvp -n $(BUILD)/tb_game_rom.vvp | grep -v "VCD info"
	iverilog -g2012 -DASIC -I asic/gen_sim -o $(BUILD)/tb_game_ff.vvp -s tb_game \
	    $(ASIC_SRC) asic/pochoco_mem_ff.v tb/tb_game.v
	vvp -n $(BUILD)/tb_game_ff.vvp | grep -v "VCD info"

asic:
	$(LIBRELANE) --run-tag final --overwrite asic/config.json

asic-ff:
	$(LIBRELANE) --run-tag ff --overwrite asic/config_ff.json

evidencia:
	-$(LIBRELANE) --run-tag p2_paso1 --overwrite asic/evidencia_p2/config_paso1.json
	-$(LIBRELANE) --run-tag p2_paso2 --overwrite --to Yosys.Synthesis asic/evidencia_p2/config_paso2.json

barrido-reloj:
	bash asic/scripts/barrido.sh periodo $(PERIODOS)

barrido-util:
	bash asic/scripts/barrido.sh util $(UTILS)

postsint:
	bash asic/scripts/postsint.sh

resumen:
	$(PY) asic/scripts/resumen.py --csv

versiones:
	bash asic/scripts/versiones.sh

# Todo seguido. -k en la llamada: si una corrida falla, sigue con la otra.
todo:
	-$(MAKE) --no-print-directory asic
	-$(MAKE) --no-print-directory recolectar
	-$(MAKE) --no-print-directory versiones
	-$(MAKE) --no-print-directory evidencia
	-$(MAKE) --no-print-directory postsint
	-$(MAKE) --no-print-directory barrido-reloj
	-$(MAKE) --no-print-directory barrido-util
	-$(MAKE) --no-print-directory asic-ff
	-$(MAKE) --no-print-directory recolectar
	-$(MAKE) --no-print-directory resumen

recolectar:
	bash asic/scripts/recolectar.sh final
	-bash asic/scripts/recolectar.sh ff

clean:
	$(PY) -c "import shutil; shutil.rmtree('$(BUILD)', ignore_errors=True)"
