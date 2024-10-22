import numpy as np


class CaribouFCM:
    def __init__(self, matrix_base=None):
        self.perception_mat = np.zeros((1, 10))
        self.last_action_mat = np.zeros((1, 5))

        # Concatenate the perception and last_action array to create our input array
        self.input_layer = np.hstack((self.perception_mat, self.last_action_mat))

        self.hidden_layer = np.zeros((1, 15))
        self.action_layer = np.zeros((1, 5))

        # track these as our "memory" layers to run through on the n+1 computation
        self.last_action = np.ones((1, 5))
        self.last_hidden = np.ones((1, 6))

        # Weights
        self.input_to_hidden_weights = np.zeros((15, 15))
        self.hidden_to_action_weights = np.zeros((15, 15))

    def process_forward(self):
        self.hidden_layer = np.dot(self.input_layer, self.input_to_hidden_weights)
        self.action_layer = np.dot(self.hidden_layer, self.hidden_to_action_weights)

        # run the sigmoid activation against the values
        self.action_layer = fcm_sigmoid_simple(self.action_layer)

        # set our action layer for next forward process
        self.last_action_mat = self.action_layer

    def get_action(self):
        return np.argmax(self.action_layer)





def fcm_sigmoid_simple(x):
    return 1 / (1 + np.exp(-x))
