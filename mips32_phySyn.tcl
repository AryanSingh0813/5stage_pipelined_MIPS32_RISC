source "helpers.tcl"
source "flow_helpers.tcl"
source "Nangate45/Nangate45.vars"

set design "mips_32"
set top_module "pipe_MIPS32"

set synth_verilog "mips32_netlist.v"
#set sdc_file "mips_sta.sdc"
set sdc_file "mips32_2.sdc"

set die_area  {0 0 1400.4938016377725 1400.4938016377725}
set core_area {60 60 1350.4938016377725 1350.4938016377725}

