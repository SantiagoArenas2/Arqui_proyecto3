// pochoco_cycle_counter.v
// Contador de ciclos de 32 bits del Pochoco (Proyecto 2, separado en su
// propio modulo en el Proyecto 3 para la trazabilidad jerarquica).
//
// Suma 1 en cada flanco de subida del reloj. El programa solo usa
// diferencias (fin - inicio): la resta sin signo de 32 bits es correcta
// aunque el contador de la vuelta entre las dos lecturas.
//
//                    FPGA (25 MHz)      ASIC (T = 100 ns, 10 MHz)
//   1 ciclo          40 ns              100 ns
//   1 decima         2.500.000 ciclos   1.000.000 ciclos
//   3 segundos       75.000.000 ciclos  30.000.000 ciclos
//   vuelta completa  171,8 s            429,5 s

module pochoco_cycle_counter (
  input  wire        clk_i,
  input  wire        rst_ni,
  output wire [31:0] count_o
);

  reg [31:0] count_q;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) count_q <= 32'b0;
    else         count_q <= count_q + 32'd1;
  end

  assign count_o = count_q;

endmodule
