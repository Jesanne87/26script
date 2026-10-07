#!/usr/bin/env python3
# JsPhantom Account Control V1.3.7 - verified native runtime API
import re,json,time,subprocess,copy,tempfile,os,sys,fcntl
from pathlib import Path
CFG=Path('/usr/local/etc/xray/config.json'); ACCESS=Path('/var/log/xray/access.log'); BASE=Path('/etc/jsphantom/account-control'); POL=BASE/'policies'; STATE=BASE/'state.json'; SETTINGS=BASE/'settings.json'; LOG=Path('/var/log/jsphantom-account-control.log'); XRAY='/usr/local/bin/xray'; API='127.0.0.1:10000'; TAGS=['vless-ws','vless-xhttp']
BASE.mkdir(parents=True,exist_ok=True); POL.mkdir(parents=True,exist_ok=True)
def load(p,d):
 try:return json.loads(p.read_text())
 except:return d
def save(p,o):
 fd,t=tempfile.mkstemp(dir=str(p.parent),prefix='.ac-state-')
 try:
  with os.fdopen(fd,'w') as f:json.dump(o,f,indent=2)
  os.chmod(t,0o600);os.replace(t,p)
 finally:Path(t).unlink(missing_ok=True)
def log(x):
 with LOG.open('a') as f:f.write(time.strftime('%F %T ')+x+'\n')
def uuid(u):
 a=CFG.read_text(errors='ignore').splitlines()
 for i,l in enumerate(a[:-1]):
  if re.match(r'^#=\s+'+re.escape(u)+r'(?:\s|$)',l):
   m=re.search(r'"id"\s*:\s*"([^"]+)"',a[i+1])
   if m:return m.group(1)
# Native Xray CLI: no grpcurl dependency; preserve complete inbound/client.
def api_call(command,*args):
 try:
  r=subprocess.run([XRAY,'api',command,'--server='+API,*args],
                   stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=15)
 except (OSError,subprocess.TimeoutExpired) as e:
  raise RuntimeError(str(e))
 if r.returncode:raise RuntimeError(r.stdout.strip() or command+' failed')
 return r.stdout
def runtime_present(tag,u):
 d=json.loads(api_call('inbounduser','-tag='+tag))
 if not isinstance(d,dict) or not isinstance(d.get('users',[]),list):
  raise RuntimeError('Invalid runtime user response: '+tag)
 return any(c.get('email')==u for c in d.get('users',[]))
def user_inbound(tag,u):
 text=CFG.read_text()
 d=json.loads(re.sub(r'(?m)^\s*#.*$','',text))
 inbound=[i for i in d.get('inbounds',[]) if i.get('tag')==tag and i.get('protocol')=='vless']
 if len(inbound)!=1:raise RuntimeError('Missing/duplicate VLESS inbound: '+tag)
 i=copy.deepcopy(inbound[0])
 clients=[c for c in i.get('settings',{}).get('clients',[]) if c.get('email')==u]
 if len(clients)!=1:raise RuntimeError('Missing/duplicate client: '+tag+'/'+u)
 i['settings']['clients']=clients
 return i
def alter(tag,u,uid,add):
 try:
  exists=runtime_present(tag,u)
  if exists==add:return True
  if add:
   inbound=user_inbound(tag,u)
   fd,path=tempfile.mkstemp(prefix='jsphantom-ac-adu-',suffix='.json')
   try:
    with os.fdopen(fd,'w') as f:json.dump({'inbounds':[inbound]},f)
    out=api_call('adu',path)
    if not re.search(r'Added 1 user\(s\) in total\.',out):
     raise RuntimeError(out.strip() or 'adu did not confirm an addition')
   finally:Path(path).unlink(missing_ok=True)
  else:api_call('rmu','-tag='+tag,u)
  if runtime_present(tag,u)!=add:raise RuntimeError('Runtime verification failed')
  return True
 except Exception as e:
  log('API-FAILED '+('ADD ' if add else 'REMOVE ')+tag+'/'+u+': '+str(e))
  return False
