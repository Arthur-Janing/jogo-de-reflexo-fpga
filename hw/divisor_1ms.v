// divisor_1ms.v
// Gera um pulso (tique) a cada 1 ms.
// O clock da DE10-Lite e 50 MHz, entao 1 ms = 50000 ciclos.
// So conta quando "ligado" = 1. Quando desliga, volta pra zero, assim
// a contagem sempre comeca certinha quando o cronometro e armado.

module divisor_1ms (
    input  wire clk,
    input  wire ligado,
    output reg  tique
);

    parameter CLOCKS_POR_MS = 50000;   // da pra diminuir na simulacao

    reg [15:0] contador = 0;

    initial tique = 0;

    always @(posedge clk) begin
        if (!ligado) begin
            contador <= 0;
            tique    <= 0;
        end
        else if (contador == CLOCKS_POR_MS - 1) begin
            contador <= 0;
            tique    <= 1;
        end
        else begin
            contador <= contador + 1;
            tique    <= 0;
        end
    end

endmodule
