#!/usr/bin/env python3
import os,sys,json,time,hmac,hashlib,secrets,base64,html,re,copy,urllib.parse,subprocess,email.parser,email.policy
from pathlib import Path
from http.server import ThreadingHTTPServer,BaseHTTPRequestHandler
from http.cookies import SimpleCookie
BASE=Path('/etc/jsphantom/central'); DATA=BASE/'data.json'; AUTH=BASE/'auth.json'; SESS=BASE/'sessions.json'; IMAGES=BASE/'images'; HOST='shin1.btvpn-my.eu.org'
# JSPHANTOM_SYNC_V11
SYNC=BASE/'sync-requests.json'
# JSPHANTOM_SYNC_V12


DEFAULT={'contacts':{'whatsapp':'','telegram':''},'tutorial':{'android_title':'Android · NetMod Syna','android_text':'Copy config → import → Play','android_app_url':'https://play.google.com/store/apps/details?id=com.netmod.syna','android_app_button':'Download Android APP','android_image':'android.jpg','ios_title':'iOS · V2Box','ios_text':'Copy config, import dan connect.','ios_url':'','ios_button':'WATCH iOS TUTORIAL','ios_app_url':'https://apps.apple.com/app/id6446814690','ios_app_button':'Download iOS APP'},'text':{'heading':'JsPhantom User Detail','contact_heading':'Contact Admin','contact_note':'Perlukan bantuan? Hubungi admin.'},'buttons':[],'servers':{}}
def atomic(path,data):
 path.parent.mkdir(parents=True,exist_ok=True); t=path.with_name(path.name+'.tmp-'+secrets.token_hex(4)); t.write_text(json.dumps(data,ensure_ascii=False,indent=2)); os.chmod(t,0o600); os.replace(t,path)
def read(p,default):
 try:return json.loads(p.read_text())
 except (OSError,ValueError):return copy.deepcopy(default)
def backup():
 b=BASE/'backups';b.mkdir(exist_ok=True); p=b/(time.strftime('%Y%m%d-%H%M%S')+'-'+secrets.token_hex(3)+'.json');p.write_bytes(DATA.read_bytes());os.chmod(p,0o600)
 for old in sorted(b.glob('*.json'))[:-30]:old.unlink()
def hashpass(password,salt=None):
 salt=salt or secrets.token_bytes(16); return salt.hex(),hashlib.scrypt(password.encode(),salt=salt,n=16384,r=8,p=1).hex()
def init():
 BASE.mkdir(parents=True,exist_ok=True);os.chmod(BASE,0o700);IMAGES.mkdir(exist_ok=True);os.chmod(IMAGES,0o700)
 if not DATA.exists():atomic(DATA,DEFAULT)
 if not SESS.exists():atomic(SESS,{})
def setup():
 import getpass
 init();print('JsPhantom Central Admin — set password (minimum 12 characters)')
 a=getpass.getpass('Password: ');b=getpass.getpass('Confirm: ')
 if a!=b or len(a)<12:sys.exit('Password mismatch or too short')
 salt,digest=hashpass(a);atomic(AUTH,{'salt':salt,'digest':digest});atomic(SESS,{});print('Admin password saved')
def add_server(name):
 init()
 if not re.fullmatch(r'[a-zA-Z0-9_-]{1,32}',name):sys.exit('Invalid server name')
 d=read(DATA,DEFAULT)
 if name in d['servers']:sys.exit('Server already exists')
 token=secrets.token_urlsafe(36);d['servers'][name]={'token_hash':hashlib.sha256(token.encode()).hexdigest(),'created':int(time.time()),'last_seen':0};backup();atomic(DATA,d)
 print('Server:',name,'\nAgent token (SAVE NOW; shown once):',token)
def esc(v):return html.escape(str(v),quote=True)
def input_field(name,value,kind='text'):
 return f'<label>{esc(name)}<input name="{esc(name)}" type="{kind}" value="{esc(value)}" maxlength="2000"></label>'
