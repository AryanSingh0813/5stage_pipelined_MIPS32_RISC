# MIPS32 Pipelined Processor

A 5-stage pipelined MIPS32 processor implementation in Verilog with support for physical synthesis using OpenROAD and the Nangate45 library.

## Overview

This project implements a classic 5-stage MIPS pipeline processor with two-phase clocking (clk1 and clk2). The design supports a subset of MIPS32 instructions including arithmetic, logical, load/store, and branch operations.

## Pipeline Stages

The processor implements the following pipeline stages:

1. **IF (Instruction Fetch)** - clk1
2. **ID (Instruction Decode)** - clk2
3. **EX (Execute)** - clk1
4. **MEM (Memory Access)** - clk2
5. **WB (Write Back)** - clk1

## Supported Instructions

### R-Type (Register-Register ALU)
- `ADD` - Addition
- `SUB` - Subtraction
- `AND` - Bitwise AND
- `OR` - Bitwise OR
- `SLT` - Set on Less Than
- `MUL` - Multiplication

### I-Type (Register-Immediate ALU)
- `ADDI` - Add Immediate
- `SUBI` - Subtract Immediate
- `SLTI` - Set on Less Than Immediate

### Load/Store
- `LW` - Load Word
- `SW` - Store Word

### Branch
- `BEQZ` - Branch if Equal to Zero
- `BNEQZ` - Branch if Not Equal to Zero

### Control
- `HLT` - Halt execution

## File Structure
```
.
├── mips_32.v              # Main processor RTL design
├── pipe_MIPS_tb.v         # Testbench for simulation
├── mips32_2.sdc           # Timing constraints (recommended)
├── mips_sta.sdc           # Alternative timing constraints
├── mips32_phySyn.tcl      # Physical synthesis configuration
└── README.md              # This file
```

## Design Files

### RTL Design (`mips_32.v`)
- **Module**: `pipe_MIPS32`
- **Inputs**: `clk1`, `clk2`
- **Outputs**: `pc_out[31:0]`, `ALU_output[31:0]`
- **Memory**: 512 words (instruction + data)
- **Registers**: 32 general-purpose registers (R0 hardwired to 0)

### Testbench (`pipe_MIPS_tb.v`)
Includes sample program that:
- Initializes registers R0-R31
- Executes arithmetic operations
- Demonstrates pipeline functionality

### Timing Constraints

#### `mips32_2.sdc` (Recommended)
- Clock period: 10ns (100MHz)
- Setup uncertainty: 0.2ns
- Hold uncertainty: 0.1ns
- Multicycle path constraints for two-phase clocking
- Output delay specifications

#### `mips_sta.sdc` (Alternative)
- Clock period: 1ps (for high-speed testing)
- Phase relationship between clk1 and clk2
- Physically exclusive clock groups

## Two-Phase Clocking

The design uses a two-phase non-overlapping clock scheme:
- **clk1**: Drives IF, EX, and WB stages
- **clk2**: Drives ID and MEM stages

This ensures proper pipeline separation and prevents race conditions.

## Physical Synthesis

### Prerequisites
- OpenROAD flow tools
- Nangate45 PDK library
- TCL 8.5 or higher

### Synthesis Configuration (`mips32_phySyn.tcl`)
```tcl
Design: pipe_MIPS32
Die area: 1400.49 × 1400.49 µm²
Core area: 1350.49 × 1350.49 µm² (with 60µm margins)
Technology: Nangate45
```

### Running Physical Synthesis
```bash
# Source the synthesis script
source mips32_phySyn.tcl

# This will:
# 1. Load the netlist (mips32_netlist.v)
# 2. Apply timing constraints (mips32_2.sdc)
# 3. Perform floorplanning with specified die/core areas
# 4. Run place and route
```

## Simulation

### Using ModelSim/QuestaSim
```bash
vlog mips_32.v pipe_MIPS_tb.v
vsim -c pipe_MIPS32_tb -do "run -all"
```

### Using Icarus Verilog
```bash
iverilog -o mips_sim mips_32.v pipe_MIPS_tb.v
vvp mips_sim
```

### Using Vivado
```tcl
# Create project
create_project mips32_sim ./sim -part <your_part>

# Add sources
add_files {mips_32.v pipe_MIPS_tb.v}
set_property top pipe_MIPS32_tb [get_filesets sim_1]

# Run simulation
launch_simulation
run all
```

## Sample Program Explanation

The testbench loads the following program:
```assembly
Mem[0]: 0x2801000a  # ADDI R1, R0, 10    (R1 = 10)
Mem[1]: 0x28020014  # ADDI R2, R0, 20    (R2 = 20)
Mem[2]: 0x28030019  # ADDI R3, R0, 25    (R3 = 25)
Mem[3]: 0x0ce77800  # OR R7, R7, R7      (NOP equivalent)
Mem[4]: 0x0ce77800  # OR R7, R7, R7      (NOP equivalent)
Mem[5]: 0x00222000  # ADD R4, R1, R2     (R4 = 30)
Mem[6]: 0x0ce77800  # OR R7, R7, R7      (NOP equivalent)
Mem[7]: 0x00832800  # ADD R5, R4, R3     (R5 = 55)
Mem[8]: 0xfc000000  # HLT                (Halt)
```

Expected results after execution:
- R1 = 10
- R2 = 20
- R3 = 25
- R4 = 30
- R5 = 55

## Pipeline Hazards

### Handled Hazards
- **Structural hazards**: Avoided by two-phase clocking
- **Branch hazards**: Branch target computed in EX stage with `TAKEN_BRANCH` flag

### Note on Data Hazards
The current implementation does **not** include hardware forwarding. Software must insert NOPs or reorder instructions to avoid data hazards.

## Key Features

- ✅ Two-phase non-overlapping clock design
- ✅ 5-stage classical pipeline architecture
- ✅ Register R0 hardwired to zero
- ✅ Signed immediate extension
- ✅ Branch prediction (simple taken/not-taken)
- ✅ Unified instruction and data memory
- ⚠️ No data forwarding (requires software hazard handling)
- ⚠️ No cache hierarchy

## Timing Analysis

Use OpenSTA for static timing analysis:
```bash
sta -exit mips32_2.sdc << EOF
read_liberty Nangate45/NangateOpenCellLibrary_typical.lib
read_verilog mips32_netlist.v
link_design pipe_MIPS32
read_sdc mips32_2.sdc
report_checks
report_wns
report_tns
EOF
```

## Known Limitations

1. No hazard detection/forwarding unit
2. Simple branch handling (may cause pipeline bubbles)
3. Limited instruction set
4. No interrupt/exception handling
5. No cache memory
6. Fixed memory size (512 words)

## Future Enhancements

- [ ] Add data forwarding logic
- [ ] Implement hazard detection unit
- [ ] Add branch prediction
- [ ] Expand instruction set
- [ ] Implement cache hierarchy
- [ ] Add exception handling
- [ ] Support for multiply-divide unit

## License

This is an educational project. Use freely for learning purposes.

## References

- Computer Architecture: A Quantitative Approach (Hennessy & Patterson)
- MIPS32 Architecture Documentation
- OpenROAD Project Documentation

## Authors

Created for educational purposes in digital design and computer architecture.

---

**Note**: This design is intended for educational and research purposes. For production use, additional verification, optimization, and hazard handling mechanisms are required.
