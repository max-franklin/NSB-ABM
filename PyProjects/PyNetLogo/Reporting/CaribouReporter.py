import datetime

import pandas as pd
import pynetlogo
from pynetlogo import NetLogoLink

import pyarrow as pa
import pyarrow.parquet as pq

from Simulation.agents.CaribouAgent import CaribouAgent
from Simulation.config import CONFIG
from Simulation.fcms.CaribouFCM import CaribouFCM


class CaribouReporter:
    def __init__(self, netlogo : NetLogoLink, caribou_agents : list[CaribouAgent], dataframe_dictionary : dict[str, object]):
        self.netlogo = netlogo
        self.caribou_agents = caribou_agents
        self.dataframe_dictionary = dataframe_dictionary

        self.__UID = -1
        self.__temp_energy_data = []
        self.__temp_state_data = []

        # The initial update moves this index to 0. If we see -1, we know it's an error
        self.__energy_file_counter = -1
        self.__state_file_counter = -1

        now = datetime.datetime.now()

        self.__str_file_date = now.strftime('%Y-%m-%d')
        self.energy_filepath = CONFIG['LOGGING_PATH']
        self.setup()



    def add_energy_data(self):
        """
        Collects and appends energy data from NetLogo simulation for caribou agents.

        The method uses the `NetLogoLink.py` library to fetch data about caribou agents, including
        ticks, agent IDs, and their corresponding bioenergy values. The data is temporarily stored
        in a buffer (`__temp_energy_data`). Once the number of stored entries exceeds the specified
        limit in the configuration (`CONFIG['WRITE_EVERY_N_ROWS']`), the buffered data is written
        to a Pandas DataFrame and appended to the `dataframe_dictionary` under the key 'energy'.
        The buffer is then cleared.

        :return: None
        """
        energy_data = self.netlogo.report('map [c -> (list ticks [who] of c [bioenergy] of c)] (sort caribou)')

        self.__temp_energy_data.append(energy_data)

        # Check the Config for the write limit and write to a data frame past the buffer
        if self.__temp_energy_data.count > CONFIG['WRITE_EVERY_N_ROWS']:
            part_df = pd.DataFrame(self.__temp_energy_data)
            self.dataframe_dictionary['energy'] = pd.concat([self.dataframe_dictionary['energy'], part_df], ignore_index=True)
            self.__temp_energy_data = []


    # Should be called as per day total
    def add_state_data(self, day : int):

        temp_caribou_list = []

        for c in self.caribou_agents:
            caribou_data = [day, c.who].extend(c.action_history)
            temp_caribou_list.append(caribou_data)
            c.action_history = [0, 0, 0, 0, 0]


        # List CONTENTS should match:
        #   ['day', 'who', ['evade', 'interforage', 'migrate', 'rest', 'intraforage']

        #state_data = self.netlogo.report('map [c -> (list ticks [who] of c [bioenergy] of c)] (sort caribou)')

        self.__temp_state_data.extend(temp_caribou_list)

        # Check the Config for the write limit and write to a data frame past the buffer
        if len(self.__temp_state_data) > int(CONFIG['WRITE_EVERY_N_ROWS']):
            part_df = pd.DataFrame(self.__temp_state_data)
            self.dataframe_dictionary['state'] = pd.concat([self.dataframe_dictionary['state'], part_df],
                                                            ignore_index=True)
            self.__temp_state_data = []

    def write_all_data(self):
        """
        Writes all temporary energy and state data to their respective DataFrame stored in `dataframe_dictionary` and resets the temporary data lists.

        :return: None
        """
        # Write out the energy data and reset the list
        part_df = pd.DataFrame(self.__temp_energy_data)
        self.dataframe_dictionary['energy'] = pd.concat([self.dataframe_dictionary['energy'], part_df],
                                                        ignore_index=True)
        self.__temp_energy_data = []

        # Write out the state data and reset the list
        part_df = pd.DataFrame(self.__temp_state_data)
        self.dataframe_dictionary['state'] = pd.concat([self.dataframe_dictionary['state'], part_df],
                                                        ignore_index=True)
        self.__temp_state_data = []

    def setup(self):
        """
        Initializes and sets up the required data structures and file paths for tracking energy and state data.

        :return: None
        """
        # Define dataframes
        self.dataframe_dictionary['energy'] = pd.DataFrame(columns=['tick', 'who', 'energy'])
        self.dataframe_dictionary['state'] = pd.DataFrame(columns=['day', 'who', 'evade', 'interforage', 'migrate', 'rest', 'intraforage'])



        self.__UID = self.netlogo.report('seed')
        self.energy_filepath = (self.energy_filepath + str(self.__UID) + '_'
                                + 'caribou_energy_' + self.__str_file_date
                                + "_" + str(self.__energy_file_counter) + '.parquet')


    def update_increment_energy_path(self):
        """
        Updates the energy file path by incrementing the internal energy file counter and appending it to the existing energy file path, uniquely identifying the file with a UID, date, and counter.

        :return: None
        """
        self.__energy_file_counter += 1
        self.energy_filepath = (self.energy_filepath + str(self.__UID) + '_'
                                + 'caribou_energy_' + self.__str_file_date
                                + "_" + str(self.__energy_file_counter) + '.parquet')

    def write_energy_data(self):
        # Get our new path to partition data
        self.update_increment_energy_path()

        # Create a datatable for the parquet
        data_table = pa.Table.from_pandas(df=self.__temp_energy_data)
        pq.write_table(data_table, self.energy_filepath)