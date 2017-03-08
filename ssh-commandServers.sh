#!/bin/bash

exec 3< ~/.serverlist.txt

while read -u 3 server; do
	printf "%s %s: " '---' "$server";
	ssh "$server" "$*";
	echo "";
done
