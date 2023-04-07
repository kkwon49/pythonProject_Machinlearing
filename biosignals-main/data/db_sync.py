import os
import re
import google.oauth2.service_account as service_account
from google.cloud import storage
from pathlib import Path
from biosignals.data._cleaner import clean_files
from biosignals.data.patient_data import PatientData
from biosignals.signals import Signal


class CloudData:
    '''Instances represent individual patient data files stored in the cloud.
    Not typically instantiated directly.'''
    def __init__(self, blob:storage.blob.Blob) -> None:
        self._blob = blob
        self.name = blob.name
        
        self.to_clean = False
        channel_match = re.search(r"-ch(\d)", self.name.split('/')[-1])
        if channel_match:
            self.to_clean = True
            self._channel = channel_match.group()[-1]

        # parse patient ID
        self.patient = self._regex_find(r"/[0-9|A-F|a-f]+/")
        if self.patient is not None:
            self.patient = self.patient[1:-1]
        
        # parse date
        self.date = self._regex_find(r"\d{4}[\. | _ | -]\d{2}[\. | _ | -]\d{2}")
        if self.date is not None and '.' in self.date:
            self.date = self.date.replace('.', '-')  

        # parse times
        self.use_offset_time = False
        self.time = self._regex_find(r"\d{2}[\. | _]\d{2}[\. | _]\d{2}")
        if self.time is None:
            time = self._regex_find(r"[0-9]+", multiple=True)
            if time:
                self.time = time[-1]
                self.use_offset_time = True
            else:
                self.time = None
        elif '.' in self.time:
            self.date = self.date.replace('.', '_')  
            
        # parse measurement
        self.signal = None
        for signal in Signal:
            str_signal = signal.value
            match = self._regex_find(str_signal.upper())
            if match is not None:
                self.signal = signal
                break

    def _regex_find(self, expression, multiple=False) -> str:
        name = self.name.upper()
        if not multiple:
            match = re.search(expression, name)
            if match is not None:
                return match.group()
            return None
        
        return re.findall(expression, name)

    def make_filename(self, include_channel=False) -> str:
        '''Returns the file name for this `PatientData` instance.'''
        if self.to_clean and self.signal == Signal.PPG and include_channel:
            # handle separate PPG from postpartum monitor
            return (self.patient + '_' + self.signal.name + '-ch' + self._channel + '_' 
                + self.time + '__' + self.date + '.csv') 

        return (self.patient + '_' + self.signal.name + '_' 
            + self.time + '__' + self.date + '.csv')  

    def to_memory(self, client):
        blob = self._blob
        return blob.download_as_bytes(client=client)

    def local_save(self, location:str, client) -> None:
        """
        Saves the database data corresponding to this PatientData at
        the given filepath `location`.
        """
        blob = self._blob
        with open (location, 'wb') as file_obj:
            client.download_blob_to_file(blob, file_obj)

    def to_patient_data(self) -> PatientData:
        pass


