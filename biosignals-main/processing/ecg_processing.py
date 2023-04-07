from biosignals.signals import Signal, Passband
from biosignals.processing.signal_processing import SignalProcessing
from scipy.signal import find_peaks, savgol_filter
import biosignals.processing._util as _util
import numpy as np


class EcgProcessing(SignalProcessing):
    def __init__(self, sample_rate, passband=Passband(0.8, 25)) -> None:
        super().__init__(Signal.ECG, sample_rate=sample_rate, passband=passband)

    # def find_r_peaks(self, raw_ecg):
    #     fs = self.sample_rate

    #     # moving standard deviation calculation
    #     steps = np.arange(len(raw_ecg), step=2*fs) # 2 second segments
    #     splits = np.split(raw_ecg, steps)[1:] # drop first because it's always empty
    #     segments = np.vstack(splits[:-1]) # up to last because last is likely different shape
    #     stds = np.std(segments, axis=1)

    #     # thresholding similar to an elbow method 
    #     threshold = np.quantile(stds, 0.8)
    #     segments_to_clean = stds > threshold
    #     segments[segments_to_clean] = 0
    #     cleaned = segments.reshape((-1,))

    #     detectors = Detectors(fs)
    #     r_peaks = detectors.swt_detector(raw_ecg)
    #     return r_peaks, None

    def find_r_peaks(self, raw_ecg):
        raw_ecg = np.array(raw_ecg)
        fs = self.sample_rate

        # preprocess
        idxs_to_keep = ~np.isnan(raw_ecg)
        raw_ecg = raw_ecg[idxs_to_keep]

        if np.count_nonzero(idxs_to_keep) == 0:
            return None

        ecg = _util.filt(
            raw_ecg, self.passband.band, fs=fs, mode='bandpass')
        ecg_abs = np.abs(ecg)

        if np.quantile(ecg_abs, 0.9) < 1e-6:
            return None

       # gradient squared to emphasize QRS complex, especially R peak
        ecg_grad_sq = np.square(np.gradient(ecg_abs))

        # zero-out high noise regions
        ecg_grad_sq[ecg_grad_sq > 2*np.std(ecg_grad_sq)] = 0

        # scale from 0 to 1 for numerical reasons
        scaled = ecg_grad_sq / np.max(ecg_grad_sq)

        # Pan-Tompkins moving mean 
        movmean_window_size = int(fs * 0.15) 
        if movmean_window_size % 2 == 0:
            movmean_window_size += 1

        ecg_movmean = _util.movmean(scaled, movmean_window_size)

        # smooth with savitzy golay filtering
        savgol_window_size = int(fs // 2)
        if savgol_window_size % 2 == 0:
            savgol_window_size += 1

        cleaned_smooth = savgol_filter(ecg_movmean, savgol_window_size, polyorder=3)

        # segment smoothed signal for more robust peak finding
        steps = np.arange(len(scaled), step=5*fs) # 5 second segments

        # drop first because it's always empty and up to last because last 
        # is likely different shape
        segments = np.split(cleaned_smooth, steps)[1:-1] # 
        # segments = np.vstack(splits[:-1]) 
        # stds = np.std(segments, axis=1)

        total_std = np.std(cleaned_smooth)
        all_rpeaks = []
        for i, segment in enumerate(segments):
            std = np.std(segment)
            if std <= 3*total_std:
                rpeak_idxs, _ = find_peaks(segment, 
                                distance=int(0.2*fs),
                                prominence=np.std(segment), 
                                wlen=int(fs))
                all_rpeaks.append(rpeak_idxs + i*len(segment))

        if not all_rpeaks:
            return None
        
        rpeak_idxs = np.concatenate(all_rpeaks)
    
        # nudge peaks to local maxima
        nudged_peaks = np.copy(rpeak_idxs)
        for i, peak_idx in enumerate(rpeak_idxs):
            window = int(fs * 0.05)
            left_side = max(peak_idx - window, 0)
            right_side = min(peak_idx + window, len(ecg) - 1)

            ecg_window = ecg[left_side:right_side+1]
            if np.max(ecg_window) > ecg[peak_idx]:
                # nudge peaks
                nudged_peaks[i] = np.argmax(ecg_window) + left_side

        return nudged_peaks

        # leverage prominence especially for peak detection
        # rpeak_idxs, _ = find_peaks(cleaned_smooth, 
        #                         distance=int(0.2*fs), # minimum 200ms refractory period 
        #                         prominence=np.std(cleaned_smooth), 
        #                         wlen=int(fs))



    def heart_rate(self, raw_times, raw_ecg):
        raw_times = np.array(raw_times)
        raw_ecg = np.array(raw_ecg)
        fs = self.sample_rate

        # preprocess
        idxs_to_keep = ~np.isnan(raw_ecg)
        raw_ecg = raw_ecg[idxs_to_keep]
        times = raw_times[idxs_to_keep]   

        # denoise
        ecg = _util.filt(
            raw_ecg, self.passband.band, fs=fs, mode='bandpass', order=4)
        # ecg = self.denoise(ecg)

        # get r-peaks
        r_peak_idxs = self.find_r_peaks(ecg)
        if r_peak_idxs is None or len(r_peak_idxs) == 0:
            return None

        # hr and hr_t calculation 
        beat_intervals = np.diff(r_peak_idxs) / fs
        hr = 60 / beat_intervals
        to_keep = ((hr < 200) & (hr > 40))

        hr = hr[to_keep]
        hr_t = raw_times[r_peak_idxs[1:]][to_keep]

        # smoothing output 
        try:
            filtered_hr = _util.savgol_filter(hr, window_length=25, polyorder=5)
        except ValueError:
            filtered_hr = hr
            
        return (hr_t, filtered_hr)

    def heart_rate_variability(self, raw_times, raw_ecg):
        raw_times = np.array(raw_times)
        raw_ecg = np.array(raw_ecg)
        fs = self.sample_rate

        # preprocess
        idxs_to_keep = ~np.isnan(raw_ecg)
        raw_ecg = raw_ecg[idxs_to_keep]
        times = raw_times[idxs_to_keep]  

        # denoise
        ecg = _util.filt(
            raw_ecg, self.passband.band, fs=fs, mode='bandpass', order=4)
        # ecg = self.denoise(ecg)

        # get r-peaks
        r_peak_idxs = self.find_r_peaks(ecg)
        if r_peak_idxs is None or len(r_peak_idxs) == 0:
            return None

        beat_durations = np.diff(r_peak_idxs) / fs

        if len(beat_durations) == 0:
            return None

        return raw_times[r_peak_idxs[1:]], _util.movmean(beat_durations, 11)

    def respiration_rate(self, raw_times, raw_ecg):
        raw_times = np.array(raw_times)
        raw_ecg = np.array(raw_ecg)
        fs = self.sample_rate

        # preprocess
        idxs_to_keep = ~np.isnan(raw_ecg)
        raw_ecg = raw_ecg[idxs_to_keep]
        times = raw_times[idxs_to_keep]  

        # denoise
        ecg = _util.filt(
            raw_ecg, self.passband.band, fs=fs, mode='bandpass')
        # ecg = self.denoise(ecg)

        # get r-peaks
        r_peak_idxs = self.find_r_peaks(ecg)

        if r_peak_idxs is None or len(r_peak_idxs) == 0:
            return None

        # get envelope of ECG and envelope's peaks
        window_len = 11
        if len(r_peak_idxs) <= window_len:
            return raw_times, np.zeros(len(raw_times))
        
        envelope = savgol_filter(ecg[r_peak_idxs], window_length=window_len, polyorder=4)
        rr_peaks, _ = find_peaks(envelope, wlen=2)
        breath_durations = np.diff(r_peak_idxs[rr_peaks]) / fs
        breaths_per_minute = 60 / breath_durations
        
        return raw_times[r_peak_idxs[rr_peaks]][1:], breaths_per_minute


