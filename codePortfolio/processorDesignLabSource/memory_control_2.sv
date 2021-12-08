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
    enum logic [3:0] {REQUEST,ARBITRATE,SNOOP,BUSmem1,BUSmem2,BUSmemdone,BUSWB1,BUSWB2,BUSWBdone,NORMAL_WB1,NORMAL_WB2} state, next_state;
    logic service_snoop,service, next_service, next_service_snoop;
    word_t daddr_reg0, daddr_reg1, daddr_reg, next_daddr_reg, next_daddr_reg0,next_daddr_reg1, daddr_snoop, next_daddr_snoop;
   word_t dstore_reg0,dstore_reg1,dstore_reg, next_dstore_reg, next_dstore_reg0, next_dstore_reg1,dstore_snoop, next_dstore_snoop;
   logic  dwen_reg0,dwen_reg1,dwen_reg,next_dwen_reg, next_dwen_reg0, next_dwen_reg1, dwen_snoop,next_dwen_snoop;
   //load buffer 2 word
   word_t next_bus_load0,next_bus_load1,bus_load0,bus_load1;
   //store buffer 2 word
   word_t next_bus_store0,next_bus_store1,bus_store0,bus_store1;

   logic  bus_iwait;
    logic bus_dwait;
   logic  bus_ramren;
   logic bus_ramwen;

   //////
    logic cache_WEN0, next_cache_WEN0;
    logic cache_REN0, next_cache_REN0;
    logic cache_WEN1, next_cache_WEN1;
    logic cache_REN1, next_cache_REN1;

    logic dload, next_dload;
    logic dstore, next_dstore;


    word_t bus_ramaddr;
    word_t bus_ramstore;
    logic bus_iREN;
   /////
    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            state <= REQUEST;
	   service <= '0;
           service_snoop <= '0;
	   dwen_snoop <= '0;
	   daddr_snoop <= '0;
	   daddr_reg0 <= '0;
	   daddr_reg1 <= '0;
	   daddr_reg <= '0;
	   dstore_reg0 <= '0;
	   dstore_reg1 <= '0;
	   dstore_reg <= '0;
	   dwen_reg0 <= '0;
	   dwen_reg1 <= '0;
	   dwen_reg <= '0;
	   bus_load0 <= '0;
	   bus_load1 <= '0;
	   bus_store0 <= '0;
	   bus_store1 <= '0;

        end
        else begin
           state <= next_state;
	   service <= next_service;
           service_snoop <= next_service_snoop;
	   dwen_snoop <= next_dwen_snoop;
	   daddr_snoop <= next_daddr_snoop;
	   daddr_reg0 <= next_daddr_reg0;
	   daddr_reg1 <= next_daddr_reg1;
	   dstore_reg0 <= next_dstore_reg0;
	   dstore_reg1 <= next_dstore_reg1;
	   dwen_reg0 <= next_dwen_reg0;
	   dwen_reg1 <= next_dwen_reg1;
	   daddr_reg <= next_daddr_reg;
	   dwen_reg <= next_dwen_reg;
	   dstore_reg <= next_dstore_reg;
	   bus_load0 <= next_bus_load0;
	   bus_load1 <= next_bus_load1;
	   bus_store0 <= next_bus_store0;
	   bus_store1 <= next_bus_store1;
        end
    end
