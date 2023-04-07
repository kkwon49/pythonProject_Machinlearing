import os
import numpy as np
import pandas as pd
import pathlib
import matplotlib.pyplot as plt
from multiprocessing import Pool, cpu_count

from scipy.stats import zscore
from scipy.interpolate import interp1d, interpn
from scipy.signal import butter, sosfiltfilt, savgol_filter, medfilt, stft

def normalize(x, nan_policy='raise', axis=0):
    return zscore(x, nan_policy=nan_policy, axis=axis)

def multiprocess(f, x):
    result = None
    with Pool(min(len(x), cpu_count()-1)) as p:
        result = p.map(f, x)
    return result

def med_sg(x, med_size, sg_size, sg_order=4):
    if sg_size <= 1:
        return medfilt(x, kernel_size=med_size)
    return savgol_filter(medfilt(x, kernel_size=med_size), sg_size, polyorder=sg_order)

def pickle(x, output:pathlib.Path):
    if str(output) not in os.listdir():
        os.mkdir(output)
    with open(output, 'wb') as f:
        pickle.dump(x, f)

def load_csv(path, use_numpy=True, skip_on_failure=True):
    """Loads the .csv file at `path`. Returns a pandas dataframe if `use_numpy`
    is `True` and a pandas dataframe otherwise. Defaults to `True`."""
    on_bad_lines = 'skip' if skip_on_failure else 'error'
    
    try:
        data = pd.read_csv(path, on_bad_lines=on_bad_lines, dtype=float)
    except Exception as e:
        print(f"Failed loading {path}: ", e)
    else:
        if use_numpy:
            return data.to_numpy()
        
        return data

def find_csv(root=None, include:str=None, return_tree:bool=False) -> list:
    """Recursively explores through the file system starting at `root`, 
    finding all .csv files through the tree. Will include only those
    files with `include` in the file name, or all .csv files by default.
    If `return_tree` is `True`, the results are returned as a dictionary
    matching the file system's structure. If Returns built-in `pathlib`
    objects.
    
    If `root` is not provided, defaults to current working directory.

    """
    files = []
    if root is None:
        root = os.getcwd()

    if not os.path.isdir(root):
        raise ValueError("Invalid root!")

    for element in os.listdir(root):
        new_path = pathlib.Path(root, element)
        if os.path.isdir(new_path):
            new_files = find_csv(new_path, include, return_tree)
            [files.append(x) for x in new_files if len(new_files) > 0]
        elif ((include is not None and include in element and ".csv" in element)
           or (include is None and ".csv" in element)):
            files.append(new_path)

    return files

def filt(x, filter_freq, fs, mode:str, order:int=3):
    '''Applies an `order`-th order butterworth filter. `mode` 
    (`high`, `low`, `bandpass`) controls the filter design.
    Does not replace existing patient data'''
    sos  = butter(order, filter_freq, mode, output='sos', fs=fs)
    return sosfiltfilt(sos, x, axis=0)

def movmean(y, window_size):
    N = window_size
    return np.convolve(y, np.ones(N)/N, mode='same')

def interp1(x_orig, y_orig, x_new):
    f = interp1d(x_orig, y_orig)
    return f(x_new)


def density_scatter(x, y, ax=None, sort=True, bins=20, **kwargs ):
    """ Scatter plot colored by 2d histogram"""
    if ax is None :
        _ , ax = plt.subplots()
    data , x_e, y_e = np.histogram2d(x, y, bins=bins, density=True )
    z = interpn((0.5*(x_e[1:] + x_e[:-1]), 
                 0.5*(y_e[1:] + y_e[:-1])), 
                  data, np.vstack([x,y]).T, method="splinef2d", bounds_error=False)
    #To be sure to plot all data
    z[np.where(np.isnan(z))] = 0.0
    
    # Sort the points by density, so that the densest points are plotted last
    if sort :
        idx = z.argsort()
        x, y, z = x[idx], y[idx], z[idx]
    ax.scatter(x, y, c=z, **kwargs)
    return ax, z

def imshow(im):
    x = np.arange(im.shape[1])
    y = np.arange(im.shape[0])
    plt.pcolormesh(x, y, im, vmin=0, vmax=10, shading='gouraud')
    plt.show()

def spectrogram(x, fs, show=False):
    f, t, Zxx = stft(x, fs, nperseg=400, noverlap=350)
    Z_abs = np.abs(Zxx)
    vmax = np.mean(Z_abs) + 3*np.std(Z_abs) 
    if show:
        plt.pcolormesh(t, f*60, Z_abs, vmin=0, vmax=vmax, shading='gouraud')
        plt.ylabel('Frequency [Hz]')
        plt.xlabel('Time [sec]')
        plt.show()

    return t, f, Zxx

