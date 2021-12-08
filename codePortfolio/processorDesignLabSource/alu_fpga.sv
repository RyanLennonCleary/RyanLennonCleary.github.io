/*
   Eric Villasenor
   evillase@gmail.com

   register file fpga wrapper
 */

// interface

`include "alu_if.vh"
`include "cpu_types_pkg.vh"

module alu_fpga (
    input logic CLOCK_50,
    input logic [3:0] KEY,
    input logic [17:0] SW,
    output logic [5:0] HEX0,
    output logic [5:0] HEX1,
    output logic [5:0] HEX2,
    output logic [5:0] HEX3,
    output logic [5:0] HEX4,
    output logic [5:0] HEX5,
    output logic [5:0] HEX6,
    output logic [5:0] HEX7
    );
word_t regB;
word_t next_regB;
import cpu_types_pkg::*;
always_ff @(posedge CLOCK_50) begin
regB <= next_regB;
end
//always_comb begin
//if (SW[17] == 1) begin
//  next_regB = {16{SW[16]},SW[15:0]};
//end

alu_if aface();
alu ALU(.aface(aface));

assign next_regB = SW[17] ? {{16{SW[16]}},SW[15:0]} : regB;
assign aface.portA = {{16{SW[16]}},SW[15:0]};
assign aface.portB = regB;
assign aface.aluop = aluop_t'({KEY[3],KEY[2],KEY[1],KEY[1],KEY[0]});

//7 segment display is active low
always_comb
  begin
unique casez (aface.outPort[3:0])
  'h0: HEX0 = 7'b1000000;
  'h1: HEX0 = 7'b1111001;
  'h2: HEX0 = 7'b0100100;
  'h3: HEX0 = 7'b0110000;
  'h4: HEX0 = 7'b0011001;
  'h5: HEX0 = 7'b0010010;
  'h6: HEX0 = 7'b0000010;
  'h7: HEX0 = 7'b1111000;
  'h8: HEX0 = 7'b0000000;
  'h9: HEX0 = 7'b0010000;
  'ha: HEX0 = 7'b0001000;
  'hb: HEX0 = 7'b0000011;
  'hc: HEX0 = 7'b0100111;
  'hd: HEX0 = 7'b0100001;
  'he: HEX0 = 7'b0000110;
  'hf: HEX0 = 7'b0001110;
  endcase

unique casez (aface.outPort[7:4])
  'h0: HEX1 = 7'b1000000;
  'h1: HEX1 = 7'b1111001;
  'h2: HEX1 = 7'b0100100;
  'h3: HEX1 = 7'b0110000;
  'h4: HEX1 = 7'b0011001;
  'h5: HEX1 = 7'b0010010;
  'h6: HEX1 = 7'b0000010;
  'h7: HEX1 = 7'b1111000;
  'h8: HEX1 = 7'b0000000;
  'h9: HEX1 = 7'b0010000;
  'ha: HEX1 = 7'b0001000;
  'hb: HEX1 = 7'b0000011;
  'hc: HEX1 = 7'b0100111;
  'hd: HEX1 = 7'b0100001;
  'he: HEX1 = 7'b0000110;
  'hf: HEX1 = 7'b0001110;
  endcase

unique casez (aface.outPort[11:8])
  'h0: HEX2 = 7'b1000000;
  'h1: HEX2 = 7'b1111001;
  'h2: HEX2 = 7'b0100100;
  'h3: HEX2 = 7'b0110000;
  'h4: HEX2 = 7'b0011001;
  'h5: HEX2 = 7'b0010010;
  'h6: HEX2 = 7'b0000010;
  'h7: HEX2 = 7'b1111000;
  'h8: HEX2 = 7'b0000000;
  'h9: HEX2 = 7'b0010000;
  'ha: HEX2 = 7'b0001000;
  'hb: HEX2 = 7'b0000011;
  'hc: HEX2 = 7'b0100111;
  'hd: HEX2 = 7'b0100001;
  'he: HEX2 = 7'b0000110;
  'hf: HEX2 = 7'b0001110;
  endcase
