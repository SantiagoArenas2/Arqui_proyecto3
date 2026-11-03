// pochoco_mem_rom.v
// Proyecto 3 - Estrategia 1: ROM combinacional de instrucciones + RAM de
// datos reducida. Implementa el modulo pochoco_mem que instancia el SoC.
//
// Puerto A (instrucciones): ROM generada por el ensamblador a partir de
//   sw/game.s (asic/gen/game_rom.v). La ROM es logica combinacional; la
//   salida se registra aqui para mantener la misma latencia de 1 ciclo
//   que la BRAM de la FPGA (el Espino no cambia).
//
// Puerto B (datos): RAM de DATA_WORDS palabras de flip-flops. El juego
//   solo usa la pila (PILA_PALABRAS = 1 en game.s), asi que basta 1
//   palabra. La decodificacion es parcial: solo se miran los bits de
//   direccion necesarios para elegir la palabra, y cualquier direccion
//   que no sea de periferico cae en la RAM. Por eso el programa no puede
//   leer datos de la ROM (game.s ya no tiene tablas .word).
//
// Mapa de memoria:
//   0x0000_0000 - 0x0000_03FF   ROM (256 palabras como maximo)
//   cualquier otra (bit 31 = 0) RAM de datos, repetida cada DATA_WORDS
//   0x8000_0000 - ...           perifericos (los decodifica el SoC)

module pochoco_mem #(
  parameter integer DATA_WORDS = 1    // potencia de 2; >= PILA_PALABRAS de game.s
) (
  input  wire        clk_i,
  input  wire        rst_ni,

  // Puerto A: instrucciones
  input  wire        a_req_i,
  input  wire [31:0] a_addr_i,
  output reg  [31:0] a_rdata_o,

  // Puerto B: datos
  input  wire        b_req_i,
  input  wire        b_we_i,
  input  wire [3:0]  b_be_i,
  input  wire [31:0] b_addr_i,
  input  wire [31:0] b_wdata_i,
  output reg  [31:0] b_rdata_o
);

  // ------------------------------------------------------------------
  // ROM de instrucciones
  // ------------------------------------------------------------------
  wire [31:0] rom_data;

  game_rom u_rom (
    .addr_i (a_addr_i[9:2]),
    .data_o (rom_data)
  );

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)      a_rdata_o <= 32'b0;
    else if (a_req_i) a_rdata_o <= rom_data;
  end

  // ------------------------------------------------------------------
  // RAM de datos
  // ------------------------------------------------------------------
  localparam integer AW = (DATA_WORDS > 1) ? $clog2(DATA_WORDS) : 1;

  reg  [31:0]   ram_q [0:DATA_WORDS-1];
  wire [AW-1:0] idx;

  generate
    if (DATA_WORDS > 1) begin : g_idx
      assign idx = b_addr_i[AW+1:2];
      wire _unused = &{1'b0, b_addr_i[1:0]};
    end else begin : g_idx1
      assign idx = 1'b0;
      wire _unused = &{1'b0, b_addr_i[AW+1:0]};
    end
  endgenerate

  wire we = b_req_i & b_we_i;

  always @(posedge clk_i) begin
    if (we & b_be_i[0]) ram_q[idx][7:0]   <= b_wdata_i[7:0];
    if (we & b_be_i[1]) ram_q[idx][15:8]  <= b_wdata_i[15:8];
    if (we & b_be_i[2]) ram_q[idx][23:16] <= b_wdata_i[23:16];
    if (we & b_be_i[3]) ram_q[idx][31:24] <= b_wdata_i[31:24];
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)      b_rdata_o <= 32'b0;
    else if (b_req_i) b_rdata_o <= ram_q[idx];
  end

  wire _unused_a = &{1'b0, a_addr_i[31:10], a_addr_i[1:0], b_addr_i[31:AW+2]};

endmodule
