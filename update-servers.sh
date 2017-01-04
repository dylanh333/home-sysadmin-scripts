#!/bin/bash

exec 3< ~/.serverlist.txt

export TERM=xterm
while read -u 3 server; do
	echo "--- Updating $server"
	
	if ! (
		ssh "$server" "sudo apt-get -y update; sudo apt-get -y upgrade; sudo apt-get -y autoremove" 2> /dev/null
	) then
		echo "$server is offline."
	else
		echo "$server is now up to date."
	fi

	echo ""
done
