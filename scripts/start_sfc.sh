#!/bin/bash

CURR_DIR=$(pwd)
ONVM_DIR="/home/tzhang/openNetVM"
CONFIG="linear"

cd "${ONVM_DIR}/examples"

# Check if a new configuration is specified
if [ -n "$1" ]; then
  CONFIG="$1"
else
  # If not, use the default value for CONFIG
  CONFIG="linear"
fi

python3 run_group.py "${CURR_DIR}/scripts/${CONFIG}.json"

