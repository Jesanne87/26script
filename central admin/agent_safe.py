#!/usr/bin/env python3
"""JsPhantom safe agent: preview, explicit apply, rollback. Python 3.9+."""
import sys, json, os, ssl, urllib.request, re, base64, secrets, shutil, time, hashlib
from pathlib import Path
CFG=Path('/etc/jsphantom/central-agent.json')
BASE=Path('/etc/jsphantom/user-status')
BACK=Path('/var/backups/jsphantom-central-agent')
MASTER='https://shin1.btvpn-my.eu.org'

def read_json(p):
    if not p.exists(): return {}
    d=json.loads(p.read_text(encoding='utf-8'))
    if not isinstance(d,dict): raise ValueError('Invalid JSON object: '+str(p))
    return d

def atomic(p,data):
    p.parent.mkdir(parents=True,exist_ok=True)
    t=p.with_name(p.name+'.tmp-'+secrets.token_hex(6))
    try:
        with t.open('x',encoding='utf-8') as f: json.dump(data,f,indent=2,ensure_ascii=False);f.write('\n')
        os.chmod(t,0o600);os.replace(t,p)
    finally:
        if t.exists(): t.unlink()

def fetch():
    c=read_json(CFG);name=c['name'];token=c['token']
    if not re.fullmatch('[A-Za-z0-9_-]{1,32}',name) or len(token)<30: raise ValueError('Invalid agent credentials')
    url=MASTER+'/admin/api/agent/'+name
    req=urllib.request.Request(url,headers={'Authorization':'Bearer '+token,'User-Agent':'JsPhantomSafeAgent/1.0.1'})
    with urllib.request.urlopen(req,timeout=15,context=ssl.create_default_context()) as r:
        raw=r.read(15*1024*1024+1)
    if len(raw)>15*1024*1024: raise ValueError('Response too large')
    d=json.loads(raw)
    if not isinstance(d,dict): raise ValueError('Bad response')
    for k in ('contacts','tutorial','text'):
        if not isinstance(d.get(k),dict):raise ValueError('Bad '+k)
    if not isinstance(d.get('buttons'),list) or len(d['buttons'])>8 or not isinstance(d.get('images'),dict):raise ValueError('Bad buttons/images')
    for k in ('contacts','tutorial'):
        if not all(isinstance(a,str) and isinstance(b,str) and len(b)<10000 for a,b in d[k].items()):raise ValueError('Bad values in '+k)
    imgs={}
    for name,encoded in d['images'].items():
        if not re.fullmatch(r'[A-Za-z0-9_.-]+\.(?:jpg|jpeg|png|webp)',name,re.I) or name.startswith('.'):raise ValueError('Unsafe image name')
        if not isinstance(encoded,str):raise ValueError('Bad image data')
        blob=base64.b64decode(encoded,validate=True)
        if len(blob)>2*1024*1024:raise ValueError('Image too large')
        imgs[name]=blob
    return d,imgs

def target_data(d):
    out={}
    for filename,key in [('admin-contact.json','contacts'),('tutorial.json','tutorial')]:
        old=read_json(BASE/filename)
        old.update(d[key]);out[filename]=old
    out['central-content.json']={'text':d['text'],'buttons':d['buttons']}
    return out

def diff(d,imgs):
    targets=target_data(d)
    print('=== JsPhantom SAFE PREVIEW (no changes) ===')
    for filename,new in targets.items():
        old=read_json(BASE/filename)
        changed=[k for k in sorted(set(old)|set(new)) if old.get(k)!=new.get(k)]
        print(filename,':',len(changed),'changed keys',', '.join(changed) if changed else '(unchanged)')
    for name,blob in sorted(imgs.items()):
        p=BASE/'tutorials'/name
        changed=not p.exists() or hashlib.sha256(p.read_bytes()).digest()!=hashlib.sha256(blob).digest()
        print('image:',name,'CHANGE' if changed else 'unchanged')
    print('No Xray/Nginx/service restart. Auto-sync is NOT installed.')

def backup(targets,imgs):
    BACK.mkdir(parents=True,exist_ok=True);os.chmod(BACK,0o700)
    folder=BACK/(time.strftime('%Y%m%d-%H%M%S')+'-'+secrets.token_hex(4));folder.mkdir(mode=0o700)
    manifest={}
    for filename in targets:
        p=BASE/filename;manifest[filename]=p.exists()
        if p.exists():shutil.copy2(p,folder/filename)
    for name in imgs:
        p=BASE/'tutorials'/name;key='tutorials/'+name;manifest[key]=p.exists()
        if p.exists():
            (folder/'tutorials').mkdir(exist_ok=True);shutil.copy2(p,folder/key)
    atomic(folder/'manifest.json',manifest)
    return folder

def apply(d,imgs):
    if not BASE.is_dir() or not (BASE/'tutorial.json').exists() or not (BASE/'admin-contact.json').exists():
        raise ValueError('Existing User Detail configuration missing; refusing to write')
    targets=target_data(d)
    folder=backup(targets,imgs)
    try:
        for filename,value in targets.items():atomic(BASE/filename,value)
        imgdir=BASE/'tutorials';imgdir.mkdir(exist_ok=True)
        for name,blob in imgs.items():
            p=imgdir/name;t=p.with_name(p.name+'.tmp-'+secrets.token_hex(4))
            try:
                t.write_bytes(blob);os.chmod(t,0o600);os.replace(t,p)
            finally:
                if t.exists():t.unlink()
        print('APPLY OK. Backup:',folder)
    except Exception:
        restore(folder)
        raise

def restore(folder):
    manifest=read_json(folder/'manifest.json')
    if not manifest:raise ValueError('Invalid backup')
    for name,existed in manifest.items():
        p=BASE/name
        if existed:
            p.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(folder/name,p)
        elif p.exists():p.unlink()
    print('RESTORED:',folder)

def main():
    if os.geteuid()!=0:raise ValueError('Run as root')
    if len(sys.argv)<2:raise ValueError('Usage: agent_safe.py preview | apply | rollback BACKUP_DIR')
    cmd=sys.argv[1]
    if cmd=='rollback':
        if len(sys.argv)!=3:raise ValueError('Specify backup directory')
        folder=Path(sys.argv[2]).resolve()
        if folder.parent!=BACK.resolve():raise ValueError('Backup must be inside '+str(BACK))
        restore(folder);return
    if cmd not in ('preview','apply'):raise ValueError('Unknown command')
    d,imgs=fetch();diff(d,imgs)
    if cmd=='apply':
        print('Type APPLY to confirm:',end=' ',flush=True)
        if input().strip()!='APPLY':raise ValueError('Cancelled; no files changed')
        apply(d,imgs)

if __name__=='__main__':
    try:main()
    except Exception as e:print('ERROR:',str(e),file=sys.stderr);sys.exit(1)
