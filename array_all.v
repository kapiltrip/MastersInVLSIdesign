//------------------------------------------------------------------------------
// File: array_all.v
// Description: Collection of simple memory implementations showcasing behavioral,
//              dataflow, and structural coding styles. The modules highlight how
//              identical memory behavior can be written in different ways: the
//              behavioral model registers both ports, the dataflow version
//              exposes a combinational read, and the structural implementation
//              builds the storage out of flip-flops to reveal the underlying
//              hardware.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Module: array_behavioral
// Feature: parameterized memory with synchronous write and registered read
// This behavioral description uses a reg array to represent memory and a
// single clocked process to model write and read operations, mirroring the
// style of synchronous RAM available in many devices.
//------------------------------------------------------------------------------
module array_behavioral #(parameter WIDTH=8, DEPTH=16, ADDR=4) (
  input                 clk,
  input  [WIDTH-1:0]    write_data,
  input  [ADDR-1:0]     write_addr,
  input                 write_en,
  input  [ADDR-1:0]     read_addr,
  output reg [WIDTH-1:0] read_data
);
  reg [WIDTH-1:0] mem_array [0:DEPTH-1];
  integer idx;
  initial begin
    for (idx = 0; idx < DEPTH; idx = idx + 1)
      mem_array[idx] = {WIDTH{1'b0}};
    read_data = {WIDTH{1'b0}};
  end
  always @(posedge clk) begin
    if (write_en)
      mem_array[write_addr] <= write_data; // store new data into selected word
    read_data <= mem_array[read_addr];
  end
endmodule

//------------------------------------------------------------------------------
// Module: array_dataflow
// Feature: memory with synchronous write and combinational read access
// Here the memory still uses a reg array, but the read port is modeled as a
// simple continuous assignment, producing the selected word immediately
// without waiting for a clock edge.
//------------------------------------------------------------------------------
module array_dataflow #(parameter WIDTH=8, DEPTH=16, ADDR=4) (
  input              clk,
  input [WIDTH-1:0]  write_data,
  input [ADDR-1:0]   write_addr,
  input              write_en,
  input [ADDR-1:0]   read_addr,
  output [WIDTH-1:0] read_data
);
  reg [WIDTH-1:0] mem_array [0:DEPTH-1];
  integer idx;
  initial begin
    for (idx = 0; idx < DEPTH; idx = idx + 1)
      mem_array[idx] = {WIDTH{1'b0}};
  end
  always @(posedge clk) begin
    if (write_en)
      mem_array[write_addr] <= write_data; // store data on rising edge
  end
  assign read_data = mem_array[read_addr];
endmodule

//------------------------------------------------------------------------------
// Module: dff
// Feature: simple enabled D flip-flop used by structural memory
// The flip-flop captures the input on a rising clock edge when enable is high,
// providing the basic storage element for the structural memory example.
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

//------------------------------------------------------------------------------
// Module: array_structural
// Feature: 4-word memory built from D flip-flops with decoded write enables
// The structural implementation instantiates one flip-flop per stored bit and
// decodes the write address into individual enables, providing a clear view of
// the hardware resources consumed by a small memory.
//------------------------------------------------------------------------------
module array_structural #(parameter WIDTH=8) (
  input clk,
  input [WIDTH-1:0] write_data,
  input [1:0] write_addr,
  input write_en,
  input [1:0] read_addr,
  output [WIDTH-1:0] read_data
);
  wire [WIDTH-1:0] word0, word1, word2, word3;
  wire word0_we = write_en & (write_addr == 2'b00);
  wire word1_we = write_en & (write_addr == 2'b01);
  wire word2_we = write_en & (write_addr == 2'b10);
  wire word3_we = write_en & (write_addr == 2'b11);

  genvar bit_idx;
  generate
    for (bit_idx=0; bit_idx<WIDTH; bit_idx=bit_idx+1) begin: mem
      dff d0(.clk(clk), .enable(word0_we), .d_in(write_data[bit_idx]), .q_out(word0[bit_idx]));
      dff d1(.clk(clk), .enable(word1_we), .d_in(write_data[bit_idx]), .q_out(word1[bit_idx]));
      dff d2(.clk(clk), .enable(word2_we), .d_in(write_data[bit_idx]), .q_out(word2[bit_idx]));
      dff d3(.clk(clk), .enable(word3_we), .d_in(write_data[bit_idx]), .q_out(word3[bit_idx]));
    end
  endgenerate

  assign read_data = (read_addr==2'b00) ? word0 :
                     (read_addr==2'b01) ? word1 :
                     (read_addr==2'b10) ? word2 : word3;
endmodule

