//------------------------------------------------------------------------------
// Testbench: array_dataflow_tb
// Feature: validates array_dataflow by checking combinational reads
// Variables:
//   clk        - clock for write operations and loop progression
//   write_data - stimulus data written into memory
//   write_addr - address for write transactions
//   write_en   - enables writes during test
//   read_addr  - address used for combinational readback
//   read_data  - data observed from DUT output
//   errors     - mismatch counter
// Future Improvements:
//   * incorporate random delays between writes and reads
//   * add reset sequence and error injection
//   * scale to larger depths for stress testing
//------------------------------------------------------------------------------

// function: clog2 (defined below)
// purpose: computes address width from depth using only Verilog-2001 constructs
`timescale 1ns/1ps
module array_dataflow_tb;
  // manual clog2 function avoids extra include files while remaining pure Verilog-2001
  function integer clog2;
    input integer value; // value to evaluate
    integer i;
    begin
      value = value - 1;
      for (i = 0; value > 0; i = i + 1)
        value = value >> 1;
      clog2 = i; // number of address bits required
    end
  endfunction
  localparam WIDTH = 8;
  localparam DEPTH = 4;
  localparam ADDR  = clog2(DEPTH); // address width based on depth

  reg clk;
  reg [WIDTH-1:0] write_data;
  reg [ADDR-1:0] write_addr;
  reg write_en;
  reg [ADDR-1:0] read_addr;
  wire [WIDTH-1:0] read_data;

  array_dataflow #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut(
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
    // refresher: populate memory so later reads have known values
    for (i = 0; i < DEPTH; i = i + 1) begin
      @(posedge clk);           // synchronous write
      write_en = 1;
      write_addr = i[ADDR-1:0]; // select word
      write_data = i * 8'h22;   // patterned data
    end
    @(posedge clk);
    // reset control signals and data using standard Verilog zeros
    write_en = 0; write_data = 0; write_addr = 0;

    // read phase
    // refresher: combinational output means data appears without waiting for clock
    for (i = 0; i < DEPTH; i = i + 1) begin
      read_addr = i[ADDR-1:0];
      #1; // allow mux to settle
      if (read_data !== i * 8'h22) begin
        $display("Read mismatch at %0d: expected %0h got %0h", i, i * 8'h22, read_data);
        errors = errors + 1;
      end
      @(posedge clk); // advance clock for next iteration
    end

    if (errors == 0)
      $display("array_dataflow_tb PASS");
    else
      $display("array_dataflow_tb FAIL with %0d errors", errors);
    $finish;
  end
endmodule