def configured_user_tags(u):
 # Old restored accounts may belong to only one transport. Validate the
 # complete selection before changing runtime; duplicates are real errors.
 d=json.loads(re.sub(r'(?m)^\s*#.*$','',CFG.read_text()))
 selected=[]
 for tag in TAGS:
  inbounds=[i for i in d.get('inbounds',[]) if i.get('tag')==tag]
  if len(inbounds)>1:raise RuntimeError('Duplicate inbound: '+tag)
  if not inbounds:continue
  i=inbounds[0]
  if i.get('protocol')!='vless':raise RuntimeError('Not a VLESS inbound: '+tag)
  clients=[c for c in i.get('settings',{}).get('clients',[]) if c.get('email')==u]
  if len(clients)>1:raise RuntimeError('Duplicate client: '+tag+'/'+u)
  if clients:selected.append(tag)
 if not selected:raise RuntimeError('User absent from configured VLESS inbounds: '+u)
 return selected

def set_runtime(u,add):
 try:tags=configured_user_tags(u) if add else TAGS
 except Exception as e:
  log('RESTORE-INCOMPLETE '+u+': '+str(e)+' xray_restart=NO')
  return False
 results=[alter(t,u,'',add) for t in tags]  # no all() short circuit
 ok=all(results)
 log(('RESTORE' if add else 'REMOVE')+(' ' if ok else '-INCOMPLETE ')+u+
     ': '+','.join(t+'='+('OK' if r else 'FAILED') for t,r in zip(tags,results))+' xray_restart=NO')
 return ok
def restore_user(u,uid=None):
 return set_runtime(u,True)

def unlock_account(u):
 st=load(STATE,{})
 x=st.get(u)
 if not x or (not x.get('locked') and not x.get('runtime_pending')):
  print('User is not locked.');return 0
 p=load(POL/(u+'.json'),{})
 q=int(p.get('quota_bytes',0))
 if q and int(x.get('used_bytes',0))>=q:
  print('Quota still exceeded. Reset or increase quota first.');return 1
 if not uuid(u):
  print('Account no longer exists in config; unlock cancelled.');return 1
 if restore_user(u):
  x.update(locked=False,reason='',locked_at=0,unlock_at=0)
  x.pop('runtime_pending',None);x.pop('runtime_error',None)
  clear_ip_state(x)
  save(STATE,st)
  log('MANUAL-UNLOCK '+u+' verified=configured-inbounds xray_restart=NO')
  print('Unlocked: '+u+'; configured inbound runtime verified. No Xray restart.')
  return 0
 x['runtime_pending']='unlock';x['runtime_error']='Configured inbound restore incomplete'
 save(STATE,st)
 print('Unlock incomplete. State retained; monitor will retry configured inbounds.')
 return 1

def clear_ip_state(x):
 x['ip_violation_checks']=0
 x['ip_seen']={};x['ips']=[];x['ip_count']=0
 x['ip_activity']={};x['ip_first_seen']={}
 x.pop('ip_overlap',None);x.pop('ip_overlap_since',None)
 x['ip_observation_version']=2;x['ip_previous_check']=0

def stats():
 try:s=subprocess.check_output([XRAY,'api','statsquery','--server='+API,''],stderr=subprocess.DEVNULL,text=True,timeout=12)
 except:return None
 out={}; name=None
 for line in s.splitlines():
  m=re.search(r'user>>>([^>]+)>>>traffic>>>(?:up|down)link',line)
  if m:name=m.group(1)
  elif name and '"value"' in line:
   m=re.search(r'([0-9.eE+-]+)',line.split(':',1)[-1])
   if m:
    try:out[name]=out.get(name,0)+int(float(m.group(1)))
    except:pass
   name=None
 return out
