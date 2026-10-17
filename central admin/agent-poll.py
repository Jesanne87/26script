#!/usr/bin/env python3
import sys,json,urllib.request,ssl,os,re,hashlib
sys.path.insert(0,'/opt/jsphantom-agent')
import agent_safe as a
MASTER='https://shin1.btvpn-my.eu.org'
def request(path,payload=None):
 c=a.read_json(a.CFG);name=c['name'];token=c['token']
 if not re.fullmatch(r'[A-Za-z0-9_-]{1,32}',name) or len(token)<30:raise ValueError('Invalid agent credentials')
 data=json.dumps(payload).encode() if payload is not None else None
 headers={'Authorization':'Bearer '+token,'User-Agent':'JsPhantomSyncOnDemand/1.1'}
 if data is not None:headers['Content-Type']='application/json'
 req=urllib.request.Request(MASTER+path,headers=headers,data=data)
 with urllib.request.urlopen(req,timeout=20,context=ssl.create_default_context()) as r:return json.loads(r.read(8192)) if payload is None else r.read(8192)
def main():
 if os.geteuid()!=0:raise ValueError('Run as root')
 c=a.read_json(a.CFG);name=c['name']
 cmd=request('/admin/api/sync-command/'+name)
 rid=cmd.get('id','')
 if not rid:return
 if not re.fullmatch(r'[a-f0-9]{32}',rid):raise ValueError('Invalid sync request ID')
 print('Sync request received:',rid,flush=True)
 try:
  d,imgs=a.fetch()
  a.diff(d,imgs)
  # JSPHANTOM_SYNC_V12: skip all writes/backups if every target is identical.
  targets=a.target_data(d)
  same=all(a.read_json(a.BASE/filename)==value for filename,value in targets.items())
  if same:
   for filename,blob in imgs.items():
    target=a.BASE/'tutorials'/filename
    if not target.is_file() or hashlib.sha256(target.read_bytes()).digest()!=hashlib.sha256(blob).digest():
     same=False;break
  if same:print('SKIP UNCHANGED: no files written, no backup needed',flush=True)
  else:a.apply(d,imgs)
  status='success'
 except Exception as e:
  print('SYNC FAILED:',str(e),file=sys.stderr,flush=True)
  status='failed'
 request('/admin/api/sync-ack',{'name':name,'id':rid,'status':status})
 if status!='success':sys.exit(1)
if __name__=='__main__':main()
