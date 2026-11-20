# clock da placa: 50 MHz (20 ns)
create_clock -name clk50 -period 20.000 [get_ports MAX10_CLK1_50]
derive_clock_uncertainty
