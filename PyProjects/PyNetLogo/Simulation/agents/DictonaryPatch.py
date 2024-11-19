from Simulation.agents.Patch import Patch


class DictionaryPatch(Patch):
    """
        Class representing a netlogo patch with additional values for the caribou model

        Attributes:
        xcor (int): The x-coordinate of the patch.
        ycor (int): The y-coordinate of the patch.
        utility (float): The utility value of the patch.
    """
    def __init__(self, xcor, ycor, patch_variables : dict[str, object]):
        super().__init__(xcor, ycor)
        self.patch_variables = patch_variables
