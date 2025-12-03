`timescale 1ns / 1ps

// UPDATED: expanded control interface to match HK251 opcode/funct spec.
// [MOD] alu_op widened to 7 bits to preserve full opcode+funct combination.
module ControlUnit(
    input  [15:0] instruction,
    output reg [6:0] alu_op,
    output reg       reg_write,
    output reg       mem_read,
    output reg       mem_write,
    output reg       branch_bneq,
    output reg       branch_bgtz,
    output reg       jump_abs,
    output reg       jump_reg,
    output reg [1:0] alu_src,
    output reg       mem_to_reg,
    output reg       mtsr_write,
    output reg [2:0] special_sel,
    output reg       mfsr_read,
    output reg       rd_is_dest,
    output reg       halt
);

    wire [3:0] opcode = instruction[15:12];
    wire [2:0] funct  = instruction[2:0];

    always @(*) begin
        // Default control signals
        alu_op       = 7'b0;
        reg_write    = 1'b0;
        mem_read     = 1'b0;
        mem_write    = 1'b0;
        branch_bneq  = 1'b0;
        branch_bgtz  = 1'b0;
        jump_abs     = 1'b0;
        jump_reg     = 1'b0;
        alu_src      = 2'b00;  // 00=registers, 01=imm, 10=zero
        mem_to_reg   = 1'b0;
        mtsr_write   = 1'b0;
        special_sel  = 3'b000;
        mfsr_read    = 1'b0;
        rd_is_dest   = 1'b1;
        halt         = 1'b0;

        case (opcode)
            4'b0000,
            4'b0001,
            4'b0010: begin
                alu_op     = {opcode, funct};
                reg_write  = (opcode != 4'b0001 || funct != 3'b111);  // jr doesn't write rd
                rd_is_dest = 1'b1;
                jump_reg   = (opcode == 4'b0001 && funct == 3'b111);
            end

            4'b0011,
            4'b0100: begin
                alu_op     = {opcode, 3'b000};
                reg_write  = 1'b1;
                rd_is_dest = 1'b0;     // rt is destination
                alu_src    = 2'b01;
            end

            4'b0101: begin
                alu_op      = {opcode, 3'b000};
                branch_bneq = 1'b1;
                rd_is_dest  = 1'b0;
            end

            4'b0110: begin
                alu_op      = {opcode, 3'b000};
                branch_bgtz = 1'b1;
                alu_src     = 2'b10; // compare rs with zero
                rd_is_dest  = 1'b0;
            end

            4'b0111: begin
                jump_abs = 1'b1;
                rd_is_dest = 1'b0;
            end

            4'b1000: begin
                alu_op     = {opcode, 3'b000};
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                reg_write  = 1'b1;
                rd_is_dest = 1'b0;   // rt destination
                alu_src    = 2'b01;
            end

            4'b1001: begin
                alu_op     = {opcode, 3'b000};
                mem_write  = 1'b1;
                rd_is_dest = 1'b0;
                alu_src    = 2'b01;
            end

            4'b1010: begin
                reg_write   = 1'b1;
                rd_is_dest  = 1'b1;
                mfsr_read   = 1'b1;
                special_sel = funct;
            end

            4'b1011: begin
                mtsr_write  = 1'b1;
                rd_is_dest  = 1'b0;
                special_sel = funct;
            end

            4'b1111: begin
                halt = 1'b1;
            end
        endcase
    end
endmodule
