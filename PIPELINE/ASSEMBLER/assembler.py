# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
# MIPS Assembly to Hex Converter. 													 		     |
# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+	 |

import sys
import binascii

from utils.parser import InstructionParser

class Assembler(object):
    def __init__(self, infilenames, outfilename):
        self.infilenames = infilenames
        self.outfilename = outfilename

    def stripComments(self, line):
        if not line:
            return ''

        cleaned = line
        if line.find('#') != -1:
            cleaned = line[0:line.find('#')] # Get rid of anything after a comment.

        return cleaned

    def buildLabelsMap(self, lines):
        labelsMap = {}

        for lineNo, line in enumerate(lines):
            split = line.split(':', 1)
            if len(split) > 1:
                label = split[0]
                labelsMap[label] = lineNo

        return labelsMap

    def mergeInputFiles(self):
        outlines = []

        for filename in self.infilenames:
            with open(filename) as f:
                outlines += f.readlines()

            f.close()

        return outlines

    def AssemblyToHex(self, output_format='bin'):
        '''given an ascii assembly file , read it in line by line and convert each line of assembly to machine code
        then save that machinecode to an outputfile'''
        inlines = self.mergeInputFiles()
        outlines = []

        lines = map(lambda line: self.stripComments(line.rstrip()), inlines)  #get rid of \n whitespace at end of line
        lines = filter(lambda line: line, lines)
        lines = list(lines)

        labelsMap = self.buildLabelsMap(lines)
        parser = InstructionParser(labelsMap=labelsMap)

        for line in lines:
            # Convert line to binary machine code
            binary_machine_code = parser.convert(line, format='binary')
            if output_format == 'bin':
                # Append binary machine code directly to outlines
                outlines.append(binary_machine_code)
            elif output_format == 'hex':
                # Convert binary machine code to hexadecimal
                hexadecimal_machine_code = binascii.hexlify(binary_machine_code.encode()).decode()
                outlines.append(hexadecimal_machine_code)


        with open(self.outfilename,'w') as of:
            for outline in outlines:
                of.write(outline)
                of.write("\n")
        of.close()

if __name__ == "__main__":
	print(f'Number of arguments: {len(sys.argv)} arguments.')
	print(f'Argument List: {str(sys.argv)}')

	if (len(sys.argv) < 4) or ('-i' not in sys.argv) or ('-o' not in sys.argv):
		print('Usage: python Assembler.py -i <inputfile.asm>[ <inputfile2.asm> <inputfile3.asm> ...] -o <outputfile.hex>')
		sys.exit(2)
  
	inputfiles = sys.argv[sys.argv.index('-i') + 1: sys.argv.index('-o')]
	outputfile = sys.argv[sys.argv.index('-o') + 1]

	assembler = Assembler(inputfiles, outputfile)
	assembler.AssemblyToHex(output_format='bin')