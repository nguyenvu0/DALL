`timescale 1ns / 1ps

// [MOD] Register file implements 8 GPR + special registers ZERO/PC/RA/AT/HI/LO.
module RegisterFile(
    input        clk,
    input        reset,
    input  [2:0] rs_addr,
    input  [2:0] rt_addr,
    input  [2:0] rd_addr,
    input        rd_write_en,
    input  [15:0] rd_write_data,
    input        mtsr_write_en,
    input  [2:0] mtsr_sel,
    input  [15:0] mtsr_data,
    input        hi_we,
    input        lo_we,
    input  [15:0] hi_data,
    input  [15:0] lo_data,
    input  [2:0]  special_sel,
    input  [15:0] pc_value,
    output [15:0] rs_data,
    output [15:0] rt_data,
    output reg [15:0] special_read_data
);

    reg [15:0] gpr [0:7];
    reg [15:0] ra_reg;
    reg [15:0] at_reg;
    reg [15:0] hi_reg;
    reg [15:0] lo_reg;

    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1) begin
                gpr[i] <= 16'h0000;
            end
            ra_reg <= 16'h0000;
            at_reg <= 16'h0000;
            hi_reg <= 16'h0000;
            lo_reg <= 16'h0000;
        end else begin
            if (rd_write_en && (rd_addr != 3'b000)) begin
                gpr[rd_addr] <= rd_write_data;
            end
            if (mtsr_write_en) begin
                case (mtsr_sel)
                    3'b010: ra_reg <= mtsr_data;
                    3'b011: at_reg <= mtsr_data;
                    3'b100: hi_reg <= mtsr_data;
                    3'b101: lo_reg <= mtsr_data;
                    default: ;
                endcase
            end
            if (hi_we) begin
                hi_reg <= hi_data;
            end
            if (lo_we) begin
                lo_reg <= lo_data;
            end
        end
    end

    assign rs_data = (rs_addr == 3'b000) ? 16'h0000 : gpr[rs_addr];
    assign rt_data = (rt_addr == 3'b000) ? 16'h0000 : gpr[rt_addr];

    always @(*) begin
        case (special_sel)
            3'b000: special_read_data = 16'h0000;     // $ZERO
            3'b001: special_read_data = pc_value;     // $PC
            3'b010: special_read_data = ra_reg;
            3'b011: special_read_data = at_reg;
            3'b100: special_read_data = hi_reg;
            3'b101: special_read_data = lo_reg;
            default: special_read_data = 16'h0000;
        endcase
    end

endmodule
