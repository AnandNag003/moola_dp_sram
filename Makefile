# ==============================================================================
# Makefile: Moola True Dual-Port SRAM Flow
# Targets: Functional Simulation, Waveform Inspection, ASIC Synthesis, STA
# ==============================================================================

SIM_TOOL    := iverilog
VVP_TOOL    := vvp
WAVE_TOOL   := surfer
WAVE_FALLBK := gtkwave
SIM_FLAGS   := -g2012 -Wall

SV2V        := sv2v
YOSYS       := yosys
STA         := sta

RTL_SRC     := rtl/moola_dp_sram.sv
TB_SRC      := tb/tb_moola_dp_sram.sv
SYN_WRAPPER := synth/moola_dp_sram_syn.sv
PDK_LIB     := sky130_fd_sc_hd__tt_025C_1v80.lib

SIM_DIR     := sim
SYN_DIR     := synth

SIM_TARGET  := $(SIM_DIR)/sram_sim
VCD_FILE    := $(SIM_DIR)/tb_moola_dp_sram.vcd
SV2V_OUT    := $(SYN_DIR)/synth_input.v
NETLIST_OUT := $(SYN_DIR)/moola_dp_sram.vg
SYNTH_LOG   := $(SYN_DIR)/sram_synth.log
STA_LOG     := $(SYN_DIR)/sta.log

.PHONY: all simulate wave synth sta clean help

all: simulate synth sta

# --- Simulation Flow ---
compile:
	@mkdir -p $(SIM_DIR)
	@echo "[SIM] Compiling RTL and Testbench..."
	$(SIM_TOOL) $(SIM_FLAGS) -o $(SIM_TARGET) $(RTL_SRC) $(TB_SRC)

simulate: compile
	@echo "[SIM] Running functional simulation..."
	$(VVP_TOOL) $(SIM_TARGET)

wave: simulate
	@echo "[WAVE] Launching waveform viewer..."
	@if command -v $(WAVE_TOOL) >/dev/null 2>&1; then \
		$(WAVE_TOOL) $(VCD_FILE); \
	else \
		$(WAVE_FALLBK) $(VCD_FILE) & \
	fi

# --- ASIC Synthesis Flow ---
$(SV2V_OUT): $(RTL_SRC) $(SYN_WRAPPER)
	@mkdir -p $(SYN_DIR)
	@echo "[SV2V] Lowering SystemVerilog with scaled depth (ADDR_WIDTH=6)..."
	@sed 's/parameter int ADDR_WIDTH.*= 14/parameter int ADDR_WIDTH = 6/' $(RTL_SRC) > $(SYN_DIR)/moola_dp_sram_small.sv
	$(SV2V) $(SYN_DIR)/moola_dp_sram_small.sv $(SYN_WRAPPER) > $(SV2V_OUT)

synth: $(SV2V_OUT)
	@echo "[SYNTH] Running Yosys ASIC synthesis targeting SkyWater 130nm..."
	$(YOSYS) scripts/synth.ys | tee $(SYNTH_LOG)
	@echo "[SYNTH] Gate-level netlist generated: $(NETLIST_OUT)"

sta: synth
	@echo "[STA] Running OpenSTA timing and power analysis..."
	$(STA) scripts/sta.tcl | tee $(STA_LOG)

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(SIM_DIR)
	rm -f $(SYN_DIR)/synth_input.v $(SYN_DIR)/moola_dp_sram_small.sv
	rm -f $(SYN_DIR)/moola_dp_sram.vg $(SYNTH_LOG) $(STA_LOG)

help:
	@echo "Available targets:"
	@echo "  make simulate  : Run testbench simulation"
	@echo "  make wave      : Run simulation and view waveforms"
	@echo "  make synth     : Run sv2v lowering and Sky130 Yosys synthesis"
	@echo "  make sta       : Run static timing & power analysis (OpenSTA)"
	@echo "  make all       : Run simulation, synthesis, and STA"
	@echo "  make clean     : Remove generated build artifacts"
