#!/bin/bash

# File with a server name on each line
serverList=~/.serverlist.txt

# Update commands to run for each server
read -r -d '' updateCommands <<-EOF0
	/bin/sh <<EOF1

		# Update commands for pfSense
		if(uname -a | egrep pfSense >/dev/null); then 
			yes | pfSense-upgrade
		
		# Update commands for Debian and derivatives
		elif(uname -a | egrep 'Debian|Ubuntu|PVE' >/dev/null); then
			sudo apt-get -y update &&
			sudo env DEBIAN_FRONTEND=noninteractive \
				apt-get --with-new-pkgs -y upgrade &&
			sudo apt-get -y autoremove
		fi

	EOF1
EOF0

# Terminal text styling templates
FORMAT_RESET="\x1b[0m"
FORMAT_HEADING="\x1b[3;38m"
FORMAT_SUCCESS="\x1b[3;32m"
FORMAT_FAIL="\x1b[3;31m"
FORMAT_SUCCESS_MSG="\x1b[0;32m"
FORMAT_FAIL_MSG="\x1b[0;31m"
function printHeading(){
	printf "$FORMAT_HEADING" >&3
	printf "%s" "--- $1 ---"
	printf "$FORMAT_RESET" >&3
	printf "\n"
}
function printSuccess(){
	printf "$FORMAT_SUCCESS" >&3
	printf "[SUCCESS]" >&2
	printf "$FORMAT_SUCCESS_MSG" >&3
	printf " %s" "$1" >&2
	printf "$FORMAT_RESET" >&3
	printf "\n" >&2
}
function printFail(){
	printf "$FORMAT_FAIL" >&3
	printf "[FAIL]" >&2
	printf "$FORMAT_FAIL_MSG" >&3
	printf " %s" "$1" >&2
	printf "$FORMAT_RESET" >&3
	printf "\n" >&2
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
