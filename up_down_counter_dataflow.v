//------------------------------------------------------------------------------
// Module: up_down_counter_dataflow
// Feature: 4-bit synchronous up/down counter (dataflow)
// Reference: Based on Morris Mano's textbook design
//------------------------------------------------------------------------------
module up_down_counter_dataflow (
  input  wire       clk,
  input  wire       reset,
  input  wire       up,
  output reg  [3:0] count
);
  wire [3:0] inc = count + 4'b0001;
  wire [3:0] dec = count - 4'b0001;
  wire [3:0] next = up ? inc : dec;
  always @(posedge clk or posedge reset) begin
    if (reset)
      count <= 4'b0000;
    else
      count <= next;
  end
endmodule
