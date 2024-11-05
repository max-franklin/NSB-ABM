from pynetlogo import NetLogoLink


class Agent:
    def __init__(self, who, netlogo : NetLogoLink, xcor=0, ycor=0, alive=True):
        """
        Replicates Netlogo Data for an agents
            who (int): Unique ID of the agents (NetLogo's `who` variable).
            xcor (float): X-coordinate of the agents.
            ycor (float): Y-coordinate of the agents.
            alive (bool): Whether the agents is alive or not.
        """
        self.netlogo = netlogo
        self.who = who
        self.xcor = xcor
        self.ycor = ycor
        self.alive = alive

    def get_neighbor_patches(self) -> dict[str,tuple]:
        """
        :return: A dictionary mapping each cardinal direction to the coordinates of the neighboring patch.
        The keys are the directions: 'northwest', 'north', 'northeast', 'west', 'east', 'southwest', 'south', 'southeast'.
        The values are tuples representing the (pxcor, pycor) coordinates of the neighboring patches for the current turtle.
        """
        neighbors = self.netlogo.report(f"map [list pxcor pycor] of [neighbors] of turtle {self.who}")
        directions = ['northwest', 'north', 'northeast', 'west', 'east', 'southwest', 'south', 'southeast']
        surrounding_patches = {direction: tuple(coords) for direction, coords in zip(directions, neighbors)}
        return surrounding_patches
