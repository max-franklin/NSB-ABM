import json
import os
from turtledemo.clock import setup
from typing import Dict

import pandas as pd
import pynetlogo
from pynetlogo import NetLogoLink

from Simulation.agents.CaribouAgent import CaribouAgent



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


    def setup(self):
        self.setup_netlogo()
        self.setup_agents()


    def run(self):
        self.simulation_loop()

    def get_netlogo_instance(self) -> NetLogoLink:
        return self.netlogo