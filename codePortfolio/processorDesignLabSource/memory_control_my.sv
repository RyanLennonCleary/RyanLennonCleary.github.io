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
		       cache_control_if. cc ccif);
   // type import
   import cpu_types_pkg::*;
   // number of cpus for cc
   parameter CPUS = 2;
   
   enum 			   logic [4:0] {REQUEST, GRANT, SNOOP, BUSRD1, BUSRD2, BUSWB1, BUSWB2, SELFWB1, SELFWB2, REPLYREAD, REPLYWRITE, COMPLETEREAD, COMPLETEWRITE, BUSRDX1, BUSRDX2, COMPLETESELFWB} state, next_state;
   enum 			   logic [2:0] {d0,d1,i0,i1,nobody} winner;
   logic 			   bus_wait;
   logic 			   next_dservice,dservice;
   logic 			   next_iservice,iservice;
   
   logic 			   dwen0_lock, next_dwen0_lock;
   logic 			   dwen1_lock, next_dwen1_lock;
   logic 			   dren0_lock, next_dren0_lock;
   logic 			   dren1_lock, next_dren1_lock;
   
   word_t 			   daddr0_lock, next_daddr0_lock;
   word_t 			   daddr1_lock, next_daddr1_lock;
   word_t 			   dstore0_lock, next_dstore0_lock;
   word_t 			   dstore1_lock, next_dstore1_lock;
   
   word_t 			   ramload_buff0, next_ramload_buff0;
   word_t 			   ramload_buff1, next_ramload_buff1;
   
   assign bus_wait =  !(ccif.ramstate == ACCESS);
   
   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 state <= REQUEST;
	 
	 ramload_buff0 <= '0;
	 ramload_buff1 <= '0;
	 
	 dservice <= '0;
	 iservice <= '0;
      end
      else begin
	 state <= next_state;
	 dservice <= next_dservice;
	 iservice <= next_iservice;
      end
   end
   
   assign ccif.iload[0] = ccif.ramload;
   assign ccif.iload[1] = ccif.ramload;
   assign ccif.dload[0] = ccif.ramload;
   assign ccif.dload[1] = ccif.ramload;
   
   //STATE TRANSITION
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
	   if (dren0_lock || dren1_lock) next_state = SNOOP;
	   else if (dwen0_lock || dwen1_lock) next_state = SELFWB1;
	end
	SNOOP: begin
	   if (ccif.cctrans[!dservice] == 1'b0) begin
	      next_state = SNOOP;
	   end
	   else if (ccif.ccwrite[!dservice] == 1'b1 && ccif.cctrans[!dservice] == 1'b1) begin
	      next_state = BUSWB1;
	   end
	   else if (ccif.ccwrite[!dservice] == 1'b0
		    && ccif.ccwrite[dservice] == 1'b1
		    && ccif.cctrans[!dservice] == 1'b1) begin
	      next_state = BUSRDX1;
	   end
	   else if (ccif.ccwrite[!dservice] == 1'b0
		    && ccif.ccwrite[dservice] == 1'b0
		    && ccif.cctrans[!dservice] == 1'b1) begin
	      next_state = BUSRD1;
	   end
	end
	BUSRD1: begin
	   if (bus_wait == 1'b0) begin
	      next_state = BUSRD2;
	   end
	   else begin
	      next_state = BUSRD1;
	   end
	end
	BUSRD2: begin
	   if (bus_wait == 1'b0) begin
	      next_state = REQUEST;//REPLYREAD;
	   end
	   else begin
	      next_state = BUSRD2;
	   end
	end
	BUSRDX1: begin
	   if (bus_wait == 1'b0) begin
	      next_state = BUSRDX2;
	   end
	   else begin
	      next_state = BUSRDX1;
	   end
	end
	BUSRDX2: begin
	   if (bus_wait == 1'b0) begin
	      next_state = REQUEST;//REPLYREAD;
	   end
	   else begin
	      next_state = BUSRDX2;
	   end
	end
	BUSWB1: begin
	   if (bus_wait == 1'b0) begin
	      next_state = BUSWB2;//REPLYWRITE;
	   end
	   else begin
	      next_state = BUSWB1;
	   end
	end
	BUSWB2: begin
	   if (bus_wait == 1'b0) begin
	      next_state = REQUEST;//REPLYWRITE;
	   end
	   else begin
	      next_state = BUSWB2;
	   end
	end
	SELFWB1: begin
	   if (bus_wait == 1'b0) begin
	      next_state = SELFWB2;//COMPLETESELFWB;
	   end
	   else begin
	      next_state = SELFWB1;
	   end
	end
	SELFWB2: begin
	   if (bus_wait == 1'b0) begin
	      next_state = REQUEST;//COMPLETESELFWB;
	   end
	   else begin
	      next_state = SELFWB2;
	   end
	end
	
      endcase
   end // always_comb
   
   
   //locks for d requests
   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 dwen0_lock <= '0;
	 dren0_lock <= '0;
	 dwen1_lock <= '0;
	 dwen1_lock <= '0;
      end
      else begin
	 //next_values are only allowed to change in grant state
	 dwen0_lock <= next_dwen0_lock;
	 dren0_lock <= next_dren0_lock;
	 dwen1_lock <= next_dwen1_lock;
	 dren1_lock <= next_dren1_lock;
      end
   end
   
   //locks for d addrs
   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 daddr0_lock <= '0;
	 daddr1_lock <= '0;
	 dstore0_lock <= '0;
	 dstore1_lock <= '0;
      end
      else begin
	 //next_values are only allowed to change in grant state
	 daddr0_lock <= next_daddr0_lock;
	 daddr1_lock <= next_daddr1_lock;
	 dstore0_lock <= next_dstore0_lock;
	 dstore1_lock <= next_dstore1_lock;
      end
   end

   assign ccif.ccsnoopaddr[0] = daddr1_lock;
   assign ccif.ccsnoopaddr[1] = daddr0_lock;

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
      //keep the locks frozen
      next_dwen0_lock = dwen0_lock;
      next_dren0_lock = dren0_lock;
      next_dwen1_lock = dwen1_lock;
      next_dren1_lock = dren1_lock;
      next_daddr0_lock = daddr0_lock;
      next_daddr1_lock = daddr0_lock;
      next_dstore0_lock = dstore0_lock;
      next_dstore1_lock = dstore1_lock;
      
      next_ramload_buff0 = ramload_buff0;
      next_ramload_buff1 = ramload_buff1;
      
      //default: nobody gets the bus
      //output to ram: ram gets i request
      ccif.ramaddr = ccif.iaddr[iservice];
      ccif.ramREN = ccif.iREN[iservice];
      ccif.ramWEN = '0;
      ccif.ramstore = '0;
      //other dummy output
      //wait signals: everybody waits
      ccif.iwait[0] = bus_wait;
      ccif.iwait[1] = bus_wait;
      ccif.dwait[0] = '1;
      ccif.dwait[1] = '1;
      
      casez(state)
	REQUEST: begin
	   //lock the locks for the current bus transaction
	   next_dwen0_lock = ccif.dWEN[0];
	   next_dren0_lock = ccif.dREN[0];
	   next_dwen1_lock = ccif.dWEN[1];
	   next_dren1_lock = ccif.dREN[1];
	   next_daddr0_lock = ccif.daddr[0];
	   next_daddr1_lock = ccif.daddr[1];
	   next_dstore0_lock = ccif.dstore[0];
	   next_dstore1_lock = ccif.dstore[1];
	   
	   next_ramload_buff0 = ramload_buff0;
	   next_ramload_buff1 = ramload_buff1;
	   
	   //lock the selection of d request
	   next_dservice = dservice;
	   
	end
	GRANT: begin
	   if (dwen0_lock == 1'b1 || dren0_lock == 1'b1) begin
	      next_dservice = 1'b0;
	   end
	   else if (dwen1_lock == 1'b1 || dren1_lock == 1'b1) begin
	      next_dservice = 1'b1;
	   end
	end
	SNOOP: begin
	   //exchange addr on snoopaddr
	end
	BUSRD1, BUSRDX1: begin
	   //lock the local ramload buffer
	   next_ramload_buff0 = ccif.ramload;
	   
	   if(dservice ==1'b0) begin
	      ccif.ramaddr = {daddr0_lock[31:3],3'b000};
	      ccif.ramREN = dren0_lock;
	      ccif.ramWEN = dwen0_lock;
	      ccif.ramstore = dstore0_lock;
	      ccif.dwait[0] = bus_wait;
	   end
	   else begin
	      ccif.ramaddr = {daddr1_lock[31:3],3'b000};
	      ccif.ramREN = dren1_lock;
	      ccif.ramWEN = dwen1_lock;
	      ccif.ramstore = dstore1_lock;
	      ccif.dwait[1] = bus_wait;
	   end
	end
	BUSRD2, BUSRDX2: begin
	   //lock the local ramload buffer
	   next_ramload_buff1 = ccif.ramload;
	   
	   if(dservice ==1'b0) begin
	      ccif.ramaddr = {daddr0_lock[31:3],3'b100};
	      ccif.ramREN = dren0_lock;
	      ccif.ramWEN = dwen0_lock;
	      ccif.ramstore = dstore0_lock;
	      ccif.dwait[0] = bus_wait;
	   end
	   else begin
	      ccif.ramaddr = {daddr1_lock[31:3],3'b100};
	      ccif.ramREN = dren1_lock;
	      ccif.ramWEN = dwen1_lock;
	      ccif.ramstore = dstore1_lock;
	      ccif.dwait[1] = bus_wait;
	   end
	end // case: BUSRD2, BUSRDX2
	
	SELFWB1: begin
	   if(dservice ==1'b0) begin
	      ccif.ramaddr = {daddr0_lock[31:3],3'b000};
	      ccif.ramREN = dren0_lock;
	      ccif.ramWEN = dwen0_lock;
	      ccif.ramstore = dstore0_lock;
	      ccif.dwait[0] = bus_wait;
	   end
	   else begin
	      ccif.ramaddr = {daddr1_lock[31:3],3'b000};
	      ccif.ramREN = dren1_lock;
	      ccif.ramWEN = dwen1_lock;
	      ccif.ramstore = dstore1_lock;
	      ccif.dwait[1] = bus_wait;
	   end
	end
	SELFWB2: begin
	   if(dservice ==1'b0) begin
	      ccif.ramaddr = {daddr0_lock[31:3],3'b100};
	      ccif.ramREN = dren0_lock;
	      ccif.ramWEN = dwen0_lock;
	      ccif.ramstore = dstore0_lock;
	      ccif.dwait[0] = bus_wait;
	   end
	   else begin
	      ccif.ramaddr = {daddr1_lock[31:3],3'b100};
	      ccif.ramREN = dren1_lock;
	      ccif.ramWEN = dwen1_lock;
	      ccif.ramstore = dstore1_lock;
	      ccif.dwait[1] = bus_wait;
	   end
	end
	
	BUSWB1: begin
	   if(dservice ==1'b1) begin //Servicing dcache1, write back cache0
	      ccif.ramaddr = {daddr1_lock[31:3],3'b000};
	      ccif.ramREN = 1'b0;
	      ccif.ramWEN = 1'b1;
	      ccif.ramstore = ccif.dstore[0];
	      ccif.dwait[1] = bus_wait;
	   end
	   else begin
	      ccif.ramaddr = {daddr0_lock[31:3],3'b000};
	      ccif.ramREN = 1'b0;
	      ccif.ramWEN = 1'b1;
	      ccif.ramstore = ccif.dstore[1];
	      ccif.dwait[0] = bus_wait;
	   end
	end
	BUSWB2: begin
	   if(dservice ==1'b1) begin //Servicing dcache1, write back cache0
	      ccif.ramaddr = {daddr1_lock[31:3],3'b100};
	      ccif.ramREN = 1'b0;
	      ccif.ramWEN = 1'b1;
	      ccif.ramstore = ccif.dstore[0];
	      ccif.dwait[1] = bus_wait;
	   end
	   else begin
	      ccif.ramaddr = {daddr0_lock[31:3],3'b100};
	      ccif.ramREN = 1'b0;
	      ccif.ramWEN = 1'b1;
	      ccif.ramstore = ccif.dstore[1];
	      ccif.dwait[0] = bus_wait;
	   end
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
	 ccif.ccwait[!dservice] = 1'b1;
      end
   end
   
   always_comb begin
      ccif.ccinv[0] = 1'b0;
      ccif.ccinv[1] = 1'b0;
      if (state == SNOOP && ccif.ccwrite[!dservice] == 1'b0
	  && ccif.ccwrite[dservice] == 1'b1
	  && ccif.cctrans[!dservice] == 1'b1) begin
	 ccif.ccinv[!dservice] = 1'b1;
      end
   end
endmodule
