//------------------------------------------------------------------------------
// Module: bin2gray
// Description: Combinational converter that maps a binary value to its Gray-code
//              equivalent. Gray coding changes only one bit between successive
//              values, which is useful for pointer synchronization across clock
//              domains or for minimizing switching noise.
//------------------------------------------------------------------------------
module bin2gray #(parameter WIDTH = 8) (
  input  [WIDTH-1:0] bin,
  output [WIDTH-1:0] gray
);
  // refresher: Gray code is binary value XORed with itself shifted right by one
  assign gray = bin ^ (bin >> 1);
endmodule
