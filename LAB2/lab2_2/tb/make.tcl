vlib work

quit -sim

vlog -sv  ../rtl/lab2_2.sv
vlog -sv  lab2_2_tb.sv

vlog -work work -refresh
vsim -novopt lab2_2_tb
add wave -hex -r lab2_2_tb/*

run -all



