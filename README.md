# Jogo de Reflexo na FPGA (DE10-Lite + Nios II)

Trabalho da disciplina: um jogo de tempo de reação feito na placa DE10-Lite. Você aperta o botão pra começar, espera os LEDs acenderem e aperta de novo o mais rápido possível. O tempo aparece no display em milissegundos e o programa guarda o recorde e um ranking com os 5 melhores tempos.

A parte que mede o tempo foi feita em Verilog, e as regras do jogo rodam num processador Nios II (soft processor) dentro da FPGA, programado em C.

## Como jogar

- O display mostra `PLAY`. Aperte o **KEY0** pra começar.
- O display mostra `----`. Espere: depois de 1 a 5 segundos (sorteado) todos os LEDs acendem.
- Quando os LEDs acenderem, aperte o KEY0 o mais rápido que conseguir.
- O display mostra seu tempo, por exemplo `0.243` (243 ms).
- Se apertar antes dos LEDs acenderem, aparece `CEdO` e a rodada não vale.
- **KEY1** apaga o recorde e o ranking.
- Quando sai um recorde novo, os LEDs piscam 3 vezes.

Se tiver um monitor ligado na saída VGA da placa, a tela muda de cor junto com o jogo (não é obrigatório, o jogo funciona sem monitor):

- azul: `PLAY`
- vermelho: esperando, não aperta
- verde: aperta!
- amarelo: `CEdO`
- preto com uma barra branca: o tamanho da barra é o tempo (quanto menor, melhor)

No computador, o terminal do Nios mostra os tempos e o ranking:

```
Rodada 3: espere os LEDs acenderem...
Seu tempo: 0.180 s
*** NOVO RECORDE! ***
------ RANKING ------
1. 0.180 s  (rodada 3)
2. 0.250 s  (rodada 1)
---------------------
```

## Requisitos do trabalho

1. **Ter um hard ou soft processor:** usamos o Nios II/e, que é um soft processor montado dentro da FPGA pelo Platform Designer. Ele roda o `sw/main.c`.
2. **Relatório no GitHub com passo a passo:** é este README.
3. **Apresentação pra turma:** vamos apresentar jogando ao vivo.

A maior parte do projeto está em Verilog (pasta `hw`). O C só cuida das regras do jogo.

## Como funciona

A ideia foi dividir assim:

- **Hardware (Verilog):** mede o tempo com precisão de 1 ms e para o tempo no exato momento em que o botão é apertado. Também sorteia o número da espera e controla os displays.
- **Nios II (C):** espera o tempo sorteado, vê se o jogador apertou cedo, acende os LEDs, lê o tempo medido e atualiza recorde e ranking.

Fizemos a medição em hardware porque assim o tempo para no mesmo clock em que o botão é apertado (20 ns a 50 MHz), sem depender do programa.

### Módulos em Verilog (`hw/`)

- `divisor_1ms.v`: conta 50.000 clocks e gera um pulso a cada 1 ms. Só conta enquanto o cronômetro está medindo, pra começar sempre do zero.
- `cronometro_ms.v`: soma 1 a cada ms, em BCD (um dígito decimal a cada 4 bits), de 0.000 até 9.999 s. Quando o botão é apertado, ele congela o tempo.
- `sorteio.v`: um contador de 12 bits que fica girando a 50 MHz. O Nios lê o valor dele na hora que o jogador aperta pra começar, então o número sai diferente toda vez.
- `decod_7seg.v`: converte um dígito pros 7 segmentos.
- `display.v`: escolhe o que aparece no display (tempo, `PLAY`, `----` ou `CEdO`). Usamos os 4 displays da direita, o HEX5 e o HEX4 ficam apagados.
- `vga_sync.v`: gera o sincronismo do VGA em 640x480 a 60 Hz. O pixel é de 25 MHz, então ele anda um pixel a cada 2 clocks de 50 MHz.
- `tela.v`: escolhe a cor de cada pixel conforme o momento do jogo. Na hora do resultado desenha uma barra com 1 pixel a cada 16 ms.
- `reflexo_top.v`: liga tudo nos pinos da placa. Também tem um sincronizador de 2 flip-flops no botão, porque o botão é um sinal externo e pode mudar a qualquer momento.
- `teste_sem_nios_top.v`: um top só pra testar o hardware sem o Nios, usando as chaves.

