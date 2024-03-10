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

# Test the function
for i in {1..25}; do
    flip_bit
    echo "Returned: $i $(flip_bit)"
    #flip_bit
done