class CloudSync:
    _STORAGE_BUCKET_NAME = "data-storage-339220.appspot.com"

    @staticmethod
    def _get_client(cred_path:Path=None) -> storage.Client:
        """
        Fetch the service account key JSON file contents and init database client
        """
        if cred_path is None:
            cred_path = Path(os.getcwd(), 'biosignals', 'credentials.json')

        if not isinstance(cred_path, Path) or not cred_path.exists():
            raise Exception("Could not find cloud credentials." \
                        + "Check that you have a credentials.json file.")

        get_creds = service_account.Credentials.from_service_account_file
        credentials = get_creds(str(cred_path))
        return storage.Client(credentials=credentials)

    def __init__(self, projects, signals:list=None, cred_path=None) -> None:
        supported_projects = CloudSync.list_projects()
        if not isinstance(projects, str) and not isinstance(projects, list):
            raise TypeError(f"`projects` must be list or str, not {type(projects)}")
        elif (isinstance(projects, str) 
                and projects.upper() not in map(str.upper, supported_projects)):
            raise ValueError(f"Project {projects} not found in cloud.")
        elif isinstance(projects, str):
            # make list for following list comprehension
            projects = [projects]

        # set all project names to exact spelling/capitalization
        self.projects= {[cloud_name for cloud_name in supported_projects 
                        if cloud_name.upper() == p.upper()][0]
                        for p in projects}

        if isinstance(signals, list) and signals:
            self.signals = list(signals)
        elif isinstance(signals, Signal):
            self.signals = [signals]
        elif signals is None:
            # default to all supported signals
            self.signals = [signal for signal in Signal]
        else:
            raise ValueError(
                "`signals` must be a Signal, list of Signals, or None")

        self.storage_client = CloudSync._get_client(cred_path)
        if not self.authenticated:
            raise Warning("Could not authenticate with cloud")

        self.destination = None # to be set later

    @staticmethod
    def list_projects(cred_path=None) -> list:
        client = CloudSync._get_client(cred_path)
        blobs = client.list_blobs(CloudSync._STORAGE_BUCKET_NAME)
        roots = {Path(blob.name).parts[0] for blob in blobs}
        return list(roots)

    @property
    def authenticated(self) -> bool: 
        return self.storage_client is not None

    def _checkTolerance(self, a, b, tol) -> bool:
        return abs(int(a) - int(b)) <= tol

    def _getHourMinuteSecond(self, time:str) -> tuple:
            match = re.search(r"(?P<hr>\d{2})[\. | _](?P<min>\d{2})[\. | _](?P<sec>\d{2})", time)
            return (match.group('hr'), match.group('min'), match.group('sec'))

    def _checkTimes(self, time1:str, time2:str, use_offset_time:bool) -> bool:
        '''Returns `True` if `time1` and `time2` are thought to coincide.
        This can be used to handle conflicts in the comparison of two files due to 
        time differences on the order of seconds.'''
        if not use_offset_time:
            (h1, m1, s1) = self._getHourMinuteSecond(time1)
            (h2, m2, s2) = self._getHourMinuteSecond(time2)

            return (h1 == h2 
                    and self._checkTolerance(m1, m2, 1) 
                    and self._checkTolerance(s1, s2, 10))
        
        return abs(int(time1) - int(time2)) < 5e3

    def try_mkdir(self, path) -> None:
        '''Attempts to make a directory of the provided path.'''
        if not os.path.exists(path):
            os.makedirs(path)
            
    def _procees_day(self, day, patient_data:PatientData, patient_dir:Path):
        '''Saves the submissions for this day for a given patient.'''
        # make directory for this day
        day_path = patient_dir.joinpath(day)
        self.try_mkdir(day_path)

        # this day's files
        d_data = [df for df in patient_data if df.date == day]
        times = list(set([df.time for df in d_data]))
        times.sort()
        patient_files_saved = 0
        trial = 0

        for t in times:
            # make per-day folders
            t_data = [df for df in d_data if self._checkTimes(df.time, t, df.use_offset_time)]
            # if len(t_data) < len(self.signals):
            #     # skip this time if insufficient number of files were uploaded
            #     continue 
                
            did_save_data = False
            for df in t_data:
                clean_file_name = df.make_filename(include_channel=False)
                path_with_time = lambda i: day_path.joinpath(i, clean_file_name)
                possibly_existing_paths = [path_with_time(str(i)) 
                    for i in range(0, len(times))]

                # check if this data already exists 
                if not any(map(os.path.exists, possibly_existing_paths)):
                    trial_dir = day_path.joinpath(str(trial))
                    self.try_mkdir(trial_dir)
                    actual_file_name = df.make_filename(include_channel=True)
                    file_path = trial_dir.joinpath(actual_file_name)
                    df.local_save(file_path, self.storage_client)
                    
                    # discard file if empty
                    if os.stat(file_path).st_size == 0:
                        os.remove(file_path)
                    else:
                        did_save_data = True
                        patient_files_saved += 1

            if did_save_data and any(map(lambda df: df.to_clean, t_data)): 
                clean_files(day_path.joinpath(str(trial)))
            trial += 1
            
        return patient_files_saved

    def _download(self, patient_records:dict, destination) -> int:
        self.try_mkdir(destination)

        # we loop over each individual patient, processing their uploads 
        # day-by-day
        patients = patient_records.keys()
        num_saved = 0
        for p in patients:
            patient_files = 0

            # make a root for the patient using the project name + their ID
            p_dir = destination.joinpath(p)
            self.try_mkdir(p_dir)
            p_data = patient_records[p]

            for d in set([df.date for df in p_data]): 
                patient_files += self._procees_day(d, p_data, p_dir) 

            num_saved += patient_files

            if patient_files > 0:
                print(p + ": " + str(patient_files))

        return num_saved

    def _sync_project(self, project:str):
        assert self.destination is not None, "Internal: must provide destination"

        # retrieve all objects for the project of interest and make PatientData objects
        db_objects = self.storage_client.list_blobs(
            CloudSync._STORAGE_BUCKET_NAME, prefix= project + "/")

        # datafiles = list(map(PatientData, db_objects))
        datafiles = list(map(CloudData, db_objects))

        # organize all relevant patient data
        patients = {df.patient for df in datafiles }
        failed_datafiles = {df for df in datafiles 
                            if None in {df.patient, df.time, df.signal}}

        num_failed = len(failed_datafiles)

        patient_datafiles = {
            p : [df for df in datafiles 
                    # make sure our dict values correspond to the right patient
                    if df.patient == p

                    # ensure correctly parsed files 
                    and df not in failed_datafiles

                    # only include those signal requested
                    and df.signal in self.signals] 
            for p in patients if p is not None
        }

        project_root = self.destination.joinpath(project)
        num_saved = self._download(patient_datafiles, project_root)

        return num_saved, num_failed

    def sync(self, destination:Path=None) -> tuple:
        """
        Synchronizes local files starting at `destination` with files in the
        cloud. `destination` is the desired file system root within which 
        project-specific folder will be synchronized. If no `destination` is
        provided, it defaults to <current working directory>/data/.
        """

        if destination is None:
            destination = Path(os.getcwd(), 'data')
        else:
            self.destination = Path(destination)

        for project in self.projects:
            # download files for each project

            print('\nProject: ' + project.capitalize())

            num_saved, num_failed = self._sync_project(project)

            if num_failed > 0:
                print(f"Failed parsing {num_failed} files.")

            if num_saved == 0:
                print("No new files to save.")