unique casez (aface.outPort[15:12])
  'h0: HEX3 = 7'b1000000;
  'h1: HEX3 = 7'b1111001;
  'h2: HEX3 = 7'b0100100;
  'h3: HEX3 = 7'b0110000;
  'h4: HEX3 = 7'b0011001;
  'h5: HEX3 = 7'b0010010;
  'h6: HEX3 = 7'b0000010;
  'h7: HEX3 = 7'b1111000;
  'h8: HEX3 = 7'b0000000;
  'h9: HEX3 = 7'b0010000;
  'ha: HEX3 = 7'b0001000;
  'hb: HEX3 = 7'b0000011;
  'hc: HEX3 = 7'b0100111;
  'hd: HEX3 = 7'b0100001;
  'he: HEX3 = 7'b0000110;
  'hf: HEX3 = 7'b0001110;
  endcase
unique casez (aface.outPort[19:16])
  'h0: HEX4 = 7'b1000000;
  'h1: HEX4 = 7'b1111001;
  'h2: HEX4 = 7'b0100100;
  'h3: HEX4 = 7'b0110000;
  'h4: HEX4 = 7'b0011001;
  'h5: HEX4 = 7'b0010010;
  'h6: HEX4 = 7'b0000010;
  'h7: HEX4 = 7'b1111000;
  'h8: HEX4 = 7'b0000000;
  'h9: HEX4 = 7'b0010000;
  'ha: HEX4 = 7'b0001000;
  'hb: HEX4 = 7'b0000011;
  'hc: HEX4 = 7'b0100111;
  'hd: HEX4 = 7'b0100001;
  'he: HEX4 = 7'b0000110;
  'hf: HEX4 = 7'b0001110;
  endcase
unique casez (aface.outPort[23:20])
  'h0: HEX5 = 7'b1000000;
  'h1: HEX5 = 7'b1111001;
  'h2: HEX5 = 7'b0100100;
  'h3: HEX5 = 7'b0110000;
  'h4: HEX5 = 7'b0011001;
  'h5: HEX5 = 7'b0010010;
  'h6: HEX5 = 7'b0000010;
  'h7: HEX5 = 7'b1111000;
  'h8: HEX5 = 7'b0000000;
  'h9: HEX5 = 7'b0010000;
  'ha: HEX5 = 7'b0001000;
  'hb: HEX5 = 7'b0000011;
  'hc: HEX5 = 7'b0100111;
  'hd: HEX5 = 7'b0100001;
  'he: HEX5 = 7'b0000110;
  'hf: HEX5 = 7'b0001110;
  endcase
unique casez (aface.outPort[27:24])
  'h0: HEX6 = 7'b1000000;
  'h1: HEX6 = 7'b1111001;
  'h2: HEX6 = 7'b0100100;
  'h3: HEX6 = 7'b0110000;
  'h4: HEX6 = 7'b0011001;
  'h5: HEX6 = 7'b0010010;
  'h6: HEX6 = 7'b0000010;
  'h7: HEX6 = 7'b1111000;
  'h8: HEX6 = 7'b0000000;
  'h9: HEX6 = 7'b0010000;
  'ha: HEX6 = 7'b0001000;
  'hb: HEX6 = 7'b0000011;
  'hc: HEX6 = 7'b0100111;
  'hd: HEX6 = 7'b0100001;
  'he: HEX6 = 7'b0000110;
  'hf: HEX6 = 7'b0001110;
  endcase
unique casez (aface.outPort[31:28])
  'h0: HEX7 = 7'b1000000;
  'h1: HEX7 = 7'b1111001;
  'h2: HEX7 = 7'b0100100;
  'h3: HEX7 = 7'b0110000;
  'h4: HEX7 = 7'b0011001;
  'h5: HEX7 = 7'b0010010;
  'h6: HEX7 = 7'b0000010;
  'h7: HEX7 = 7'b1111000;
  'h8: HEX7 = 7'b0000000;
  'h9: HEX7 = 7'b0010000;
  'ha: HEX7 = 7'b0001000;
  'hb: HEX7 = 7'b0000011;
  'hc: HEX7 = 7'b0100111;
  'hd: HEX7 = 7'b0100001;
  'he: HEX7 = 7'b0000110;
  'hf: HEX7 = 7'b0001110;
  endcase

  end
  endmodule
