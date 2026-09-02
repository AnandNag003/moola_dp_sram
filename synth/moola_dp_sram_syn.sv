`timescale 1ns / 1ps

module moola_dp_sram_syn #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 6,
  parameter int BYTE_WIDTH = 8,
  parameter int NUM_BYTES  = DATA_WIDTH / BYTE_WIDTH
)(
  input  logic                  clk,
  input  logic                  rst,
  // Port A
  input  logic                  en_a,
  input  logic [NUM_BYTES-1:0]  wstrb_a,
  input  logic [ADDR_WIDTH-1:0] addr_a,
  input  logic [DATA_WIDTH-1:0] wdata_a,
  output logic [DATA_WIDTH-1:0] rdata_a,
  // Port B
  input  logic                  en_b,
  input  logic [NUM_BYTES-1:0]  wstrb_b,
  input  logic [ADDR_WIDTH-1:0] addr_b,
  input  logic [DATA_WIDTH-1:0] wdata_b,
  output logic [DATA_WIDTH-1:0] rdata_b
);

  moola_dp_sram #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .BYTE_WIDTH(BYTE_WIDTH),
    .INIT_FILE_EN(1'b0)
  ) u_sram (
    .clk_a(clk), .rst_a(rst), .en_a(en_a), .wstrb_a(wstrb_a), .addr_a(addr_a), .wdata_a(wdata_a), .rdata_a(rdata_a),
    .clk_b(clk), .rst_b(rst), .en_b(en_b), .wstrb_b(wstrb_b), .addr_b(addr_b), .wdata_b(wdata_b), .rdata_b(rdata_b)
  );

endmodule
