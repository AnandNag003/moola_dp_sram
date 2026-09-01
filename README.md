# ⚡ Moola True Dual-Port Byte-Enable SRAM (`moola_dp_sram`)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Standard](https://img.shields.io/badge/Language-SystemVerilog%20(IEEE%201800--2012)-brightgreen.svg)](#)

A parameterizable, synthesizable True Dual-Port Synchronous SRAM macro IP designed in **SystemVerilog (IEEE 1800-2012)**. 

Optimized for **FPGA Block RAM (BRAM)** inference with independent byte-write masking per port.

---

## 🌟 Key Features

* **True Dual-Port (TDP) Architecture:** Fully independent clock domains (`clk_a`, `clk_b`), chip enables, address buses, and data lines.
* **FPGA BRAM-Friendly Byte Strobes:** Byte-sliced internal array representation (`mem_array [NUM_BYTES-1:0][DEPTH-1:0]`) guarantees single-cycle byte write-enable inference.
* **Deterministic Initialization:** Native `$readmemh` memory pre-loading with automated bit-slice repacking for hex firmware initialization.
* **Read-First Pipeline Mode:** Preserves prior memory state during concurrent read-write access to eliminate race conditions.

---

## 📐 Interface Specification

### Parameters
| Parameter | Default | Description |
| :--- | :--- | :--- |
| `DATA_WIDTH` | `32` | Data bus width in bits |
| `ADDR_WIDTH` | `14` | Address width in words ($2^{14} = 16,384\text{ words} = 64\text{ KB}$) |
| `BYTE_WIDTH` | `8` | Bits per byte lane |
| `NUM_BYTES` | `DATA_WIDTH / BYTE_WIDTH` | Total byte strobes per port |
| `INIT_FILE_EN`| `1'b0` | Set `1'b1` to load memory array from hex file on startup |
| `INIT_FILE` | `"mem_init.hex"` | Path to hex initialization file |

### Port Signals (Identical for Port A & Port B)
| Signal | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `clk_x` | Input | 1 | Port clock |
| `rst_x` | Input | 1 | Synchronous read-port reset |
| `en_x` | Input | 1 | Active-high chip enable |
| `wstrb_x` | Input | `NUM_BYTES` | Active-high byte-write enable mask |
| `addr_x` | Input | `ADDR_WIDTH` | Word address |
| `wdata_x` | Input | `DATA_WIDTH` | Write data |
| `rdata_x` | Output | `DATA_WIDTH` | Synchronous registered read data |

---

## 🚀 Quickstart & Simulation

### Prerequisites
* **Icarus Verilog** (`iverilog` >= v11.0)
* **Make**

### Running Regression
```bash
make run