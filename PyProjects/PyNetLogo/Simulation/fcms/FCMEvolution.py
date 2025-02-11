import numpy as np

from Simulation.fcms.CaribouFCM import CaribouFCM


class FCMEvolution:
    @staticmethod
    def uniform_crossover(parent_a: np.ndarray, parent_b: np.ndarray, crossover_rate=0.5):
        """
        :param parent_a: A numpy array representing the first parent for crossover.
        :param parent_b: A numpy array representing the second parent for crossover.
        :param crossover_rate: A float representing the probability of inheriting genes from parent_a. Default is 0.5.
        :return: A numpy array representing the child resulting from the uniform crossover operation.
        """
        mask = np.random.rand(*parent_a.shape) < crossover_rate
        # Create child by selecting weights from parentA or parentB
        child = np.where(mask, parent_a, parent_b)
        return child

    @staticmethod
    def mutate(weights: np.ndarray, mutation_rate=0.1):
        """
        :param weights: The array of weights that will be mutated. It is expected to be a NumPy ndarray.
        :param mutation_rate: The probability for each weight to undergo mutation. Default value is 0.1.
        :return: The mutated weights as a NumPy ndarray.
        """
        mutation_mask = np.random.rand(*weights.shape) < mutation_rate
        mutation_values = np.random.normal(0, 0.1, weights.shape)
        weights += mutation_mask * mutation_values
        return weights

    @staticmethod
    def cross_caribou_fcms(parent_a: CaribouFCM, parent_b: CaribouFCM, crossover_rate=0.5):
        """
        :param parent_a: First CaribouFCM object representing a parent.
        :param parent_b: Second CaribouFCM object representing a parent.
        :param crossover_rate: The rate at which crossover occurs during the evolution process, default is 0.5.
        :param mutation_rate: The rate at which mutation occurs after the evolution process, default is 0.1.
        :return: None, modifies the parent objects directly.
        """
        new_input_to_hidden_weights = FCMEvolution.uniform_crossover(parent_a.input_to_hidden_weights, parent_b.input_to_hidden_weights, crossover_rate)
        new_hidden_to_action_weights = FCMEvolution.uniform_crossover(parent_a.hidden_to_action_weights, parent_b.hidden_to_action_weights, crossover_rate)


        parent_a.input_to_hidden_weights = new_input_to_hidden_weights
        parent_b.input_to_hidden_weights = new_input_to_hidden_weights

        parent_a.hidden_to_action_weights = new_hidden_to_action_weights
        parent_b.hidden_to_action_weights = new_hidden_to_action_weights

    @staticmethod
    def mutate_caribou_fcm(fcm: CaribouFCM, mutation_rate=0.001):
        """
        :param fcm: CaribouFCM object to be mutated.
        :param mutation_rate: The rate at which mutation occurs. Default value is 0.1.
        :return: None, modifies the weights of the fcm directly.
        """
        fcm.input_to_hidden_weights = FCMEvolution.mutate(fcm.input_to_hidden_weights, mutation_rate)
        fcm.hidden_to_action_weights = FCMEvolution.mutate(fcm.hidden_to_action_weights, mutation_rate)
