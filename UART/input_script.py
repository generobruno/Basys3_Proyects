import serial
import sys

# Function to configure the UART serial connection
def configure_serial_connection():
    try:
        ser = serial.Serial('/dev/ttyUSB0', baudrate = 19200, bytesize = serial.EIGHTBITS, parity = serial.PARITY_NONE, stopbits = serial.STOPBITS_ONE)  # Change 'COM1' to the appropriate port
        return ser
    except serial.SerialException:
        return None

def send_binary_data(ser, binary_data):
    # Send binary data over the serial connection
    if ser:
        ser.write(binary_data.encode())

def read_binary_response(ser):
    # Read the binary response from the serial connection (or return None if no serial port)
    if ser:
        response = ser.read(8)  # Assuming the response is 8 bits (adjust as needed)
        return response
    else:
        return None

def binary_to_ascii(binary_data):
    # Convert binary data to ASCII
    ascii_data = int(binary_data, 2) # TODO SIGNED
    return chr(ascii_data)

# Number of bits for each field
OPCODE_BITS = 8
OPERAND_BITS = 8

try:
    # Try to configure the serial connection
    serial_connection = configure_serial_connection()

    while True:
        # Get user input in the format "OPCODE OP1, OP2"
        user_input = input("Enter instruction (e.g., 'ADD 2,5'): ")

        # Validate user input format
        if ' ' not in user_input or ',' not in user_input:
            print("Invalid input format. Please use 'CODE OP1,OP2' format.")
            continue

        # Split the user input into operation code and operands
        opcode, operands = user_input.split()
        op1, op2 = map(int, operands.split(','))

        # Map operation code to the corresponding binary value
        opcode_map = {
            "ADD": "00100000",
            "SUB": "00100010",
            "AND": "00100100",
            "OR": "00100101",
            "XOR": "00100110",
            "SRA": "00000011",
            "SRL": "00000010",
            "NOR": "00100111"
        }

        if opcode not in opcode_map:
            print("Invalid operation code")
            continue

        # Convert operands to 8-bit binary representation with left-padding
        op1_binary = format(op1, f'0{OPERAND_BITS}b')
        op2_binary = format(op2, f'0{OPERAND_BITS}b')

        # Construct the 8-bit binary instruction with left-padded opcode and operands
        binary_instruction = opcode_map[opcode] + op1_binary + op2_binary

        # Send the binary instruction to the ALU and print it
        send_binary_data(serial_connection, binary_instruction)
        print("Sent instruction (Binary):", binary_instruction)

        # Read and convert the binary response to ASCII and print it
        binary_response = read_binary_response(serial_connection)
        if binary_response:
            ascii_response = binary_to_ascii(binary_response)
            print("ALU Response (Binary):", binary_response)
            print("ALU Response (ASCII):", ascii_response)
        else:
            print("No serial port detected. Cannot receive response.")

except KeyboardInterrupt:
    print("User interrupted the program.")

finally:
    if serial_connection:
        serial_connection.close()
