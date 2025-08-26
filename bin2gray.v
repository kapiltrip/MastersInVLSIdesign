//------------------------------------------------------------------------------
// Module: bin2gray
// Feature: converts binary code to Gray code using pure combinational logic
// Variables:
//   bin  - binary input vector
//   gray - output Gray-coded vector
// Future Improvements:
//   * add inverse gray2bin module for completeness
//   * parameterize for optional pipelining
//------------------------------------------------------------------------------
module bin2gray #(parameter WIDTH = 8) (
  input  [WIDTH-1:0] bin,
  output [WIDTH-1:0] gray
);
  // refresher: Gray code is binary value XORed with itself shifted right by one
  assign gray = bin ^ (bin >> 1);
endmodule
