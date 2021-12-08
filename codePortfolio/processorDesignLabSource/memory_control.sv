/*
Eric Villasenor
evillase@gmail.com

this block is the coherence protocol
and artibtration for ram
*/

// interface include
`include "cache_control_if.vh"

// memory types
`include "cpu_types_pkg.vh"

module memory_control (
    input logic CLK,
    input logic nRST,
    cache_control_if.cc ccif);
    // type import
    import cpu_types_pkg::*;
    // number of cpus for cc
    parameter CPUS = 2;
    word_t iaddr;
    enum logic [4:0] {REQUEST, GRANT, SNOOP, BUSRD1, BUSRD2, BUSWB1, BUSWB2, SELFWB1, SELFWB2, REPLYREAD, REPLYWRITE, COMPLETEREAD, COMPLETEWRITE, BUSRDX1, BUSRDX2, COMPLETESELFWB} state, next_state;
    logic next_service,service;
    word_t daddr_reg, next_daddr_reg;
    word_t daddr_reg0, daddr_reg1;
    logic cache_WEN0, next_cache_WEN0;
    logic cache_REN0, next_cache_REN0;
    logic cache_WEN1, next_cache_WEN1;
    logic cache_REN1, next_cache_REN1;
    logic bus_ramren;
    word_t dload, next_dload;
    word_t dstore, next_dstore;
    logic bus_iwait;
    logic bus_dwait;
    logic bus_ramwen;
    word_t bus_ramaddr;
    word_t bus_ramstore;
    logic bus_iREN;
    word_t next_daddr_reg0;
    word_t next_daddr_reg1;
    logic next_iservice, iservice;
    logic bus_wait;
    word_t next_snoopaddr, snoopaddr;
    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            state <= REQUEST;
            daddr_reg <= '0;
            cache_REN0 <= '0;
            cache_REN0 <= '0;
            cache_WEN1 <= '0;
            cache_WEN1 <= '0;
            dload <= '0;
            dstore <= '0;
            service <= '0;
            daddr_reg0 <= '0;
            daddr_reg1 <= '0;
            iservice <= '0;
            snoopaddr <= '0;
        end
        else begin
            state <= next_state;
            daddr_reg <= next_daddr_reg;
            cache_REN0 <= next_cache_REN0;
            cache_WEN0 <= next_cache_WEN0;
            cache_REN1 <= next_cache_REN1;
            cache_WEN1 <= next_cache_WEN1;
            dload <= next_dload;
            dstore <= next_dstore;
            service <= next_service;
            daddr_reg0 <= next_daddr_reg0;
            daddr_reg1 <= next_daddr_reg1;
            iservice <= next_iservice;
            snoopaddr <= next_snoopaddr;
        end
    end

    always_comb begin
        //outputs to cache
        //bus_iwait = 1'b1;
        //bus_dwait = 1'b1;
        ccif.ramWEN = 1'b0;
        ccif.ramaddr = iaddr;
        ccif.ramREN = bus_iREN;
        if (bus_ramwen == 1'b1 || bus_ramren == 1'b1) begin
            ccif.ramWEN = bus_ramwen;
            ccif.ramaddr = bus_ramaddr;
            ccif.ramREN = bus_ramren;;
            if (ccif.ramstate == ACCESS) begin
                //bus_dwait = 1'b0;
            end
        end
        else begin
            if (ccif.ramstate == ACCESS) begin
                bus_iwait = 1'b0;
            end
        end
    end
    assign ccif.ramstore = bus_ramstore;
    assign ccif.iload[0] = ccif.ramload;
    assign ccif.iload[1] = ccif.ramload;
    assign bus_wait = !(ccif.ramstate == ACCESS);
    //assign bus_iwait = !(ccif.ramstate == ACCESS);

    always_comb begin
        next_iservice = iservice;
        if ((ccif.iREN[0] == 1'b1) && (ccif.iREN[1] == 1'b0) && !bus_wait) begin
            next_iservice = 1'b0;
        end
        else if ((ccif.iREN[1] == 1'b1) && (ccif.iREN[0] == 1'b0) && !bus_wait) begin
            next_iservice = 1'b1;
        end
        else if (ccif.iREN[0] == 1'b1 && ccif.iREN[1] == 1'b1 && !bus_wait) begin
            next_iservice = !iservice;
        end
    end

    always_comb begin
        iaddr = '0;
        if ((ccif.iREN[0] == 1'b1) && (ccif.iREN[1] == 1'b0)) begin
            iaddr = ccif.iaddr[0];
        end
        else if ((ccif.iREN[1] == 1'b1) && (ccif.iREN[0] == 1'b0)) begin
            iaddr = ccif.iaddr[1];
        end
        else if (ccif.iREN[0] && ccif.iREN[1]) begin
            iaddr = ccif.iaddr[!iservice];
        end
    end

    always_comb begin
        bus_iREN = '0;
        if (ccif.iREN[0] || ccif.iREN[1]) begin
            bus_iREN = 1'b1;
        end
    end

    always_comb begin
        ccif.iwait[0] = 1'b1;
        ccif.iwait[1] = 1'b1;
        if (ccif.dREN[0] || ccif.dWEN[0] || ccif.dREN[1] || ccif.dWEN[1]) begin
        end
        else if (state == REQUEST) begin
            if (ccif.iREN[0] == 1'b1 && ccif.iREN[1] == 1'b0) begin
                ccif.iwait[0] = bus_wait;
            end
            else if (ccif.iREN[0] == 1'b0 && ccif.iREN[1] == 1'b1) begin
                ccif.iwait[1] = bus_wait;
            end
            else if (ccif.iREN[0] == 1'b1 && ccif.iREN[1] == 1'b1) begin
                ccif.iwait[!iservice] = bus_wait;
            end
        end
    end

    always_comb begin
        bus_dwait = 1'b1;
        if (ccif.dREN[0] || ccif.dWEN[0] || ccif.dREN[1] || ccif.dWEN[1]) begin
            bus_dwait = bus_wait;
        end
    end

    always_comb begin
        next_state = state;
        casez(state)
            REQUEST: begin
                if (ccif.dWEN[0]
                    || ccif.dREN[0]
                    || ccif.dWEN[1]
                    || ccif.dREN[1]) next_state = GRANT;
                else next_state = REQUEST;
            end
            GRANT: begin
                if (cache_REN0 || cache_REN1) next_state = SNOOP;
                else if (cache_WEN0 || cache_WEN1) next_state = SELFWB1;
            end
            SNOOP: begin
                if (ccif.cctrans[!service] == 1'b0) begin
                    next_state = SNOOP;
                end
                else if (ccif.ccwrite[!service] == 1'b1 && ccif.cctrans[!service] == 1'b1) begin
                    next_state = BUSWB1;
                end
                else if (ccif.ccwrite[!service] == 1'b0
                    && ccif.ccwrite[service] == 1'b1
                    && ccif.cctrans[!service] == 1'b1) begin
                        next_state = BUSRDX1;
                    end
                else if (ccif.ccwrite[!service] == 1'b0
                    && ccif.ccwrite[service] == 1'b0
                    && ccif.cctrans[!service] == 1'b1) begin
                        next_state = BUSRD1;
                    end
            end
            BUSRD1: begin
                if (bus_dwait == 1'b0) begin
                    next_state = BUSRD2;
                end
                else begin
                    next_state = BUSRD1;
                end
            end
            BUSRD2: begin
                if (bus_dwait == 1'b0) begin
                    next_state = REPLYREAD;
                end
                else begin
                    next_state = BUSRD2;
                end
            end
            BUSRDX1: begin
                if (bus_dwait == 1'b0) begin
                    next_state = BUSRDX2;
                end
                else begin
                    next_state = BUSRDX1;
                end
            end
            BUSRDX2: begin
                if (bus_dwait == 1'b0) begin
                    next_state = REPLYREAD;
                end
                else begin
                    next_state = BUSRDX2;
                end
            end
            BUSWB1: begin
                next_state = BUSWB2;
            end
            BUSWB2: begin
                if (bus_dwait == 1'b0) begin
                    next_state = REPLYWRITE;
                end
                else begin
                    next_state = BUSWB2;
                end
            end
            SELFWB1: begin
                next_state = SELFWB2;
            end
            SELFWB2: begin
                if (bus_dwait == 1'b0) begin
                    next_state = COMPLETESELFWB;
                end
                else begin
                    next_state = SELFWB2;
                end
            end
            COMPLETESELFWB: begin
                if (bus_wait == 1'b0) begin
                    next_state = REQUEST;
                end
                else begin
                    next_state = COMPLETESELFWB;
                end
            end
            REPLYWRITE: begin
                if(bus_dwait == 1'b0) begin
                    next_state = COMPLETEWRITE;
                end
                else begin
                    next_state = REPLYWRITE;
                end
            end
            REPLYREAD: begin
                next_state = COMPLETEREAD;
            end
            COMPLETEREAD: begin
                next_state = REQUEST;
            end
            COMPLETEWRITE: begin
                next_state = REQUEST;
            end
        endcase
    end

    always_comb begin
        next_daddr_reg = daddr_reg;
        next_service = service;
        next_dload = dload;
        bus_ramren = '0;
        bus_ramaddr = '0;
        bus_ramwen = '0;
        bus_ramstore = '0;
        next_cache_WEN0 = cache_WEN0;
        next_cache_REN0 = cache_REN0;
        next_cache_WEN1 = cache_WEN1;
        next_cache_REN1 = cache_REN1;
        next_dstore = dstore;
        next_daddr_reg0 = daddr_reg0;
        next_daddr_reg1 = daddr_reg1;
        ccif.dwait[0] = '1;
        ccif.dwait[1] = '1;
        ccif.ccsnoopaddr[0] = snoopaddr;
        ccif.ccsnoopaddr[1] = snoopaddr;
        ccif.dload[0] = '0;
        ccif.dload[1] = '0;
       next_snoopaddr = snoopaddr;


        casez(state)
            REQUEST: begin
                next_cache_WEN0 = ccif.dWEN[0];
                next_cache_REN0 = ccif.dREN[0];
                next_cache_WEN1 = ccif.dWEN[1];
                next_cache_REN1 = ccif.dREN[1];
                next_daddr_reg0 = {ccif.daddr[0][31:3],3'b000};
                next_daddr_reg1 = {ccif.daddr[1][31:3],3'b000};
            end
            GRANT: begin
                if (cache_REN0 == 1'b1 || cache_WEN0 == 1'b1) begin
                    next_service = 1'b0;
                    next_daddr_reg = daddr_reg0;
                    next_snoopaddr = daddr_reg0;
                end
                else if (cache_REN1 == 1'b1 || cache_WEN1 == 1'b1) begin
                    next_service = 1'b1;
                    next_daddr_reg = daddr_reg1;
                    next_snoopaddr = daddr_reg1;
                end
            end
            SNOOP: begin
            end
            BUSRD1: begin
                bus_ramren = 1'b1;
                bus_ramaddr = daddr_reg;
                next_dload = ccif.ramload;
            end
            BUSRD2: begin
                bus_ramren = 1'b1;
                bus_ramaddr = {daddr_reg[31:3],3'b100};
                if (bus_dwait == 1'b0) begin
                    next_dload = ccif.ramload;
                end
                ccif.dload[service] = dload;
                ccif.dwait[service] = bus_dwait;
            end
            BUSRDX1: begin
                bus_ramren = 1'b1;
                bus_ramaddr = daddr_reg;
                next_dload = ccif.ramload;
            end
            BUSRDX2: begin
                bus_ramren = 1'b1;
                bus_ramaddr = {daddr_reg[31:3], 3'b100};
                if (bus_dwait == 1'b0) begin
                    next_dload = ccif.ramload;
                end
                ccif.dload[service] = dload;
                ccif.dwait[service] = bus_dwait;
            end
            REPLYREAD: begin
                bus_ramren = 1'b0;
                ccif.dload[service] = dload;
                ccif.dwait[service] = 1'b0;
            end
            BUSWB1: begin
                next_dstore = ccif.dstore[!service];
                ccif.dwait[!service] = 1'b0;
            end
            BUSWB2: begin
                bus_ramwen = 1'b1;
                bus_ramaddr = daddr_reg;
                if (bus_dwait == 1'b0) begin
                    next_dstore = ccif.dstore[!service];
                end
                bus_ramstore = dstore;
                ccif.dwait[!service] = bus_dwait;
            end
            REPLYWRITE: begin
                bus_ramwen = 1'b1;
                bus_ramaddr = {daddr_reg[31:3],3'b100};
                bus_ramstore = dstore;
            end
            SELFWB1: begin
                next_dstore = ccif.dstore[service];
                ccif.dwait[service] = 1'b0;
            end
            SELFWB2: begin
                bus_ramwen = 1'b1;
                bus_ramaddr = daddr_reg;
                bus_ramstore = dstore;
                if (bus_dwait == 1'b0) begin
                    next_dstore = ccif.dstore[service];
                    next_daddr_reg = {daddr_reg[31:3],3'b100};
                end
            end
            COMPLETESELFWB: begin
                bus_ramwen = 1'b1;
                bus_ramaddr = daddr_reg;
                bus_ramstore = dstore;
                ccif.dwait[service] = bus_dwait;
            end
        endcase
    end

    always_comb begin
        ccif.ccwait[0] = 1'b0;
        ccif.ccwait[1] = 1'b0;
        if ((state == SNOOP)
            || (state == BUSWB1)
            || (state == BUSWB2)
        )begin
            ccif.ccwait[!service] = 1'b1;
        end
    end

    always_comb begin
        ccif.ccinv[0] = 1'b0;
        ccif.ccinv[1] = 1'b0;
        if (state == SNOOP && ccif.ccwrite[!service] == 1'b0
            && ccif.ccwrite[service] == 1'b1
            && ccif.cctrans[!service] == 1'b1) begin
                ccif.ccinv[!service] = 1'b1;
            end
    end
endmodule
