## Constraints for RISC CPU 16-bit on Arty Z7-20
## Based on Arty-Z7-20-Master.xdc

## Clock Signal - 125 MHz
set_property -dict { PACKAGE_PIN H16    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

## Reset Button - BTN0 (currently ignored, reset forced to 0 in cpu_top)
set_property -dict { PACKAGE_PIN D19    IOSTANDARD LVCMOS33 } [get_ports { reset_btn }];

## Debug Output LEDs - Show PC[3:0]
## Note: LD0 will also show halt status since halt affects PC
set_property -dict { PACKAGE_PIN R14    IOSTANDARD LVCMOS33 } [get_ports { pc_led[0] }]; # LD0
set_property -dict { PACKAGE_PIN P14    IOSTANDARD LVCMOS33 } [get_ports { pc_led[1] }]; # LD1
set_property -dict { PACKAGE_PIN N16    IOSTANDARD LVCMOS33 } [get_ports { pc_led[2] }]; # LD2
set_property -dict { PACKAGE_PIN M14    IOSTANDARD LVCMOS33 } [get_ports { pc_led[3] }]; # LD3

## Optional: Switches for input (if needed)
#set_property -dict { PACKAGE_PIN M20    IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
#set_property -dict { PACKAGE_PIN M19    IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];

## Optional: More buttons (BTN1-3)
#set_property -dict { PACKAGE_PIN D20    IOSTANDARD LVCMOS33 } [get_ports { btn[1] }];
#set_property -dict { PACKAGE_PIN L20    IOSTANDARD LVCMOS33 } [get_ports { btn[2] }];
#set_property -dict { PACKAGE_PIN L19    IOSTANDARD LVCMOS33 } [get_ports { btn[3] }];