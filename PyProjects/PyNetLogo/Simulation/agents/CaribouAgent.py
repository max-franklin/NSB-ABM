from pynetlogo import NetLogoLink

from Simulation.config import CONFIG
from Simulation.agents.Agent import Agent
from Simulation.fcms.CaribouFCM import CaribouFCM
from enum import Enum

class CaribouActions(Enum):
    EVADE = 0
    INTERFORAGE = 1
    MIGRATE = 2
    REST = 3
    INTRAFORAGE = 4

class CaribouAgent(Agent):
    def __init__(self, who, netlogo : NetLogoLink, xcor = None, ycor = None, bioenergy = None, fcm: CaribouFCM = None, ):
        super().__init__(who, netlogo, xcor, ycor)
        self.bioenergy = bioenergy
        self.fcm: CaribouFCM = fcm
        #self.action_state: int = None
        if self.fcm is None:
            self.fcm = CaribouFCM()

        self.action_history: list = [0, 0, 0, 0, 0]
        self.action_counter: int = 1

        self.action_score: float = 0.0





    def set_perceptions(self, high_food_dist, bioenergy, local_food_qual, disturb_dist, hunt_dist):
        # Pass to the FCM implementation
        self.fcm.set_perceptions(
            high_food_dist,
            bioenergy,
            local_food_qual,
            disturb_dist,
            hunt_dist)

    def process_fcm(self):
        self.fcm.process_forward()

    def get_action_state(self):
        action_value = self.fcm.get_action()

        mod_ticks = CONFIG["MODEL_DAYS_PER_TICK"] % self.action_counter

        self.action_history[action_value] += 1
        self.action_counter += 1


        if mod_ticks == 0:
            score = CaribouAgent.sad_similarity(CONFIG["CARIBOU_IDEAL_STATE"], self.action_history, mod_ticks)

            if(self.action_counter <=  CONFIG["MODEL_DAYS_PER_TICK"]):
                self.action_score = score
            else:
                self.action_score = (self.action_score + score) / 2


        self.action_history: list = [0, 0, 0, 0, 0]

        self.action_history[action_value] = self.action_history[action_value] + 1

        return action_value

        #return self.fcm.get_action()

    @staticmethod
    def sad_similarity(truth, sample, total_ticks) -> float:
        """
        Returns a similarity score between 0 (worst) and 1 (best),
        based on 1 - (SAD / (2*total_ticks)).
        """
        sad = sum(abs(t - s) for t, s in zip(truth, sample))
        max_sad = 2 * total_ticks  # = 32 if total_ticks=16

        # Handle First Tick case
        if max_sad == 0:
            return 0

        return 1 - (sad / max_sad)

    def set_random_fcm(self):
        self.fcm.randomize_weights()