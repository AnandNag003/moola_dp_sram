//=============================================================================
// IP Name      : Moola True Dual-Port Byte-Enable SRAM (moola_dp_sram)
// Description  : Parameterized, FPGA-BRAM inferable True Dual-Port Synchronous
//                SRAM with independent byte write strobes per port.
// Features     : 
//   - Fully parameterizable DATA_WIDTH, ADDR_WIDTH, and BYTE_WIDTH
//   - Independent Clock, Enable, Write-Strobe, Address, and Data buses per port
//   - True Read-First synchronous memory array behavior
//   - Clean 32-bit word Hex memory initialization ($readmemh) support
//=============================================================================

`timescale 1ns / 1ps

module moola_dp_sram #(
  parameter int DATA_WIDTH     = 32,                          // Width of data bus in bits
  parameter int ADDR_WIDTH     = 14,                          // Depth = 2^ADDR_WIDTH (14 = 16384 words = 64 KB for 32-bit)
  parameter int BYTE_WIDTH     = 8,                           // Bits per byte lane
  parameter int NUM_BYTES      = DATA_WIDTH / BYTE_WIDTH,     // Number of byte strobes
  parameter bit INIT_FILE_EN   = 1'b0,                        // Enable pre-loading from file
  parameter string INIT_FILE   = "mem_init.hex"               // Path to hex file
)(
  // -------------------------------------------------------------------------
  // Port A Interface (Typically Instruction Fetch / IMEM)
  // -------------------------------------------------------------------------
  input  logic                      clk_a,
  input  logic                      rst_a,                    // Synchronous read-port reset
  input  logic                      en_a,                     // Port A chip enable
  input  logic [NUM_BYTES-1:0]      wstrb_a,                  // Port A byte-write enable mask
  input  logic [ADDR_WIDTH-1:0]     addr_a,                   // Port A word address
  input  logic [DATA_WIDTH-1:0]     wdata_a,                  // Port A write data
  output logic [DATA_WIDTH-1:0]     rdata_a,                  // Port A read data (registered output)

  // -------------------------------------------------------------------------
  // Port B Interface (Typically Data Load/Store / DMEM)
  // -------------------------------------------------------------------------
  input  logic                      clk_b,
  input  logic                      rst_b,                    // Synchronous read-port reset
  input  logic                      en_b,                     // Port B chip enable
  input  logic [NUM_BYTES-1:0]      wstrb_b,                  // Port B byte-write enable mask
  input  logic [ADDR_WIDTH-1:0]     addr_b,                   // Port B word address
  input  logic [DATA_WIDTH-1:0]     wdata_b,                  // Port B write data
  output logic [DATA_WIDTH-1:0]     rdata_b                   // Port B read data (registered output)
);

  // -------------------------------------------------------------------------
  // Parameter Validation
  // -------------------------------------------------------------------------
  initial begin
    if (DATA_WIDTH % BYTE_WIDTH != 0) begin
      $fatal(1, "[moola_tdp_sram] DATA_WIDTH (%0d) must be an integer multiple of BYTE_WIDTH (%0d).",
             DATA_WIDTH, BYTE_WIDTH);
    end
  end

  // Derive total memory depth in words
  localparam int DEPTH = 1 << ADDR_WIDTH;

  // -------------------------------------------------------------------------
  // Memory Array Definition
  // -------------------------------------------------------------------------
  // 2D byte-split array guarantees clean FPGA BRAM write-strobe inference
  (* ram_style = "block" *) logic [BYTE_WIDTH-1:0] mem_array [NUM_BYTES-1:0][DEPTH-1:0];

  // Internal output registers for synchronous read latency (1 cycle)
  logic [DATA_WIDTH-1:0] rdata_a_reg;
  logic [DATA_WIDTH-1:0] rdata_b_reg;

  // -------------------------------------------------------------------------
  // Memory Array Initialization
  // -------------------------------------------------------------------------
  initial begin
    // Clear entire memory array to zero
    for (int b = 0; b < NUM_BYTES; b++) begin
      for (int w = 0; w < DEPTH; w++) begin
        mem_array[b][w] = '0;
      end
    end

    // Pre-load from hex file if enabled
    if (INIT_FILE_EN) begin
      logic [DATA_WIDTH-1:0] temp_mem [DEPTH-1:0];
      
      // Initialize temp_mem to zero so unwritten hex lines don't become 'X'
      for (int w = 0; w < DEPTH; w++) begin
        temp_mem[w] = '0;
      end

      $display("[moola_dp_sram] Preloading memory data from: %s", INIT_FILE);
      $readmemh(INIT_FILE, temp_mem);

      // Distribute 32-bit words into individual byte slices
      for (int w = 0; w < DEPTH; w++) begin
        for (int b = 0; b < NUM_BYTES; b++) begin
          mem_array[b][w] = temp_mem[w][(b*BYTE_WIDTH) +: BYTE_WIDTH];
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // Port A Synchronous Logic (Read-First Mode)
  // -------------------------------------------------------------------------
  generate
    for (genvar i = 0; i < NUM_BYTES; i++) begin : gen_port_a
      always_ff @(posedge clk_a) begin
        if (rst_a) begin
          rdata_a_reg[(i*BYTE_WIDTH) +: BYTE_WIDTH] <= '0;
        end else if (en_a) begin
          // Synchronous Read: latches data currently in the array
          rdata_a_reg[(i*BYTE_WIDTH) +: BYTE_WIDTH] <= mem_array[i][addr_a];

          // Synchronous Byte Write: updates byte lane if strobe bit is high
          if (wstrb_a[i]) begin
            mem_array[i][addr_a] <= wdata_a[(i*BYTE_WIDTH) +: BYTE_WIDTH];
          end
        end
      end
    end
  endgenerate

  // -------------------------------------------------------------------------
  // Port B Synchronous Logic (Read-First Mode)
  // -------------------------------------------------------------------------
  generate
    for (genvar j = 0; j < NUM_BYTES; j++) begin : gen_port_b
      always_ff @(posedge clk_b) begin
        if (rst_b) begin
          rdata_b_reg[(j*BYTE_WIDTH) +: BYTE_WIDTH] <= '0;
        end else if (en_b) begin
          // Synchronous Read: latches data currently in the array
          rdata_b_reg[(j*BYTE_WIDTH) +: BYTE_WIDTH] <= mem_array[j][addr_b];

          // Synchronous Byte Write: updates byte lane if strobe bit is high
          if (wstrb_b[j]) begin
            mem_array[j][addr_b] <= wdata_b[(j*BYTE_WIDTH) +: BYTE_WIDTH];
          end
        end
      end
    end
  endgenerate

  // Continuous assignments to drive output ports
  assign rdata_a = rdata_a_reg;
  assign rdata_b = rdata_b_reg;

endmodule : moola_dp_sram