### Ligação entre o Nios e o Verilog

O Nios conversa com o nosso hardware por PIOs (registradores do Platform Designer). No C, cada PIO é um endereço de memória: a gente escreve com `IOWR_ALTERA_AVALON_PIO_DATA` e lê com `IORD_ALTERA_AVALON_PIO_DATA`.

| PIO | Direção | Bits | Uso |
|---|---|---|---|
| botoes | entrada | 2 | KEY1 e KEY0 |
| leds | saída | 10 | LEDR9..LEDR0 |
| comando | saída | 2 | bit 0 = armar, bit 1 = zerar |
| modo | saída | 2 | 0 = tempo, 1 = PLAY, 2 = ----, 3 = CEdO |
| tempo | entrada | 16 | tempo medido em BCD |
| sorteio | entrada | 12 | número sorteado |

### Uma rodada

1. O C mostra `PLAY` e espera o KEY0.
2. Lê o `sorteio` e calcula a espera: 1000 ms + número (de 1 a 5,1 s).
3. Mostra `----`, zera o cronômetro e espera. Se apertarem antes, mostra `CEdO`.
4. Acende os LEDs e arma o cronômetro.
5. O hardware conta os ms e para sozinho quando o botão é apertado.
6. O C lê o tempo, mostra no display e atualiza recorde e ranking.

## Arquivos

```
hw/          Verilog
sw/main.c    programa do Nios II
sim/         testbench (simulação)
quartus/     scripts do Platform Designer e do Quartus, pinos e clock
MONTAR.bat   compila tudo
JOGAR.bat    grava a placa e roda o jogo
```

## O que precisa

- Quartus Prime Lite 18.1, com o suporte ao MAX 10 (o Nios II EDS já vem junto)
- Placa DE10-Lite (chip 10M50DAF484C7G) e cabo USB
- Driver do USB-Blaster (fica em `C:\intelFPGA_lite\18.1\quartus\drivers\usb-blaster`)

Usamos a versão 18.1 porque ela suporta a DE10-Lite (MAX 10) e é a última em que o Nios II funciona no Windows sem precisar instalar o WSL.

## Passo a passo

### Jeito rápido

O projeto tem que estar em `C:\projetos\jogo-de-reflexo`.

1. Dois cliques no `MONTAR.bat`. Ele monta o Nios no Platform Designer, compila no Quartus e compila o C. Demora alguns minutos e não precisa da placa. A saída fica em `montar_log.txt`.
2. Liga a DE10-Lite no USB e dá dois cliques no `JOGAR.bat`. Ele grava a placa, carrega o programa e abre o terminal com o ranking.

Se mudar algum `.v`, apaga o `quartus/reflexo.sof` antes de rodar o `MONTAR.bat` de novo, senão ele pula o Quartus.

### Passo a passo manual (pelo Quartus)

É o que os scripts fazem, mas pelas telas do Quartus.

**1. Criar o projeto**

- File > New Project Wizard. Pasta `quartus`, nome `reflexo`.
- Family: MAX 10, Device: 10M50DAF484C7G.
- Adicionar os arquivos `hw/divisor_1ms.v`, `cronometro_ms.v`, `decod_7seg.v`, `display.v`, `teste_sem_nios_top.v` e o `quartus/restricoes.sdc`.
- Tools > Tcl Scripts > `quartus/pinos_de10lite.tcl` > Run, pra colocar os pinos.
- Em Assignments > Device > Device and Pin Options > Configuration, colocar o modo "Single Uncompressed Image with Memory Initialization" (precisa pra RAM do Nios).

**2. Testar o hardware sem o Nios**

- Top-level: `teste_sem_nios_top`. Processing > Start Compilation.
- Tools > Programmer > Hardware Setup: USB-Blaster > Start.
- Testar com as chaves: SW9 e SW8 mudam o display (`PLAY`, `----`, `CEdO`), SW1 zera, SW0 começa a contar e o KEY0 para o tempo.

**3. Montar o Nios II no Platform Designer**

Tools > Platform Designer. Adicionar estes componentes com estes nomes (o C usa esses nomes):

- `cpu`: Nios II Processor, versão Nios II/e
- `memoria`: On-Chip Memory, RAM de 32768 bytes (desmarcar "Initialize memory content")
- `jtag_uart`: JTAG UART
- `sysid`: System ID Peripheral
- PIOs: `botoes` (entrada, 2 bits), `leds` (saída, 10), `comando` (saída, 2), `modo` (saída, 2), `tempo` (entrada, 16), `sorteio` (entrada, 12)

