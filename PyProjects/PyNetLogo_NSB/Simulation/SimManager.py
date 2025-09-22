import ast
import math
import os
import statistics
import sys
import threading
from typing import Dict, List

import numpy as np
import pynetlogo
from line_profiler_pycharm import profile
from pynetlogo import NetLogoLink

from Reporting.CaribouReporter import CaribouReporter
from Simulation import config
from Simulation.agents.CaribouAgent import CaribouAgent
from Simulation.agents.DictonaryPatch import DictionaryPatch
from Simulation.config import CONFIG
from Simulation.controllers.PatchFactorController import PatchFactorController
from Simulation.fcms.FCMEvolution import FCMEvolution


class SimController:
    def __init__(self, dataframe_dictionary: Dict[str, object], shutdown_flag):
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

        self._current_year : int = 0
        self._current_day : int = 0

        self._go_calls : int = 0
        self.shutdown_flag = shutdown_flag or threading.Event()

        self._PatchFactorController :PatchFactorController = None
        self._median_caribou_energy = 0


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

        self.netlogo = pynetlogo.NetLogoLink(gui=True,
                                             jvmargs=["-Xmx20G"])
                                                     # ,"-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005"])
        self.netlogo.load_model(absolute_model_path)

        self.netlogo.command('set scenario "caribou-evolution"')
        self.netlogo.command("setup")

        self._PatchFactorController = PatchFactorController(self.netlogo)


    def update_console_values(self):
        sys.stdout.write(f"\rYear: {self._current_year} | Day: {self._current_day} | Tick: {self._go_calls}" )
        sys.stdout.flush()

    @profile
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
            self._go_calls += 1
            self.update_console_values()

            # TODO: Split Logging into its own Class set

            if tick % int(CONFIG["MODEL_DAYS_PER_TICK"]) == 0:
                self._current_day = math.floor(tick / int(CONFIG["MODEL_DAYS_PER_TICK"]))
                self.on_day_change()

            # Get the current year
            current_year = int(self.netlogo.report("year"))

            if current_year > last_year:
                last_year = current_year
                self._current_year = current_year
                self.on_year_change()

            # If the year is a multiple of 20, update the data
            if current_year >= 1000:
                print("Simulation ended at year 1000.")
                self.caribou_reporter.write_all_data()
                break

            self.go_agents_optimized_test()


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
    @profile()

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


    @profile
    def go_agents_optimized_test(self):
        # Retrieve all relevant perceptions in one NetLogo call
        raw_string = str(self.netlogo.report("caribou-perception-string"))

        caribou_perceptions = [
            list(map(float, line.split()))
            for line in raw_string.strip().split('\n')
            if line.strip()
        ]

        #  Map 'who' to perception vectors
        caribou_by_who = {int(entry[0]): entry[1:] for entry in caribou_perceptions}

        # Pass perceptions to agents and run FCM
        for caribou in self.caribou_agents:
            perceptions = caribou_by_who[caribou.who]
            caribou.set_perceptions(*perceptions)
            caribou.process_fcm()

        # Gather updated action states from agents
        who_values = [int(caribou.who) for caribou in self.caribou_agents]
        external_state_values = [int(caribou.get_action_state()) for caribou in self.caribou_agents]

        # Format Python lists into NetLogo list strings
        who_values_str = "[" + " ".join(map(str, who_values)) + "]"
        external_state_values_str = "[" + " ".join(map(str, external_state_values)) + "]"

        self.netlogo.set_breed_variable_by_who("caribou", "caribou-external-state", who_values, external_state_values)

        # Construct and run the table-based NetLogo command
        # command = f"set-external-caribou-states {who_values_str} {external_state_values_str}"
        # self.netlogo.command(command)

    def on_year_change(self):
        self.evolve_caribou()
        self._PatchFactorController.evolve(self._median_caribou_energy)


    #TODO Move this to a more appropriate caribou class
    def evolve_caribou(self):
        """
        Evolves the population of caribou agents by performing crossover and mutation operations on the fuzzy cognitive maps (FCM) associated with selected parent agents.
        The selection of parents is based on their energy levels, with the top two caribou being chosen.

        :return: None
        """

        # Must be even
        fcm_selects = 8
        new_fcms = []

        caribou_data = self.netlogo.report("[(list who bioenergy-success)] of caribou")
        sorted_energy = sorted(caribou_data, key=lambda c: c[1], reverse=True)

        #caribou_scores = [(c.who, c.action_score) for c in self.caribou_agents]

       # merged_caribou = self.merge_and_average(sorted_energy, caribou_scores)
        sorted_caribou = sorted(sorted_energy, key=lambda c: c[1], reverse=True)
        bioenergy_values = [c[1] for c in sorted_caribou]
        self._median_caribou_energy = statistics.median(bioenergy_values)



        sorted_who = [item[0] for item in sorted_caribou]

        parent_agent_whos = self.stochastic_selection(sorted_who, num_selected=fcm_selects)
        parent_caribou = [caribou for caribou in self.caribou_agents if caribou.who in parent_agent_whos]


        # Loop through selections
        pair_num = 0
        while pair_num < (fcm_selects / 2):
            crossed_fcm = FCMEvolution.cross_caribou_fcms(parent_caribou[pair_num * 2].fcm, parent_caribou[pair_num * 2 + 1].fcm, crossover_rate=.5)
            new_fcms.append(crossed_fcm)
            pair_num += 1


        total_new : int = int(fcm_selects / 2)
        fcm_increment : int = 0
        for caribou in self.caribou_agents:
            caribou.fcm = new_fcms[fcm_increment % total_new]
            FCMEvolution.mutate_caribou_fcm(caribou.fcm)
            fcm_increment += 1

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
        self.caribou_reporter.add_state_data(self._current_year, self._current_day)
        self.caribou_reporter.add_energy_data()


        for caribou in self.caribou_agents:
            caribou.reset_action_history()
