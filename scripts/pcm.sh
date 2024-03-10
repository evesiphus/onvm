#!/bin/bash

# The installation directory of Intel PCM.
PCM_HOME="/home/tzhang/pcm/build/bin"

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
	sudo "${PCM_HOME}/pcm" -silent -nsys -yc ${core} -csv="${val}-pcm.csv" &
   fi
done

# Locate the PIDs & Cores of the TX and RX threads of ONVM
TX="$(ps -L -o pid,tid,comm,args -p $(pidof onvm_mgr) | grep -E 'lcore-slave-1' | awk '{print $2}')"
RX="$(ps -L -o pid,tid,comm,args -p $(pidof onvm_mgr) | grep -E 'lcore-slave-2' | awk '{print $2}')"
TX_core="$(taskset -cp ${TX} | awk '{print $6}')"
RX_core="$(taskset -cp ${RX} | awk '{print $6}')"

echo -e "TX thread: ${TX} core ${TX_core}, RX thread: ${RX} core ${RX_core}."
sudo "${PCM_HOME}/pcm" -silent -nsys -yc "${TX_core}" -csv="tx-pcm.csv" &
sudo "${PCM_HOME}/pcm" -silent -nsys -yc "${RX_core}" -csv="rx-pcm.csv" &

sudo /home/tzhang/pcm/build/bin/pcm-pcie -e -csv="pcm-pcie.csv" &
sudo /home/tzhang/pcm/build/bin/pcm-memory -csv="pcm-memory.csv" &
