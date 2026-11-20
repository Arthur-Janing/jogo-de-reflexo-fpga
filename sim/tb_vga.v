// tb_vga.v
// Testa o VGA: tempo de uma linha, linhas por tela e as cores da tela.
//
// Pra rodar no ModelSim: do sim/simular.do

`timescale 1ns/1ps
module tb_vga;

    reg clk = 0;
    always #10 clk = ~clk;   // 50 MHz

    wire       pixel_en, visivel, hs, vs;
    wire [9:0] x, y;

    vga_sync u_vga (.clk(clk), .pixel_en(pixel_en), .x(x), .y(y),
                    .visivel(visivel), .hsync(hs), .vsync(vs));

    // a tela e testada com x e y escolhidos aqui
    reg  [1:0]  modo = 0;
    reg         contando = 0;
    reg  [15:0] tempo = 0;
    reg  [9:0]  tx = 0, ty = 0;
    reg         tvis = 1;
    wire [3:0]  r, g, b;

    // os segmentos vem do mesmo modulo que controla os displays da placa
    wire [6:0] h3, h2, h1, h0;
    wire       p3, p2, p1, p0;
    display u_display (.modo(modo), .tempo(tempo),
                       .hex3(h3), .hex2(h2), .hex1(h1), .hex0(h0),
                       .dp3(p3), .dp2(p2), .dp1(p1), .dp0(p0));

    tela u_tela (.modo(modo), .contando(contando), .tempo(tempo),
                 .hex3(h3), .hex2(h2), .hex1(h1), .hex0(h0), .ponto(p3),
                 .x(tx), .y(ty), .visivel(tvis), .r(r), .g(g), .b(b));

    integer erros = 0;

    task confere_cor(input [11:0] esperado, input [255:0] nome); begin
        #1;
        if ({r, g, b} === esperado)
            $display("  ok   %0s", nome);
        else begin
            $display("  ERRO %0s: cor = %h, esperado %h", nome, {r, g, b}, esperado);
            erros = erros + 1;
        end
    end endtask

    realtime t1, t2;
    integer linhas;

    initial begin
        $display("== Teste do VGA ==");

        // tempo de uma linha: 800 pixels de 40 ns = 32 us
        @(negedge hs); t1 = $realtime;
        @(negedge hs); t2 = $realtime;
        if (t2 - t1 == 32000) $display("  ok   linha = %0.0f ns", t2 - t1);
        else begin $display("  ERRO linha = %0.0f ns", t2 - t1); erros = erros + 1; end

        // pulso do hsync: 96 pixels = 3840 ns
        @(negedge hs); t1 = $realtime;
        @(posedge hs); t2 = $realtime;
        if (t2 - t1 == 3840) $display("  ok   pulso hsync = %0.0f ns", t2 - t1);
        else begin $display("  ERRO pulso hsync = %0.0f ns", t2 - t1); erros = erros + 1; end

        // linhas por tela: 525 (conta os hsync entre dois vsync)
        @(negedge vs);
        linhas = 0;
        fork : contagem
            forever begin @(negedge hs); linhas = linhas + 1; end
            begin @(negedge vs); disable contagem; end
        join
        if (linhas == 525) $display("  ok   %0d linhas por tela (60 Hz)", linhas);
        else begin $display("  ERRO %0d linhas por tela", linhas); erros = erros + 1; end

        // cores do fundo (ponto fora dos digitos)
        tx = 100; ty = 100;
        modo = 1;                 confere_cor(12'h00F, "PLAY = azul");
        modo = 2;                 confere_cor(12'hF00, "esperando = vermelho");
        contando = 1;             confere_cor(12'h0F0, "contando = verde");
        contando = 0; modo = 3;   confere_cor(12'hFF0, "CEdO = amarelo");

        // digitos grandes: o primeiro digito fica em x 50..149, y 150..329
        // (100, 155) = segmento a      (100, 240) = segmento g (meio)
        modo = 1; tx = 100; ty = 155;  confere_cor(12'hFFF, "P: segmento a branco");
        modo = 2; tx = 100; ty = 155;  confere_cor(12'hF00, "traco: segmento a apagado");
                  tx = 100; ty = 240;  confere_cor(12'hFFF, "traco: segmento g branco");
        contando = 1;                  confere_cor(12'h000, "contando: traco preto");
        contando = 0;
        modo = 3; tx = 100; ty = 155;  confere_cor(12'h000, "C: segmento a preto");
                  tx = 100; ty = 240;  confere_cor(12'hFF0, "C: segmento g apagado");

        // resultado 0.243: primeiro digito e 0 (sem o g) e tem o ponto
        modo = 0; tempo = 16'h0243;
        tx = 100; ty = 155;       confere_cor(12'hFFF, "0: segmento a branco");
        tx = 100; ty = 240;       confere_cor(12'h000, "0: segmento g apagado");
        tx = 170; ty = 320;       confere_cor(12'hFFF, "ponto depois do 0");
        modo = 1;                 confere_cor(12'h00F, "PLAY sem ponto");
        modo = 0;

        // barra: 243 ms -> 243/16 = 15 pixels (x de 0 a 15), linhas 380 a 409
        tx = 10;  ty = 390;       confere_cor(12'hFFF, "barra branca em x=10");
        tx = 20;  ty = 390;       confere_cor(12'h000, "fim da barra em x=20");
        tx = 10;  ty = 100;       confere_cor(12'h000, "fora da faixa da barra");
        tempo = 16'h9999;
        tx = 620; ty = 390;       confere_cor(12'hFFF, "9999 ms chega em x=620");
        tvis = 0; modo = 1;       confere_cor(12'h000, "fora da area visivel = preto");

        if (erros == 0) $display(">>> TODOS OS TESTES DO VGA PASSARAM");
        else            $display(">>> %0d ERRO(S)", erros);
        $finish;
    end

endmodule
