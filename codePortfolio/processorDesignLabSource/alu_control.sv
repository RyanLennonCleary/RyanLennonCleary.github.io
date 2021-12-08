`include "alu_control_datapath_if.vh"
`include "cpu_types_pkg.vh"

module alu_control(alu_control_datapath_if.ac acif);
    import cpu_types_pkg::*;
    always_comb begin
        unique casez(acif.alug)
            3'b000: acif.aluop = ALU_ADD;
            3'b001: acif.aluop = ALU_SUB;
            3'b010: acif.aluop = ALU_OR;
            3'b011: acif.aluop = ALU_AND;
            3'b100: begin
                unique casez(acif.func)
                    6'b000000,
                    SLLV: acif.aluop = ALU_SLL;
                    SRLV: acif.aluop = ALU_SRL;
                    JR: acif.aluop = ALU_ADD;
                    ADD: acif.aluop = ALU_ADD;
                    ADDU: acif.aluop = ALU_ADD;
                    SUB: acif.aluop = ALU_SUB;
                    SUBU: acif.aluop = ALU_SUB;
                    AND: acif.aluop = ALU_AND;
                    OR: acif.aluop = ALU_OR;
                    XOR: acif.aluop = ALU_XOR;
                    NOR: acif.aluop =ALU_NOR;
                    SLT: acif.aluop =ALU_SLT;
                    SLTU: acif.aluop =ALU_SLTU;
                    default: acif.aluop = ALU_SLL;
                endcase
            end
            3'b101: acif.aluop = ALU_SLT;
            3'b110: acif.aluop = ALU_SLTU;
            3'b111: acif.aluop = ALU_XOR;
        endcase
    end
endmodule
