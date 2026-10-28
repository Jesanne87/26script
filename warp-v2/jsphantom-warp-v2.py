#!/usr/bin/env python3
"""JsPhantom WARP V2: preserves original Xray account comments and unmanaged rules."""
import argparse, datetime, json, os, pathlib, re, shutil, socket, subprocess, sys, tempfile
ROOT=pathlib.Path('/etc/jsphantom/warp-v2')
STATE=ROOT/'settings.json'
BACK=ROOT/'backups'
CONFIG=pathlib.Path(os.environ.get('JSPHANTOM_XRAY_CONFIG','/usr/local/etc/xray/config.json'))
DEFAULT={'mode':'off','domains':[],'inbounds':['vless-ws','vless-xhttp'],'port':40000}
START='# JSPHANTOM_WARP_V2_START'
END='# JSPHANTOM_WARP_V2_END'

def run(cmd): return subprocess.run(cmd,text=True,capture_output=True)
def load():
    if STATE.exists():
        d=json.loads(STATE.read_text()); return {**DEFAULT,**d}
    return dict(DEFAULT)
def save(d):
    ROOT.mkdir(parents=True,exist_ok=True)
    tmp=STATE.with_suffix('.tmp');tmp.write_text(json.dumps(d,indent=2)+'\n');os.chmod(tmp,0o600);os.replace(tmp,STATE)
def strip_comments(s):
    return '\n'.join(line for line in s.splitlines() if not line.lstrip().startswith('#'))
def json_obj(s): return json.loads(strip_comments(s))
def find_array(text, parent, name):
    # Locate a named property inside a parent object using JSON tokenization.
    start=0 if parent is None else parent[0]
    end=len(text) if parent is None else parent[1]
    m=re.search(r'"'+re.escape(name)+r'"\s*:\s*\[',text[start:end])
    if not m: raise ValueError('Array not found: '+name)
    a=start+m.end()-1
    return a,closing(text,a,'[',']')
def find_object(text,name):
    m=re.search(r'"'+re.escape(name)+r'"\s*:\s*\{',text)
    if not m: raise ValueError('Object not found: '+name)
    a=m.end()-1;return a,closing(text,a,'{','}')
def closing(s,a,left,right):
    depth=0;quoted=False;esc=False;comment=False
    for i in range(a,len(s)):
        c=s[i]
        if comment:
            if c=='\n':comment=False
            continue
        if quoted:
            if esc:esc=False
            elif c=='\\':esc=True
            elif c=='"':quoted=False
            continue
        if c=='#' and (i==0 or s[s.rfind('\n',0,i)+1:i].strip()==''):comment=True;continue
        if c=='"':quoted=True;continue
        if c==left:depth+=1
        if c==right:
            depth-=1
            if depth==0:return i
    raise ValueError('Unbalanced '+left)
def array_items(s,a,b):
    out=[];i=a+1
    while i<b:
        if s[i].isspace() or s[i]==',':i+=1;continue
        if s[i]=='#':
            i=s.find('\n',i)+1
            if i==0:break
            continue
        if s[i]!='{':raise ValueError('Expected object in array')
        e=closing(s,i,'{','}');out.append((s[i:e+1],json_obj(s[i:e+1])));i=e+1
    return out
def replace_array(s,a,b,items):
    return s[:a+1]+'\n'+',\n'.join('      '+raw.replace('\n','\n      ') for raw,obj in items)+'\n    '+s[b:]
def render_rule(rule):return json.dumps(rule,indent=2,ensure_ascii=False)
def managed(s):
    if START in s or END in s:
        if s.count(START)!=1 or s.count(END)!=1:raise ValueError('Malformed managed markers')
        s=re.sub(r'\s*'+re.escape(START)+r'.*?'+re.escape(END)+r'\s*', '\n',s,flags=re.S)
    return s

