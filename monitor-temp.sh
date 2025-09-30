#!/bin/bash

function getSensorTemps(){
	sensors coretemp-isa-0000;
}

function getDiskTemps(){
	# TODO: Make sure this doesn't choke on the attribute output format
	# `smartctl` uses for NVMe disks.
	
	skipMissing=0;
	while true; do
		case "$1" in
			'-s')
				skipMissing=1;
				shift;
				continue;
			;;
			'')
				break;
			;;
			*)
				shift;
				continue;
			;;
		esac
	done


	lsblk -dne 7 -o PATH \
	| while read disk; do
		currAttrs='';
		matchingAttrs='';
		
		if currAttrs="$(smartctl -A "$disk")"; then
			echo "$currAttrs" | sed -r 's, +,\t,g';
		elif [ $skipMissing == 0 ]; then
			printf '0\tTemperature Unknown\t\t\t\t\t\t\t\tsmartctl couldn'"'"'t read attributes for disk.\n';
		fi \
		| if matchingAttrs="$(grep -E '^(190|194|0)')"; then
			echo "$matchingAttrs";
		  elif [ $skipMissing == 0 ]; then
			printf '0\tTemperature Unknown \t\t\t\t\t\t\t\tNo temperature attributes found (NVMe?).\n';
		  fi \
		| cut -sf 2,10 \
		| while read metric; do
			key="$(echo "$metric" | cut -f 1 | tr -d '\n')";
			val="$(echo "$metric" | cut -f 2 | tr -d '\n')";
			printf '%s: %s: %s\n' "$disk" "$key" "$val";
		  done

	  done
}

function getIpmiTemps(){
	ipmitool sdr type Temperature;
}

function getAllStats(){
	flags="$@";

	for stat in getSensorTemps getDiskTemps getIpmiTemps; do
		printf '%s:\n' "$stat";
		$stat $flags | sed -r 's,^,  ,';
		printf "\n----------\n\n";
	done
}

function usage(){
	cat <<EOF
Usage:
  $0 [ { -n | --nothing } | { -d | --dump } | { -i <interval> | --interval <interval> } ]

Options:
  -n, --nothing		Do nothing and exit. Useful for including this
			script's functions in other scripts.

  -d, --dump		Dump sensor values once and exit without watching them
			continuously.

  -i, --interval	Interval (seconds) between when the sensor values are
			refreshed. Defaults to 5 seconds.

  -s, --skip-missing	Skip devices (e.g. disks) where the tempoerature value
			can't be retreived.

EOF
}

function main(){
	interval=5;
	dump=0;
	flags='';

	while true; do
		case "$1" in
			'-n'|'--nothing')
				return;
			;;
			'-d'|'--dump')
				dump=1;
				
				shift;
				continue;
			;;
			'-i'|'--interval')
				if ! ( [ -n "$2" ] && [ "$2" -ge 1 ] ); then
					echo 'Interval required';
					exit 1;
				fi

				interval="$2";
				
				shift 2;
				continue;
			;;
			'-s'|'--skip-missing')
				flags+='-s ';

				shift;
				continue;
			;;
			'')
				shift;
				break;
			;;
			*)
				usage;
				exit 1;
			;;
		esac
	done

	if [ "$dump" == 1 ]; then
		getAllStats $flags;
	else
		printf 'Preparing stats for display every %s seconds...\n' "$interval";
		watch -d -n "$interval" "$0" -d $flags;
	fi
}

main $@;
