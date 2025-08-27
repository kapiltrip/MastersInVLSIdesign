//------------------------------------------------------------------------------
// File: array_db.v
// Description: Simple synchronous memory using behavioral modeling. The design
//              illustrates a parameterized RAM with a single clock, registered
//              read data, and synchronous write capability, making it a compact
//              template for small buffers or register files.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Module: array_behavioral_simple
// Feature: parameterized memory with synchronous write and registered read
// This lightweight module demonstrates how a reg array can model a memory
// block. Data is written on the rising edge when enabled, and the addressed
// word is presented on the output at the next clock cycle.
//------------------------------------------------------------------------------
module array_behavioral_simple #(parameter WIDTH=8, DEPTH=4, ADDR=2) (
  input                 clk,
  input  [WIDTH-1:0]    write_data,
  input  [ADDR-1:0]     write_addr,
  input                 write_en,
  input  [ADDR-1:0]     read_addr,
  output reg [WIDTH-1:0] read_data
);
  // memory array
  reg [WIDTH-1:0] mem_array [DEPTH-1:0];
  integer i;

  // initialize memory and output to known values
  initial begin
    for (i = 0; i < DEPTH; i = i + 1)
      mem_array[i] = {WIDTH{1'b0}};
    read_data = {WIDTH{1'b0}};
  end

  // synchronous write and registered read
  always @(posedge clk) begin
    read_data <= mem_array[read_addr];
    if (write_en)
      mem_array[write_addr] <= write_data;
  end
endmodule

