import argparse
import re
from typing import List, Any
from decimal import Decimal

import numpy as np
import os.path
from enum import Enum

parser = argparse.ArgumentParser(description='Reads a state/bioenergy list and returns the most ideal based on fitness')

parser.add_argument('-t', '--ticks', type=int, nargs='?', default=8, help='The number of simulation ticks that represent 24 hours (integer).')
parser.add_argument('-a', '--actions', type=int, nargs='?', default=5, help='The total number of possible states/actions (integer).')
parser.add_argument('-s', '--states', type=str, help="File containing a list of ideal states")
parser.add_argument('-w', '--weighting', metavar='w', action='append', help="List the importance of Bioenergy, then State Ideal-ness by percent \n \t Ex: -w 75 -w 25 ")
parser.add_argument('-f', '--file', type=str, help="File containing data to analyze")

args = parser.parse_args()

# Dictionaries for parsed data: agent_num: value
agent_fcm = {}
agent_state = {}
agent_bioenergy = {}
agent_state_score = {}

# Dictionaries of FCM Data by year
year_agent_bioenergy = {}
year_agent_fcm = {}
year_agent_state_score = {}

# Score Tracking
best_agent = -1
best_score = -1
best_year = -1
best_fcm = -1

# Score Calc
max_bio = 0
max_score = 0

# open files
state_file = open(args.file, 'r')
state_comparison = [0, 2, 0, 4, 2]

# States from
states = [(142, [0, 2, 0, 4, 2]),
          (182, [0, 2, 4, 2, 0]),
          (197, [0, 3, 0, 2, 2]),
          (244, [0, 2, 4, 2, 0])]

#Data read flow control variables
# Track day info
last_day_read = -1
read_year_flag = False

def state_score(state_comp, actual):
    i = 0
    match_score = 0
    while i < len(state_comp):
        if state_comp[i] != actual[i]:
            match_score = match_score + 1
        i = i + 1
    return match_score

def process_fcm_line(data):
    repaired_data = data.replace("\\t", "\t") # fix netlogo error that doesn't print tab characters
    reg_split = re.findall("(\d{3}\t)(\[\[.*?\]\])", repaired_data)

    i = 0
    while i < len(reg_split):
        numpy_text_array: List[str] = re.findall("(\[?[^\[]+?\])", reg_split[i][1])
        j = 0
        matrix_string = ''
        while j < len(numpy_text_array):
            mat_row = numpy_text_array[j].replace("[", "").replace("]", "")
            matrix_string = matrix_string + mat_row
            if j < len(numpy_text_array) - 1:
                matrix_string = matrix_string + "; "

            j += 1
        numpy_matrix = np.matrix(matrix_string)
        agent_num = int(reg_split[i][0])
        agent_fcm[agent_num] = numpy_matrix
        i += 1


def process_state_lines(data):
    global read_year_flag
    global last_day_read
    global max_bio
    global max_score
    global states
    global state_comparison

    if len(data) > 5:
        if last_day_read == 258:
            # Save highest FCM data
            read_year_flag = True
            state_bio_line = re.findall("(\d{3}) (\{\{matrix:  \[ \[ )(.{9}) (\] \]\}\} )(-?\d*.\d*)", data)
            agent_num = int(state_bio_line[0][0])
            agent_states = list(map(int, state_bio_line[0][2].split(" ")))
            agent_score = state_score(state_comparison, agent_states)
            agent_state_score[agent_num] = agent_score
            bioenergy = Decimal(state_bio_line[0][4])

            if agent_score > max_score:
                max_score = agent_score
            if bioenergy > max_bio:
                max_bio = bioenergy

            # Save bioenergy and agent num to dictionary
            agent_bioenergy[agent_num] = bioenergy

    else: # Year and Day Data
        if read_year_flag: # Read the Year
            read_year_flag = False
            year = int(data)

            # Copy holding dictionaries into their year key
            year_agent_bioenergy[year] = agent_bioenergy.copy()
            year_agent_fcm[year] = agent_fcm.copy()
            year_agent_state_score[year] = agent_state_score.copy()

            # Clear holding dictionaries
            agent_bioenergy.clear()
            agent_fcm.clear()
            agent_state_score.clear()
        else: # Update the last day read for checks
            k = 0

            while k < len(states):
                if states[k][0] > last_day_read:
                    state_comparison = states[k][1]
                k = k + 1

            last_day_read = int(data)

def state_list_from_file():
    line = state_file.readline() # initial reading of file
    while line != "":
        line = state_file.readline()
        if line == '':
            break
        if line[0] != '#':
            if len(line) > 100: # fcm data line
                process_fcm_line(line)
            else:
                process_state_lines(line)

def find_best():
    global max_bio
    global max_score

    global best_fcm
    global best_year
    global best_agent
    global best_score

    for year in year_agent_bioenergy:
        for agent_num in year_agent_bioenergy[year]:
            score = (max((float(year_agent_bioenergy[year][agent_num]) / float(max_bio)), 0) * 0.5) + ((float(year_agent_state_score[year][agent_num]) / float(max_score)) * float(0.5))
            if score > best_score:
                best_score = score
                best_year = year
                best_agent = agent_num
                best_fcm = year_agent_fcm[year][agent_num]

def main():
    state_list_from_file()
    find_best()

    print("-- FCM --")
    print(best_fcm)
    print()
    print("-- Score --")
    print(best_score)
    print()
    print("-- Agent --")
    print(best_agent)
    print()
    print("-- Year --")
    print(best_year)

if __name__ == '__main__':
    main()

