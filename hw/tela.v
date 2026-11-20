// tela.v
// Escolhe a cor de cada pixel do monitor conforme o momento do jogo:
//   PLAY              -> tela azul
//   esperando (----)  -> tela vermelha (nao aperta!)
//   VAI (contando)    -> tela verde (aperta!)
//   CEdO              -> tela amarela
//   resultado (tempo) -> fundo preto com uma barra branca do tamanho do tempo
//
// Em cima da cor aparece o mesmo texto dos displays da placa, so que grande
// (4 digitos de 7 segmentos, um do lado do outro, no meio da tela).
//
// A barra tem 1 pixel a cada 16 ms (9999 ms da 625 pixels, cabe nos 640).

module tela (
    input  wire [1:0]  modo,       // mesmo modo do display (vem do Nios)
    input  wire        contando,   // 1 = cronometro contando (LEDs acesos)
    input  wire [15:0] tempo,      // tempo em BCD
    input  wire [6:0]  hex3, hex2, hex1, hex0,   // segmentos dos displays
    input  wire        ponto,      // ponto depois do primeiro digito (0 = aceso)
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire        visivel,
    output reg  [3:0]  r,
    output reg  [3:0]  g,
    output reg  [3:0]  b
);

    // ---- digitos grandes (linhas 150 a 329) ----
    wire aceso3, aceso2, aceso1, aceso0;

    digito_tela #(.X0(50),  .Y0(150)) dig3 (.x(x), .y(y), .seg(hex3), .aceso(aceso3));
    digito_tela #(.X0(190), .Y0(150)) dig2 (.x(x), .y(y), .seg(hex2), .aceso(aceso2));
    digito_tela #(.X0(330), .Y0(150)) dig1 (.x(x), .y(y), .seg(hex1), .aceso(aceso1));
    digito_tela #(.X0(470), .Y0(150)) dig0 (.x(x), .y(y), .seg(hex0), .aceso(aceso0));

    // ponto: quadradinho entre o primeiro e o segundo digito
    wire no_ponto = ~ponto && (x >= 162) && (x < 178) && (y >= 314) && (y < 330);

    wire texto = aceso3 | aceso2 | aceso1 | aceso0 | no_ponto;

    // ---- barra do tempo (linhas 380 a 409, embaixo dos digitos) ----
    // converte o tempo de BCD pra numero normal (ms)
    wire [13:0] ms = tempo[15:12] * 1000 + tempo[11:8] * 100 + tempo[7:4] * 10 + tempo[3:0];

    // x * 16 < ms  e o mesmo que  x < ms / 16
    wire na_barra = (y >= 380) && (y < 410) && ({x, 4'b0000} < ms);

    always @(*) begin
        if (!visivel) begin
            r = 0; g = 0; b = 0;                 // fora da tela: preto (obrigatorio)
        end
        else if (contando) begin
            if (texto) begin r = 0; g = 0;  b = 0; end   // texto preto
            else       begin r = 0; g = 15; b = 0; end   // verde: aperta!
        end
        else begin
            case (modo)
                1: begin                                 // PLAY: azul, texto branco
                    if (texto) begin r = 15; g = 15; b = 15; end
                    else       begin r = 0;  g = 0;  b = 15; end
                end
                2: begin                                 // esperando: vermelho, texto branco
                    if (texto) begin r = 15; g = 15; b = 15; end
                    else       begin r = 15; g = 0;  b = 0;  end
                end
                3: begin                                 // CEdO: amarelo, texto preto
                    if (texto) begin r = 0;  g = 0;  b = 0;  end
                    else       begin r = 15; g = 15; b = 0;  end
                end
                default: begin                           // tempo: texto e barra brancos
                    if (texto || na_barra) begin
                        r = 15; g = 15; b = 15;
                    end
                    else begin
                        r = 0; g = 0; b = 0;
                    end
                end
            endcase
        end
    end

endmodule
