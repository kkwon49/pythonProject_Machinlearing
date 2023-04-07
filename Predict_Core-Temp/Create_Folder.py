import os

def createFolder(directory):
    try:
        if not os.path.exists(directory):
            os.makedirs(directory)
    except OSError:
        print('Error: Creating directory. ' + directory)


for k in range(0,10):
    createFolder(f'/Users/kang-kyukwon/PycharmProjects/pythonProjectEMG/EMG_8BM_Classification/Raw_Data/data_time/Horizontal/{k}')
