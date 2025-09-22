from Simulation.agents.Patch import Patch


class CaribouPatch(Patch):
    """
        Class representing a netlogo patch with additional values for the caribou model

        Attributes:
        xcor (int): The x-coordinate of the patch.
        ycor (int): The y-coordinate of the patch.
        utility (float): The utility value of the patch.
    """
    def __init__(self, xcor, ycor, utility):
        super().__init__(xcor, ycor)
        self.utility = utility