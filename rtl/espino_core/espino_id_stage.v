// Copyright 2026 Universidad de los Andes.
// Licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: SHL-0.51
//
// Course: Arquitectura de Computadores (2026)
// 
// Authors:
// - Nicolás Villegas <navillegas@miuandes.cl>

module espino_id_stage (
  input  wire        clk_i,
  input  wire        rst_ni,

  input  wire        instr_valid_i,
  input  wire [31:0] instr_rdata_i,
  input  wire [31:0] pc_id_i,
  input  wire        stall_i,

  // Register file
  output wire [3:0]  rf_raddr_a_o,
  output wire [3:0]  rf_raddr_b_o,
  input  wire [31:0] rf_rdata_a_i,
  input  wire [31:0] rf_rdata_b_i,
  output wire [3:0]  rf_waddr_o,
  output reg  [31:0] rf_wdata_o,
  output wire        rf_we_o,

  // LSU control
  output wire        lsu_req_o,
  output wire        lsu_we_o,
  output wire [1:0]  lsu_type_o,
  output wire        lsu_sign_o,
  output wire [31:0] lsu_addr_o,
  output wire [31:0] lsu_wdata_o,
  input  wire [31:0] lsu_rdata_i,

  // Control transfer
  output wire        branch_taken_o,
  output wire        jump_o,
  output wire [31:0] pc_target_o,

  // Sync-read handshake to controller
  output wire        rf_ready_o,

  output wire        illegal_insn_o
);

  localparam [1:0] OP_A_PC   = 2'd1;
  localparam [1:0] OP_A_ZERO = 2'd2;
  localparam       OP_B_IMM  = 1'b1;
  localparam [1:0] WD_LSU    = 2'd1;
  localparam [1:0] WD_PC4    = 2'd2;

  // Register addresses
  assign rf_raddr_a_o = instr_rdata_i[18:15];
  assign rf_raddr_b_o = instr_rdata_i[23:20];
  assign rf_waddr_o   = instr_rdata_i[10:7];

  // ---- synchronous-read wait FSM ----
  reg  ops_valid_q;
  wire advance = ~stall_i;
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)      ops_valid_q <= 1'b0;
    else if (advance) ops_valid_q <= 1'b0;
    else              ops_valid_q <= 1'b1;
  end
  assign rf_ready_o = ops_valid_q;

  // Decode
  wire [3:0]  alu_operator;
  wire [1:0]  alu_op_a_sel;
  wire        alu_op_b_sel;
  wire [31:0] imm_operand, imm_target;
  wire        rf_we_dec;
  wire [1:0]  rf_wd_sel;
  wire        is_branch, is_jal, is_jalr;
  wire        lsu_req_dec, lsu_we_dec;
  wire [1:0]  lsu_type_dec;
  wire        lsu_sign_dec;

  // Proyecto 3 (seccion 3.4): con ESPINO_PREDECODIFICAR definido, las
  // salidas del decodificador se registran. No cambia ningun ciclo: cada
  // instruccion ya pasa un ciclo esperando la lectura sincrona del banco de
  // registros (ops_valid_q = 0). En ese ciclo la instruccion no cambia
  // (el fetch esta detenido), asi que en el ciclo de ejecucion el registro
  // ya tiene la instruccion decodificada y el decodificador sale de la ruta
  // instruccion -> ALU -> escritura en el banco de registros.
  wire [3:0]  alu_operator_c;
  wire [1:0]  alu_op_a_sel_c;
  wire        alu_op_b_sel_c;
  wire [31:0] imm_operand_c, imm_target_c;
  wire        rf_we_dec_c;
  wire [1:0]  rf_wd_sel_c;
  wire        is_branch_c, is_jal_c, is_jalr_c;
  wire        lsu_req_dec_c, lsu_we_dec_c;
  wire [1:0]  lsu_type_dec_c;
  wire        lsu_sign_dec_c;

  espino_decoder u_decoder (
    .instr_i        (instr_rdata_i),
    .illegal_insn_o (illegal_insn_o),
    .alu_operator_o (alu_operator_c),
    .alu_op_a_sel_o (alu_op_a_sel_c),
    .alu_op_b_sel_o (alu_op_b_sel_c),
    .imm_operand_o  (imm_operand_c),
    .imm_target_o   (imm_target_c),
    .rf_we_o        (rf_we_dec_c),
    .rf_wd_sel_o    (rf_wd_sel_c),
    .is_branch_o    (is_branch_c),
    .is_jal_o       (is_jal_c),
    .is_jalr_o      (is_jalr_c),
    .lsu_req_o      (lsu_req_dec_c),
    .lsu_we_o       (lsu_we_dec_c),
    .lsu_type_o     (lsu_type_dec_c),
    .lsu_sign_o     (lsu_sign_dec_c)
  );

  localparam integer DEC_W = 4 + 2 + 1 + 32 + 32 + 1 + 2 + 1 + 1 + 1 + 1 + 1 + 2 + 1;
  wire [DEC_W-1:0] dec_c = {alu_operator_c, alu_op_a_sel_c, alu_op_b_sel_c,
                            imm_operand_c, imm_target_c, rf_we_dec_c, rf_wd_sel_c,
                            is_branch_c, is_jal_c, is_jalr_c, lsu_req_dec_c,
                            lsu_we_dec_c, lsu_type_dec_c, lsu_sign_dec_c};
  wire [DEC_W-1:0] dec;

