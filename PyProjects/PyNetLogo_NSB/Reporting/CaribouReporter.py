import datetime
from pathlib import Path

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
        self._temp_state_dataframe = None
        self._temp_energy_dataframe = None
        self.netlogo = netlogo
        self.caribou_agents = caribou_agents
        self.dataframe_dictionary = dataframe_dictionary

        self.__UID = -1
        self._temp_energy_data = []
        self._temp_state_data = []

        # The initial update moves this index to 0. If we see -1, we know it's an error
        self._energy_file_counter = -1
        self._state_file_counter = -1

        now = datetime.datetime.now()

        self.__str_file_date = now.strftime('%Y-%m-%d')
        self.caribou_filepath = CONFIG['LOGGING_PATH']
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
        energy_data = self.netlogo.report('map [c -> (list year day ticks [who] of c [bioenergy] of c)] (sort caribou)')

        # Append to temporary buffer

        self._temp_energy_data.append(energy_data)

        # Check Config for the write threshold
        if len(self._temp_energy_data) > CONFIG['WRITE_EVERY_N_ROWS']:
            # Use NumPy for efficient flattening of 3D data to 2D
            import numpy as np
            flattened_data = np.array([
                [year, day, ticks, who, bioenergy]
                for batch in self._temp_energy_data  # Iterate over each batch
                for year, day, ticks, who, bioenergy in batch  # Expand the inner list per batch
            ])

            # Create DataFrame from the flattened data
            part_df = pd.DataFrame(flattened_data, columns=["year", "day", "ticks", "who", "bioenergy"])

            # Check if 'energy' DataFrame exists, initialize if not
            if 'energy' not in self.dataframe_dictionary:
                self.dataframe_dictionary['energy'] = pd.DataFrame(columns=["year", "day","ticks", "who", "bioenergy"])

            # Efficiently update the 'energy' DataFrame by collecting in batches
            self.dataframe_dictionary['energy'] = pd.concat(
                [self.dataframe_dictionary['energy'], part_df],  # Efficient concatenation of larger batches
                ignore_index=True,
            )

            self.write_energy_data()

            # Clear the temporary buffer to free memory
            self._temp_energy_data = []


    # Should be called as per day total
    def add_state_data(self,year : int ,day : int):

        temp_caribou_list = []

        for c in self.caribou_agents:
            caribou_data = [year, day, c.who]
            caribou_data.extend(c.action_history)
            temp_caribou_list.append(caribou_data)
            c.action_history = [0, 0, 0, 0, 0]


        # List CONTENTS should match:
        #   ['day', 'who', ['evade', 'interforage', 'migrate', 'rest', 'intraforage']


        self._temp_state_data.extend(temp_caribou_list)

        # Check the Config for the write limit and write to a data frame past the buffer
        if len(self._temp_state_data) > int(CONFIG['WRITE_EVERY_N_ROWS']) * 50:
            part_df = pd.DataFrame(self._temp_state_data)
            self.dataframe_dictionary['state'] = pd.concat([self.dataframe_dictionary['state'], part_df],
                                                            ignore_index=True)

            self.write_state_data()

            # Clear the temporary buffer to free memory
            self._temp_state_data = []

    def write_all_data(self):
        """
        Writes all temporary energy and state data to their respective DataFrame stored in `dataframe_dictionary` and resets the temporary data lists.

        :return: None
        """
        self.write_energy_data()
        self.write_state_data()

    def setup(self):
        """
        Initializes and sets up the required data structures and file paths for tracking energy and state data.

        :return: None
        """
        # Define dataframes
        self.dataframe_dictionary['energy'] = pd.DataFrame(columns=["year", "day", 'tick', 'who', 'energy'])
        self.dataframe_dictionary['state'] = pd.DataFrame(columns=['year', 'day', 'who', 'evade', 'interforage', 'migrate', 'rest', 'intraforage'])



        self.__UID = self.netlogo.report('seed')
        self.caribou_filepath = (CONFIG['LOGGING_PATH'] + str(self.__UID) + '_'
                                + 'caribou_energy_' + self.__str_file_date
                                + "_" + str(self._energy_file_counter) + '.parquet')

        self.caribou_filepath = (CONFIG['LOGGING_PATH'] + str(self.__UID) + '_'
                                + 'caribou_state_' + self.__str_file_date
                                + "_" + str(self._state_file_counter) + '.parquet')


    def update_increment_energy_path(self):
        """
        Updates the energy file path by incrementing the internal energy file counter and appending it to the existing energy file path, uniquely identifying the file with a UID, date, and counter.

        :return: None
        """
        self._energy_file_counter += 1
        self.caribou_filepath = (CONFIG['LOGGING_PATH'] + str(self.__UID) + '_'
                                + 'caribou_energy_' + self.__str_file_date
                                + "_" + str(self._energy_file_counter) + '.parquet')


    def update_increment_state_path(self):
        """
        Updates the state file path by incrementing the internal energy file counter and appending it to the existing energy file path, uniquely identifying the file with a UID, date, and counter.

        :return: None
        """
        self._state_file_counter += 1
        self.caribou_filepath = (CONFIG['LOGGING_PATH'] + str(self.__UID) + '_'
                                + 'caribou_state_' + self.__str_file_date
                                + "_" + str(self._state_file_counter) + '.parquet')

    def write_energy_data(self):
        # Get our new path to partition data
        self.update_increment_energy_path()

        directory = Path(self.caribou_filepath).parent
        directory.mkdir(parents=True, exist_ok=True)

        # Ensure _temp_energy_data is a Pandas DataFrame
        if isinstance(self._temp_energy_data, list):
            # Flatten the list if required and convert to a DataFrame
            flattened_data = [
                [year, day, ticks, who, bioenergy]
                for batch in self._temp_energy_data
                for year, day, ticks, who, bioenergy in batch
            ]
            self._temp_energy_dataframe = pd.DataFrame(flattened_data, columns=["year", "day", "ticks", "who", "bioenergy"])

        if not isinstance(self._temp_energy_dataframe, pd.DataFrame):
            raise ValueError("self._temp_energy_dataframe must be a Pandas DataFrame or convertible to one.")

        # Create a data table for Parquet storage
        data_table = pa.Table.from_pandas(df=self._temp_energy_dataframe)

        # Write the table to the specified Parquet file
        pq.write_table(data_table, self.caribou_filepath)
        
        
    def write_state_data(self):
        # Get our new path to partition data
        self.update_increment_state_path()

        directory = Path(self.caribou_filepath).parent
        directory.mkdir(parents=True, exist_ok=True)

        # Ensure _temp_state_data is a Pandas DataFrame
        if isinstance(self._temp_state_data, list):
            # Directly convert the existing list of lists to a DataFrame
            self._temp_state_dataframe = pd.DataFrame(
                self._temp_state_data,
                columns=['year', 'day', 'who', 'evade', 'interforage', 'migrate', 'rest', 'intraforage']
            )

        if not isinstance(self._temp_state_dataframe, pd.DataFrame):
            raise ValueError("self._temp_state_dataframe must be a Pandas DataFrame or convertible to one.")

        # Create a data table for Parquet storage
        data_table = pa.Table.from_pandas(df=self._temp_state_dataframe)

        # Write the table to the specified Parquet file
        pq.write_table(data_table, self.caribou_filepath)
