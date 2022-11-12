import argparse
import sqlite3
from pathlib import Path

parser = argparse.ArgumentParser(description='Search available apps.')
parser.add_argument('app_name', metavar='app_name', type=str, nargs=1,
                    help="an app name")
app_name = parser.parse_args().app_name[0]

scoop_directory_db = Path(__file__).resolve().parent.joinpath('scoop_directory.db')
conn = sqlite3.connect(scoop_directory_db)
with conn:
    apps = conn.execute(
        "SELECT * FROM app WHERE name LIKE ? ORDER BY version DESC", ('%' + app_name + '%',)
    ).fetchall()
conn.close()


def max_length_of_line(arr):
    max_len = 0
    for line in arr:
        if len(line) > max_len:
            max_len = len(line)
    return max_len


def format_arr(arr):
    max_len = max_length_of_line(arr)
    for i in range(len(arr)):
        line = arr[i]
        if len(line) != max_len:
            arr[i] = f"{line}{' ' * (max_len - len(line))}"


app_names = []
app_versions = []
app_bucket_repos = []
app_names.append('app_name')
app_versions.append('app_version')
app_bucket_repos.append('bucket_repo')
for app in apps:
    app_names.append(app[1])
    app_versions.append(app[2])
    app_bucket_repos.append(app[5])
format_arr(app_names)
format_arr(app_versions)
format_arr(app_bucket_repos)

i = 0
while i < len(app_names):
    print(f'{app_names[i]}\t{app_versions[i]}\t{app_bucket_repos[i]}')
    i += 1
