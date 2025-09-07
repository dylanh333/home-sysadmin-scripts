#!/bin/bash
while [ 1 ]; do
	clear
	
	sensors coretemp-isa-0000
	
	lsblk -dne 7 -o PATH | while read disk; do smartctl -a "$disk" | sed "s,^,$disk: ,"; done | grep -i temp

	sleep 5
done
