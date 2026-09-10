#!/usr/bin/env python3
"""Merge the repo's managed Windows Terminal settings into the live file.

Not a copy, unlike the glazewm/zebar installs, for two reasons:

  * `profiles.list` and `defaultProfile` are machine-generated GUIDs. WT mints
    them per install, so shipping this machine's would leave a rebuilt box
    pointing `defaultProfile` at a profile that does not exist.
  * WT rewrites settings.json itself (reformatting, adding new profiles as
    distros appear). A copy would fight both the app and any UI-side edit.

So we own a subset - keybindings, actions, schemes, themes, fonts, and the
handful of top-level toggles - and leave identity to the machine. Keys absent
from settings.managed.json are left exactly as WT wrote them.

Exits 0 with "changed"/"ok" on stdout for ansible's changed_when.
"""
import json
import shutil
import sys

managed_path, live_path = sys.argv[1], sys.argv[2]

with open(managed_path, encoding='utf-8') as f:
    managed = json.load(f)

try:
    with open(live_path, encoding='utf-8-sig') as f:
        live = json.load(f)
except FileNotFoundError:
    live = {}

before = json.dumps(live, sort_keys=True)

# Shallow merge per top-level key. `profiles` is the one exception: merge into
# `profiles.defaults` so `profiles.list` (the machine's own profiles) survives.
for key, value in managed.items():
    if key == 'profiles':
        profiles = live.setdefault('profiles', {})
        profiles.setdefault('defaults', {}).update(value.get('defaults', {}))
    else:
        live[key] = value

if json.dumps(live, sort_keys=True) == before:
    print('ok')
    sys.exit(0)

# DrvFs has no atomic rename across the WSL boundary worth relying on, and WT
# may hold the file open; write in place after a backup.
try:
    shutil.copy2(live_path, live_path + '.bak')
except FileNotFoundError:
    pass

with open(live_path, 'w', encoding='utf-8') as f:
    json.dump(live, f, indent=4, ensure_ascii=False)
    f.write('\n')

print('changed')
