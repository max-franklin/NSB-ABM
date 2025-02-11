import json
import math
import os
from turtledemo.clock import setup
from typing import Dict, List

import numpy as np
import pandas as pd
import pynetlogo
from pynetlogo import NetLogoLink

from Reporting.CaribouReporter import CaribouReporter
from Simulation import config
from Simulation.agents.CaribouAgent import CaribouAgent
from Simulation.agents.DictonaryPatch import DictionaryPatch
import Simulation.config
from Simulation.config import CONFIG
from Simulation.fcms.CaribouFCM import CaribouFCM
from Simulation.fcms.FCMEvolution import FCMEvolution



class SimController:

    def __init__(self, dataframe_dictionary: Dict[str, object]):
        """
        :param dataframe_dictionary: Dictionary containing initial data for bioenergy and other configurations.
        :type dataframe_dictionary: Dict[str, object]
        """
        config.load_config()
        self.dataframe_dictionary = dataframe_dictionary
        self.energy_data = dataframe_dictionary['energy']
        self.state_data = dataframe_dictionary['state']

        self.netlogo = None

        self.caribou_agents : list[CaribouAgent] = None
        self.caribou_reporter : CaribouReporter = None

        self.__current_year : int = 0
        self.__current_day : int = 0



    def setup_netlogo(self):
        """
        Prepares the NetLogo environment by setting up the NetLogo model.

        :return: None
        """
        absolute_model_path = os.path.abspath(os.path.join(os.getcwd(), CONFIG['MODEL_PATH']))

        java_home = os.environ.get('JAVA_HOME')
        if java_home:
            jvm_path = os.path.join(java_home, 'bin', 'server', 'jvm.dll')
        else:
            raise Exception('JAVA_HOME is not set in system environment variables.')

        self.netlogo = pynetlogo.NetLogoLink(gui=True, jvmargs=["-Xmx20G"])
        self.netlogo.load_model(absolute_model_path)

        self.netlogo.command('set scenario "caribou-evolution"')
        self.netlogo.command("setup")


    def simulation_loop(self):
        """
        Simulates a loop where the NetLogo simulation is advanced, bio-energy values of 'caribou' are recorded, calculated, and logged.
        The simulation runs until the year 1000 is reached.

        :return: None
        """
        last_year = 0
        tick = 0

        while True:
            # In theory this will always be synchronized with actual ticks since go is a single tick
            tick += 1
            self.netlogo.command("go")

            # TODO: Split Logging into its own Class set

            if tick % int(CONFIG["MODEL_DAYS_PER_TICK"]) == 0:
                self.__current_day = math.floor(tick / int(CONFIG["MODEL_DAYS_PER_TICK"]))
                self.on_day_change()

            # Get the current year
            current_year = int(self.netlogo.report("year"))

            if current_year > last_year:
                last_year = current_year
                self.__current_year = current_year
                self.on_year_change()

            #
            # # Monitor the bio-energy of caribou
            # bio_energy_values = self.netlogo.report("map [c -> [bioenergy] of c] sort caribou")
            #
            # # Calculate mean, median, max, and min
            # mean_bio_energy = pd.Series(bio_energy_values).mean()
            # median_bio_energy = pd.Series(bio_energy_values).median()
            # max_bio_energy = pd.Series(bio_energy_values).max()
            # min_bio_energy = pd.Series(bio_energy_values).min()
            #
            # # Log data
            # tick = self.netlogo.report("ticks")
            # new_row = pd.DataFrame(
            #     {'tick': [tick], 'mean_bio_energy': [mean_bio_energy], 'median_bio_energy': [median_bio_energy],
            #      'max_bio_energy': [max_bio_energy], 'min_bio_energy': [min_bio_energy]})
            # df = pd.concat([df, new_row], ignore_index=True)

            # If the year is a multiple of 20, update the data
            if current_year >= 1000:
                print("Simulation ended at year 1000.")
                break

            self.go_agents()


            # time.sleep(1)  # Slow down the simulation for smoother updates

    def setup_agents(self):
        """
        Sets up Caribou agents in the simulation.

        This method retrieves the identifiers ('who' values) and bioenergy levels of caribou from the NetLogo model and
        creates a list of CaribouAgent instances based on these values.

        :return: None
        """
        who_values = self.netlogo.report("[who] of caribou")
        bioenergy_list =  self.netlogo.report("[energy] of caribou")

        # Create a list representing the Netlogo Caribou Agents
        # TODO Refactor self in agents
        self.caribou_agents = [CaribouAgent(who, self, self.netlogo) for who in who_values]
        self.caribou_reporter = CaribouReporter(self.netlogo, self.caribou_agents, self.dataframe_dictionary)


        # TODO: Bind this to a simulation configuration
        # Set random fcm
        for caribou in self.caribou_agents:
            caribou.set_random_fcm()


    def load_patches(self):
        """
        Loads all patch variables into a nested dictionary where each patch is represented by
        its coordinates (pxcor, pycor), and its associated variables are stored as key-value pairs.

        Returns:
            dict: A nested dictionary where the keys are (pxcor, pycor) tuples, and the values are
                  dictionaries of patch variables.
        """
        # Get a list of all patch variables
        patch_variables = self.netlogo.report("patches-own")

        # Initialize the dictionary to store patch data
        patches_dict = {}

        # Retrieve data for all patches
        all_patches_data = self.netlogo.report(f"[list pxcor pycor {patch_variables}] of patches")

        # Populate the dictionary
        for patch_data in all_patches_data:
            pxcor, pycor, *variables = patch_data
            variable_dict = dict(zip(patch_variables, variables))
            patches_dict[(pxcor, pycor)] = DictionaryPatch(pxcor, pycor, variable_dict)

        return patches_dict