def scan_ips(users,window,now):
 # Build per-user/IP activity inside the recent window.
 # Each IP keeps first timestamp, last timestamp and hit count.
 o={u:{} for u in users}
 if not ACCESS.exists():return o
 try:lines=subprocess.check_output(['tail','-n','30000',str(ACCESS)],text=True,errors='ignore').splitlines()
 except:return o
 for l in lines:
  em=re.search(r'email:\s*([^\s]+)',l)
  if not em or em.group(1) not in o:continue
  im=re.search(r'from\s+(?:tcp:)?(\[[0-9a-fA-F:]+\]|[0-9.]+):\d+',l)
  if not im:continue
  tm=re.match(r'^(\d{4})[-/](\d{2})[-/](\d{2})[ T](\d{2}):(\d{2}):(\d{2})',l)
  if not tm:continue
  try:
   y,mo,d,h,mi,se=map(int,tm.groups())
   ts=int(time.mktime((y,mo,d,h,mi,se,0,0,-1)))
  except:continue
  if ts>now+300 or now-ts>window:continue
  ip=im.group(1).strip('[]');u=em.group(1)
  z=o[u].setdefault(ip,{'first':ts,'last':ts,'hits':0})
  z['first']=min(int(z.get('first',ts)),ts)
  z['last']=max(int(z.get('last',ts)),ts)
  z['hits']=int(z.get('hits',0))+1
 return o
def sync_deleted_users(st):
 try: txt=CFG.read_text(errors='ignore')
 except: return st
 live=set()
 for line in txt.splitlines():
  m=re.match(r'^#=\s+(\S+)(?:\s|$)',line)
  if m: live.add(m.group(1))
 removed=[]
 for f in list(POL.glob('*.json')):
  p=load(f,{});u=p.get('user',f.stem)
  if p.get('protocol')=='vless' and u not in live:
   try:f.unlink()
   except:pass
   st.pop(u,None);removed.append(u)
 if removed:log('AUTO-SYNC removed deleted VLESS: '+','.join(sorted(removed)))
 return st

