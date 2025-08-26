//============================================================
// Module and Testbench: bin2gray and self-checking TB
//   - Pure Verilog-2001 code in a single file for clarity
//   - Converts binary input to Gray code using XOR
//   - Exhaustively verifies conversion and Gray adjacency
//============================================================
`timescale 1ns/1ps

//------------------------------
// Module: bin2gray
//------------------------------
module bin2gray #(parameter WIDTH = 8) (
  input  [WIDTH-1:0] bin,   // binary input
  output [WIDTH-1:0] gray   // Gray-coded output
);
  // Gray code is simply the binary value XOR'd with itself shifted right by one
  assign gray = bin ^ (bin >> 1);
endmodule

//------------------------------
// Testbench: tb_bin2gray
//------------------------------
module tb_bin2gray;
  parameter WIDTH = 8;
  reg  [WIDTH-1:0] bin;          // stimulus vector
  wire [WIDTH-1:0] gray;         // DUT output
  reg  [WIDTH-1:0] prev_gray;    // previous Gray code for adjacency check
  integer idx;                   // loop variable
  integer errors;                // counter for mismatches

  // Device Under Test
  bin2gray #(.WIDTH(WIDTH)) dut (
    .bin  (bin),
    .gray (gray)
  );

  // Reference model: b ^ (b>>1)
  function [WIDTH-1:0] gray_ref;
    input [WIDTH-1:0] b;
    begin
      gray_ref = b ^ (b >> 1);
    end
  endfunction

  // Bit-count helper to measure Hamming distance
  function integer popcount;
    input [WIDTH-1:0] v;
    integer i;
    begin
      popcount = 0;
      for (i = 0; i < WIDTH; i = i + 1)
        popcount = popcount + v[i];
    end
  endfunction

  initial begin
    $display("TB: verifying bin2gray WIDTH=%0d", WIDTH);
    errors    = 0;
    prev_gray = 0;
    // Sweep all codes 0..2^WIDTH-1
    for (idx = 0; idx < (1<<WIDTH); idx = idx + 1) begin
      bin = idx;       // drive input
      #1;              // allow combinational settle
      if (gray !== gray_ref(bin)) begin
        $display("ERROR: bin=%0d exp=%b got=%b", idx, gray_ref(bin), gray);
        errors = errors + 1;
      end
      if (idx > 0 && popcount(gray ^ prev_gray) != 1) begin
        $display("ERROR: adjacency fail between %0d and %0d", idx-1, idx);
        errors = errors + 1;
      end
      prev_gray = gray;
    end
    if (errors == 0)
      $display("PASS: all %0d patterns correct", (1<<WIDTH));
    else
      $display("FAIL: %0d errors", errors);
    $finish;
  end
endmodule

