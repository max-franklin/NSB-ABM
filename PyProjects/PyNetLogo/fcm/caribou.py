import numpy as np


class CaribouFCM:
    def __init__(self, who, matrix_base=None):
        self.who = who

        self.perception_layer = [np.ones((1, 21)) for _ in range(5)]
        self.hidden_layer = [np.zeros((1, 6)) for _ in range(5)]
        self.action_layer = [np.zeros((1, 5)) for _ in range(5)]

        # track these as our "memory" layers to run through on the n+1 computation
        self.last_action = [np.ones((1, 5)) for _ in range(5)]
        self.last_hidden = [np.ones((1, 6)) for _ in range(5)]

        # Weights
        self.perception_to_hidden_weights = [np.zeros((21, 6)) for _ in range(5)]
        self.hidden_to_action_weights = [np.zeros((6, 5)) for _ in range(5)]




    def process_forward(self):
        self.hidden_layer = np.dot(self.perception_layer, self.perception_to_hidden_weights)


def fcm_sigmoid_simple(x):
    return 1 / (1 + np.exp(-x))
