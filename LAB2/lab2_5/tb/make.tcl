vlib work

quit -sim

vlog -sv  ../rtl/lab2_5.sv
vlog -sv  lab2_5_tb.sv

vlog -work work -refresh
vsim -novopt lab2_5_tb
add wave -hex -r lab2_5_tb/*

run -all



