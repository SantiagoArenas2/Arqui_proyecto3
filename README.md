# Proyecto 3 — Pochoco SoC como macro ASIC en GF180MCU

**ICC3302 Arquitectura de Computadores** · Universidad de los Andes · 2026-2
Profesor: Jorge Gómez Mir

**Integrantes:** José Tomás Arévalo · Santiago Arenas · Danna Collazos

El Pochoco SoC con el juego de reflejos del Proyecto 2, llevado desde RTL hasta
un **GDSII** con **LibreLane** y el PDK **GF180MCU** (variante `gf180mcuD`,
biblioteca `gf180mcu_fd_sc_mcu7t5v0`). El resultado es un macro digital de celdas
estándar: sus puertos son terminales del bloque, no pads.

El mismo RTL (`rtl/`) sigue funcionando en la FPGA del Proyecto 2 (`fpga/`).

---

## Versiones de la corrida final

| | |
|---|---|
| LibreLane | **3.0.17** (tag `3.0.17`, commit `64ef808`) |
| PDK | **gf180mcuD**, open_pdks `54435919abffb937387ec956209f9cf5fd2dfbee` (el que fija LibreLane 3.0.17, descargado por ciel) |
| Biblioteca de celdas | **gf180mcu_fd_sc_mcu7t5v0** (7 tracks, 5 V) |
| Herramientas | Yosys, OpenROAD, Magic, Netgen, KLayout, Verilator: las del entorno Nix de LibreLane 3.0.17. Versiones exactas en `asic/resultados/versiones.txt` (`make versiones`). |

---

## Qué hay en el repositorio

```
rtl/                       RTL comun (FPGA y ASIC)
  pochoco_soc.v            SoC: Espino + memoria + perifericos + SPI. Sin nada de FPGA.
  pochoco_periph.v         LEDs, botones, displays
  pochoco_cycle_counter.v  contador de ciclos (Proyecto 2), modulo propio
  pochoco_spi_slave.v
  espino_core/             procesador RV32E (sin el banco de registros)
asic/                      Proyecto 3
  asic_top.v               top del macro: reset y botones sincronizados
  espino_register_file.v   banco de registros de flip-flops
  pochoco_mem_rom.v        estrategia 1: ROM combinacional + RAM de 1 palabra
  pochoco_mem_ff.v         estrategia 2: memoria unificada de flip-flops
  gen/                     ROM e imagen generadas desde sw/game.s (corrida final)
  gen_sim/, gen_postsint/  lo mismo con las esperas acortadas para simular
  config.json              LibreLane, estrategia 1 (corrida final)
  config_ff.json           LibreLane, estrategia 2
  config_postsint.json     sintesis del programa acortado (seccion 3.7)
  pin_order.cfg            ubicacion de los terminales del macro
  evidencia_p2/            RTL del Proyecto 2 sin cambios (seccion 3.1)
  scripts/                 generar, barrido, resumen, postsint, resaltar, recolectar, versiones
  resultados/              lo que se entrega de las corridas (GDS, metricas, reportes)
fpga/                      lo propio de la FPGA (Proyecto 2)
  game_top.v               top de la Go Board: reset de encendido, segmentos activos en bajo
  pochoco_mem.v            memoria BRAM con $readmemh
  espino_register_file.v   banco de registros con SB_RAM40_4K
  goboard.pcf
asm/asm.py                 ensamblador del grupo (genera tambien la ROM y la imagen de FF)
sw/game.s                  el juego
tb/                        testbenches (tb_game sirve para FPGA y ASIC; tb_postsintesis)
Makefile                   flujos FPGA y ASIC
```

---

## 1. Instalar LibreLane

LibreLane necesita Linux o macOS. En Windows se usa **WSL2**.

**Windows:** en PowerShell como administrador, `wsl --install -d Ubuntu`,
reiniciar y abrir "Ubuntu" desde el menú Inicio.

**En Ubuntu (o cualquier Linux / macOS):**

```bash
sudo apt-get install -y curl git
curl --proto '=https' --tlsv1.2 -fsSL https://artifacts.nixos.org/nix-installer | sh -s -- install --no-confirm --extra-conf "
    extra-substituters = https://nix-cache.fossi-foundation.org
    extra-trusted-public-keys = nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs=
    extra-experimental-features = nix-command flakes
"
```

Cerrar y volver a abrir la terminal. Después:

```bash
git clone --branch 3.0.17 https://github.com/librelane/librelane ~/librelane
cd ~/librelane
nix-shell                       # la primera vez tarda ~10 min
librelane --smoke-test          # debe terminar sin errores
```

Cada vez que se trabaje en el proyecto: `cd ~/librelane && nix-shell`, y
dentro de esa terminal ir a la carpeta del repositorio. El PDK lo descarga
LibreLane solo (con ciel, en `~/.ciel`) la primera vez que se usa `--pdk gf180mcuD`.

