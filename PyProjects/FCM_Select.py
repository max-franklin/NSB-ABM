import numpy as np
import argparse
import os.path



def is_valid_file(parser, arg):
    if not os.path.exists(arg):
        parser.error("The file %s does not exist!" % arg)
    else:
        return open(arg, 'r')  # return an open file handle

parser = argparse.ArgumentParser(description='Reads a state/bioenergy list and returns the most ideal based on fitness')

parser.add_argument('TicksInDay', metavar='t', type=int, nargs='?', default=8, help='The number of simulation ticks that represent 24 hours (integer).')
parser.add_argument('StateLength', metavar='l', type=int, nargs='?', default=5, help='The total number of possible states (integer).')
parser.add_argument('CaribouCount', metavar='c', type=int, nargs='?', default=21, help='The number of caribou agents in the simulation')
parser.add_argument('StateListFile', metavar='s', type= lambda x: is_valid_file(parser, x), help="File containing a list of ideal states")
parser.add_argument('Weighting', metavar='w', action='append', help="List the importance of Bioenergy, then State Ideal-ness by percent \n \t Ex: -w 75 -w 25 ")
parser.add_argument('AgentFile', metavar='f', type= lambda x: is_valid_file(parser, x), help="File containing data to analyze")

args = parser.parse_args()

# Preferred State/Year Data
states = []
years = []

def state_list_from_file(file_in):
    year_string = ''
    state_string = ''
    with file_in as fp:
        for line in fp:
            if (line[0:1] != "#"):
                index = 0
                while index < len(line):
                    if(line[index] != "["):
                        year_string = year_string + line[index] # get our year by looking for the opening character
                        index = index + 1
                    else:
                        state_string = line[index:len(line)] # get the array as a string
                        years.append(int(year_string))
                        year_string = ''
                        states.append(np.fromstring(state_string))
                        state_string = ''
                        index = len(line)

def caribou_data_from_file(file_in):
    year_string = ''
    state_string = ''
    with file_in as fp:
        for line in fp:
            if (line[0:1] != "#"):
                index = 0





def main():


main()