// display.v
// Escolhe o que aparece nos 4 displays, conforme o modo que o Nios manda:
//   0 = tempo (ex: 0.243)
//   1 = PLAY
//   2 = ----  (esperando)
//   3 = CEdO  (apertou cedo)

module display (
    input  wire [1:0]  modo,
    input  wire [15:0] tempo,
    output reg  [6:0]  hex3, hex2, hex1, hex0,
    output reg         dp3, dp2, dp1, dp0
);

    // letras (0 = segmento aceso)
    localparam LETRA_P = 7'b0001100;
    localparam LETRA_L = 7'b1000111;
    localparam LETRA_A = 7'b0001000;
    localparam LETRA_Y = 7'b0010001;
    localparam LETRA_C = 7'b1000110;
    localparam LETRA_E = 7'b0000110;
    localparam LETRA_d = 7'b0100001;
    localparam LETRA_O = 7'b1000000;
    localparam TRACO   = 7'b0111111;

    wire [6:0] num3, num2, num1, num0;
    decod_7seg d3 (.digito(tempo[15:12]), .seg(num3));
    decod_7seg d2 (.digito(tempo[11:8]),  .seg(num2));
    decod_7seg d1 (.digito(tempo[7:4]),   .seg(num1));
    decod_7seg d0 (.digito(tempo[3:0]),   .seg(num0));

    always @(*) begin
        dp3 = 1; dp2 = 1; dp1 = 1; dp0 = 1;   // pontos apagados

        case (modo)
            0: begin
                hex3 = num3; hex2 = num2; hex1 = num1; hex0 = num0;
                dp3  = 0;   // ponto depois dos segundos
            end
            1: begin
                hex3 = LETRA_P; hex2 = LETRA_L; hex1 = LETRA_A; hex0 = LETRA_Y;
            end
            2: begin
                hex3 = TRACO; hex2 = TRACO; hex1 = TRACO; hex0 = TRACO;
            end
            default: begin
                hex3 = LETRA_C; hex2 = LETRA_E; hex1 = LETRA_d; hex0 = LETRA_O;
            end
        endcase
    end

endmodule
