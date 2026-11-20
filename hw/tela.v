// tela.v
// Escolhe a cor de cada pixel do monitor conforme o momento do jogo:
//   PLAY              -> tela azul
//   esperando (----)  -> tela vermelha (nao aperta!)
//   VAI (contando)    -> tela verde (aperta!)
//   CEdO              -> tela amarela
//   resultado (tempo) -> fundo preto com uma barra branca do tamanho do tempo
//
// A barra tem 1 pixel a cada 16 ms (9999 ms da 625 pixels, cabe nos 640).

module tela (
    input  wire [1:0]  modo,       // mesmo modo do display (vem do Nios)
    input  wire        contando,   // 1 = cronometro contando (LEDs acesos)
    input  wire [15:0] tempo,      // tempo em BCD
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire        visivel,
    output reg  [3:0]  r,
    output reg  [3:0]  g,
    output reg  [3:0]  b
);

    // converte o tempo de BCD pra numero normal (ms)
    wire [13:0] ms = tempo[15:12] * 1000 + tempo[11:8] * 100 + tempo[7:4] * 10 + tempo[3:0];

    // a barra fica no meio da tela (linhas 200 a 279)
    // x * 16 < ms  e o mesmo que  x < ms / 16
    wire na_barra = (y >= 200) && (y < 280) && ({x, 4'b0000} < ms);

    always @(*) begin
        if (!visivel) begin
            r = 0; g = 0; b = 0;                 // fora da tela: preto (obrigatorio)
        end
        else if (contando) begin
            r = 0; g = 15; b = 0;                // verde: aperta!
        end
        else begin
            case (modo)
                1: begin r = 0;  g = 0;  b = 15; end   // PLAY: azul
                2: begin r = 15; g = 0;  b = 0;  end   // esperando: vermelho
                3: begin r = 15; g = 15; b = 0;  end   // CEdO: amarelo
                default: begin                         // tempo: barra
                    if (na_barra) begin
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
