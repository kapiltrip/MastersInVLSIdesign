//============================================================
// Verilog testbench for 4-bit up/down counters
// Instantiates behavioral, dataflow, and structural versions
//============================================================
`timescale 1ns/1ps
module tb_up_down_counter;
  reg        clk;
  reg        reset;
  reg        up;
  wire [3:0] count_behav;
  wire [3:0] count_data;
  wire [3:0] count_struct;
  reg  [3:0] expected;
  integer    i;
  integer    errors;

  // Devices Under Test
  up_down_counter_behavioral dut_behav (
    .clk   (clk),
    .reset (reset),
    .up    (up),
    .count (count_behav)
  );

  up_down_counter_dataflow dut_data (
    .clk   (clk),
    .reset (reset),
    .up    (up),
    .count (count_data)
  );

  up_down_counter_structural dut_struct (
    .clk   (clk),
    .reset (reset),
    .up    (up),
    .count (count_struct)
  );

  // clock generator: 100MHz
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    errors   = 0;
    expected = 4'd0;
    reset    = 1'b1; // apply reset for one cycle
    up       = 1'b1; // start with count up
    @(posedge clk);  // allow reset to propagate
    #1 reset = 1'b0; // release reset after clock edge

    // count up for 10 cycles
    for (i = 0; i < 10; i = i + 1) begin
      @(posedge clk);
      #1; // wait for counter update
      expected = expected + 1;
      if (count_behav !== expected) begin
        $display("UP BEHAV ERROR: exp=%0d got=%0d", expected, count_behav);
        errors = errors + 1;
      end
      if (count_data !== expected) begin
        $display("UP DATA ERROR: exp=%0d got=%0d", expected, count_data);
        errors = errors + 1;
      end
      if (count_struct !== expected) begin
        $display("UP STRUCT ERROR: exp=%0d got=%0d", expected, count_struct);
        errors = errors + 1;
      end
    end

    // now count down for 10 cycles
    up = 1'b0;
    for (i = 0; i < 10; i = i + 1) begin
      @(posedge clk);
      #1; // wait for counter update
      expected = expected - 1;
      if (count_behav !== expected) begin
        $display("DOWN BEHAV ERROR: exp=%0d got=%0d", expected, count_behav);
        errors = errors + 1;
      end
      if (count_data !== expected) begin
        $display("DOWN DATA ERROR: exp=%0d got=%0d", expected, count_data);
        errors = errors + 1;
      end
      if (count_struct !== expected) begin
        $display("DOWN STRUCT ERROR: exp=%0d got=%0d", expected, count_struct);
        errors = errors + 1;
      end
    end

    if (errors == 0)
      $display("PASS: all up/down counter implementations verified.");
    else
      $display("FAIL: %0d mismatches detected.", errors);
    $finish;
  end
endmodule
