// decod_7seg.v
// Converte um digito (0-9) pros 7 segmentos.
// Na DE10-Lite o segmento acende com 0. Ordem dos bits: g f e d c b a

module decod_7seg (
    input  wire [3:0] digito,
    output reg  [6:0] seg
);

    always @(*) begin
        case (digito)
            0: seg = 7'b1000000;
            1: seg = 7'b1111001;
            2: seg = 7'b0100100;
            3: seg = 7'b0110000;
            4: seg = 7'b0011001;
            5: seg = 7'b0010010;
            6: seg = 7'b0000010;
            7: seg = 7'b1111000;
            8: seg = 7'b0000000;
            9: seg = 7'b0010000;
            default: seg = 7'b1111111;   // apagado
        endcase
    end

endmodule
