import numpy as np
from numba import jit

class CaribouFCM:
    def __init__(self, input_to_hidden_weights=None, hidden_to_action_weights=None):
        """
        Initialize the CaribouFCM class.

        :param matrix_base: Optional argument to initialize the matrix base
        :param input_to_hidden_weights: Weights from input to hidden layer
        :param hidden_to_action_weights: Weights from hidden to action layer
        """
        self.perception_mat = np.zeros((1, 10))
        self.last_action_mat = np.zeros((1, 5))
        # Concatenate the perception and last_action array to create our input array
        self.input_layer = np.hstack((self.perception_mat, self.last_action_mat))
        self.hidden_layer = np.zeros((1, 15))
        self.action_layer = np.zeros((1, 5))
        # track these as our "memory" layers to run through on the n+1 computation
        self.last_action = np.ones((1, 5))
        self.last_hidden = np.ones((1, 15))
        # Weights
        if input_to_hidden_weights is None:
            self.input_to_hidden_weights = np.zeros((15, 15))
        else:
            self.input_to_hidden_weights = input_to_hidden_weights

        if hidden_to_action_weights is None:
            self.hidden_to_action_weights = np.zeros((15, 5))
        else:
            self.hidden_to_action_weights = hidden_to_action_weights

    def process_forward(self):
        """
        Executes the forward propagation process for a neural network.

        Takes the input layer and computes the hidden layer by performing
        a dot product with the input-to-hidden weights.
        Then, computes the action layer by performing a dot product
        of the hidden layer with the hidden-to-action weights.

        After calculating the action layer, the sigmoid activation function is
        applied to the resulting values.

        Lastly, the action layer is stored for use in any future forward processing.

        :return: None
        """
        # Concatenate the perception and last_action layers into the input layer
        self.input_layer = np.hstack((self.perception_mat, self.last_action_mat))


        self.hidden_layer = np.dot(self.input_layer, self.input_to_hidden_weights)
      #  self.hidden_layer = np.vectorize(fcm_sigmoid_simple)(self.hidden_layer)
        self.hidden_layer = 1 / (1 + np.exp(-self.hidden_layer))  # Vectorized

        self.action_layer = np.dot(self.hidden_layer, self.hidden_to_action_weights)

        # run the sigmoid activation against the values
        #self.action_layer = np.vectorize(fcm_sigmoid_simple)(self.action_layer)
        self.action_layer / (1 + np.exp(-self.action_layer))  # Vectorized sigmoid

        # set our action layer for next forward process
        self.last_action_mat = self.action_layer


    # TODO: Set this such that the result is stochastic instead of the current MAX value
    def get_action(self):
        return np.argmax(self.action_layer)


    def randomize_weights(self):
        self.input_to_hidden_weights = np.random.rand(15, 15)
        self.hidden_to_action_weights = np.random.rand(15, 5)

    # TODO: Bind these to a simulation configuration file
    def set_perceptions(self, high_food_dist, bioenergy, local_food_qual, disturb_dist, hunt_dist):
        """
        :param high_food_dist: Distance to the high-quality food source. A float value representing the distance in some unit of measurement.
        :param bioenergy: The current bioenergy level of the organism. A float value between 22000 and 33000.
        :param local_food_qual: The quality of the local food source. A float value between 0 and 1.
        :param disturb_dist: Distance to the disturbance source. A float value representing the distance in some unit of measurement.
        :param hunt_dist: Distance to the hunter. A float value between 0.25 and 0.75.
        :return: None
        """
        # Hunter Distance
        self.perception_mat[0][0] =  1 - normalize_value(0.25, 0.75, hunt_dist)
        self.perception_mat[0][1] =  normalize_value(0.25, 0.75, hunt_dist)

        # Food Distance
        self.perception_mat[0][2] = 1 - normalize_value(0, 3, high_food_dist)
        self.perception_mat[0][3] = normalize_value(0, 3, high_food_dist)

        # Bioenergy
        self.perception_mat[0][4] = 1 - normalize_value(22000, 33000, bioenergy)
        self.perception_mat[0][5] = normalize_value(22000, 33000, bioenergy)

        # Local Food Quality
        self.perception_mat[0][6] = 1 - normalize_value(0, 0.50, local_food_qual)
        self.perception_mat[0][7] = normalize_value(0.50, 1, local_food_qual)

        # Disturbance Distance
        self.perception_mat[0][8] = 1 - normalize_value(1, 3, disturb_dist)
        self.perception_mat[0][9] = normalize_value(1, 3, disturb_dist)


def fcm_sigmoid_simple(x):
    # Clamp to prevent overflow on the sigmoid function
    x_clamped = np.clip(x, a_min=- -709.78, a_max=709.78)
    return 1 / (1 + np.exp(x))

def normalize_value(min_val, max_val, value):
    """
    Normalize a value within a given range [min_val, max_val] to a percentage between 0 and 1.
    In the model this was referred to as a "ternary" function

    Args:
        min_val (float): The minimum value of the range.
        max_val (float): The maximum value of the range.
        value (float): The value to be normalized.

    Returns:
        float: The normalized value between 0 and 1.
    """
    if min_val == max_val:
        raise ValueError("min_val and max_val must be different")

    return (value - min_val) / (max_val - min_val)