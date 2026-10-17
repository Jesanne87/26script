#!/usr/bin/env python3
"""JsPhantom Central Master recovery: verify first, stage safely, rollback on failure."""
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
from datetime import datetime
from pathlib import Path, PurePosixPath

BASE = Path('/etc/jsphantom/central')
CODE = Path('/opt/jsphantom-central/central.py')
UNIT = Path('/etc/systemd/system/jsphantom-central.service')
NGINX = Path('/etc/nginx/conf.d/xray.conf')
BACK = Path('/root/jsphantom-central-recovery')
ALLOWED = ('etc/jsphantom/central/', 'opt/jsphantom-central/central.py',
           'etc/systemd/system/jsphantom-central.service', 'etc/nginx/conf.d/xray.conf')
REQUIRED = {'etc/jsphantom/central/data.json', 'etc/jsphantom/central/auth.json'}
MAX_FILE = 20 * 1024 * 1024
MAX_TOTAL = 100 * 1024 * 1024


def run(*cmd):
    subprocess.run(cmd, check=True)


def inspect(path):
    names = set()
    total = 0
    with tarfile.open(path, 'r:gz') as archive:
        members = archive.getmembers()
        if len(members) > 10000:
            raise ValueError('Too many archive members')
        for member in members:
            name = member.name.rstrip('/')
            p = PurePosixPath(name)
            if (not name or p.is_absolute() or '..' in p.parts or
                    any(part in ('', '.') for part in p.parts)):
                raise ValueError('Unsafe path: ' + member.name)
            if not (name == 'etc/jsphantom/central' or
                    name.startswith('etc/jsphantom/central/') or
                    name in ALLOWED):
                raise ValueError('Unexpected archive entry: ' + name)
            if not (member.isfile() or member.isdir()):
                raise ValueError('Links/special files prohibited: ' + name)
            if name in names:
                raise ValueError('Duplicate archive entry: ' + name)
            names.add(name)
            if member.size > MAX_FILE:
                raise ValueError('Oversized file: ' + name)
            total += member.size
            if total > MAX_TOTAL:
                raise ValueError('Archive too large')
        if not REQUIRED.issubset(names):
            raise ValueError('Missing required Master data files')
        for filename in REQUIRED:
            member = archive.getmember(filename)
            if not member.isfile():
                raise ValueError('Required item not a file: ' + filename)
            with archive.extractfile(member) as stream:
                value = json.load(stream)
            if not isinstance(value, dict):
                raise ValueError('Invalid JSON object: ' + filename)
        for member in members:
            if member.isfile():
                with archive.extractfile(member) as stream:
                    while stream.read(1024 * 1024):
                        pass  # verify decompression and checksums
    return members


def backup_current():
    BACK.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(BACK, 0o700)
    filename = BACK / ('pre-restore-' + datetime.now().strftime('%Y%m%d-%H%M%S') + '-' + str(os.getpid()) + '.tar.gz')
    with tarfile.open(filename, 'w:gz') as archive:
        for p in (BASE, CODE, UNIT, NGINX):
            if p.exists():
                archive.add(p, arcname=str(p).lstrip('/'), recursive=True)
    os.chmod(filename, 0o600)
    return filename


def stage(path, stage_dir, members):
    with tarfile.open(path, 'r:gz') as archive:
        for member in members:
            target = stage_dir / member.name.rstrip('/')
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
                target.chmod(member.mode & 0o777)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                with archive.extractfile(member) as stream, target.open('wb') as dst:
                    shutil.copyfileobj(stream, dst)
                target.chmod(member.mode & 0o777)


