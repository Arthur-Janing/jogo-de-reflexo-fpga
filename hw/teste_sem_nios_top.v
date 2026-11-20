// teste_sem_nios_top.v
// Top pra testar o hardware sem o Nios, usando as chaves:
//   SW0 = armar, SW1 = zerar, SW9..SW8 = modo do display
//   KEY0 = para o tempo
// LEDR0 = contando, LEDR1 = parado

module teste_sem_nios_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,
    input  wire [9:0] SW,
    output wire [9:0] LEDR,
    output wire [7:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

    reg botao_a = 0;
    reg botao_b = 0;
    always @(posedge MAX10_CLK1_50) begin
        botao_a <= ~KEY[0];
        botao_b <= botao_a;
    end

    wire        tique, parado;
    wire [15:0] tempo;

    divisor_1ms u_divisor (.clk(MAX10_CLK1_50), .ligado(SW[0] & ~parado), .tique(tique));

    cronometro_ms u_cronometro (
        .clk(MAX10_CLK1_50), .tique(tique), .zerar(SW[1]), .armar(SW[0]),
        .botao(botao_b), .tempo(tempo), .parado(parado)
    );

    wire [6:0] h3, h2, h1, h0;
    wire       p3, p2, p1, p0;

    display u_display (
        .modo(SW[9:8]), .tempo(tempo),
        .hex3(h3), .hex2(h2), .hex1(h1), .hex0(h0),
        .dp3(p3), .dp2(p2), .dp1(p1), .dp0(p0)
    );

    assign HEX0 = {p0, h0};
    assign HEX1 = {p1, h1};
    assign HEX2 = {p2, h2};
    assign HEX3 = {p3, h3};
    assign HEX4 = 8'hFF;
    assign HEX5 = 8'hFF;

    assign LEDR = {8'b0, parado, SW[0] & ~parado};

endmodule
