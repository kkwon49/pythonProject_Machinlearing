import glob
import os

import scipy.io
from PIL import Image
import numpy as np

import pandas as pd
import matplotlib.pyplot as plt

"""
Data is each other data checking data of shape (완료)
Data concatenate 하기 
"""
# 최상단 위치
for j in range(5,30):
    main_root = f'/Users/kang-kyukwon/Dropbox/KyuSleepDataShared/LearningData_Sleep/{j}_SpectroPNG/class4'


    def location():
        emg_data = []
        for data in glob.glob(os.path.join(main_root, '*.png')):
            emg_data.append(data)
            emg_data.sort()

        return emg_data


    def data_move():
        data = location()
        if len(data)>0:
            for i in range(0, len(data)):
                structure = Image.open(f'{data[i]}')
                structure = structure.resize((256,256))
                structure.save(f"/Users/kang-kyukwon/Dropbox/KyuSleepDataShared/LearningData_Sleep_Updated/Spectro_PNG/class4/s{j}_4_ep{i}.png", format='png')


    data_move()
