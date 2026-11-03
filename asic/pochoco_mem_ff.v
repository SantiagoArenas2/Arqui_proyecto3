// pochoco_mem_ff.v
// Proyecto 3 - Estrategia 2: memoria unificada de flip-flops.
// Implementa el modulo pochoco_mem que instancia el SoC.
//
// Una sola memoria guarda el programa y los datos (como la BRAM de la
// FPGA), dimensionada segun el uso real del juego: GAME_WORDS palabras =
// palabras del programa + PILA_PALABRAS de pila. Los dos valores vienen
// de asic/gen/game_ffmem.vh, que genera el ensamblador.
//
// En silicio no hay $readmemh: el programa se carga como VALOR DE RESET de
// los flip-flops. Cada palabra es un registro de 32 bits con reset
// asincrono; cada bit usa un flip-flop con reset (bit 0 del programa) o
// con set (bit 1). Al soltar el reset la memoria ya contiene el programa.
//
// Ambos puertos leen cualquier palabra (mux de GAME_WORDS a 1, registrado
// para mantener la latencia de 1 ciclo de la BRAM). El puerto B tambien
// escribe, con byte enables.

module pochoco_mem (
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

  `include "game_ffmem.vh"

  localparam integer AW = $clog2(GAME_WORDS);

  wire [AW-1:0] a_idx = a_addr_i[AW+1:2];
  wire [AW-1:0] b_idx = b_addr_i[AW+1:2];

  wire [32*GAME_WORDS-1:0] words;

  genvar i;
  generate
    for (i = 0; i < GAME_WORDS; i = i + 1) begin : g_word
      reg  [31:0] q;
      wire        we = b_req_i & b_we_i & (b_idx == i);

      always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          q <= GAME_IMAGE[32*i +: 32];
        end else if (we) begin
          if (b_be_i[0]) q[7:0]   <= b_wdata_i[7:0];
          if (b_be_i[1]) q[15:8]  <= b_wdata_i[15:8];
          if (b_be_i[2]) q[23:16] <= b_wdata_i[23:16];
          if (b_be_i[3]) q[31:24] <= b_wdata_i[31:24];
        end
      end

      assign words[32*i +: 32] = q;
    end
  endgenerate

  // Lecturas registradas. Una direccion fuera de la memoria devuelve 0.
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      a_rdata_o <= 32'b0;
      b_rdata_o <= 32'b0;
    end else begin
      if (a_req_i) a_rdata_o <= (a_idx < GAME_WORDS) ? words[32*a_idx +: 32] : 32'b0;
      if (b_req_i) b_rdata_o <= (b_idx < GAME_WORDS) ? words[32*b_idx +: 32] : 32'b0;
    end
  end

  wire _unused = &{1'b0, a_addr_i[31:AW+2], a_addr_i[1:0], b_addr_i[31:AW+2], b_addr_i[1:0]};

endmodule
