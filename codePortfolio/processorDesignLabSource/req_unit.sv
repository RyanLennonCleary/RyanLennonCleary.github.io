`include "request_datapath_if.vh"
`include "cpu_types_pkg.vh"

module req_unit(input logic CLK, input logic nRST, request_datapath_if.ru rif);

    import cpu_types_pkg::*;
    logic dREN, dWEN, next_dREN, next_dWEN;
    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            dREN <= 1'b0;
            dWEN <= 1'b0;
        end
        else begin
            dREN <= next_dREN;
            dWEN <= next_dWEN;
        end
    end

    always_comb begin
                next_dREN = dREN;
                next_dWEN = dWEN;

        if (rif.dhit == 1'b1) begin
            next_dREN = 1'b0;
            next_dWEN = 1'b0;
        end
        else if (rif.ihit == 1'b1) begin
            next_dREN = rif.dmemREN;
            next_dWEN = rif.dmemWEN;
        end
    end
    assign rif.dREN = dREN;
    assign rif.dWEN = dWEN;
    assign rif.iREN = 1'b1;
endmodule
