import sqlite3
from pathlib import Path

import requests
from pyquery import PyQuery as pq

scoop_directory_db = Path(__file__).resolve().parent.joinpath('scoop_directory.db')
conn = sqlite3.connect(scoop_directory_db)

with conn:
    conn.executescript('''\
PRAGMA foreign_keys = false;

DROP TABLE IF EXISTS "app";
CREATE TABLE "app" (
  "id" INTEGER,
  "name" TEXT,
  "version" TEXT,
  "description" TEXT,
  "license" TEXT,
  "bucket_repo" TEXT
);

DROP TABLE IF EXISTS "bucket";
CREATE TABLE "bucket" (
  "score" real,
  "bucket_repo" TEXT NOT NULL,
  "apps" integer,
  "stars" integer,
  "forks" integer,
  "updated" text,
  PRIMARY KEY ("bucket_repo")
);

PRAGMA foreign_keys = true;
''')


def get_content(url):
    # proxies = {
    #     "http": "http://127.0.0.1:7890",
    #     "https": "http://127.0.0.1:7890",
    # }
    # req = requests.get(url, proxies=proxies)
    req = requests.get(url)
    return req.content.decode('utf-8')


d = pq(get_content(url='https://rasa.github.io/scoop-directory/by-score'))
table_count = d("table").length

bucket_repos = []
for td in d("table").eq(0)("tr td:nth-child(2)").items():
    if td("a").attr("href").startswith("https"):
        bucket_repos.append(td("a").attr("href"))
        with conn:
            conn.execute("INSERT INTO bucket(bucket_repo) VALUES (?)", (td("a").attr("href"),))

idx = 0
for td in d("table").eq(0)("tr td:nth-child(1)").items():
    if idx < table_count - 1:
        with conn:
            conn.execute("UPDATE bucket SET score = ? WHERE bucket_repo = ?",
                         (td.text().partition(". ")[2], bucket_repos[idx]))
    idx += 1

idx = 0
for td in d("table").eq(0)("tr td:nth-child(3)").items():
    if idx < table_count - 1:
        with conn:
            conn.execute("UPDATE bucket SET apps = ? WHERE bucket_repo = ?", (td("a").text(), bucket_repos[idx]))
    idx += 1

nths = [4, 5, 6]
bucket_fields = ['stars', 'forks', 'updated']
while_idx = 0
while while_idx < len(nths):
    idx = 0
    for td in d("table").eq(0)(f"tr td:nth-child({nths[while_idx]})").items():
        if idx < table_count - 1:
            with conn:
                conn.execute(f"UPDATE bucket SET {bucket_fields[while_idx]} = ? WHERE bucket_repo = ?",
                             (td("a").text(), bucket_repos[idx]))
        idx += 1
    while_idx += 1

bucket_repos = []
for i in range(0, d('h2').length):
    bucket_repos.append(d('h2').eq(i)('a').eq(1).attr("href"))

app_id = 1

for i in range(1, table_count):
    j = app_id
    k = app_id
    l = app_id
    for td in d("table").eq(i)("tr td:nth-child(1)").items():
        if td("a").text():
            with conn:
                conn.execute(
                    "INSERT INTO app(id, name, bucket_repo) VALUES (?, ?, ?)",
                    (app_id, td("a").text(), bucket_repos[i - 1]))
        else:
            with conn:
                conn.execute(
                    "INSERT INTO app(id, name, bucket_repo) VALUES (?, ?, ?)",
                    (app_id, td.text(), bucket_repos[i - 1]))
        app_id += 1

    for td in d("table").eq(i)("tr td:nth-child(2)").items():
        if td("a").text():
            with conn:
                conn.execute(
                    "UPDATE app SET version = ? WHERE id = ?",
                    (td("a").text(), j))
        else:
            with conn:
                conn.execute(
                    "UPDATE app SET version = ? WHERE id = ?",
                    (td.text(), j))
        j += 1

    for td in d("table").eq(i)("tr td:nth-child(3)").items():
        if td("a").text():
            with conn:
                conn.execute(
                    "UPDATE app SET description = ? WHERE id = ?",
                    (td("a").text(), k))
        else:
            with conn:
                conn.execute(
                    "UPDATE app SET description = ? WHERE id = ?",
                    (td.text(), k))
        k += 1

    for td in d("table").eq(i)("tr td:nth-child(4)").items():
        if td("a").text() == 'Link':
            with conn:
                conn.execute(
                    "UPDATE app SET license = ? WHERE id = ?",
                    (td("a").attr("href"), l))
        elif td("a").text():
            with conn:
                conn.execute(
                    "UPDATE app SET license = ? WHERE id = ?",
                    (td("a").text(), l))
        else:
            with conn:
                conn.execute(
                    "UPDATE app SET license = ? WHERE id = ?",
                    (td.text(), l))
        l += 1

conn.close()
