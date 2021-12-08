`include "pipeline_latch_if.vh"
`include "cpu_types_pkg.vh"

module pipeline_latch(
    input logic CLK,
    input logic nRST,
    input logic enable,
    input logic flush,
    pipeline_latch_if plif);
    import cpu_types_pkg::*;

    word_t [23:0] pipe;
    word_t [23:0] next_pipe;

    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            for (int i = 0; i < 23; i++) begin
                pipe[i] <= '0;
            end
        end
        else begin
            pipe <= next_pipe;
        end
    end

    always_comb begin
        next_pipe = pipe;
        if (enable == 1'b1 && flush == 1'b0) begin
            next_pipe[0] = plif.instr_i;
            next_pipe[1] = plif.bne_i;
            next_pipe[2] = plif.beq_i;
            next_pipe[3] = plif.alusrc_i;
            next_pipe[4] = plif.extop_i;
            next_pipe[5] = plif.regwr_i;
            next_pipe[6] = plif.load_i;
            next_pipe[7] = plif.store_i;
            /*if (plif.halt_i == 1'b1) begin
                next_pipe[8] = 1'b1;
        end
                else begin
                next_pipe[8] = pipe[8];
        end*/ // if (enable == 1'b1 && flush == 1'b0)
                next_pipe[8] = plif.halt_i;
                next_pipe[9] = plif.regdst_i;
                next_pipe[10] = plif.aluop_i;
                next_pipe[11] = plif.portA_i;
                next_pipe[12] = plif.portB_i;
                next_pipe[13] = plif.outPort_i;
                next_pipe[14] = plif.imm32_ex_i;
                next_pipe[15] = plif.dmemload_i;
                next_pipe[16] = plif.zero_i;
                next_pipe[17] = plif.pc_plus_4_i;
                next_pipe[18] = plif.memtoreg_i;
                next_pipe[19] = plif.branch_addr_i;
                next_pipe[20] = plif.pc_i;
                next_pipe[21] = plif.lui_i;
                next_pipe[22] = plif.branched_i;
                next_pipe[23] = plif.datomic_i;

        end
        else if (flush == 1'b1) begin
            next_pipe = '0;
            //next_pipe[22] = plif.branched_i;
        end
        //else next_pipe[22] = plif.branched_i;
        /*
        else if (flush == 1'b1) begin
        for (int i = 0; i < 27; i++) begin
        if (i != 25) begin
        next_pipe[i] = '0;
    end
    end
    end*/
    end

    assign plif.instr_o = pipe[0];
    assign plif.bne_o = pipe[1][0];
    assign plif.beq_o = pipe[2][0];
    assign plif.alusrc_o = pipe[3][0];
    assign plif.extop_o = pipe[4][0];
    assign plif.regwr_o = pipe[5][0];
    assign plif.load_o = pipe[6][0];
    assign plif.store_o = pipe[7][0];
    assign plif.halt_o = pipe[8][0];
    assign plif.rs_o = pipe[0][25:21];
    assign plif.rt_o = pipe[0][20:16];
    assign plif.rd_o = pipe[0][15:11];
    assign plif.opcode_o = opcode_t'(pipe[0][31:26]);
    assign plif.imm16_o = pipe[0][15:0];
    assign plif.regdst_o = pipe[9][1:0];
    assign plif.aluop_o = aluop_t'(pipe[10][5:0]);
    assign plif.portA_o = pipe[11];
    assign plif.portB_o = pipe[12];
    assign plif.outPort_o = pipe[13];
    assign plif.imm32_ex_o = pipe[14];
    assign plif.jump_addr_o = {pipe[17][31:28],pipe[0][25:0],2'b00};
    assign plif.dmemload_o = pipe[15];
    assign plif.zero_o = pipe[16][0];
    assign plif.pc_plus_4_o = pipe[17];
    assign plif.memtoreg_o = pipe[18][1:0];
    assign plif.branch_addr_o = pipe[19];
    assign plif.func_o = funct_t'(pipe[0][5:0]);
    assign plif.pc_o = pipe[20];
    assign plif.lui_o = pipe[21];
    assign plif.branched_o = pipe[22];
    assign plif.datomic_o = pipe[23][0];

endmodule

