import pandas as pd
import numpy as np
import os
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import MinMaxScaler

import warnings
warnings.filterwarnings("ignore", category=np.VisibleDeprecationWarning)
def create_data():
    folder = rf'/Users/kang-kyukwon/Downloads/Exo_Data/Test2/Shoulder_Abduction-B/'
    """
    image dataset 만들때는 폴더 하나가 label 하나라고 보면 됨 
    이걸 보면 내 컴퓨터에는 Box_holding 이라는 폴더가 label 이다 라고 보면됨 
    그러면 총 8개의 label 이 있다 라고 보면 되는것!
    """
    # data labeling
    categorical = ['Rest','On-set','Activation']
    num_classes = len(categorical)  # 총 갯수
    x = []
    y = []

    for index, categorical in enumerate(categorical):
        label = [0 for _ in range(num_classes)]
        label[index] = 1
        dir_ = rf'{folder + categorical}'
        print(dir_)
        for top, dir1, f in os.walk(dir_):
            for filename in f:
                location = rf'{dir_}//{filename}'
                print(location)
                seq = pd.read_csv(location, header=None)
                seq = np.array(seq).astype("float32") / 255.

                sc = StandardScaler()
                #sc=MinMaxScaler()
                seq = sc.fit_transform(seq)
                #print(seq.shape)
                x.append(np.array(seq).reshape(seq.shape[0], seq.shape[1]))
                print(np.array(x).shape)
                y.append(label)

    X_train, X_test, y_train, y_test = train_test_split(x, y, train_size=0.7, test_size=0.3,
                                                          shuffle=True, random_state=2021)
    #print(np.array(X_train))
    print(np.array(X_test).shape)
    print(np.array(X_train).shape)
    np.savez('Shoulder_Abduction_B_3class.npz', X_train=X_train, X_test=X_test, y_train=y_train, y_test=y_test)
    print('done!')


create_data()