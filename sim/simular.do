# simular.do - roda os dois testbenches no ModelSim
# No ModelSim: File > Change Directory e escolher a pasta do projeto
# Depois digitar no Transcript:  do sim/simular.do

# quando um teste termina ($finish), continua pro proximo
onbreak {resume}

vlib work

# os arquivos do hw nao tem `timescale, entao passamos aqui (igual ao do testbench)
vlog -timescale 1ns/1ps hw/divisor_1ms.v hw/cronometro_ms.v hw/sorteio.v hw/decod_7seg.v hw/display.v
vlog -timescale 1ns/1ps hw/vga_sync.v hw/digito_tela.v hw/tela.v hw/reflexo_top.v
vlog -timescale 1ns/1ps sim/sistema_nios_falso.v sim/tb_reflexo.v sim/tb_vga.v

# teste do jogo (cronometro, displays, sorteio)
vsim -onfinish stop tb_reflexo
run -all

# teste do VGA
vsim -onfinish stop tb_vga
run -all
