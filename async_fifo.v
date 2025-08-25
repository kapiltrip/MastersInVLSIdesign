//------------------------------------------------------------------------------
// Module: async_fifo
// Feature: asynchronous FIFO with Gray-coded read/write pointers and status
// Concept: bridges independent write/read clocks by exchanging only pointers
//          across domains, avoiding data-path synchronization
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
//   write_ptr_bin_sync/read_ptr_bin_sync - pointers after CDC for status logic
// Concept: pointers include an extra MSB to track wraparound and discriminate
//          between full and empty conditions
// Revision: m - expanded block-level commentary and clarified variable roles
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
  // Each pointer uses ADDR+1 bits: ADDR for indexing, MSB as a wrap indicator
  reg [ADDR:0] write_ptr_bin, write_ptr_gray, read_ptr_bin, read_ptr_gray;
  reg [ADDR:0] write_ptr_gray_sync1, write_ptr_gray_sync2;
  reg [ADDR:0] read_ptr_gray_sync1, read_ptr_gray_sync2;
  // ---------------------------------------------------------------------------
  // WRITE DOMAIN LOGIC: advance pointer and store data in write clock domain
  // ---------------------------------------------------------------------------
  always @(posedge write_clk or negedge write_reset_n) begin
    if (!write_reset_n) write_ptr_bin <= 0;
    // capture data only when FIFO has space; pointer advances in binary for easy arithmetic
    else if (write_en && !full) begin
      fifo_mem[write_ptr_bin[ADDR-1:0]] <= write_data; // store data at current pointer
      write_ptr_bin <= write_ptr_bin + 1;              // increment to next location
    end
  end
  /*
    Concept: The write clock domain owns this sequential block.  It stores
    incoming data into FIFO memory and advances a binary pointer when space is
    available.  Using binary arithmetic keeps the increment logic straightforward
    while gating writes with the full flag prevents overflow into unread data.
  */
  // convert binary pointer to Gray code so only one bit toggles between updates
  // this minimizes uncertainty when the pointer value crosses into read domain
  always @* write_ptr_gray = (write_ptr_bin >> 1) ^ write_ptr_bin;
  /*
    Concept: Gray coding the write pointer ensures only a single bit changes
    per increment, reducing ambiguity when the read clock samples this value.
    Fewer simultaneous bit flips make cross-domain synchronization more robust.
  */
  // ---------------------------------------------------------------------------
  // READ DOMAIN LOGIC: fetch data and advance pointer under read clock
  // ---------------------------------------------------------------------------
  always @(posedge read_clk or negedge read_reset_n) begin
    if (!read_reset_n) read_ptr_bin <= 0;
    else if (read_en && !empty) read_ptr_bin <= read_ptr_bin + 1; // move to next unread word
  end
  always @* read_ptr_gray = (read_ptr_bin >> 1) ^ read_ptr_bin;
  assign read_data = fifo_mem[read_ptr_bin[ADDR-1:0]]; // output data in read domain
  /*
    Concept: The read process mirrors the write side but operates on the read
    clock.  Data is fetched from memory only when the FIFO is non-empty, and the
    binary read pointer advances accordingly.  Converting this pointer to Gray
    code prepares it for safe transmission back to the write domain.
  */
  // ---------------------------------------------------------------------------
  // POINTER SYNCHRONIZATION: two-flop CDC for Gray-coded pointers
  // ---------------------------------------------------------------------------
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
  /*
    Concept: Each domain captures the other's Gray pointer through a pair of
    flip-flops, a classic CDC technique that filters metastability.  Once
    aligned with the local clock, the synchronized Gray values are converted
    back to binary so arithmetic comparisons can safely determine FIFO status.
  */
  // ---------------------------------------------------------------------------
  // STATUS FLAGS: compare synchronized pointers to derive FIFO state
  // ---------------------------------------------------------------------------
  // FIFO is full when write pointer has wrapped once beyond synchronized read pointer
  assign full  = ( (write_ptr_gray[ADDR:ADDR-1] == ~read_ptr_gray_sync2[ADDR:ADDR-1]) &&
                   (write_ptr_gray[ADDR-2:0] == read_ptr_gray_sync2[ADDR-2:0]) );
  // FIFO is empty when both pointers match after crossing into read domain
  assign empty = (write_ptr_gray_sync2 == read_ptr_gray);
  /*
    Concept: Full and empty conditions arise from comparing synchronized
    pointers.  A differing MSB indicates that the write pointer has wrapped
    around, while matching lower bits confirm alignment.  This logic prevents
    overwriting unread data and stops reads when no data remains.
  */
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
  /*
    Concept: gray2bin performs cumulative XOR operations starting from the
    most-significant bit, reconstructing the original binary count from its
    Gray-coded representation.  This decoding is essential when arithmetic on
    synchronized pointers is required.
  */
endmodule
