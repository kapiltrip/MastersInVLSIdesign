//------------------------------------------------------------------------------
// Module: array_dataflow
// Feature: memory with synchronous write and combinational read access
// Variables:
//   clk        - clock governing memory updates
//   write_data - data to store on write operations
//   write_addr - address specifying which word to update
//   write_en   - enables storing write_data into memory_array
//   read_addr  - address selecting which word to output
//   read_data  - combinational readback of selected word
// Future Improvements:
//   * add read enable to gate combinational outputs
//   * include optional output register for timing closure
//   * support initialization from file for simulation
//------------------------------------------------------------------------------
module array_dataflow #(parameter WIDTH=8, DEPTH=16, ADDR=$clog2(DEPTH)) (
  input              clk,
  input [WIDTH-1:0]  write_data,
  input [ADDR-1:0]   write_addr,
  input              write_en,
  input [ADDR-1:0]   read_addr,
  output [WIDTH-1:0] read_data
);
  reg [WIDTH-1:0] mem_array [0:DEPTH-1];
  // refresher: array acts as simple RAM, indexed by addresses
  always @(posedge clk) begin
    if (write_en)
      mem_array[write_addr] <= write_data; // store data on rising edge
  end
  // refresher: combinational read returns data immediately without clock delay
  assign read_data = mem_array[read_addr];
endmodule
