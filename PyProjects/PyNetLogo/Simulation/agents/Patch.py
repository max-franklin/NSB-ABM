class Patch:
    """
        Class representing a netlogo patch

        Attributes:
        xcor (int): The x-coordinate of the patch.
        ycor (int): The y-coordinate of the patch.
    """
    def __init__(self, xcor : int, ycor : int):
        self.xcor = xcor
        self.ycor = ycor