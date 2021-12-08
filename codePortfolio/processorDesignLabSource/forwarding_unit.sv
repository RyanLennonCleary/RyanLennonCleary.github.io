`include "forwarding_unit_if.vh"
`include "cpu_types_pkg.vh"
module forwarding_unit(
    forwarding_unit_if.fu fuif);
    import cpu_types_pkg::*;

    logic dep_exmem1;
    assign dep_exmem1 = (fuif.wsel_mem == fuif.rsel1_ex) && (fuif.wen_mem);
    logic dep_exmem2;
    assign dep_exmem2 = (fuif.wsel_mem == fuif.rsel2_ex) && (fuif.wen_mem);
    logic dep_idmem1;
    assign dep_idmem1 = (fuif.wsel_mem == fuif.id_rsel1) && (fuif.wen_mem);
    logic dep_idmem2;
    assign dep_idmem2 = (fuif.wsel_mem == fuif.id_rsel2) && (fuif.wen_mem);
    logic dep_exwb1;
    assign dep_exwb1 = (fuif.wsel_wb == fuif.rsel1_ex) && (fuif.wen_wb);
    logic dep_exwb2;
    assign dep_exwb2 = (fuif.wsel_wb == fuif.rsel2_ex) && (fuif.wen_wb);

    always_comb begin
        fuif.portA_select = 3'b000; //0 for default of register file source 
        fuif.portB_select = 3'b000;
        fuif.hu_override_mem = 1'b0;
        fuif.hu_override_ex = 1'b0;
        fuif.hu_override_wb = 1'b0;
        //normal data hazard: forward
        if ((dep_exmem1) && ((fuif.opcode_mem != LW) && (fuif.opcode_mem != LL) && (fuif.opcode_mem != SW) && (fuif.opcode_mem != SC))) begin
            fuif.hu_override_ex = 1'b1;
            fuif.portA_select = 3'b010; //2 is for forwarding from mem register alu output
        end
        else if (dep_exwb1) begin
            fuif.portA_select = 3'b011; //3 is for forwarding from wb register alu output
        end
        if ((dep_exmem2) && ((fuif.opcode_mem != LW) && (fuif.opcode_mem != LL) && (fuif.opcode_mem != SW) && (fuif.opcode_mem != SC))) begin
            fuif.hu_override_ex = 1'b1;
            fuif.portB_select = 3'b010; //sam as above
        end
        else if (dep_exwb2) begin
            fuif.portB_select = 3'b011; //sam as above
        end

        if((dep_idmem1 || dep_idmem2)) begin
            fuif.hu_override_ex = 1'b1;
            if  ((fuif.opcode_ex == LW || fuif.opcode_ex == SW || fuif.opcode_ex == LL || fuif.opcode_ex == SC)) begin
                //&& (dep_exmem1 || dep_exmem2)) begin
                    fuif.hu_override_ex = 1'b0;
            end	   
        end
        if ((dep_exmem1 || dep_exmem2) && fuif.opcode_mem == LW && fuif.opcode_ex == JR) begin
            fuif.hu_override_ex = 1'b0;
        end
       if(fuif.opcode_mem == LL && fuif.opcode_ex == BNE) fuif.hu_override_ex = 1'b0;

    end
endmodule
