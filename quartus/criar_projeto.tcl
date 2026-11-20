# criar_projeto.tcl
# Cria o projeto do Quartus com os arquivos e os pinos.
# Uso: quartus_sh -t criar_projeto.tcl

project_new reflexo -overwrite

set_global_assignment -name FAMILY "MAX 10"
set_global_assignment -name DEVICE 10M50DAF484C7G
set_global_assignment -name TOP_LEVEL_ENTITY reflexo_top

# no MAX 10 esse modo deixa usar memoria interna inicializada (a RAM do Nios)
set_global_assignment -name INTERNAL_FLASH_UPDATE_MODE "SINGLE IMAGE WITH ERAM"

set_global_assignment -name VERILOG_FILE ../hw/divisor_1ms.v
set_global_assignment -name VERILOG_FILE ../hw/cronometro_ms.v
set_global_assignment -name VERILOG_FILE ../hw/sorteio.v
set_global_assignment -name VERILOG_FILE ../hw/decod_7seg.v
set_global_assignment -name VERILOG_FILE ../hw/display.v
set_global_assignment -name VERILOG_FILE ../hw/vga_sync.v
set_global_assignment -name VERILOG_FILE ../hw/tela.v
set_global_assignment -name VERILOG_FILE ../hw/reflexo_top.v
set_global_assignment -name QIP_FILE sistema_nios/synthesis/sistema_nios.qip
set_global_assignment -name SDC_FILE restricoes.sdc

source pinos_de10lite.tcl

project_close
