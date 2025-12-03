`timescale 1ns / 1ps

// [MOD] Rebuilt pipeline datapath to honor HK251 5-stage flow with stalls/flush.
module Datapath(
    input         clk,
    input         reset,
    input  [15:0] instruction,
    input  [6:0]  alu_op,
    input         reg_write,
    input         mem_read,
    input         mem_write,
    input         branch_bneq,
    input         branch_bgtz,
    input         jump_abs,
    input         jump_reg,
    input  [1:0]  alu_src,
    input         mem_to_reg,
    input         mtsr_write,
    input         mfsr_read,
    input  [2:0]  special_sel,
    input         rd_is_dest,
    input         halt_decode,
    output [15:0] pc_out,
    output        halt
);

    // ------------------------------------------------------------------
    // IF stage registers
    // ------------------------------------------------------------------
    reg [15:0] pc_q;
    reg [15:0] IF_ID_instr;
    reg [15:0] IF_ID_pc_plus2;

    wire [15:0] pc_plus2 = pc_q + 16'd2;

    // ------------------------------------------------------------------
    // ID/EX pipeline registers
    // ------------------------------------------------------------------
    reg [3:0]  ID_EX_opcode;
    reg [2:0]  ID_EX_funct;
    reg [2:0]  ID_EX_rs_addr;
    reg [2:0]  ID_EX_rt_addr;
    reg [2:0]  ID_EX_rd_addr;
    reg [2:0]  ID_EX_dest_addr;
    reg [5:0]  ID_EX_imm6;
    reg [11:0] ID_EX_jump_addr;
    reg [15:0] ID_EX_rs_data;
    reg [15:0] ID_EX_rt_data;
    reg [15:0] ID_EX_special_data;
    reg [6:0]  ID_EX_alu_op;
    reg [1:0]  ID_EX_alu_src;
    reg        ID_EX_reg_write;
    reg        ID_EX_mem_read;
    reg        ID_EX_mem_write;
    reg        ID_EX_branch_bneq;
    reg        ID_EX_branch_bgtz;
    reg        ID_EX_jump_abs;
    reg        ID_EX_jump_reg;
    reg        ID_EX_mem_to_reg;
    reg        ID_EX_mtsr_write;
    reg        ID_EX_mfsr_read;
    reg [2:0]  ID_EX_special_sel;
    reg [15:0] ID_EX_pc_plus2;
    reg        ID_EX_halt;

    // ------------------------------------------------------------------
    // EX/MEM and MEM/WB registers
    // ------------------------------------------------------------------
    reg [15:0] EX_MEM_result;
    reg [15:0] EX_MEM_rt_data;
    reg [2:0]  EX_MEM_dest_addr;
    reg        EX_MEM_reg_write;
    reg        EX_MEM_mem_read;
    reg        EX_MEM_mem_write;
    reg        EX_MEM_mem_to_reg;
    reg        EX_MEM_mtsr_write;
    reg [2:0]  EX_MEM_special_sel;
    reg [15:0] EX_MEM_special_bus;

    reg [15:0] MEM_WB_result;
    reg [15:0] MEM_WB_mem_data;
    reg [2:0]  MEM_WB_dest_addr;
    reg        MEM_WB_reg_write;
    reg        MEM_WB_mem_to_reg;
    reg        MEM_WB_mtsr_write;
    reg [2:0]  MEM_WB_special_sel;
    reg [15:0] MEM_WB_special_bus;

    // ------------------------------------------------------------------
    // Instruction field extraction (3-bit register spec)
    // ------------------------------------------------------------------
    wire [3:0] opcode_if = IF_ID_instr[15:12];
    wire [2:0] rs_if     = IF_ID_instr[11:9];
    wire [2:0] rt_if     = IF_ID_instr[8:6];
    wire [2:0] rd_if     = IF_ID_instr[5:3];
    wire [2:0] funct_if  = IF_ID_instr[2:0];
    wire [5:0] imm6_if   = IF_ID_instr[5:0];
    wire [11:0] jump_addr_if = IF_ID_instr[11:0];

    // ------------------------------------------------------------------
    // Register file + forwarding signals
    // ------------------------------------------------------------------
    wire [15:0] rs_data;
    wire [15:0] rt_data;
    wire [15:0] special_read_data;
    wire [15:0] data_mem_rdata;

    wire [15:0] wb_data = MEM_WB_mem_to_reg ? MEM_WB_mem_data : MEM_WB_result;

    wire [15:0] forward_from_ex = EX_MEM_result;
    wire [15:0] forward_from_wb = wb_data;

    wire hit_ex_a = EX_MEM_reg_write && (EX_MEM_dest_addr == ID_EX_rs_addr) && (EX_MEM_dest_addr != 3'b000);
    wire hit_wb_a = MEM_WB_reg_write && (MEM_WB_dest_addr == ID_EX_rs_addr) && (MEM_WB_dest_addr != 3'b000);
    wire hit_ex_b = EX_MEM_reg_write && (EX_MEM_dest_addr == ID_EX_rt_addr) && (EX_MEM_dest_addr != 3'b000);
    wire hit_wb_b = MEM_WB_reg_write && (MEM_WB_dest_addr == ID_EX_rt_addr) && (MEM_WB_dest_addr != 3'b000);

    wire [15:0] alu_a =
        hit_ex_a ? forward_from_ex :
        hit_wb_a ? forward_from_wb :
        ID_EX_rs_data;

    wire [15:0] rt_forward =
        hit_ex_b ? forward_from_ex :
        hit_wb_b ? forward_from_wb :
        ID_EX_rt_data;

    wire [15:0] imm_ext = {{10{ID_EX_imm6[5]}}, ID_EX_imm6};

    wire [15:0] alu_b =
        (ID_EX_alu_src == 2'b00) ? rt_forward :
        (ID_EX_alu_src == 2'b01) ? imm_ext :
                                   16'h0000;  // compare with zero

    // ------------------------------------------------------------------
    // ALU + branch control
    // ------------------------------------------------------------------
    wire [15:0] alu_result;
    wire [15:0] alu_hi;
    wire [15:0] alu_lo;
    wire        zero_flag;
    wire        sign_flag;

    ALU alu_inst(
        .A(alu_a),
        .B(alu_b),
        .op(ID_EX_alu_op),
        .result(alu_result),
        .hi(alu_hi),
        .lo(alu_lo),
        .zero_flag(zero_flag),
        .sign_flag(sign_flag)
    );

    wire branch_taken = (ID_EX_branch_bneq && alu_result[0]) ||
                        (ID_EX_branch_bgtz && alu_result[0]);
    wire jump_taken   = ID_EX_jump_abs;
    wire jr_taken     = ID_EX_jump_reg;
    wire flush_pipe   = branch_taken || jump_taken || jr_taken;

    wire [15:0] branch_target = ID_EX_pc_plus2 + {{9{ID_EX_imm6[5]}}, ID_EX_imm6, 1'b0};
    wire [15:0] jump_target   = {ID_EX_pc_plus2[15:13], ID_EX_jump_addr, 1'b0};
    wire [15:0] jr_target     = alu_a;

    wire [15:0] next_pc_seq = pc_plus2;
    wire [15:0] pc_next =
        jr_taken     ? jr_target   :
        jump_taken   ? jump_target :
        branch_taken ? branch_target :
                       next_pc_seq;

    // ------------------------------------------------------------------
    // Load-use hazard detection
    // ------------------------------------------------------------------
    wire load_stall = ID_EX_mem_read &&
                      ((ID_EX_dest_addr == rs_if) ||
                       (ID_EX_dest_addr == rt_if));

    // ------------------------------------------------------------------
    // Halt handling
    // ------------------------------------------------------------------
    reg halt_latched;

    // ------------------------------------------------------------------
    // Sequential logic
    // ------------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_q              <= 16'h0000;
            IF_ID_instr       <= 16'h0000;
            IF_ID_pc_plus2    <= 16'h0000;
            ID_EX_opcode      <= 4'b0000;
            ID_EX_funct       <= 3'b000;
            ID_EX_rs_addr     <= 3'b000;
            ID_EX_rt_addr     <= 3'b000;
            ID_EX_rd_addr     <= 3'b000;
            ID_EX_dest_addr   <= 3'b000;
            ID_EX_imm6        <= 6'b000000;
            ID_EX_jump_addr   <= 12'h000;
            ID_EX_rs_data     <= 16'h0000;
            ID_EX_rt_data     <= 16'h0000;
            ID_EX_special_data<= 16'h0000;
            ID_EX_alu_op      <= 6'b000000;
            ID_EX_alu_src     <= 2'b00;
            ID_EX_reg_write   <= 1'b0;
            ID_EX_mem_read    <= 1'b0;
            ID_EX_mem_write   <= 1'b0;
            ID_EX_branch_bneq <= 1'b0;
            ID_EX_branch_bgtz <= 1'b0;
            ID_EX_jump_abs    <= 1'b0;
            ID_EX_jump_reg    <= 1'b0;
            ID_EX_mem_to_reg  <= 1'b0;
            ID_EX_mtsr_write  <= 1'b0;
            ID_EX_mfsr_read   <= 1'b0;
            ID_EX_special_sel <= 3'b000;
            ID_EX_pc_plus2    <= 16'h0000;
            ID_EX_halt        <= 1'b0;
            EX_MEM_result     <= 16'h0000;
            EX_MEM_rt_data    <= 16'h0000;
            EX_MEM_dest_addr  <= 3'b000;
            EX_MEM_reg_write  <= 1'b0;
            EX_MEM_mem_read   <= 1'b0;
            EX_MEM_mem_write  <= 1'b0;
            EX_MEM_mem_to_reg <= 1'b0;
            EX_MEM_mtsr_write <= 1'b0;
            EX_MEM_special_sel<= 3'b000;
            EX_MEM_special_bus<= 16'h0000;
            MEM_WB_result     <= 16'h0000;
            MEM_WB_mem_data   <= 16'h0000;
            MEM_WB_dest_addr  <= 3'b000;
            MEM_WB_reg_write  <= 1'b0;
            MEM_WB_mem_to_reg <= 1'b0;
            MEM_WB_mtsr_write <= 1'b0;
            MEM_WB_special_sel<= 3'b000;
            MEM_WB_special_bus<= 16'h0000;
            halt_latched      <= 1'b0;
        end else begin
            // PC update (freeze on halt or stall)
            if (!halt_latched && !load_stall) begin
                pc_q <= pc_next;
            end

            // IF/ID register
            if (!load_stall && !halt_latched) begin
                IF_ID_instr    <= flush_pipe ? 16'h0000 : instruction;
                IF_ID_pc_plus2 <= pc_plus2;
            end

            // ID/EX register
            if (load_stall || flush_pipe) begin
                ID_EX_opcode      <= 4'b0000;
                ID_EX_funct       <= 3'b000;
                ID_EX_reg_write   <= 1'b0;
                ID_EX_mem_read    <= 1'b0;
                ID_EX_mem_write   <= 1'b0;
                ID_EX_branch_bneq <= 1'b0;
                ID_EX_branch_bgtz <= 1'b0;
                ID_EX_jump_abs    <= 1'b0;
                ID_EX_jump_reg    <= 1'b0;
                ID_EX_mem_to_reg  <= 1'b0;
                ID_EX_mtsr_write  <= 1'b0;
                ID_EX_mfsr_read   <= 1'b0;
                ID_EX_halt        <= 1'b0;
            end else begin
                ID_EX_opcode      <= opcode_if;
                ID_EX_funct       <= funct_if;
                ID_EX_rs_addr     <= rs_if;
                ID_EX_rt_addr     <= rt_if;
                ID_EX_rd_addr     <= rd_if;
                ID_EX_dest_addr   <= rd_is_dest ? rd_if : rt_if;
                ID_EX_rs_data     <= rs_data;
                ID_EX_rt_data     <= rt_data;
                ID_EX_special_data<= special_read_data;
                ID_EX_imm6        <= imm6_if;
                ID_EX_jump_addr   <= jump_addr_if;
                ID_EX_alu_op      <= alu_op;
                ID_EX_alu_src     <= alu_src;
                ID_EX_reg_write   <= reg_write;
                ID_EX_mem_read    <= mem_read;
                ID_EX_mem_write   <= mem_write;
                ID_EX_branch_bneq <= branch_bneq;
                ID_EX_branch_bgtz <= branch_bgtz;
                ID_EX_jump_abs    <= jump_abs;
                ID_EX_jump_reg    <= jump_reg;
                ID_EX_mem_to_reg  <= mem_to_reg;
                ID_EX_mtsr_write  <= mtsr_write;
                ID_EX_mfsr_read   <= mfsr_read;
                ID_EX_special_sel <= special_sel;
                ID_EX_pc_plus2    <= IF_ID_pc_plus2;
                ID_EX_halt        <= halt_decode;
            end

            // EX/MEM register
            EX_MEM_result      <= ID_EX_mfsr_read ? ID_EX_special_data : alu_result;
            EX_MEM_rt_data     <= rt_forward;
            EX_MEM_dest_addr   <= ID_EX_dest_addr;
            EX_MEM_reg_write   <= ID_EX_reg_write;
            EX_MEM_mem_read    <= ID_EX_mem_read;
            EX_MEM_mem_write   <= ID_EX_mem_write;
            EX_MEM_mem_to_reg  <= ID_EX_mem_to_reg;
            EX_MEM_mtsr_write  <= ID_EX_mtsr_write;
            EX_MEM_special_sel <= ID_EX_special_sel;
            EX_MEM_special_bus <= rt_forward;

            // MEM/WB register
            MEM_WB_result      <= EX_MEM_result;
            MEM_WB_mem_data    <= data_mem_rdata;
            MEM_WB_dest_addr   <= EX_MEM_dest_addr;
            MEM_WB_reg_write   <= EX_MEM_reg_write;
            MEM_WB_mem_to_reg  <= EX_MEM_mem_to_reg;
            MEM_WB_mtsr_write  <= EX_MEM_mtsr_write;
            MEM_WB_special_sel <= EX_MEM_special_sel;
            MEM_WB_special_bus <= EX_MEM_special_bus;

            // Halt latch
            if (!halt_latched && ID_EX_halt) begin
                halt_latched <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------
    // Data memory (word aligned)
    // ------------------------------------------------------------------
    Memory data_mem_inst(
        .clk(clk),
        .address(EX_MEM_result),
        .write_data(EX_MEM_rt_data),
        .mem_read(EX_MEM_mem_read),
        .mem_write(EX_MEM_mem_write),
        .read_data(data_mem_rdata)
    );

    // ------------------------------------------------------------------
    // Register file with special register access
    // ------------------------------------------------------------------
    wire ex_is_mul = (ID_EX_opcode == 4'b0000 || ID_EX_opcode == 4'b0001) && (ID_EX_funct == 3'b010);
    wire ex_is_div = (ID_EX_opcode == 4'b0000 || ID_EX_opcode == 4'b0001) && (ID_EX_funct == 3'b011);
    wire hi_lo_we  = ex_is_mul || ex_is_div;

    RegisterFile rf_inst(
        .clk(clk),
        .reset(reset),
        .rs_addr(rs_if),
        .rt_addr(rt_if),
        .rd_addr(MEM_WB_dest_addr),
        .rd_write_en(MEM_WB_reg_write),
        .rd_write_data(wb_data),
        .mtsr_write_en(MEM_WB_mtsr_write),
        .mtsr_sel(MEM_WB_special_sel),
        .mtsr_data(MEM_WB_special_bus),
        .hi_we(hi_lo_we),
        .lo_we(hi_lo_we),
        .hi_data(alu_hi),
        .lo_data(alu_lo),
        .special_sel(special_sel),
        .pc_value(pc_q),
        .rs_data(rs_data),
        .rt_data(rt_data),
        .special_read_data(special_read_data)
    );

    assign pc_out = pc_q;
    assign halt   = halt_latched;

endmodule
