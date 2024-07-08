from termcolor import colored

#Dictionaries used for opcodes
opcodesDictionary = {
    "load": "00",
    "add": "01",
    "sub": "10",
    "jnz": "11"
}
#Dictionary used for registers
registersDictionary = {
    "r0": "00",
    "r1": "01",
    "r2": "10",
    "r3": "11"
}

# A dictionary for choosing one color for each opcode
opcodeColorDictionary = {
    "load": "cyan",
    "add": "green",
    "sub": "yellow",
    "jnz": "red"
}

def convert_assembly_to_binary(input_data):
    #asseble parameters
    label_address = {}
    output = ""
    
    #functions
    def convert_to_binary(number):
        number = max(0, min(number, 63))
        binary_string = format(number, '06b')
        return binary_string
    
    def extract_first_register(instruction):
        return registersDictionary[instruction[1]]
    
    def extract_opcode(instruction):
        opcode = instruction[0]
        #check if the first item of instruction has label too
        if ":" in opcode:
            opcode = opcode.split(':')[1]
            
        return opcode
    
    def extract_data_from_line(line):
        line = line.strip()
        if not line:
            return False

        line = line.replace(',', '')
        instruction = line.split(' ')
        
        return instruction
    
    def get_command_size(line):
        if "load" in line:
            return 2
        else:
            return 1

    def calculate_label_addresses(lines):
        current_address = 0

        for line in lines:
            if ":" in line:
                new_label_key=line.split(':')[0].strip()
                label_address[new_label_key] = current_address
            current_address += get_command_size(line)
    
    #assemble starts
    lines = input_data.split('\n')
    calculate_label_addresses(lines)

    for line in lines:
        
        instruction = extract_data_from_line(line)
        
        #check if line is empty
        if not instruction:
            continue

        opcode = extract_opcode(instruction)
        
        #check opcode that is in declared in operations or not
        if opcode not in opcodesDictionary:
            continue
        
        first_register = extract_first_register(instruction)
        
        #first add opcode and first_register binary codes to output
        output += colored(opcodesDictionary[opcode], opcodeColorDictionary[opcode])
        output += colored(first_register, opcodeColorDictionary[opcode])
        

        #second add rest of the binary code depend on third item in instruction list
        restOfOutput = ""
        if opcode=="load":
            restOfOutput += "00\n"
            load_value = convert_to_binary(int(instruction[2]))
            restOfOutput += colored(load_value, "blue")
        elif opcode=="jnz":
            restOfOutput += "00\n"
            jump_address = convert_to_binary(label_address[instruction[2]])
            restOfOutput += colored(jump_address, "blue")
        else:
            restOfOutput += registersDictionary[instruction[2]]
        
        output+=colored(restOfOutput, opcodeColorDictionary[opcode])
        output += "\n"

    #end of the binary code
    output += "111111"
    return output


def giveExampleInput():
    input_data = """load r0, 8
                    load r1, 6
                    load r2, 0
                    load r3, 1
                    addLabel:add r2, r0
                    sub r1, r3
                    jnz r1, addLabel"""

    print("output:\n" + convert_assembly_to_binary(input_data))


giveExampleInput()
