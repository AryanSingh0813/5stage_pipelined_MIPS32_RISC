# MIPS32 Pipeline Processor Timing Constraints for OpenSTA
# Created for: pipe_MIPS32

# Clock definitions - assuming 100MHz frequency
create_clock -name clk1 -period 10 [get_ports clk1]
create_clock -name clk2 -period 10 [get_ports clk2]

# Clock uncertainty
set_clock_uncertainty -setup 0.2 [get_clocks {clk1 clk2}]
set_clock_uncertainty -hold 0.1 [get_clocks {clk1 clk2}]

# Inter-clock constraints for two-phase pipeline
set_multicycle_path -setup 2 -from [get_clocks clk1] -to [get_clocks clk2]
set_multicycle_path -hold 1 -from [get_clocks clk1] -to [get_clocks clk2]
set_multicycle_path -setup 2 -from [get_clocks clk2] -to [get_clocks clk1]
set_multicycle_path -hold 1 -from [get_clocks clk2] -to [get_clocks clk1]

# Input delays - manually specify non-clock inputs
# Assuming your design only has clk1, clk2 as clock inputs
# Add other input ports here if they exist
# set_input_delay -clock clk1 -max 2 [get_ports other_input_port]
# set_input_delay -clock clk1 -min 1 [get_ports other_input_port]

# Output delays
set_output_delay -clock clk1 -max 2 [all_outputs]
set_output_delay -clock clk1 -min 1 [all_outputs]

# Critical output timing
set_output_delay -clock clk1 -max 1.5 [get_ports pc_out]
set_output_delay -clock clk2 -max 1.5 [get_ports ALU_output]

# Load capacitance for output ports
set_load 0.05 [all_outputs]

# Maximum transition and capacitance constraints
set_max_transition 0.5 [current_design]
set_max_capacitance 0.5 [current_design]

# Group paths for better analysis
group_path -name INPUTS -from [all_inputs]
group_path -name OUTPUTS -to [all_outputs]
group_path -name CLK1_REGS -from [get_clocks clk1] -to [get_clocks clk1]
group_path -name CLK2_REGS -from [get_clocks clk2] -to [get_clocks clk2]
