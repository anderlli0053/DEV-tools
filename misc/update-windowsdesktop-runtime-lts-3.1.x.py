import json
import os
import re
import urllib.request

version_check_url = 'https://dotnet.microsoft.com/download/dotnet/3.1'
manifest_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', 'bucket', 'windowsdesktop-runtime-lts-3.1.x-{arch}.json')
archs = ['x86', 'x64']

for arch in archs:
    arch_manifest_path = manifest_path.format(arch=arch)
    manifest = json.load(open(arch_manifest_path, mode='r'))

    with urllib.request.urlopen(version_check_url) as url:
        version_current = re.findall('data-target="#version_0">([\\d.]+)</button>', url.read().decode())[0]
        version_existing = manifest['version']

        if version_current != version_existing:
            print("New version {0} detected (current version {1}) for the {2} arch. Will update the manifest...".format(version_current, version_existing, arch))
            manifest_arch = next(iter(manifest['architecture']))

            download_page_url = manifest['autoupdate']['architecture'][manifest_arch]['hash']['url'].replace('$version', version_current)
            with urllib.request.urlopen(download_page_url) as download_page:
                download_page_source = download_page.read().decode()
                current_hash = re.findall('id="checksum".*value="([a-f0-9]{128})"\\s', download_page_source)[0]
                current_url = re.findall('id="directLink".*href="(https.*?\\.exe)"', download_page_source)[0]

                # Update the manifest before saving to file
                manifest['version'] = version_current
                manifest['architecture'][manifest_arch]['hash'] = "sha512:" + current_hash
                manifest['architecture'][manifest_arch]['url'] = current_url

                target = open(arch_manifest_path, "w")
                target.write(json.dumps(manifest, indent=4, sort_keys=False) + "\n")
                target.close()
                
                # Write commit messages
                message = "windowsdesktop-runtime-lts-3.1.x-{0}: Update to version {1}".format(arch, version_current)
                commit_message = open('.commit_messages', 'a')
                commit_message.write(message + "\n")
                commit_message.close()
        else:
            print("No new version detected for the {0} arch. Will not update the manifest. ".format(arch))
