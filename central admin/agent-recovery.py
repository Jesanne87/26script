#!/usr/bin/env python3
"""JsPhantom Agent recovery: strict, bounded archive verification and scoped restore."""
import argparse, datetime, io, json, os, pathlib, re, shutil, sys, tarfile, tempfile

ROOT = pathlib.Path('/')
BACK = pathlib.Path('/root/jsphantom-central-recovery')
FILES = {
 'etc/jsphantom/central-agent.json',
 'etc/jsphantom/user-status/admin-contact.json',
 'etc/jsphantom/user-status/tutorial.json',
 'etc/jsphantom/user-status/central-content.json',
 'opt/jsphantom-agent/agent_safe.py',
 'opt/jsphantom-agent/agent-poll.py',
 'usr/local/sbin/jsphantom-agent-safe',
 'etc/systemd/system/jsphantom-sync-poll.service',
 'etc/systemd/system/jsphantom-sync-poll.timer',
}
PREFIX = 'etc/jsphantom/user-status/tutorials/'
MAX_FILE = 8 * 1024 * 1024
MAX_TOTAL = 48 * 1024 * 1024
MAX_ENTRIES = 200

def allowed(name):
 return name in FILES or (name.startswith(PREFIX) and bool(re.fullmatch(r'[A-Za-z0-9_.-]+\.(?:png|jpg|jpeg|webp)', name[len(PREFIX):], re.I)) and not name[len(PREFIX):].startswith('.'))

def verify(path):
 if not path.is_file() or path.is_symlink(): raise ValueError('Backup missing or symlink')
 result={}; total=0
 with tarfile.open(path,'r:gz') as tar:
  members=tar.getmembers()
  if len(members)>MAX_ENTRIES: raise ValueError('Too many archive entries')
  for member in members:
   name=member.name
   if not allowed(name) or not member.isfile() or member.size>MAX_FILE or member.size<0 or name in result:
    raise ValueError('Unsafe or unexpected archive entry: '+name)
   total+=member.size
   if total>MAX_TOTAL: raise ValueError('Archive expanded size too large')
   f=tar.extractfile(member)
   if f is None: raise ValueError('Cannot read '+name)
   blob=f.read(MAX_FILE+1)
   if len(blob)!=member.size: raise ValueError('Truncated archive entry: '+name)
   result[name]=blob
 for key in ('etc/jsphantom/central-agent.json','etc/jsphantom/user-status/admin-contact.json','etc/jsphantom/user-status/tutorial.json'):
  if key not in result: raise ValueError('Missing required '+key)
 for name,blob in result.items():
  if name.endswith('.json'):
   obj=json.loads(blob.decode('utf-8'))
   if not isinstance(obj,dict): raise ValueError('Expected JSON object: '+name)
 c=json.loads(result['etc/jsphantom/central-agent.json'])
 if not isinstance(c.get('name'),str) or not re.fullmatch(r'[A-Za-z0-9_-]{1,32}',c['name']) or not isinstance(c.get('token'),str) or len(c['token'])<30:
  raise ValueError('Invalid agent credential fields')
 for name,blob in result.items():
  if name.endswith('.py'): compile(blob,name,'exec')
 print('AGENT ARCHIVE VERIFIED:',path.name,'| files:',len(result),'| server:',c['name'])
 return result

def create_backup():
 BACK.mkdir(parents=True,exist_ok=True);os.chmod(BACK,0o700)
 stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
 dest=BACK/('agent-complete-'+stamp+'-'+str(os.getpid())+'.tar.gz')
 present=[x for x in sorted(FILES) if (ROOT/x).is_file() and not (ROOT/x).is_symlink()]
 images=ROOT/PREFIX
 if images.is_dir():
  present.extend(PREFIX+p.name for p in sorted(images.iterdir()) if p.is_file() and not p.is_symlink() and allowed(PREFIX+p.name))
 for mandatory in ('etc/jsphantom/central-agent.json','etc/jsphantom/user-status/admin-contact.json','etc/jsphantom/user-status/tutorial.json'):
  if mandatory not in present: raise ValueError('Missing required local file: '+mandatory)
 fd=os.open(dest,os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600)
 try:
  with os.fdopen(fd,'wb') as raw:
   with tarfile.open(fileobj=raw,mode='w:gz') as tar:
    for name in present:
     p=ROOT/name
     if p.stat().st_size>MAX_FILE: raise ValueError('File too large: '+name)
     tar.add(str(p),arcname=name,recursive=False)
  verify(dest)
 except BaseException:
  dest.unlink(missing_ok=True)
  raise
 print('AGENT COMPLETE BACKUP:',dest)
 print('PRIVATE: contains agent token. Copy OFF VPS securely; do not share publicly.')

def restore(path,kind):
 data=verify(path)
 if kind=='settings':
  selected={n:b for n,b in data.items() if n.startswith('etc/jsphantom/user-status/')}
  base=ROOT/'etc/jsphantom/user-status'
  if not base.is_dir(): raise ValueError('User Detail must be installed before restoring settings')
 else:
  selected={'etc/jsphantom/central-agent.json':data['etc/jsphantom/central-agent.json']}
  target=ROOT/'etc/jsphantom/central-agent.json'
  if target.exists():
   current=json.loads(target.read_text())
   incoming=json.loads(selected['etc/jsphantom/central-agent.json'])
   if current!=incoming: raise ValueError('Different credentials already installed; refusing to replace. Register/reconcile manually.')
 # Transactional for selected files; stop poll timer for credentials to prevent races.
 snapshots={}
 for name in selected:
  dest=ROOT/name
  if dest.is_symlink() or any(p.is_symlink() for p in list(dest.parents)[:-1]): raise ValueError('Symlink in destination path: '+name)
  snapshots[name]=dest.read_bytes() if dest.is_file() else None
 written=[]
 try:
  for name,blob in selected.items():
   dest=ROOT/name;dest.parent.mkdir(parents=True,exist_ok=True)
   fd,tmp=tempfile.mkstemp(prefix='.jsphantom-restore-',dir=str(dest.parent))
   try:
    with os.fdopen(fd,'wb') as f: f.write(blob);f.flush();os.fsync(f.fileno())
    os.chmod(tmp,0o600);os.replace(tmp,dest)
   finally:
    if os.path.exists(tmp): os.unlink(tmp)
   written.append(name)
 except BaseException:
  for name in reversed(written):
   dest=ROOT/name;old=snapshots[name]
   if old is None: dest.unlink(missing_ok=True)
   else:
    fd,tmp=tempfile.mkstemp(prefix='.jsphantom-rollback-',dir=str(dest.parent))
    with os.fdopen(fd,'wb') as f: f.write(old)
    os.chmod(tmp,0o600);os.replace(tmp,dest)
  raise
 print('RESTORE',kind.upper(),'OK:',len(selected),'files. No Xray/Nginx restart.')
 if kind=='credentials': print('Run Setup Agent if needed, preview, then manually start polling when ready.')

def main():
 if os.geteuid()!=0: raise ValueError('Run as root')
 p=argparse.ArgumentParser();p.add_argument('command',choices=['backup','verify','restore-settings','restore-credentials']);p.add_argument('archive',nargs='?');a=p.parse_args()
 if a.command=='backup': create_backup();return
 if not a.archive: raise ValueError('Archive path required')
 path=pathlib.Path(a.archive)
 if a.command=='verify': verify(path)
 else: restore(path,'settings' if a.command=='restore-settings' else 'credentials')
if __name__=='__main__':
 try: main()
 except Exception as e: print('ERROR:',e,file=sys.stderr);sys.exit(1)