def restore(path, full):
    members = inspect(path)
    if full and not all(x in {m.name.rstrip('/') for m in members} for x in ALLOWED[1:]):
        raise ValueError('Full restore requires code, systemd unit and Nginx config in archive')
    # Stage on local disk, no direct tar extraction to /.
    with tempfile.TemporaryDirectory(prefix='jsphantom-restore-', dir='/root') as td:
        staged = Path(td) / 'archive'
        staged.mkdir()
        stage(path, staged, members)
        if full:
            run(sys.executable, '-m', 'py_compile', str(staged / str(CODE).lstrip('/')))
        before = backup_current()
        print('Pre-restore backup:', before, flush=True)
        targets = [BASE] + ([CODE, UNIT, NGINX] if full else [])
        snapshot = Path(td) / 'snapshot'
        snapshot.mkdir()
        existed = {}
        for target in targets:
            existed[target] = target.exists()
            if target.exists():
                copy_target(target, snapshot / str(target).lstrip('/'))
        changed = False
        try:
            if full:
                run('systemctl', 'stop', 'jsphantom-central')
            for target in targets:
                incoming = staged / str(target).lstrip('/')
                if not incoming.exists():
                    raise ValueError('Missing staged path: ' + str(target))
                replace_target(incoming, target)
                changed = True
            if full:
                run('nginx', '-t')
                run('systemctl', 'daemon-reload')
                run('systemctl', 'restart', 'jsphantom-central')
                run('systemctl', 'reload', 'nginx')
            else:
                # Master reads settings on request; restart central only for consistency.
                if CODE.exists() and UNIT.exists():
                    run('systemctl', 'restart', 'jsphantom-central')
            print('RESTORE SUCCESS. Check dashboard and agent registrations.')
        except Exception:
            print('RESTORE FAILED. Attempting rollback...', file=sys.stderr, flush=True)
            if changed:
                for target in targets:
                    original = snapshot / str(target).lstrip('/')
                    try:
                        if existed[target]:
                            replace_target(original, target)
                        elif target.exists():
                            remove_target(target)
                    except Exception as error:
                        print('Rollback error for', target, error, file=sys.stderr)
            if full:
                subprocess.run(['systemctl', 'daemon-reload'], check=False)
                subprocess.run(['nginx', '-t'], check=False)
                subprocess.run(['systemctl', 'restart', 'jsphantom-central'], check=False)
                subprocess.run(['systemctl', 'reload', 'nginx'], check=False)
            elif CODE.exists() and UNIT.exists():
                subprocess.run(['systemctl', 'restart', 'jsphantom-central'], check=False)
            print('Manual recovery backup:', before, file=sys.stderr)
            raise


def copy_target(src, dest):
    dest.parent.mkdir(parents=True, exist_ok=True)
    if src.is_dir():
        shutil.copytree(src, dest, symlinks=True)
    else:
        shutil.copy2(src, dest)


def remove_target(path):
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    else:
        path.unlink()


def replace_target(src, dest):
    dest.parent.mkdir(parents=True, exist_ok=True)
    # Copy to sibling temp before replacement to avoid partial files on copy failure.
    sibling = Path(tempfile.mkdtemp(prefix='.jsphantom-new-', dir=dest.parent))
    incoming = sibling / 'payload'
    try:
        copy_target(src, incoming)
        if dest.exists():
            remove_target(dest)
        os.replace(incoming, dest)
    finally:
        shutil.rmtree(sibling, ignore_errors=True)


def main():
    if os.geteuid() != 0:
        raise PermissionError('Run as root')
    if len(sys.argv) != 3 or sys.argv[1] not in ('verify', 'restore-data', 'restore-full'):
        raise ValueError('Usage: recovery.py verify|restore-data|restore-full /path/to/master-backup.tar.gz')
    action, path = sys.argv[1], Path(sys.argv[2]).resolve(strict=True)
    if not path.is_file():
        raise ValueError('Not a file')
    members = inspect(path)
    print('ARCHIVE VERIFIED:', path.name)
    print('Entries:', len(members))
    print('Includes:', ', '.join(k for k in ('etc/jsphantom/central/data.json',
          'etc/jsphantom/central/auth.json', 'opt/jsphantom-central/central.py',
          'etc/systemd/system/jsphantom-central.service', 'etc/nginx/conf.d/xray.conf')
          if k in {m.name.rstrip('/') for m in members}))
    if action != 'verify':
        restore(path, full=action == 'restore-full')


if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        print('ERROR:', exc, file=sys.stderr)
        sys.exit(1)