def transform(src,d):
    s=managed(src)
    # Ensure no accidental duplication, preserve existing account comments and rules.
    ra,rb=find_array(s,find_object(s,'routing'),'rules')
    items=array_items(s,ra,rb)
    clean=[]
    for raw,obj in items:
        if obj.get('outboundTag') == 'jsphantom-warp-v2':
            continue # Remove all previously managed WARP rules before rebuilding.
        if obj.get('outboundTag') in ('WARP-socks5-v4','WARP-socks5-v6') and 'domain' in obj:
            continue # Legacy domain rules are migrated during install.
        clean.append((raw,obj))
    # A full-mode catch-all must follow blocking and API rules, and precede normal routing.
    idx=0
    for i,(_,o) in enumerate(clean):
        if o.get('outboundTag') in ('blocked','api'):
            idx=i+1
    rules=[]
    if d['mode']=='full':
        rules=[{'type':'field','inboundTag':d['inbounds'],'outboundTag':'jsphantom-warp-v2'}]
    elif d['mode']=='selective' and d['domains']:
        rules=[{'type':'field','inboundTag':d['inbounds'],'domain':d['domains'],'outboundTag':'jsphantom-warp-v2'}]
    for n,r in enumerate(rules):clean.insert(idx+n,(render_rule(r),r))
    s=replace_array(s,ra,rb,clean)
    oa,ob=find_array(s,None,'outbounds')
    outs=array_items(s,oa,ob)
    outs=[(raw,o) for raw,o in outs if o.get('tag')!='jsphantom-warp-v2']
    outbound={'tag':'jsphantom-warp-v2','protocol':'socks','settings':{'servers':[{'address':'127.0.0.1','port':d['port']}]}}
    outs.append((render_rule(outbound),outbound))
    s=replace_array(s,oa,ob,outs)
    # Xray accepts # comments; never rewrite the user-client array.
    return s

def test(path):
    if shutil.which('xray') is None:raise RuntimeError('xray binary not found')
    p=run(['xray','run','-test','-config',str(path)])
    if p.returncode:raise RuntimeError('Xray config test failed: '+(p.stderr+p.stdout)[-1200:])
def service_active():return run(['systemctl','is-active','xray']).stdout.strip()=='active'
def backup_file():
    BACK.mkdir(parents=True,exist_ok=True)
    name=datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    dest=BACK/name;dest.mkdir(mode=0o700)
    shutil.copy2(CONFIG,dest/'config.json')
    if STATE.exists():shutil.copy2(STATE,dest/'settings.json')
    return dest

def apply(d):
    if not CONFIG.is_file():raise RuntimeError('Xray config missing: '+str(CONFIG))
    if not service_active():raise RuntimeError('Xray service is not active; refusing live change')
    if d['mode'] in ('full','selective'):
        if run(['systemctl','is-active','wireproxy']).stdout.strip()!='active':
            raise RuntimeError('WireProxy is not active')
        try:
            with socket.create_connection(('127.0.0.1',d['port']),timeout=3):pass
        except OSError as e:
            raise RuntimeError('WireProxy SOCKS port is unreachable: '+str(e))
    src=CONFIG.read_text();new=transform(src,d)
    json_obj(new) # catch syntax errors, even if Xray permits comments
    if new==src:
        save(d);print('No Xray changes needed');return
    fd,tmp=tempfile.mkstemp(prefix='.jsphantom-warp-',suffix='.json',dir=str(CONFIG.parent));os.close(fd)
    try:
        pathlib.Path(tmp).write_text(new);os.chmod(tmp,CONFIG.stat().st_mode & 0o777)
        test(tmp)
        b=backup_file()
        try:
            os.replace(tmp,CONFIG)
            p=run(['systemctl','restart','xray'])
            if p.returncode or not service_active():raise RuntimeError('Xray restart failed: '+p.stderr)
            save(d)
        except Exception:
            shutil.copy2(b/'config.json',CONFIG)
            run(['systemctl','restart','xray'])
            raise
        print('Applied successfully. Backup:',b)
    finally:
        if os.path.exists(tmp):os.unlink(tmp)

def rollback(path):
    p=pathlib.Path(path).resolve()
    if p.parent!=BACK.resolve() or not (p/'config.json').is_file():raise ValueError('Invalid backup directory')
    test(p/'config.json')
    current=backup_file()
    try:
        shutil.copy2(p/'config.json',CONFIG)
        r=run(['systemctl','restart','xray'])
        if r.returncode or not service_active():raise RuntimeError('Restart failed')
        if (p/'settings.json').exists():shutil.copy2(p/'settings.json',STATE)
        else:save(DEFAULT)
    except Exception:
        shutil.copy2(current/'config.json',CONFIG)
        run(['systemctl','restart','xray'])
        raise
    print('Rollback completed; previous state saved:',current)

