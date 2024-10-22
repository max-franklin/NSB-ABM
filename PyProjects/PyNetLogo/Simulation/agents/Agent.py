class Agent:
    def __init__(self, who, xcor=0, ycor=0, alive=True):
        """
        Replicates Netlogo Data for an agents
            who (int): Unique ID of the agents (NetLogo's `who` variable).
            xcor (float): X-coordinate of the agents.
            ycor (float): Y-coordinate of the agents.
            alive (bool): Whether the agents is alive or not.
        """
        self.who = who
        self.xcor = xcor
        self.ycor = ycor
        self.alive = alive
