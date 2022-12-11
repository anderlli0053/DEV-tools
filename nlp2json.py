#!/usr/bin/env python3
# -*- coding: utf-8 -*-
""" @todo add docstring """

import configparser
import json
import os
import re
import subprocess
import sys
from collections import OrderedDict

if len(sys.argv) > 1:
    if "-h" in sys.argv[1:] or "--help" in sys.argv[1:]:
        print(f"Usage: {sys.argv[0]} [path\\to\\NirSoft [path\\to\\nirlauncher.json]]")
        sys.exit(0)
    nirsoft_dir = sys.argv[1]
else:
    nirsoft_dir = os.path.join(os.getenv("SCOOP", default=os.path.expanduser("~/scoop")), "apps/nirlauncher/current/NirSoft")
nirsoft_dir = os.path.normpath(nirsoft_dir)
nirsoft_nlp = os.path.join(nirsoft_dir, "nirsoft.nlp")

if len(sys.argv) > 2:
    nirlauncher_json = sys.argv[2]
else:
    nirlauncher_json = os.path.join(nirsoft_dir, "../manifest.json")
nirlauncher_json = os.path.normpath(nirlauncher_json)

try:
    with open(nirsoft_nlp, "r", encoding="utf-8") as f:
        nlp = configparser.ConfigParser()
        nlp.read_file(f)
except OSError as err:
    sys.exit(err)

try:
    with open(nirlauncher_json, "r", encoding="utf-8") as f:
        manifest = json.load(f)
except OSError as err:
    sys.exit(err)

manifest["architecture"]["64bit"]["bin"] = []
manifest["architecture"]["64bit"]["shortcuts"] = []
manifest["architecture"]["32bit"]["bin"] = []
manifest["architecture"]["32bit"]["shortcuts"] = []

a64b = manifest["architecture"]["64bit"]["bin"]
a64s = manifest["architecture"]["64bit"]["shortcuts"]
a32b = manifest["architecture"]["32bit"]["bin"]
a32s = manifest["architecture"]["32bit"]["shortcuts"]

a64b.append("NirLauncher.exe")
a64s.append(["NirLauncher.exe", "NirLauncher"])
a32b.append("NirLauncher.exe")
a32s.append(["NirLauncher.exe", "NirLauncher"])


def cleanup(s, name):
    s = s.strip()
    if not s:
        return s
    s = s.replace('"', "'")
    s = s.replace("/", ",")
    s = s.replace(",", ", ")
    first, *rest = s.split()
    first = first.lower()
    if [first, rest[0]] in [[name.lower(), "is"], ["this", "utility"]]:
        rest = rest[1:]
        if " ".join(rest[0:4]).lower() == "a small utility that":
            rest = rest[4:]
        first = rest.pop(0).lower()
    if first in ["csv,", "dns", "gui", "mac", "qr", "usb"]:
        first = first.upper()
    else:
        first = first.capitalize()
    return " ".join([" -", first, *rest]).rstrip(".")


def isgui(x, g):
    if g == "Command-Line Utilities":
        # early return, plus eliminate some false positives
        return False
    p = os.path.join(nirsoft_dir, x)
    o = subprocess.check_output(["7z.exe", "l", p], universal_newlines=True)
    return bool(re.search("Subsystem = Windows GUI", o))


for i in range(int(nlp["General"]["SoftwareCount"])):
    sw = nlp[f"Software{i}"]
    bin32 = sw["exe"].strip()
    bin64 = sw["exe64"].strip() or bin32
    group = sw["group"].strip()
    group = nlp[f"Group{group}"]["Name"].strip()
    name = sw["AppName"].strip() # or bin32.removesuffix(".exe")
    if not name:
        name = re.sub(r'\.exe$', '', bin32)
    gui = isgui(bin32, group)
    bin32 = f"NirSoft\\{bin32}"
    bin64 = f"NirSoft\\{bin64}"
    a64b.append(bin64)
    a32b.append(bin32)
    if gui:
        desc = cleanup(sw["ShortDesc"], name)
        shortcut = f"NirSoft\\{name}{desc}"
        a64s.append([bin64, shortcut])
        a32s.append([bin32, shortcut])

nirlauncher_temp = nirlauncher_json + ".tmp"

try:
    with open(nirlauncher_temp, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=4)
        f.write("\n")
except OSError as err:
    sys.exit(err)

try:
    os.replace(nirlauncher_temp, nirlauncher_json)
except OSError as err:
    sys.exit(err)
