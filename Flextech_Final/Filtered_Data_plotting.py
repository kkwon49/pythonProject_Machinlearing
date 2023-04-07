import os
import pandas as pd
import glob

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

path_root = '/Users/kang-kyukwon/Downloads/Exo_Data/'
sub_root = 'Raw/'
sub_root1 = 'Editted/'
sub_root2 = '601'
Start_time = 1673639424
#Start_time = 1673640780
#Stop_time = 1671587424
emg_proc = EmgProcessing(sample_rate=500)
data1 = pd.read_csv(f'{path_root}{sub_root}{sub_root2}/EMG_E8/EMG.csv', header=0)
#data = pd.read_csv(f'{path_root}{filename1}.csv', header=0)
data1 = pd.DataFrame(data1)
data1.columns = ['Time', 'channel']
time = data1.Time
data1 = data1[ np.abs(time) > Start_time]
#data1 = data1[ np.abs(time) < Stop_time]
Time1 = data1.Time
channel = data1.channel
channel = emg_proc.passband_filt(channel)
#channel = hilbert(channel)
channel = abs(channel)
low_pass = 10 / 250
b2, a2 = sp.signal.butter(4, low_pass, btype='lowpass')
channel1 = sp.signal.filtfilt(b2, a2, channel)
#channel = filteremg(channel, low_pass=10, sfreq=500, high_band=0.05, low_band=100)

data2 = pd.read_csv(f'{path_root}{sub_root}{sub_root2}/EMG_E3/EMG.csv', header=0)
#data = pd.read_csv(f'{path_root}{filename1}.csv', header=0)
data2 = pd.DataFrame(data2)
data2.columns = ['Time', 'channel']
time = data2.Time
data2 = data2[ np.abs(time) > Start_time]
#data1 = data1[ np.abs(time) < Stop_time]
Time2 = data2.Time
channel = data2.channel
channel = emg_proc.passband_filt(channel)
channel = hilbert(channel)
channel = abs(channel)
low_pass = 10 / 250
b2, a2 = sp.signal.butter(4, low_pass, btype='lowpass')
channel2 = sp.signal.filtfilt(b2, a2, channel)

data3= pd.read_csv(f'{path_root}{sub_root}{sub_root2}/EMG_K0/EMG.csv', header=0)
#data = pd.read_csv(f'{path_root}{filename1}.csv', header=0)
data3 = pd.DataFrame(data3)
data3.columns = ['Time', 'channel']
time = data3.Time
data3 = data3[ np.abs(time) > Start_time]
#data1 = data1[ np.abs(time) < Stop_time]
Time3 = data3.Time
channel = data3.channel
channel = emg_proc.passband_filt(channel)
#channel = hilbert(channel)
channel = abs(channel)
low_pass = 10 / 250
b2, a2 = sp.signal.butter(4, low_pass, btype='lowpass')
channel3 = sp.signal.filtfilt(b2, a2, channel)

data4 = pd.read_csv(f'{path_root}{sub_root}{sub_root2}/EMG_K1/EMG.csv', header=0)
#data = pd.read_csv(f'{path_root}{filename1}.csv', header=0)
data4 = pd.DataFrame(data4)
data4.columns = ['Time', 'channel']
time = data4.Time
data4 = data4[ np.abs(time) > Start_time]
#data1 = data1[ np.abs(time) < Stop_time]
Time4 = data4.Time
channel = data4.channel
channel = emg_proc.passband_filt(channel)
#channel = hilbert(channel)
channel = abs(channel)
low_pass = 10 / 250
b2, a2 = sp.signal.butter(4, low_pass, btype='lowpass')
channel4 = sp.signal.filtfilt(b2, a2, channel)
#channel = filteremg(channel, low_pass=10, sfreq=500, high_band=0.05, low_band=100)

data5 = pd.read_csv(f'{path_root}{sub_root}{sub_root2}/EMG_K8/EMG.csv', header=0)
#data = pd.read_csv(f'{path_root}{filename1}.csv', header=0)
data5 = pd.DataFrame(data5)
data5.columns = ['Time', 'channel']
time = data5.Time
data5 = data5[ np.abs(time) > Start_time]
#data1 = data1[ np.abs(time) < Stop_time]
Time5 = data5.Time
channel = data5.channel
channel = emg_proc.passband_filt(channel)
#channel = hilbert(channel)
channel = abs(channel)
low_pass = 10 / 250
b2, a2 = sp.signal.butter(4, low_pass, btype='lowpass')
channel5 = sp.signal.filtfilt(b2, a2, channel)
#channel = filteremg(channel, low_pass=10, sfreq=500, high_band=0.05, low_band=100)


fig, (ax1, ax2, ax3, ax4, ax5) = plt.subplots(5, 1)
#ax1.set_xlim(0,200000)
ax1.plot( channel1, color='limegreen')
#ax2.set_xlim(0,200000)
ax2.plot( channel2, color='violet')
ax3.plot(channel3, color='red')
ax4.plot(channel4, color='blue')
ax5.plot( channel5, color='brown')

plt.show()

"""
plt.plot(Time,channel)
#plt.ylim(-0.01, 0.01)
plt.show()
"""
