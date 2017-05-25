#!/bin/bash

# File with a server name on each line
serverList=~/.serverlist.txt

# Update commands to run for each server
read -r -d '' updateCommands <<-EOF0
	/bin/sh <<EOF1

		# Update commands for pfSense
		if(uname -a | egrep pfSense >/dev/null); then 
			pfSense-upgrade
		
		# Update commands for Debian and derivatives
		elif(uname -a | egrep 'Debian|Ubuntu|PVE' >/dev/null); then 
			sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y autoremove
		fi

	EOF1
EOF0

# Terminal text styling templates
FORMAT_RESET="\x1b[0m"
FORMAT_HEADING="\x1b[1;4m"
FORMAT_SUCCESS="\x1b[42m"
FORMAT_FAIL="\x1b[41m"
function printHeading(){
	printf "$FORMAT_HEADING" >&3
	printf "%s\n" "--- $1 ---"
	printf "$FORMAT_RESET" >&3
}
function printSuccess(){
	printf "$FORMAT_SUCCESS" >&3
	printf "SUCCESS: " >&2
	printf "%s\n" "$1" >&2
	printf "$FORMAT_RESET" >&3
}
function printFail(){
	printf "$FORMAT_FAIL" >&3
	printf "FAIL: " >&2
	printf "%s\n" "$1" >&2
	printf "$FORMAT_RESET" >&3
}

# Only enable pretty printing if stdout is a terminal
if [ -t 1 ]; then
	exec 3>&1
else
	exec 3>/dev/null
fi

# Needed to prevent screen breaking TERM variable
export TERM="xterm-color"

# For each line of the server list
exec 4< "$serverList"
while read -u 4 server; do
	printHeading "Updating $server"
	
	ssh "$server" "$updateCommands" 2> /dev/null
	exitCode="$?"
	
	case "$exitCode" in
		255)
			printFail "$server is offline."
			;;
		0)
			printSuccess "$server is now up to date."
			;;
		*)
			printFail "$server exited with status code $exitCode."
			;;
	esac

	echo ""
done
