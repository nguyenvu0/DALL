`timescale 1ns / 1ps

// UPDATED: enforce word-aligned addressing per LH/SH definition.
module Memory(
    input        clk,
    input  [15:0] address,
    input  [15:0] write_data,
    input        mem_read,
    input        mem_write,
    output reg [15:0] read_data
);

    reg [15:0] mem [0:32767];

    wire [14:0] word_addr = address[15:1];  // [MOD] explicit 15-bit index

    always @(posedge clk) begin
        if (mem_write) begin
            mem[word_addr] <= write_data;
        end
        if (mem_read) begin
            read_data <= mem[word_addr];
        end
    end
endmodule
