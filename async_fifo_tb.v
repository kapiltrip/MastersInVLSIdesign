`timescale 1ns/1ps

module async_fifo_tb;
  // --- Parameters (keep DEPTH a power-of-two for Gray-pointer full/empty correctness)
  localparam integer DATA_WIDTH = 8;
  localparam integer DEPTH      = 8;

  // --- Simple integer clog2 (Verilog-2001)
  function integer clog2;
    input integer value; 
    integer i;
    begin
      value = value - 1; //happens only once in the loop as to reach the correct value of the bits used.
      for (i=0; value>0; i=i+1) 
          value = value >> 1; 
          clog2 = i;   
    end
  endfunction
  localparam integer ADDR = clog2(DEPTH);  //address width  , like needed to count all the address depth , we need address width . 

  // --- DUT I/O
  reg                   write_clk, write_reset_n, write_en;  //resets write pointer 
  reg  [DATA_WIDTH-1:0] write_data;
  reg                   read_clk,  read_reset_n,  read_en;  //resets read pointer 
  wire [DATA_WIDTH-1:0] read_data;
  wire                  full, empty;                         
  wire [ADDR:0]         count;                               //addr +1 width , its like occupancy counter, so should be ADDR+1


  // --- Instantiate DUT
  async_fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (    //2 parameters 
    .write_clk(write_clk), .write_reset_n(write_reset_n), .write_en(write_en), .write_data(write_data),
    .read_clk(read_clk),   .read_reset_n(read_reset_n),   .read_en(read_en),   .read_data(read_data),
    .full(full), .empty(empty), .count(count)
  );

  // --- Clocks (co-prime to vary phase)
 initial begin 
  write_clk = 0; 
  forever #5 write_clk = ~write_clk; 
end

initial begin 
  read_clk  = 0;   
  forever #7 read_clk  = ~read_clk;  
end    //to create real asynchronous nature , i give it diffenent time . Hence a 7 ns delay.

  // --- Enforce power-of-two DEPTH (Gray-pointer scheme assumes this)
  initial begin
    if ((DEPTH & (DEPTH-1)) != 0) begin
      $display("ERROR: DEPTH=%0d must be a power-of-two for this FIFO.", DEPTH);
      $finish;
    end
  end

  // ------------------------------------------------------------
  // Tiny scoreboard: ring buffer + handshake-accurate accounting
  // ------------------------------------------------------------
  reg [DATA_WIDTH-1:0] sb_mem [0:DEPTH-1];
  integer sb_wr, sb_rd;  //read and write, from where the next data is read/will be written .
  integer sb_count;      //occupancy of the reference .
  integer errors;         //how much mismatch is there .
 
  // write-side scoreboard: push only when the DUT accepts the write
  always @(posedge write_clk or negedge write_reset_n) begin
    if (!write_reset_n) begin
      sb_wr    <= 0;
      sb_count <= 0;
    end else if (write_en && !full) begin
      sb_mem[sb_wr] <= write_data;
      sb_wr         <= (sb_wr + 1) % DEPTH;
      sb_count      <= sb_count + 1;
    end
  end

  // read-side reference : capture expected item at handshake,
  // then compare ONE read clock later to avoid races with DUT register
  reg [DATA_WIDTH-1:0] exp_pipe0, exp_pipe1;  //exp_pipe current version of the data, and exp_pipe1 is the delayed dataon the next clock edge it will have the expected data 

  reg vld0, vld1;  // 2-stage valid shift register if read happens , it will be high .


  always @(posedge read_clk or negedge read_reset_n) begin
    if (!read_reset_n) begin
      sb_rd   <= 0;
      vld0    <= 0;
      vld1    <= 0;
      errors  <= 0;
    end else begin
      // pipeline shift for expected value
      vld1      <= vld0;
      exp_pipe1 <= exp_pipe0;  //read means pop bro.

      // when DUT accepts a read, pop scoreboard and arm a compare for next cycle
      if (read_en && !empty) begin
        exp_pipe0 <= sb_mem[sb_rd];
        sb_rd     <= (sb_rd + 1) % DEPTH;
        sb_count  <= sb_count - 1;
        vld0      <= 1'b1;
      end else begin
        vld0      <= 1'b0;  //vld0 is just telling us whether read handshake took place or not .
      end

      // compare in the *next* read clock
      if (vld1) begin
        if (read_data !== exp_pipe1) begin
          $display("ERROR @%0t: data mismatch exp=%0h got=%0h", $time, exp_pipe1, read_data);
          errors = errors + 1;
        end
      end
    end
  end

  // ------------------------------------------------------------
  // Simple helper tasks (Verilog-2001, automatic)
  // ------------------------------------------------------------
  task automatic wr_blocking(input [DATA_WIDTH-1:0] d);
    begin
      @(posedge write_clk);
      while (full) @(posedge write_clk);
      write_en   <= 1'b1;  //write enable 
      write_data <= d;
      @(posedge write_clk);
      write_en   <= 1'b0;
    end
  endtask

  task automatic rd_blocking;            //the keyword automatic will make it stack based. SO its not a parallel operation rather independent operation 

    begin
      @(posedge read_clk);
      while (empty) @(posedge read_clk);
      read_en <= 1'b1;
      @(posedge read_clk);  //read will happen here 
      read_en <= 1'b0;
    end
  endtask

  // ------------------------------------------------------------
  // Stimulus  //driver of the DUT module 
  // ------------------------------------------------------------
  integer i;
  integer seed;  //if we want random stumulus 

  initial begin
    // reset
    write_en = 0; read_en = 0; write_data = {DATA_WIDTH{1'b0}};
    write_reset_n = 0; read_reset_n = 0;   //to make a reset , so all 0

    repeat (3) @(posedge write_clk);   //we need some time for reset to propagate , so we simulate like this 

    repeat (2) @(posedge read_clk);  // with both the pulses 

    write_reset_n = 1; read_reset_n = 1;

    // ---- Phase A: directed fill to FULL (tests wrap boundary)
    for (i = 0; i < DEPTH; i = i + 1) begin
      wr_blocking(i * 8'h11);  // simple pattern like we r creating sample data 

    end
    // allow clocks to advance
    repeat (2) @(posedge write_clk);
    if (!full)  $display("WARN: expected FULL after %0d writes.", DEPTH);

    // ---- Phase B: directed drain to EMPTY
    for (i = 0; i < DEPTH; i = i + 1) begin
      rd_blocking();
    end
    repeat (2) @(posedge read_clk);
    if (!empty) $display("WARN: expected EMPTY after %0d reads.", DEPTH);

    // ---- Phase C: short mixed random traffic (forces wrap-around)
    seed = 32'h1BAD_B002;
    for (i = 0; i < 200; i = i + 1) begin
      // probabilistic attempt to write and/or read; tasks block on full/empty
      if ($random(seed) & 1) wr_blocking($random(seed));   //if random 32 bit number and 1 is 1 then we do writing , 
      if ($random(seed) & 1) rd_blocking();                     //random is always signed by nature 
    end
                                                                //so here seed is updated after a new number is created . 
    // ---- Final checks
    // sb_count tracks accepted writes - reads; DUT count is write-domain,
    // so allow a couple of write clocks to settle before comparing.
    repeat (3) @(posedge write_clk);
    if (sb_count !== count) begin
      $display("ERROR: count mismatch scoreboard=%0d dut=%0d", sb_count, count);
      errors = errors + 1;
    end

    if (errors == 0) $display("PASS: async_fifo minimal TB");
    else             $display("FAIL: %0d error(s) observed", errors);
    $finish;
  end

endmodule
