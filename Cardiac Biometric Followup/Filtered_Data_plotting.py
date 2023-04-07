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

#fig, axs = plt.subplots(1, sharex = True, sharey=False)
path_folder = f'/Users/kang-kyukwon/PycharmProjects/pythonProjectEMG/Cardiac Biometric Followup/CleanWAV - 2_Output_mono.csv'
data = pd.read_csv(path_folder, header=0)
print(data)
data.columns = ['Time','channel']
plt.plot(data.Time,data.channel)
plt.show()

