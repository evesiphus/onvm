import random 

def generate_ddio_allocation(current_ddio_hex):
    # Convert hex to binary, ensuring it's padded to represent 20 bits
    current_ddio_bin = bin(int(current_ddio_hex, 16))[2:].zfill(20)

    # Count occupied and unoccupied bits
    occupied = current_ddio_bin.count('1')
    unoccupied = 20 - occupied

    # Randomly decide to increase (by b) or decrease (by a) the allocation
    a = random.randint(0, occupied) # Possible decrease
    b = random.randint(0, unoccupied) # Possible increase

    # Generating new binary DDIO configuration with left-to-right allocation or deallocation
    new_ddio_bin = list(current_ddio_bin)
    if b > 0 and occupied < 20: # If there's room to increase
        added = 0
        for i in range(20):
            if new_ddio_bin[i] == '0' and added < b:
                new_ddio_bin[i] = '1'
                added += 1
            if added >= b:
                break
    elif a > 0: # If we need to decrease
        removed = 0
        for i in range(19, -1, -1):
            if new_ddio_bin[i] == '1' and removed < a:
                new_ddio_bin[i] = '0'
                removed += 1
            if removed >= a:
                break

    # Convert back to hex
    new_ddio_hex = hex(int(''.join(new_ddio_bin), 2)).upper().replace('0X', '0x').zfill(5)

    return new_ddio_hex

# Example usage
current_ddio_hex = "60000"
new_ddio_hex = generate_ddio_allocation(current_ddio_hex)
print(new_ddio_hex)
#print(f"Current DDIO setting: {current_ddio_hex} -> New DDIO setting: {new_ddio_hex}")
