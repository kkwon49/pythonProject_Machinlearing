import os
import numpy as np


def load_data(file='test_seq_2s_data.npz'):
    root_location = os.getcwd()
    path = f'{root_location}/{file}'
    with np.load(path, allow_pickle=True) as f:
        X_train, X_test  = f['X_train'], f['X_test']
        y_train, y_test = f['y_train'], f['y_test']

        return (X_train, y_train), (X_test, y_test)

