// digito_tela.v
// Desenha um digito de 7 segmentos grande no monitor.
// Recebe o mesmo padrao de segmentos que vai pro display da placa
// (0 = aceso, ordem g f e d c b a) e diz se o pixel (x, y) cai
// em cima de um segmento aceso.
//
// Cada digito ocupa 100 x 180 pixels e cada segmento tem 16 de grossura:
//
//     aaaaaa
//    f      b
//    f      b
//     gggggg
//    e      c
//    e      c
//     dddddd

module digito_tela #(
    parameter X0 = 0,       // canto esquerdo do digito
    parameter Y0 = 0        // canto de cima do digito
) (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [6:0] seg,
    output wire       aceso
);

    // posicao do pixel dentro do digito
    wire [9:0] dx = x - X0;
    wire [9:0] dy = y - Y0;

    wire dentro = (x >= X0) && (x < X0 + 100) && (y >= Y0) && (y < Y0 + 180);

    // regiao de cada segmento
    wire seg_a = (dy < 16);
    wire seg_g = (dy >= 82) && (dy < 98);
    wire seg_d = (dy >= 164);
    wire seg_f = (dx < 16)  && (dy < 90);
    wire seg_b = (dx >= 84) && (dy < 90);
    wire seg_e = (dx < 16)  && (dy >= 90);
    wire seg_c = (dx >= 84) && (dy >= 90);

    // o segmento so aparece se estiver aceso (bit em 0)
    assign aceso = dentro && ( (seg_a & ~seg[0]) | (seg_b & ~seg[1]) | (seg_c & ~seg[2]) |
                               (seg_d & ~seg[3]) | (seg_e & ~seg[4]) | (seg_f & ~seg[5]) |
                               (seg_g & ~seg[6]) );

endmodule
