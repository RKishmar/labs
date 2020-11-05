vlib work

quit -sim

vlog     ../rtl/fifo_ip.v
vlog -sv ../rtl/packet_resolver.sv
vlog -sv ../rtl/packet_resolver_top.sv
vlog -sv packet_resolver_tb.sv
vlog -work work -refresh

vsim -novopt work.packet_resolver_tb -L altera_mf_ver 

add wave -hex -r packet_resolver_tb/*

run -all



