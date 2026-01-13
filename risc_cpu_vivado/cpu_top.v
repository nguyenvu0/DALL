module cpu_top(
    input clk,           // 125 MHz from board
    input reset_btn,     // BTN0 (not used)
    output [3:0] pc_led  // LD0-LD3 (show PC[3:0])
);

    // ========================================
    // CLOCK DIVIDER: 125 MHz -> ~2 Hz
    // ========================================
    reg [26:0] clk_counter = 0;
    reg slow_clk = 0;
    
    always @(posedge clk) begin
        if (clk_counter == 27'd31_250_000) begin
            clk_counter <= 0;
            slow_clk <= ~slow_clk;
        end else begin
            clk_counter <= clk_counter + 1;
        end
    end

    // ========================================
    // EMBEDDED SIMPLE CPU (WORKING VERSION)
    // ========================================
    
    // Program Counter
    reg [15:0] pc = 0;
    
    // Instruction Memory (hardcoded)
    reg [15:0] instr_mem [0:15];
    initial begin
        instr_mem[0] = 16'h3040;  // addi $1, $0, 0
        instr_mem[1] = 16'h3049;  // addi $1, $1, 1  
        instr_mem[2] = 16'h308F;  // addi $2, $0, 15
        instr_mem[3] = 16'h129C;  // slt $3, $1, $2
        instr_mem[4] = 16'h56FE;  // bneq $3, $0, -2
        instr_mem[5] = 16'hFFFF;  // halt
        instr_mem[6] = 16'h0000;
        instr_mem[7] = 16'h0000;
        instr_mem[8] = 16'h0000;
        instr_mem[9] = 16'h0000;
        instr_mem[10] = 16'h0000;
        instr_mem[11] = 16'h0000;
        instr_mem[12] = 16'h0000;
        instr_mem[13] = 16'h0000;
        instr_mem[14] = 16'h0000;
        instr_mem[15] = 16'h0000;
    end
    
    // Register File (8 registers)
    reg [15:0] regs [0:7];
    integer i;
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            regs[i] = 16'h0000;
        end
    end
    
    // Fetch instruction
    wire [3:0] pc_index = pc[4:1];
    wire [15:0] instruction = instr_mem[pc_index];
    
    // Decode
    wire [3:0] opcode = instruction[15:12];
    wire [2:0] rs = instruction[11:9];
    wire [2:0] rt = instruction[8:6];
    wire [2:0] rd = instruction[5:3];
    wire [5:0] imm = instruction[5:0];
    wire signed [15:0] imm_ext = {{10{imm[5]}}, imm};
    
    // Halt detection
    wire is_halt = (instruction == 16'hFFFF);
    reg halted = 0;
    wire reset = 1'b0;  // Never reset
    
    // Execute
    always @(posedge slow_clk) begin
        if (reset) begin
            pc <= 0;
            halted <= 0;
            for (i = 0; i < 8; i = i + 1) begin
                regs[i] <= 16'h0000;
            end
        end else if (!halted) begin
            if (is_halt) begin
                halted <= 1;
            end else begin
                case (opcode)
                    4'b0011: begin  // ADDI
                        regs[rt] <= regs[rs] + imm_ext;
                        pc <= pc + 2;
                    end
                    
                    4'b0001: begin  // ALU1
                        case (instruction[2:0])
                            3'b100: begin  // SLT
                                regs[rd] <= ($signed(regs[rs]) < $signed(regs[rt])) ? 16'h0001 : 16'h0000;
                                pc <= pc + 2;
                            end
                            default: pc <= pc + 2;
                        endcase
                    end
                    
                    4'b0101: begin  // BNEQ
                        if (regs[rs] != regs[rt]) begin
                            pc <= pc + 2 + (imm_ext << 1);
                        end else begin
                            pc <= pc + 2;
                        end
                    end
                    
                    default: pc <= pc + 2;
                endcase
            end
        end
    end
    
    // Output PC to LEDs
    assign pc_led = pc[3:0];

endmodule
