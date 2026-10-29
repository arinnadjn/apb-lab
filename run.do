vlib work
vlog -sv +incdir+. apb_slave.sv apb_master.sv top.sv
vsim work.top
add wave -r /top/*
run -all