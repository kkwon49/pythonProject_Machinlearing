# biosignals
Easy-to-use, cloud-integrated biosignal processing. 

Examples:
```python
import numpy as np
import pandas as pd
from biosignals.processing.ecg_processing import EcgProcessing

# load data
raw_data = pd.read_csv(ECG_FILE_NAME).to_numpy()
ecg_times = raw_data[:,0]
ecg = raw_data[:,1]

# define ECG processing object
ecg_proc = EcgProcessing(sample_rate=SAMPLE_RATE)

# process ECG
hr_times, hr = ecg_proc.heart_rate(ecg_times, ecg) # HR
rr_times, rr = ecg_proc.respiration_rate(ecg_times, ecg) # RR
ecg_snr = ecg_proc.snr(ecg)
denoised_ecg = ecg_proc.denoise(ecg)
```

## Installing
1. Install Git CLI using [these](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) instructions for your operating system. Once installed, follow [these](https://git-scm.com/book/en/v2/Git-Basics-Getting-a-Git-Repository) instructions to pull from this repository. This code is now useable in the local directory as shown in the above examples. If a module import error occurs or if you do not have Python, continue with the following steps.

2. Ensure a [Python runtime](https://www.python.org/downloads/) is installed by running `python --version` in the command prompt (which should print the local Python version if installed correctly). See [Anaconda](https://www.anaconda.com/) installation or similar for easy Python package/environment management. 

3. Open command prompt (or the package manager terminal, if using one), navigate to the local repository from step 1, and enter `pip install -r requirements.txt`. This will install the necessary packages for this project, and the code can be as shown above.

## Cloud Integration
Cloud storage data uploaded by the Flutter App can be downloaded using the `CloudSync` module, which organizes the saved files in a format suitable for batch data processing with the `PatientSeries` and `PatientData` modules.
```python
from biosignals.data.db_sync import CloudSync
from biosignals.signals import Signal
from pathlib import Path

cloud_sync = CloudSync(projects=["Choa Patch"])
cloud_sync.sync(destination=Path('test_data'))
```
This will establish a local file tree that will be updated with the same commands as data is uploaded over time, e.g. during clinical trials. The `sync` function reports the number of downloaded files for each patient ID:
```console
Project: Choa patch
6: 26
2: 4
3: 4
```

## Batch Data Processing
The file structure produced by the `sync` function can be used for clinical data organization and processing. For example,
```python
from biosignals.data.patient_data import PatientData
from biosignals.data.patient_series import PatientSeries
from biosignals.signals import Signal
from pathlib import Path

choa_path = Path('data', 'Choa Patch')
series = PatientSeries.gather(choa_path)
```
assigns to `series` a list of `PatientSeries` objects for the given project root (in this case, `./data/Choa Patch`). Each `PatientSeries` contains all uploads from a patient for that project. Each upload is contained within a `PatientData` object that allows for high-level manipulation of the contained waveform data, or low-level access to the data directly. The uploads can be accessed via the `trials` field for each `PatientSeries`. `PatientSeries` tries to group its `PatientData` uploads by the date and time they were uploaded to quickly establish a timeline of patient activity and for effective chronological processing of data. For example,

```python
series[0].trials
```

yields

```console
{ 
  datetime.datetime(2023, 1, 5, 17, 48, 50): [<biosignals.data.patient_data.PatientData at 0x1fa353d85b0>,
                                              <biosignals.data.patient_data.PatientData at 0x1fa353d8820>,
                                              <biosignals.data.patient_data.PatientData at 0x1fa353d8c70>],
  datetime.datetime(2023, 1, 5, 17, 50, 54): [<biosignals.data.patient_data.PatientData at 0x1fa353d8c40>,
                                              <biosignals.data.patient_data.PatientData at 0x1fa353d91b0>,
                                              <biosignals.data.patient_data.PatientData at 0x1fa353d8700>],
  datetime.datetime(2023, 1, 12, 17, 0, 45): [<biosignals.data.patient_data.PatientData at 0x1fa353d9360>],
  datetime.datetime(2023, 1, 12, 17, 3, 15): [<biosignals.data.patient_data.PatientData at 0x1fa353d8e50>],
  ...
}
```

Alternatively, if only a single signal is needed, the `only` function will filter the above trials to only include uploads of that signal:
```python
series[0].only(Signal.ECG)
```

Each resulting datetime-data pair has only one upload, corresponding to the single ECG file sent by this patient at each upload:

```console
{
  datetime.datetime(2023, 1, 5, 17, 48, 50): <biosignals.data.patient_data.PatientData at 0x1fa353d8820>,
  datetime.datetime(2023, 1, 5, 17, 50, 54): <biosignals.data.patient_data.PatientData at 0x1fa353d91b0>,
  datetime.datetime(2023, 1, 13, 10, 36, 42): <biosignals.data.patient_data.PatientData at 0x1fa353d87c0>
  ...  
}
```
These results can be readily iterated through with the Python built-in `items()` function:

```python
ecg_uploads = series[0].only(Signal.ECG)
for date_time, patient_data in ecg_uploads.items():
    ecg_t = patient_data[:,0]
    ecg = patient_data[:,1]

    # get biosignal results
    hr_result = ecg_proc.heart_rate(ecg_t, ecg)
    rr_result = ecg_proc.respiration_rate(ecg_t, ecg)
    hrv_result = ecg_proc.heart_rate_variability(ecg_t, ecg)
    snr_result = ecg_proc.snr(ecg)
```

## Bioradio Data
Comma-separated values exported from the Bioradio can be loaded by the library, which automatically parses the string datetime to a UNIX timestamp - the same kind saved the Flutter app:

```python
from pathlib import Path
from biosignals.data import BioradioData

csv_path = Path("bioradio.csv") # your csv path here, either a Path or str
Bioradio.load()
```

This returns a pandas dataframe, allowing for more sophisticated processing:

```console
Real Time	ECG    	        HR	PPG HR         SpO2 
1.676657e+09	-0.001326	511	79.691154	127
1.676657e+09	-0.001331	511	79.691154	127
1.676657e+09	-0.001332	511	79.691154	127
1.676657e+09	-0.001335	511	79.691154	127
1.676657e+09	-0.001336	511	79.691154	127
...	...	...	...	...	...
1.676658e+09	-0.002750	67	79.334709	98
1.676658e+09	-0.002741	67	79.320061	98
1.676658e+09	-0.002741	67	79.320061	98
1.676658e+09	-0.002742	67	79.320061	98
1.676658e+09	-0.002744	67	79.320061	98
```