from abc import ABC
import numpy as np
import biosignals.processing._util as _util
from biosignals.signals import Signal, Passband

class SignalProcessing(ABC):
    def __init__(self, signal:Signal, sample_rate, passband) -> None:
        super().__init__()
        if not isinstance(signal, Signal):
            raise ValueError("`signal` must be a `Signal` instance")
        if not isinstance(passband, Passband):
            raise ValueError("`passband` must be a `Passband` instance")
        if not isinstance(sample_rate, int):
            raise ValueError("`sample_rate` must be integer.")

        self.signal = signal
        self.passband = passband
        self.sample_rate = sample_rate

    def passband_filt(self, data:np.ndarray)->np.ndarray:
        return _util.filt(data, 
            self.passband.band, fs=self.sample_rate, mode='bandpass')

    def snr(self, data:np.ndarray)->np.ndarray:
        high_pass = _util.filt(data, 
            self.passband[0], fs=self.sample_rate, mode='high')
        signal = _util.filt(high_pass, 
        self.passband[1], fs=self.sample_rate, mode='low')

        noise = high_pass - signal

        return 10*(np.log10(signal**2) - np.log10(noise**2))
        # bandpassed = self.passband_filt(data)
        # snr = np.var(bandpassed) / np.var(np.abs(bandpassed))

    def denoise(self, data:np.ndarray)->np.ndarray:
        # remove baseline wander
        zero_centered_data = data - np.mean(data)
        short_moving_mean = _util.movmean(zero_centered_data, self.sample_rate*7)

        # simple noise identification based on moving average
        noise_idxs = np.abs(short_moving_mean) >= 2*np.mean(data) 
        denoised_data = data.copy()
        denoised_data[noise_idxs] = 0
        return denoised_data

    def spectrogram(self, data, **kwargs):
        pass





    

    
        