def main():
 cfg=load(SETTINGS,{'lock_duration_seconds':600,'ip_window_seconds':90,'violation_confirm_checks':3,'ip_min_hits':2,'new_ip_grace_seconds':30})
 lockdur=max(60,int(cfg.get('lock_duration_seconds',600)))
 window=max(30,int(cfg.get('ip_window_seconds',90)))
 confirm=max(1,int(cfg.get('violation_confirm_checks',3)))
 min_hits=max(1,int(cfg.get('ip_min_hits',2)))
 grace=max(0,int(cfg.get('new_ip_grace_seconds',30)))
 st=load(STATE,{})
 st=sync_deleted_users(st)
 ps={}
 for f in POL.glob('*.json'):
  p=load(f,{})
  if p.get('protocol')=='vless':ps[p.get('user',f.stem)]=p
 cur=stats()
 now=int(time.time())
 seen=scan_ips(ps,window,now)
 for u,p in ps.items():
  x=st.setdefault(u,{'used_bytes':0,'last_counter':0,'locked':False,'reason':'','ip_seen':{},'ip_violation_checks':0})
  if cur is not None:
   c=cur.get(u,0);oldc=int(x.get('last_counter',0));d=c-oldc if c>=oldc else c
   if d>0:x['used_bytes']=int(x.get('used_bytes',0))+d
   x['last_counter']=c
  # Access logs record accepted requests, not device/session lifetimes.
  # Require renewed activity since the previous poll, then retain only a
  # stable overlapping cohort through rotation grace and confirmation.
  if x.get('ip_observation_version')!=2:
   clear_ip_state(x)
  previous=int(x.get('ip_previous_check',0))
  interval=max(10,int(cfg.get('check_interval_seconds',60)))
  contiguous=bool(previous and 0<now-previous<=max(window,interval*2))
  first_seen=x.setdefault('ip_first_seen',{})
  activity=seen.get(u,{})
  for a,z in activity.items():
   if a not in first_seen:first_seen[a]=int(z.get('first',now))
  first_seen={a:int(t) for a,t in first_seen.items() if a in activity}
  x['ip_first_seen']=first_seen
  qualified={};details={}
  for a,z in activity.items():
   hits=int(z.get('hits',0));last=int(z.get('last',0));first=int(first_seen.get(a,z.get('first',now)))
   age=max(0,now-first);last_age=max(0,now-last)
   fresh=bool(contiguous and previous<last<=now)
   ok=(fresh and hits>=min_hits and age>=grace)
   details[a]={'hits':hits,'age':age,'last_age':last_age,'fresh':fresh,'qualified':ok}
   if ok:qualified[a]=last
  x['ip_seen']=qualified;x['ip_count']=len(qualified);x['ips']=sorted(qualified);x['ip_activity']=details;x['last_check']=now
  x['ip_previous_check']=now
  q=int(p.get('quota_bytes',0));lim=int(p.get('ip_limit',0))
  quota_hit=bool(q and x['used_bytes']>=q)
  rotation_grace=max(0,int(cfg.get('ip_rotation_grace_seconds',180)))
  ip_hit=bool(lim>0 and len(qualified)>lim)
  if ip_hit:
   overlap=set(x.get('ip_overlap',[])) & set(qualified)
   if len(overlap)<=lim:
    overlap=set(qualified)
    x['ip_overlap_since']=now;x['ip_violation_checks']=0
   x['ip_overlap']=sorted(overlap)
   elapsed=max(0,now-int(x.get('ip_overlap_since',now)))
   if elapsed>=rotation_grace:
    x['ip_violation_checks']=int(x.get('ip_violation_checks',0))+1
   log('IP-CHECK '+u+': qualified='+','.join(x['ips'])+' count='+str(x['ip_count'])+'/'+str(lim)+' overlap='+','.join(x['ip_overlap'])+' grace='+str(elapsed)+'/'+str(rotation_grace)+' confirm='+str(x['ip_violation_checks'])+'/'+str(confirm))
  else:
   x['ip_violation_checks']=0
   x.pop('ip_overlap',None);x.pop('ip_overlap_since',None)
  confirmed_ip=ip_hit and x['ip_violation_checks']>=confirm
  reason='QUOTA_EXCEEDED' if quota_hit else ('IP_LIMIT' if confirmed_ip else '')
  pending=x.get('runtime_pending')
  # A lock intent survives a partial API failure. Never label it verified early.
  want_lock=(pending=='lock' or (p.get('auto_lock',True) and reason and not x.get('locked') and (pending!='unlock' or quota_hit)))
  if x.get('locked') and quota_hit:
   x['reason']='QUOTA_EXCEEDED';x['unlock_at']=0
   if pending=='unlock':x.pop('runtime_pending',None);pending=None
  want_unlock=(pending=='unlock' or
               (x.get('locked') and x.get('reason')=='IP_LIMIT' and
                now>=int(x.get('unlock_at') or (int(x.get('locked_at',now))+lockdur))))
  if want_lock:
   lock_reason=reason or x.get('reason') or 'IP_LIMIT'
   x.update(reason=lock_reason,runtime_pending='lock')
   if set_runtime(u,False):
    x.update(locked=True,locked_at=now,unlock_at=(now+lockdur if lock_reason=='IP_LIMIT' else 0))
    x.pop('runtime_pending',None);x.pop('runtime_error',None)
    log('LOCK '+u+': '+lock_reason+' verified=WS+XHTTP')
   else:
    x['runtime_error']='WS/XHTTP lock incomplete'
  elif want_unlock and not quota_hit:
   x['runtime_pending']='unlock'
   if uuid(u) and restore_user(u):
    x.update(locked=False,reason='',locked_at=0,unlock_at=0)
    x.pop('runtime_pending',None);x.pop('runtime_error',None)
    clear_ip_state(x)
    log('AUTO-UNLOCK '+u+' verified=configured-inbounds xray_restart=NO')
   else:x['runtime_error']='WS/XHTTP unlock incomplete'
  elif x.get('locked'):
   # Enforce locked accounts again after an external Xray restart.
   if set_runtime(u,False):
    x.pop('runtime_pending',None);x.pop('runtime_error',None)
   else:
    x['runtime_pending']='lock';x['runtime_error']='WS/XHTTP lock incomplete'
 save(STATE,st)
if __name__=='__main__':
 with (BASE/'runtime.lock').open('a') as lock:
  try:fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
  except BlockingIOError:
   print('Another Account Control operation is running; retry shortly.')
   sys.exit(1 if len(sys.argv)>1 else 0)
  try:
   if len(sys.argv)==3 and sys.argv[1]=='--unlock':
    sys.exit(unlock_account(sys.argv[2]))
   elif len(sys.argv)>1:
    print('Usage: jsphantom-account-control [--unlock USER]');sys.exit(1)
   else:main()
  except Exception as e:
   log('ERROR '+str(e));print('Account Control error: '+str(e));sys.exit(1)

