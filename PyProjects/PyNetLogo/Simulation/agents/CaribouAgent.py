from Simulation.agents.Agent import Agent
from Simulation.fcms import CaribouFCM
from enum import Enum

class CaribouActions(Enum):
    EVADE = 0
    INTERFORAGE = 1
    MIGRATE = 2
    REST = 3
    INTRAFORAGE = 4

class CaribouAgent(Agent):
    def __init__(self, who, xcor, ycor, bioenergy, fcm: CaribouFCM):
        super().__init__(who, xcor, ycor)
        self.bioenergy = bioenergy
        self.fcm: CaribouFCM = fcm

