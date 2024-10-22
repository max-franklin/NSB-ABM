import os
from typing import Dict

import pynetlogo


class SimController:
    def __init__(self, data_dictionary: Dict[str, object]):
        self.bioenergy_data = data_dictionary['bio_energy']
        self.netlogo = None

    def setup_netlogo(self):
        absolute_model_path = os.path.abspath(os.path.join(os.getcwd(), MODEL_PATH))

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

