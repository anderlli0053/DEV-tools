import json
import os
import re
import urllib.request
import hashlib

version_check_url = 'https://www.diskgenius.cn/pro/statistics/update.php'
manifest_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', 'bucket', 'diskgen.json')
manifest = json.load(open(manifest_path, mode='r'))

with urllib.request.urlopen(version_check_url) as url:
    version_current = re.findall('\\[([\\d.]+)\\]', url.read().decode())[-1]
    version_existing = manifest['version']

    if version_current != version_existing:
        print("New version {0} detected (current version {1}). Will update the manifest...".format(version_current, version_existing))
        archs = ['32bit', '64bit']
        
        # Update the manifest version
        manifest['version'] = version_current
        
        for arch in archs:
            download_url = manifest['autoupdate']['architecture'][arch]['url'].replace('$cleanVersion', version_current.replace('.', ''))
            
            # Download the files to generate hash, as official website does not provide one
            with urllib.request.urlopen(download_url) as dist_package:
                print("Downloading {0} for hashing, this might take a while...".format(download_url))
                dist_package_binary = dist_package.read()
                current_hash = hashlib.sha256(dist_package_binary).hexdigest()
            
                # Update the manifest download URL and hash
                manifest['architecture'][arch]['hash'] = current_hash
                manifest['architecture'][arch]['url'] = download_url

        target = open(manifest_path, "w")
        target.write(json.dumps(manifest, indent=4, sort_keys=False) + "\n")
        target.close()
                
        # Write commit messages
        message = "diskgen: Update to version {0}".format(version_current)
        commit_message = open('.commit_messages', 'a')
        commit_message.write(message + "\n")
        commit_message.close()
    else:
        print("No new version detected. Will not update the manifest. ")
