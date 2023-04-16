import os

os.chdir(os.path.abspath(os.path.dirname(__file__)))

updaters = [
    'busybox',
    'windowsdesktop-runtime',
    'windowsdesktop-runtime-lts-3.1.x',
    'windowsdesktop-runtime-lts-6.0.x',
    'diskgen'
]

for updater in updaters:
    print("===> {0}".format(updater))
    exec(open('update-' + updater + '.py').read())
