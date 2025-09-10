# Rudimentary "one-liner" for grabbing current temperatures, fan speeds, voltages, and currents from my Dell SC200
# SCSI enclosure.
# 
# This uses a hardcoded SCSI address and makes a lot of assumptions, but I still want to save this somewhere for
# future reference, in case I want to turn it into a proper and robust monitoring script later on.
#
# Requires "sg3-utils" package to be installed.
watch -c -d -x bash -c 'dev=/dev/bsg/9:0:6:0; for type in ts coo vs cs; do printf "[%s] " "$type"; sg_ses "$dev" --index="$type",0-255; echo; done | grep -E -e "^" -e "hex:( [0-9a-f]{2})+|[0-9]+ C|[0-9]+ rpm" --color=always'
