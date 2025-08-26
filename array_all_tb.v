//------------------------------------------------------------------------------
// Testbench: array_all_tb
// Description: Runs basic tests for array_behavioral, array_dataflow,
//              and array_structural memories.
//------------------------------------------------------------------------------
`timescale 1ns/1ps
module array_all_tb;
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
  localparam DEPTH = 4;
  localparam ADDR  = clog2(DEPTH);

  // shared clock
  reg clk;
  initial clk = 0;
  always #5 clk = ~clk;

  // signals for behavioral memory
  reg [WIDTH-1:0] write_data_beh;
  reg [ADDR-1:0] write_addr_beh;
  reg write_en_beh;
  reg [ADDR-1:0] read_addr_beh;
  wire [WIDTH-1:0] read_data_beh;

  array_behavioral #(.WIDTH(WIDTH), .DEPTH(DEPTH), .ADDR(ADDR)) dut_beh (
    .clk(clk), .write_data(write_data_beh), .write_addr(write_addr_beh),
    .write_en(write_en_beh), .read_addr(read_addr_beh), .read_data(read_data_beh)
  );

  // signals for dataflow memory
  reg [WIDTH-1:0] write_data_data;
  reg [ADDR-1:0] write_addr_data;
  reg write_en_data;
  reg [ADDR-1:0] read_addr_data;
  wire [WIDTH-1:0] read_data_data;

  array_dataflow #(.WIDTH(WIDTH), .DEPTH(DEPTH), .ADDR(ADDR)) dut_data (
    .clk(clk), .write_data(write_data_data), .write_addr(write_addr_data),
    .write_en(write_en_data), .read_addr(read_addr_data), .read_data(read_data_data)
  );

  // signals for structural memory
  reg [WIDTH-1:0] write_data_struct;
  reg [1:0] write_addr_struct;
  reg write_en_struct;
  reg [1:0] read_addr_struct;
  wire [WIDTH-1:0] read_data_struct;

  array_structural #(.WIDTH(WIDTH)) dut_struct (
    .clk(clk), .write_data(write_data_struct), .write_addr(write_addr_struct),
    .write_en(write_en_struct), .read_addr(read_addr_struct), .read_data(read_data_struct)
  );

  // task to test behavioral memory
  task test_behavioral;
    integer i; integer errors;
    begin
      errors = 0;
      write_en_beh = 0; write_data_beh = 0; write_addr_beh = 0; read_addr_beh = 0;
      for (i = 0; i < DEPTH; i = i + 1) begin
        write_en_beh = 1;
        write_addr_beh = i[ADDR-1:0];
        write_data_beh = i * 8'h11;
        @(posedge clk);
      end
      write_en_beh = 0;
      @(posedge clk);
      for (i = 0; i < DEPTH; i = i + 1) begin
        read_addr_beh = i[ADDR-1:0];
        @(posedge clk);
        #1;
        if (read_data_beh !== i * 8'h11) begin
          $display("Behavioral mismatch at %0d: expected %0h got %0h", i, i * 8'h11, read_data_beh);
          errors = errors + 1;
        end
      end
      if (errors == 0)
        $display("array_behavioral PASS");
      else
        $display("array_behavioral FAIL with %0d errors", errors);
    end
  endtask

  // task to test dataflow memory
  task test_dataflow;
    integer i; integer errors;
    begin
      errors = 0;
      write_en_data = 0; write_data_data = 0; write_addr_data = 0; read_addr_data = 0;
      for (i = 0; i < DEPTH; i = i + 1) begin
        write_en_data = 1;
        write_addr_data = i[ADDR-1:0];
        write_data_data = i * 8'h22;
        @(posedge clk);
      end
      write_en_data = 0;
      @(posedge clk);
      for (i = 0; i < DEPTH; i = i + 1) begin
        read_addr_data = i[ADDR-1:0];
        #1;
        if (read_data_data !== i * 8'h22) begin
          $display("Dataflow mismatch at %0d: expected %0h got %0h", i, i * 8'h22, read_data_data);
          errors = errors + 1;
        end
        @(posedge clk);
      end
      if (errors == 0)
        $display("array_dataflow PASS");
      else
        $display("array_dataflow FAIL with %0d errors", errors);
    end
  endtask

  // task to test structural memory
  task test_structural;
    integer i; integer errors;
    begin
      errors = 0;
      write_en_struct = 0; write_data_struct = 0; write_addr_struct = 0; read_addr_struct = 0;
      for (i = 0; i < 4; i = i + 1) begin
        write_en_struct = 1;
        write_addr_struct = i[1:0];
        write_data_struct = i * 8'h33;
        @(posedge clk);
      end
      write_en_struct = 0;
      @(posedge clk);
      for (i = 0; i < 4; i = i + 1) begin
        read_addr_struct = i[1:0];
        #1;
        if (read_data_struct !== i * 8'h33) begin
          $display("Structural mismatch at %0d: expected %0h got %0h", i, i * 8'h33, read_data_struct);
          errors = errors + 1;
        end
        @(posedge clk);
      end
      if (errors == 0)
        $display("array_structural PASS");
      else
        $display("array_structural FAIL with %0d errors", errors);
    end
  endtask

  initial begin
    test_behavioral;
    test_dataflow;
    test_structural;
    $display("array_all_tb complete");
    $finish;
  end
endmodule
