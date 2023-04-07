import re
import pathlib
from enum import Enum
import pathlib
import biosignals.processing._util as _util
from biosignals.signals import Signal
from datetime import time, date, datetime

class PatientData:
    '''Provides a nice interface for manipulating local .csv data.'''
    def __init__(self, path, lazy=False):
        path = pathlib.Path(path)

        self.path = path.as_posix()
        self._start = PatientData._get_path_time(str(path))
        self.lazy = lazy
        self._offset = 0
        self.signal = PatientData._get_path_signal(path)

        # parse dates
        pd_date = PatientData._parse_date(self.path)
        if not pd_date:
            raise ValueError(path)

        # parse times
        pd_time = PatientData._parse_time(self.path)

        self.datetime = datetime.combine(date=pd_date, time=pd_time)

        if self.lazy:
            self.data = None
        else: 
            self.load()

    def local_save(self, location:str, client) -> None:
        '''Saves the database data corresponding to this PatientData at
        the given filepath `location`.'''
        blob = self.__blob
        with open (location, 'wb') as file_obj:
            client.download_blob_to_file(blob, file_obj)

    @staticmethod
    def _parse_date(path:pathlib.Path):
        expression = r"[_|/](?P<year>\d{4})[-|_](?P<month>\d{2})[-|_](?P<day>\d{2})"
        result = re.search(expression, str(path))

        if not result:
            return None

        return date(int(result.group('year')), 
                    int(result.group('month')), 
                    int(result.group('day')))

    @staticmethod
    def _parse_time(path:pathlib.Path):
        expression = r"[_|/](?P<hr>\d{2})[\.|_](?P<min>\d{2})[\. | _](?P<sec>\d{2})"
        result = re.search(expression, str(path))

        if result:
            return time(int(result.group('hr')), 
            int(result.group('min')), 
            int(result.group('sec')))

        # handle Postpartum Monitor edge case in file formatting
        expression = r"_(?P<offset>\d+)_"
        match = re.search(expression, str(path))
        assert match, "Could not parse time"
        
        offset = int(match.group('offset'))
        complete_seconds = offset // 1000
        
        hour = complete_seconds // 3600
        minute = complete_seconds % 3600 // 60
        second = complete_seconds % 60
        milliseconds = offset % 1000
        pd_time = time(hour, minute, second, microsecond=milliseconds*1000)

        if not pd_time:
            return None

        return pd_time

    def _is_complete(self):
        return (self.data is not None 
                and self.path is not None 
                and self.datetime is not None)

    @staticmethod
    def gather(root, exclude_on_none=True):
        """
        Returns a list of PatientData instances from parsing the data contained
        at `root`.
        """
        files = _util.find_csv(root)
        all_data = [PatientData(csv_file) for csv_file in files
                    if csv_file is not None]

        if not exclude_on_none:
            return all_data

        return [pd for pd in all_data if pd._is_complete()]

    @staticmethod
    def _get_path_signal(path:pathlib.Path):
        candidate_signals = [s for s in Signal 
                                if s.value.upper() in path.name.upper()]
        if len(candidate_signals) != 1:
            return None
        else:
            return candidate_signals[0]
        
    @staticmethod
    def _get_path_time(str_path):
        results = re.findall(r'\d+', str_path)
        if len(results) == 0:
            return None
        return int(results[-1]) / 1000

    @staticmethod
    def align(*args) -> None:
        max_start = 0
        for patient_data in args:
            max_start = max(patient_data._start, max_start)
            if patient_data.data is None: 
                patient_data.load()
            else:
                patient_data.reset_alignment()
        for patient_data in args:
            deltaT = max_start - patient_data._start
            patient_data.data[:,0] += deltaT
            patient_data._offset += deltaT
        
    def __getitem__(self, key):
        if self.data is None:
            return []
        return self.data[key]

    def __setitem__(self, key, value):
        self.data[key] = value

    def reset_alignment(self):
        self.data[:,0] -= self._offset
        self._offset = 0

    def normalize(self):
        self.data[:,1:] = _util.normalize(self.data[:,1:])

    def trim(self, time):
        keep = self.data[:,0] >= time
        self.data = self.data[keep, :]

    def reverse_trim(self, time):
        keep = self.data[:,0] < time
        self.data = self.data[keep, :]

    def filt(self, freqs:list, fs:int, mode:str):
        if self.data is None:
            self.load()
        fs = self.measurement.fs
        self.data[:,1:] = _util.filt(self.data[:,1:], freqs, fs, mode)

    def load(self):
        self.data = _util.load_csv(self.path)