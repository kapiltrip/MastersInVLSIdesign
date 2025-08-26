//------------------------------------------------------------------------------
// Module: async_fifo
// Feature: asynchronous FIFO with Gray-coded read/write pointers and status flags
// Variables:
//   write_clk       - clock that drives writes
//   write_reset_n   - active-low reset for write side
//   write_en        - enables storing data into FIFO
//   write_data      - data bus used when writing
//   read_clk        - clock that drives reads
//   read_reset_n    - active-low reset for read side
//   read_en         - enables taking data from FIFO
//   read_data       - data bus seen when reading
//   full            - high when FIFO cannot take more writes
//   empty           - high when FIFO has nothing to read
//   fifo_mem        - array that keeps all data words
//   write_ptr_bin   - binary form of write pointer
//   write_ptr_gray  - write pointer changed into Gray code
//   read_ptr_bin    - binary form of read pointer
//   read_ptr_gray   - read pointer changed into Gray code
//   write_ptr_gray_sync* / read_ptr_gray_sync* - pointers moved safe across
//       clock domains
// Future Improvements:
//   * expose almost_full/almost_empty status outputs
//   * add parameterizable overflow/underflow protection
//   * incorporate formal verification or assertions
//------------------------------------------------------------------------------

// function: clog2 (defined within module)
// purpose: find ceiling of log2 using plain Verilog-2001 for parameter math

module async_fifo #(
  parameter DATA_WIDTH = 8,
  parameter DEPTH = 16
)(
  write_clk, write_reset_n, write_en, write_data,
  read_clk, read_reset_n, read_en, read_data,
  full, empty
);
  // manual clog2 function avoids extra include files and stays in plain Verilog-2001
  function integer clog2;
    input integer value; // number to check for needed bits
    integer i;
    begin
      value = value - 1;
      for (i = 0; value > 0; i = i + 1)
        value = value >> 1;
      clog2 = i; // return bit count needed to index value-1
    end
  endfunction
  localparam ADDR = clog2(DEPTH); // number of bits for address and pointers

  input                     write_clk;
  input                     write_reset_n;
  input                     write_en;
  input  [DATA_WIDTH-1:0]   write_data;
  input                     read_clk;
  input                     read_reset_n;
  input                     read_en;
  output [DATA_WIDTH-1:0]   read_data;
  output                    full;
  output                    empty;
  reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];
  // FIFO memory seen by both clocks; array works like simple dual-port RAM
  reg [ADDR:0] write_ptr_bin, write_ptr_gray, read_ptr_bin, read_ptr_gray;
  // Extra MSB (ADDR+1 bits) helps know when pointers have wrapped around each other
  reg [ADDR:0] write_ptr_gray_sync1, write_ptr_gray_sync2;
  reg [ADDR:0] read_ptr_gray_sync1, read_ptr_gray_sync2;
  // write pointer and memory control
  always @(posedge write_clk or negedge write_reset_n) begin
    if (!write_reset_n) write_ptr_bin <= 0;
    // capture data only when FIFO has space; pointer counts in binary for easy math
    else if (write_en && !full) begin
      fifo_mem[write_ptr_bin[ADDR-1:0]] <= write_data; // store data at current pointer
      write_ptr_bin <= write_ptr_bin + 1;              // go to next location
    end
  end
  // convert binary pointer to Gray so only one bit changes between updates
  always @* write_ptr_gray = (write_ptr_bin >> 1) ^ write_ptr_bin;
  // read pointer logic looks like write side but uses read clock
  always @(posedge read_clk or negedge read_reset_n) begin
    if (!read_reset_n) read_ptr_bin <= 0;
    else if (read_en && !empty) read_ptr_bin <= read_ptr_bin + 1; // move to next data word
  end
  always @* read_ptr_gray = (read_ptr_bin >> 1) ^ read_ptr_bin;
  assign read_data = fifo_mem[read_ptr_bin[ADDR-1:0]]; // data seen in read domain
  // synchronize pointers across clock domains
  always @(posedge write_clk or negedge write_reset_n) begin
    if (!write_reset_n) {read_ptr_gray_sync1, read_ptr_gray_sync2} <= 0;
    else {read_ptr_gray_sync1, read_ptr_gray_sync2} <= {read_ptr_gray_sync2, read_ptr_gray};
  end
  always @(posedge read_clk or negedge read_reset_n) begin
    if (!read_reset_n) {write_ptr_gray_sync1, write_ptr_gray_sync2} <= 0;
    else {write_ptr_gray_sync1, write_ptr_gray_sync2} <= {write_ptr_gray_sync2, write_ptr_gray};
  end
  // double-register Gray pointers to lower metastability when crossing domains
  // convert the synchronized Gray pointers back to binary for any math or checks
  wire [ADDR:0] write_ptr_bin_sync, read_ptr_bin_sync;
  assign write_ptr_bin_sync = gray2bin(write_ptr_gray_sync2);
  assign read_ptr_bin_sync = gray2bin(read_ptr_gray_sync2);
  // status flags
  // FIFO is full when write pointer wrapped once beyond synced read pointer
  assign full  = ( (write_ptr_gray[ADDR:ADDR-1] == ~read_ptr_gray_sync2[ADDR:ADDR-1]) &&
                   (write_ptr_gray[ADDR-2:0] == read_ptr_gray_sync2[ADDR-2:0]) );
  // FIFO is empty when both pointers match after sync into read domain
  assign empty = (write_ptr_gray_sync2 == read_ptr_gray);
  // gray to binary function
  function [ADDR:0] gray2bin;
    input [ADDR:0] gray_value; // Gray value to turn into binary
    integer bit_idx;
    begin
      gray2bin[ADDR] = gray_value[ADDR];
        // XOR each bit with higher one to decode Gray into binary
      for (bit_idx = ADDR-1; bit_idx >= 0; bit_idx = bit_idx-1)
        gray2bin[bit_idx] = gray2bin[bit_idx+1] ^ gray_value[bit_idx];
    end
  endfunction
endmodule
