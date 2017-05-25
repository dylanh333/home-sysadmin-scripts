#!/bin/bash

# Serverlist file
serverList=~/.serverlist.txt

# Update commands
updateCommands="sudo apt-get -y update; sudo apt-get -y upgrade; sudo apt-get -y autoremove"

# Terminal text styling templates
FORMAT_RESET="\x1b[0m"
FORMAT_HEADING="\x1b[1;4m"
FORMAT_SUCCESS="\x1b[42m"
FORMAT_FAIL="\x1b[41m"
function printHeading(){
	printf "$FORMAT_HEADING"
	printf "%s\n" "--- $1 ---"
	printf "$FORMAT_RESET"
}
function printSuccess(){
	printf "$FORMAT_SUCCESS"
	printf "SUCCESS: "
	printf "%s\n" "$1"
	printf "$FORMAT_RESET"
}
function printFail(){
	printf "$FORMAT_FAIL"
	printf "FAIL: " >&2
	printf "%s\n" "$1" >&2
	printf "$FORMAT_RESET"
}

# Needed to prevent screen breaking TERM variable
export TERM="xterm-color"

# For each line of the server list
exec 3< "$serverList"
while read -u 3 server; do
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
