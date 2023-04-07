import os
from os.path import join
import pandas as pd

# DATA_DESTINATION = r'C:\Users\Jared\OneDrive\GTech\YeoLab\Postpartum Monitor\Clinical Data Processing\data\Postpartum Monitor'
# DEFAULT_ROOT = r'C:\Users\Jared\OneDrive\GTech\YeoLab\Postpartum Monitor\Clinical Data Processing\data\Postpartum Monitor\\20'

def _transform(ppg):
    bitmask = 0x3FFFF
    ppg = (ppg * 262144.0 / 16384.0).astype(int) & bitmask
    return ppg / 262144.0 * 16384.0

def _clean(path, files):
    ppg_files = [f for f in files if 'PPG-' in f]
    PPG_ch0 = pd.read_csv(join(path, ppg_files[0]), names=['times', 'values'])
    PPG_ch1 = pd.read_csv(join(path, ppg_files[1]), names=['times', 'values'])

    PPG_ch0['values'] = _transform(PPG_ch0['values'].to_numpy())
    PPG_ch1['values'] = _transform(PPG_ch1['values'].to_numpy())

    PPG_data = pd.concat([PPG_ch0, PPG_ch1['values']], axis=1, ignore_index=True)
    file_name = ppg_files[0].replace('-ch0', '')
    PPG_data[1:].to_csv(join(path, file_name), index=False, header=False)
    
    for f in map(lambda x: join(path, x), ppg_files):
        os.remove(f)

def _clean_files(root:str):
    '''
    Explores the file system starting at root, combining separate PPG 
    channel data into single files.
    '''
    contents = os.listdir(root)
    csv_files = [c for c in contents if ".csv" in c]

    if csv_files:
       _clean(root, csv_files) 
    else:
        for x in contents:
            path = join(root, x)
            if os.path.isdir(path):
                _clean_files(path)

def clean_files(root:str):
    files = _clean_files(root)
