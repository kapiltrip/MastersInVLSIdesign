//------------------------------------------------------------------------------
// Testbench: async_fifo_tb
// Description: Drives the async_fifo with independent write and read clocks to
//              demonstrate safe data transfer across clock domains. The testbench
//              pushes a sequence of bytes into the FIFO, then reads them out while
//              checking the full and empty indicators and the reported count.
//------------------------------------------------------------------------------
`timescale 1ns/1ps
module async_fifo_tb;
  localparam DATA_WIDTH = 8;
  localparam DEPTH      = 8;

  function integer clog2;
    input integer value;
    integer i;
    begin
      value = value - 1;
      for (i = 0; value > 0; i = i + 1)
        value = value >> 1;
      clog2 = i;
    end
  endfunction
  localparam ADDR = clog2(DEPTH);

  reg write_clk, write_reset_n, write_en;
  reg [DATA_WIDTH-1:0] write_data;
  reg read_clk, read_reset_n, read_en;
  wire [DATA_WIDTH-1:0] read_data;
  wire full, empty;
  wire [ADDR:0] count;

  async_fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut(
    .write_clk(write_clk), .write_reset_n(write_reset_n), .write_en(write_en), .write_data(write_data),
    .read_clk(read_clk), .read_reset_n(read_reset_n), .read_en(read_en), .read_data(read_data),
    .full(full), .empty(empty), .count(count)
  );

  initial begin write_clk = 0; forever #5 write_clk = ~write_clk; end
  initial begin read_clk = 0; forever #7 read_clk = ~read_clk; end

  integer i;
  integer errors = 0;
  reg [DATA_WIDTH-1:0] expected [0:DEPTH-1];

  initial begin
    // initialize all signals to zero without using SystemVerilog literal syntax
    write_reset_n = 0; read_reset_n = 0; write_en = 0; read_en = 0; write_data = 0;
    #20; write_reset_n = 1; read_reset_n = 1;

    // write data into FIFO
    // refresher: push DEPTH items, watching for spurious full flag
    for (i = 0; i < DEPTH; i = i + 1) begin
      @(posedge write_clk);       // operate in write clock domain
      if (full) begin             // FIFO shouldn't be full yet
        $display("Unexpected full at write %0d", i);
        errors = errors + 1;
      end
      write_en = 1;               // request write
      write_data = i * 8'h44;     // patterned test data
      expected[i] = i * 8'h44;    // store for later comparison
    end
    @(posedge write_clk); write_en = 0; // stop writing
    if (count !== DEPTH) begin
      $display("Count mismatch after writes: expected %0d got %0d", DEPTH, count);
      errors = errors + 1;
    end

    // allow time before reading
    repeat (4) @(posedge read_clk);

    for (i = 0; i < DEPTH; i = i + 1) begin
      @(posedge read_clk);        // operate in read clock domain
      if (empty) begin            // should have data available
        $display("Unexpected empty at read %0d", i);
        errors = errors + 1;
      end
      read_en = 1;                // request read
      #1;                         // small delay for data to emerge
      if (read_data !== expected[i]) begin
        $display("Read mismatch at %0d: expected %0h got %0h", i, expected[i], read_data);
        errors = errors + 1;
      end
    end
    @(posedge read_clk); read_en = 0; // stop reading
    repeat (4) @(posedge write_clk);
    if (count !== 0) begin
      $display("Count mismatch after reads: expected 0 got %0d", count);
      errors = errors + 1;
    end

    if (errors == 0)
      $display("async_fifo_tb PASS");
    else
      $display("async_fifo_tb FAIL with %0d errors", errors);
    $finish;
  end
endmodule
