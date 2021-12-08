`include "register_file_if.vh"
`include "cpu_types_pkg.vh"
module register_file(
        input logic CLK,
        input logic nRST,
        register_file_if.rf rfif);
    import cpu_types_pkg::*;
    word_t [31:0] registers;
    word_t [31:0] next_registers;
    always_ff @(negedge CLK, negedge nRST) begin
        if (!nRST) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= '0;
            end
        end
        else begin
            registers <= next_registers;
        end
    end
    always_comb begin
        next_registers = registers;
        if (rfif.WEN == 1'b1 && rfif.wsel != 5'b00000) begin
            next_registers[rfif.wsel] = rfif.wdat;
        end
    end
    assign rfif.rdat1 = registers[rfif.rsel1];
    assign rfif.rdat2 = registers[rfif.rsel2];
endmodule
