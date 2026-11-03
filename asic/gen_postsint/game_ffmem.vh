// game_ffmem.vh
// GENERADO por asm/asm.py desde sw/game.s. No editar a mano.
// Constantes redefinidas: -D FRECUENCIA=10000000 -D CICLOS_DECIMA=1 -D RONDAS=2
//
// Imagen de la memoria unificada de flip-flops (estrategia 2 del Proyecto 3):
// 172 palabras de programa + 1 de pila (PILA_PALABRAS) = 173 palabras.
// Cada palabra es el valor que toman sus 32 flip-flops durante el reset.

localparam integer GAME_PROG_WORDS = 172;
localparam integer GAME_WORDS      = 173;
localparam [32*173-1:0] GAME_IMAGE = {
  32'h00000000,  // [172] 0x2b0  pila
  32'h00008067,  // [171] 0x2ac  ret
  32'h00542023,  // [170] 0x2a8  sw   t0, DISPLAY(s0)
  32'h00a2e2b3,  // [169] 0x2a4  or   t0, t0, a0
  32'h005282b3,  // [168] 0x2a0  add  t0, t0, t0
  32'h005282b3,  // [167] 0x29c  add  t0, t0, t0
  32'h005282b3,  // [166] 0x298  add  t0, t0, t0
  32'h005282b3,  // [165] 0x294  add  t0, t0, t0
  32'hff5ff06f,  // [164] 0x290  j    md_1
  32'h00128293,  // [163] 0x28c  addi t0, t0, 1
  32'h40650533,  // [162] 0x288  sub  a0, a0, t1
  32'h00656863,  // [161] 0x284  bltu a0, t1, md_2
  32'h00a00313,  // [160] 0x280  li   t1, 10
  32'h00000293,  // [159] 0x27c  li   t0, 0
  32'h00008067,  // [158] 0x278  ret
  32'h00028513,  // [157] 0x274  mv   a0, t0
  32'h00128293,  // [156] 0x270  addi t0, t0, 1
  32'h00656463,  // [155] 0x26c  bltu a0, t1, pro_3
  32'h00a50533,  // [154] 0x268  add  a0, a0, a0
  32'hff5ff06f,  // [153] 0x264  j    pro_1
  32'h00128293,  // [152] 0x260  addi t0, t0, 1
  32'h40650533,  // [151] 0x25c  sub  a0, a0, t1
  32'h00656863,  // [150] 0x258  bltu a0, t1, pro_2
  32'h00200313,  // [149] 0x254  li   t1, RONDAS
  32'h00000293,  // [148] 0x250  li   t0, 0
  32'h00008067,  // [147] 0x24c  ret
  32'h00028513,  // [146] 0x248  mv   a0, t0
  32'h00030293,  // [145] 0x244  mv   t0, t1
  32'h00537463,  // [144] 0x240  bleu t0, t1, cad_3
  32'h06300313,  // [143] 0x23c  li   t1, DECIMAS_TOPE
  32'hff5ff06f,  // [142] 0x238  j    cad_1
  32'h00128293,  // [141] 0x234  addi t0, t0, 1
  32'h40650533,  // [140] 0x230  sub  a0, a0, t1
  32'h00656863,  // [139] 0x22c  bltu a0, t1, cad_2
  32'h00100313,  // [138] 0x228  li   t1, CICLOS_DECIMA
  32'h00000293,  // [137] 0x224  li   t0, 0
  32'h00008067,  // [136] 0x220  ret
  32'hff5ff06f,  // [135] 0x21c  j    eo_4
  32'hfff28293,  // [134] 0x218  addi t0, t0, -1
  32'h00a50533,  // [133] 0x214  add  a0, a0, a0
  32'h00028863,  // [132] 0x210  beqz t0, eo_5
  32'h00100513,  // [131] 0x20c  li   a0, 1
  32'h007282b3,  // [130] 0x208  add  t0, t0, t2
  32'h007383b3,  // [129] 0x204  add  t2, t2, t2
  32'h007033b3,  // [128] 0x200  snez t2, t2
  32'h0061f3b3,  // [127] 0x1fc  and  t2, gp, t1
  32'h00630333,  // [126] 0x1f8  add  t1, t1, t1
  32'h005032b3,  // [125] 0x1f4  snez t0, t0
  32'h0061f2b3,  // [124] 0x1f0  and  t0, gp, t1
  32'h00010337,  // [123] 0x1ec  li   t1, 0x10000
  32'hfe0394e3,  // [122] 0x1e8  bnez t2, eo_1
  32'hfff38393,  // [121] 0x1e4  addi t2, t2, -1
  32'h003181b3,  // [120] 0x1e0  add  gp, gp, gp
  32'h0080006f,  // [119] 0x1dc  j    eo_3
  32'h0061c1b3,  // [118] 0x1d8  xor  gp, gp, t1
  32'h003181b3,  // [117] 0x1d4  add  gp, gp, gp
  32'h0001d863,  // [116] 0x1d0  bgez gp, eo_2
  32'h00730313,  // [115] 0x1cc  li   t1, POLINOMIO
  32'h00400337,  // [114] 0x1c8  li   t1, POLINOMIO
  32'h00800393,  // [113] 0x1c4  li   t2, 8
  32'h00008067,  // [112] 0x1c0  ret
  32'h00100193,  // [111] 0x1bc  li   gp, 1
  32'h00019463,  // [110] 0x1b8  bnez gp, mez_1
  32'h0051c1b3,  // [109] 0x1b4  xor  gp, gp, t0
  32'h00c42283,  // [108] 0x1b0  lw   t0, CONTADOR(s0)
  32'h00008067,  // [107] 0x1ac  ret
  32'h00410113,  // [106] 0x1a8  addi sp, sp, 4
  32'h00012083,  // [105] 0x1a4  lw   ra, 0(sp)
  32'hfe0294e3,  // [104] 0x1a0  bnez t0, sol_1
  32'h00842283,  // [103] 0x19c  lw   t0, BOTONES(s0)
  32'hfb0080e7,  // [102] 0x198  call esperar
  32'h00000097,  // [101] 0x194  call esperar
  32'h00000513,  // [100] 0x190  li   a0, CICLOS_REBOTE
  32'hfe029ee3,  // [ 99] 0x18c  bnez t0, sol_1
  32'h00842283,  // [ 98] 0x188  lw   t0, BOTONES(s0)
  32'h00112023,  // [ 97] 0x184  sw   ra, 0(sp)
  32'hffc10113,  // [ 96] 0x180  addi sp, sp, -4
  32'h00008067,  // [ 95] 0x17c  ret
  32'h00030513,  // [ 94] 0x178  mv   a0, t1
  32'h00008067,  // [ 93] 0x174  ret
  32'h00000513,  // [ 92] 0x170  li   a0, 0
  32'hfea368e3,  // [ 91] 0x16c  bltu t1, a0, eob_1
  32'h40530333,  // [ 90] 0x168  sub  t1, t1, t0
  32'h00c42303,  // [ 89] 0x164  lw   t1, CONTADOR(s0)
  32'h00031c63,  // [ 88] 0x160  bnez t1, eob_2
  32'h00842303,  // [ 87] 0x15c  lw   t1, BOTONES(s0)
  32'h00c42283,  // [ 86] 0x158  lw   t0, CONTADOR(s0)
  32'h00008067,  // [ 85] 0x154  ret
  32'hfea36ce3,  // [ 84] 0x150  bltu t1, a0, esp_1
  32'h40530333,  // [ 83] 0x14c  sub  t1, t1, t0
  32'h00c42303,  // [ 82] 0x148  lw   t1, CONTADOR(s0)
  32'h00c42283,  // [ 81] 0x144  lw   t0, CONTADOR(s0)
  32'hef1ff06f,  // [ 80] 0x140  j    nueva_partida
  32'h048080e7,  // [ 79] 0x13c  call soltar_botones
  32'h00000097,  // [ 78] 0x138  call soltar_botones
  32'h080080e7,  // [ 77] 0x134  call mezclar_semilla
  32'h00000097,  // [ 76] 0x130  call mezclar_semilla
  32'hfe0506e3,  // [ 75] 0x12c  beqz a0, parpadeo_final
  32'h034080e7,  // [ 74] 0x128  call esperar_o_boton
  32'h00000097,  // [ 73] 0x124  call esperar_o_boton
  32'h00500513,  // [ 72] 0x120  li   a0, CICLOS_PARPADEO
  32'h00f74713,  // [ 71] 0x11c  xori a4, a4, 0b1111
  32'h00e42223,  // [ 70] 0x118  sw   a4, LEDS(s0)
  32'h00900713,  // [ 69] 0x114  li   a4, 0b1001
  32'h170080e7,  // [ 68] 0x110  call mostrar_decimas
  32'h00000097,  // [ 67] 0x10c  call mostrar_decimas
  32'h14c080e7,  // [ 66] 0x108  call promedio
  32'h00000097,  // [ 65] 0x104  call promedio
  32'h00020513,  // [ 64] 0x100  mv   a0, tp
  32'h04c080e7,  // [ 63] 0x0fc  call esperar
  32'h00000097,  // [ 62] 0x0f8  call esperar
  32'h01400513,  // [ 61] 0x0f4  li   a0, CICLOS_FINAL
  32'h00042223,  // [ 60] 0x0f0  sw   zero, LEDS(s0)
  32'hf51ff06f,  // [ 59] 0x0ec  j    ronda
  32'h060080e7,  // [ 58] 0x0e8  call esperar
  32'h00000097,  // [ 57] 0x0e4  call esperar
  32'h00a00513,  // [ 56] 0x0e0  li   a0, CICLOS_ERROR
  32'h0a8080e7,  // [ 55] 0x0dc  call soltar_botones
  32'h00000097,  // [ 54] 0x0d8  call soltar_botones
  32'h00042223,  // [ 53] 0x0d4  sw   zero, LEDS(s0)
  32'h00542023,  // [ 52] 0x0d0  sw   t0, DISPLAY(s0)
  32'h0ee00293,  // [ 51] 0x0cc  li   t0, ERROR_EE
  32'h0280006f,  // [ 50] 0x0c8  j    fin_partida
  32'hf654cce3,  // [ 49] 0x0c4  blt  s1, t0, ronda
  32'h00200293,  // [ 48] 0x0c0  li   t0, RONDAS
  32'h0c8080e7,  // [ 47] 0x0bc  call soltar_botones
  32'h00000097,  // [ 46] 0x0b8  call soltar_botones
  32'h00148493,  // [ 45] 0x0b4  addi s1, s1, 1
  32'h1d0080e7,  // [ 44] 0x0b0  call mostrar_decimas
  32'h00000097,  // [ 43] 0x0ac  call mostrar_decimas
  32'h00a20233,  // [ 42] 0x0a8  add  tp, tp, a0
  32'h184080e7,  // [ 41] 0x0a4  call ciclos_a_decimas
  32'h00000097,  // [ 40] 0x0a0  call ciclos_a_decimas
  32'h00078513,  // [ 39] 0x09c  mv   a0, a5
  32'h02b71a63,  // [ 38] 0x098  bne  a4, a1, ronda_error
  32'h120080e7,  // [ 37] 0x094  call mezclar_semilla
  32'h00000097,  // [ 36] 0x090  call mezclar_semilla
  32'h00038793,  // [ 35] 0x08c  mv   a5, t2
  32'h00028713,  // [ 34] 0x088  mv   a4, t0
  32'hfe0286e3,  // [ 33] 0x084  beqz t0, esperar_boton
  32'h00842283,  // [ 32] 0x080  lw   t0, BOTONES(s0)
  32'h40d30633,  // [ 31] 0x07c  sub  a2, t1, a3
  32'h00d3e463,  // [ 30] 0x078  bltu t2, a3, leer_botones
  32'h40c303b3,  // [ 29] 0x074  sub  t2, t1, a2
  32'h00c42303,  // [ 28] 0x070  lw   t1, CONTADOR(s0)
  32'h06300693,  // [ 27] 0x06c  li   a3, CICLOS_TOPE
  32'h00c42603,  // [ 26] 0x068  lw   a2, CONTADOR(s0)
  32'h00b42223,  // [ 25] 0x064  sw   a1, LEDS(s0)
  32'h00050593,  // [ 24] 0x060  mv   a1, a0
  32'h16c080e7,  // [ 23] 0x05c  call elegir_objetivo
  32'h00000097,  // [ 22] 0x058  call elegir_objetivo
  32'h130080e7,  // [ 21] 0x054  call soltar_botones
  32'h00000097,  // [ 20] 0x050  call soltar_botones
  32'h0fc080e7,  // [ 19] 0x04c  call esperar
  32'h00000097,  // [ 18] 0x048  call esperar
  32'h01e00513,  // [ 17] 0x044  li   a0, CICLOS_INICIO
  32'h00542223,  // [ 16] 0x040  sw   t0, LEDS(s0)
  32'h00f00293,  // [ 15] 0x03c  li   t0, 0b1111
  32'h00042023,  // [ 14] 0x038  sw   zero, DISPLAY(s0)
  32'h00000213,  // [ 13] 0x034  li   tp, 0
  32'h00000493,  // [ 12] 0x030  li   s1, 0
  32'h158080e7,  // [ 11] 0x02c  call soltar_botones
  32'h00000097,  // [ 10] 0x028  call soltar_botones
  32'h190080e7,  // [  9] 0x024  call mezclar_semilla
  32'h00000097,  // [  8] 0x020  call mezclar_semilla
  32'hfe028ee3,  // [  7] 0x01c  beqz t0, esperar_inicio
  32'h00842283,  // [  6] 0x018  lw   t0, BOTONES(s0)
  32'h00042023,  // [  5] 0x014  sw   zero, DISPLAY(s0)
  32'h00042223,  // [  4] 0x010  sw   zero, LEDS(s0)
  32'h00100193,  // [  3] 0x00c  li   gp, 1
  32'h80000437,  // [  2] 0x008  li   s0, PERIF
  32'h2b410113,  // [  1] 0x004  li   sp, fin_programa + 4 * PILA_PALABRAS
  32'h00000137   // [  0] 0x000  li   sp, fin_programa + 4 * PILA_PALABRAS
};
