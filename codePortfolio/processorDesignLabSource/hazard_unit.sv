`include "cpu_types_pkg.vh"
`include "hazard_unit_if.vh"
//without wr_mem and wr_ex: mergesort takes 25181 cycles (LAT=0)syn
//with wr_mem and wr_ex: mergesort takes 25471 cycles (LAT=0)syn
//with both wr and instr: mergesort takes 24929 cycles (LAT=0)syn
//with all and check rsels: mergesort takes 24929 cycles (LAT=0)syn

//huif.rsel1->rs
//huif.rsel2->rt
//i type instructions only care about rs rsel1
module hazard_unit(hazard_unit_if.huif huif,input logic wrong);
    import cpu_types_pkg::*;
   //logic dontcare_rt_id = opcode_id == ADDIU || opcode_id == ADDI || opcode_id == ANDI || opcode_id == LUI || opcode_id == LW 
   logic dep_idmem1;
   assign dep_idmem1= (huif.wr_mem == 1'b1) && (huif.rsel1_id == huif.wsel_mem) && (huif.rsel1_id != '0);
   logic dep_idmem2;
   assign dep_idmem2= (huif.wr_mem == 1'b1) && (huif.rsel2_id == huif.wsel_mem) && (huif.rsel2_id != '0);
   logic dep_idex1;
   assign dep_idex1= (huif.wr_ex == 1'b1) && (huif.rsel1_id == huif.wsel_ex) && (huif.rsel1_id != '0);
   logic dep_idex2;
   assign dep_idex2= (huif.wr_ex == 1'b1) && (huif.rsel2_id == huif.wsel_ex) && (huif.rsel2_id != '0);
   logic dep_exmem1;
   assign dep_exmem1= (huif.wr_mem == 1'b1) && (huif.rsel1_ex == huif.wsel_mem) && (huif.rsel1_ex != '0);
   logic dep_exmem2;
   assign dep_exmem2= (huif.wr_mem == 1'b1) && (huif.rsel2_ex == huif.wsel_mem) && (huif.rsel2_ex != '0);
    
   always_comb begin
        huif.ifid_flush = 1'b0;
        huif.idex_flush = 1'b0;
        huif.exmem_flush = 1'b0;
        huif.memwb_flush = 1'b0;
        huif.pc_disable = 1'b0;
        huif.ifid_disable = 1'b0;
        huif.idex_disable = 1'b0;
        huif.pc_override = 1'b0;
        huif.pcsrc = 3'b000;
       
	   if(dep_exmem1 || dep_exmem2 || dep_idmem1 || dep_idmem2) begin 
            huif.pc_disable = 1'b1;
            huif.ifid_disable = 1'b1;
            huif.idex_disable = 1'b1;    
	      huif.exmem_flush = 1'b1;
    end
            casez(huif.opcode_mem)
                BEQ,
                BNE: begin
                    if (wrong) begin
                        huif.pc_disable = 1'b0;
                        huif.ifid_flush = 1'b1;
                        huif.idex_flush = 1'b1;
                        huif.exmem_flush = 1'b1;
                        if(huif.takebranch_mem)begin //should have taken
                            huif.pc_override = 1'b1;
                            huif.pcsrc = 3'b010;
                        end
                        else begin
                            huif.pc_override = 1'b1;
                            huif.pcsrc = 3'b100;
                        end

                    end
                end
                J,
                JAL: begin
                    huif.pc_disable = 1'b0;
                    huif.ifid_flush = 1'b1;
                    huif.idex_flush = 1'b1;
                    huif.exmem_flush = 1'b1;
                    huif.pc_override = 1'b1;
                    huif.pcsrc = 3'b011;
                end                    
                RTYPr: begin
                    if (huif.func_mem == JR) begin
                        huif.pc_disable = 1'b0;
                        huif.ifid_flush = 1'b1;
                        huif.idex_flush = 1'b1;
                        huif.exmem_flush = 1'b1;
                        huif.pc_override = 1'b1;
                        huif.pcsrc = 3'b001;
                    end
                    else begin
                        if (wrong) begin
                            huif.pc_disable = 1'b0;
                            huif.ifid_flush = 1'b1;
                            huif.idex_flush = 1'b1;
                            huif.exmem_flush = 1'b1;
                            huif.pc_override = 1'b1;
                            huif.pcsrc = 3'b100;
                        end
                    end
                end
                default: begin
                    if (wrong) begin
                        huif.pc_disable = 1'b0;
                        huif.ifid_flush = 1'b1;
                        huif.idex_flush = 1'b1;
                       huif.exmem_flush = 1'b0;
                        huif.pcsrc = 3'b100;
                    end	  
                end
            endcase
    end
endmodule
