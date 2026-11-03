@echo off
REM ============================================================
REM  probar.bat - Graba en la FPGA un programa de ejemplo del
REM  Pochoco, sin tocar sw\game.hex. Sirve para saber si la placa
REM  y el SoC funcionan, independiente del juego.
REM
REM  Uso:  probar buttons_leds    cada boton enciende su LED
REM        probar blink           los 4 LEDs parpadean
REM        probar 7seg            el display cuenta
REM
REM  Para volver al juego:  build
REM ============================================================

setlocal enabledelayedexpansion

if "%~1"=="" (
    echo.
    echo   Uso: probar buttons_leds   ^(o blink, o 7seg^)
    echo.
    exit /b 1
)
if not exist "sw\%~1.hex" (
    echo.
    echo   No existe sw\%~1.hex
    echo.
    exit /b 1
)
if not exist build mkdir build

set SRCS=
for %%f in (rtl\*.v)             do set SRCS=!SRCS! rtl/%%~nxf
for %%f in (rtl\espino_core\*.v) do set SRCS=!SRCS! rtl/espino_core/%%~nxf
for %%f in (fpga\*.v)             do set SRCS=!SRCS! fpga/%%~nxf

REM chparam cambia el programa que carga la RAM (MemFile de game_top)
> build\probar.ys echo read_verilog!SRCS!
>>build\probar.ys echo chparam -set MemFile "sw/%~1.hex" game_top
>>build\probar.ys echo synth_ice40 -top game_top -dffe_min_ce_use 4 -json build/probar.json

echo.
echo   [1/4] Sintesis con sw\%~1.hex ...
yosys -q -s build\probar.ys
if errorlevel 1 (
    echo   FALLO LA SINTESIS.
    exit /b 1
)

echo   [2/4] Place and route ...
nextpnr-ice40 --hx1k --package vq100 --freq 25 --json build/probar.json --pcf fpga/goboard.pcf --asc build/probar.asc 2> build\probar_pnr.log
if errorlevel 1 (
    echo   FALLO EL PLACE AND ROUTE. Revisa build\probar_pnr.log
    exit /b 1
)

echo   [3/4] Bitstream ...
icepack build/probar.asc build/probar.bin
if errorlevel 1 exit /b 1

echo   [4/4] Grabando ...
iceprog build/probar.bin
if errorlevel 1 (
    echo   FALLO LA GRABACION. Revisa la placa: iceprog -t
    exit /b 1
)

echo.
echo   LISTO: sw\%~1.hex esta corriendo. Para volver al juego: build
echo.

endlocal
