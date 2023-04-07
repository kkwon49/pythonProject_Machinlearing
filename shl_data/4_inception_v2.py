# MUSA MAHMOOD - Copyright 2018
# Python 3.6.5
# TF 1.12.0, Keras 2.2.4

# Imports:
import os
from time import time
import tensorflow as tf
print(tf.__version__)
import numpy as np
from keras import optimizers
from keras.callbacks import TensorBoard
from keras.layers import Conv1D, LeakyReLU, BatchNormalization, Concatenate, UpSampling1D, ZeroPadding1D
from keras.layers import Dropout, Input, AveragePooling1D, MaxPooling1D, ReLU, Cropping1D
from keras.models import load_model, Model
from scipy.io import savemat

import tf_shared_k as tfs

# Setup:
TRAIN = True
TEST = True
SAVE_PREDICTIONS = False
SAVE_HIDDEN = False
EXPORT_ANDROID = False

# Network Variables
min_units = 4  # Number of filters on first convolution layer.
learn_rate = 0.001
lr_decay_r = 0.0
batch_size = 8
epochs = 5

# Names/Labels:
# TODO: You may change model_detail to uniquely name variations in networks.
#  I put two variables as an example, but you may make this as complex as you like.
#  You may want to create different variables (e.g. for dropout rate) and concat to model_detail.
DATASET = 'shl_steth'
model_detail = "_inception.v2." + str(min_units) + "_" + str(learn_rate)

# These variables are set based on the dataset we are looking at.
num_channels = 1
num_classes = 3
data_directory_train = 'shl_labeled_seg/train'
data_directory_test = 'shl_labeled_seg/test'
# test_set = 'data/v2labtest_5c'

description = DATASET + model_detail  # TODO:

keras_model_name = description + '.h5'
model_dir = tfs.prep_dir('model_exports/')
keras_file_location = model_dir + keras_model_name

cuda_model_fname = DATASET + model_detail + '_cuda.h5'
nocuda_model_fname = DATASET + model_detail + '_nocuda.h5'

print("Keras Model File Location: ", keras_file_location)

output_folder = 'data_out/' + description + '/'
seq_length = 8000
input_length = seq_length
x_shape = [seq_length, num_channels]
y_shape = [seq_length, num_classes]

# Start Timer:
start_time_ms = tfs.current_time_ms()

# # Load pre-split dataset:
x_train = None
y_train = None
x_test = None
y_test = None
x_test0 = None
y_test0 = None

if TRAIN:
    x_train, y_train = tfs.load_data_v2(data_directory_train, x_shape, y_shape, 'X', 'Y')

if TEST:
    x_test, y_test = tfs.load_data_v2(data_directory_test, x_shape, y_shape, 'X', 'Y')
    # Load Test Data:
    # x_test0, y_test0 = tfs.load_data_v2(test_set, x_shape, y_shape, 'X', 'Y')


def build_annotator(input_channels=1, output_channels=1):
    def conv_op(layer_input, filters=1, filter_size=8, strides=2, padding='same', alpha=0.2):
        d = Conv1D(filters, filter_size, strides=strides, padding=padding)(layer_input)
        norm = BatchNormalization()(d)
        if alpha:
            return LeakyReLU(alpha=0.2)(norm)
        else:
            return ReLU()(norm)

    def inception_stem(layer_input, filters):
        s1 = conv_op(layer_input, filters=filters, filter_size=16, strides=2, alpha=0)
        s2 = conv_op(s1, filters=filters, filter_size=16, strides=1, alpha=0)  # , padding='valid'
        s3 = conv_op(s2, filters * 2, filter_size=16, strides=1, alpha=0)
        branch_0 = MaxPooling1D(pool_size=2)(s3)
        branch_1 = conv_op(s3, filters * 2, filter_size=16, strides=2, alpha=0)
        return Concatenate()([branch_0, branch_1])

    def conv_resnet_block(layer_input, filter_units):
        # SubBlock1 1: [1] conv + [3] conv + [5] conv:str2
        sb1_c1 = conv_op(layer_input, filters=filter_units, filter_size=2, strides=1)
        sb1_c2 = conv_op(sb1_c1, filters=filter_units * 2, filter_size=5, strides=1)
        sb1_c3 = conv_op(sb1_c2, filters=filter_units * 2, filter_size=7, strides=2)
        # SubBlock2 1: [1] conv + [5] conv:str2
        sb2_c1 = conv_op(layer_input, filters=filter_units, filter_size=1, strides=1)
        sb2_c2 = conv_op(sb2_c1, filters=filter_units, filter_size=5, strides=2)
        # SubBlock3: AveragePool[2]
        sb3_ap = AveragePooling1D(pool_size=2)(layer_input)
        # sb3_ap = MaxPooling1D(pool_size=2)(layer_input)
        return Concatenate()([sb1_c3, sb2_c2, sb3_ap])

    def deconv_layer(layer_input, skip_input, filters, f_size=4, dropout_rate=0):
        u = UpSampling1D(size=2)(layer_input)
        u = Conv1D(filters, f_size, strides=1, padding='same', activation='relu')(u)
        if dropout_rate:
            u = Dropout(dropout_rate)(u)
        u = BatchNormalization()(u)
        u = Concatenate()([u, skip_input])
        return u

    def upscale_layer(layer_input, filters, f_size=8, upscale_factor=2):
        u = UpSampling1D(size=upscale_factor)(layer_input)
        u = Conv1D(filters, f_size, strides=1, padding='same', activation='relu')(u)
        u = BatchNormalization()(u)
        return u

    # Input samples
    input_samples = Input(shape=(input_length, input_channels))

    # Stem:
    stem = inception_stem(input_samples, min_units)
    stem_padded = ZeroPadding1D(padding=(24, 24))(stem)

    # Downsampling:
    d1 = conv_resnet_block(stem_padded, min_units * 4)
    d2 = conv_resnet_block(d1, min_units * 4 * 2)
    d3 = conv_resnet_block(d2, min_units * 4 * 4)
    d4 = conv_resnet_block(d3, min_units * 4 * 8)

    # Now Upsample:
    u1 = deconv_layer(d4, d3, min_units * 4 * 4, f_size=8)
    u2 = deconv_layer(u1, d2, min_units * 4 * 2, f_size=8)
    u3 = deconv_layer(u2, d1, min_units * 4, f_size=8)
    u4 = upscale_layer(u3, 128, f_size=16)
    u5 = upscale_layer(u4, 64, f_size=16, upscale_factor=4)
    u6 = Cropping1D(cropping=(96, 96))(u5)
    output_samples = Conv1D(output_channels, kernel_size=8, strides=1, padding='same', activation='softmax')(u6)
    k_model = Model(input_samples, output_samples)
    adam = tf.keras.optimizers.Adam(lr=learn_rate, beta_1=0.9, beta_2=0.999, epsilon=1e-08, decay=lr_decay_r)
    k_model.compile(loss='categorical_crossentropy', optimizer=adam, metrics=['accuracy'])
    return k_model