---

## 2. Regenerar el programa desde `game.s`

```bash
make gen          # o: bash asic/scripts/generar.sh
```

El ensamblador genera el programa como hardware:

```bash
python3 asm/asm.py sw/game.s -o build/game_asic.hex -D FRECUENCIA=10000000 \
        --rom asic/gen/game_rom.v --ffmem asic/gen/game_ffmem.vh
```

| Salida | Qué es |
|---|---|
| `asic/gen/game_rom.v` | ROM combinacional (`module game_rom`): un `case` con una palabra por dirección. Estrategia 1. |
| `asic/gen/game_ffmem.vh` | Imagen de la memoria de flip-flops: programa + pila, como valor de reset de cada flip-flop. Estrategia 2. |

`-D FRECUENCIA=10000000` ajusta las esperas al reloj del ASIC (T = 100 ns,
10 MHz): una décima son 1.000.000 de ciclos y tres segundos, 30.000.000.

El juego usa **179 palabras de instrucciones y 1 de datos** (la pila, que solo
guarda `ra` en `soltar_botones`).

---

## 3. Corrida final

```bash
make asic         # = librelane --pdk gf180mcuD --run-tag final --overwrite asic/config.json
make resumen      # tabla con timing, area, DRC, LVS y antena de cada corrida
python3 asic/scripts/resumen.py --corrida final    # detalle: corners, celdas, ruta critica
make recolectar   # copia GDS, metricas y reportes a asic/resultados/
make versiones    # versiones exactas -> asic/resultados/versiones.txt
```

Parámetros de la corrida final: `CLOCK_PERIOD = 100` ns, `FP_CORE_UTIL = 40` %.
Se considera cerrada si LibreLane termina, DRC y LVS están limpios, no hay
antenas sin justificar y WNS ≥ 0, TNS = 0 en setup y hold en todos los corners.

Ver el layout:

```bash
librelane --pdk gf180mcuD --run-tag final --flow OpenInKLayout asic/config.json
librelane --pdk gf180mcuD --run-tag final --flow OpenInOpenROAD asic/config.json
#   en la consola de OpenROAD:  source asic/scripts/resaltar.tcl
#   marca register file, ALU y contador, suma su area y guarda
#   asic/resultados/layout_bloques.png
```

---

## 4. Exploración

```bash
make asic-ff                       # estrategia 2 (memoria de flip-flops)
make barrido-reloj                 # CLOCK_PERIOD = 100 50 35 30 25 20 ns
make barrido-reloj PERIODOS="28 26"
make barrido-util                  # FP_CORE_UTIL = 40 55 70 85 %
make evidencia                     # RTL del Proyecto 2 en LibreLane (seccion 3.1)
```

Cada corrida queda en `asic/runs/<nombre>` y su salida en `asic/runs_logs/`.
Con `CONFIG=asic/config_ff.json bash asic/scripts/barrido.sh ...` se barre la
estrategia 2.

La propuesta de la sección 3.4 (registrar las salidas del decodificador, sin
cambiar ningún ciclo) se activa con:

```bash
librelane --pdk gf180mcuD --run-tag predecodificado --overwrite \
    -c 'VERILOG_DEFINES=["ESPINO_PREDECODIFICAR"]' -c CLOCK_PERIOD=<periodo> asic/config.json
```

---

## 5. Simulación

```bash
make sim-asic     # juego completo en el RTL del ASIC, con las dos memorias (28/28 cada una)
make postsint     # seccion 3.7: RTL vs netlist de LibreLane, mismos estimulos
```

`make postsint` sintetiza con LibreLane el programa acortado (una décima = 1
ciclo, 2 rondas), simula el RTL y el netlist (modelos GF180 sin retardos) con los
botones apretados en ciclos fijos, y compara los eventos ciclo a ciclo. Debe
terminar en `IGUALES`.

Con el display mostrando décimas de 1 ciclo, el número que aparece **son los
ciclos que midió el programa**: 19 en la ronda 1 y 33 en la ronda 2, en las dos
simulaciones.

---

## 6. FPGA (Proyecto 2)

El flujo de la Go Board sigue igual. En Windows, en la terminal de OSS CAD Suite:

```
build             ensambla, sintetiza y graba
sim tb_game       simulacion del juego (28/28)
```

En Linux/macOS: `make` y `make test`. Usa `fpga/*.v` en vez de `asic/*.v`.

---

## Créditos

- Pochoco SoC y Espino Core: Nicolás Villegas, Universidad de los Andes
  ([pochoco_soc](https://github.com/nic0villegasc/pochoco_soc)), bajo la licencia
  Solderpad Hardware License 0.51. Se conservan sus avisos de copyright.
- Juego, ensamblador, contador de ciclos, adaptación a ASIC, memorias y
  scripts: el grupo.
