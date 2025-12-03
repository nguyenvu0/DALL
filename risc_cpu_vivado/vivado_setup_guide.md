# Vivado Setup Guide (HK251 RISC CPU)

## Prerequisites
- Vivado 2020.1+ (tested)
- Arty-Z7 (XC7Z020) or equivalent 100 MHz board
- Hex/`mem` file that contains the 16-bit program to execute

## Project Flow

### 1. Create project
1. Open Vivado → **Create Project**
2. Name: `hk251_cpu`
3. Project type: *RTL project*, uncheck “Add sources”
4. Select the target part/board (e.g. `xc7z020clg400-1`)

### 2. Add RTL sources
Add all Verilog files inside `risc_cpu_vivado/`:
```
ALU_spec.v
ControlUnit.v
CPU.v
Datapath.v
Memory.v
RegisterFile.v
```
`cpu_top.v` is optional; `CPU.v` is the synthesizable top that connects ControlUnit↔Datapath.

### 3. Instruction memory initialisation
`CPU.v` instantiates an internal ROM (`instr_mem`). Before synthesis, edit the file (or generate a dedicated `instr_mem.v`) to call `initial $readmemh("program.hex", instr_mem);` and place `program.hex` under the Vivado project directory. The file must contain 16-bit words encoded per HK251 ISA (see spec). Without this step the CPU will fetch zeros only.

### 4. Constraints
Add `constraints.xdc` and map the board pins:
- `clk` → 100 MHz pin (Arty-Z7: E3)
- `reset` → push button (Arty-Z7 BTNC: C12)
- Optional LEDs/UART for debug (e.g. LD0 for HALT)

### 5. Set top & elaborate
1. In Sources → right-click `CPU` → **Set as Top**
2. Run *Elaborated Design* to verify hierarchy (ALU, Datapath, RegisterFile, Memory).

### 6. Synthesis / Implementation / Bitstream
Follow Flow Navigator:
1. **Run Synthesis**
2. **Run Implementation** (fix timing/IO warnings if any)
3. **Generate Bitstream**
4. Save reports (`utilization`, `timing`) for the course deliverable.

### 7. Program FPGA
1. **Open Hardware Manager** → Auto connect
2. **Program Device** with the generated bitstream
3. Observe LEDs/UART or use ILA if instrumented.

### 8. Reset / Halt behaviour
- Reset is active high: asserting BTNC reloads PC=0 and flushes pipeline.
- The pipeline halts when the instruction `1111` (HLT) executes; expose the latched `halt` signal to an LED to confirm.

## Troubleshooting tips
- **Instruction memory blank**: ensure `$readmemh` path is relative to Vivado run directory.
- **Branch/JR misbehaviour**: confirm your program encodes offsets as signed values shifted left by 1 (per HK251 spec).
- **Synthesis errors**: all modules use SystemVerilog syntax (packed structs/functions). Enable SystemVerilog parsing or rename files with `.sv`.
- **Timing failures**: reduce clock to 50 MHz or enable retiming (project settings → synthesis strategy).
- **Reset polarity**: check `constraints.xdc` matches board button (Arty BTNC is active high).

## Quick resource numbers (Arty-Z7 build @100 MHz)
- LUTs: 700–900 (depends on optional debug)
- FFs: 400–600
- BRAM: 2 (instruction/data memory)
- Max clock: ~120 MHz in default implementation

## Deliverable checklist
- RTL + constraint sources in Vivado
- `program.hex` matching your test/demo
- Timing/utilization reports
- Optional: waveform from simulation (`xsim`) showing IF→WB execution of mandatory instructions
