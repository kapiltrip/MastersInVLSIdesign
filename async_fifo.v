//------------------------------------------------------------------------------
// Module: async_fifo
// Feature: asynchronous FIFO with Gray-coded read/write pointers and status
// Variables:
//   write_clk       - clock for write domain
//   write_reset_n   - active-low reset for write domain
//   write_en        - enables data storage into FIFO
//   write_data      - input data bus for write operations
//   read_clk        - clock for read domain
//   read_reset_n    - active-low reset for read domain
//   read_en         - enables data retrieval from FIFO
//   read_data       - output data bus from FIFO
//   full            - asserted when FIFO cannot accept more data
//   empty           - asserted when FIFO has no data to read
//   fifo_mem        - storage array
//   write_ptr_bin   - binary write pointer
//   write_ptr_gray  - Gray-coded write pointer
//   read_ptr_bin    - binary read pointer
//   read_ptr_gray   - Gray-coded read pointer
//   write_ptr_gray_sync* / read_ptr_gray_sync* - synchronized pointers across
//       clock domains
// Future Improvements:
//   * expose almost_full/almost_empty status outputs
//   * add parameterizable overflow/underflow protection
//   * incorporate formal verification or assertions
//------------------------------------------------------------------------------
module async_fifo #(
  parameter DATA_WIDTH = 8,
  parameter DEPTH = 16,
  parameter ADDR = $clog2(DEPTH)
)(
  input                     write_clk,
  input                     write_reset_n,
  input                     write_en,
  input  [DATA_WIDTH-1:0]   write_data,
  input                     read_clk,
  input                     read_reset_n,
  input                     read_en,
  output [DATA_WIDTH-1:0]   read_data,
  output                    full,
  output                    empty
);
  reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];
  // FIFO memory is accessed from two clock domains; arrays act as simple dual-port RAM
  reg [ADDR:0] write_ptr_bin, write_ptr_gray, read_ptr_bin, read_ptr_gray;
  // Extra MSB (ADDR+1 bits) lets us detect when write and read pointers wrap around
  reg [ADDR:0] write_ptr_gray_sync1, write_ptr_gray_sync2;
  reg [ADDR:0] read_ptr_gray_sync1, read_ptr_gray_sync2;
  // write pointer and memory
  always @(posedge write_clk or negedge write_reset_n) begin
    if (!write_reset_n) write_ptr_bin <= 0;
    // capture data only when FIFO has space; pointer advances in binary for easy arithmetic
    else if (write_en && !full) begin
      fifo_mem[write_ptr_bin[ADDR-1:0]] <= write_data; // store data at current pointer
      write_ptr_bin <= write_ptr_bin + 1;              // increment to next location
    end
  end
  // convert binary pointer to Gray code so only one bit toggles between updates
  always @* write_ptr_gray = (write_ptr_bin >> 1) ^ write_ptr_bin;
  // read pointer logic mirrors write side but operates on read clock
  always @(posedge read_clk or negedge read_reset_n) begin
    if (!read_reset_n) read_ptr_bin <= 0;
    else if (read_en && !empty) read_ptr_bin <= read_ptr_bin + 1; // move to next unread word
  end
  always @* read_ptr_gray = (read_ptr_bin >> 1) ^ read_ptr_bin;
  assign read_data = fifo_mem[read_ptr_bin[ADDR-1:0]]; // output data in read domain
  // synchronize pointers across domains
  always @(posedge write_clk or negedge write_reset_n) begin
    if (!write_reset_n) {read_ptr_gray_sync1, read_ptr_gray_sync2} <= 0;
    else {read_ptr_gray_sync1, read_ptr_gray_sync2} <= {read_ptr_gray_sync2, read_ptr_gray};
  end
  always @(posedge read_clk or negedge read_reset_n) begin
    if (!read_reset_n) {write_ptr_gray_sync1, write_ptr_gray_sync2} <= 0;
    else {write_ptr_gray_sync1, write_ptr_gray_sync2} <= {write_ptr_gray_sync2, write_ptr_gray};
  end
  // double-register the Gray pointers to suppress metastability when crossing clock domains
  // convert synchronized Gray pointers back to binary for potential arithmetic/occupancy checks
  wire [ADDR:0] write_ptr_bin_sync, read_ptr_bin_sync;
  assign write_ptr_bin_sync = gray2bin(write_ptr_gray_sync2);
  assign read_ptr_bin_sync = gray2bin(read_ptr_gray_sync2);
  // status flags
  // FIFO is full when write pointer has wrapped once beyond synchronized read pointer
  assign full  = ( (write_ptr_gray[ADDR:ADDR-1] == ~read_ptr_gray_sync2[ADDR:ADDR-1]) &&
                   (write_ptr_gray[ADDR-2:0] == read_ptr_gray_sync2[ADDR-2:0]) );
  // FIFO is empty when both pointers match after crossing into read domain
  assign empty = (write_ptr_gray_sync2 == read_ptr_gray);
  // gray to binary function
  function [ADDR:0] gray2bin;
    input [ADDR:0] gray_value;
    integer bit_idx;
    begin
      gray2bin[ADDR] = gray_value[ADDR];
        // XOR each bit with the higher-order result to decode Gray
      for (bit_idx = ADDR-1; bit_idx >= 0; bit_idx = bit_idx-1)
        gray2bin[bit_idx] = gray2bin[bit_idx+1] ^ gray_value[bit_idx];
    end
  endfunction
endmodule
