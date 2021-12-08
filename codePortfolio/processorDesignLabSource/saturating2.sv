`include "cpu_types_pkg.vh"
import cpu_types_pkg::*;
module saturating2(
    input logic 	CLK,
    input logic 	nRST,
    input logic 	exmembne_o,
    input logic 	exmembeq_o,
    input logic 	changepc_branch,
    input word_t 	pcmem,
    input word_t 	pc,
    input logic ihit,

    output logic takebranch);
    typedef logic [1:0] state_t;
    state_t [127:0] state,nxt_state;
    typedef logic [1:0] history_t;
    history_t [31:0] history, next_history;

    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            state <= '0;
            history <= '0;
        end
        else begin
            state <= nxt_state;
            history <= next_history;
        end
    end
    always_comb begin
        nxt_state = state;
        next_history = history;
        if (ihit && (exmembne_o || exmembeq_o)) begin
            next_history[pcmem[5:2]] = {history[pcmem[5:2]][0],changepc_branch};
            casez(state[{pcmem[5:2],history[pcmem[5:2]]}]) 
                2'b00: begin
                    if(changepc_branch) nxt_state[{pcmem[5:2],history[pcmem[5:2]]}] = 2'b01;
                    else nxt_state[{pcmem[5:2],history[pcmem[5:2]]}] = 2'b00;
                end
                2'b01: begin
                    if(changepc_branch) nxt_state[{pcmem[5:2],history[pcmem[5:2]]}] = 2'b10;
                    else nxt_state[{pcmem[5:2],history[pcmem[5:2]]}] = 2'b00;
                end
                2'b10: begin
                    if(changepc_branch) nxt_state[{pcmem[5:2],history[pcmem[5:2]]}] = 2'b11;
                    else nxt_state[{pcmem[5:2],history[pcmem[5:2]]}] = 2'b01;
                end
                2'b11: begin
                    if(changepc_branch) nxt_state[{pcmem[5:2],history[pcmem[5:2]]}] = 2'b11;
                    else nxt_state[{pcmem[5:2],history[pcmem[5:2]]}] = 2'b10;
                end
            endcase 
        end 
    end 
    always_comb begin
        takebranch = 1'b0;
        casez(state[{pc[5:2],history[pc[5:2]]}])
            2'b00: takebranch = 1'b0;
            2'b01: takebranch = 1'b0;
            2'b10: takebranch = 1'b1;
            2'b11: takebranch = 1'b1;
        endcase 
    end 
endmodule
