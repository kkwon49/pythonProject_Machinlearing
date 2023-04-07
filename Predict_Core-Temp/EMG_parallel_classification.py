import pandas as pd
import tensorflow as tf
import numpy as np
import os
import datetime
import seaborn as sns

from tensorflow.keras.layers import Dense, Dropout, Flatten, Conv1D
from tensorflow.keras.layers import LSTM, MaxPooling1D, Reshape, Input, BatchNormalization
from tensorflow.keras.models import Model
from tensorflow.keras.models import load_model
from tensorflow.keras.optimizers import Adam
from confusion_shared import print_confusion_matrix_v2
from tensorflow.keras import layers
import matplotlib.pyplot as plt
from emg_load_data import load_data
from confusion_shared import logw
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay
import itertools
from scikitplot.metrics import plot_confusion_matrix



# 세부 파라미터 조정
num_classes = 4
batch_size = 2 # 64~128
epochs = 50  # 10~50
learning_rate = 0.002
tf.random.set_seed(0)
np.random.seed(0)
labels = ["1","2","3","4"]

(X_train, y_train), (X_test, y_test) = load_data()

# file directory creat in file name is result
fnpath = '/Users/kang-kyukwon/PycharmProjects/pythonProjectEMG/Predict_Core-Temp/result/'
try:
    os.mkdir(fnpath)
except OSError as e:
    print(f'An error has occurred. Continuing anyway: {e}')

# file create location
filename = f'{os.getcwd()}/result/classification_output.txt'
file = open(filename, 'a+')

logw(file, 'start -> {:%Y-%m-%d %H:%M:%S}'.format(datetime.datetime.now()))

logw(file, f'Shape checking X_test : {X_test.shape}')
logw(file, f'Shape checking X_train : {X_train.shape}')

input_shape = Input(shape=[X_train.shape[1], X_train.shape[2]])
activate_relu = tf.keras.layers.LeakyReLU()


# 범용 활성화함수
# activation 입니다 False 라고 한 이유는 각 activation function parameter False 는 사용안함 True 하면 사용
def activation_optional(input_size, leaky_relu=True):
    d = Conv1D(8, 16, 2, padding="same")(input_size)
    norm = BatchNormalization()(d)
    if leaky_relu:
        activate = tf.keras.layers.LeakyReLU(alpha=0.3)(norm)
    else:
        activate = tf.keras.layers.ReLU()(norm)
    return MaxPooling1D(1)(activate)

def cnn_model_arch1():
    cnn1d = Conv1D(24, 16, 2, padding="same", activation=activate_relu)(input_shape)
    cnn1d = activation_optional(cnn1d)
    flatten = Flatten()(cnn1d)
    dense1 = Dense(10, activation=activate_relu)(flatten)

    return dense1

def cnn_model_arch2():
    cnn1d = Conv1D(24, 16, 2, padding="same", activation=activate_relu)(input_shape)
    cnn1d = activation_optional(cnn1d)
    flatten = Flatten()(cnn1d)
    dense1 = Dense(10, activation=activate_relu)(flatten)

    return dense1

def lstm_modeling():
    lstm = (LSTM(10, activation="tanh", return_sequences=True))(input_shape)
    flatten_lstm = Flatten()(lstm)

    return flatten_lstm


# cnn1 cnn 2 lstm concatnate
def data_concatnate():
    model_concat = tf.keras.layers.concatenate([cnn_model_arch2(),cnn_model_arch1()])
    #norm = BatchNormalization()(model_concat)
    dropout_concat = Dropout(0.2)(model_concat)
    finally_dense = (Dense(num_classes, activation='softmax'))(dropout_concat)
    k_model = Model(input_shape, finally_dense)
    tf.keras.utils.plot_model(k_model, 'modeling_data_64_32_batch_drop.png', show_shapes=True)
    k_model.summary()

    return k_model


def model_fitting():
    k_model = data_concatnate()
    # optimizer

    adam = Adam(learning_rate, epsilon=1e-6, decay=2e-5, amsgrad=True)
    # 과적합 방지
    callback = tf.keras.callbacks.EarlyStopping(monitor='val_acc', patience=10, restore_best_weights=True)
    k_model.compile(loss='categorical_crossentropy', optimizer=adam, metrics=['acc'])
    # modeling fitting
    history = k_model.fit(X_train, y_train, epochs=epochs, batch_size=batch_size,
                          validation_data=(X_test, y_test),
                          verbose=1 ,callbacks=[callback])
    print(k_model.save('cnn_64_batch_dropout.h5'))
    logw(file, f"Model Test loss -> {k_model.evaluate(X_test, y_test)[0]}, "
               f"Model Test accuracy -> {k_model.evaluate(X_test, y_test)[1]}")
    # prediction model
    start = datetime.datetime.now()
    prediction_result = k_model.predict(X_test)
    end = datetime.datetime.now()
    time = end-start
    #print("Computation time:", time)
    logw(file, 'finish -> {:%Y-%m-%d %H:%M:%S}'.format(datetime.datetime.now()))
    prediction_labels = np.argmax(prediction_result, axis=-1)
    test_label = np.argmax(y_test, axis=-1)
    matrix = confusion_matrix(test_label, prediction_labels, normalize='true')
    print(f"acc_train : {k_model.evaluate(X_train, y_train)}")
    print(f"acc_test : {k_model.evaluate(X_test, y_test)}")



    # confusion matrix

    def confusion_matrix_visualization():
        confusion_frame = pd.DataFrame(matrix, columns=['1','2','3','4'],
                                   index=['1','2','3','4'])
        plt.figure(figsize=(7,5))
        sns.heatmap(confusion_frame, cmap="Blues", annot=True)
        plt.show()




# model training graph visualization
    def visualization():
        fig, loss_ax = plt.subplots()

        acc_ax = loss_ax.twinx()

        loss_ax.plot(history.history['loss'], 'y', label='train loss')
        loss_ax.plot(history.history['val_loss'], 'r', label='val loss')

        acc_ax.plot(history.history['acc'], 'b', label='train acc')
        acc_ax.plot(history.history['val_acc'], 'g', label='val acc')

        loss_ax.set_xlabel('epoch')
        loss_ax.set_ylabel('loss')
        acc_ax.set_ylabel('accuray')

        loss_ax.legend(loc='upper left')
        acc_ax.legend(loc='lower left')

        plt.show()


    # confusion matrix making text file
    def print_matrix():
        confusion = print_confusion_matrix_v2(prediction_result, y_test)
        logw(file, f'Confusion Matrix -> \n' + np.array2string(confusion))

    visualization()
    print_matrix()
    confusion_matrix_visualization()



def main():
    model_fitting()

main()
