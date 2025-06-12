import json
from pathlib import Path
from urllib.request import urlretrieve
from urllib.parse import urlparse
import shutil


with Path("data.json").open() as f:
    data = json.load(f)["files"]

for file_obj in data:
    url = urlparse(file_obj["url"])
    filename = Path(url.path).name
    downloaded = Path()
    for ix, dest in enumerate(file_obj["dest"]):
        destination = Path(dest).joinpath(filename)
        destination.parent.mkdir(exist_ok=True)
        if not destination.exists():
            if ix == 0:
                print(f"Downloading {url.geturl()} to {dest}")
                urlretrieve(url.geturl(), destination)
                downloaded = destination
            elif downloaded.name:
                print(f"Copying {downloaded} to {destination}")
                shutil.copy(downloaded, destination)