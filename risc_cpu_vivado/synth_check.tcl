read_verilog -sv cpu_top.v
read_verilog -sv CPU.v
read_verilog -sv Datapath.v
read_verilog -sv ALU_spec.v
read_verilog -sv ControlUnit.v
read_verilog -sv RegisterFile.v
read_verilog -sv Memory.v
synth_design -top cpu_top -part xc7z020clg484-1
report_utilization
exit
