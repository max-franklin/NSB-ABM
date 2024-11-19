import json
import os
from turtledemo.clock import setup
from typing import Dict

import pandas as pd
import pynetlogo
from pynetlogo import NetLogoLink

from Simulation.agents.CaribouAgent import CaribouAgent
from Simulation.agents.DictonaryPatch import DictionaryPatch


class SimController:
    def __init__(self, data_dictionary: Dict[str, object]):
        """
        :param data_dictionary: Dictionary containing initial data for bioenergy and other configurations.
        :type data_dictionary: Dict[str, object]
        """
        with open('config.json', 'r') as config_file:
            config = json.load(config_file)

        self.MODEL_PATH = config['Paths']['ModelPath']
        self.NLOGO_HOME = config['Paths']['NetlogoPath']

        self.bioenergy_data = data_dictionary['bio_energy'] = None
        self.netlogo = None

        self.caribou_agents = None


    def setup_netlogo(self):
        """
        Prepares the NetLogo environment by setting up the NetLogo model.

        :return: None
        """
        absolute_model_path = os.path.abspath(os.path.join(os.getcwd(), self.MODEL_PATH))

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
        while True:
            self.netlogo.command("go")

            # Get the current year
            current_year = int(self.netlogo.report("year"))

            # Monitor the bio-energy of caribou
            bio_energy_values = self.netlogo.report("map [c -> [bioenergy] of c] sort caribou")

            # Calculate mean, median, max, and min
            mean_bio_energy = pd.Series(bio_energy_values).mean()
            median_bio_energy = pd.Series(bio_energy_values).median()
            max_bio_energy = pd.Series(bio_energy_values).max()
            min_bio_energy = pd.Series(bio_energy_values).min()

            # Log data
            tick = self.netlogo.report("ticks")
            new_row = pd.DataFrame(
                {'tick': [tick], 'mean_bio_energy': [mean_bio_energy], 'median_bio_energy': [median_bio_energy],
                 'max_bio_energy': [max_bio_energy], 'min_bio_energy': [min_bio_energy]})
            df = pd.concat([df, new_row], ignore_index=True)

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
        self.caribou_agents = [CaribouAgent(who, self.netlogo) for who in zip(who_values)]


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


    def go_agents(self):
        caribou_perceptions = self.netlogo.report(f"[(list who caribou-high-food-distance energy caribou-local-utility caribou-disturbance-distance caribou-hunter-distance)] of caribou")

        caribou_by_who = {entry[0]: entry[1:] for entry in caribou_perceptions}

        for caribou in self.caribou_agents:
            if caribou.who in caribou_by_who:
                perceptions = caribou_by_who[caribou.who]
                caribou.set_perceptions(*perceptions)



    def setup(self):
        self.setup_netlogo()
        self.setup_agents()
        self.load_patches()


    def run(self):
        self.simulation_loop()

    def get_netlogo_instance(self) -> NetLogoLink:
        return self.netlogo