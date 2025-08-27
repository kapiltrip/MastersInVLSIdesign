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
  always @(posedge clk or posedge reset) begin
    if (reset)
      q <= 1'b0;
    else
      q <= d;
  end
endmodule

module full_adder (
  input  wire a,
  input  wire b,
  input  wire cin,
  output wire sum,
  output wire cout
);
  assign sum  = a ^ b ^ cin;
  assign cout = (a & b) | (b & cin) | (a & cin);
endmodule

module up_down_counter_structural (
  input  wire       clk,
  input  wire       reset,
  input  wire       up,
  output wire [3:0] count
);
  wire [3:0] q;
  wire [3:0] b;
  wire [3:0] sum;
  wire c0, c1, c2, c3;
  assign b = up ? 4'b0001 : 4'b1111; // +1 when up, -1 when down

  full_adder fa0 (.a(q[0]), .b(b[0]), .cin(1'b0), .sum(sum[0]), .cout(c0));
  full_adder fa1 (.a(q[1]), .b(b[1]), .cin(c0),    .sum(sum[1]), .cout(c1));
  full_adder fa2 (.a(q[2]), .b(b[2]), .cin(c1),    .sum(sum[2]), .cout(c2));
  full_adder fa3 (.a(q[3]), .b(b[3]), .cin(c2),    .sum(sum[3]), .cout(c3));

  dff dff0 (.clk(clk), .reset(reset), .d(sum[0]), .q(q[0]));
  dff dff1 (.clk(clk), .reset(reset), .d(sum[1]), .q(q[1]));
  dff dff2 (.clk(clk), .reset(reset), .d(sum[2]), .q(q[2]));
  dff dff3 (.clk(clk), .reset(reset), .d(sum[3]), .q(q[3]));

  assign count = q;
endmodule
