################################################################
#   filename: pglCalibration.py
#    purpose: Handles calibration of display
#         by: JLG
#       date: September 18, 2025
################################################################

#############
# Import modules
#############
import numpy as np
from ._pglComm import pglSerial

#############
# Parameter class
#############
class pglCalibration():
    '''
    Class representing a display calibration.
    '''
    def __init__(self, description=""):
        '''
        Initialize the calibration.
        '''
        self.description = description

        
    def __del__(self):
        '''
        Destructor for the calibration class.
        '''
        pass
    
    def measure(self):
        '''
        Measure the display characteristics.
        '''
        pass

    def load(self, filepath):
        '''
        Load calibration data from a file.
        '''
        pass

    def save(self, filepath):
        '''
        Save calibration data to a file.
        '''
        pass

    def apply(self, value):
        '''
        Apply the calibration to a given value.
        '''
        pass
    

class pglCalibrationMinolta(pglCalibration):
    '''
    Class representing a Minolta calibration.
    '''
    def __init__(self, description="Minolta CS-100A"):
        '''
        Initialize the Minolta calibration.
        '''
        super().__init__(description)
        
        # init serial port
        self.serial = pglSerial()
    
    def measure(self):
        '''
        Measure the display characteristics using Minolta device.
        '''
        self.serial.write("MES\r\n")
        r = self.serial.read()
        print("Measurement result:", r)
        pass

    def load(self, filepath):
        '''
        Load Minolta calibration data from a file.
        '''
        pass

    def save(self, filepath):
        '''
        Save Minolta calibration data to a file.
        '''
        pass

    def apply(self, value):
        '''
        Apply the Minolta calibration to a given value.
        '''
        pass
    
