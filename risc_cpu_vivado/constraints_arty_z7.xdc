## Arty Z7-20 minimal constraints (clock / reset / halt LED)

## System clock 125 MHz (pin H16, SYSCLK)
set_property PACKAGE_PIN H16 [get_ports {clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {clk}]
create_clock -name sys_clk -period 8.000 [get_ports {clk}]

## Push button BTNC / BTN0 (pin D19) used as active-high reset
set_property PACKAGE_PIN D19 [get_ports {reset}]
set_property IOSTANDARD LVCMOS33 [get_ports {reset}]

## User LED LD0 (pin R14) indicates halt
set_property PACKAGE_PIN R14 [get_ports {halt}]
set_property IOSTANDARD LVCMOS33 [get_ports {halt}]