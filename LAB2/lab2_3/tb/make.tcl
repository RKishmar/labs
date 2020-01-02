vlib work

quit -sim

vlog -sv  ../rtl/lab2_3.sv
vlog -sv  lab2_3_tb.sv

vlog -work work -refresh
vsim -novopt lab2_3_tb
add wave -hex -r lab2_3_tb/*

run -all



