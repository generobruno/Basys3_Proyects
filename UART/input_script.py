import serial
import re

try:
    # Serial port configuration
    ser = serial.Serial('/dev/ttyUSB1', baudrate=19200, bytesize=serial.EIGHTBITS, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE)
except serial.SerialException:
    print("Error: Serial port not found or cannot be configured.")
    ser = None

# Opcode mapping
opcode_map = {
    "ADD": "00100000",
    "SUB": "00100010",
    "AND": "00100100",
    "OR":  "00100101",
    "XOR": "00100110",
    "SRA": "00000011",
    "SRL": "00000010",
    "NOR": "00100111"
}

def invert_bits(byte):
    return byte[::-1]

def send_data(opcode, op1, op2):
    # Check if the opcode is valid
    if opcode.upper() in opcode_map:
        opcode_binary = opcode_map[opcode.upper()]

        # Convert operands to 8-bit binary strings with MSB set to 1 for signed numbers
        op1_binary = format(op1 , '08b')
        op2_binary = format(op2 , '08b')

        # Set the MSB to 1 for negative values
        if op1 < 0:
            op1_binary = '1' + op1_binary[1:]
        if op2 < 0:
            op2_binary = '1' + op2_binary[1:]
        
        # Invert the bits for all bytes
        opcode_binary = invert_bits(opcode_binary)
        op1_binary = invert_bits(op1_binary)
        op2_binary = invert_bits(op2_binary)
        
        data_to_send = f"{opcode_binary}_{op1_binary}_{op2_binary}"

        # Print binary data sent
        print(f"Sending: {data_to_send}")

        if ser:
            # Send the data to the serial port
            ser.write(opcode_binary.encode())
            ser.write(op1_binary.encode())
            ser.write(op2_binary.encode())
            
            # Wait for the response
            response = ser.read(8)  # Assuming the response is 8 bits long

            # Print binary response
            response_binary = invert_bits(format(int(response.hex(), 16), '08b'))
            print(f"Received: {response_binary}")

        else:
            print("No serial port available. Printing data only.")

    else:
        print("Invalid opcode. Supported opcodes are:", list(opcode_map.keys()))

try:
    while True:
        user_input = input("Enter OPCODE OP1,OP2: ").strip()
        if user_input.lower() == "exit":
            break

        match = re.match(r'(\w+)\s+(-?\d+),(-?\d+)', user_input)
        if match:
            opcode, op1, op2 = match.groups()
            op1, op2 = int(op1), int(op2)
            send_data(opcode, op1, op2)
        else:
            print("Invalid input format. Use OPCODE OP1,OP2 format or type 'exit' to quit.")

except KeyboardInterrupt:
    print("\nUser interrupted. Exiting the loop.")

finally:
    if ser:
        ser.close()
