import hashlib
import json
import re
import subprocess
import urllib.request

fonts = [
    "ibmplexmono",
    "ibmplexsans",
    "ibmplexserif",
    "montserrat",
    "montserrat-alternates",
    "recmono-casual",
    "recmono-duotone",
    "recmono-linear",
    "recmono-semicasual",
    "urbanist"
]

autoupdate_re = re.compile("\$version")

github_re = re.compile("\/releases\/tag\/(?:v|V)?([\d.]+)")

for font in fonts:
    with open(f"./bucket/{font}.json", "r") as f:
        json_object = json.load(f)

    if json_object["checkver"] == "github":
        try:
            with urllib.request.urlopen(f"{json_object['homepage']}/releases") as f:
                checkver = f.read().decode('utf-8')

            checkver_version = github_re.search(checkver)
            if checkver_version and checkver_version.group(1):
                latest_version = checkver_version.group(1)

            if latest_version != json_object["version"]:
                hashes = []

                for i, url in enumerate(json_object["url"]):
                    if "autoupdate" in json_object:
                        url = autoupdate_re.sub(latest_version, json_object["autoupdate"]["url"][i])

                    with urllib.request.urlopen(f"{url}") as f:
                        sha256_hash = hashlib.sha256()
                        for byte_block in iter(lambda: f.read(4096),b""):
                            sha256_hash.update(byte_block)
                        hashes.append(sha256_hash.hexdigest())

                json_object["version"] = latest_version
                json_object["hash"] = hashes

                with open(f"./bucket/{font}.json", "w") as f:
                    json.dump(json_object, f, indent=4)
                    f.write("\n")

                subprocess.check_call(["hub", "add", f"bucket/{font}.json"])
                subprocess.check_call(["hub", "commit", "-m", f"{font}: Update to version {latest_version}"])
        except Exception as e:
            print(f"Something wrong happened with {font}.")
