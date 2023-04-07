import pathlib
from biosignals.data.patient_data import PatientData
from biosignals.signals import Signal
import datetime

class PatientSeries:
    '''Organizes `PatientData` instances found starting at `root`. A series
    is considered a group of distinct patient uploads over time.'''
    def __init__(self, root, load_lazily=False) -> None:
        self.root = root
        self.patient = None
        self._trials = {}

        if not load_lazily:
            self.load()

    def __getitem__(self, key):
        '''Returns a list of uploaded `PatientData` corresponding to `key`. 
        If `key` is a Python `datetime`, returns the uploads for that 
        `datetime` if any and `None` otherwise; if `key` is an `int`, returns
        the dictionary entry at that chronological position in the series;
        otherwise, raises a `TypeError`.'''
        if isinstance(key, datetime.datetime):
            return self._trials[key]
        elif isinstance(key, int):
            target_datetime = sorted(self._trials)[key]
            return self._trials[target_datetime]

        raise TypeError(key)

    @property
    def series(self) -> list[PatientData]:
        '''Returns a `list` of `PatientData` lists, where each inner `list` is
        represents a set of uploaded data from the series. The returned `list`
        is ordered chronologically.'''
        return [self._trials[upload_time] for upload_time in sorted(self._trials)]

    @property
    def trials(self) -> dict:
        '''The trials within this series represented as a dictionary of 
        Python `datetime` to `PatientData` instances. No ordering of entries
        is guaranteed.'''
        return self._trials

    @staticmethod
    def gather(root):
        '''Try to create `PatientSeries` instances using the file
        system structure starting at the `root` level. Directories contained
        within `root` should correspond to the data of individual patients,
        wherein different days worth of data for each should be kept.
        `root` can be a `str` path or `pathlib.Path` instance.'''

        # gather all series
        all_series = []
        for filesys_obj in list(pathlib.Path(root).glob('*')):
            if filesys_obj.is_dir() and filesys_obj.name.isnumeric():
                patient_series = PatientSeries(filesys_obj, load_lazily=True) 
                all_series.append(patient_series)

        # lazily load to catch file system errors above rather than during this
        # slow process
        for series in all_series:
            series.load()

        return all_series

    def only(self, signal:Signal):
        '''Returns a subset of the patient series corresponding to `signal`'''
        return {upload_time:signal_data 
                for upload_time, upload in self._trials.items()
                for signal_data in upload if signal_data.signal is signal}

    def load(self):
        self.patient = self.root.name
        patient_data = PatientData.gather(self.root)
        for pd in patient_data:
            dt = pd.datetime
            if dt in self._trials:
                self._trials[dt].append(pd)
            else:
                self._trials[dt] = [pd]

        