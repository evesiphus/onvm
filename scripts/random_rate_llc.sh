#!/bin/bash

# Please customize the following paths according to the configuration of your local environment.
ONVM_HOME="/home/tzhang/openNetVM"
PROJECT_HOME="/home/tzhang/onvm"
SCRIPT_DIR="${PROJECT_HOME}/scripts"
MOONGEN_HOME="/home/tzhang/MoonGen"
PORT0=0
PORT1=1
NFS=( "firewall" "ndpi_stats" "nf_router" "payload_scan" "bridge" )

# Check if the script is executed with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run with sudo privileges. Please try again using 'sudo'."
  exit 1
fi

# clear the output files of the past experiments
sudo rm -f "${ONVM_HOME}/nf_out.csv"

# Check if the 'msr' module is loaded
if ! lsmod | grep -q msr; then
  echo "The 'msr' module is not loaded, attempting to load it..."
  sudo modprobe msr
  echo "The 'msr' module has been loaded."
else
  echo "The 'msr' module is already loaded."
fi

sudo "${MOONGEN_HOME}/build/MoonGen" "${SCRIPT_DIR}"/random_rate.lua  "${PORT0}" "${PORT1}" &

end=$((SECONDS+20000))

sleep 50

while [ $SECONDS -lt $end ]; do
    # Do what you want.
    :
       FLIP=$(($(($RANDOM%10))%2))
       if [ $FLIP -eq 1 ];then
          cache=$(python3 -c "import numpy as np; print(np.random.randint(10,50))")
          sudo stress-ng --cache "${cache}" --cache-level 3 --taskset 9 --timeout 20
       fi
done

sudo killall onvm_mgr

cp "${ONVM_HOME}/nf_out.csv" .

sudo killall pcm
sudo killall pcm-memory
sudo killall pcm-pcie
sudo killall MoonGen
