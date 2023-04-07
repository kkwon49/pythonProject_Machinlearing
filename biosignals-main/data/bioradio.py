import pandas as pd
from pathlib import Path, PosixPath, WindowsPath
from datetime import datetime
from dateutil.parser import parse
from dateutil.tz import gettz

class BioradioData: 
    def __init__(self, path:str) -> None:
        self.path = Path(path)
        if self.path.suffix.upper() != ".CSV":
            raise ValueError(f"{self.path} is not a .csv file.")
        self._data = None

    @property
    def data(self):
        return self._data

    def __getitem__(self, key):
        if self.data is not None:
            return self.data[key]
        return None

    @staticmethod
    def _parse_bioradio_dt(series):
        '''
        Helper method for parsing bioradio string times. Returns
        integer number of seconds since epoch. Takes a Pandas
        series element as passed by `pd.apply`.
        '''
        dt_str = series[0] + "EST"
        parsed_dt = parse(dt_str, tzinfos={'EST':gettz('America/New_York')})
        return parsed_dt.timestamp()

    def load(self, drop_cols=['BioRadio Event', 'Unnamed'], col_map=None):
        """
        Loads the bioradio data contained in the .csv file located
        at `path`, which is either a string or pathlib object. Columns
        containing any keywords from `drop_cols` will be dropped, and similarly 
        any columns containing a `col_map` key will have its name mapped to 
        the corresponding dictionary value. `drop_cols` defauls. 

        `drop_cols` defauls to ['BioRadio Event', 'Unnamed'], while `col_map` 
        defauls to o    
        """
        df = pd.read_csv(self.path)

        # drop spurious columns
        cols_to_drop = [col for col in df.columns 
                        for key in drop_cols 
                        if key in col]
        df.drop(labels=cols_to_drop, axis=1, inplace=True)

        # map datetimes to seconds since epoch
        df.iloc[:,0] = df.apply(BioradioData._parse_bioradio_dt, axis=1)
        self._data = df
