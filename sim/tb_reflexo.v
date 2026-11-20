// tb_reflexo.v
// Testbench do jogo. Usa o reflexo_top com um Nios falso e testa:
// medida de 243,5 ms, tempo congelado, zerar, botao desarmado,
// displays, limite de 9.999 e o sorteio.
//
// iverilog -o tb sim/*.v hw/divisor_1ms.v hw/cronometro_ms.v hw/sorteio.v hw/decod_7seg.v hw/display.v hw/vga_sync.v hw/tela.v hw/reflexo_top.v
// vvp tb

`timescale 1ns/1ps
module tb_reflexo;

    reg clk = 0;
    always #10 clk = ~clk;                     // 50 MHz

    reg  [1:0] KEY = 2'b11;                   // nenhum botao apertado
    wire [9:0] LEDR;
    wire [7:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire [3:0] VGA_R, VGA_G, VGA_B;
    wire       VGA_HS, VGA_VS;

    reflexo_top dut (
        .MAX10_CLK1_50(clk), .KEY(KEY), .LEDR(LEDR),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS)
    );

    integer erros = 0;

    task confere_tempo(input [15:0] esperado, input [255:0] nome); begin
        if (dut.tempo === esperado)
            $display("  ok   %0s: tempo = %h", nome, dut.tempo);
        else begin
            $display("  ERRO %0s: tempo = %h, esperado %h", nome, dut.tempo, esperado);
            erros = erros + 1;
        end
    end endtask

    task confere_display(input [6:0] h3, h2, h1, h0, input ponto, input [255:0] nome); begin
        #1;
        if (HEX3[6:0] === h3 && HEX2[6:0] === h2 && HEX1[6:0] === h1 && HEX0[6:0] === h0 && HEX3[7] === ponto && HEX4 === 8'hFF && HEX5 === 8'hFF)
            $display("  ok   display %0s", nome);
        else begin
            $display("  ERRO display %0s: %b %b %b %b %b %b", nome, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);
            erros = erros + 1;
        end
    end endtask

    // cronometro com divisor rapido so pra testar o limite 9.999
    wire        tique_rapido, parado_r;
    wire [15:0] tempo_r;
    divisor_1ms #(.CLOCKS_POR_MS(2)) div_rapido (.clk(clk), .ligado(1'b1), .tique(tique_rapido));
    cronometro_ms crono_r (.clk(clk), .tique(tique_rapido), .zerar(1'b0), .armar(1'b1),
                           .botao(1'b0), .tempo(tempo_r), .parado(parado_r));

    initial begin
        $display("== Teste 1: reacao de 243,5 ms ==");
        dut.u_nios.comando = 2'b10;  #100;     // zerar
        dut.u_nios.comando = 2'b01;            // armar
        #243_500_000;                          // espera 243,5 ms
        KEY[0] = 0;                         // jogador aperta
        #1_000_000;                            // segura 1 ms
        confere_tempo(16'h0243, "tempo medido");

        $display("== Teste 2: tempo fica congelado ==");
        KEY[0] = 1;                         // solta
        #50_000_000;                           // espera mais 50 ms
        confere_tempo(16'h0243, "depois de soltar");
        if (dut.parado !== 1) begin $display("  ERRO: parado deveria ser 1"); erros = erros + 1; end

        $display("== Teste 3: zerar ==");
        dut.u_nios.comando = 2'b10;  #100;
        dut.u_nios.comando = 2'b00;  #100;
        confere_tempo(16'h0000, "depois de zerar");

        $display("== Teste 4: apertar desarmado nao faz nada ==");
        KEY[0] = 0;  #20_000_000;  KEY[0] = 1;
        #1000;   // espera o sincronizador (2 clocks)
        confere_tempo(16'h0000, "botao com cronometro desarmado");

        $display("== Teste 5: displays ==");
        dut.u_nios.modo = 1; confere_display(7'b0001100, 7'b1000111, 7'b0001000, 7'b0010001, 1, "PLAY");
        dut.u_nios.modo = 2; confere_display(7'b0111111, 7'b0111111, 7'b0111111, 7'b0111111, 1, "----");
        dut.u_nios.modo = 3; confere_display(7'b1000110, 7'b0000110, 7'b0100001, 7'b1000000, 1, "CEdO");
        dut.u_nios.comando = 2'b01; #243_500_000; KEY[0] = 0; #1_000_000; KEY[0] = 1;
        dut.u_nios.modo = 0; confere_display(7'b1000000, 7'b0100100, 7'b0011001, 7'b0110000, 0, "0.243");

        $display("== Teste 6: tempo maximo ==");
        if (tempo_r === 16'h9999)
            $display("  ok   parou em 9.999");
        else begin
            $display("  ERRO limite: %h", tempo_r); erros = erros + 1;
        end

        $display("== Teste 7: sorteio esta girando ==");
        begin : sorteio_teste
            reg [11:0] a; a = dut.numero; #100;
            if (dut.numero !== a) $display("  ok   numero mudou (%0d -> %0d)", a, dut.numero);
            else begin $display("  ERRO: sorteio parado"); erros = erros + 1; end
        end

        if (erros == 0) $display(">>> TODOS OS TESTES PASSARAM");
        else            $display(">>> %0d ERRO(S)", erros);
        $finish;
    end

endmodule
