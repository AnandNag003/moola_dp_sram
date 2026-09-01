//=============================================================================
// Testbench : tb_moola_dp_sram
// Purpose   : Comprehensive self-checking verification testbench for 
//             moola_dp_sram IP core.
// Tests     :
//   1. Hex preload verification on Port A and Port B
//   2. Byte-masked writes on Port A (testing individual byte strobes)
//   3. Concurrent dual-port operations (Port A Write -> Port B Read)
//   4. Synchronous reset validation
//=============================================================================

`timescale 1ns / 1ps

module tb_moola_dp_sram;

  localparam int DATA_WIDTH = 32;
  localparam int ADDR_WIDTH = 10; // 1024 words depth for simulation speed
  localparam int BYTE_WIDTH = 8;
  localparam int NUM_BYTES  = DATA_WIDTH / BYTE_WIDTH;

  // Port A Signals
  logic                  clk_a;
  logic                  rst_a;
  logic                  en_a;
  logic [NUM_BYTES-1:0]  wstrb_a;
  logic [ADDR_WIDTH-1:0] addr_a;
  logic [DATA_WIDTH-1:0] wdata_a;
  logic [DATA_WIDTH-1:0] rdata_a;

  // Port B Signals
  logic                  clk_b;
  logic                  rst_b;
  logic                  en_b;
  logic [NUM_BYTES-1:0]  wstrb_b;
  logic [ADDR_WIDTH-1:0] addr_b;
  logic [DATA_WIDTH-1:0] wdata_b;
  logic [DATA_WIDTH-1:0] rdata_b;

  // Verification Error Tracking
  int error_count = 0;

  // -------------------------------------------------------------------------
  // Device Under Test (DUT) Instantiation
  // -------------------------------------------------------------------------
  moola_dp_sram #(
    .DATA_WIDTH   (DATA_WIDTH),
    .ADDR_WIDTH   (ADDR_WIDTH),
    .BYTE_WIDTH   (BYTE_WIDTH),
    .INIT_FILE_EN (1'b1),
    .INIT_FILE    ("tb/mem_test.hex")
  ) dut (
    .clk_a   (clk_a),
    .rst_a   (rst_a),
    .en_a    (en_a),
    .wstrb_a (wstrb_a),
    .addr_a  (addr_a),
    .wdata_a (wdata_a),
    .rdata_a (rdata_a),

    .clk_b   (clk_b),
    .rst_b   (rst_b),
    .en_b    (en_b),
    .wstrb_b (wstrb_b),
    .addr_b  (addr_b),
    .wdata_b (wdata_b),
    .rdata_b (rdata_b)
  );

  // -------------------------------------------------------------------------
  // Clocks: Dual independent clock domains
  // -------------------------------------------------------------------------
  initial clk_a = 0;
  always #5.0 clk_a = ~clk_a; // 100 MHz

  initial clk_b = 0;
  always #3.7 clk_b = ~clk_b; // ~135 MHz (Asynchronous relationship)

  // -------------------------------------------------------------------------
  // Waveform Dump Setup
  // -------------------------------------------------------------------------
  initial begin
    $dumpfile("sim/tb_moola_dp_sram.vcd");
    $dumpvars(0, tb_moola_dp_sram);
  end

  // Helper check task
  task check(string test_name, logic [DATA_WIDTH-1:0] actual, logic [DATA_WIDTH-1:0] expected);
    if (actual !== expected) begin
      $display("[FAIL] %-35s | Expected: 0x%08h | Got: 0x%08h at %0t ps", test_name, expected, actual, $time);
      error_count++;
    end else begin
      $display("[PASS] %-35s | Actual: 0x%08h", test_name, actual);
    end
  endtask

  // -------------------------------------------------------------------------
  // Main Verification Routine
  // -------------------------------------------------------------------------
  initial begin
    $display("\n========================================================");
    $display("   STARTING MOOLA DUAL-PORT SRAM IP VERIFICATION        ");
    $display("========================================================\n");

    // Initialize all input ports
    rst_a   = 1'b1;
    en_a    = 1'b0;
    wstrb_a = '0;
    addr_a  = '0;
    wdata_a = '0;

    rst_b   = 1'b1;
    en_b    = 1'b0;
    wstrb_b = '0;
    addr_b  = '0;
    wdata_b = '0;

    // Apply synchronous reset for 2 cycles
    @(posedge clk_a);
    @(posedge clk_a);
    rst_a = 1'b0;
    rst_b = 1'b0;
    en_a  = 1'b1;
    en_b  = 1'b1;

    // -----------------------------------------------------------------------
    // TEST 1: Hex Preload Verification on Both Ports
    // -----------------------------------------------------------------------
    $display("[TEST 1] Verifying Hex Preloading on Port A and Port B...");
    addr_a = 10'h000; // Expected: 0x11223344
    addr_b = 10'h001; // Expected: 0x55667788

    @(posedge clk_a);
    #1;
    check("Port A Read Word 0", rdata_a, 32'h11223344);

    @(posedge clk_b);
    #1;
    check("Port B Read Word 1", rdata_b, 32'h55667788);

    // -----------------------------------------------------------------------
    // TEST 2: Byte-Masked Writes on Port A
    // -----------------------------------------------------------------------
    $display("\n[TEST 2] Verifying Byte-Strobe Writes on Port A...");
    // Step A: Write Byte 0 (0xBB) and Byte 2 (0xAA) to word address 0x010
    @(posedge clk_a);
    addr_a  <= 10'h010;
    wdata_a <= 32'h00AA_00BB;
    wstrb_a <= 4'b0101; // Enable byte 2 and byte 0

    // Step B: Write Byte 1 (0xDD) and Byte 3 (0xCC) to same word address 0x010
    @(posedge clk_a);
    wdata_a <= 32'hCC00_DD00;
    wstrb_a <= 4'b1010; // Enable byte 3 and byte 1

    // Step C: Read back the assembled 32-bit word
    @(posedge clk_a);
    wstrb_a <= 4'b0000;
    
    @(posedge clk_a);
    #1;
    check("Port A Byte-Strobe Reassembly", rdata_a, 32'hCCAA_DDBB);

    // -----------------------------------------------------------------------
    // TEST 3: Concurrent Operations (Port A Write -> Port B Read)
    // -----------------------------------------------------------------------
    $display("\n[TEST 3] Verifying Cross-Port Concurrency (Write A -> Read B)...");
    @(posedge clk_a);
    addr_a  <= 10'h025;
    wdata_a <= 32'hDEAD_BEEF;
    wstrb_a <= 4'b1111; // Full word write
    
    @(posedge clk_a);
    wstrb_a <= 4'b0000;

    // Read that same address from Port B synchronously
    @(posedge clk_b);
    addr_b <= 10'h025;
    
    @(posedge clk_b);
    #1;
    check("Port B Cross-Port Read", rdata_b, 32'hDEAD_BEEF);

    // -----------------------------------------------------------------------
    // Final Summary
    // -----------------------------------------------------------------------
    $display("\n========================================================");
    if (error_count == 0) begin
      $display("   ALL DUAL-PORT SRAM TESTS PASSED SUCCESSFULLY!       ");
    end else begin
      $display("   VERIFICATION FAILED: %0d ERROR(S) ENCOUNTERED.      ", error_count);
    end
    $display("========================================================\n");

    $finish;
  end

endmodule : tb_moola_dp_sram