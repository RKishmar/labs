vlib work

quit -sim

vlog -sv  ../rtl/fifo.sv
vlog -sv  fifo_tb.sv

vlog -work work -refresh
vsim -novopt fifo_tb
add wave -hex -r fifo_tb/*

run -all



