//------------------------------------------------------------------------------
// Testbench: array_db_tb
// Description: Runs basic tests for array_behavioral_simple memory.
//------------------------------------------------------------------------------
`timescale 1ns/1ps
module array_db_tb;
  // function to compute address width
  function integer clog2;
    input integer value; integer i;
    begin
      value = value - 1;
      for (i = 0; value > 0; i = i + 1)
        value = value >> 1;
      clog2 = i;
    end
endfunction 

  localparam WIDTH = 8;
  localparam DEPTH = 8;
  localparam ADDR  = clog2(DEPTH);

  // shared clock
  reg clk;
  initial clk = 0;
  always #5 clk = ~clk;

  // signals for memory
  reg [WIDTH-1:0] write_data;
  reg [ADDR-1:0] write_addr;
  reg write_en;
  reg [ADDR-1:0] read_addr;
  wire [WIDTH-1:0] read_data;

  array_behavioral_simple #(.WIDTH(WIDTH), .DEPTH(DEPTH), .ADDR(ADDR)) dut (
    .clk(clk), .write_data(write_data), .write_addr(write_addr),
    .write_en(write_en), .read_addr(read_addr), .read_data(read_data)
  );
 
  integer i; 
  integer errors;
  initial begin
    errors = 0;
    write_en = 0; write_data = 0; write_addr = 0; read_addr = 0;
    // write pattern
    for (i = 0; i < DEPTH; i = i + 1) begin
      @(negedge clk);           //so the inputs of the positive edges of array are stable .
      write_en = 1;
      write_addr = i[ADDR-1:0];
      write_data = i * 8'h11;
    end
    @(negedge clk);
    write_en = 0;
    // readback
    for (i = 0; i < DEPTH; i = i + 1) begin
      read_addr = i[ADDR-1:0];
      @(posedge clk);
      #1;
      if (read_data !== i * 8'h11) begin
        $display("Mismatch at %0d: expected %0h got %0h", i, i * 8'h11, read_data);
        errors = errors + 1;
      end
    end
    if (errors == 0)
      $display("array_behavioral_simple PASS");
    else
      $display("array_behavioral_simple FAIL with %0d errors", errors);
    $display("array_db_tb complete");
    $finish;
  end
endmodule

