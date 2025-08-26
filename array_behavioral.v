//------------------------------------------------------------------------------
// Module: array_behavioral
// Feature: parameterized memory with synchronous write and registered read
// Variables:
//   clk        - clock driving all operations
//   write_data - input data written when write_en is asserted
//   write_addr - address selecting the memory word to update
//   write_en   - enables storing write_data into memory_array
//   read_addr  - address of the word to output
//   read_data  - registered readback of selected word
// Future Improvements:
//   * add asynchronous reset to clear memory contents
//   * implement byte enables for partial word writes
//   * parameterize read latency for pipelined designs
//------------------------------------------------------------------------------

// function: clog2 (defined within module)
// purpose: compute address width from depth using only Verilog-2001 constructs

module array_behavioral #(parameter WIDTH=8, DEPTH=16) (
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

  input                 clk;
  input  [WIDTH-1:0]    write_data;
  input  [ADDR-1:0]     write_addr;
  input                 write_en;
  input  [ADDR-1:0]     read_addr;
  output reg [WIDTH-1:0] read_data;
  reg [WIDTH-1:0] mem_array [0:DEPTH-1];
  // refresher: memory array holds DEPTH words, addressed by write_addr/read_addr
  always @(posedge clk) begin
    // refresher: sequential block means writes occur only on rising edges
    if (write_en)
      mem_array[write_addr] <= write_data; // store new data into selected word
    // refresher: registered read adds one-cycle latency for synchronous behavior
    read_data <= mem_array[read_addr];
  end
endmodule
