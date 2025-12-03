`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg reset;
    wire halt;
    integer cycle;

    CPU cpu(
        .clk(clk),
        .reset(reset),
        .halt(halt)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1;
        #50 reset = 0;

        for (cycle = 0; cycle < 2000; cycle = cycle + 1) begin
            @(posedge clk);
            if (halt) begin
                $display("[%0t] HALT detected", $time);
                $finish;
            end
        end

        $display("[%0t] Simulation timed out without HALT", $time);
        $finish;
    end

endmodule
