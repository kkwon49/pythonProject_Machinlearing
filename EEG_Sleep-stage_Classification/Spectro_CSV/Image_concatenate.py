from PIL import Image
import glob
import os

import pandas as pd
import matplotlib.pyplot as plt

"""
Data is each other data checking data of shape (완료)
Data concatenate 하기 
"""
# 최상단 위치
main_root = '/home/lmsky/PycharmProjects/torch_practice/'
# 하위 위치
file = 'data_preprocessing/210814_emg_training_session/'
os.chdir(file)
# 현재 디렉토리 파일 list 형태로 보여줌
location = os.getcwd()
# 현재 디렉토리 파일 하위 폴더 위치 보여줌
root = os.listdir(location)
segment_root = [f'{main_root}{file}{file_name}/1st/' for file_name in root]
segment_root.sort()

def location():
    global segment_root
    emg_data = []
    for loc in segment_root:
        data = glob.glob(loc + '*.csv')
        data.sort()
        emg_data.append(data)
    return emg_data


def image_visualization():
    data = root
    data.sort()
    for i in data:
        # 경로 자기 디렉터리 순서로 바꿔주세요
        path_folder = f'{main_root}{file}{i}/1st/'
        path_folder2 = f'{main_root}img_direct/{i}/'
        print(path_folder2)
        root_data = os.listdir(path_folder)
        root_data.sort()



image1 = Image.open()

