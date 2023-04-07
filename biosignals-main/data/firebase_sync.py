import os
from pathlib import Path
import pandas as pd
from google.cloud import firestore
import google.oauth2.service_account as service_account

class FirebaseSync:
    """
    Easy access of stored Firebase project data. See 
    `FirebaseSync.valid_projects` for the currently supported projects.
    """
    def __init__(self, project="CMAT Bioreactor") -> None:
        """
        Returns a `FirebaseSync` instance which allows for easy access of 
        stored Firebase project data. `project` must be a valid project name.
        See `FirebaseSync.valid_projects` for the currently supported projects.
        """
        existing_projects = FirebaseSync.valid_projects
        if project not in existing_projects:
            raise ValueError(f"Project must be one of {existing_projects}")

        db = FirebaseSync._get_db()
        self._project_doc = db.collection('projects').document(project)

    @staticmethod
    def _get_client(cred_path:Path=None) -> firestore.Client:
        """
        Returns a database Firestore database client for the Yeo Lab 
        GCP cloud.
        """
        if cred_path is None:
            cred_path = Path(os.getcwd(), 'biosignals', 'credentials.json')

        if not isinstance(cred_path, Path) or not cred_path.exists():
            raise Exception("Could not find cloud credentials." \
                        + "Check that you have a credentials.json file.")

        get_creds = service_account.Credentials.from_service_account_file
        credentials = get_creds(str(cred_path))
        return firestore.Client(project="data-storage-339220", 
                                credentials=credentials)

    @property
    def valid_dates(self):
        """
        Returns a list of the dates of received data for this project
        """
        return [collection.id for collection 
                in self._project_doc.collections()]
    
    valid_projects = {doc.id for doc in 
                      _get_client().collection('projects').list_documents()}

    def _get(self, date):
        """
        Returns a dataframe of the data for the given date
        """
        date = str(date)
        for collection in self._project_doc.collections():
            if collection.id == date:
                data = {}
                for doc in collection.list_documents():
                    # different hours
                    new_data = doc.get().to_dict()
                    data.update(**new_data)

                df = pd.DataFrame.from_dict(data).T
                df.reset_index(inplace=True)
                df.rename(columns={"index":"timestamp"}, inplace=True)

                return df
        
    def from_date(self, date):
        """
        Pass a date of the form `YYYY-MM-DD` to get all data from that day.
        """
        date = str(date)
        valid_dates = self.valid_dates
        if date not in valid_dates:
            raise ValueError(f"`date` must be one of {valid_dates}")
        
        return self._get(date)
    
    def most_recent(self):
        """
        Returns the data from the most recent upload day.
        """
        most_reccent = self.valid_dates[-1]
        return self._get(most_reccent)
        