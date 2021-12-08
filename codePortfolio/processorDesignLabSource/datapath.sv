/*
Ryan Cleary and Zhewen Pan
https://github.com/pan185/437
*/
`include "datapath_cache_if.vh"
`include "request_datapath_if.vh"
`include "alu_control_datapath_if.vh"
`include "alu_if.vh"
`include "control_datapath_if.vh"
`include "instructionfetch_datapath_if.vh"
`include "register_file_if.vh"
`include "request_datapath_if.vh"
`include "hazard_unit_if.vh"
`include "pipeline_latch_if.vh"
`include "cpu_types_pkg.vh"
`include "forwarding_unit_if.vh"
//2. Portlist, b
module datapath (
    input logic CLK, nRST,
    datapath_cache_if.dp dpif
);

    import cpu_types_pkg::*;
    parameter PC_INIT = 0;
    logic changepc_branch;
    logic dont_branch;
    logic if_id_enable;
    logic if_id_flush;
    logic id_ex_enable;
    logic id_ex_flush;
    logic ex_mem_enable;
    logic ex_mem_flush;
    logic mem_wb_enable;
    logic mem_wb_flush;
    logic  next_memRENWEN;
    logic  memRENWEN;
    logic   branched;
    word_t dmemload;
    word_t next_dmemload;
    word_t wdata, wdata_wb;
    logic   wrong;
    logic takebranch;
    regbits_t wsel;
    logic  halt;
    logic  next_halt;
    logic data_op_done, next_data_op_done;
   logic  memop_override;
   

    //interfaces
    alu_control_datapath_if acif();
    alu_if aif();
    control_unit_if cuif();
    instructionfetch_datapath_if ifif();
    register_file_if rfif();
    pipeline_latch_if plif_if_id();
    pipeline_latch_if plif_id_ex();
    pipeline_latch_if plif_ex_mem();
    pipeline_latch_if plif_mem_wb();
    hazard_unit_if huif();
    forwarding_unit_if fuif();

    //Modules
    alu_control ac(.acif(acif));
    alu alu(.aface(aif));
    control_unit cu(.CLK(CLK), .nRST(nRST), .cuif(cuif));
    instructionfetch #(.PC_INIT(PC_INIT)) iu (.CLK(CLK), .nRST(nRST), .ifif(ifif), .takebranch(takebranch),.memop_override(memop_override));
    register_file rf(.CLK(CLK), .nRST(nRST), .rfif(rfif));
    pipeline_latch if_id(.CLK (CLK), .nRST(nRST), .enable (if_id_enable),
        .flush (if_id_flush), .plif(plif_if_id));
    pipeline_latch id_ex(.CLK (CLK), .nRST(nRST), .enable (id_ex_enable),
        .flush (id_ex_flush), .plif(plif_id_ex));
    pipeline_latch ex_mem(.CLK (CLK), .nRST(nRST), .enable (ex_mem_enable),
        .flush (ex_mem_flush), .plif(plif_ex_mem));
    pipeline_latch mem_wb(.CLK (CLK), .nRST(nRST), .enable (mem_wb_enable),
        .flush (mem_wb_flush), .plif(plif_mem_wb));
    hazard_unit hu(.huif(huif),.wrong(wrong));
    forwarding_unit fu(.fuif(fuif));
    saturating2 predictor(.CLK(CLK), .nRST(nRST), .takebranch(takebranch), .exmembne_o(plif_ex_mem.bne_o), .exmembeq_o(plif_ex_mem.beq_o), .changepc_branch(changepc_branch), .pcmem(plif_ex_mem.pc_o), .pc(ifif.pc_out), .ihit(dpif.ihit));


    always_comb begin
        wrong = 1'b0;
        if (plif_ex_mem.branched_o == 1'b1) begin
            if((dont_branch == 1'b1 || plif_id_ex.pc_o != plif_ex_mem.branch_addr_o) /*|| ((plif_ex_mem.bne_o == 1'b0) && (plif_ex_mem.beq_o == 1'b0))*/) wrong = 1'b1;
            else wrong = 1'b0;
            if((plif_ex_mem.bne_o == 1'b0) && (plif_ex_mem.beq_o == 1'b0)) wrong = 1'b1;
        end
        else begin
            if((changepc_branch == 1'b1)/* || ((plif_ex_mem.bne_o == 1'b0) && (plif_ex_mem.beq_o == 1'b0))*/) wrong = 1'b1;
            else wrong = 1'b0;
        end

    end 

    always_ff @(posedge CLK, negedge nRST) begin
        if(!nRST) begin
            memRENWEN <= '0;
            halt <= '0;
        end
        else begin
            memRENWEN <= next_memRENWEN;
            halt <= next_halt;
        end
    end

    always_comb begin
        //mem stage
        next_halt = halt;
        if(plif_ex_mem.halt_o) next_halt = '1;
    end
    always_comb begin
        wsel = '0;
        next_memRENWEN = memRENWEN;
        dpif.dmemWEN = plif_ex_mem.store_o && memRENWEN;
        dpif.dmemREN = plif_ex_mem.load_o && memRENWEN;
        //turn off  R/WEN on dhit

        if(dpif.dhit)begin
            next_memRENWEN = '0;
        end
        else if (dpif.ihit)begin
            next_memRENWEN = '1;
        end

        //pipeline latch
        if_id_enable = 1'b0;
        id_ex_enable = 1'b0;
        ex_mem_enable = 1'b0;
        mem_wb_enable = 1'b0;
        ifif.pc_disable = 1'b1;
        mem_wb_flush = dpif.ihit ? huif.memwb_flush : 1'b0;
        ex_mem_flush = (dpif.ihit && (huif.ifid_flush)) ? huif.exmem_flush : 1'b0;
        if_id_flush = dpif.ihit ? huif.ifid_flush : 1'b0;
        id_ex_flush = dpif.ihit ? huif.idex_flush : 1'b0;
       memop_override = 0;
       

        //disable pipeline registers on ihit = 0 or halt

        if (dpif.ihit == 1'b1 && !(plif_ex_mem.load_o || plif_ex_mem.store_o)) begin 
            mem_wb_enable = 1'b1;
            if_id_enable = 1'b1;
            id_ex_enable = 1'b1;
            ex_mem_enable = 1'b1;
            ifif.pc_disable = 1'b0;
            if (fuif.hu_override_ex == 1'b0) begin 
                if_id_enable = ~huif.ifid_disable;
                id_ex_enable = ~huif.idex_disable;
                ifif.pc_disable = huif.pc_disable;
                ex_mem_flush = dpif.ihit ? huif.exmem_flush : 1'b0;
            end
        end
        else if (dpif.ihit == 1'b1 
            && dpif.dhit == 1'b0 
            && (plif_ex_mem.load_o || plif_ex_mem.store_o)) begin
                mem_wb_enable = 1'b0;
                if_id_enable = 1'b0;
                id_ex_enable = 1'b0;
                ex_mem_enable = 1'b0;
                ifif.pc_disable = 1'b1;
	   memop_override = '1;
        end
        else if (dpif.dhit == 1'b1 
            && dpif.ihit == 1'b0 
            && (plif_ex_mem.load_o || plif_ex_mem.store_o)) begin
                mem_wb_enable = 1'b1;
                if_id_enable = 1'b0;
                id_ex_enable = 1'b0;
                ex_mem_enable = 1'b0;
                ifif.pc_disable = 1'b1;
                ex_mem_flush = 1'b1;
	   memop_override = '1;
            end
        else if (dpif.ihit == 1'b1 
            && dpif.dhit == 1'b1
            && (plif_ex_mem.load_o || plif_ex_mem.store_o)) begin
                mem_wb_enable = 1'b1;
                if_id_enable = 1'b1;
                id_ex_enable = 1'b1;
                ex_mem_enable = 1'b1;
                ifif.pc_disable = 1'b0;
	   memop_override = '1;
                if (fuif.hu_override_ex == 1'b0) begin 
                    if_id_enable = ~huif.ifid_disable;
                    id_ex_enable = ~huif.idex_disable;
                    ifif.pc_disable = huif.pc_disable;
                    ex_mem_flush = huif.exmem_flush;
                end
            end


        //wsel inpu to hazard unit 
        if (plif_id_ex.regdst_o == 2'b01) begin
            huif.wsel_ex = plif_id_ex.rd_o;
            fuif.wsel_ex = plif_id_ex.rd_o;
        end
        else if (plif_id_ex.regdst_o == 2'b00) begin
            huif.wsel_ex = plif_id_ex.rt_o;
            fuif.wsel_ex = plif_id_ex.rt_o;
            if(plif_id_ex.opcode_o == SW || plif_id_ex.opcode_o == BEQ || plif_id_ex.opcode_o == BNE) begin
                huif.wsel_ex = '0;
                fuif.wsel_ex = '0;
            end
        end
        else begin
            huif.wsel_ex = 5'b11111;
            fuif.wsel_ex = 5'b11111;
        end
        //wsel of instruction in the mem stage input to hazard unit
        if (plif_ex_mem.regdst_o == 2'b01) begin
            huif.wsel_mem = plif_ex_mem.rd_o;
            fuif.wsel_mem = plif_ex_mem.rd_o;
        end
        else if (plif_ex_mem.regdst_o == 2'b00) begin
            huif.wsel_mem = plif_ex_mem.rt_o;
            fuif.wsel_mem = plif_ex_mem.rt_o;
        end
        else begin
            huif.wsel_mem = 5'b11111;
            fuif.wsel_mem = 5'b11111;
        end
        if (plif_mem_wb.regdst_o == 2'b01) begin
            fuif.wsel_wb = plif_mem_wb.rd_o;
        end
        else if (plif_mem_wb.regdst_o == 2'b00) begin
            fuif.wsel_wb = plif_mem_wb.rt_o;
        end
        else begin
            fuif.wsel_wb = 5'b11111;
        end

        plif_ex_mem.branch_addr_i = plif_id_ex.pc_plus_4_o + {plif_id_ex.imm32_ex_o[29:0], 2'b0};

        //extend immediate
        if (cuif.extop == 1'b1) begin
            plif_id_ex.imm32_ex_i = plif_if_id.imm16_o[15] == 1'b1 
                                    ? {{16{plif_if_id.imm16_o[15]}},plif_if_id.imm16_o}
                                    : {16'b0,plif_if_id.imm16_o};
        end
        else begin
            plif_id_ex.imm32_ex_i = {16'b0,plif_if_id.imm16_o};
        end

        if (plif_ex_mem.memtoreg_o == 2'b00) begin
            wdata = plif_ex_mem.outPort_o;
        end
        /*
         *else if (plif_ex_mem.memtoreg_o == 2'b01) begin
         *    wdata = dpif.dmemload;
         *end
         */
        else if (plif_ex_mem.memtoreg_o == 2'b10) begin
            wdata = plif_ex_mem.lui_o;
        end
        else begin
            wdata = plif_ex_mem.pc_plus_4_o;
        end

        if (plif_mem_wb.memtoreg_o == 2'b01) begin
            wdata_wb = plif_mem_wb.dmemload_o;
        end
        else begin
            wdata_wb = plif_mem_wb.outPort_o;
        end
        
        if (fuif.portA_select == 3'b010) begin//2
            aif.portA = wdata;//plif_ex_mem.outPort_o;
        end
        else if (fuif.portA_select == 3'b011) begin//3
            aif.portA = wdata_wb;
        end
        else begin
            aif.portA = plif_id_ex.portA_o;
        end

        //choose alu input for portB
        if (plif_id_ex.alusrc_o == 1'b1) begin
            if (fuif.portB_select == 3'b010) begin//2
                aif.portB = wdata;//plif_ex_mem.outPort_o;
                plif_ex_mem.portB_i = wdata;
            end
            else if (fuif.portB_select == 3'b011) begin//3
                aif.portB = wdata_wb;
                plif_ex_mem.portB_i = wdata_wb;
            end
            else begin
                aif.portB = plif_id_ex.portB_o;
                plif_ex_mem.portB_i = plif_id_ex.portB_o;
            end
        end
        else begin
            aif.portB = plif_id_ex.imm32_ex_o;
            if (fuif.portB_select == 3'b010) begin
                plif_ex_mem.portB_i = wdata;//plif_ex_mem.outPort_o;
            end
            else if (fuif.portB_select == 3'b011) begin
                plif_ex_mem.portB_i = wdata_wb;//wdata;
            end
            else begin
                plif_ex_mem.portB_i = plif_id_ex.portB_o;
            end
        end

        //choose input to wsel
        if (plif_mem_wb.regdst_o == 2'b01) begin
            rfif.wsel = plif_mem_wb.rd_o;
            //wsel = plif_mem_wb.rd_o;
        end
        else if (plif_mem_wb.regdst_o == 2'b00) begin
            rfif.wsel = plif_mem_wb.rt_o;
            wsel = plif_mem_wb.rt_o;
        end
        else begin
            rfif.wsel = 5'b11111;
            //wsel = 5'b11111;
        end

        //calculate whether branch will be taken
        changepc_branch = (plif_ex_mem.zero_o && plif_ex_mem.beq_o)
                          | (!(plif_ex_mem.zero_o) && plif_ex_mem.bne_o);
        dont_branch = (plif_ex_mem.zero_o && plif_ex_mem.bne_o)
                      | (!(plif_ex_mem.zero_o) && plif_ex_mem.beq_o);

    end

    //inputs of the four pipeline latches
    assign plif_if_id.instr_i = dpif.imemload;
    assign plif_if_id.bne_i = '0;
    assign plif_if_id.beq_i = '0;
    assign plif_if_id.alusrc_i = '0;
    assign plif_if_id.extop_i = '0;
    assign plif_if_id.regwr_i = '0;
    assign plif_if_id.load_i = '0;
    assign plif_if_id.store_i = '0;
    assign plif_if_id.halt_i = '0;
    assign plif_if_id.regdst_i = '0;
    assign plif_if_id.memtoreg_i = '0;
    assign plif_if_id.aluop_i = aluop_t'(ALU_SLL);
    assign plif_if_id.portA_i = '0;
    assign plif_if_id.portB_i = '0;
    assign plif_if_id.outPort_i = '0;
    assign plif_if_id.imm32_ex_i = '0;
    assign plif_if_id.dmemload_i = '0;
    assign plif_if_id.zero_i = '0;
    assign plif_if_id.pc_plus_4_i = ifif.pcplusfour;
    assign plif_if_id.branch_addr_i = '0;
    assign plif_if_id.pc_i = ifif.pc_out;
    assign plif_if_id.lui_i = '0;
    assign plif_if_id.branched_i = branched;
    assign plif_if_id.datomic_i = '0;


    //id_ex inputs
    assign plif_id_ex.instr_i = plif_if_id.instr_o;
    assign plif_id_ex.bne_i = cuif.bne;
    assign plif_id_ex.beq_i = cuif.beq;
    assign plif_id_ex.alusrc_i = cuif.alusrc;
    assign plif_id_ex.extop_i = cuif.extop;
    assign plif_id_ex.regwr_i = cuif.regwen;
    assign plif_id_ex.load_i = cuif.load;
    assign plif_id_ex.store_i = cuif.store;
    assign plif_id_ex.halt_i = cuif.halt;
    assign plif_id_ex.regdst_i = cuif.regdest;
    assign plif_id_ex.memtoreg_i = cuif.wdatasrc;
    assign plif_id_ex.aluop_i = acif.aluop;
    assign plif_id_ex.portA_i = rfif.rdat1;
    assign plif_id_ex.portB_i = rfif.rdat2;
    assign plif_id_ex.outPort_i = '0;
    assign plif_id_ex.dmemload_i = '0;
    assign plif_id_ex.zero_i = '0;
    assign plif_id_ex.pc_plus_4_i = plif_if_id.pc_plus_4_o;
    assign plif_id_ex.branch_addr_i = plif_if_id.branch_addr_o;
    assign plif_id_ex.pc_i = plif_if_id.pc_o;
    assign plif_id_ex.lui_i = {plif_if_id.instr_o[15:0],16'h0000};
    assign plif_id_ex.branched_i = plif_if_id.branched_o;
    assign plif_id_ex.datomic_i = cuif.datomic;

    //ex_mem inputs
    assign plif_ex_mem.instr_i = plif_id_ex.instr_o;
    assign plif_ex_mem.bne_i = plif_id_ex.bne_o;
    assign plif_ex_mem.beq_i = plif_id_ex.beq_o;
    assign plif_ex_mem.alusrc_i = plif_id_ex.alusrc_o;
    assign plif_ex_mem.extop_i = plif_id_ex.extop_o;
    assign plif_ex_mem.regwr_i = plif_id_ex.regwr_o;
    assign plif_ex_mem.load_i = plif_id_ex.load_o;
    assign plif_ex_mem.store_i = plif_id_ex.store_o;
    assign plif_ex_mem.halt_i = plif_id_ex.halt_o;
    assign plif_ex_mem.regdst_i = plif_id_ex.regdst_o;
    assign plif_ex_mem.memtoreg_i = plif_id_ex.memtoreg_o;
    assign plif_ex_mem.aluop_i = plif_id_ex.aluop_o;
    assign plif_ex_mem.portA_i = (wsel == 5'd31) ? plif_mem_wb.dmemload_o : plif_id_ex.portA_o;
    assign plif_ex_mem.outPort_i = aif.outPort;
    assign plif_ex_mem.imm32_ex_i = plif_id_ex.imm32_ex_o;
    assign plif_ex_mem.dmemload_i = '0;
    assign plif_ex_mem.zero_i = aif.zero;
    assign plif_ex_mem.pc_plus_4_i = plif_id_ex.pc_plus_4_o;
    assign plif_ex_mem.pc_i = plif_id_ex.pc_o;
    assign plif_ex_mem.lui_i = plif_id_ex.lui_o;
    assign plif_ex_mem.branched_i = plif_id_ex.branched_o;
    assign plif_ex_mem.datomic_i = plif_id_ex.datomic_o;

    //mem_wb inputs
    assign plif_mem_wb.instr_i = plif_ex_mem.instr_o;
    assign plif_mem_wb.bne_i = plif_ex_mem.bne_o;
    assign plif_mem_wb.beq_i = plif_ex_mem.beq_o;
    assign plif_mem_wb.alusrc_i = plif_ex_mem.alusrc_o;
    assign plif_mem_wb.extop_i = plif_ex_mem.extop_o;
    assign plif_mem_wb.regwr_i = plif_ex_mem.regwr_o;
    assign plif_mem_wb.load_i = plif_ex_mem.load_o;
    assign plif_mem_wb.store_i = plif_ex_mem.store_o;
    assign plif_mem_wb.halt_i = plif_ex_mem.halt_o;
    assign plif_mem_wb.regdst_i = plif_ex_mem.regdst_o;
    assign plif_mem_wb.memtoreg_i = plif_ex_mem.memtoreg_o;
    assign plif_mem_wb.aluop_i = plif_ex_mem.aluop_o;
    assign plif_mem_wb.portA_i = plif_ex_mem.portA_o;
    assign plif_mem_wb.portB_i = plif_ex_mem.portB_o;
    //assign plif_mem_wb.outPort_i = plif_ex_mem.outPort_o;
    assign plif_mem_wb.outPort_i = wdata;
    assign plif_mem_wb.imm32_ex_i = plif_ex_mem.imm32_ex_o;
    assign plif_mem_wb.dmemload_i = dpif.dmemload;
    assign plif_mem_wb.zero_i = plif_ex_mem.zero_o;
    assign plif_mem_wb.pc_plus_4_i = plif_ex_mem.pc_plus_4_o;
    assign plif_mem_wb.branch_addr_i = plif_ex_mem.branch_addr_o;
    assign plif_mem_wb.pc_i = plif_ex_mem.pc_o;
    assign plif_mem_wb.lui_i = plif_ex_mem.lui_o;
    assign plif_mem_wb.branched_i = plif_ex_mem.branched_o;
    assign plif_mem_wb.datomic_i = plif_ex_mem.datomic_o;

    //register file inputs
    assign rfif.rsel1 = plif_if_id.rs_o;
    assign rfif.rsel2 = plif_if_id.rt_o;
    assign rfif.WEN = plif_mem_wb.regwr_o;
    assign rfif.wdat = wdata_wb;//wdata;
    //alu inputs
    assign aif.aluop = aluop_t'(plif_id_ex.aluop_o);

    //alu control inputs
    assign acif.alug = cuif.alug;
    assign acif.func = plif_if_id.func_o;

    //control unit inputs
    assign cuif.func = plif_if_id.func_o;
    assign cuif.opcode = plif_if_id.opcode_o;
    assign cuif.ihit = dpif.ihit;
    assign cuif.x_brnch = changepc_branch;
    assign cuif.t_brnch = dont_branch;

    //instruction fetch inputs
    assign ifif.ihit = dpif.ihit;
    assign ifif.cu_pcsrc = cuif.pcsrc;
    assign ifif.hu_pcsrc = huif.pcsrc;
    assign ifif.jaddr = plif_ex_mem.jump_addr_o;
    assign ifif.jraddr = plif_ex_mem.portA_o;
    assign ifif.baddr = plif_ex_mem.branch_addr_o;
    assign ifif.pc_override = huif.pc_override;
    assign ifif.isntr = dpif.imemload;
    assign ifif.beq_mem = plif_ex_mem.beq_o;
    assign ifif.bne_mem = plif_ex_mem.bne_o;
    assign ifif.pc_mem = plif_ex_mem.pc_o;
    assign ifif.pcbranch_mem = plif_ex_mem.branch_addr_o;
    assign branched = ifif.branched;
    
    //datapath outputs
   assign dpif.imemREN = !halt;//1'b1;
    assign dpif.dmemstore = plif_ex_mem.portB_o;
    assign dpif.imemaddr = ifif.pc_out;
    assign dpif.dmemaddr = plif_ex_mem.outPort_o;
    assign dpif.halt = halt;//plif_mem_wb.halt_o;
    assign dpif.datomic = plif_ex_mem.datomic_o;

    //hazard unit inputs
    //assign huif.instr_ex = plif_id_ex.instr_o;
    //assign huif.instr_mem = plif_ex_mem.instr_o;
    assign huif.rsel1_id = plif_if_id.rs_o;
    assign huif.rsel2_id = plif_if_id.rt_o;
    assign huif.takebranch_mem = changepc_branch;
    //assign huif.opcode_ex = plif_id_ex.opcode_o;
    assign huif.opcode_mem = plif_ex_mem.opcode_o;
    assign huif.func_mem = plif_ex_mem.func_o;
    assign huif.wr_mem = plif_ex_mem.regwr_o;
    assign huif.wr_ex = plif_id_ex.regwr_o;
    assign huif.instr_ex = plif_id_ex.instr_o;
    assign huif.instr_mem = plif_ex_mem.instr_o;
    assign huif.rsel1_ex = plif_id_ex.rs_o;
    assign huif.rsel2_ex = plif_id_ex.rt_o;

    //forwarding unit
    assign fuif.rsel1_ex = plif_id_ex.rs_o;
    assign fuif.rsel2_ex = plif_id_ex.rt_o;
    assign fuif.id_rsel1 = plif_if_id.rs_o;
    assign fuif.id_rsel2 = plif_if_id.rt_o;
    assign fuif.wen_mem = plif_ex_mem.regwr_o;
    assign fuif.wen_wb = plif_mem_wb.regwr_o;
    assign fuif.opcode_ex = plif_id_ex.opcode_o;
    assign fuif.opcode_mem = plif_ex_mem.opcode_o;
endmodule
