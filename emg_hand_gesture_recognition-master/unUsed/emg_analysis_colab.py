# generic import
import numpy as np
from numpy import matlib

# mne import
from mne import Epochs
from mne.io import concatenate_raws
from mne.io import read_raw_bdf
from mne import find_events
from mne.io import RawArray
from scipy import signal

# pyriemann import
from pyriemann.estimation import Covariances
from pyriemann.utils.tangentspace import tangent_space
from pyriemann.utils.mean import mean_covariance

# sklearn imports
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis

# math
import math

#
from matplotlib import pyplot as plt

# load BDF files and concatenate them
raw_files = [read_raw_bdf('src/db/real%d.bdf' % i) for i in range(1, 11) ]
raw = concatenate_raws(raw_files)
raw.load_data()

# re-referencing with a electrode of A29
raw.set_eeg_reference(ref_channels=['A29'])

# define events
events = find_events(raw, stim_channel='Status')
event_dict = {'rest': 1, 'fist': 2, 'flexion': 3,
              'extension': 4, 'index_finger': 5, 'middle_finger': 6,
              'riger_finger': 7, 'little_finger': 8,
              'spread': 9, 'pinch all': 10}

n_channels = len(raw.ch_names)

# filtering with scipy
info = raw.info
x = raw.get_data()
# x = x[:10,:]
b, a = signal.iirfilter(4, np.array([20, 450])/(2048/2))
x_filtered = signal.lfilter(b, a, x, axis=0)

x_filtered = signal.lfilter(b, a, x[0, :8000], axis=0)

# filtering with real time manner
x1 = x[0, :4000]
x2 = x[0, 4000:8000]
np.equal(x[0, :8000], np.concatenate([x1, x2], axis=0)).all()
# zi = signal.lfilter_zi(b, a)
# zi = np.concatenate([x1[i, 0]*zi for i in range(10)]).reshape(32, -1)
# zi = np.concatenate([x1[i, 0] for i in range(10)]).reshape(32, -1)
# zi = matlib.repmat(zi, 10, 1)
x_filtered_realtime = np.zeros(x_filtered.shape)
x_filtered_1 = np.zeros(x1.shape)
x_filtered_2 = np.zeros(x2.shape)
tmp = signal.lfilter_zi(b, a)
zi = tmp

x_filtered_1, zi = signal.lfilter(b, a, x1, zi=zi*x1[0])
x_filtered_2, zi = signal.lfilter(b, a, x2, zi=zi*x2[0])
x_filtered_realtime = np.concatenate([x_filtered_1, x_filtered_2], axis=0)
print(np.equal(x_filtered, x_filtered_realtime).all())
plt.plot(x_filtered)
plt.plot(x_filtered_realtime)

plt.show()
a=1


# zi = np.zeros((n_channels, 32))
# for i in range(n_channels):
    # zi[i, :] = tmp * x1[i,0]
    # zi[i, :] = tmp

# for i in range(n_channels):
# x_filtered_1[i, :], zi[i, :] = signal.lfilter(b, a, x1[i, :], axis=0, zi=zi[i, :])
# x_filtered_2[i, :], zi[i, :] = signal.lfilter(b, a, x2[i, :], axis=0, zi=zi[i, :])

# print(np.equal(x_filtered(:,1), x_filtered_realtime(:,1)).all())

raw = RawArray(x_filtered, info)

# Extract epochs (Segments) during making hand gestures
epochs = Epochs(raw, events, tmin=0, tmax=3, event_id=event_dict,
                baseline=None, preload=True)

# get x and y
x = epochs.get_data()
labels = epochs.events[:, -1]-1

# delete unnecesarray variables
del raw, raw_files, epochs

def get_cov_from_epochs(x):
    winSize = math.floor(0.3 * 2048);
    winInc = math.floor(0.05 * 2048);
    st = 0;
    ed = winSize;
    c = []
    [nTotalTrial, nCh, nSeg] = x.shape;

    while True:
        if ed > nSeg:
            break
        c.append(Covariances().transform((x[:, :, st:ed])))
        st = st + winInc
        ed = ed + winInc
        # print('st: %d ed: %d' % (st, ed))

    return np.concatenate(c, axis=0)


# set indices of trials for training, and indices of channels to use
idxRep = [0, 1, 2]
idxChan = np.array([3, 4, 13, 14, 23, 25]) + 1

# compute covariances
c = get_cov_from_epochs(x[:, idxChan, :])

# labeling
nWin = int(c.shape[0] / x.shape[0])
y = [labels for _ in range(nWin)]
y = np.concatenate(y, axis=0)
r = [np.array([i for i in range(20) for _ in range(10)]) for _ in range(nWin)]
r = np.concatenate(r, axis=0)

# select indices of training/test datasets
idx_train = np.in1d(r, idxRep)
idx_test = ~np.in1d(r, idxRep)

# compute reference covaraince
c_ref = mean_covariance(c[idx_train, :, :]);

# extract features using tangent space mapping
x_tr = tangent_space(c[idx_train, :, :], c_ref);
y_tr = y[idx_train];

# fit LDA classifier
clf = LinearDiscriminantAnalysis()
clf.fit(x_tr, y_tr);

# test
x_te = tangent_space(c[idx_test, :, :], c_ref);
y_te = y[idx_test];
y_hat = clf.predict(x_te);

# compute accuracy
acc = np.sum(y_te == y_hat) / y_te.shape[0];
print(acc)