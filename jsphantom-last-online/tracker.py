#!/usr/bin/env python3
"""JsPhantom Last Online V2.4.1: incremental VLESS access-log activity tracker."""
import fcntl
import json
import os
import re
import tempfile
import time
from datetime import datetime
from pathlib import Path

LOG = Path('/var/log/xray/access.log')
DB = Path('/etc/xray/user_lastseen.db')
BASE = Path('/etc/jsphantom/user-status')
CURSOR = BASE / 'last-online-cursor.json'
POL = Path('/etc/jsphantom/account-control/policies')
LOCK = BASE / '.last-online.lock'
ENTRY = re.compile(r'^(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})(?:\.\d+)?\s+.*?\baccepted\b.*?\bemail:\s*([A-Za-z0-9_.-]{1,80})(?:\s|$)')
MAX_READ = 8 * 1024 * 1024

def atomic_write(path, contents, mode=0o600):
    fd, name = tempfile.mkstemp(prefix='.last-online-', dir=str(path.parent))
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as out:
            out.write(contents)
            out.flush()
            os.fsync(out.fileno())
        os.chmod(name, mode)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)

def vless_users():
    users = set()
    for f in POL.glob('*.json'):
        try:
            data = json.loads(f.read_text())
            name = data.get('user', f.stem)
            if data.get('protocol') == 'vless' and re.fullmatch(r'[A-Za-z0-9_.-]{1,80}', name):
                users.add(name)
        except (OSError, ValueError, TypeError):
            continue
    return users

def run():
    BASE.mkdir(parents=True, exist_ok=True)
    with LOCK.open('a+') as guard:
        fcntl.flock(guard, fcntl.LOCK_EX)
        if not LOG.is_file():
            print('Xray access log missing; no changes')
            return
        try:
            cursor = json.loads(CURSOR.read_text())
        except (OSError, ValueError):
            cursor = {}
        st = LOG.stat()
        same = cursor.get('dev') == st.st_dev and cursor.get('ino') == st.st_ino
        old_pos = int(cursor.get('offset', 0)) if same else 0
        if old_pos < 0 or old_pos > st.st_size:
            old_pos = 0
        # Bound first-run and catch-up work; discard a partial first line.
        pos = max(old_pos, st.st_size - MAX_READ)
        skip_first = pos > old_pos
        users = vless_users()
        updates = {}
        with LOG.open('rb') as f:
            f.seek(pos)
            if skip_first:
                f.readline()
            # Read only complete lines; leave a trailing incomplete line for next poll.
            while True:
                start = f.tell()
                line = f.readline()
                if not line:
                    break
                if not line.endswith(b'\n'):
                    f.seek(start)
                    break
                m = ENTRY.match(line.decode('utf-8', errors='replace').strip())
                if not m or m.group(2) not in users:
                    continue
                try:
                    ts = int(datetime.strptime(m.group(1), '%Y/%m/%d %H:%M:%S').timestamp())
                except ValueError:
                    continue
                if 1000000000 < ts <= int(time.time()) + 300:
                    u = m.group(2)
                    updates[u] = max(updates.get(u, 0), ts)
            end = f.tell()
        if updates:
            existing = {}
            if DB.exists():
                for line in DB.read_text(errors='replace').splitlines():
                    if '=' not in line:
                        continue
                    name, value = line.split('=', 1)
                    name = name.strip()
                    try:
                        existing[name] = max(existing.get(name, 0), int(value.strip()))
                    except ValueError:
                        pass
            changed = 0
            for name, ts in updates.items():
                if ts > existing.get(name, 0):
                    existing[name] = ts
                    changed += 1
            if changed:
                DB.parent.mkdir(parents=True, exist_ok=True)
                atomic_write(DB, ''.join(f'{k}={v}\n' for k, v in sorted(existing.items())), 0o644)
        # Cursor is committed after database update so failures can be retried.
        atomic_write(CURSOR, json.dumps({'dev': st.st_dev, 'ino': st.st_ino, 'offset': end}) + '\n')
        print(f'Last Online: scanned to offset {end}; users seen={len(updates)}')

if __name__ == '__main__':
    run()
