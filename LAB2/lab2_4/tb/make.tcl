vlib work

quit -sim

vlog -sv  ../rtl/lab2_4.sv
vlog -sv  lab2_4_tb.sv

vlog -work work -refresh
vsim -novopt lab2_4_tb
add wave -hex -r lab2_4_tb/*

run -all



