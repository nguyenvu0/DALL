# Vivado Troubleshooting Guide

## Common Errors and Solutions

### 1. Duplicate Design Unit Error
**Error:** `[filemgmt 20-1318] Duplicate Design Unit 'ALU()' found in library 'xil_defaultlib'`

**Cause:** Multiple ALU modules with the same name in the project.

**Solution:**
- Remove duplicate ALU files from the project
- Keep only `ALU_spec.v` (specification-compliant version)
- In Vivado: Right-click duplicate files → Remove File from Project

### 2. opt_design ERROR
**Error:** `opt_design ERROR`

**Common Causes:**
- Timing violations
- Unconstrained paths
- Logic optimization issues

**Solutions:**
1. **Check Timing Constraints:**
   - Ensure clock constraints are properly set in XDC file
   - Verify clock period matches design requirements

2. **Add Missing Constraints:**
   - Add input/output delay constraints if needed
   - Set false paths for asynchronous signals

3. **Simplify Design:**
   - Check for combinational loops
   - Ensure all signals are properly registered
   - Reduce logic complexity if possible

### 3. Synthesis Errors
**Error:** Various synthesis failures

**Solutions:**
- Check for syntax errors in Verilog code
- Ensure all module ports are properly connected
- Verify parameter values are within valid ranges
- Check for missing module instantiations

### 4. Implementation Errors
**Error:** Place and Route failures

**Solutions:**
- Check resource utilization (LUTs, FFs, BRAM)
- Add placement constraints if needed
- Reduce design complexity
- Check timing constraints

### 5. Bitstream Generation Errors
**Error:** Bitstream generation fails

**Solutions:**
- Ensure all constraints are valid
- Check for DRC (Design Rule Check) violations
- Verify pin assignments match board specifications

## Specific to RISC CPU Design

### Memory Initialization Issues
- The CPU uses preloaded instruction memory
- Ensure memory initialization doesn't cause synthesis issues
- Consider using BRAM primitives for better performance

### Pipeline Hazards
- The design includes forwarding logic
- Ensure stall logic doesn't create combinational loops
- Check for proper reset behavior

### ALU Operation Issues
- Verify all ALU operations are synthesizable
- Check for division by zero handling
- Ensure shift operations use correct bit ranges

## Performance Optimization

### Timing Closure
```xdc
# Add to constraints.xdc for better timing
set_max_delay -from [get_ports reset] -to [all_registers] 5.0
set_false_path -from [get_ports reset] -setup
set_false_path -from [get_ports reset] -hold
```

### Resource Optimization
- Use BRAM for memory instead of distributed RAM
- Optimize ALU for area vs speed trade-off
- Consider register retiming for better timing

## Debugging Steps

1. **Run Synthesis Only First:**
   - Skip implementation to isolate synthesis issues
   - Check synthesis report for warnings/errors

2. **Check RTL Elaboration:**
   - Use "Open Elaborated Design" to verify connectivity
   - Check for unconnected ports or signals

3. **Use Vivado Debug Features:**
   - Insert ILA (Integrated Logic Analyzer) cores for debugging
   - Use Mark Debug to probe internal signals

4. **Simplify Test Case:**
   - Create minimal test design with just CPU top level
   - Gradually add complexity to isolate issues

## Hardware Debugging

### On Arty-Z7 Board
- Use onboard LEDs for status indication
- Connect to serial terminal for debug output
- Use Vivado Hardware Manager for real-time debugging

### Signal Probing
- Add debug ports to top-level module
- Use ILA to capture internal signal waveforms
- Monitor PC, instruction, and register values

## Alternative Approaches

If Vivado synthesis fails:
1. **Use different synthesis strategy:**
   - Change from "Vivado Synthesis Defaults" to "Flow_PerfOptimized_high"
   - Try "Flow_AreaOptimized_high" for smaller designs

2. **Split into smaller modules:**
   - Synthesize sub-modules separately
   - Combine in top-level design

3. **Use different HDL:**
   - Consider SystemVerilog if Verilog has issues
   - Rewrite critical paths in VHDL

## Getting Help

- Check Vivado User Guide and Tutorials
- Search Xilinx Forums for similar issues
- Review synthesis and implementation reports for clues
- Use Vivado's built-in help system

## Prevention Tips

- Always run synthesis after major code changes
- Use version control to track working designs
- Keep constraints files updated with design changes
- Test on multiple FPGA families if possible
- Document known issues and workarounds
