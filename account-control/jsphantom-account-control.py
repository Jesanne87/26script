#!/usr/bin/env python3
import re,json,time,subprocess,base64
from pathlib import Path
CFG=Path('/usr/local/etc/xray/config.json'); ACCESS=Path('/var/log/xray/access.log'); BASE=Path('/etc/jsphantom/account-control'); POL=BASE/'policies'; STATE=BASE/'state.json'; SETTINGS=BASE/'settings.json'; LOG=Path('/var/log/jsphantom-account-control.log'); XRAY='/usr/local/bin/xray'; API='127.0.0.1:10000'; TAGS=['vless-ws','vless-xhttp']
BASE.mkdir(parents=True,exist_ok=True); POL.mkdir(parents=True,exist_ok=True)
def load(p,d):
 try:return json.loads(p.read_text())
 except:return d
def save(p,o):
 t=Path(str(p)+'.tmp');t.write_text(json.dumps(o,indent=2));t.replace(p)
def log(x):
 with LOG.open('a') as f:f.write(time.strftime('%F %T ')+x+'\n')
def vi(v):
 b=b''
 while v>=128:b+=bytes([(v&127)|128]);v>>=7
 return b+bytes([v])
def fld(n,b):return bytes([(n<<3)|2])+vi(len(b))+b
def typed(n,b):return fld(1,n.encode())+fld(2,b)
def uuid(u):
 a=CFG.read_text(errors='ignore').splitlines()
 for i,l in enumerate(a[:-1]):
  if re.match(r'^#=\s+'+re.escape(u)+r'(?:\s|$)',l):
   m=re.search(r'"id"\s*:\s*"([^"]+)"',a[i+1])
   if m:return m.group(1)
def alter(tag,u,uid,add):
 gr='/usr/local/bin/grpcurl' if Path('/usr/local/bin/grpcurl').exists() else 'grpcurl'
 if add:
  acc=fld(1,uid.encode()); usr=fld(2,u.encode())+fld(3,typed('xray.proxy.vless.Account',acc)); op=fld(1,usr); typ='xray.app.proxyman.command.AddUserOperation'
 else: op=fld(1,u.encode());typ='xray.app.proxyman.command.RemoveUserOperation'
 req={'tag':tag,'operation':{'type':typ,'value':base64.b64encode(op).decode()}}
 return subprocess.run([gr,'-plaintext','-max-time','8','-d',json.dumps(req),API,'xray.app.proxyman.command.HandlerService/AlterInbound'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0
def restore_user(u,uid):
 # Idempotent unlock: clear a stale/partial API entry first, then add it back.
 # A missing/non-applicable tag is tolerated; at least one successful inbound
 # is enough to restore service. No Xray restart/reload is used.
 ok=[];bad=[]
 for tag in TAGS:
  alter(tag,u,'',False)  # best effort; also fixes partial/manual unlock states
  if alter(tag,u,uid,True): ok.append(tag)
  else: bad.append(tag)
 if ok:
  log('RESTORE '+u+': added='+','.join(ok)+((' skipped/failed='+','.join(bad)) if bad else '')+' xray_restart=NO')
  return True
 log('RESTORE-FAILED '+u+': tags='+','.join(bad))
 return False

def clear_ip_state(x):
 x['ip_violation_checks']=0
 x['ip_seen']={};x['ips']=[];x['ip_count']=0
 x['ip_activity']={};x['ip_first_seen']={}

def stats():
 try:s=subprocess.check_output([XRAY,'api','statsquery','--server='+API,''],stderr=subprocess.DEVNULL,text=True,timeout=12)
 except:return {}
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
  c=cur.get(u,0);oldc=int(x.get('last_counter',0));d=c-oldc if c>=oldc else c
  if d>0:x['used_bytes']=int(x.get('used_bytes',0))+d
  x['last_counter']=c
  # False-lock protection: an IP is counted only after it has enough
  # access hits AND has survived the new-IP grace period. Rotating telco
  # gateway IPs that flash briefly in the log therefore do not count.
  first_seen=x.setdefault('ip_first_seen',{})
  activity=seen.get(u,{})
  for a,z in activity.items():
   if a not in first_seen:first_seen[a]=int(z.get('first',now))
  first_seen={a:int(t) for a,t in first_seen.items() if a in activity or now-int(t)<=window}
  x['ip_first_seen']=first_seen
  qualified={}
  details={}
  for a,z in activity.items():
   hits=int(z.get('hits',0));last=int(z.get('last',0));first=int(first_seen.get(a,z.get('first',now)))
   age=max(0,now-first);last_age=max(0,now-last)
   ok=(hits>=min_hits and age>=grace)
   details[a]={'hits':hits,'age':age,'last_age':last_age,'qualified':ok}
   if ok:qualified[a]=last
  x['ip_seen']=qualified;x['ip_count']=len(qualified);x['ips']=sorted(qualified);x['ip_activity']=details;x['last_check']=now
  q=int(p.get('quota_bytes',0));lim=int(p.get('ip_limit',0))
  quota_hit=bool(q and x['used_bytes']>=q)
  ip_hit=bool(lim and x['ip_count']>lim)
  if ip_hit:
   x['ip_violation_checks']=int(x.get('ip_violation_checks',0))+1
   log('IP-CHECK '+u+': qualified='+','.join(x.get('ips',[]))+' count='+str(x['ip_count'])+'/'+str(lim)+' confirm='+str(x['ip_violation_checks'])+'/'+str(confirm))
  else:x['ip_violation_checks']=0
  confirmed_ip=ip_hit and x['ip_violation_checks']>=confirm
  reason='QUOTA_EXCEEDED' if quota_hit else ('IP_LIMIT' if confirmed_ip else '')
  if p.get('auto_lock',True) and reason and not x.get('locked'):
   if all(alter(t,u,'',False) for t in TAGS):
    x.update(locked=True,reason=reason,locked_at=now,unlock_at=(now+lockdur if reason=='IP_LIMIT' else 0))
    log('LOCK '+u+': '+reason+' ips='+','.join(x.get('ips',[]))+' checks='+str(x.get('ip_violation_checks',0)))
  elif x.get('locked') and x.get('reason')=='IP_LIMIT' and now>=int(x.get('unlock_at') or (int(x.get('locked_at',now))+lockdur)):
   uid=uuid(u)
   if uid and restore_user(u,uid):
    x.update(locked=False,reason='',locked_at=0,unlock_at=0)
    clear_ip_state(x)
    log('AUTO-UNLOCK '+u+' xray_restart=NO')
 save(STATE,st)
if __name__=='__main__':main()
