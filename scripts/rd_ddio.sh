#!/bin/bash

# Specify the output file
output_file="ddio_ways.csv"

touch "${output_file}"

# Loop indefinitely
while true; do
    # Run the command and store its output
    output=$(sudo rdmsr 0xc8b)

    # Append the output to the file, with a new line
    echo "${output}" >> "$output_file"

    # Wait for a second before the next iteration
    sleep 1
done