model = []
if os.path.isfile(keras_file_location):
    print("Loading Model From File: ", keras_file_location)
    model = load_model(keras_file_location)
else:
    print("Building Annotator from Code:")
    model = build_annotator(input_channels=num_channels, output_channels=num_classes)
print(model.summary())

tb = TensorBoard(log_dir="logs/{}".format(time()))

if TRAIN:
    model.fit(x_train, y_train, batch_size=batch_size, epochs=epochs, verbose=1, validation_data=(x_test, y_test),
              callbacks=[tb])
    model.save(keras_file_location)

if TEST and model is not None:
    score, acc = model.evaluate(x_test, y_test, batch_size=128, verbose=1)
    print('Test score: {} , Test accuracy: {}'.format(score, acc))
    y_prob = model.predict(x_test)
    tfs.print_confusion_matrix(y_prob, y_test)

if SAVE_PREDICTIONS:
    # predict
    yy_probabilities = model.predict(x_test, batch_size=batch_size)
    yy_predicted = tfs.maximize_output_probabilities(yy_probabilities)
    data_dict = {'x_val': x_test, 'y_val': y_test, 'y_prob': yy_probabilities, 'y_out': yy_predicted}
    savemat(tfs.prep_dir(output_folder) + description + '.mat', mdict=data_dict)

    # yy_probabilities = model.predict(x_test0, batch_size=batch_size)
    # yy_predicted = tfs.maximize_output_probabilities(yy_probabilities)
    # data_dict = {'x_val': x_test0, 'y_val': y_test0, 'y_prob': yy_probabilities, 'y_out': yy_predicted}
    # savemat(tfs.prep_dir(output_folder) + 'lab_data' + '.mat', mdict=data_dict)

if SAVE_HIDDEN:
    layers_of_interest = ['zero_padding1d_1', 'concatenate_2', 'concatenate_3', 'concatenate_4', 'concatenate_5',
                          'concatenate_6', 'concatenate_7', 'concatenate_8', 'batch_normalization_28', 'cropping1d_1',
                          'conv1d_30']  # Using crop as output of upscale_layer #2
    np.random.seed(0)
    rand_indices = np.random.randint(0, x_test.shape[0], 125)
    spec_indices = np.array([10000, 10002, 10074, 10083, 10433, 11203, 11217, 598,
                             503, 558, 414, 8214, 8224, 8228, 8239])
    print('Saving hidden layers: ', layers_of_interest)
    tfs.get_keras_layers(model, layers_of_interest, x_test[spec_indices], y_test[spec_indices],
                         output_dir=tfs.prep_dir('data_out/hidden_layers/'),
                         fname='h_' + description + '.mat')

if EXPORT_ANDROID:
    if model is None and os.path.isfile(keras_file_location):
        model = load_model(keras_file_location)
        print(model.summary())
    tfs.export_model_keras(keras_file_location, export_dir=tfs.prep_dir("graph"), model_name=description,
                           sequential=False)

print('Elapsed Time (ms): ', tfs.current_time_ms() - start_time_ms)
print('Elapsed Time (min): ', (tfs.current_time_ms() - start_time_ms) / 60000)
