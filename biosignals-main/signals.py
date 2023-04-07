from enum import Enum

class Signal(Enum):
    ECG = "ECG"
    PPG = "PPG"
    EEG = "EEG"
    ACC = "Acceleration"
    TMP = "Temperature"
    EMG = "EMG"

    @staticmethod
    def valid_names():
        return [sig.value for sig in Signal]

class Passband:
    def __init__(self, lower, upper) -> None:
        self.lower = float(lower)
        self.upper = float(upper)

    def __getitem__(self, key):
        if key == 0 or key == 'lower':
            return self.lower
        elif key == 1 or key == 'upper':
            return self.upper 
        raise KeyError(key)

    def __setitem__(self, key, value):
        value = float(value)
        if key == 0 or key == 'lower':
            self.lower = value
        elif key == 1 or key == 'upper':
            self.upper = value
        else:
            raise KeyError(key)

    @property
    def band(self) -> list:
        return (self.lower, self.upper)