//ram arbiter
    always_comb begin
        //outputs to cache
        bus_dwait = 1'b1;
       ccif.iwait[0] = '1;
       ccif.iwait[1] = '1;
        ccif.ramaddr = iaddr;
        ccif.ramREN = '0;

       if(bus_ramren || bus_ramwen) begin
	  ccif.ramREN = bus_ramren;
	  ccif.ramaddr = bus_ramaddr;
	  if(ccif.ramstate == ACCESS) begin
             bus_dwait = 1'b0;
          end
       end
       else if(ccif.iREN[0])begin
	  ccif.ramREN = ccif.iREN[0];
	  ccif.ramaddr = ccif.iaddr[0];
	  if (ccif.ramstate == ACCESS) begin
             ccif.iwait[0] = 1'b0;
          end
       end
       else if(ccif.iREN[1])begin
	  ccif.ramREN = ccif.iREN[1];
	  ccif.ramaddr = ccif.iaddr[1];
	  if (ccif.ramstate == ACCESS) begin
             ccif.iwait[1] = 1'b0;
          end
       end
    end
   assign ccif.ramWEN = bus_ramwen;
    assign ccif.ramstore = bus_ramstore;
    assign ccif.iload[0] = (ccif.iwait[0]) ? '0: ccif.ramload;
    assign ccif.iload[1] = (ccif.iwait[1]) ? '0:ccif.ramload;
   always_comb begin
      ccif.dwait[0] = '1;
      ccif.dwait[1] = '1;
      if(state == NORMAL_WB1 || state == NORMAL_WB2) ccif.dwait[service_snoop] = bus_dwait;
      else ccif.dwait[!service_snoop] = bus_dwait;
   end
   

   //controller state machine
    always_comb begin
        next_state = state;
        casez(state)
          REQUEST: begin
             if (ccif.dWEN[0] || ccif.dWEN[1]) next_state = NORMAL_WB1;
	     else if(ccif.dREN[0] || ccif.dREN[1]) next_state = ARBITRATE;
             else next_state = REQUEST;
          end
          ARBITRATE: next_state = SNOOP;
          SNOOP: begin
	     //if not responder not hit and write, from M to I or S -> write back
             if(ccif.ccwrite[!service] && ccif.cctrans[!service]) next_state = BUSWB1;
	     //else if responder hit without permission to read  or not hit and not write
	     else if ((!ccif.cctrans[!service])||((!ccif.ccwrite[!service]) && (ccif.cctrans[!service]))) next_state = BUSmem1;
            end
            BUSmem1: begin
                if (ccif.ramstate == ACCESS) begin
                    next_state = BUSmem2;
                end
                else next_state = BUSmem1;
            end
            BUSmem2: begin
                if (ccif.ramstate == ACCESS) begin
                    next_state = BUSmemdone;
                end
                else next_state = BUSmem2;
            end
            BUSmemdone: next_state = REQUEST;
            BUSWB1: next_state = BUSWB2;
            BUSWB2: begin
                if (ccif.ramstate == ACCESS) begin
                    next_state = BUSWBdone;
                end
                else next_state = BUSmem2;
            end
            BUSWBdone: begin
                if (ccif.ramstate == ACCESS) begin
                    next_state = REQUEST;
                end
                else next_state = BUSWBdone;
            end
            NORMAL_WB1: begin
                if (ccif.ramstate == ACCESS) begin
                    next_state = NORMAL_WB2;
                end
                else next_state = NORMAL_WB1;
            end
            NORMAL_WB2: begin
                if (ccif.ramstate == ACCESS) begin
                    next_state = REQUEST;
                end
                else next_state = NORMAL_WB2;
            end
        endcase
    end
   //output logic
    always_comb begin
       next_daddr_reg = daddr_reg;
       next_service = service;
       next_daddr_reg0 = daddr_reg0;
       next_daddr_reg1 = daddr_reg1;
       next_dstore_reg0 = dstore_reg0;
       next_dstore_reg1 = dstore_reg1;
       next_dwen_reg0 = dwen_reg0;
       next_dwen_reg1 = dwen_reg1;
       next_dwen_snoop = dwen_snoop;
       next_daddr_snoop = daddr_snoop;
       next_service_snoop = service_snoop;
       //ccif.ccsnoopaddr[0] = '0;
       //ccif.ccsnoopaddr[1] = '0;
       bus_ramren = 1'b0;
       bus_ramwen = '0;
       bus_ramaddr = '0;
       next_bus_store0 = bus_store0;
       next_bus_store1 = bus_store1;
       next_bus_load0 = bus_load0;
       next_bus_load1 = bus_load1;
       ccif.dload[0] = '0;
       ccif.dload[1] = '0;


        casez(state)
            REQUEST: begin
               next_daddr_reg0 = ccif.daddr[0];
	       next_daddr_reg1 = ccif.daddr[1];
	       next_dstore_reg0 = ccif.dstore[0];
	       next_dstore_reg1 = ccif.dstore[1];
	       next_dwen_reg0 = ccif.dWEN[0];
	       next_dwen_reg1 = ccif.dWEN[1];
            end
            ARBITRATE: begin
                if (ccif.dREN[0] == 1'b1) begin
                    next_service = 1'b0;
                    next_daddr_reg = next_daddr_reg0;
                end
                else if (ccif.dREN[1] == 1'b1) begin
                    next_service = 1'b1;
                    next_daddr_reg = next_daddr_reg1;
                end
            end
            SNOOP: begin
	       next_daddr_snoop = daddr_reg;
	       next_dwen_snoop = dwen_reg;
	       next_service_snoop = service;
               
            end
            BUSmem1: begin
               bus_ramren = 1'b1;
	       bus_ramwen = '0;
               bus_ramaddr = daddr_snoop;
               next_bus_load0 = ccif.ramload;//save the value in the the load0 buffer
            end
            BUSmem2: begin
               bus_ramren = 1'b1;
	       bus_ramwen = '0;
               bus_ramaddr = daddr_snoop+32'd4;
               next_bus_load1 = ccif.ramload;//save the value in the the load1 buffer
	       ccif.dload[service_snoop] = bus_load0;
            end
            BUSmemdone: begin
               bus_ramren = 1'b0;
               bus_ramwen = '0;
               //bus_ramaddr = daddr_snoop;
	       ccif.dload[service_snoop] = bus_load1;
            end
            BUSWB1: begin
	       bus_ramwen = '0;
	       bus_ramren = '0;
	       //bus_ramaddr = daddr_snoop;
	       next_bus_store0 = ccif.dstore[!service];
            end
            BUSWB2: begin
                bus_ramwen = '1;
	       bus_ramren = '0;
	       bus_ramaddr = daddr_snoop;
	       next_bus_store1 = ccif.dstore[!service];
	       bus_ramstore = bus_store0;
	       ccif.dload[service]=bus_store0;
            end
            BUSWBdone: begin
               bus_ramwen = '1;
	       bus_ramren = '0;
	       bus_ramaddr = daddr_snoop + 32'd4;
	       bus_ramstore = bus_store1;
	       ccif.dload[service] = bus_store1;
            end

            NORMAL_WB1: begin
               bus_ramwen = '1;
	       bus_ramren = '0;
	       if(ccif.dWEN[0]) begin
		  bus_ramaddr = daddr_reg0;
		  bus_ramstore = ccif.dstore[0];//dstore_reg0;
	       end
	       else begin
		  bus_ramaddr = daddr_reg1;
		  bus_ramstore =ccif.dstore[1]; //dstore_reg1;
	       end
            end
            NORMAL_WB2: begin
               bus_ramwen = '1;
	       bus_ramren = '0;
	       if(ccif.dWEN[0]) begin
		  bus_ramaddr = {daddr_reg0[31:3], 3'b100};
		  bus_ramstore = dstore_reg0;
	       end
	       else begin
		  bus_ramaddr = {daddr_reg1[31:3], 3'b100};
		  bus_ramstore = dstore_reg1;
	       end
            end
        endcase
    end
   
   always_comb begin
      ccif.ccsnoopaddr[0] = '0;
      ccif.ccsnoopaddr[1] = '0;
      ccif.ccsnoopaddr[!service_snoop] = daddr_reg[service_snoop];
   end
   
    always_comb begin//ccwait
        ccif.ccwait[0] = 1'b0;
        ccif.ccwait[1] = 1'b0;
        if ((state == REQUEST)
            || (state == ARBITRATE)
            || (state == NORMAL_WB1)
            || (state == NORMAL_WB2))begin
           ccif.ccwait[!service] = 1'b0;end
	else ccif.ccwait[!service] = 1'b1;     
    end

    //ccinv
   always_comb begin
      ccif.ccinv[0] = '0;
      ccif.ccinv[1] = '0;
      if(ccif.ccwrite[service]) ccif.ccinv[!service] = '1;
   end
   //ccsnoopaddr
   
   

endmodule
