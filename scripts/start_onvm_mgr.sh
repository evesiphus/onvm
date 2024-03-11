#!/bin/bash

onvm="/home/tzhang/openNetVM"

cd "${onvm}"

./onvm/go.sh 0,1,2,3 3 0x3F0 -s stdout