CSS='''<style>*{box-sizing:border-box}body{font:15px system-ui;background:#0b1020;color:#e8ecf5;margin:0;padding:24px}main{max-width:850px;margin:auto}section{background:#121a2e;border:1px solid #263250;border-radius:16px;padding:22px;margin:15px 0}input,textarea,select{width:100%;padding:11px;background:#0b1020;color:#fff;border:1px solid #45516b;border-radius:8px;margin:6px 0 12px}label{display:block;margin-top:7px}button{background:#63a8ff;color:#081020;padding:11px 18px;border:0;border-radius:8px;font-weight:bold;cursor:pointer}a{color:#80bbff}h1{margin:0 0 8px}.muted{color:#9eacc8}small{color:#9eacc8}nav a{margin-right:18px}img{max-width:280px;border-radius:10px}</style>'''
class H(BaseHTTPRequestHandler):
 def log_message(self,fmt,*args):pass
 def send(self,body,status=200,ctype='text/html; charset=utf-8',extra=None):
  raw=body.encode() if isinstance(body,str) else body;self.send_response(status);self.send_header('Content-Type',ctype);self.send_header('Content-Length',str(len(raw)));self.send_header('Cache-Control','no-store');self.send_header('X-Content-Type-Options','nosniff');self.send_header('X-Frame-Options','DENY');self.send_header('Referrer-Policy','same-origin');self.send_header('Content-Security-Policy',"default-src 'none'; style-src 'unsafe-inline'; img-src 'self' data:; form-action 'self'; base-uri 'none'")
  for k,v in (extra or {}).items():self.send_header(k,v)
  self.end_headers();self.wfile.write(raw)
 def form(self):
  n=int(self.headers.get('Content-Length','0'))
  if n>3*1024*1024:raise ValueError('Request too large')
  return urllib.parse.parse_qs(self.rfile.read(n).decode('utf-8'),keep_blank_values=True)
 def val(self,f,k):return f.get(k,[''])[0]
 def session(self):
  cookie=SimpleCookie()
  try:cookie.load(self.headers.get('Cookie',''))
  except Exception:return None
  if 'jspsid' not in cookie:return None
  sid=cookie['jspsid'].value; sessions=read(SESS,{})
  s=sessions.get(hashlib.sha256(sid.encode()).hexdigest())
  return s if s and s.get('expires',0)>time.time() else None
 def page(self,body):return '<!doctype html><html lang="ms"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'+CSS+'<main><h1>JsPhantom Central Admin</h1><p class="muted">Shinjiru · 3 VPS management</p>'+body+'</main></html>'
 def agent(self,name):
  d=read(DATA,DEFAULT);s=d.get('servers',{}).get(name)
  tok=self.headers.get('Authorization','').removeprefix('Bearer ').strip()
  if not s or not hmac.compare_digest(s['token_hash'],hashlib.sha256(tok.encode()).hexdigest()):self.send('Unauthorized',401);return
  s['last_seen']=int(time.time());atomic(DATA,d)
  imgs={}
  for p in IMAGES.iterdir():
   if p.is_file() and p.suffix.lower() in ('.png','.jpg','.jpeg','.webp') and p.stat().st_size<=2*1024*1024:imgs[p.name]=base64.b64encode(p.read_bytes()).decode()
  payload={'contacts':d['contacts'],'tutorial':d['tutorial'],'text':d['text'],'buttons':d['buttons'],'images':imgs}
  self.send(json.dumps(payload,ensure_ascii=False),ctype='application/json')
 def do_GET(self):
  p=urllib.parse.urlsplit(self.path).path
  if p.startswith('/admin/api/sync-command/'):
   name=p.rsplit('/',1)[-1]
   d=read(DATA,DEFAULT);server=d.get('servers',{}).get(name)
   token=self.headers.get('Authorization','').removeprefix('Bearer ').strip()
   if not server or not hmac.compare_digest(server['token_hash'],hashlib.sha256(token.encode()).hexdigest()):self.send('Unauthorized',401);return
   req=read(SYNC,{}).get(name,{})
   self.send(json.dumps({'id':req.get('id','') if req.get('status')=='pending' else ''}),ctype='application/json');return
  if p.startswith('/admin/api/agent/'):
   self.agent(p.rsplit('/',1)[-1]);return
  if p.startswith('/admin/image/'):
   if not self.session():self.send('Forbidden',403);return
   name=p.rsplit('/',1)[-1]
   if not re.fullmatch(r'[\w.-]+\.(jpg|jpeg|png|webp)',name,re.I):self.send('Not found',404);return
   f=IMAGES/name
   if not f.is_file():self.send('Not found',404);return
   ct={'.jpg':'image/jpeg','.jpeg':'image/jpeg','.png':'image/png','.webp':'image/webp'}[f.suffix.lower()];self.send(f.read_bytes(),ctype=ct);return
  if p not in ('/admin/','/admin/login','/admin/logout'):self.send('Not found',404);return
  s=self.session()
  if p=='/admin/logout':self.send('Use logout button',405);return
  if not s:
   self.send(self.page('<section><h2>Login</h2><form method="post" action="/admin/login"><input name="password" type="password" autocomplete="current-password" required><button>Login</button></form></section>'));return
  d=read(DATA,DEFAULT);csrf=esc(s['csrf']);body='<nav><a href="/admin/">Dashboard</a></nav><section><h2>Servers</h2>'
  syncs=read(SYNC,{})
  for name,server in d['servers'].items():
   state=syncs.get(name,{})
   status=state.get('status','not requested')
   when=time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(state['updated'])) if state.get('updated') else '-'
   body+=f'<p>🖥️ {esc(name)} — '+('Online recently' if time.time()-server.get('last_seen',0)<240 else 'Not synced recently')+f' | Sync: <strong>{esc(status)}</strong> ({esc(when)})</p>'
   last=state.get('last_success',0)
   laststr=time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(last)) if isinstance(last,(int,float)) and last>0 else 'Never'
   body+='<p class="muted">Last successful sync: '+esc(laststr)+'</p>'
   body+='<form method="post" action="/admin/request-sync"><input type="hidden" name="csrf" value="'+csrf+'"><input type="hidden" name="server" value="'+esc(name)+'"><button>Sync Now · '+esc(name)+'</button></form>'

  if d['servers']:
   body+='<form method="post" action="/admin/request-sync-all"><input type="hidden" name="csrf" value="'+csrf+'"><button>Sync All VPS</button></form><p class="muted">Queues registered servers that are not already pending. No automatic sync on Save.</p>'
  body+='</section><section><h2>Contact Admin</h2><form method="post" action="/admin/save"><input type="hidden" name="csrf" value="'+csrf+'"><input type="hidden" name="section" value="contacts">'
  for k,v in d['contacts'].items():body+=input_field(k,v)
  body+='<button>Save Contacts</button></form></section><section><h2>Tutorial Editor</h2><form method="post" action="/admin/save"><input type="hidden" name="csrf" value="'+csrf+'"><input type="hidden" name="section" value="tutorial">'
  for k,v in d['tutorial'].items():body+=input_field(k,v)
  body+='<button>Save Tutorial</button></form></section><section><h2>Text Editor</h2><form method="post" action="/admin/save"><input type="hidden" name="csrf" value="'+csrf+'"><input type="hidden" name="section" value="text">'
  for k,v in d['text'].items():body+=input_field(k,v)
  body+='<button>Save Text</button></form></section><section><h2>Custom Buttons</h2><p class="muted">Maximum 8. Button settings sync to agents; customer page renderer needs V2.4 integration to display them.</p><form method="post" action="/admin/buttons"><input type="hidden" name="csrf" value="'+csrf+'">'
  for i in range(8):
   b=d['buttons'][i] if i<len(d['buttons']) else {};body+=f'<h3>Button {i+1}</h3>'+input_field('label'+str(i),b.get('label',''))+input_field('url'+str(i),b.get('url',''))
  body+='<button>Save Buttons</button></form></section><section><h2>Upload Tutorial Image</h2><p class="muted">Use JPG/PNG/WEBP image (max 2 MB). Uploaded image name can be selected in tutorial android_image field.</p><form method="post" action="/admin/upload" enctype="multipart/form-data"><input type="hidden" name="csrf" value="'+csrf+'"><label>Image file</label><input type="file" name="image" accept="image/png,image/jpeg,image/webp" required><button>Upload Image</button></form></section><section><form method="post" action="/admin/logout"><input type="hidden" name="csrf" value="'+csrf+'"><button>Logout</button></form></section>'
  self.send(self.page(body))
 def do_POST(self):
  p=urllib.parse.urlsplit(self.path).path
  if p not in ('/admin/login','/admin/save','/admin/buttons','/admin/logout','/admin/upload','/admin/request-sync','/admin/request-sync-all','/admin/api/sync-ack'):self.send('Not found',404);return
  if p=='/admin/api/sync-ack':
   try:
    n=int(self.headers.get('Content-Length','0'))
    if n<1 or n>4096:raise ValueError()
    msg=json.loads(self.rfile.read(n))
    name=msg.get('name','');rid=msg.get('id','');status=msg.get('status','')
    if not re.fullmatch(r'[A-Za-z0-9_-]{1,32}',name) or not re.fullmatch(r'[a-f0-9]{32}',rid) or status not in ('success','failed'):raise ValueError()
    d=read(DATA,DEFAULT);server=d.get('servers',{}).get(name)
    token=self.headers.get('Authorization','').removeprefix('Bearer ').strip()
    if not server or not hmac.compare_digest(server['token_hash'],hashlib.sha256(token.encode()).hexdigest()):self.send('Unauthorized',401);return
    requests=read(SYNC,{})
    if requests.get(name,{}).get('id')!=rid:self.send('Stale request',409);return
    now=int(time.time())
    requests[name]['status']=status;requests[name]['updated']=now
    if status=='success':requests[name]['last_success']=now
    atomic(SYNC,requests)
    self.send('OK');return
   except (ValueError,TypeError,KeyError,json.JSONDecodeError):self.send('Bad request',400);return
  origin=self.headers.get('Origin')
  if origin=='null':
   if not self.headers.get('Referer','').startswith('https://'+HOST+'/admin/'):
    self.send('Bad origin',403);return
  elif origin not in (None,'https://'+HOST):
   self.send('Bad origin',403);return
  if p=='/admin/upload':
   s=self.session()
   if not s:self.send('Forbidden',403);return
   try:
    n=int(self.headers.get('Content-Length','0'))
    if n<1 or n>2300000:raise ValueError()
    content_type=self.headers.get('Content-Type','')
    if not content_type.startswith('multipart/form-data;'):raise ValueError()
    msg=email.parser.BytesParser(policy=email.policy.default).parsebytes(b'Content-Type: '+content_type.encode()+b'\r\nMIME-Version: 1.0\r\n\r\n'+self.rfile.read(n))
    parts={part.get_param('name',header='content-disposition'):part for part in msg.iter_parts()}
    csrf=parts['csrf'].get_content().strip()
    if not hmac.compare_digest(csrf,s['csrf']):raise ValueError()
    part=parts['image'];name=Path(part.get_filename() or '').name
    raw=part.get_payload(decode=True)
    if not re.fullmatch(r'[\w.-]+\.(jpg|jpeg|png|webp)',name,re.I) or len(raw)>2*1024*1024:raise ValueError()
    valid=(raw.startswith(b'\xff\xd8\xff') and name.lower().endswith(('.jpg','.jpeg'))) or (raw.startswith(b'\x89PNG\r\n\x1a\n') and name.lower().endswith('.png')) or (raw[:4]==b'RIFF' and raw[8:12]==b'WEBP' and name.lower().endswith('.webp'))
    if not valid:raise ValueError()
    dest=IMAGES/name;dest.write_bytes(raw);os.chmod(dest,0o600)
   except Exception:self.send('Invalid image upload',400);return
   self.send('',303,extra={'Location':'/admin/'});return
  try:f=self.form()
  except (ValueError,UnicodeDecodeError):self.send('Bad request',400);return
  if p=='/admin/login':
   auth=read(AUTH,{});password=self.val(f,'password');salt=auth.get('salt','')
   try:_,digest=hashpass(password,bytes.fromhex(salt))
   except Exception:digest=''
   if not hmac.compare_digest(digest,auth.get('digest','')):
    time.sleep(2);self.send(self.page('<section>Login failed. <a href="/admin/">Try again</a></section>'),403);return
   sid=secrets.token_urlsafe(36);sessions=read(SESS,{});sessions={k:v for k,v in sessions.items() if v.get('expires',0)>time.time()};sessions[hashlib.sha256(sid.encode()).hexdigest()]={'csrf':secrets.token_urlsafe(24),'expires':time.time()+28800};atomic(SESS,sessions)
   self.send('',303,extra={'Location':'/admin/','Set-Cookie':'jspsid='+sid+'; HttpOnly; Secure; SameSite=Strict; Path=/admin/; Max-Age=28800'});return
  s=self.session()
  if not s or not hmac.compare_digest(self.val(f,'csrf'),s['csrf']):self.send('Forbidden',403);return
  if p=='/admin/request-sync-all':
   d=read(DATA,DEFAULT);requests=read(SYNC,{})
   for name in d.get('servers',{}):
    prev=requests.get(name,{})
    if prev.get('status')=='pending':continue
    requests[name]={'id':secrets.token_hex(16),'status':'pending','updated':int(time.time()),'last_success':prev.get('last_success',0)}
   atomic(SYNC,requests)
   self.send('',303,extra={'Location':'/admin/'});return
  if p=='/admin/request-sync':
   name=self.val(f,'server');d=read(DATA,DEFAULT)
   if name not in d.get('servers',{}):self.send('Unknown server',404);return
   requests=read(SYNC,{})
   if requests.get(name,{}).get('status')=='pending':self.send('Sync already pending',409);return
   prev=requests.get(name,{})
   requests[name]={'id':secrets.token_hex(16),'status':'pending','updated':int(time.time()),'last_success':prev.get('last_success',0)}
   atomic(SYNC,requests)
   self.send('',303,extra={'Location':'/admin/'});return
  if p=='/admin/logout':
   cookie=SimpleCookie();cookie.load(self.headers.get('Cookie',''));sid=cookie.get('jspsid');sessions=read(SESS,{})
   if sid:sessions.pop(hashlib.sha256(sid.value.encode()).hexdigest(),None);atomic(SESS,sessions)
   self.send('',303,extra={'Location':'/admin/','Set-Cookie':'jspsid=; Max-Age=0; Path=/admin/; Secure; HttpOnly; SameSite=Strict'});return
  d=read(DATA,DEFAULT);backup()
  if p=='/admin/save':
   section=self.val(f,'section')
   if section not in ('contacts','tutorial','text'):self.send('Invalid section',400);return
   for k in d[section]:
    v=self.val(f,k).strip()
    if len(v)>2000:self.send('Too long',400);return
    if ('url' in k or k=='ios_url') and v and not v.startswith('https://'):self.send('URLs must use HTTPS',400);return
    if k=='android_image' and not re.fullmatch(r'[\w.-]+\.(jpg|jpeg|png|webp)',v,re.I):self.send('Invalid image filename',400);return
    d[section][k]=v
  else:
   buttons=[]
   for i in range(8):
    label=self.val(f,'label'+str(i)).strip();url=self.val(f,'url'+str(i)).strip()
    if label and url:
     if len(label)>80 or len(url)>1000 or not url.startswith('https://'):self.send('Invalid button',400);return
     buttons.append({'label':label,'url':url})
   d['buttons']=buttons
  atomic(DATA,d);self.send('',303,extra={'Location':'/admin/'})
if __name__=='__main__':
 if len(sys.argv)>1:
  if sys.argv[1]=='setup':setup()
  elif sys.argv[1]=='add-server' and len(sys.argv)==3:add_server(sys.argv[2])
  elif sys.argv[1]=='image' and len(sys.argv)==4:
   init();name=sys.argv[2];p=Path(sys.argv[3]);raw=p.read_bytes()
   if not re.fullmatch(r'[\w.-]+\.(jpg|jpeg|png|webp)',name,re.I) or len(raw)>2*1024*1024:sys.exit('Invalid filename or size')
   valid=(raw.startswith(b'\xff\xd8\xff') and name.lower().endswith(('.jpg','.jpeg'))) or (raw.startswith(b'\x89PNG\r\n\x1a\n') and name.lower().endswith('.png')) or (raw[:4]==b'RIFF' and raw[8:12]==b'WEBP' and name.lower().endswith('.webp'))
   if not valid:sys.exit('Image type mismatch')
   (IMAGES/name).write_bytes(raw);os.chmod(IMAGES/name,0o600);print('Image installed:',name)
  else:sys.exit('Usage: central.py setup | add-server NAME | image NAME PATH')
 else:
  init();ThreadingHTTPServer(('127.0.0.1',9090),H).serve_forever()
