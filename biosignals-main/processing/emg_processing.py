from biosignals.signals import Signal, Passband
from biosignals.processing.signal_processing import SignalProcessing

class EmgProcessing(SignalProcessing):
    def __init__(self, sample_rate, passband=Passband(5, 250)) -> None:
        super().__init__(Signal.EMG, sample_rate=sample_rate, passband=passband)

    
