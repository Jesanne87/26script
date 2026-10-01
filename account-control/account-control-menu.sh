#!/bin/bash
BASE=/etc/jsphantom/account-control; POL=$BASE/policies; STATE=$BASE/state.json; mkdir -p "$POL"
while true; do
 clear; echo '=============== JsPhantom Account Control V1 ==============='
 echo '[1] Status VLESS Policies'; echo '[2] Edit/Create User Policy'; echo '[3] Reset User Quota'; echo '[4] Run Monitor Now'; echo '[5] Monitor Log'; echo '[0] Back'; read -rp 'Select: ' x
 case $x in
 1) python3 -c 'import json,glob; S="/etc/jsphantom/account-control/state.json"; s=json.load(open(S)) if __import__("os").path.exists(S) else {}; print("%-16s %-8s %-20s %s"%("USER","IP","USAGE","STATUS")); [(lambda p,u,st,q,used: print("%-16s %-8s %-20s %s"%(u,str(st.get("ip_count",0))+"/"+str(p.get("ip_limit",0) or "INF"),("%.2fG"%(used/1073741824))+"/"+(("%.2fG"%(q/1073741824)) if q else "Unlimited"),("LOCKED:"+st.get("reason","") if st.get("locked") else "ACTIVE"))))(json.load(open(f)),json.load(open(f))["user"],s.get(json.load(open(f))["user"],{}),json.load(open(f)).get("quota_bytes",0),s.get(json.load(open(f))["user"],{}).get("used_bytes",0)) for f in sorted(glob.glob("/etc/jsphantom/account-control/policies/*.json"))]'; read -n1 -s -r -p ' Press any key...';;
 2) read -rp 'Username: ' u; grep -Eq "^#= $u([[:space:]]|$)" /usr/local/etc/xray/config.json || { echo 'VLESS user not found';sleep 2;continue;}; read -rp 'IP Limit (0=unlimited): ' ip; read -rp 'Quota GB (0=unlimited): ' q; python3 -c 'import json,sys;f,u,ip,q=sys.argv[1:];json.dump({"user":u,"protocol":"vless","ip_limit":int(ip),"quota_bytes":int(float(q)*1073741824),"auto_lock":True,"ip_window_seconds":300},open(f,"w"),indent=2)' "$POL/$u.json" "$u" "$ip" "$q";;
 3) read -rp 'Username: ' u; python3 -c 'import json,sys,os;f,u=sys.argv[1:];s=json.load(open(f)) if os.path.exists(f) else {}; x=s.setdefault(u,{});x.update(used_bytes=0,last_counter=0,locked=False,reason="",locked_at=0);json.dump(s,open(f,"w"),indent=2)' "$STATE" "$u"; echo 'Quota/state reset.';sleep 2;;
 4) /usr/local/bin/jsphantom-account-control; echo Done;sleep 2;;
 5) tail -50 /var/log/jsphantom-account-control.log 2>/dev/null;read -n1 -s -r -p ' Press any key...';;
 0) exit;; esac
done
