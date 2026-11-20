// vga_sync.v
// Gera os sinais do VGA 640x480 a 60 Hz.
// A tela e desenhada pixel por pixel, linha por linha:
//   cada linha tem 800 pixels (640 aparecem + 160 de pausa e sincronismo)
//   cada tela tem 525 linhas (480 aparecem + 45 de pausa e sincronismo)
// O pixel e de 25 MHz, entao usamos o clock de 50 MHz dividido por 2
// (pixel_en vale 1 em um clock sim, um nao).

module vga_sync (
    input  wire       clk,        // 50 MHz
    output reg        pixel_en,   // 1 a cada 2 clocks
    output reg  [9:0] x,          // coluna (0 a 799)
    output reg  [9:0] y,          // linha (0 a 524)
    output wire       visivel,    // 1 = dentro da area de 640x480
    output wire       hsync,
    output wire       vsync
);

    initial begin
        pixel_en = 0;
        x = 0;
        y = 0;
    end

    always @(posedge clk) begin
        pixel_en <= ~pixel_en;
    end

    always @(posedge clk) begin
        if (pixel_en) begin
            if (x == 799) begin
                x <= 0;
                if (y == 524)
                    y <= 0;
                else
                    y <= y + 1;
            end
            else begin
                x <= x + 1;
            end
        end
    end

    assign visivel = (x < 640) && (y < 480);

    // pulsos de sincronismo (ativos em 0)
    // horizontal: 640 visivel + 16 + 96 de pulso + 48
    // vertical:   480 visivel + 10 + 2 de pulso + 33
    assign hsync = ~((x >= 656) && (x < 752));
    assign vsync = ~((y >= 490) && (y < 492));

endmodule
