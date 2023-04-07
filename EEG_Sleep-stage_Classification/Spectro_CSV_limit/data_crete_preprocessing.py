import os
import pandas as pd
import h5py
import cv2
import numpy as np
import matplotlib.pyplot as plt
import scipy.io
import sklearn.model_selection
from PIL import Image
import pandas as pd
import numpy as np
import os
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

import warnings
warnings.filterwarnings("ignore", category=np.VisibleDeprecationWarning)

def create_data():
    # 그냥 임시로 해논거 바꿔야하는거 맞음 높이 너비
    #folder = f'/Users/kang-kyukwon/Dropbox/KyuSleepDataShared/LearningData_Sleep_S100/SpectroCSV_limit_test/'
    folder = f'/Users/kang-kyukwon/Dropbox/Yeo_Lab/5. KyuSleepDataShared/LearningData_Test/Lab4_SpectroCSV_Limit/'
    """
    image dataset 만들때는 폴더 하나가 label 하나라고 보면 됨 
    이걸 보면 내 컴퓨터에는 Box_holding 이라는 폴더가 label 이다 라고 보면됨 
    그러면 총 8개의 label 이 있다 라고 보면 되는것!
    """
    # data labeling
    categorical = ['class0','class1','class2','class3','class4']
    num_classes = len(categorical)  # 총 갯수
    x = []
    y = []

    for index, categorical in enumerate(categorical):
        label = [0 for _ in range(num_classes)]
        label[index] = 1
        dir_ = f'{folder + categorical}/'
        for top, dir1, f in os.walk(dir_):
            for filename in f:
                location = rf'{dir_}//{filename}'
                print(location)
                seq = np.load(location)
                print(seq)
                seq = seq.astype("float32") / 255.

                #sc = StandardScaler()
                #seq = sc.fit_transform(seq)
                x.append(seq.reshape(seq.shape[0], seq.shape[1], seq.shape[2]))
                y.append(label)

    x = np.array(x)
    y = np.array(y)
    X_train, X_test, y_train, y_test = sklearn.model_selection.train_test_split(x,y, train_size=0.3, test_size=0.7,
                                                        shuffle=True, random_state=2021)
    print(np.array(X_train).shape)
    np.savez('test_csv_data_test_Lab4.npz', x_train=X_train, x_test=X_test, y_train=y_train, y_test=y_test)
    print('done!')

create_data()

"""
경로를 자기 directory file 위치에 맞춰서 경로를 설정해줄것 
ex) /home/lmsky/PycharmProjects/torch_practice/data_time/Box_holding.csv 로 가고싶을때 
main_root = /home/lmsky/PycharmProjects/torch_practice/
file = data_time/
os.chdir(file)  # file(data_time)이라는 directory 안쪽으로 접근  
path = f'{main_root}{file}' 
"""


