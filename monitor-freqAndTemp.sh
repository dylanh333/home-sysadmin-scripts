#!/bin/bash

while [ 1 ]; do
	clear

	echo "-- CPU Frequencies"
	ls /sys/devices/system/cpu/ | egrep "cpu[0-9]+" | while read cpu; do
		printf '%s: %s kHz\n' "$cpu" "$(cat /sys/devices/system/cpu/$cpu/cpufreq/scaling_cur_freq)"
	done
	echo ""

	echo "-- Temperatures"
	sensors coretemp-isa-0000

	sleep 5
done
