import datetime
import os
import random
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
from sklearn.metrics import confusion_matrix
from tensorflow.keras.models import load_model
import numpy as np
import tensorflow as tf
from tensorflow.keras.layers import Dense, Flatten, Dropout
from tensorflow.keras.layers import LSTM, Reshape, Input
from tensorflow.keras.layers import Conv2D, BatchNormalization
from tensorflow.keras.utils import to_categorical
from tensorflow.keras.datasets import mnist

from confusion_shared import print_confusion_matrix_v2
from confusion_shared import logw

from eeg_load_data_Test import load_data

# mnist dataset 의 간단한 데이터 전처리
(X_train, y_train), (X_test, y_test) = load_data()
k_model = load_model('cnn_64_batch_dropout_final.h5',custom_objects={'LeakyReLU': tf.keras.layers.LeakyReLU()})
#custom_objects={'LeakyReLU': tf.keras.layers.LeakyReLU()}
# normalization deep learning early training speed calculation
# 0 ~ 1 scale, channel data
X_train = X_train.astype('float32') / 255.
X_test = X_test.astype('float32') / 255.
X_train = np.reshape(X_train, (len(X_train), 64, 64, 3))  # 'channels_firtst'이미지 데이터 형식을 사용하는 경우 이를 적용
X_test = np.reshape(X_test, (len(X_test), 64, 64, 3))  # 'channels_firtst'이미지 데이터 형식을 사용하는 경우 이를 적용
print(f"Shape checking X_train image: {X_train.shape}")
print(f"Shape checking X_test image: {X_test.shape}")

# 라벨링 mnist 는 0~9 총 10개
#y_train = to_categorical(y_train, 5)
#y_test = to_categorical(y_test, 5)

# file directory creat in file name is result
fnpath = 'result/'
try:
    os.mkdir(fnpath)
except OSError as e:
    print(f'An error has occurred. Continuing anyway: {e}')

# file create location
filename = f'{os.getcwd()}/result/classification_output_prediction_Lab2.txt'
file = open(filename, 'a+')

logw(file, f'Shape checking X_test image: {X_test.shape}')
logw(file, f'Shape checking X_train image: {X_train.shape}')



prediction_result = k_model.predict(X_test)
prediction_labels = np.argmax(prediction_result, axis=-1)
print(prediction_labels)
test_label = np.argmax(y_test, axis=-1)
print(test_label)

logw(file, f'Prediction_labels: {prediction_labels}')
logw(file, f'Test_labels: {test_label}')

def classes_predict():
    result = 0
    loss = 0
    for n in range(0, len(test_label)):
        if prediction_labels[n] == test_label[n]:
            result += 1
        elif prediction_labels[n] != test_label[n]:
            loss += 1
    total = result + loss
    print(f'Model classification result -> {result/total} ||| Model classification loss -> {loss/total}')
    logw(file, f'Model classification result -> {result/total} ||| Model classification loss -> {loss/total}')
    score, acc = k_model.evaluate(X_test, y_test, batch_size=128, verbose=1)

    # prediction model
    matrix = confusion_matrix(test_label, prediction_labels, normalize='true')


    # confusion matrix making text file
    def print_matrix():
        confusion = print_confusion_matrix_v2(prediction_result, y_test)
        logw(file, f'Model Test loss -> {score} , Model Test accuracy -> {acc}')
        logw(file, f'Confusion Matrix -> \n' + np.array2string(confusion))

    def confusion_matrix_visualization():
        confusion_frame = pd.DataFrame(matrix, columns=['class0','class1','class2','class3','class4'],
                                   index=['class0','class1','class2','class3','class4'])
        plt.figure(figsize=(7,5))
        sns.heatmap(confusion_frame, cmap="Blues", annot=True)
        plt.show()

    print_matrix()
    confusion_matrix_visualization()

classes_predict()
