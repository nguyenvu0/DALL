// NEW: dedicated storage for $HI/$LO/$RA/$AT special registers.
module SpecialRegisters(
    input        clk,
    input        reset,
    input        write_hi,
    input        write_lo,
    input        write_ra,
    input        write_at,
    input  [15:0] hi_i,
    input  [15:0] lo_i,
    input  [15:0] ra_i,
    input  [15:0] at_i,
    output [15:0] hi_o,
    output [15:0] lo_o,
    output [15:0] ra_o,
    output [15:0] at_o
);

    reg [15:0] hi_q;
    reg [15:0] lo_q;
    reg [15:0] ra_q;
    reg [15:0] at_q;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hi_q <= 16'b0;
            lo_q <= 16'b0;
            ra_q <= 16'b0;
            at_q <= 16'b0;
        end else begin
            if (write_hi) hi_q <= hi_i;
            if (write_lo) lo_q <= lo_i;
            if (write_ra) ra_q <= ra_i;
            if (write_at) at_q <= at_i;
        end
    end

    assign hi_o = hi_q;
    assign lo_o = lo_q;
    assign ra_o = ra_q;
    assign at_o = at_q;

endmodule

