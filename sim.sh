#!/bin/sh
# Запуск моделирования в Icarus Verilog:  ./sim.sh
set -e
iverilog -g2012 -I. -o sim.out apb_slave.sv apb_master.sv top.sv
vvp sim.out
