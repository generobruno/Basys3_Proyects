class Utils(object):
    def __init__(self):
        pass
    
    @staticmethod
    def int2bs(s, n):
        """ Converts an integer string to a 2s complement binary string.

        Args:
            s : Integer string to convet to 2s complement binary
            n : Length of outputted binary string
        """
        x = int(s)                              # Convert str to int, store in x
        if x >= 0:                              # If positive, convert to bin and strip "0b"
            ret = str(bin(x))[2:]
            return ("0"*(n-len(ret)) + ret)     # Pad with 0s 
        else:                                   
            ret = 2**n - abs(x)                 # If negative, convert to 2s complement integer
            return bin(ret)[2:]                 # convert to bin and strip "0b"
        
    @staticmethod
    def bs2hex(v):
        """ Converts a binary string to hexadecimal

        Args:
            v : Binary string to convert to hex
        """
        return(hex(int(v,2))[2:])