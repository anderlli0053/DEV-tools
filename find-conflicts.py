#!/usr/bin/env python
# -*- coding: utf-8 -*-
""" @todo add docstring """

# ### imports ###

from __future__ import (
    absolute_import,
    division,
    print_function,  # ,
    #  unicode_literals
)

import glob
import json
import os
import sys

from jsoncomment import JsonComment

# from jsonschema import validate


def decode(s):
    """doc me"""
    for encoding in "utf-8-sig", "utf-16":
        try:
            return s.decode(encoding)
        except UnicodeDecodeError:
            continue
    return s.decode("latin-1")


scoop_root = "%USERPROFILE%/scoop"
scoop_root = os.path.expandvars(scoop_root)
buckets_root = scoop_root + "/buckets"

buckets = [
    scoop_root + "/apps/scoop/current/bucket",
    # buckets_root + '/extras',
    # buckets_root + '/nirsoft',
    # buckets_root + '/rasa'
]

parser = JsonComment(json)

amap = {}

for bucket in buckets:
    for json_file in glob.glob(bucket + "/*.json"):
        with open(json_file, "rb") as f:
            jstr = f.read()
            jstr_no_bom = decode(jstr)
            json_data = parser.loads(jstr_no_bom)
            if "bin" not in json_data:
                continue
            base = os.path.basename(json_file)
            base = os.path.splitext(base)[0]
            adir = os.path.basename(os.path.dirname(json_file))
            repo = adir + "/" + base
            bins = json_data["bin"]
            if len(bins) == 0:
                continue
            if type(bins).__name__ != "list":
                bins = [bins]
            if len(bins) == 0:
                continue
            if type(bins).__name__ != "list":
                bins = [bins]
            for abin in bins:
                if type(abin).__name__ == "list":
                    if len(abin) > 1:
                        file = str(abin[1])
                    else:
                        file = str(abin[0])
                else:
                    file = abin
                file = os.path.basename(file)
                file = os.path.splitext(file)[0]
                file = file.lower()
                if file not in amap:
                    amap[file] = {}
                amap[file][repo] = 1
                # print("%s: %s" % (repo, bin))

sfile = sorted(amap.keys())

for file in sfile:
    if len(amap[file]) > 1:
        for repo in amap[file]:
            print("%s: %s" % (file, repo))

sys.exit(0)