Ligações:

- `clk_0.clk` no clock de todos, e `clk_0.clk_reset` e `cpu.debug_reset_request` no reset de todos.
- `cpu.data_master` em todos os escravos (`memoria.s1`, `cpu.debug_mem_slave`, `jtag_uart`, `sysid` e os PIOs).
- `cpu.instruction_master` na `memoria.s1` e no `cpu.debug_mem_slave`.
- IRQ da `jtag_uart` no `cpu`.
- No `cpu`, Reset Vector e Exception Vector na `memoria.s1`.
- Exportar `clk_in` como `clk`, `clk_in_reset` como `reset` e o `external_connection` de cada PIO com o nome do PIO.
- System > Assign Base Addresses. Salvar como `sistema_nios.qsys` e gerar em Verilog (Generation > Generate).

**4. Compilar o projeto completo**

- Adicionar o `sistema_nios/synthesis/sistema_nios.qip`, o `hw/sorteio.v`, o `hw/vga_sync.v`, o `hw/tela.v` e o `hw/reflexo_top.v`, e tirar o `teste_sem_nios_top.v`.
- Top-level: `reflexo_top`. Compilar e gravar com o Programmer.

**5. Programa do Nios**

- Tools > Nios II Software Build Tools for Eclipse.
- File > New > Nios II Application and BSP from Template, usando o `sistema_nios.sopcinfo` e o template Hello World Small.
- Trocar o `hello_world_small.c` pelo `sw/main.c`, compilar (Build Project) e rodar (Run As > Nios II Hardware).

## Testes

**Simulação** (`sim/tb_reflexo.v`, rodado no Icarus Verilog):

- apertando o botão 243,5 ms depois de armar, mede 0.243
- o tempo continua parado depois de soltar o botão
- zerar volta pra 0.000
- apertar com o cronômetro desarmado não muda nada
- os displays mostram PLAY, ----, CEdO e 0.243 com o ponto no lugar certo
- o cronômetro para em 9.999
- o sorteio fica girando

Pra rodar:

```
iverilog -o tb sim/tb_reflexo.v sim/sistema_nios_falso.v hw/divisor_1ms.v hw/cronometro_ms.v hw/sorteio.v hw/decod_7seg.v hw/display.v hw/vga_sync.v hw/tela.v hw/reflexo_top.v
vvp tb
```

**Simulação do VGA** (`sim/tb_vga.v`):

- cada linha dura 32 us e o pulso do hsync 3,84 us
- 525 linhas por tela (60 Hz)
- as cores de cada momento do jogo e o tamanho da barra

```
iverilog -o tbv sim/tb_vga.v hw/vga_sync.v hw/tela.v
vvp tbv
```

Também testamos a lógica do C no computador, simulando os botões: rodada normal, apertar cedo, recorde, tempo esgotado e o ranking ficando só com os 5 melhores.

**Compilação** (Quartus Prime Lite 18.1, 10M50DAF484C7G):

- 0 erros
- 2.062 elementos lógicos de 49.760 (4%)
- 273.408 bits de memória de 1.677.312 (16%), quase tudo é a RAM de 32 KB do Nios
- 75 pinos usados
- timing: sobra 7,668 ns no clock de 50 MHz (pior caso), então passa com folga
- programa em C: 10 KB, sobram 20 KB pra pilha

**Na placa:** (colocar fotos e o melhor tempo da turma)

## Problemas que podem acontecer

- O Programmer não acha a placa: falta o driver do USB-Blaster.
- O display mostra coisa estranha: algum pino errado, conferir com o manual da DE10-Lite.
- O Eclipse dá "System ID mismatch": gravar o `.sof` de novo e gerar o BSP de novo.
- O display fica parado em `PLAY`: o programa não está rodando no Nios.

## Referências

- A ideia veio do projeto [Response-Time-Game](https://github.com/JVKran/Response-Time-Game), da lista de projetos indicada pelo professor. A gente refez pra DE10-Lite usando o Nios II.
- Manual da DE10-Lite (Terasic), pra pegar os pinos.
- Documentação do Nios II e dos periféricos da Altera (PIO e JTAG UART).
