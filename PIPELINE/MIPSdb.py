import tkinter as tk
import customtkinter as ctk
from tkinter import filedialog, messagebox
import subprocess, os, serial, struct

current_file_path = ""
current_out_file = ""

class IDE(ctk.CTk):
    
    # Initialize serial port
    try:
        ser = serial.Serial('/dev/ttyUSB1', 
                            baudrate=19200, 
                            bytesize=serial.EIGHTBITS, 
                            parity=serial.PARITY_NONE,
                            stopbits=serial.STOPBITS_ONE,
                            timeout=1)
    except serial.SerialException:
        messagebox.showwarning("Serial Error", 
                               "Serial Port Not Found.\nYou need to connect it to run a program")
        ser = None
    
    def __init__(self):
        super().__init__()
        
        self.title("MIPSdb - Debugger")
        try: # Icon
            icon = tk.PhotoImage(file='./resources/icon.png')
            self.wm_iconphoto(True, icon)
        except Exception as e:
            print("Error loading icon:", e)
        ctk.set_appearance_mode("Dark")
        ctk.set_default_color_theme("dark-blue")
        self.geometry("800x600")
        
        # File management
        self.files_frame = ctk.CTkFrame(self, height=5)
        self.files_frame.pack(side="top", fill="x", pady=2, padx=2)
        
        self.file_opt = ctk.CTkOptionMenu(self.files_frame,
                                          values=["Save", "Load"], 
                                          command=self.manage_file, 
                                          height=5,
                                          width=100)
        self.file_opt.pack(side='left')
        
        self.filename_text = ctk.CTkTextbox(self.files_frame, height=1, border_spacing=1, corner_radius=2, wrap="none")
        self.filename_text.pack(side="left", fill="x", padx=5)
        
        self.run_opt = ctk.CTkOptionMenu(self.files_frame,
                                    values=["Run", "Debug"], 
                                    command=self.manage_db, 
                                    height=5,
                                    width=100)
        self.run_opt.pack(side='right')

        # Text Editor
        self.text_editor = ctk.CTkTextbox(self)
        self.text_editor.pack(side="top", fill="both", expand=True, padx=3, pady=3)

        # Buttons
        self.buttons_frame = ctk.CTkFrame(self)
        self.buttons_frame.pack(side="top", fill="x", pady=2, padx=2)

        self.compile_button = ctk.CTkButton(self.buttons_frame, text="Compile", 
                                            command=self.compile_file)
        self.compile_button.pack(side='left', pady=3, padx=1)

        self.write_button = ctk.CTkButton(self.buttons_frame, text="Write", 
                                          command=self.write_code)
        self.write_button.pack(side='left', pady=3, padx=1)

        self.run_button = ctk.CTkButton(self.buttons_frame, text="Run", 
                                        command=self.run_code)
        self.run_button.pack(side='left', pady=3, padx=1)

        # Mem-Reg-PC Frame
        self.bottom_frame = ctk.CTkFrame(self, height=80)
        self.bottom_frame.pack(side="bottom", fill="both", expand=True)

        # Registers Frame
        self.registers_frame = ctk.CTkFrame(self.bottom_frame)
        self.registers_frame.pack(side="left", fill="both", expand=True)

        self.registers_label = ctk.CTkLabel(self.registers_frame, text="Registers")
        self.registers_label.pack(side='top', pady=5)

        self.registers_text = ctk.CTkTextbox(self.registers_frame, height=3, width=30, wrap="none")
        self.registers_text.pack(side="left", fill="both", expand=True, pady=5)
        self.registers_text.configure(state=ctk.DISABLED)

        # Memory Frame
        self.memory_frame = ctk.CTkFrame(self.bottom_frame)
        self.memory_frame.pack(side="left", fill="both", expand=True)

        self.memory_label = ctk.CTkLabel(self.memory_frame, text="Memory")
        self.memory_label.pack(side='top', pady=5)

        self.memory_text = ctk.CTkTextbox(self.memory_frame, height=3, width=30, wrap="none")
        self.memory_text.pack(side="left", fill="both", expand=True, pady=5)
        self.memory_text.configure(state=ctk.DISABLED)

        # Program Counter Frame
        self.pc_frame = ctk.CTkFrame(self.bottom_frame, width=50)
        self.pc_frame.pack(side="left", fill="both", expand=False)

        self.pc_label = ctk.CTkLabel(self.pc_frame, text="Program Counter",
                                     justify="center", padx=5)
        self.pc_label.pack(side='top', pady=5, fill="both")

        self.pc_value_label = ctk.CTkLabel(self.pc_frame, text="")
        self.pc_value_label.pack(side='top', pady=5)

        self.init_tables()

    """ manage_file
        Save or Load File depending on the option selected
    """
    def manage_file(self, option):
        global current_file_path  # Access the global variable
        if option == "Load":
            filename = filedialog.askopenfilename()
            if filename:
                current_file_path = filename
                name = os.path.basename(filename)  # Get only the filename
                self.filename_text.configure(state=tk.NORMAL)
                self.filename_text.delete(1.0, tk.END)
                self.filename_text.insert(tk.END, name)
                self.filename_text.configure(state=tk.DISABLED)
                with open(filename, 'r') as file:
                    self.text_editor.delete('1.0', tk.END)
                    self.text_editor.insert(tk.END, file.read())
        elif option == "Save":
            filename = filedialog.asksaveasfilename()
            if filename:
                current_file_path = filename
                name = os.path.basename(filename)  # Get only the filename
                self.filename_text.configure(state=tk.NORMAL)
                self.filename_text.delete(1.0, tk.END)
                self.filename_text.insert(tk.END, name)
                self.filename_text.configure(state=tk.DISABLED)
                with open(filename, 'w') as file:
                    file.write(self.text_editor.get("1.0", "end-1c"))

    """ compile_file
        Save the file and execute the assembler.py program to generate the .hex file
    """
    def compile_file(self):
        global current_file_path, current_out_file  # Access the global variable
        filename = self.filename_text.get("1.0", "end-1c").strip() # Get current file name
        name = os.path.splitext(os.path.basename(filename))[0]  # Get only the filename
        current_out_file = name
        if not filename:
            filename = filedialog.asksaveasfilename()
            if not filename:
                return  # User cancelled save operation
            current_file_path = filename
            name = os.path.splitext(os.path.basename(filename))[0]  # Get only the filename
            current_out_file = name
            self.filename_text.configure(state=tk.NORMAL)
            self.filename_text.delete(1.0, tk.END)
            self.filename_text.insert(tk.END, filename)
            self.filename_text.configure(state=tk.DISABLED)
        
        try:
            # Execute assembler.py with appropriate arguments
            subprocess.run("python ASSEMBLER/assembler.py -i {} -o {}.hex".format(current_file_path, name), shell=True, check=True)
            messagebox.showinfo("Compilation Successful", "The file has been compiled successfully.")
        except subprocess.CalledProcessError:
            messagebox.showerror("Compilation Error", "An error occurred during compilation. Please check the assembler script.")

    """ manage_db
        Change Run/Step Button according to the option
    """
    def manage_db(self, option):
        if option == "Run":
            self.run_button.configure(text="Run", command=self.run_code)
            self.hide_debug_buttons()  # Hide debug buttons if "Run" option is selected
        elif option == "Debug":
            self.run_button.configure(text="Step", command=self.debug_code)
            self.show_debug_buttons()  # Show debug buttons if "Debug" option is selected

    """ show_debug_buttons
        Display debug buttons in debug mode
    """
    def show_debug_buttons(self):
        if not hasattr(self, "start_button"):
            self.start_button = ctk.CTkButton(self.buttons_frame, text="Start", 
                                              command=self.start_debug, width=50, fg_color="forest green")
            self.start_button.pack(side='right', pady=3, padx=1)
        if not hasattr(self, "stop_button"):
            self.stop_button = ctk.CTkButton(self.buttons_frame, text="Stop", 
                                             command=self.stop_debug, width=50, fg_color="firebrick3")
            self.stop_button.pack(side='right', pady=3, padx=1)

    """ hide_debug_buttons
        Hide debug buttons in run mode
    """
    def hide_debug_buttons(self):
        if hasattr(self, "start_button"):
            self.start_button.pack_forget()
            del self.start_button
        if hasattr(self, "stop_button"):
            self.stop_button.pack_forget()
            del self.stop_button

    """ get_prog_size
        Count the number of lines in the compiled file
    """
    def get_prog_size(self):
        try:
            with open(current_out_file + ".hex", 'r') as file:
                lines = file.readlines()
                return len(lines)
        except FileNotFoundError:
            messagebox.showerror("File Not Found", "Compiled .hex file not found.")
            return 0

    """ write_code
        Send .hex File to the UART to write the instructions into the instruction memory
    """
    def write_code(self):
        if self.ser:
            print("Sending code through UART...")
            # Get Program Size (Number of lines)
            prog_sz = self.get_prog_size()
            #print(prog_sz)
            #print(format(prog_sz, '02X'))
            
            # Try to write the code to the board
            try: #TODO REVISAR
                # Send START Code #TODO -> Creo que ya no es necesario ahora
                self.ser.write(bytes.fromhex('07'))
                
                # Send LOAD_PROG_SIZE Code and Send Program Size
                self.ser.write(bytes.fromhex('FE'))
                self.ser.write(bytes.fromhex(format(prog_sz, '02X')))  
                
                # Send LOAD_PROG Code and Write Program Line by Line (byte by byte)
                self.ser.write(bytes.fromhex('FD'))
                with open(current_out_file + ".hex", 'r') as file:
                    for line in file:
                        hex_line = format(int(line.strip(), 2), '08X')  # Convert binary line to 8-byte hexadecimal
                        #print(f'hex_line: {hex_line}')
                        for i in range(len(hex_line) - 2, -1, -2): # TODO Revisar Send from right to left
                            byte = hex_line[i:i+2]
                            #print(f'bye: {byte}')
                            self.ser.write(bytes.fromhex(byte))
                            
                print("Code Written to board!")
                            
            except Exception as e:
                messagebox.showwarning("Write Error", f"Could not write code.\n{e}")
        
        else:
            messagebox.showwarning("Serial Error", "Serial Port Not Found.\nYou need to connect it to run a program")

    """ parse_and_update_data
        Parse the received data and update tables with the extracted values
    """
    def parse_and_update_data(self, read_data):
        registers_values = {}
        memory_values = {}
        program_counter_value = ""
        
        if len(read_data) >= 260:  # Ensure there are enough bytes to unpack
            for i in range(0, 128, 4):  # Registers data
                reg_value = struct.unpack('<I', read_data[i:i+4])[0]  # Unpack 4 bytes as an unsigned integer
                registers_values[f"Reg {i//4}"] = f"{reg_value:#010x}"  # Format the register value as hexadecimal
            for i in range(128, 256, 4):  # Memory data
                mem_value = struct.unpack('<I', read_data[i:i+4])[0]  # Unpack 4 bytes as an unsigned integer
                memory_values[f"Mem {i//4-32}"] = f"{mem_value:#010x}"  # Format the memory value as hexadecimal
            program_counter_value = struct.unpack('<I', read_data[256:260])[0]  # Program Counter
            program_counter_value = f"{program_counter_value:#010x}"  # Format the PC value as hexadecimal
            
            # Update tables with new values
            self.update_table(self.registers_text, registers_values)
            self.update_table(self.memory_text, memory_values)
            self.pc_value_label.configure(text=f"Program Counter: {program_counter_value}")
        else:
            print("Received data does not contain enough bytes to unpack.")

    """ run_code
        Send "run" code to the UART to execute the code, and wait for "halt" code
    """
    def run_code(self):
        if self.ser: #TODO Revisar - Desactivar run_button y write_button hasta que llegue halt
            # Replace this with actual code to send code through UART and receive the result
            print("Running Program...")
            # Send NO_DEBUG Code
            self.ser.write(bytes.fromhex('F0'))
            
            # Wait for HALT Code and read info
            print("Waiting for halt code...")
            read_data = self.ser.read(260) # Read mem/regs/pc states
            
            # TODO Ver:
            # Parse the received data and update tables
            self.parse_and_update_data(read_data)
        else:
            messagebox.showwarning("Serial Error", "Serial Port Not Found.\nYou need to connect it to run a program")

    """ start_debug
        Send DEBUG code to start debugging session
    """
    def start_debug(self):
        if self.ser: # TODO Revisar -> deshabilitar start y write button
            # Send DEBUG Code
            print("Starting debug session...")
            self.ser.write(bytes.fromhex('FC'))
        else:
            messagebox.showwarning("Serial Error", "Serial Port Not Found.\nYou need to connect it to run a program")

    """ stop_debug
        Send RESTART code to stop debugging session
    """
    def stop_debug(self):
        if self.ser: #TODO REVISAR
            # Send RESTART Code
            print("Restarting...")
            self.ser.write(bytes.fromhex(''))
        else:
            messagebox.showwarning("Serial Error", "Serial Port Not Found.\nYou need to connect it to run a program")

    """ debug_code
        Send "step" code to the UART to step to the next instruction.
    """
    def debug_code(self):
        if self.ser: #TODO REVISAR
            print("Step Instruction...")
            # Send NEXT Code
            self.ser.write(bytes.fromhex('01'))
            
            # Read Data
            read_data = self.ser.read(260) # Read mem/regs/pc states
            
            # TODO Ver:
            # Parse the received data and update tables
            self.parse_and_update_data(read_data)
        else:
            messagebox.showwarning("Serial Error", "Serial Port Not Found.\nYou need to connect it to run a program")
    
    """ update_table
        Updates specfici table with new values
    """
    def update_table(self, text_widget, values): #TODO Revisar
        text_widget.configure(state=ctk.NORMAL)
        text_widget.delete('1.0', ctk.END)
        for name, value in values.items():
            try:
                dec_value = int(value, 16)  # Convert hexadecimal value to decimal
                text_widget.insert(ctk.END, f"{name} :\t\t{value} \t (d {dec_value})\n")
            except ValueError:
                text_widget.insert(ctk.END, f"{name} :\t\t{value}\n")  # If value is not a valid hexadecimal, display it as is
        text_widget.configure(state=ctk.DISABLED)

    """ update_register_memory
        Update all tables
    """
    def init_tables(self): #TODO Revisar -> Leer UART con toda la info (260 bytes -> 32*2 (mem_reg) + 1 (pc))
        # Placeholder for updating registers and memory values periodically
        registers_values = {
            f"Reg {i}": f"Value{i}" for i in range(32)
        }
        memory_values = {
            f"Mem {i}": f"Value{i}" for i in range(32)
        }
        self.update_table(self.registers_text, registers_values)
        self.update_table(self.memory_text, memory_values)
        self.pc_value_label.configure(text="0x00")

'''
                            MAIN PROGRAM
'''
if __name__ == "__main__":
    app = IDE()
    app.mainloop()
