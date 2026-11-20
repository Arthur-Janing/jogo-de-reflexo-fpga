// sistema_nios_falso.v
// So pra simulacao: substitui o sistema do Platform Designer, com as mesmas portas.
// Os valores sao controlados pelo testbench. Nao vai pro Quartus.

module sistema_nios (
    input  wire        clk_clk,
    input  wire        reset_reset_n,
    input  wire [1:0]  botoes_export,
    output wire [9:0]  leds_export,
    output wire [1:0]  comando_export,
    output wire [1:0]  modo_export,
    input  wire [15:0] tempo_export,
    input  wire [11:0] sorteio_export
);
    reg [9:0] leds    = 0;
    reg [1:0] comando = 0;
    reg [1:0] modo    = 1;

    assign leds_export    = leds;
    assign comando_export = comando;
    assign modo_export    = modo;
endmodule
