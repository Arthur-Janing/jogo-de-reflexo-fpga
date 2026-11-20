// reflexo_top.v
// Top level do projeto: liga o Nios II (gerado no Platform Designer) com os
// nossos modulos e com os pinos da DE10-Lite.
//
// KEY0 = botao do jogo
// KEY1 = apaga recorde/ranking
// VGA  = tela colorida mostrando o momento do jogo (opcional, funciona sem monitor)

module reflexo_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,
    output wire [9:0] LEDR,
    output wire [7:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,  // bit 7 = ponto
    output wire [3:0] VGA_R, VGA_G, VGA_B,
    output wire       VGA_HS, VGA_VS
);

    // fios entre o Nios e o nosso hardware (PIOs)
    wire [1:0]  comando;   // bit0 = armar, bit1 = zerar
    wire [1:0]  modo;
    wire [15:0] tempo;
    wire [11:0] numero;
    wire        parado;
    wire        tique;

    // sincronizador do botao (2 flip-flops) e inversao (KEY e ativo em 0)
    reg botao_a = 0;
    reg botao_b = 0;
    always @(posedge MAX10_CLK1_50) begin
        botao_a <= ~KEY[0];
        botao_b <= botao_a;
    end

    // sistema do Nios II (gerado pelo Platform Designer)
    sistema_nios u_nios (
        .clk_clk        (MAX10_CLK1_50),
        .reset_reset_n  (1'b1),          // os 2 botoes sao usados pelo jogo
        .botoes_export  (KEY),
        .leds_export    (LEDR),
        .comando_export (comando),
        .modo_export    (modo),
        .tempo_export   (tempo),
        .sorteio_export (numero)
    );

    divisor_1ms u_divisor (
        .clk    (MAX10_CLK1_50),
        .ligado (comando[0] & ~parado),   // so conta enquanto esta medindo
        .tique  (tique)
    );

    cronometro_ms u_cronometro (
        .clk    (MAX10_CLK1_50),
        .tique  (tique),
        .zerar  (comando[1]),
        .armar  (comando[0]),
        .botao  (botao_b),
        .tempo  (tempo),
        .parado (parado)
    );

    sorteio u_sorteio (
        .clk    (MAX10_CLK1_50),
        .numero (numero)
    );

    // usamos os 4 displays da direita (HEX3..HEX0)
    wire [6:0] h3, h2, h1, h0;
    wire       p3, p2, p1, p0;

    display u_display (
        .modo  (modo),
        .tempo (tempo),
        .hex3  (h3), .hex2 (h2), .hex1 (h1), .hex0 (h0),
        .dp3   (p3), .dp2  (p2), .dp1  (p1), .dp0  (p0)
    );

    assign HEX0 = {p0, h0};
    assign HEX1 = {p1, h1};
    assign HEX2 = {p2, h2};
    assign HEX3 = {p3, h3};
    assign HEX4 = 8'hFF;   // apagado
    assign HEX5 = 8'hFF;   // apagado

    // monitor VGA
    wire       pixel_en;
    wire [9:0] x, y;
    wire       visivel;

    vga_sync u_vga (
        .clk      (MAX10_CLK1_50),
        .pixel_en (pixel_en),
        .x        (x),
        .y        (y),
        .visivel  (visivel),
        .hsync    (VGA_HS),
        .vsync    (VGA_VS)
    );

    tela u_tela (
        .modo     (modo),
        .contando (comando[0] & ~parado),
        .tempo    (tempo),
        .hex3     (h3), .hex2 (h2), .hex1 (h1), .hex0 (h0),
        .ponto    (p3),
        .x        (x),
        .y        (y),
        .visivel  (visivel),
        .r        (VGA_R),
        .g        (VGA_G),
        .b        (VGA_B)
    );

endmodule