`ifdef ESPINO_PREDECODIFICAR
  reg [DEC_W-1:0] dec_q;
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) dec_q <= {DEC_W{1'b0}};
    else         dec_q <= dec_c;
  end
  assign dec = dec_q;
`else
  assign dec = dec_c;
`endif

  assign {alu_operator, alu_op_a_sel, alu_op_b_sel, imm_operand, imm_target,
          rf_we_dec, rf_wd_sel, is_branch, is_jal, is_jalr, lsu_req_dec,
          lsu_we_dec, lsu_type_dec, lsu_sign_dec} = dec;

  // Operand muxes
  reg  [31:0] operand_a;
  wire [31:0] operand_b;
  always @* begin
    case (alu_op_a_sel)
      OP_A_PC:   operand_a = pc_id_i;
      OP_A_ZERO: operand_a = 32'b0;
      default:   operand_a = rf_rdata_a_i;
    endcase
  end
  assign operand_b = (alu_op_b_sel == OP_B_IMM) ? imm_operand : rf_rdata_b_i;

  wire [31:0] alu_result;
  wire        alu_cmp_result;
  espino_alu u_alu (
    .operator_i   (alu_operator),
    .operand_a_i  (operand_a),
    .operand_b_i  (operand_b),
    .result_o     (alu_result),
    .cmp_result_o (alu_cmp_result)
  );

  // LSU control
  assign lsu_req_o   = lsu_req_dec & instr_valid_i & ops_valid_q;
  assign lsu_we_o    = lsu_we_dec;
  assign lsu_type_o  = lsu_type_dec;
  assign lsu_sign_o  = lsu_sign_dec;
  assign lsu_addr_o  = alu_result;
  assign lsu_wdata_o = rf_rdata_b_i;

  // Control transfer
  assign branch_taken_o = is_branch & alu_cmp_result;
  assign jump_o         = is_jal | is_jalr;
  assign pc_target_o    = is_jalr ? (alu_result & ~32'h1)
                                  : (pc_id_i + imm_target);

  wire commit = instr_valid_i & ~stall_i;

  always @* begin
    case (rf_wd_sel)
      WD_LSU:  rf_wdata_o = lsu_rdata_i;
      WD_PC4:  rf_wdata_o = pc_id_i + 32'd4;
      default: rf_wdata_o = alu_result;
    endcase
  end

  assign rf_we_o = rf_we_dec & commit;

endmodule