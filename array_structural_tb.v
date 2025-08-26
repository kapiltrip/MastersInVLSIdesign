//------------------------------------------------------------------------------
// Testbench: array_structural_tb
// Feature: verifies structural memory by exercising per-word write enables
// Variables:
//   clk        - clock for synchronous operations
//   write_data - stimulus data written into selected word
//   write_addr - address selecting which word to write
//   write_en   - global write enable
//   read_addr  - address selecting word for readback
//   read_data  - output bus from DUT
//   errors     - counter for mismatches
// Future Improvements:
//   * parameterize depth to match DUT generalization
//   * introduce randomized write/read order
//   * add assertions for timing checks
//------------------------------------------------------------------------------
`timescale 1ns/1ps
module array_structural_tb;
  localparam WIDTH = 8;

  reg clk;
  reg [WIDTH-1:0] write_data;
  reg [1:0] write_addr;
  reg write_en;
  reg [1:0] read_addr;
  wire [WIDTH-1:0] read_data;

  array_structural #(.WIDTH(WIDTH)) dut(
    .clk(clk), .write_data(write_data), .write_addr(write_addr), .write_en(write_en), .read_addr(read_addr), .read_data(read_data)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer i;
  integer errors = 0;

  initial begin
    write_en = 0; write_data = 0; write_addr = 0; read_addr = 0;
    @(posedge clk);

    // write phase
    // refresher: each iteration updates one of four words
    for (i = 0; i < 4; i = i + 1) begin
      @(posedge clk);          // writes happen on clock edge
      write_en = 1;
      write_addr = i[1:0];     // decode to per-word enable inside DUT
      write_data = i * 8'h33;  // recognizable pattern
    end
    @(posedge clk);
    // clear signals using Verilog-2001 zero values
    write_en = 0; write_data = 0; write_addr = 0;

    // read phase
    // refresher: combinational mux returns selected word immediately
    for (i = 0; i < 4; i = i + 1) begin
      read_addr = i[1:0];
      #1; // allow mux to settle
      if (read_data !== i * 8'h33) begin
        $display("Read mismatch at %0d: expected %0h got %0h", i, i * 8'h33, read_data);
        errors = errors + 1;
      end
      @(posedge clk);
    end

    if (errors == 0)
      $display("array_structural_tb PASS");
    else
      $display("array_structural_tb FAIL with %0d errors", errors);
    $finish;
  end
endmodule
