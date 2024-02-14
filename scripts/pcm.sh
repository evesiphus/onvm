#!/bin/bash

# Declare an array of string with the potential VNF types
declare -a VNFs=( "firewall" "ndpi_stats" "nf_router" "payload_scan" "bridge" "l2fwd" "l3fwd" )

# Iterate over the VNF array using for loop
for val in ${VNFs[@]}; do
   echo -e "VNF: " "${val}"
   if [[ -z $(pidof ${val}) ]]
   then
        echo -e "Skip non-existing VNF ${val}"
   else
	core=$(ps -mo psr $(pidof ${val}) | tail -n 1)
        echo -e "VNF ${val} runs on Core${core}"
	sudo /home/tzhang/pcm/build/bin/pcm -silent -nsys -yc ${core} -csv="${val}-pcm.csv" &
   fi
done

sudo /home/tzhang/pcm/build/bin/pcm-pcie -e -csv="pcm-pcie.csv" &
sudo /home/tzhang/pcm/build/bin/pcm-memory -csv="pcm-memory.csv" &