#TODO Break off commands into a separate class or string container
    def go_agents(self):
        caribou_perceptions = self.netlogo.report(f"[(list who caribou-high-food-distance energy caribou-local-utility caribou-disturbance-distance caribou-hunter-distance)] of caribou")

        caribou_by_who = {entry[0]: entry[1:] for entry in caribou_perceptions}

        for caribou in self.caribou_agents:
            perceptions = caribou_by_who[caribou.who]
            caribou.set_perceptions(*perceptions)
            caribou.process_fcm()


        who_values = [int(caribou.who) for caribou in self.caribou_agents]
        external_state_values = [int(caribou.get_action_state())for caribou in self.caribou_agents]

        who_values_str = who_values.__str__().replace(',','')
        external_state_values_str = external_state_values.__str__().replace(',','')

        # Construct the NetLogo command to batch update
        command = f"""
        (foreach {who_values_str} {external_state_values_str} [
            [the_who the_state] ->
                ask caribou with [who = the_who] [
                    set caribou-external-state the_state
                ]
        ])
        """

        # Execute the command
        self.netlogo.command(command)


    def on_year_change(self):
        self.evolve_caribou()

    #TODO Move this to a more appropriate caribou class
    def evolve_caribou(self):
        """
        Evolves the population of caribou agents by performing crossover and mutation operations on the fuzzy cognitive maps (FCM) associated with selected parent agents.
        The selection of parents is based on their energy levels, with the top two caribou being chosen.

        :return: None
        """
        caribou_data = self.netlogo.report("[(list who bioenergy-success)] of caribou")
        sorted_energy = sorted(caribou_data, key=lambda c: c[1], reverse=True)
        caribou_scores = [(c.who, c.action_score) for c in self.caribou_agents]

        merged_caribou = self.merge_and_average(sorted_energy, caribou_scores)
        sorted_caribou = sorted(merged_caribou, key=lambda c: c[1], reverse=True)


        sorted_who = [item[0] for item in sorted_caribou]

        parent_agent_who = self.stochastic_selection(sorted_who, num_selected=2)

        parent_caribou = [cari for cari in self.caribou_agents if cari.who in parent_agent_who]

        parent_a = parent_caribou[0]
        parent_b = parent_caribou[1]

        FCMEvolution.cross_caribou_fcms(parent_a.fcm, parent_b.fcm, crossover_rate=.5)

        new_fcm : CaribouFCM = parent_a.fcm

        for caribou in self.caribou_agents:
            caribou.fcm = new_fcm
            FCMEvolution.mutate_caribou_fcm(caribou.fcm)

    #TODO Move this to a more appropriate stats class
    @staticmethod
    def merge_and_average(list_a, list_b):
        # Convert list_b to a dictionary {key_b: x_b}
        dict_b = {b_key: b_x for (b_x, b_key) in list_b}

        result = []
        # Traverse list_a
        for (x_a, key_a) in list_a:
            if key_a in dict_b:
                x_b = dict_b[key_a]
                avg = (x_a + x_b) / 2
                result.append((avg, key_a))

        return result


    #TODO Move this to a more appropriate stats class
    @staticmethod
    def stochastic_selection(sorted_data, num_selected=4):
        """
        Stochastically select 'num_selected' agents from a sorted list.

        Args:
            sorted_data (list): List of [who, value] sorted from highest to lowest.
            num_selected (int): Number of agents to select.

        Returns:
            list: List of 'who' values of the selected agents.
        """
        # Extract 'who' values and their rank-based weights
        who_values = sorted_data
        ranks = np.arange(1, len(who_values) + 1)[::-1]  # Highest rank first

        # Assign probabilities inversely proportional to rank (higher = more likely)
        probabilities = ranks / ranks.sum()

        # Stochastically select agents based on their rank probabilities
        selected_indices = np.random.choice(len(who_values), size=num_selected, p=probabilities, replace=False)
        selected_who = [who_values[i] for i in selected_indices]

        return selected_who


    def setup(self):
        self.setup_netlogo()
        self.setup_agents()
        #self.load_patches()


    def run(self):
        self.simulation_loop()

    def get_netlogo_instance(self) -> NetLogoLink:
        return self.netlogo

    def on_day_change(self):
        self.caribou_reporter.add_state_data(self.__current_day)