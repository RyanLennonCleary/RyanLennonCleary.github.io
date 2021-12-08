`include "caches_if.vh"
`include "cpu_types_pkg.vh"
`include "datapath_cache_if.vh"
module icache(
    input logic CLK,
    input logic nRST,
    datapath_cache_if.icache dcif,
    caches_if.icache ciif);
    import cpu_types_pkg::*;
    enum logic {CHECK, RETRIEVE} state,next_state; 
    icache_frame [15:0] icache, next_icache;
    icachef_t addr;
    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            icache <= '0;
            state <= CHECK;
        end
        else begin
            icache <= next_icache;
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;
        next_icache = icache;
        dcif.ihit = 1'b0;
        ciif.iREN = 1'b0;
        casez(state)
            CHECK: begin
                if (icache[addr.idx].tag == addr.tag 
                    && icache[addr.idx].valid) begin
                        if(dcif.imemREN) dcif.ihit = 1'b1;
                        next_state = CHECK;
                    end
                else begin
                    next_state = RETRIEVE;
                end
            end
            RETRIEVE: begin
                next_icache[addr.idx].data = ciif.iload;
                next_icache[addr.idx].tag = addr.tag;
                next_icache[addr.idx].valid = 1'b1;
                ciif.iREN = 1'b1;
                if (ciif.iwait == '0) begin
                    next_state = CHECK;
                end
                else begin
                    next_state = RETRIEVE;
                end
            end
        endcase
    end
    assign ciif.iaddr = dcif.imemaddr;
    assign dcif.imemload = icache[addr.idx].data;
    assign addr = icachef_t'({16'h0000,dcif.imemaddr[15:0]});
endmodule


