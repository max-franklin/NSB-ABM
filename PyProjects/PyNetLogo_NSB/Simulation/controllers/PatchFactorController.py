import os
from typing import Dict, List, Optional, Any, Iterable, Tuple, Union
from copy import deepcopy
import numpy as np

# Import the NetLogoLink type from the pynetlogo API
from pynetlogo import NetLogoLink


class PatchFactorController:

    FACTOR_NAMES: Tuple[str, ...] = (
        "caribou-veg-factor",
        "caribou-rough-factor",
        "caribou-insect-factor",
        "caribou-modifier-factor",
        "caribou-deflection-factor",
        "caribou-precip-factor",
    )

    def __init__(self, netlogo: NetLogoLink = None, log_file: Optional[str] = None):
        self._netlogo: NetLogoLink = netlogo
        self._log_file: Optional[str] = log_file
        self._log_initialized: bool = False

        # Current factor values (float)
        self._values: Dict[str, float] = {name: 1.0 for name in self.FACTOR_NAMES}

        self._history: List[Dict[str, Any]] = []

        # Initial state
        self._apply_to_netlogo(self._values)
        self._append_history(fitness=0.0)

    def evolve(self, fitness: float, mu: float = 0.05) -> Dict[str, float]:
         # Log current state with the fitness it achieved
        self._append_history(fitness=fitness)

        direction = -1 if fitness < 0 else 1

        # "Drift" the values by either 1 or -1. Currently no "evolve" process
        for name in self.FACTOR_NAMES:
            self._values[name] = float(self._values[name] + (mu * np.random.choice([1, -1])))

        # send new values to NetLogo
        self._apply_to_netlogo(self._values)

        return deepcopy(self._values)

    def get_history(self) -> List[Dict[str, Any]]:
        return deepcopy(self._history)

    def get_current_values(self) -> Dict[str, float]:
        return deepcopy(self._values)

    def reset(self) -> None:
        self._values = {name: 1.0 for name in self.FACTOR_NAMES}
        self._history.clear()
        self._apply_to_netlogo(self._values)
        self._append_history(fitness=0.0)

    def set_values(self, values: Dict[str, float], record: bool = False, fitness_for_record: float = 0.0) -> None:
        if record:
            self._append_history(fitness=fitness_for_record)

        # Update current values
        for name in self.FACTOR_NAMES:
            if name in values:
                self._values[name] = float(values[name])

        self._apply_to_netlogo(self._values)

    def _append_history(self, fitness: float) -> None:
        self._history.append(
            {
                "fitness": float(fitness),
                "values": deepcopy(self._values),
            }
        )

        # self._append_record_to_file(float(fitness))

    def _apply_to_netlogo(self, values: Dict[str, float]) -> None:
        commands: List[str] = []
        for name in self.FACTOR_NAMES:
            val = float(values[name])
            commands.append(f"set {name} {val}")

        self._netlogo.command(" ".join(commands))

    # def _ensure_log_header(self) -> None:
    #     if not self._log_file:
    #         return
    #     # Create directory if needed
    #     os.makedirs(os.path.dirname(self._log_file) or ".", exist_ok=True)
    #     # Write header if file doesn't exist or is empty
    #     needs_header = not os.path.exists(self._log_file) or os.path.getsize(self._log_file) == 0
    #     if needs_header:
    #         header = ["fitness", *self.FACTOR_NAMES]
    #         with open(self._log_file, "w", newline="") as f:
    #             f.write(",".join(header) + "\n")
    #     self._log_initialized = True
    #
    # def _append_record_to_file(self, fitness: float) -> None:
    #     if not self._log_file:
    #         return
    #     if not self._log_initialized:
    #         self._ensure_log_header()
    #     row = [str(float(fitness))] + [str(float(self._values[name])) for name in self.FACTOR_NAMES]
    #     # Efficient append: single write per record
    #     with open(self._log_file, "a", newline="") as f:
    #         f.write(",".join(row) + "\n")
