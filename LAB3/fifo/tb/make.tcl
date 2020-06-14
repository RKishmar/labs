vlib work

quit -sim

vlog     q_scfifo.v
vlog -sv ../rtl/fifo.sv
vlog -sv fifo_tb.sv
vlog -work work -refresh

vsim -novopt work.fifo_tb -L altera_mf_ver 

add wave -hex -r fifo_tb/*

run -all



