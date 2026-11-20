# criar_sistema_nios.tcl
# Monta o sistema do Nios II no Platform Designer por script (mesma coisa da etapa 3 do README).
# Uso: qsys-script --script=criar_sistema_nios.tcl

package require -exact qsys 18.1

create_system sistema_nios
set_project_property DEVICE_FAMILY {MAX 10}
set_project_property DEVICE {10M50DAF484C7G}

# Componentes
add_instance clk_0 clock_source
set_instance_parameter_value clk_0 clockFrequency {50000000.0}
set_instance_parameter_value clk_0 clockFrequencyKnown {1}
set_instance_parameter_value clk_0 resetSynchronousEdges {NONE}

add_instance cpu altera_nios2_gen2
set_instance_parameter_value cpu impl {Tiny}
set_instance_parameter_value cpu resetSlave {memoria.s1}
set_instance_parameter_value cpu resetOffset {0}
set_instance_parameter_value cpu exceptionSlave {memoria.s1}
set_instance_parameter_value cpu exceptionOffset {32}

add_instance memoria altera_avalon_onchip_memory2
set_instance_parameter_value memoria memorySize {32768.0}
set_instance_parameter_value memoria dataWidth {32}
set_instance_parameter_value memoria initMemContent {0}

add_instance jtag_uart altera_avalon_jtag_uart

add_instance sysid altera_avalon_sysid_qsys
set_instance_parameter_value sysid id {1}

proc cria_pio {nome largura direcao} {
    add_instance $nome altera_avalon_pio
    set_instance_parameter_value $nome width $largura
    set_instance_parameter_value $nome direction $direcao
}
cria_pio botoes  2  Input
cria_pio leds    10 Output
cria_pio comando 2  Output
cria_pio modo    2  Output
cria_pio tempo   16 Input
cria_pio sorteio 12 Input

# Clock e reset
add_connection clk_0.clk       cpu.clk
add_connection clk_0.clk_reset cpu.reset
add_connection cpu.debug_reset_request cpu.reset

add_connection clk_0.clk       memoria.clk1
add_connection clk_0.clk_reset memoria.reset1
add_connection cpu.debug_reset_request memoria.reset1

foreach comp {jtag_uart sysid botoes leds comando modo tempo sorteio} {
    add_connection clk_0.clk       $comp.clk
    add_connection clk_0.clk_reset $comp.reset
    add_connection cpu.debug_reset_request $comp.reset
}

# Barramento (endereços fixos)
proc liga_dados {escravo endereco} {
    add_connection cpu.data_master $escravo
    set_connection_parameter_value cpu.data_master/$escravo baseAddress $endereco
}
liga_dados memoria.s1                 0x00008000
liga_dados cpu.debug_mem_slave      0x00010800
liga_dados jtag_uart.avalon_jtag_slave 0x00011000
liga_dados sysid.control_slave        0x00011008
liga_dados botoes.s1                  0x00011010
liga_dados leds.s1                    0x00011020
liga_dados comando.s1                 0x00011030
liga_dados modo.s1                    0x00011040
liga_dados tempo.s1                   0x00011050
liga_dados sorteio.s1                 0x00011060

add_connection cpu.instruction_master memoria.s1
set_connection_parameter_value cpu.instruction_master/memoria.s1 baseAddress 0x00008000
add_connection cpu.instruction_master cpu.debug_mem_slave
set_connection_parameter_value cpu.instruction_master/cpu.debug_mem_slave baseAddress 0x00010800

# Interrupção da JTAG UART
add_connection cpu.irq jtag_uart.irq
set_connection_parameter_value cpu.irq/jtag_uart.irq irqNumber {0}

# Portas exportadas (viram pinos do sistema_nios)
add_interface clk clock sink
set_interface_property clk EXPORT_OF clk_0.clk_in
add_interface reset reset sink
set_interface_property reset EXPORT_OF clk_0.clk_in_reset

foreach pio {botoes leds comando modo tempo sorteio} {
    add_interface $pio conduit end
    set_interface_property $pio EXPORT_OF $pio.external_connection
}

save_system sistema_nios.qsys
