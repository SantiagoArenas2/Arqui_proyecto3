// game_ffmem.vh
// GENERADO por asm/asm.py desde sw/game.s. No editar a mano.
// Constantes redefinidas: -D FRECUENCIA=10000000 -D CICLOS_DECIMA=2500
//
// Imagen de la memoria unificada de flip-flops (estrategia 2 del Proyecto 3):
// 178 palabras de programa + 1 de pila (PILA_PALABRAS) = 179 palabras.
// Cada palabra es el valor que toman sus 32 flip-flops durante el reset.

localparam integer GAME_PROG_WORDS = 178;
localparam integer GAME_WORDS      = 179;
localparam [32*179-1:0] GAME_IMAGE = {
  32'h00000000,  // [178] 0x2c8  pila
  32'h00008067,  // [177] 0x2c4  ret
  32'h00542023,  // [176] 0x2c0  sw   t0, DISPLAY(s0)
  32'h00a2e2b3,  // [175] 0x2bc  or   t0, t0, a0
  32'h005282b3,  // [174] 0x2b8  add  t0, t0, t0
  32'h005282b3,  // [173] 0x2b4  add  t0, t0, t0
  32'h005282b3,  // [172] 0x2b0  add  t0, t0, t0
  32'h005282b3,  // [171] 0x2ac  add  t0, t0, t0
  32'hff5ff06f,  // [170] 0x2a8  j    md_1
  32'h00128293,  // [169] 0x2a4  addi t0, t0, 1
  32'h40650533,  // [168] 0x2a0  sub  a0, a0, t1
  32'h00656863,  // [167] 0x29c  bltu a0, t1, md_2
  32'h00a00313,  // [166] 0x298  li   t1, 10
  32'h00000293,  // [165] 0x294  li   t0, 0
  32'h00008067,  // [164] 0x290  ret
  32'h00028513,  // [163] 0x28c  mv   a0, t0
  32'h00128293,  // [162] 0x288  addi t0, t0, 1
  32'h00656463,  // [161] 0x284  bltu a0, t1, pro_3
  32'h00a50533,  // [160] 0x280  add  a0, a0, a0
  32'hff5ff06f,  // [159] 0x27c  j    pro_1
  32'h00128293,  // [158] 0x278  addi t0, t0, 1
  32'h40650533,  // [157] 0x274  sub  a0, a0, t1
  32'h00656863,  // [156] 0x270  bltu a0, t1, pro_2
  32'h00a00313,  // [155] 0x26c  li   t1, RONDAS
  32'h00000293,  // [154] 0x268  li   t0, 0
  32'h00008067,  // [153] 0x264  ret
  32'h00028513,  // [152] 0x260  mv   a0, t0
  32'h00030293,  // [151] 0x25c  mv   t0, t1
  32'h00537463,  // [150] 0x258  bleu t0, t1, cad_3
  32'h06300313,  // [149] 0x254  li   t1, DECIMAS_TOPE
  32'hff5ff06f,  // [148] 0x250  j    cad_1
  32'h00128293,  // [147] 0x24c  addi t0, t0, 1
  32'h40650533,  // [146] 0x248  sub  a0, a0, t1
  32'h00656863,  // [145] 0x244  bltu a0, t1, cad_2
  32'h9c430313,  // [144] 0x240  li   t1, CICLOS_DECIMA
  32'h00001337,  // [143] 0x23c  li   t1, CICLOS_DECIMA
  32'h00000293,  // [142] 0x238  li   t0, 0
  32'h00008067,  // [141] 0x234  ret
  32'hff5ff06f,  // [140] 0x230  j    eo_4
  32'hfff28293,  // [139] 0x22c  addi t0, t0, -1
  32'h00a50533,  // [138] 0x228  add  a0, a0, a0
  32'h00028863,  // [137] 0x224  beqz t0, eo_5
  32'h00100513,  // [136] 0x220  li   a0, 1
  32'h007282b3,  // [135] 0x21c  add  t0, t0, t2
  32'h007383b3,  // [134] 0x218  add  t2, t2, t2
  32'h007033b3,  // [133] 0x214  snez t2, t2
  32'h0061f3b3,  // [132] 0x210  and  t2, gp, t1
  32'h00630333,  // [131] 0x20c  add  t1, t1, t1
  32'h005032b3,  // [130] 0x208  snez t0, t0
  32'h0061f2b3,  // [129] 0x204  and  t0, gp, t1
  32'h00010337,  // [128] 0x200  li   t1, 0x10000
  32'hfe0394e3,  // [127] 0x1fc  bnez t2, eo_1
  32'hfff38393,  // [126] 0x1f8  addi t2, t2, -1
  32'h003181b3,  // [125] 0x1f4  add  gp, gp, gp
  32'h0080006f,  // [124] 0x1f0  j    eo_3
  32'h0061c1b3,  // [123] 0x1ec  xor  gp, gp, t1
  32'h003181b3,  // [122] 0x1e8  add  gp, gp, gp
  32'h0001d863,  // [121] 0x1e4  bgez gp, eo_2
  32'h00730313,  // [120] 0x1e0  li   t1, POLINOMIO
  32'h00400337,  // [119] 0x1dc  li   t1, POLINOMIO
  32'h00800393,  // [118] 0x1d8  li   t2, 8
  32'h00008067,  // [117] 0x1d4  ret
  32'h00100193,  // [116] 0x1d0  li   gp, 1
  32'h00019463,  // [115] 0x1cc  bnez gp, mez_1
  32'h0051c1b3,  // [114] 0x1c8  xor  gp, gp, t0
  32'h00c42283,  // [113] 0x1c4  lw   t0, CONTADOR(s0)
  32'h00008067,  // [112] 0x1c0  ret
  32'h00410113,  // [111] 0x1bc  addi sp, sp, 4
  32'h00012083,  // [110] 0x1b8  lw   ra, 0(sp)
  32'hfe0294e3,  // [109] 0x1b4  bnez t0, sol_1
  32'h00842283,  // [108] 0x1b0  lw   t0, BOTONES(s0)
  32'hfb0080e7,  // [107] 0x1ac  call esperar
  32'h00000097,  // [106] 0x1a8  call esperar
  32'h1f400513,  // [105] 0x1a4  li   a0, CICLOS_REBOTE
  32'hfe029ee3,  // [104] 0x1a0  bnez t0, sol_1
  32'h00842283,  // [103] 0x19c  lw   t0, BOTONES(s0)
  32'h00112023,  // [102] 0x198  sw   ra, 0(sp)
  32'hffc10113,  // [101] 0x194  addi sp, sp, -4
  32'h00008067,  // [100] 0x190  ret
  32'h00030513,  // [ 99] 0x18c  mv   a0, t1
  32'h00008067,  // [ 98] 0x188  ret
  32'h00000513,  // [ 97] 0x184  li   a0, 0
  32'hfea368e3,  // [ 96] 0x180  bltu t1, a0, eob_1
  32'h40530333,  // [ 95] 0x17c  sub  t1, t1, t0
  32'h00c42303,  // [ 94] 0x178  lw   t1, CONTADOR(s0)
  32'h00031c63,  // [ 93] 0x174  bnez t1, eob_2
  32'h00842303,  // [ 92] 0x170  lw   t1, BOTONES(s0)
  32'h00c42283,  // [ 91] 0x16c  lw   t0, CONTADOR(s0)
  32'h00008067,  // [ 90] 0x168  ret
  32'hfea36ce3,  // [ 89] 0x164  bltu t1, a0, esp_1
  32'h40530333,  // [ 88] 0x160  sub  t1, t1, t0
  32'h00c42303,  // [ 87] 0x15c  lw   t1, CONTADOR(s0)
  32'h00c42283,  // [ 86] 0x158  lw   t0, CONTADOR(s0)
  32'heddff06f,  // [ 85] 0x154  j    nueva_partida
  32'h048080e7,  // [ 84] 0x150  call soltar_botones
  32'h00000097,  // [ 83] 0x14c  call soltar_botones
  32'h080080e7,  // [ 82] 0x148  call mezclar_semilla
  32'h00000097,  // [ 81] 0x144  call mezclar_semilla
  32'hfe0504e3,  // [ 80] 0x140  beqz a0, parpadeo_final
  32'h034080e7,  // [ 79] 0x13c  call esperar_o_boton
  32'h00000097,  // [ 78] 0x138  call esperar_o_boton
  32'h0d450513,  // [ 77] 0x134  li   a0, CICLOS_PARPADEO
  32'h00003537,  // [ 76] 0x130  li   a0, CICLOS_PARPADEO
  32'h00f74713,  // [ 75] 0x12c  xori a4, a4, 0b1111
  32'h00e42223,  // [ 74] 0x128  sw   a4, LEDS(s0)
  32'h00900713,  // [ 73] 0x124  li   a4, 0b1001
  32'h178080e7,  // [ 72] 0x120  call mostrar_decimas
  32'h00000097,  // [ 71] 0x11c  call mostrar_decimas
  32'h154080e7,  // [ 70] 0x118  call promedio
  32'h00000097,  // [ 69] 0x114  call promedio
  32'h00020513,  // [ 68] 0x110  mv   a0, tp
  32'h050080e7,  // [ 67] 0x10c  call esperar
  32'h00000097,  // [ 66] 0x108  call esperar
  32'h35050513,  // [ 65] 0x104  li   a0, CICLOS_FINAL
  32'h0000c537,  // [ 64] 0x100  li   a0, CICLOS_FINAL
  32'h00042223,  // [ 63] 0x0fc  sw   zero, LEDS(s0)
  32'hf45ff06f,  // [ 62] 0x0f8  j    ronda
  32'h068080e7,  // [ 61] 0x0f4  call esperar
  32'h00000097,  // [ 60] 0x0f0  call esperar
  32'h1a850513,  // [ 59] 0x0ec  li   a0, CICLOS_ERROR
  32'h00006537,  // [ 58] 0x0e8  li   a0, CICLOS_ERROR
  32'h0b4080e7,  // [ 57] 0x0e4  call soltar_botones
  32'h00000097,  // [ 56] 0x0e0  call soltar_botones
  32'h00042223,  // [ 55] 0x0dc  sw   zero, LEDS(s0)
  32'h00542023,  // [ 54] 0x0d8  sw   t0, DISPLAY(s0)
  32'h0ee00293,  // [ 53] 0x0d4  li   t0, ERROR_EE
  32'h02c0006f,  // [ 52] 0x0d0  j    fin_partida
  32'hf654c8e3,  // [ 51] 0x0cc  blt  s1, t0, ronda
  32'h00a00293,  // [ 50] 0x0c8  li   t0, RONDAS
  32'h0d4080e7,  // [ 49] 0x0c4  call soltar_botones
  32'h00000097,  // [ 48] 0x0c0  call soltar_botones
  32'h00148493,  // [ 47] 0x0bc  addi s1, s1, 1
  32'h1e0080e7,  // [ 46] 0x0b8  call mostrar_decimas
  32'h00000097,  // [ 45] 0x0b4  call mostrar_decimas
  32'h00a20233,  // [ 44] 0x0b0  add  tp, tp, a0
  32'h190080e7,  // [ 43] 0x0ac  call ciclos_a_decimas
  32'h00000097,  // [ 42] 0x0a8  call ciclos_a_decimas
  32'h00078513,  // [ 41] 0x0a4  mv   a0, a5
  32'h02b71a63,  // [ 40] 0x0a0  bne  a4, a1, ronda_error
  32'h12c080e7,  // [ 39] 0x09c  call mezclar_semilla
  32'h00000097,  // [ 38] 0x098  call mezclar_semilla
  32'h00038793,  // [ 37] 0x094  mv   a5, t2
  32'h00028713,  // [ 36] 0x090  mv   a4, t0
  32'hfe0286e3,  // [ 35] 0x08c  beqz t0, esperar_boton
  32'h00842283,  // [ 34] 0x088  lw   t0, BOTONES(s0)
  32'h40d30633,  // [ 33] 0x084  sub  a2, t1, a3
  32'h00d3e463,  // [ 32] 0x080  bltu t2, a3, leer_botones
  32'h40c303b3,  // [ 31] 0x07c  sub  t2, t1, a2
  32'h00c42303,  // [ 30] 0x078  lw   t1, CONTADOR(s0)
  32'h6cc68693,  // [ 29] 0x074  li   a3, CICLOS_TOPE
  32'h0003c6b7,  // [ 28] 0x070  li   a3, CICLOS_TOPE
  32'h00c42603,  // [ 27] 0x06c  lw   a2, CONTADOR(s0)
  32'h00b42223,  // [ 26] 0x068  sw   a1, LEDS(s0)
  32'h00050593,  // [ 25] 0x064  mv   a1, a0
  32'h17c080e7,  // [ 24] 0x060  call elegir_objetivo
  32'h00000097,  // [ 23] 0x05c  call elegir_objetivo
  32'h140080e7,  // [ 22] 0x058  call soltar_botones
  32'h00000097,  // [ 21] 0x054  call soltar_botones
  32'h10c080e7,  // [ 20] 0x050  call esperar
  32'h00000097,  // [ 19] 0x04c  call esperar
  32'h4f850513,  // [ 18] 0x048  li   a0, CICLOS_INICIO
  32'h00012537,  // [ 17] 0x044  li   a0, CICLOS_INICIO
  32'h00542223,  // [ 16] 0x040  sw   t0, LEDS(s0)
  32'h00f00293,  // [ 15] 0x03c  li   t0, 0b1111
  32'h00042023,  // [ 14] 0x038  sw   zero, DISPLAY(s0)
  32'h00000213,  // [ 13] 0x034  li   tp, 0
  32'h00000493,  // [ 12] 0x030  li   s1, 0
  32'h16c080e7,  // [ 11] 0x02c  call soltar_botones
  32'h00000097,  // [ 10] 0x028  call soltar_botones
  32'h1a4080e7,  // [  9] 0x024  call mezclar_semilla
  32'h00000097,  // [  8] 0x020  call mezclar_semilla
  32'hfe028ee3,  // [  7] 0x01c  beqz t0, esperar_inicio
  32'h00842283,  // [  6] 0x018  lw   t0, BOTONES(s0)
  32'h00042023,  // [  5] 0x014  sw   zero, DISPLAY(s0)
  32'h00042223,  // [  4] 0x010  sw   zero, LEDS(s0)
  32'h00100193,  // [  3] 0x00c  li   gp, 1
  32'h80000437,  // [  2] 0x008  li   s0, PERIF
  32'h2cc10113,  // [  1] 0x004  li   sp, fin_programa + 4 * PILA_PALABRAS
  32'h00000137   // [  0] 0x000  li   sp, fin_programa + 4 * PILA_PALABRAS
};
