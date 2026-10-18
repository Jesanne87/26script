#!/usr/bin/env python3
"""Patch only the last_online function in the installed User Detail backend."""
import ast
import sys
from pathlib import Path

p = Path(sys.argv[1])
s = p.read_text()
tree = ast.parse(s)
functions = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == 'last_online']
if len(functions) != 1:
    raise SystemExit('Expected exactly one last_online function; refusing to patch')
node = functions[0]
lines = s.splitlines(keepends=True)
replacement = '''def last_online(user,src):
    # Real VPN activity only: do not confuse Account Control last_check with activity.
    stamps=[]
    if isinstance(src,dict):
        for key in ('last_seen','last_seen_at','last_online','last_online_at'):
            try:
                n=int(float(src.get(key)))
                if 1000000000 < n <= int(time.time())+300: stamps.append(n)
            except (TypeError,ValueError,OverflowError): pass
    try:
        for line in LASTSEEN.read_text(errors='replace').splitlines():
            name,sep,value=line.partition('=')
            if sep and name.strip()==user:
                try:
                    n=int(value.strip())
                    if 1000000000 < n <= int(time.time())+300: stamps.append(n)
                except ValueError: pass
    except OSError: pass
    if not stamps:return 'Not available'
    return time.strftime('%Y-%m-%d %H:%M:%S MYT',time.localtime(max(stamps)))
'''
lines[node.lineno-1:node.end_lineno] = [replacement]
s = ''.join(lines)
# Only footer version, leave all existing features untouched.
s = s.replace('JsPhantom User Detail V2.3.1 - Refresh page', 'JsPhantom User Detail V2.4.1 - Refresh page')
ast.parse(s)
p.write_text(s)
