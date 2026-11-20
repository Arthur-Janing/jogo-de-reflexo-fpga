// sorteio.v
// Contador de 12 bits girando a 50 MHz (0 a 4095).
// O Nios le esse valor na hora que o jogador aperta pra comecar,
// como ninguem consegue apertar sempre no mesmo instante o numero
// sai "aleatorio". Usamos pra decidir quanto tempo esperar.

module sorteio (
    input  wire        clk,
    output reg  [11:0] numero
);

    initial numero = 0;

    always @(posedge clk) begin
        numero <= numero + 1;
    end

endmodule