def diagnostic_routing(d):
    """Read Xray's hash-commented JSON without changing it."""
    try:
        cfg=json_obj(CONFIG.read_text())
        rules=cfg.get('routing',{}).get('rules',[])
        outbound_tags={o.get('tag') for o in cfg.get('outbounds',[])}
        tag='jsphantom-warp-v2'
        matches=[(i,r) for i,r in enumerate(rules,1) if r.get('outboundTag')==tag]
        print('WARP outbound:', 'present' if tag in outbound_tags else 'missing')
        print('WARP routing rules:',len(matches))
        for i,r in matches:
            print('  Rule',i,'| inbound:',','.join(r.get('inboundTag',[])) or '(any)',
                  '| domains:',','.join(r.get('domain',[])) or '(all)')
        expected=1 if d['mode']=='full' or (d['mode']=='selective' and d['domains']) else 0
        if len(matches)!=expected:
            print('WARNING: WARP rule count mismatch: expected',expected,'got',len(matches))
        if d['mode']=='selective' and any('domain' not in r for _,r in matches):
            print('WARNING: Full WARP catch-all rule exists in selective mode')
        if d['mode']=='off' and matches:
            print('WARNING: State OFF but WARP routing rules still exist')
        elif d['mode']=='selective' and d['domains'] and not matches:
            print('WARNING: Selective rules missing in Xray config')
        elif d['mode']=='full' and not matches:
            print('WARNING: Full mode rule missing in Xray config')
        legacy=[(i,r) for i,r in enumerate(rules,1) if r.get('outboundTag') in ('WARP-socks5-v4','WARP-socks5-v6')]
        if legacy: print('Legacy WARP rules remaining:',len(legacy))
        if matches and tag not in outbound_tags:
            print('WARNING: WARP rule references missing outbound')
    except Exception as e:
        print('WARP routing diagnostic error:',str(e))

def check(d):
    print('Mode:',d['mode'],'\nPort:',d['port'],'\nVLESS inbounds:',', '.join(d['inbounds']))
    print('Domains:',len(d['domains']),'\nXray:', 'active' if service_active() else 'inactive')
    print('WireProxy:',run(['systemctl','is-active','wireproxy']).stdout.strip() or 'unknown')
    try:
        with socket.create_connection(('127.0.0.1',d['port']),timeout=2):print('SOCKS TCP port: reachable (not proof of WARP egress)')
    except OSError:print('SOCKS TCP port: unreachable')
    if CONFIG.is_file():
        try:test(CONFIG);print('Xray config test: OK')
        except Exception as e:print('Xray config test:',e)
        diagnostic_routing(d)

def main():
    ap=argparse.ArgumentParser();sub=ap.add_subparsers(dest='cmd',required=True)
    for x in ('status','install','off','selective','full','list','backups'):sub.add_parser(x)
    a=sub.add_parser('add');a.add_argument('domain')
    a=sub.add_parser('delete');a.add_argument('domain')
    a=sub.add_parser('port');a.add_argument('number',type=int)
    a=sub.add_parser('rollback');a.add_argument('path')
    a=sub.add_parser('inbounds');a.add_argument('tags',nargs='+')
    args=ap.parse_args();d=load()
    if args.cmd=='status':check(d);return
    if args.cmd=='list':print('\n'.join(d['domains']) or '(empty)');return
    if args.cmd=='backups':print('\n'.join(str(x) for x in sorted(BACK.iterdir(),reverse=True)[:15]) if BACK.exists() else '(none)');return
    if args.cmd=='rollback':rollback(args.path);return
    if args.cmd=='install':
        # Migrate legacy domain lists only on first install.
        if not STATE.exists() and CONFIG.exists():
            s=CONFIG.read_text();ra,rb=find_array(s,find_object(s,'routing'),'rules')
            for _,o in array_items(s,ra,rb):
                if o.get('outboundTag') in ('WARP-socks5-v4','WARP-socks5-v6'):
                    for dom in o.get('domain',[]):
                        if dom not in ('domain:example.com',) and dom not in d['domains']:d['domains'].append(dom)
        d['mode']='off'
    elif args.cmd in ('off','selective','full'):d['mode']=args.cmd
    elif args.cmd in ('add','delete'):
        domain=args.domain.strip().lower()
        if not re.fullmatch(r'(domain|full|keyword|regexp|geosite):[^\s",]{1,250}',domain):raise ValueError('Use domain:example.com or geosite:netflix')
        if args.cmd=='add' and domain not in d['domains']:d['domains'].append(domain)
        if args.cmd=='delete':d['domains']=[v for v in d['domains'] if v!=domain]
    elif args.cmd=='port':
        if not 1<=args.number<=65535:raise ValueError('Invalid port')
        d['port']=args.number
    elif args.cmd=='inbounds':
        allowed={'vless-ws','vless-xhttp'}
        if not set(args.tags)<=allowed:raise ValueError('Only supported VLESS tags: '+', '.join(sorted(allowed)))
        d['inbounds']=list(dict.fromkeys(args.tags))
    apply(d)
if __name__=='__main__':
    try:main()
    except Exception as e:print('ERROR:',e,file=sys.stderr);sys.exit(1)
