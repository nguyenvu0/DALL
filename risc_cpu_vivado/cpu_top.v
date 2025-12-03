module cpu_top(
    input clk,
    input reset,
    output halt
);

    CPU cpu(
        .clk(clk),
        .reset(reset),
        .halt(halt)
    );

endmodule
