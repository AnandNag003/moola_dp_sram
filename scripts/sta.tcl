read_liberty sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog synth/moola_dp_sram.vg
link_design moola_dp_sram_syn
create_clock -name clk -period 10.0 [get_ports clk]
set_input_delay 0.5 -clock clk [get_ports {rst en_a en_b wstrb_a* wstrb_b* addr_a* addr_b* wdata_a* wdata_b*}]
set_output_delay 0.5 -clock clk [get_ports {rdata_a* rdata_b*}]
report_checks -path_delay max -fields {input_pin slew cap net fanout}
report_checks -path_delay min -fields {input_pin slew cap net fanout}
report_power
exit
