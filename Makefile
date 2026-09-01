# Simulator settings
SIM_TOOL   := iverilog
VVP_TOOL   := vvp
WAVE_TOOL  := gtkwave
FLAGS      := -g2012 -Wall

RTL_SRC    := rtl/moola_dp_sram.sv
TB_SRC     := tb/tb_moola_dp_sram.sv
OUT_DIR    := sim
TARGET     := $(OUT_DIR)/sram_sim
VCD_FILE   := $(OUT_DIR)/tb_moola_dp_sram.vcd

.PHONY: all compile run wave clean

all: run

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

compile: $(OUT_DIR)
	@echo "Compiling RTL and Testbench..."
	$(SIM_TOOL) $(FLAGS) -o $(TARGET) $(RTL_SRC) $(TB_SRC)

run: compile
	@echo "Running simulation..."
	$(VVP_TOOL) $(TARGET)

wave: run
	@echo "Launching GTKWave..."
	$(WAVE_TOOL) $(VCD_FILE) &

clean:
	@echo "Cleaning up build artifacts..."
	rm -rf $(OUT_DIR)
