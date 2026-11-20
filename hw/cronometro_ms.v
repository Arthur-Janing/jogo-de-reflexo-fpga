// cronometro_ms.v
// Conta o tempo de reacao em ms, de 0.000 ate 9.999 s.
// Os digitos ficam em BCD (4 bits por digito) pra ir direto pro display.
//
// zerar = 1  -> volta pra 0.000
// armar = 1  -> comeca a contar
// botao = 1  -> para o tempo (quem para e o hardware, nao o C)

module cronometro_ms (
    input  wire        clk,
    input  wire        tique,     // pulso de 1 ms
    input  wire        zerar,
    input  wire        armar,
    input  wire        botao,
    output reg  [15:0] tempo,     // {seg, cen, dez, uni}
    output reg         parado     // 1 = jogador ja apertou
);

    reg [3:0] seg;   // segundos
    reg [3:0] cen;   // centenas de ms
    reg [3:0] dez;   // dezenas de ms
    reg [3:0] uni;   // unidades de ms

    initial begin
        seg = 0; cen = 0; dez = 0; uni = 0;
        parado = 0;
    end

    always @(posedge clk) begin
        if (zerar) begin
            seg <= 0; cen <= 0; dez <= 0; uni <= 0;
            parado <= 0;
        end
        else if (armar && !parado) begin
            if (botao) begin
                parado <= 1;              // congela o tempo
            end
            else if (tique) begin
                // soma 1 ms (igual hodometro: passou de 9 vai um)
                if (seg == 9 && cen == 9 && dez == 9 && uni == 9) begin
                    // chegou no maximo, nao faz nada
                end
                else if (uni != 9) begin
                    uni <= uni + 1;
                end
                else begin
                    uni <= 0;
                    if (dez != 9) begin
                        dez <= dez + 1;
                    end
                    else begin
                        dez <= 0;
                        if (cen != 9) begin
                            cen <= cen + 1;
                        end
                        else begin
                            cen <= 0;
                            seg <= seg + 1;
                        end
                    end
                end
            end
        end
    end

    always @(*) begin
        tempo = {seg, cen, dez, uni};
    end

endmodule
