vlib work

quit -sim

vlog -sv  ../rtl/lab2_6.sv
vlog -sv  lab2_6_tb.sv

vlog -work work -refresh
vsim -novopt lab2_6_tb
add wave -hex -r lab2_6_tb/*

run -all



