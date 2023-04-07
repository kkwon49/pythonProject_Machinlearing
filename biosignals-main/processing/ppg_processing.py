from biosignals.signals import Signal, Passband
from biosignals.processing.signal_processing import SignalProcessing
import biosignals.processing._util as _util
import numpy as np

class PpgProcessing(SignalProcessing):
    def __init__(self, sample_rate, passband=Passband(0.8,8)) -> None:
        super().__init__(Signal.PPG, sample_rate, passband)
 
    def _rms(self, data):
        return np.sqrt(np.mean(np.square(data)))

    def blood_oxygen(self, times, red, ir):
        t = np.array(times)
        red = np.array(red)
        ir = np.array(ir)
        fs = self.sample_rate

        # median filtering
        med_window = int(fs/8)
        if med_window % 2 == 0:
            med_window += 1
        red_filt = _util.medfilt(red, med_window) 
        ir_filt = _util.medfilt(ir, med_window)

        # bandpass filtering
        freqs = np.array([0.8, 8])
        red_filt = _util.filt(red_filt, freqs, fs=50, mode='bandpass', order=4)
        ir_filt = _util.filt(ir_filt, freqs, fs=50, mode='bandpass', order=4)

        # define coefficients
        a = 1.5958422
        b = -34.6596622
        c = 112.6898759

        # prepare segmentation for spo2 calculation
        lowpass_cutoff = 0.1 # Hz
        window_size = 5 # seconds
        R = np.zeros(int(np.ceil(len(t)/fs)))

        for i in range(fs*window_size, len(t), fs):
            i1 = i - fs*window_size
            i2 = i
            idxs = np.arange(i1, i2, dtype=int)

            red_filt_subset = red_filt[idxs]
            ir_filt_subset = ir_filt[idxs]

            red_dc = np.mean(_util.filt(red[idxs], lowpass_cutoff, 50, 'low', 4))
            ir_dc = np.mean(_util.filt(ir[idxs], lowpass_cutoff, 50, 'low', 4))

            red_ac = self._rms(red_filt_subset)
            ir_ac = self._rms(ir_filt_subset)

            R_idx = int(i1/fs)
            R_val = (red_ac/red_dc) / (ir_ac/ir_dc)
            R[R_idx] = R_val
            
        # calculation of spo2 from R values
        spo2 = a*np.square(R) + b*R + c;
        spo2[spo2 > 100] = 100
        spo2[spo2 < 70] = 70
        
        # time bounds 
        spo2_t = np.linspace(t[0], t[-1], len(spo2))
        
        return (spo2_t, spo2)
        

