# Запуск в ModelSim / Questa:  vsim -c -do run.do
vlib work
vlog -sv +incdir+. apb_slave.sv apb_master.sv top.sv
vsim -c work.top -do "run -all; quit -f"
