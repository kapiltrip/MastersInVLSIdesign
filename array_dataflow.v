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

// function: clog2 (defined within module)
// purpose: derive address width from depth using only Verilog-2001 constructs

module array_dataflow #(parameter WIDTH=8, DEPTH=16) (
  clk, write_data, write_addr, write_en, read_addr, read_data
);
  // manual clog2 function avoids extra include files while remaining pure Verilog-2001
  function integer clog2;
    input integer value; // value to evaluate
    integer i;
    begin
      value = value - 1;
      for (i = 0; value > 0; i = i + 1)
        value = value >> 1;
      clog2 = i; // returns number of address bits
    end
  endfunction
  localparam ADDR = clog2(DEPTH); // address width derived from DEPTH

  input              clk;
  input [WIDTH-1:0]  write_data;
  input [ADDR-1:0]   write_addr;
  input              write_en;
  input [ADDR-1:0]   read_addr;
  output [WIDTH-1:0] read_data;
  reg [WIDTH-1:0] mem_array [0:DEPTH-1];
  // refresher: array acts as simple RAM, indexed by addresses
  always @(posedge clk) begin
    if (write_en)
      mem_array[write_addr] <= write_data; // store data on rising edge
  end
  // refresher: combinational read returns data immediately without clock delay
  assign read_data = mem_array[read_addr];
endmodule
