//------------------------------------------------------------------------------
// Module: up_down_counter_structural
// Feature: 4-bit synchronous up/down counter (structural)
// Reference: Based on Morris Mano's textbook design
//------------------------------------------------------------------------------
module dff (
  input  wire clk,
  input  wire reset,
  input  wire d,
  output reg  q
);
  // Asynchronous active-high reset.
  // On each rising edge of clk, q follows input d.
  always @(posedge clk or posedge reset) begin
    if (reset)
      q <= 1'b0;  // clear output when reset is asserted
    else
      q <= d;     // capture new value on clock edge
  end
endmodule

module full_adder (
  input  wire a,
  input  wire b,
  input  wire cin,
  output wire sum,
  output wire cout
);
  // Single-bit full adder.
  // Adds bits a and b with carry-in cin.
  assign sum  = a ^ b ^ cin;               // sum bit
  assign cout = (a & b) | (b & cin) | (a & cin);  // carry-out
endmodule

module up_down_counter_structural (
  input  wire       clk,
  input  wire       reset,
  input  wire       up,
  output wire [3:0] count
);
  // q stores the current count state.
  wire [3:0] q;
  // b represents the value to add: +1 for up, -1 for down (two's complement).
  wire [3:0] b;
  // sum holds the next-state value after addition.
  wire [3:0] sum;
  // carry signals between the chained full adders.
  wire c0, c1, c2, c3;

  // Select increment or decrement based on control input 'up'.
  assign b = up ? 4'b0001 : 4'b1111; // +1 when up, -1 when down

  // Ripple-carry addition of current count and increment/decrement.
  full_adder fa0 (.a(q[0]), .b(b[0]), .cin(1'b0), .sum(sum[0]), .cout(c0)); // LSB
  full_adder fa1 (.a(q[1]), .b(b[1]), .cin(c0),    .sum(sum[1]), .cout(c1));
  full_adder fa2 (.a(q[2]), .b(b[2]), .cin(c1),    .sum(sum[2]), .cout(c2));
  full_adder fa3 (.a(q[3]), .b(b[3]), .cin(c2),    .sum(sum[3]), .cout(c3)); // MSB

  // Register the computed sum on each clock edge.
  dff dff0 (.clk(clk), .reset(reset), .d(sum[0]), .q(q[0]));
  dff dff1 (.clk(clk), .reset(reset), .d(sum[1]), .q(q[1]));
  dff dff2 (.clk(clk), .reset(reset), .d(sum[2]), .q(q[2]));
  dff dff3 (.clk(clk), .reset(reset), .d(sum[3]), .q(q[3]));

  // Expose the register contents as the counter output.
  assign count = q;
endmodule
