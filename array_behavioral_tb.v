//------------------------------------------------------------------------------
// Testbench: array_behavioral_tb
// Feature: exercises array_behavioral by writing then verifying registered reads
// Variables:
//   clk        - clock driving the DUT
//   write_data - stimulus data written into memory
//   write_addr - address used during write phase
//   write_en   - enables write transactions
//   read_addr  - address used during readback
//   read_data  - data observed from DUT
//   errors     - count of mismatches detected
// Future Improvements:
//   * randomize write/read sequences for broader coverage
//   * include reset behavior tests
//   * expand depth and add boundary condition checks
//------------------------------------------------------------------------------
`timescale 1ns/1ps
module array_behavioral_tb;
  localparam WIDTH = 8;
  localparam DEPTH = 4;
  localparam ADDR  = $clog2(DEPTH);

  reg clk;
  reg [WIDTH-1:0] write_data;
  reg [ADDR-1:0] write_addr;
  reg write_en;
  reg [ADDR-1:0] read_addr;
  wire [WIDTH-1:0] read_data;

  array_behavioral #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut(
    .clk(clk), .write_data(write_data), .write_addr(write_addr), .write_en(write_en), .read_addr(read_addr), .read_data(read_data)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer i;
  integer errors = 0;

  initial begin
    write_en = 0; write_data = 0; write_addr = 0; read_addr = 0;
    @(posedge clk); // initialize

    // write phase
    // refresher: load each address with a unique pattern
    for (i = 0; i < DEPTH; i = i + 1) begin
      @(posedge clk); // wait for clock edge to mimic synchronous write
      write_en = 1;                // enable write for this cycle
      write_addr = i[ADDR-1:0];    // target address
      write_data = i * 8'h11;      // simple pattern (multiples of 0x11)
    end
    @(posedge clk);
    write_en = 0; write_data = '0; write_addr = '0;

    // read phase
    // refresher: read_data updates one cycle after address because of registered output
    for (i = 0; i < DEPTH; i = i + 1) begin
      read_addr = i[ADDR-1:0];
      @(posedge clk); // allow read_data to capture selected word
      if (read_data !== i * 8'h11) begin
        $display("Read mismatch at %0d: expected %0h got %0h", i, i * 8'h11, read_data);
        errors = errors + 1;
      end
    end

    if (errors == 0)
      $display("array_behavioral_tb PASS");
    else
      $display("array_behavioral_tb FAIL with %0d errors", errors);
    $finish;
  end
endmodule
