##create clock -name clk1 -period 1000[get_ports clk1]

##create clock -name clk2 -period 1000[get_ports clk2]

##set_input_delay 2 -clock clk1 [all_inputs]
##set_input_delay 2 -clock clk2 [all_inputs]

##set_output_delay 2 -clock clk1 [all_outputs]
##set_output_delay 2 -clock clk2 [all_outputs]


##create_clock -name clk1 -period 1000 [get_ports clk1]
##create_clock -name clk2 -period 1000 [get_ports clk2]

##set_clock_uncertainty 0.2 [get_clocks]


##create_clock -name clk1 -period 10 [get_ports clk1]
##create_clock -name clk2 -period 10 [get_ports clk2]

##set_clock_uncertainty -setup 2.0 [get_clocks clk1]
##set_clock_uncertainty -setup 2.0 [get_clocks clk2]

##set_clock_uncertainty -hold 2.0 [get_clocks clk1]
##set_clock_uncertainty -hold 2.0 [get_clocks clk2]


##set_clock_groups -asynchronous -group {clk1} -group {clk2}


# Create primary clocks
create_clock -name clk1 -period 0.001 [get_ports clk1]
create_clock -name clk2 -period 0.001 [get_ports clk2]

# Define the phase relationship between clk1 and clk2
# Assuming clk2 is 180 degrees out of phase with clk1 (5ns offset for 10ns period)
set_clock_latency -source 0.0 [get_clocks clk1]
set_clock_latency -source 0.00025 [get_clocks clk2]

# Set clock uncertainties (jitter and skew)
set_clock_uncertainty -setup 0.00001 [get_clocks clk1]
set_clock_uncertainty -setup 0.00001 [get_clocks clk2]
set_clock_uncertainty -hold 0.00001 [get_clocks clk1]
set_clock_uncertainty -hold 0.00001 [get_clocks clk2]

# Define clock groups - these clocks are related (not asynchronous)
# They form a two-phase clock system
set_clock_groups -physically_exclusive -group {clk1} -group {clk2}

# Set input/output delays
# Assume external logic provides/receives data with respect to clk1
set_input_delay -clock clk1 0.00001 [get_ports clk1]
set_input_delay -clock clk1 0.00001 [get_ports clk2]

set_output_delay -clock clk1 2.0 [get_ports pc_out]
set_output_delay -clock clk1 2.0 [get_ports ALU_output]

# Set false paths for asynchronous resets/initialization (if any were present)
# Note: This design uses initial blocks which are synthesis artifacts

# Multicycle path constraints for the pipeline stages
# Data flows from clk1 domain to clk2 domain and back
set_multicycle_path -setup 1 -from [get_clocks clk1] -to [get_clocks clk2]
set_multicycle_path -hold 0 -from [get_clocks clk1] -to [get_clocks clk2]
set_multicycle_path -setup 1 -from [get_clocks clk2] -to [get_clocks clk1]
set_multicycle_path -hold 0 -from [get_clocks clk2] -to [get_clocks clk1]

# Memory constraints
# Set max delay for memory access if needed
# set_max_delay 8.0 -from [get_pins -of_objects [get_cells mem*]] -to [get_pins -of_objects [get_cells MEM_WB_LMD*]]

# Clock transition and load constraints (adjust based on your technology library)
set_clock_transition 0.2 [get_clocks clk1]
set_clock_transition 0.2 [get_clocks clk2]

# Drive strength for input ports (adjust based on your technology)
##set_driving_cell -lib_cell <your_buffer_cell> [get_ports clk1]
##set_driving_cell -lib_cell <your_buffer_cell> [get_ports clk2]

# Load constraints for output ports (adjust based on your requirements)
set_load 0.1 [get_ports pc_out]
set_load 0.1 [get_ports ALU_output]
