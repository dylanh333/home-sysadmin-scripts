#!/bin/bash
while [ 1 ]; do
	clear
	cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq
	sleep 5
done
