#!/bin/bash

#check if a filename is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

filename=$1

num_lsmod=$(lsmod | wc -l)
if [ "$num_lsmod" -eq "2" ]; then
    echo "Removing kernel module..."
    rmmod main
fi

# Disable FPGA bridges
echo "Disabling FPGA bridges..."
echo 0 > /sys/class/fpga-bridge/fpga2hps/enable
echo 0 > /sys/class/fpga-bridge/hps2fpga/enable
echo 0 > /sys/class/fpga-bridge/lwhps2fpga/enable

# Program FPGA
echo "Programming FPGA with $filename..."
dd if="$filename" of=/dev/fpga0 bs=1M

# Enable FPGA bridges
echo "Enabling FPGA bridges..."
echo 1 > /sys/class/fpga-bridge/fpga2hps/enable
echo 1 > /sys/class/fpga-bridge/hps2fpga/enable
echo 1 > /sys/class/fpga-bridge/lwhps2fpga/enable

echo "Adding kernel module..."
insmod HPSChicken/kernel/main/main.ko

echo "Done."
