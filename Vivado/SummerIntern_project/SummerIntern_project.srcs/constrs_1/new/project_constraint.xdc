## Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports {clk}]; 
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}];

## Led
set_property -dict {PACKAGE_PIN H17    IOSTANDARD LVCMOS33} [get_ports {corner_out}];

## USB-RS232 Interface
set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports {tx}]; 