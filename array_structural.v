//------------------------------------------------------------------------------
// Module: array_structural
// Feature: 4-word memory built from D flip-flops with decoded write enables
// Variables:
//   clk        - clock for all storage elements
//   write_data - input data bus to be stored
//   write_addr - two-bit address selecting which word to update
//   write_en   - global write enable signal
//   read_addr  - two-bit address choosing which word to output
//   read_data  - multiplexed output of selected word
//   word0..3   - internal storage words
//   word*_we   - individual word write enables derived from write_addr
// Future Improvements:
//   * generalize depth beyond four words using generate loops
//   * add asynchronous reset to DFF cells
//   * implement read enable to hold output when inactive
//------------------------------------------------------------------------------
module dff (
  input clk,
  input enable,
  input d_in,
  output reg q_out
);
  always @(posedge clk)
    if (enable) q_out <= d_in;
endmodule

module array_structural #(parameter WIDTH=8)(
  input clk,
  input [WIDTH-1:0] write_data,
  input [1:0] write_addr,
  input write_en,
  input [1:0] read_addr,
  output [WIDTH-1:0] read_data
);
  wire [WIDTH-1:0] word0, word1, word2, word3;
  // refresher: decode address into one-hot enables so only one word updates
  wire word0_we = write_en & (write_addr == 2'b00);
  wire word1_we = write_en & (write_addr == 2'b01);
  wire word2_we = write_en & (write_addr == 2'b10);
  wire word3_we = write_en & (write_addr == 2'b11);
  genvar bit_idx;
  generate
    // refresher: for each bit position, create four DFFs (one per word)
    for (bit_idx=0; bit_idx<WIDTH; bit_idx=bit_idx+1) begin: mem
      dff d0(.clk(clk), .enable(word0_we), .d_in(write_data[bit_idx]), .q_out(word0[bit_idx]));
      dff d1(.clk(clk), .enable(word1_we), .d_in(write_data[bit_idx]), .q_out(word1[bit_idx]));
      dff d2(.clk(clk), .enable(word2_we), .d_in(write_data[bit_idx]), .q_out(word2[bit_idx]));
      dff d3(.clk(clk), .enable(word3_we), .d_in(write_data[bit_idx]), .q_out(word3[bit_idx]));
    end
  endgenerate
  // refresher: multiplexer selects which word to present on read_data
  assign read_data = (read_addr==2'b00) ? word0 :
                     (read_addr==2'b01) ? word1 :
                     (read_addr==2'b10) ? word2 : word3;
endmodule
