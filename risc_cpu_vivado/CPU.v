`timescale 1ns / 1ps

module CPU #(
    parameter PROGRAM_FILE = ""
)(
    input clk,
    input reset,
    output halt
);

    wire [15:0] pc;
    wire [15:0] instruction;
    // [MOD] align CPU wiring with expanded control/datapath interface
    wire [6:0] alu_op;
    wire       reg_write;
    wire       mem_read;
    wire       mem_write;
    wire       branch_bneq;
    wire       branch_bgtz;
    wire       jump_abs;
    wire       jump_reg;
    wire [1:0] alu_src;
    wire       mem_to_reg;
    wire       mtsr_write;
    wire       mfsr_read;
    wire [2:0] special_sel;
    wire       rd_is_dest;
    wire       halt_decode;

    // Instruction memory (word-aligned ROM)
    (* ram_style = "block" *) reg [15:0] instr_mem [0:32767];
    integer                      rom_init_idx;
    assign instruction = instr_mem[pc[15:1]];

    initial begin
        for (rom_init_idx = 0; rom_init_idx < 32768; rom_init_idx = rom_init_idx + 1) begin
            instr_mem[rom_init_idx] = 16'h0000;
        end
        instr_mem[0] = 16'hFFFF; // Default HALT program

        if (PROGRAM_FILE != "") begin
            $display("Loading program image from %s", PROGRAM_FILE);
            $readmemh(PROGRAM_FILE, instr_mem);
        end
    end

    ControlUnit cu(
        .instruction(instruction),
        .alu_op(alu_op),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch_bneq(branch_bneq),
        .branch_bgtz(branch_bgtz),
        .jump_abs(jump_abs),
        .jump_reg(jump_reg),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .mtsr_write(mtsr_write),
        .special_sel(special_sel),
        .mfsr_read(mfsr_read),
        .rd_is_dest(rd_is_dest),
        .halt(halt_decode)
    );

    Datapath dp(
        .clk(clk),
        .reset(reset),
        .instruction(instruction),
        .alu_op(alu_op),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch_bneq(branch_bneq),
        .branch_bgtz(branch_bgtz),
        .jump_abs(jump_abs),
        .jump_reg(jump_reg),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .mtsr_write(mtsr_write),
        .mfsr_read(mfsr_read),
        .special_sel(special_sel),
        .rd_is_dest(rd_is_dest),
        .halt_decode(halt_decode),
        .pc_out(pc),
        .halt(halt)
    );


endmodule
