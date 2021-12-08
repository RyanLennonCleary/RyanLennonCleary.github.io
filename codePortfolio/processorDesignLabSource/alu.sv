`include "alu_if.vh"
`include "cpu_types_pkg.vh"


module alu(
    alu_if.alu aface);
    import cpu_types_pkg::*;

    always_comb begin
        aface.overflow = 1'b0;
        aface.negative = 1'b0;
        aface.zero = 1'b0;

         unique casez(aface.aluop)
            ALU_SLL: begin
                aface.outPort = aface.portB << aface.portA[4:0]; //shift left logical, shift in zeros from the right
            end
            ALU_SRL: begin
                aface.outPort = aface.portB >> aface.portA[4:0];
            end
            ALU_ADD: begin
                aface.outPort = $signed(aface.portA) + $signed(aface.portB);
                if ((aface.portA[31] == 1 && aface.portB[31] == 1)
                        || (aface.portA[31] == 0 && aface.portB[31] == 0)) begin
                    if (aface.outPort[31] != aface.portA[31]) begin
                        aface.overflow = 1'b1;
                    end
                end
            end
            ALU_SUB: begin
                aface.outPort = $signed(aface.portA) - $signed(aface.portB);
                if ((aface.portA[31] == 1 && aface.portB[31] == 0)
                        || (aface.portA[31] == 0 && aface.portB[31] == 1)) begin
                    if (aface.outPort[31] != aface.portA[31]) begin
                        aface.overflow = 1'b1;
                    end
                end
            end
            ALU_AND: begin
                aface.outPort = aface.portA & aface.portB;
            end
            ALU_OR: begin
                aface.outPort = aface.portA | aface.portB;
            end
            ALU_XOR: begin
                aface.outPort = aface.portA ^ aface.portB;
            end
            ALU_NOR: begin
                aface.outPort = ~(aface.portA | aface.portB);
            end
            ALU_SLT: begin
                aface.outPort = $signed(aface.portA) < $signed(aface.portB) ? 32'h1 : 32'h0;
            end
            ALU_SLTU: begin
                aface.outPort = aface.portA < aface.portB ? 32'h1 : 32'h0;
            end
         endcase


    aface.negative = aface.outPort[31] == 1 ? 1'b1 : 1'b0;
    aface.zero = aface.outPort == '0 ? 1'b1 : 1'b0;
    end

endmodule
