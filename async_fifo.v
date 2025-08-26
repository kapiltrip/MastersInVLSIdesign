//------------------------------------------------------------------------------
// Module: async_fifo
// Simple asynchronous FIFO that moves data between two clocks with Gray pointers.
// Signals list:
//   write_clk       - clock used when pushing data into the fifo
//   write_reset_n   - active-low reset for the write side
//   write_en        - when high, store write_data
//   write_data      - data bus that gets written
//   read_clk        - clock used when pulling data out
//   read_reset_n    - active-low reset for the read side
//   read_en         - when high, grab the next word
//   read_data       - data bus that leaves the fifo
//   full            - high means the fifo has no room left
//   empty           - high means there's nothing to read
//   fifo_mem        - actual storage array
//   write_ptr_bin   - binary write pointer
//   write_ptr_gray  - same write pointer but Gray coded for crossing clocks
//   read_ptr_bin    - binary read pointer
//   read_ptr_gray   - Gray-coded read pointer
//   write_ptr_gray_sync* / read_ptr_gray_sync* - pointers after syncing to the
//       other clock domain
// Future ideas:
//   * maybe add almost_full / almost_empty flags
//   * options to guard against overflow or underflow
//   * room for formal checks or other assertions later on
//------------------------------------------------------------------------------

// function: clog2 (defined inside this file)
// purpose: figure out how many address bits we need without leaving plain Verilog-2001

module async_fifo #(
  parameter DATA_WIDTH = 8,
  parameter DEPTH = 16
)(
  write_clk, write_reset_n, write_en, write_data,
  read_clk, read_reset_n, read_en, read_data,
  full, empty
);
  // manual clog2 here so file stays self-contained and still pure Verilog-2001
  function integer clog2;
    input integer value; // number we are checking
    integer i;
    begin
      value = value - 1;
      for (i = 0; value > 0; i = i + 1)
        value = value >> 1;
      clog2 = i; // how many bits it takes to count up to value-1
    end
  endfunction
  localparam ADDR = clog2(DEPTH); // address width adjusts automatically with DEPTH

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
  // both clocks touch this array, so it ends up acting like a tiny dual-port RAM
  reg [ADDR:0] write_ptr_bin, write_ptr_gray, read_ptr_bin, read_ptr_gray;
  // ADDR+1 bits give an extra MSB so we can tell when the pointers wrap
  reg [ADDR:0] write_ptr_gray_sync1, write_ptr_gray_sync2;
  reg [ADDR:0] read_ptr_gray_sync1, read_ptr_gray_sync2;
  // write pointer and memory
  // handled in the write clock domain
  always @(posedge write_clk or negedge write_reset_n) begin
    if (!write_reset_n) write_ptr_bin <= 0;
    // store incoming data only when space available
    // pointer stays in binary so math stays simple
    else if (write_en && !full) begin
      fifo_mem[write_ptr_bin[ADDR-1:0]] <= write_data; // store data at current pointer
      write_ptr_bin <= write_ptr_bin + 1;              // move to next location
    end
  end
  // turn the binary pointer into Gray code so only one bit flips each step
  always @* write_ptr_gray = (write_ptr_bin >> 1) ^ write_ptr_bin;
  // read side mirrors the write logic but runs on the read clock
  always @(posedge read_clk or negedge read_reset_n) begin
    if (!read_reset_n) read_ptr_bin <= 0;
    else if (read_en && !empty) read_ptr_bin <= read_ptr_bin + 1; // step to next unread slot
  end
  always @* read_ptr_gray = (read_ptr_bin >> 1) ^ read_ptr_bin;
  assign read_data = fifo_mem[read_ptr_bin[ADDR-1:0]]; // data appears in the read clock domain
  // pass Gray pointers safely between clocks
  always @(posedge write_clk or negedge write_reset_n) begin
    if (!write_reset_n) {read_ptr_gray_sync1, read_ptr_gray_sync2} <= 0;
    else {read_ptr_gray_sync1, read_ptr_gray_sync2} <= {read_ptr_gray_sync2, read_ptr_gray};
  end
  always @(posedge read_clk or negedge read_reset_n) begin
    if (!read_reset_n) {write_ptr_gray_sync1, write_ptr_gray_sync2} <= 0;
    else {write_ptr_gray_sync1, write_ptr_gray_sync2} <= {write_ptr_gray_sync2, write_ptr_gray};
  end
  // double-register the Gray pointers to calm metastability when moving between clocks
  // after syncing, turn Gray back to binary for any math or occupancy checks
  wire [ADDR:0] write_ptr_bin_sync, read_ptr_bin_sync;
  assign write_ptr_bin_sync = gray2bin(write_ptr_gray_sync2);
  assign read_ptr_bin_sync = gray2bin(read_ptr_gray_sync2);
  // status flags
  // full goes high when the write pointer laps the synced read pointer
  assign full  = ( (write_ptr_gray[ADDR:ADDR-1] == ~read_ptr_gray_sync2[ADDR:ADDR-1]) &&
                   (write_ptr_gray[ADDR-2:0] == read_ptr_gray_sync2[ADDR-2:0]) );
  // empty goes high when pointers line up after crossing into the read clock
  assign empty = (write_ptr_gray_sync2 == read_ptr_gray);
  // helper to convert Gray code back into plain binary
  function [ADDR:0] gray2bin;
    input [ADDR:0] gray_value;
    integer bit_idx;
    begin
      gray2bin[ADDR] = gray_value[ADDR];
        // XOR with previous decoded bit to peel off Gray encoding
      for (bit_idx = ADDR-1; bit_idx >= 0; bit_idx = bit_idx-1)
        gray2bin[bit_idx] = gray2bin[bit_idx+1] ^ gray_value[bit_idx];
    end
  endfunction
endmodule
