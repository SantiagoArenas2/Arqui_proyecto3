// tb_postsintesis.v
// Proyecto 3, seccion 3.7 - Simulacion funcional post-sintesis.
//
// El mismo testbench se corre dos veces con los MISMOS estimulos:
//   1. con el RTL de asic_top                       (sim postsint_rtl)
//   2. con el netlist de LibreLane (sin retardos)   (sim postsint_nl)
// y cada corrida escribe sus eventos en un log. Si el netlist es
// equivalente, los dos logs son identicos ciclo a ciclo.
//
// Los botones se presionan en CICLOS DEFINIDOS (tabla de abajo), sin
// mirar los LEDs: el estimulo es el mismo en las dos simulaciones.
//
// Configuracion acortada del programa (la misma en las dos corridas):
//   python asm/asm.py sw/game.s -o build/game_postsint.hex
//          -D FRECUENCIA=10000000 -D CICLOS_DECIMA=1 -D RONDAS=2
//          --rom asic/gen_postsint/game_rom.v ...
//   - CICLOS_DECIMA = 1: una "decima" dura 1 ciclo. La fase inicial dura
//     30 ciclos en vez de 3 s, y el display muestra DIRECTAMENTE los
//     ciclos que midio el programa (decimas = ciclos / 1).
//   - RONDAS = 2: la partida termina tras 2 rondas correctas. Si el
//     error se contara como ronda, la partida terminaria antes.
//
// Se verifica:
//   - una ronda correcta muestra los ciclos medidos (y son los mismos en
//     RTL y netlist: se compara el log completo);
//   - una pulsacion incorrecta muestra EE, apaga los LEDs y reinicia la
//     ronda actual: vuelve la fase con los 4 LEDs y otro objetivo, y la
//     partida NO avanza (sigue necesitando 2 rondas correctas).

`timescale 1ns/1ps

module tb_postsintesis;

  reg clk = 1'b0;
  always #50 clk = ~clk;                    // T = 100 ns

  reg        rst_n = 1'b0;
  reg  [3:0] btn   = 4'b0000;
  wire [3:0] led;
  wire [6:0] seg1, seg2;

  asic_top dut (
    .clk        (clk),
    .rst_n      (rst_n),
    .btn_i      (btn),
    .led_o      (led),
    .seg1_o     (seg1),
    .seg2_o     (seg2),
    .spi_sclk_i (1'b0),
    .spi_mosi_i (1'b0),
    .spi_cs_n_i (1'b1),
    .spi_miso_o ()
  );

  // ---------------------------------------------------------------
  // Estimulos: ciclo en que se aprieta, boton, ciclos apretado
  // (los ciclos se cuentan desde que se suelta el reset)
  // ---------------------------------------------------------------
  // Los ciclos salen de una primera corrida RTL: cada boton se aprieta
  // un poco despues de que se enciende el LED objetivo de esa ronda.
  parameter integer T_INICIO  = 20;    parameter [3:0] B_INICIO  = 4'b0001;  // empezar partida
  parameter integer T_RONDA1  = 340;   parameter [3:0] B_RONDA1  = 4'b0001;  // ronda 1: correcto
  parameter integer T_ERROR   = 900;   parameter [3:0] B_ERROR   = 4'b0100;  // ronda 2: EQUIVOCADO
  parameter integer T_RONDA2  = 1290;  parameter [3:0] B_RONDA2  = 4'b1000;  // ronda 2 otra vez: correcto
  parameter integer FIN       = 2000;
  // Un boton queda apretado 40 ciclos: mas que una vuelta del bucle que
  // lee los botones (14 ciclos), como cualquier pulsacion humana.
  localparam integer APRETADO  = 40;

  // ---------------------------------------------------------------
  // Display (segmentos activos en alto) -> digito hexadecimal
  // ---------------------------------------------------------------
  function [3:0] digito(input [6:0] s);     // s = {G,F,E,D,C,B,A}
    begin
      case (s)
        7'b0111111: digito = 4'h0;  7'b0000110: digito = 4'h1;
        7'b1011011: digito = 4'h2;  7'b1001111: digito = 4'h3;
        7'b1100110: digito = 4'h4;  7'b1101101: digito = 4'h5;
        7'b1111101: digito = 4'h6;  7'b0000111: digito = 4'h7;
        7'b1111111: digito = 4'h8;  7'b1101111: digito = 4'h9;
        7'b1110111: digito = 4'hA;  7'b1111100: digito = 4'hB;
        7'b0111001: digito = 4'hC;  7'b1011110: digito = 4'hD;
        7'b1111001: digito = 4'hE;  7'b1110001: digito = 4'hF;
        default:    digito = 4'hX;
      endcase
    end
  endfunction

  wire [7:0] display = {digito(seg1), digito(seg2)};

  // El display muestra el numero en decimal: 0x37 -> 37
  function integer decimal(input [7:0] d);
    decimal = d[7:4] * 10 + d[3:0];
  endfunction

  // ---------------------------------------------------------------
  // Ciclos y log de eventos
  // ---------------------------------------------------------------
  integer ciclo = -1;                       // -1 durante el reset
  integer log;
  reg [3:0] led_ant = 4'bxxxx;
  reg [7:0] disp_ant = 8'hxx;

  always @(posedge clk) begin
    if (rst_n) ciclo = ciclo + 1;
    #1;
    if (ciclo >= 0 && (led !== led_ant || display !== disp_ant)) begin
      $fdisplay(log, "ciclo %4d  LEDs %b  display %h", ciclo, led, display);
      led_ant  = led;
      disp_ant = display;
    end
  end

  integer pasadas = 0, total = 0;
  task revisar(input condicion, input [8*80-1:0] etiqueta);
    begin
      total = total + 1;
      if (condicion) begin pasadas = pasadas + 1; $display("PASS %0s", etiqueta); end
      else $display("FAIL %0s  (ciclo %0d, LEDs %b, display %h)", etiqueta, ciclo, led, display);
    end
  endtask

  task esperar_ciclo(input integer c);
    begin
      while (ciclo < c) @(posedge clk);
    end
  endtask

  // Espera a que el display cambie (con limite de ciclos)
  task esperar_display_nuevo(input integer limite);
    reg [7:0] antes;
    integer k;
    begin
      antes = display;
      k = 0;
      while (display === antes && k < limite) begin @(posedge clk); k = k + 1; end
    end
  endtask

  // Los estimulos cambian en el flanco de BAJADA: asi nunca coinciden con
  // el flanco de subida en que los flip-flops muestrean, y el RTL y el
  // netlist ven exactamente lo mismo (sin carreras del testbench).
  task apretar(input [3:0] b);
    begin
      @(negedge clk) btn = b;
      repeat (APRETADO) @(negedge clk);
      btn = 4'b0000;
    end
  endtask

  // Ciclo en que se encendio el LED objetivo (un solo LED)
  integer t_led = 0;
  always @(led) if (led == 4'b0001 || led == 4'b0010 || led == 4'b0100 || led == 4'b1000)
    t_led = ciclo;

  integer medidos1, medidos2, t_fase;

  initial begin
`ifdef NETLIST
    log = $fopen("build/postsint_nl.log", "w");
    $display("== Simulacion post-sintesis: NETLIST ==");
