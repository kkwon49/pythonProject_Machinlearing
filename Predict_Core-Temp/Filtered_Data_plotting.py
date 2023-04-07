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

fig, axs = plt.subplots(4, sharex = True, sharey=False)
for i in range(1,5):
    path_folder = f'/Users/kang-kyukwon/PycharmProjects/pythonProjectEMG/EMG_8BM_Classification/Raw_Data/data_time/Horizontal/1/EMG_C{i}_1.csv'
    data = pd.read_csv(path_folder)
    axs[i-1].plot(data.time,data.channel)
plt.show()

