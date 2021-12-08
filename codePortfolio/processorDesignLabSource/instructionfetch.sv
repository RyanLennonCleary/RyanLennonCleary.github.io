`include "instructionfetch_datapath_if.vh"
`include "cpu_types_pkg.vh"
import cpu_types_pkg::*;
module instructionfetch(
			input logic CLK,
			input logic nRST,
			//input logic beq_mem, bne_mem,//BTB input from exmem
			//input word_t pc_mem,//BTB input from exmem
			//input word_t pcbranch_mem,
			//output logic branched,
			instructionfetch_datapath_if.in ifif,
            input logic takebranch,
			input memop_override);
    parameter PC_INIT = 0;
    
    word_t pc;
    word_t next_pc;
    word_t pcplusfour;
    word_t pc_mem_plus_four;
    logic [2:0] pcsrc;
    word_t [63:0] branch_target;
    word_t read_branch_target;
   
   ////////BTB///////
   assign read_branch_target = branch_target[(pc[7:2])];
   always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
	   branch_target <= '0;
        end
        else begin
	   branch_target <= branch_target;
	   if(ifif.beq_mem || ifif.bne_mem) begin //write BTB
	      branch_target[(ifif.pc_mem[7:2])] <= {1'b1,ifif.pcbranch_mem[30:0]};
	   end
        end
    end
   //////////BTB/////////
   
    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            pc <= PC_INIT;
        end
        else begin
            pc <= next_pc;
        end
    end
   
    always_comb begin
        next_pc = pc;
        pcplusfour = pc + 3'd4;
        pc_mem_plus_four = ifif.pc_mem + 32'd4;
        ifif.branched = '0;
        //determine source for next pc
        if (ifif.ihit == 1'b1 && ifif.pc_disable == 1'b0) begin
            if (ifif.hu_pcsrc == 3'b000) begin //normal
                next_pc = pcplusfour;//pc + 3'b100;
                /////////if hit select branch target addr 
                if((read_branch_target[31] != '0) && takebranch)begin
                    ifif.branched='1;
                    next_pc = {1'b0,read_branch_target[30:0]};
                end
            end
            else if (ifif.hu_pcsrc == 3'b010) begin //branch
                next_pc = ifif.baddr;
            end
            else if (ifif.hu_pcsrc == 3'b100) begin
                //pc_mem + 4
                next_pc = pc_mem_plus_four;//ifif.pc_mem + 32'd4;
            end

            else if (ifif.hu_pcsrc == 3'b001) begin
                next_pc = ifif.jraddr;
            end
            else if (ifif.hu_pcsrc == 3'b011) begin
                //jump address = 4msbs of pc,jumpaddress and left shifted two
                next_pc = ifif.jaddr;
            end
        end // if (ifif.ihit == 1'b1 && ifif.pc_disable == 1'b0)
       
       if(memop_override && ifif.hu_pcsrc == 3'b100) next_pc = pc_mem_plus_four;
    end

    assign ifif.pc_out = pc;
    assign ifif.pcplusfour = pcplusfour;
endmodule
