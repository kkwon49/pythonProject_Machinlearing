import time
import numpy as np
import tensorflow as tf

from emg_load_data import load_data
from tensorflow.keras.models import load_model

(X_train, y_train), (X_test, y_test) = load_data()
k_model = load_model('cnn_64_batch_dropout.h5')

# Convert the model.
converter = tf.lite.TFLiteConverter.from_keras_model(k_model)
tflite_model = converter.convert()

# Save the model.
with open('model.tflite', 'wb') as f:
  f.write(tflite_model)