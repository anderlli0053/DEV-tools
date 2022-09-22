import os
import json
import xml.etree.ElementTree as ET
import requests
from zipfile import ZipFile
from io import BytesIO
import time
from traceback import print_exc
import subprocess


HEADERS = {"Referer": "https://github.com/MCOfficer/scoop-nirsoft"}


def probe_for_exe(url):
    print("Downloading " + url + "...")
    r = requests.get(
        url, headers=HEADERS)
    r.raise_for_status()
    with ZipFile(BytesIO(r.content)) as z:
        for name in z.namelist():
            if name.endswith(".exe"):
                return name


if __name__ == '__main__':
    print("Fetching Padfile links")
    pads = requests.get("https://www.nirsoft.net/pad/pad-links.txt").text

    i = 0
    for line in pads.splitlines():
        i += 1
        print("")
        print("Generating from " + line + " (" + str(i) +
              "/" + str(len(pads.splitlines())) + ")")

        try:
            padfile = requests.get(line).text
            root = ET.fromstring(padfile)

            info = root.find("Program_Info")
            version = info.find("Program_Version").text
            full_name = info.find("Program_Name").text

            web_info = root.find("Web_Info")
            website = web_info.find("Application_URLs").find(
                "Application_Info_URL").text.replace("http:", "https:")
            download = web_info.find("Download_URLs").find(
                "Primary_Download_URL").text.replace("http:", "https:")
            download64 = download.replace(".zip", "-x64.zip")
            name = os.path.splitext(os.path.basename(line))[0]

            bin = probe_for_exe(download)
            if not bin:
                print("No executable found! Skipping")

            description = ""
            shortcut = "NirSoft\\" + full_name
            try:
                descriptions = root.find(
                    "Program_Descriptions").find("English")
                description = descriptions.find("Char_Desc_80").text
            except AttributeError:
                pass

            print("Checking 64-bit download url")
            r = requests.head(download64, headers=HEADERS)
            x64 = bool(r.ok)
            if not x64:
                print("64-bit download unavailable")

            manifest = {
                "version": version,
                "homepage": website,
                "url": download,
                "bin": bin,
                "shortcuts": [
                    [bin, shortcut]
                ],
                "persist": [
                    name + "_lng.ini",
                    name + ".cfg"
                ],
                "hash": "tbd",
                "architecture": "",
                "description": description,
                "license": "Freeware",
                "notes": "If this application is useful to you, please consider donating to nirsoft.",
                "checkver": {
                    "url": "https://www.nirsoft.net/pad/" + name + ".xml",
                    "xpath": "/XML_DIZ_INFO/Program_Info/Program_Version"
                },
                "autoupdate": {
                    "url": download
                }
            }

            if x64:
                manifest.pop("url")
                manifest.pop("hash")
                manifest["autoupdate"] = {
                    "architecture": {
                        "64bit": {
                            "url": download64
                        },
                        "32bit": {
                            "url": download
                        }
                    },
                }
                manifest["architecture"] = {
                    "64bit": {
                        "url": download64,
                        "hash": "tbd"
                    },
                    "32bit": {
                        "url": download,
                        "hash": "tbd"
                    }
                }
            else:
                manifest.pop("architecture")
                manifest["url"] = download
                manifest["hash"] = "tbd"

            with open("bucket/" + name + ".json", "w") as j:
                json.dump(manifest, j, indent=1)

        except Exception as e:
            print_exc()

    print("")
    print("Running checkver -f")
    subprocess.run(["powershell", "-Command", r".\bin\checkver.ps1", "-f"])
