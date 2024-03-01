#!/bin/bash

# Please customize the following paths and variables according to your local configuration.
# First, the installation directory of OpenNetMV (ONVM).
ONVM_HOME="/home/tzhang/openNetVM"

# Second, the directory of the current project.
PROJECT_HOME="/home/tzhang/onvm"
SCRIPT_DIR="${PROJECT_HOME}/scripts"

# Third, the installation directory of MoonGen.
MOONGEN_HOME="/home/tzhang/MoonGen"

# Fourth, the default TX/RX port for MoonGen.
PORT0=0
PORT1=1

# Lastly, the intended network service configuration. Default: Linear SFC.
CONFIG="linear"

# Check if the script is executed with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run with sudo privileges. Please try again using 'sudo'."
  exit 1
fi

# (Optinal) Specify the intended SFC configuration from the command line.
if [ $# -gt 0 ]; then
    CONFIG=$1
fi

# clear the ONVM output files of the past experiments.
sudo rm -f "${ONVM_HOME}/nf_out.csv"

# Ensure the 'msr' module is loaded for Intel PCM to be functional
if ! lsmod | grep -q msr; then
  echo "The 'msr' module is not loaded, attempting to load it..."
  sudo modprobe msr
  echo "The 'msr' module has been loaded."
else
  echo "The 'msr' module is already loaded."
fi

# Launch MoonGen for traffic generation/measurement. The SFC will be invoked during the process.
sudo "${MOONGEN_HOME}/build/MoonGen" "${SCRIPT_DIR}"/random_rate.lua  "${PORT0}" "${PORT1}" -t "${CONFIG}" &

# Set up the duration of the experiment.
end=$((SECONDS+10000))

# Run the experiment for the specified duration.
while [ $SECONDS -lt $end ]; do
    # Do what you want.
    :
done

# Clear up and gather the data.
sudo killall onvm_mgr

cp "${ONVM_HOME}/nf_out.csv" .

sudo killall -9 pcm
sudo killall -9 pcm-memory
sudo killall -9 pcm-pcie
sudo killall MoonGen
