//------------------------------------------------------------------------------
// Module: up_down_counter_behavioral
// Feature: 4-bit synchronous up/down counter (behavioral)
// Reference: Based on Morris Mano's textbook design
//------------------------------------------------------------------------------
module up_down_counter_behavioral (
  input  wire       clk,
  input  wire       reset,
  input  wire       up,
  output reg  [3:0] count
);
  always @(posedge clk or posedge reset) begin
    if (reset)
      count <= 4'b0000;       // reset clears counter to 0
    else if (up)
      count <= count + 1'b1;  // increment when up=1
    else
      count <= count - 1'b1;  // decrement when up=0
  end
endmodule
