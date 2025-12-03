`timescale 1ns / 1ps

// [MOD] opcode/funct bus widened to 7 bits (4+3) to match control unit encoding.
module ALU(
    input  [15:0] A,
    input  [15:0] B,
    input  [6:0]  op,   // {opcode[3:0], funct[2:0]}
    output reg [15:0] result,
    output reg [15:0] hi,
    output reg [15:0] lo,
    output reg        zero_flag,
    output reg        sign_flag
);

    wire [3:0] opcode = op[6:3];
    wire [2:0] funct  = op[2:0];

    // UPDATED: helper functions for rotate operations to keep logic compact.
    function automatic [15:0] ror16(input [15:0] value, input [3:0] shamt);
        ror16 = (shamt == 0) ? value : ((value >> shamt) | (value << (16 - shamt)));
    endfunction

    function automatic [15:0] rol16(input [15:0] value, input [3:0] shamt);
        rol16 = (shamt == 0) ? value : ((value << shamt) | (value >> (16 - shamt)));
    endfunction

    always @(*) begin
        hi = 16'b0;
        lo = 16'b0;
        result = 16'b0;

        case (opcode)
            4'b0000: begin  // ALU0 (unsigned)
                case (funct)
                    3'b000: result = A + B;                         // addu
                    3'b001: result = A - B;                         // subu
                    3'b010: {hi, lo} = A * B;                       // multu
                    3'b011: if (B != 0) begin                       // divu
                                 lo = A / B;
                                 hi = A % B;
                             end
                    3'b100: result = A & B;                         // and
                    3'b101: result = A | B;                         // or
                    3'b110: result = ~(A | B);                      // nor
                    3'b111: result = A ^ B;                         // xor
                endcase
            end

            4'b0001: begin  // ALU1 (signed)
                case (funct)
                    3'b000: result = $signed(A) + $signed(B);        // add
                    3'b001: result = $signed(A) - $signed(B);        // sub
                    3'b010: {hi, lo} = $signed(A) * $signed(B);      // mult
                    3'b011: if (B != 0) begin                        // div
                                 lo = $signed(A) / $signed(B);
                                 hi = $signed(A) % $signed(B);
                             end
                    3'b100: result = ($signed(A) < $signed(B));      // slt
                    3'b101: result = (A == B);                       // seq
                    3'b110: result = (A < B);                        // sltu (unsigned)
                    3'b111: result = A;                              // jr passes rs value forward
                endcase
            end

            4'b0010: begin  // ALU2 (shift / rotate)
                case (funct)
                    3'b000: result = B >> A[3:0];                    // shr
                    3'b001: result = B << A[3:0];                    // shl
                    3'b010: result = ror16(B, A[3:0]);               // ror
                    3'b011: result = rol16(B, A[3:0]);               // rol
                    default: result = 16'b0;
                endcase
            end

            4'b0011: result = $signed(A) + $signed(B);               // ADDI
            4'b0100: result = ($signed(A) < $signed(B));             // SLTI
            4'b0101: result = (A != B) ? 16'h0001 : 16'h0000;        // BNEQ comparison
            4'b0110: result = ($signed(A) > 0) ? 16'h0001 : 16'h0000;// BGTZ comparison
            4'b1000,
            4'b1001: result = A + B;                                 // LH / SH address calc
            default: result = A + B;
        endcase

        zero_flag = (result == 16'b0);
        sign_flag = result[15];
    end
endmodule
