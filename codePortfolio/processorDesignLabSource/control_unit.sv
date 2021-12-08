`include "control_datapath_if.vh"
`include "cpu_types_pkg.vh"


module control_unit(input logic CLK, input logic nRST, control_unit_if.cu cuif);
    import cpu_types_pkg::*;
    logic halt, next_halt;

    always_comb begin
        cuif.bne = 1'b0;
        cuif.beq = 1'b0;
        cuif.load = 1'b0;
        cuif.store = 1'b0;
        cuif.pcsrc = 3'b000;
        cuif.regdest = 2'b01;
        cuif.regwen = 1'b1;
        cuif.extop = 1'b1;
        cuif.alusrc = 1'b1;
        cuif.dmemREN = 1'b0;
        cuif.dmemWEN = 1'b0;
        cuif.wdatasrc = 2'b00;
        cuif.alug = 3'b100;
        cuif.halt = 1'b0;
        cuif.datomic = 1'b0;
        unique casez(cuif.opcode)
            RTYPr:begin
                if (cuif.func == JR) begin
                    //       cuif.pcsrc = 3'b001;
                    cuif.regwen = 1'b0;
                end
	       ///////////
		else if(cuif.func == '0) begin
		   cuif.regwen = 1'b0;
		end
	       
            end
            HALT: begin
                cuif.regwen = 1'b0;
                cuif.pcsrc = 3'b100;
                cuif.halt = 1'b1;
            end
            J: begin
                //cuif.pcsrc = 3'b011;
                cuif.regwen = 1'b0;
            end
            JAL: begin
                //cuif.pcsrc = 3'b011;
                cuif.regdest = 2'b10;
                cuif.wdatasrc = 2'b11;
            end
            BEQ: begin
                //                        cuif.pcsrc = cuif.zero == 1 ? 3'b010 : 3'b000;
                cuif.regwen = 1'b0;
                cuif.alug = 3'b001;
                cuif.beq = 1'b1;
            end
            BNE: begin
                //                      cuif.pcsrc = cuif.zero != 1 ? 3'b010 : 3'b000;
                cuif.regwen = 1'b0;
                cuif.alug = 3'b001;
                cuif.bne = 1'b1;
            end
            ADDI: begin
                cuif.regdest = 2'b00;
                cuif.alusrc = 1'b0;
                cuif.alug = 3'b000;
            end
            ADDIU: begin
                cuif.regdest = 2'b00;
                cuif.alusrc = 1'b0;
                cuif.alug = 3'b000;
            end
            SLTI: begin
                cuif.regdest = 2'b00;
                cuif.alusrc = 1'b0;
                cuif.alug = 3'b101;
            end
            SLTIU: begin
                cuif.regdest = 2'b00;
                cuif.extop = 1'b0;
                cuif.alusrc = 1'b0;
                cuif.alug = 3'b110;
            end
            ANDI: begin
                cuif.regdest = 2'b00;
                cuif.extop = 1'b0;
                cuif.alusrc = 1'b0;
                cuif.alug = 3'b011;
            end
            ORI: begin
                cuif.regdest = 2'b00;
                cuif.extop = 1'b0;
                cuif.alusrc = 1'b0;
                cuif.alug = 3'b010;
            end
            XORI: begin
                cuif.regdest = 2'b00;
                cuif.extop = 1'b0;
                cuif.alusrc = 1'b0;
                cuif.alug = 3'b111;
            end
            LUI: begin
                cuif.regdest = 2'b00;
                cuif.wdatasrc = 2'b10;
            end
            LW: begin
                cuif.regdest = 2'b00;
                cuif.alusrc = 1'b0;
                cuif.dmemREN = 1'b1;
                cuif.wdatasrc = 2'b01;
                cuif.alug = 3'b000;
                cuif.load = 1'b1;
                cuif.extop = 1'b0;
            end
            SW: begin
                cuif.regwen = 1'b0;
                cuif.alusrc = 1'b0;
                cuif.dmemWEN = 1'b1;
                cuif.alug = 3'b000;
                cuif.store = 1'b1;
                cuif.regdest = 2'b01; //set regdest to rs, the calculated value in aluout is rs not rt    
                cuif.extop = 1'b0;
	    end
            LL: begin
                cuif.regdest = 2'b00;
                cuif.alusrc = 1'b0;
                cuif.dmemREN = 1'b1;
                cuif.wdatasrc = 2'b01;
                cuif.alug = 3'b000;
                cuif.load = 1'b1;
                cuif.datomic = 1'b1;
                cuif.extop = 1'b0;
            end
            SC: begin
	       cuif.wdatasrc = 2'b01;
                cuif.alusrc = 1'b0;
                cuif.dmemWEN = 1'b1;
                cuif.alug = 3'b000;
                cuif.store = 1'b1;
                cuif.regdest = 2'b00;
                cuif.extop = 1'b0;
                cuif.datomic = 1'b1;
            end


        endcase
        //                    if (cuif.x_brnch == 1'b1) begin
        //                        cuif.pcsrc = 3'b000;
        //                    end
        //                    //if branch taken override pc source to branch address
        //                    else if (cuif.t_brnch == 1'b1) begin
        //                        cuif.pcsrc = 3'b010;
        //                    end
    end
endmodule
