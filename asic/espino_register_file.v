// espino_register_file.v (version ASIC)
// Proyecto 3 - banco de registros del Espino implementado con flip-flops.
//
// En la FPGA el banco de registros instancia directamente dos pares de
// SB_RAM40_4K (fpga/espino_register_file.v), un bloque que solo existe en
// la iCE40. Esta version tiene la misma interfaz y el mismo
// comportamiento ciclo a ciclo, con flip-flops:
//
//   - 15 registros de 32 bits (x1..x15). x0 no se implementa: vale 0.
//   - Lectura sincrona, como la BRAM: el dato sale registrado en el flanco
//     siguiente a la direccion. Si en el mismo flanco se escribe y se lee
//     el mismo registro, la lectura entrega el valor anterior (igual que
//     SB_RAM40_4K). Asi el pipeline del Espino no cambia.
//   - Dos puertos de lectura (A y B) y uno de escritura. La BRAM necesitaba
//     dos copias del banco para tener dos lecturas; con flip-flops basta
//     una copia y dos multiplexores.
//   - Los registros no tienen reset (como un banco de registros RISC-V
//     normal): el programa escribe cada registro antes de leerlo.

module espino_register_file (
  input  wire        clk_i,
  input  wire        rst_ni,
  input  wire [3:0]  raddr_a_i,
  output wire [31:0] rdata_a_o,
  input  wire [3:0]  raddr_b_i,
  output wire [31:0] rdata_b_o,
  input  wire [3:0]  waddr_i,
  input  wire [31:0] wdata_i,
  input  wire        we_i
);

  reg [31:0] regs [1:15];
  reg [31:0] rdata_a_q, rdata_b_q;

  always @(posedge clk_i) begin
    if (we_i && (waddr_i != 4'd0)) regs[waddr_i] <= wdata_i;
  end

  // Salidas registradas con reset, como la salida de la BRAM (que arranca
  // en 0): asi el nucleo nunca ve un valor indefinido durante el reset.
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rdata_a_q <= 32'b0;
      rdata_b_q <= 32'b0;
    end else begin
      rdata_a_q <= (raddr_a_i == 4'd0) ? 32'b0 : regs[raddr_a_i];
      rdata_b_q <= (raddr_b_i == 4'd0) ? 32'b0 : regs[raddr_b_i];
    end
  end

  assign rdata_a_o = rdata_a_q;
  assign rdata_b_o = rdata_b_q;

endmodule
