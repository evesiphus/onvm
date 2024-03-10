#!/bin/bash

# Please customize the following paths according to the configuration of your local environment.
ONVM_HOME="/home/tzhang/openNetVM"
PROJECT_HOME="/home/tzhang/onvm/"
SCRIPT_DIR="${PROJECT_HOME}/scripts"
MOONGEN_HOME="/home/tzhang/MoonGen"
PORT0=0
PORT1=1

# Check if the script is executed with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run with sudo privileges. Please try again using 'sudo'."
  exit 1
fi

# Initialize a global variable outside the function
declare -g current_value=$((0x80000))

flip_bit() {
    # Store the current value to be returned
    local value_to_return=$(printf "0x%x" "$current_value")

    # Update current_value for the next call
    if (( current_value == 0xFFFFF )); then
        current_value=$((0x80000))
    else
        # Incrementally set the next bit to 1
        current_value=$((current_value | (current_value >> 1)))
    fi

    # Echo the stored value, which is the state at the function call
    echo "$value_to_return"
}

# clear the output files of the past experiments
sudo rm -f "${ONVM_HOME}/nf_out.csv"
sudo rm -f "${PROJECT_HOME}/ddio_ways.csv"

# Check if the 'msr' module is loaded
if ! lsmod | grep -q msr; then
  echo "The 'msr' module is not loaded, attempting to load it..."
  sudo modprobe msr
  echo "The 'msr' module has been loaded."
else
  echo "The 'msr' module is already loaded."
fi

sudo wrmsr 0xc8b 0x80000

sudo "${MOONGEN_HOME}/build/MoonGen" "${SCRIPT_DIR}"/random_size_mg.lua  "${PORT0}" "${PORT1}" -t "ndpi_stats" &

end=$((SECONDS+20000))

sleep 15

# Start collect_rdmsr.sh in the background
./scripts/rd_ddio.sh &

# Save the PID of the background process
PID=$!

while [ $SECONDS -lt $end ]; do
    :
    #ddio="$(python3 scripts/ddio_ways.py)"
    flip_bit
    ddio=$(flip_bit)
    echo -e "DDIO ways: ${ddio}"
    sudo wrmsr 0xc8b "${ddio}"
    sleep 10
done

sudo kill "${PID}"
sudo wrmsr 0xc8b 0x60000
sudo killall onvm_mgr

cp "${ONVM_HOME}/nf_out.csv" .

sudo killall pcm
sudo killall pcm-memory
sudo killall pcm-pcie
sudo killall MoonGen
