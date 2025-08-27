//============================================================
// Testbench: tb_bin2gray
// Description: Self-checking environment for the bin2gray module. The testbench
//              sweeps through every possible input value, compares the DUT
//              output against a reference model, and ensures consecutive Gray
//              codes differ by only one bit.
//============================================================
 `timescale 1ns/1ps
 module tb_bin2gray;
  parameter WIDTH = 8;
  reg  [WIDTH-1:0] bin;
  wire [WIDTH-1:0] gray;
  reg  [WIDTH-1:0] gray_prev;
  reg  [WIDTH-1:0] exp;
  integer          x;
  integer          errors;
  // Device Under Test
  bin2gray #(.WIDTH(WIDTH)) dut (
    .bin (bin),
    .gray(gray)
  );
  // Reference model (pure Verilog-2001 function)
  function [WIDTH-1:0] gray_ref;
    input [WIDTH-1:0] b;
    begin
      gray_ref = b ^ (b >> 1);
    end
  endfunction
  // Popcount utility for Hamming distance check
  function integer popcount;
    input [WIDTH-1:0] v;
    integer i;
    begin
      popcount = 0;
      for (i = 0; i < WIDTH; i = i + 1)
        popcount = popcount + v[i]; // sums bits; X propagates as X
    end
  endfunction
  initial begin
    $display("TB: Exhaustive verification for WIDTH=%0d", WIDTH);
    errors    = 0;
    gray_prev = {WIDTH{1'b0}};
    // Sweep all input codes: 0 .. 2^WIDTH - 1
    for (x = 0; x < (1 << WIDTH); x = x + 1) begin
      bin = x;        // automatic truncation to WIDTH bits
      #1;             // allow combinational settle
      // Self-check against reference model
      exp = gray_ref(bin);
      if (gray !== exp) begin
        $display("ERROR: bin=%0d exp=%b got=%b", x, exp, gray);
        errors = errors + 1;
      end
      // Adjacency property wrt previous code
      if (x > 0) begin
        if (popcount(gray ^ gray_prev) != 1) begin
          $display("ERROR: adjacency violation between %0d and %0d", x-1, x);
          errors = errors + 1;
        end
      end
      gray_prev = gray;
    end
    if (errors == 0)
      $display("PASS: All %0d patterns correct; Gray adjacency holds.", (1<<WIDTH));
    else
      $display("FAIL: %0d total errors detected.", errors);
    $finish;
  end
 endmodule
