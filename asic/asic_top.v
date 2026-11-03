// asic_top.v
// Proyecto 3 - Pochoco SoC con el juego de reflejos, como macro digital
// ICC3302 Arquitectura de Computadores, Universidad de los Andes, 2026-2
//
// Modulo superior del ASIC (DESIGN_NAME de LibreLane). Instancia el mismo
// pochoco_soc de la FPGA, sin nada propio de la FPGA ni de la Go Board.
//
// Los puertos son terminales del macro (pines en el borde del bloque),
// no pads: en un chip completo cada uno pasaria por un pad de I/O con su
// proteccion ESD, su buffer de salida y su conversion de nivel.
//
//   Puerto        Dir  Funcion
//   clk           in   reloj del sistema (T = 100 ns -> 10 MHz)
//   rst_n         in   reset asincrono, activo en bajo
//   btn_i[3:0]    in   botones; boton i = bit i de 0x8000_0008
//   led_o[3:0]    out  LEDs; LED i = bit i de 0x8000_0004
//   seg1_o[6:0]   out  display izquierdo (nibble alto de 0x8000_0000)
//   seg2_o[6:0]   out  display derecho (nibble bajo)
//                      segmentos activos en alto: bit 0 = A ... bit 6 = G
//   spi_*         -    esclavo SPI del Pochoco (sin uso en el juego)
//
// Diferencias con fpga/game_top.v (ver informe, seccion 3.1):
//   - El reset viene de un pin. En la FPGA era un contador con valor
//     inicial (reg por_cnt = 0), que en silicio no existe.
//   - El reset se sincroniza: se activa de inmediato (asincrono) y se
//     suelta en un flanco del reloj, para que todos los flip-flops salgan
//     del reset en el mismo ciclo.
//   - Los botones pasan por dos flip-flops (sincronizador). Son senales
//     asincronas al reloj y, sin sincronizar, el registro de lectura del
//     periferico podria quedar metaestable.

module asic_top (
  input  wire       clk,
  input  wire       rst_n,

  input  wire [3:0] btn_i,
  output wire [3:0] led_o,
  output wire [6:0] seg1_o,
  output wire [6:0] seg2_o,

  input  wire       spi_sclk_i,
  input  wire       spi_mosi_i,
  input  wire       spi_cs_n_i,
  output wire       spi_miso_o
);

  // ------------------------------------------------------------------
  // Sincronizador de reset: activacion asincrona, liberacion sincrona
  // ------------------------------------------------------------------
  reg [1:0] rst_sync_q;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) rst_sync_q <= 2'b00;
    else        rst_sync_q <= {rst_sync_q[0], 1'b1};
  end

  wire rst_sync_n = rst_sync_q[1];

  // ------------------------------------------------------------------
  // Sincronizador de botones: dos flip-flops por bit
  // ------------------------------------------------------------------
  reg [3:0] btn_meta_q, btn_sync_q;

  always @(posedge clk or negedge rst_sync_n) begin
    if (!rst_sync_n) begin
      btn_meta_q <= 4'b0;
      btn_sync_q <= 4'b0;
    end else begin
      btn_meta_q <= btn_i;
      btn_sync_q <= btn_meta_q;
    end
  end

  // ------------------------------------------------------------------
  // El SoC (mismo RTL que en la FPGA)
  // ------------------------------------------------------------------
  pochoco_soc u_pochoco (
    .i_Clk      (clk),
    .i_Rst_n    (rst_sync_n),
    .o_LED      (led_o),
    .i_Switch   (btn_sync_q),
    .o_Seg1     (seg1_o),
    .o_Seg2     (seg2_o),
    .i_SPI_SCLK (spi_sclk_i),
    .i_SPI_MOSI (spi_mosi_i),
    .i_SPI_CS_n (spi_cs_n_i),
    .o_SPI_MISO (spi_miso_o)
  );

endmodule
