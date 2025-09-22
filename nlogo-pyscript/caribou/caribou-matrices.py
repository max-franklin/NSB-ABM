import numpy as np

def create_matrices():
    matrices = {
        "caribou_prev_fcm_node_states": np.zeros((1, 5)),
        "caribou_fcm_perceptions": np.zeros((1, 21)),
        "caribou_fcm_perception_weights": np.zeros((21, 21)),
        "fcm_adja": np.zeros((21, 21)),
        "caribou_fcm_node_states": np.zeros((1, 5))
    }
    return matrices