`else
    log = $fopen("build/postsint_rtl.log", "w");
    $display("== Simulacion post-sintesis: RTL ==");
`endif
    $dumpfile("build/tb_postsintesis.vcd");
    $dumpvars(0, tb_postsintesis);

    repeat (5) @(posedge clk);
    @(negedge clk) rst_n = 1'b1;

    // --- Pantalla de inicio -----------------------------------------
    esperar_ciclo(T_INICIO);
    revisar(led == 4'b0000 && display == 8'h00, "al salir del reset: LEDs apagados y display 00");
    apretar(B_INICIO);

    // --- Ronda 1: boton correcto ----------------------------------------
    esperar_ciclo(T_RONDA1);
    revisar(led == B_RONDA1, "ronda 1: el LED objetivo es el esperado");
    $display("     ronda 1: LED encendido en el ciclo %0d, boton en el ciclo %0d", t_led, ciclo);
    apretar(B_RONDA1);
    esperar_display_nuevo(600);
    medidos1 = decimal(display);
    revisar(medidos1 > 0 && medidos1 < 99, "ronda 1 correcta: el display muestra los ciclos medidos");
    $display("     ronda 1: ciclos medidos por el programa = %0d", medidos1);

    // --- Ronda 2: boton equivocado ---------------------------------------
    esperar_ciclo(T_ERROR);
    revisar(led != 4'b0000 && led != 4'b1111 && led != B_ERROR,
            "ronda 2: el boton apretado NO es el del LED objetivo");
    apretar(B_ERROR);
    revisar(display == 8'hEE && led == 4'b0000, "boton equivocado: EE y LEDs apagados");
    wait (led == 4'b1111);
    t_fase = ciclo;
    revisar(display == 8'hEE, "la ronda se reinicia: vuelven los 4 LEDs (fase inicial)");
    wait (led != 4'b1111);
    revisar(ciclo - t_fase >= 30, "la fase reiniciada dura sus 30 ciclos (DECIMAS_INICIO)");

    // --- Ronda 2 otra vez: correcto ---------------------------------------
    esperar_ciclo(T_RONDA2);
    revisar(led == B_RONDA2, "ronda 2 repetida: el LED objetivo es el esperado");
    $display("     ronda 2: LED encendido en el ciclo %0d, boton en el ciclo %0d", t_led, ciclo);
    apretar(B_RONDA2);
    esperar_display_nuevo(600);
    medidos2 = decimal(display);
    $display("     ronda 2: ciclos medidos por el programa = %0d", medidos2);
    revisar(medidos2 > 0 && medidos2 < 99, "ronda 2 correcta: el display muestra los ciclos medidos");

    // --- Fin: con RONDAS = 2, la partida termina aqui ----------------------
    wait (led == 4'b1001);
    revisar(decimal(display) == (medidos1 + medidos2 + 1) / 2,
            "fin tras 2 rondas correctas (el error no conto) y promedio correcto");
    $display("     promedio mostrado = %0d  ((%0d + %0d) / 2, redondeado)",
             decimal(display), medidos1, medidos2);

    esperar_ciclo(FIN);
    $fclose(log);
    $display("");
    $display("Pruebas aprobadas: %0d/%0d", pasadas, total);
    if (pasadas == total) $display("RESULTADO: comportamiento correcto. Comparar los logs RTL y netlist.");
    else                  $display("RESULTADO: hay pruebas que fallaron.");
    $finish;
  end

  initial begin
    #(100 * 20000);
    $display("FAIL tiempo limite: la simulacion no termino");
    $finish;
  end

endmodule
