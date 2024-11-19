from pynetlogo import NetLogoLink

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

        if self.fcm is None:
            self.fcm = CaribouFCM()


    def set_perceptions(self, high_food_dist, bioenergy, local_food_qual, disturb_dist, hunt_dist):


    def set_random_fcm(self):
        self.fcm.randomize_weights()