#!/bin/bash

exec 3< ~/.serverlist.txt 

while read -u 3 server; do
	printf "$server: "

	if ! (
		ssh "$server" '
			if [ -f /var/run/reboot-required ]; then
				printf "Reboot required *"
			else
				printf "No reboot required"
			fi
		' 2> /dev/null
	) then
		printf "Offline"
	fi
	
	printf "\n"
done
