#!/bin/bash

exec 3< ~/.serverlist.txt

while read -u 3 server; do
	echo "--- $server";
	ssh "$server" "
		egrep -i 'required[\t ]+pam_wheel.so$' /etc/pam.d/su;
		egrep -i '^permitrootlogin' '/etc/ssh/sshd_config';
		egrep '^sudo' /etc/group;
		sudo egrep 'from=\"[^\"]+\"' /root/.ssh/authorized_keys
	"
	echo -e ""
done
