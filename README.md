# MIPS32 Pipelined Processor

A 5-stage pipelined MIPS32 processor implementation in Verilog with dual-clock architecture.

## Author
Aryan Singh

## Overview

This project implements a pipelined MIPS32 processor with the following five stages:
- **IF (Instruction Fetch)** - Fetches instructions from memory
- **ID (Instruction Decode)** - Decodes instructions and reads registers
- **EX (Execute)** - Performs ALU operations
- **MEM (Memory Access)** - Handles load/store operations
- **WB (Write Back)** - Writes results back to registers

## Architecture Features

### Dual Clock Design
- **clk1**: Controls IF, EX, and WB stages
- **clk2**: Controls ID and MEM stages

### Pipeline Registers
- `IF_ID`: Stores instruction and next PC between IF and ID stages
- `ID_EX`: Stores decoded values between ID and EX stages
- `EX_MEM`: Stores ALU results between EX and MEM stages
- `MEM_WB`: Stores memory/ALU data between MEM and WB stages

### Hazard Handling
- **Branch Handling**: Implements branch taken logic for BEQZ and BNEQZ instructions
- **TAKEN_BRANCH**: Flag to disable writes during branch execution to prevent incorrect updates

## Supported Instructions

### R-Type (Register-Register) ALU Operations
- `ADD` (000000) - Addition
- `SUB` (000001) - Subtraction
- `AND` (000010) - Bitwise AND
- `OR` (000011) - Bitwise OR
- `SLT` (000100) - Set Less Than
- `MUL` (000101) - Multiplication

### I-Type (Register-Immediate) ALU Operations
- `ADDI` (001010) - Add Immediate
- `SUBI` (001011) - Subtract Immediate
- `SLTI` (001100) - Set Less Than Immediate

### Memory Operations
- `LW` (001000) - Load Word
- `SW` (001001) - Store Word

### Branch Operations
- `BEQZ` (001110) - Branch if Equal to Zero
- `BNEQZ` (001101) - Branch if Not Equal to Zero

### Control
- `HLT` (111111) - Halt execution

## Instruction Format

### R-Type Instructions
### I-Type Instructions

## Memory Organization

- **Register File**: 32 registers (Reg[0:31])
- **Data Memory**: 1024 words (Mem[0:1023])
- **Register 0**: Always returns 0 when read

## Test Program

The testbench includes a sample program that:

1. `ADDI R1, R0, 10` - Load 10 into R1
2. `ADDI R2, R0, 20` - Load 20 into R2
3. `ADDI R3, R0, 25` - Load 25 into R3
4. `OR R15, R7, R7` - NOP operation
5. `OR R15, R7, R7` - NOP operation
6. `ADD R4, R2, R1` - R4 = R2 + R1 (30)
7. `OR R15, R7, R7` - NOP operation
8. `ADD R5, R3, R2` - R5 = R3 + R2 (45)
9. `HLT` - Halt execution

### Expected Results
## Timing

The testbench runs for 280ns with:
- Clock period: 20ns (10ns per phase)
- 20 clock cycles total
- Results displayed at simulation end

## Files

- **mips_32.v**: Main processor module
- **pipe_MIPS_tb.v**: Testbench with sample program

## Running the Simulation

1. Compile both Verilog files in your simulator
2. Run the testbench module `pipe_MIPS32_tb`
3. Observe the register values displayed at the end of simulation

## Design Considerations

### Pipeline Delays
All register updates use `#2` delay to model realistic timing

### Branch Prediction
Simple branch handling that flushes the pipeline when a branch is taken

### Data Hazards
The current implementation uses NOP instructions (OR R15, R7, R7) to handle data hazards. A more advanced implementation could include forwarding logic.

## Limitations

- No forwarding/bypassing logic implemented
- Simple branch handling (no branch prediction)
- Limited instruction set
- No exception handling
- No cache memory

## Future Enhancements

- Add data forwarding to eliminate NOP requirements
- Implement branch prediction
- Add more MIPS instructions
- Include exception handling
- Add performance counters
- Implement cache memory





