import serial
import re

try:
    # Serial port configuration
    ser = serial.Serial('/dev/ttyUSB1', baudrate=19200, bytesize=serial.EIGHTBITS, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE, timeout=1)
except serial.SerialException:
    print("Error: Serial port not found or cannot be configured.")
    ser = None

# Opcode mapping
opcode_map = {
    "ADD": b'\x20',
    "SUB": b'\x22',
    "AND": b'\x24',
    "OR":  b'\x25',
    "XOR": b'\x26',
    "SRA": b'\x03',
    "SRL": b'\x02',
    "NOR": b'\x27'
}

def send_data(opcode, op1, op2):
    # Check if the opcode is valid
    if opcode.upper() in opcode_map:
        opcode_byte = opcode_map[opcode.upper()]

        # Convert operands to bytes with MSB set to 1 for signed numbers
        op1_byte = op1.to_bytes(1, byteorder='big', signed=True)
        op2_byte = op2.to_bytes(1, byteorder='big', signed=True)

        # Print data sent
        print(f"Sending: {opcode_byte + op1_byte + op2_byte}")

        if ser:
            # Send the data to the serial port in the order: opcode, op1, op2
            data_to_send = op1_byte + op2_byte + opcode_byte
            ser.write(data_to_send)

            # Wait for the response
            response = ser.read(1)  # Assuming the response is 1 byte long

            # Determine if the operation is ADD or SUB
            is_add_or_sub = opcode.upper() in ["ADD", "SUB"]

            if is_add_or_sub:
                # Print result in decimal
                response_decimal = int.from_bytes(response, byteorder='big', signed=True)
                print(f"Received: {response_decimal}")
            else:
                # Print binary response (8 bits) for other operations
                response_binary = format(int.from_bytes(response, byteorder='big', signed=True), '08b')
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
