import os
import pandas as pd
import glob
import numpy as np
import scipy.io
import numpy as np
import matplotlib.pyplot as plt
import scipy as sp
import sklearn.model_selection
from PIL import Image
from scipy import signal
from scipy.signal import butter, lfilter
from EmgProcessing import EmgProcessing
from scipy.signal import hilbert
from filter_EMG import filteremg
from sklearn.decomposition import FastICA
def signaltonoise_dB(a, axis=0, ddof=0):
    a = np.asanyarray(a)
    m = a.mean(axis)
    sd = a.std(axis=axis, ddof=ddof)
    return 20*np.log10(abs(np.where(sd == 0, 0, m/sd)))

path_root = '/Users/kang-kyukwon/Downloads/Exo_Data/Raw/602/EMG_K1'
#sub_root = 'Raw/'
#sub_root1 = 'Editted/'
#sub_root2 = 'Back_adding'
Start_time = 1673641006
#Start_time = 1673640780
Stop_time = 1673641115
#Start_time = 1674005845
emg_proc = EmgProcessing(sample_rate=500)

data1 = pd.read_csv(f'{path_root}/IMU.csv', header=0)
#data1 = pd.read_csv(f'{path_root}{sub_root}{sub_root2}/EMG.csv', header=0)
#data = pd.read_csv(f'{path_root}{filename1}.csv', header=0)
data1 = pd.DataFrame(data1)
data1.columns = ['Time','channel1','channel2','channel3','channel4','channel5','channel6']
#data1.columns = ['index','Time', 'channel']
#data1 = data1['Time','channel']
time = data1.Time
data1 = data1[np.abs(time) > Start_time]
#data1 = data1[ np.abs(time) < Stop_time]
#Time1 = data1.Time
#channel = data1.channel
#channel1 = emg_proc.passband_filt(channel)
#channel = hilbert(channel)
#channel1 = abs(channel1)
#low_pass = 10 / 250
#b2, a2 = sp.signal.butter(4, low_pass, btype='lowpass')
#channel1 = sp.signal.filtfilt(b2, a2, channel1)
#channel = filteremg(channel, low_pass=10, sfreq=500, high_band=0.05, low_band=100)
#Time2 = pd.DataFrame(Time1)
#Time2.reset_index(drop=True, inplace = True)
#data2= pd.DataFrame(channel)
#data2.reset_index(drop=True, inplace = True)
#data = pd.concat([Time2,data2],axis=1, ignore_index=True)
datak = pd.DataFrame(data1)
datak.columns = ['Time','channel1','channel2','channel3','channel4','channel5','channel6']
time = datak.Time
data = datak[np.abs(time) < Stop_time]
data.columns = ['Time','channel1','channel2','channel3','channel4','channel5','channel6']
timek = data.Time
channelk = data.channel1
#SNR = signaltonoise_dB(np.array(channelk))
#print(SNR)
plt.plot(timek,channelk)

data.to_csv(f'{path_root}/IMU_Shoulder-abduction_Shoulder.csv', index_label=False, index=False, header=None)

plt.show()


"""
plt.plot(Time,channel)
#plt.ylim(-0.01, 0.01)
plt.show()
"""
