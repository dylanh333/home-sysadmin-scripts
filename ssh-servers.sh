#!/bin/bash

exec 3< ~/.serverlist.txt 

while read -u 3 server; do
	echo "--- $server";
	sleep 1;
	ssh "$server";
	echo "";
done
