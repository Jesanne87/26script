#!/usr/bin/env bash
# JsPhantom Full Wipe V1.3.3 - destructive, dedicated VPN VPS ONLY
# Reviewed against supplied installer and VPS preflight; NOT tested on live VPS.
set -Eeuo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
umask 077
MODE=${1:---plan}
case "$MODE" in --plan|--scan|--wipe|--help) ;; *) echo 'Usage: script --plan|--wipe'; exit 2;; esac
[[ "$MODE" != --help ]] || { echo 'Usage: script --plan|--wipe'; exit 0; }
[[ $EUID -eq 0 && -d /run/systemd/system ]] || { echo 'ERROR: root + systemd required'; exit 1; }
STAMP=$(date +%Y%m%d-%H%M%S)
LOG=/root/jsphantom-full-wipe-v1.3.3-$STAMP.log
exec > >(tee -a "$LOG") 2>&1
PHASE=preflight
FAILURES=0
WARNINGS=0
DNS_CHANGED=0
DESTRUCTIVE_STARTED=0
error_trap() {
 local status=$?
 echo "ERROR: phase=$PHASE line=$1 status=$status; inspect $LOG" >&2
 if (( DNS_CHANGED == 1 && DESTRUCTIVE_STARTED == 0 )); then
  if [[ -f "$RECOVERY/etc/resolv.conf" ]]; then
   cp -a -- "$RECOVERY/etc/resolv.conf" /etc/resolv.conf && echo 'DNS rolled back (before destructive phase)' >&2
  fi
 fi
 exit "$status"
}
trap 'error_trap "$LINENO"' ERR
warn() { echo "WARNING: $*"; WARNINGS=$((WARNINGS+1)); }
fail() { echo "FAIL: $*"; FAILURES=$((FAILURES+1)); }


BIN_NAMES=(menu vmess vless traffic warp-menu tweak-menu lock_unlock_id add-vmess del-vmess extend-vmess trialvmess cek-vmess add-vless del-vless extend-vless trialvless cek-vless log-vless xp change_domain certxray xray_switcher about clear-log dns_tweak nf telegram-backup dnsstatus vps_performance system-diagnostic autoclear-menu auto-clear-ram bot_menu telegram_vless)
PATHS=(
 /usr/local/etc/xray /etc/jsphantom /root/account-control /var/log/xray /var/log/jsphantom
 /var/www/html/vless /var/www/html/vmess /var/lib/dnsvps.conf /user/current
 /home/ver /home/exp /home/exp2 /home/cname /home/cname2 /home/autoclear.conf
 /usr/local/libexec/jsphantom-safe-update /usr/local/libexec/jsphantom-my-protection
 /usr/local/libexec/jsphantom-my-protection-core /usr/local/libexec/jsphantom-central-admin
 /usr/local/libexec/jsphantom-last-online /etc/xray/isp_cache.txt /etc/xray/user_lastseen.db
 /etc/nginx/conf.d/xray.conf /etc/nginx/conf.d/00-jsphantom-my-geo.conf
 /etc/systemd/system/xray.service.d/20-jsphantom-legacy-user.conf
 /etc/sysctl.d/99-jsphantom-performance-v3.1.conf /etc/systemd/system.conf.d/99-jsphantom-nofile.conf
 /usr/local/bin/xray /usr/local/bin/auto_logger /usr/local/bin/jsphantom-account-control
 /usr/local/bin/jsphantom-user-status /usr/local/bin/jsphantom-last-online-tracker
 /usr/local/bin/jsphantom-lock-history-watch /usr/local/bin/jsphantom-account-menu
 /usr/local/bin/jsphantom-safe-update /usr/local/bin/jsphantom-central-menu
 /usr/local/sbin/jsphantom-central-deploy-update /usr/local/sbin/jsphantom-central-menu
 /usr/local/sbin/jsphantom-my-protection /usr/local/sbin/jsphantom-my-geo-sync.sh
 /usr/local/sbin/nginx-memory-guard /usr/local/sbin/jsphantom-safe-update
 /usr/local/bin/jsphantom-my-protection /usr/local/bin/__pycache__/jsphantom-user-statuscpython-313.pyc
 /usr/local/bin/__pycache__/jsphantom-lock-history-watchcpython-313.pyc
 /etc/nginx/conf.d/xray.conf.bak-user-status-20261019-220901
)
for n in "${BIN_NAMES[@]}"; do PATHS+=("/usr/bin/$n"); done
UNITS=(xray.service xray@.service jsphantom-account-control.service jsphantom-account-control.timer
 jsphantom-user-status.service jsphantom-last-online.service jsphantom-last-online.timer
 jsphantom-lock-history.service jsphantom-lock-history.timer
 jsphantom-central-agent.service jsphantom-central-agent.timer jsphantom-central-master.service jsphantom-central-master.timer
 jsphantom-my-protection-boot.service jsphantom-my-geo-sync.service jsphantom-my-geo-sync.timer
 jsphantom-my-protection-health.service jsphantom-my-protection-health.timer
 jsphantom-my-rollback.service jsphantom-my-rollback.timer
 auto-clear-ram.service auto_logger.service nginx-memory-guard.service)
for u in "${UNITS[@]}"; do
 for d in /etc/systemd/system /usr/local/lib/systemd/system; do PATHS+=("$d/$u"); done
done
BACKUPS=(/root/backup-dnsmasq /root/jsphantom-account-control-backups /root/jsphantom-backup-v3.2
 /root/jsphantom-last-online-backup-20261019-220903 /root/jsphantom-my-v1.3.7-backup
 /root/jsphantom-safe-update-migration /root/jsphantom-safe-update-v2.1
 /root/jsphantom-update-backup /root/nginx-backups)

# Only explicitly branded root-level artifacts. Never recurse through /root.
# Current running script, current log and recovery are deliberately retained.
ROOT_ARTIFACTS=()
collect_root_artifacts() {
 local f base
 ROOT_ARTIFACTS=()
 while IFS= read -r -d '' f; do
  base=${f##*/}
  [[ "$f" == "$LOG" || "$f" == "$RECOVERY" ]] && continue
  # Match only branded installer/log/archive names, not unrelated root content.
  case "$base" in
   jsphantom-*.sh|jsphantom-*.zip|jsphantom-*.log|jsphantom-*.c|jsphantom-*.x|jsphantom-*.sh.x|jsphantom-*.sh.c)
    ROOT_ARTIFACTS+=("$f");;
  esac
 done < <(find /root -mindepth 1 -maxdepth 1 -type f -print0 2>/dev/null)
}

safe_rm() {
 local p=$1 parent
 case "$p" in /|/etc|/root|/usr|/usr/local|/usr/bin|/home|/var|/user|/backup|'') echo "REFUSED $p"; return 1;; esac
 [[ "$p" == /* && "$p" != *'..'* ]] || { echo "REFUSED malformed $p"; return 1; }
 parent=$(dirname "$p")
 while [[ "$parent" != / ]]; do [[ ! -L "$parent" ]] || { echo "REFUSED symlink parent $parent"; return 1; }; parent=$(dirname "$parent"); done
 if [[ -e "$p" || -L "$p" ]]; then rm -rf --one-file-system -- "$p" && echo "REMOVED $p"; fi
}

printf 'JsPhantom Full Wipe V1.3.3 | %s | %s\n' "$(date -Is)" "$MODE"
echo 'DESTROYS VPN accounts, JsPhantom data and listed backups; preserves shared acme.sh.'
echo 'PRESERVES SSH, host networking, Fail2ban and Debian packages.'
echo '=== MATCHED FILE TARGETS ==='
for p in "${PATHS[@]}" "${BACKUPS[@]}"; do [[ ! -e "$p" && ! -L "$p" ]] || echo "$p"; done
RECOVERY=''
collect_root_artifacts
echo '=== ROOT INSTALLER / LOG CANDIDATES ==='
for p in "${ROOT_ARTIFACTS[@]}"; do
 if [[ "$p" == "$0" || "$p" == "$(readlink -f -- "$0" 2>/dev/null || true)" ]]; then
  echo "PRESERVE RUNNING SCRIPT: $p"
 else
  echo "CANDIDATE: $p"
 fi
done
echo '=== SHARED CONFIGS TO RESET ===' 
for p in /etc/resolv.conf /etc/dnsmasq.conf /etc/nginx/nginx.conf /etc/iptables/rules.v4 /etc/iptables.up.rules /etc/nftables.conf /etc/crontab /root/.profile; do [[ ! -e "$p" ]] || echo "REVIEW: $p"; done
echo '=== SERVICE INVENTORY ==='
systemctl list-unit-files --no-pager --no-legend 2>/dev/null | grep -Ei 'jsphantom|xray|nginx-memory-guard|auto_logger|auto-clear-ram|dnsmasq' || true
echo '=== DNS ==='; cat /etc/resolv.conf 2>/dev/null || true
echo '=== NFT ==='; nft list tables 2>/dev/null | grep -Ei 'jsphantom|f2b' || true
echo '=== NOTES ==='
echo 'Provider-specific firewall, Nginx includes, sysctl runtime and non-listed addons require post-wipe inspection.'
echo 'Unknown backups under /backup and /user are NOT recursively deleted.'
echo 'Shared acme.sh certificate store is PRESERVED for manual review.'
echo 'Running wipe script, current log and recovery directory are PRESERVED.'
if [[ "$MODE" != --wipe ]]; then echo "PLAN ONLY: no changes. Log: $LOG"; exit 0; fi
[[ -t 0 ]] || { echo 'ERROR: interactive SSH/console required'; exit 2; }
# Preflight guards before touching services or files.
PHASE=preflight
for cmd in dig getent timeout iptables iptables-restore iptables-save nft nginx python3 systemctl; do
 command -v "$cmd" >/dev/null || { echo "ABORT: missing required command $cmd"; exit 1; }
done
[[ -f /etc/resolv.conf && ! -L /etc/resolv.conf ]] || { echo 'ABORT: unsupported resolver file'; exit 1; }
if [[ -f /etc/iptables/rules.v4 ]]; then iptables-restore --test < /etc/iptables/rules.v4 || { echo 'ABORT: invalid rules.v4'; exit 1; }; fi
if [[ -f /etc/iptables.up.rules ]]; then iptables-restore --test < /etc/iptables.up.rules || { echo 'ABORT: invalid iptables.up.rules'; exit 1; }; fi

if [[ -f /etc/nftables.conf ]] && grep -Eq 'jsphantom_my_protect|jsphantom-my|jsphantom_my' /etc/nftables.conf; then
 echo 'ABORT: persistent nftables config references JsPhantom. Review it manually before wipe.'; exit 1
fi
if [[ -f /etc/nginx/nginx.conf ]]; then
  for f in /etc/nginx/conf.d/*.conf; do
    [[ -e "$f" ]] || continue
    case "$f" in /etc/nginx/conf.d/xray.conf|/etc/nginx/conf.d/00-jsphantom-my-geo.conf) ;; *) echo "ABORT: non-JsPhantom Nginx conf: $f"; exit 1;; esac
  done
  if find /etc/nginx/sites-enabled -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null | grep -q .; then
    echo 'ABORT: nginx sites-enabled is nonempty; cannot replace main config safely.'; exit 1
  fi
fi

read -r -p 'Type DEDICATED-VPS to confirm no other websites/apps use Nginx, dnsmasq or acme.sh: ' a
[[ "$a" == DEDICATED-VPS ]] || { echo CANCELLED; exit 2; }
read -r -p 'Type ERASE-ALL-JSPHANTOM-DATA to delete VPN accounts, tokens, certs and backups: ' a
[[ "$a" == ERASE-ALL-JSPHANTOM-DATA ]] || { echo CANCELLED; exit 2; }
read -r -p 'Type YES-I-HAVE-CONSOLE to confirm VPS provider console/snapshot is available: ' a
[[ "$a" == YES-I-HAVE-CONSOLE ]] || { echo CANCELLED; exit 2; }

RECOVERY=/root/jsphantom-wipe-recovery-v1.3.3-$STAMP
PHASE=backup
mkdir -m 700 "$RECOVERY"
for p in /etc/resolv.conf /etc/dnsmasq.conf /etc/nginx/nginx.conf /etc/crontab /root/.profile /etc/iptables/rules.v4 /etc/iptables.up.rules /etc/nftables.conf; do
 if [[ -f "$p" || -L "$p" ]]; then mkdir -p "$RECOVERY$(dirname "$p")"; cp -a -- "$p" "$RECOVERY$p"; fi
done
iptables-save > "$RECOVERY/iptables-live.before" 2>/dev/null || true
nft list ruleset > "$RECOVERY/nft-live.before" 2>/dev/null || true

PHASE=dns
# Fail closed: DNS is switched and verified before dnsmasq is stopped.
[[ -f /etc/resolv.conf && ! -L /etc/resolv.conf ]] || { echo 'ABORT: resolv.conf is symlinked/missing; handle provider DNS manually'; exit 1; }
command -v dig >/dev/null || { echo 'ABORT: dig required to validate public DNS'; exit 1; }
DNS_IP=''
for ip in 1.1.1.1 9.9.9.9 76.76.2.172; do
 if timeout 7 dig +time=2 +tries=1 @"$ip" debian.org A +short 2>/dev/null | grep -Eq '^[0-9]+\.[0-9]+\.'; then DNS_IP=$ip; break; fi
done
[[ -n "$DNS_IP" ]] || { echo 'ABORT: no tested external resolver. No services stopped.'; exit 1; }
printf 'nameserver %s\n' "$DNS_IP" > /etc/resolv.conf.jsphantom-v1.3.tmp
chmod 644 /etc/resolv.conf.jsphantom-v1.3.tmp
mv /etc/resolv.conf.jsphantom-v1.3.tmp /etc/resolv.conf
DNS_CHANGED=1
if ! timeout 10 getent ahostsv4 debian.org >/dev/null; then
 cp -a "$RECOVERY/etc/resolv.conf" /etc/resolv.conf
 DNS_CHANGED=0; echo 'ABORT: DNS validation failed, resolver restored'; exit 1
fi
echo "DNS switched to tested resolver $DNS_IP"
# Recheck without the local resolver to prove dnsmasq can be stopped.
if ! timeout 8 dig +time=2 +tries=1 @"$DNS_IP" debian.org A +short | grep -Eq '^[0-9]+\.[0-9]+\.'; then
 cp -a -- "$RECOVERY/etc/resolv.conf" /etc/resolv.conf; DNS_CHANGED=0; echo 'ABORT: replacement resolver failed repeat test; restored original DNS'; exit 1
fi
# Persistent resolver may be overwritten by DHCP/cloud-init after reboot.
if grep -R -Eql '127\.0\.0\.1|resolv\.conf' /etc/network/interfaces /etc/network/interfaces.d /etc/cloud/cloud.cfg.d 2>/dev/null; then
 warn 'Provider network/cloud-init may manage resolver on reboot; inspect after reboot'
fi
DESTRUCTIVE_STARTED=1
PHASE=stop-services

# Stop dedicated JsPhantom services; never stop SSH or Fail2ban.
for u in "${UNITS[@]}"; do
 if systemctl list-unit-files --no-legend "$u" 2>/dev/null | grep -Fq "$u"; then
  systemctl disable --now "$u" >/dev/null 2>&1 || warn "could not disable $u"
  if systemctl is-active --quiet "$u"; then fail "service still active: $u"; fi
 fi
done
systemctl disable --now dnsmasq.service >/dev/null 2>&1 || warn 'could not disable dnsmasq'
if systemctl is-active --quiet dnsmasq.service; then fail 'dnsmasq remains active'; fi
PHASE=firewall
# Remove only the dedicated JsPhantom nft table.
if nft list table inet jsphantom_my_protect >/dev/null 2>&1; then
 nft delete table inet jsphantom_my_protect || fail 'nft table could not be deleted'
fi
# Remove exact installer BitTorrent FORWARD rules (not other firewall rules).
TORRENT_STRINGS=('get_peers' 'announce_peer' 'find_node' 'BitTorrent' 'BitTorrent protocol' 'peer_id=' '.torrent' 'announce.php?passkey=' 'torrent' 'announce' 'info_hash')
for s in "${TORRENT_STRINGS[@]}"; do
 while iptables -C FORWARD -m string --string "$s" --algo bm -j DROP >/dev/null 2>&1; do
  iptables -D FORWARD -m string --string "$s" --algo bm -j DROP || { fail "could not remove live iptables rule $s"; break; }
  echo "Removed FORWARD rule: $s"
 done
done
# Remove only exact JsPhantom rules from persistent files, preserving all other lines.
# Never rewrite a persistent policy from a snapshot of the current live firewall.
for rules_file in /etc/iptables/rules.v4 /etc/iptables.up.rules; do
 if [[ -f "$rules_file" ]]; then
  python3 - "$rules_file" <<'PYRULES'
import pathlib, sys
p=pathlib.Path(sys.argv[1])
lines=p.read_text().splitlines(keepends=True)
strings={'get_peers','announce_peer','find_node','BitTorrent','BitTorrent protocol','peer_id=','.torrent','announce.php?passkey=','torrent','announce','info_hash'}
import shlex
out=[]
for line in lines:
    remove=False
    try:
        parts=shlex.split(line)
        if len(parts)>2 and parts[:2]==['-A','FORWARD'] and '--string' in parts and '--algo' in parts and '-j' in parts:
            val=parts[parts.index('--string')+1]
            algo=parts[parts.index('--algo')+1]
            jump=parts[parts.index('-j')+1]
            remove=(val in strings and algo=='bm' and jump=='DROP' and '-m' in parts and 'string' in parts)
    except (ValueError, IndexError):
        pass
    if not remove: out.append(line)
if len(out)!=len(lines):
    tmp=p.with_name(p.name+'.jsphantom-wipe.tmp')
    tmp.write_text(''.join(out))
    tmp.chmod(p.stat().st_mode & 0o777)
    tmp.replace(p)
    print(f'Updated {p}: removed {len(lines)-len(out)} exact JsPhantom rules')
PYRULES
 fi
done

PHASE=delete-files
# Root installer cleanup only after core deletion phase begins; no wildcards in rm.
# Re-enumerate in case root files changed after --plan.
collect_root_artifacts
for p in "${ROOT_ARTIFACTS[@]}"; do
 if [[ "$p" == "$0" || "$p" == "$(readlink -f -- "$0" 2>/dev/null || true)" ]]; then
  echo "PRESERVED running wipe script: $p"
  continue
 fi
 safe_rm "$p" || fail "failed to remove root artifact $p"
done
for p in "${PATHS[@]}"; do safe_rm "$p" || fail "failed to remove $p"; done
# Extra known JsPhantom backups: intentionally irreversible after confirmation.
for p in "${BACKUPS[@]}"; do safe_rm "$p" || fail "failed to remove backup $p"; done
# Remove only exact installer cron lines.
if [[ -f /etc/crontab ]]; then
 sed -i '\|^\*/15 \* \* \* \* root xp$|d; \|^\*/3 \* \* \* \* root clear-log$|d' /etc/crontab
fi
# Disable JsPhantom root login auto-menu without clobbering unrelated profile customizations.
if [[ -f /root/.profile ]] && grep -qx 'menu' /root/.profile; then
 sed -i '/^menu$/d' /root/.profile
 echo 'Removed root login auto-menu line.'
fi
# dnsmasq config is owned by this dedicated installation: clear Control D settings.
if [[ -f /etc/dnsmasq.conf ]]; then
 printf '# Reset by JsPhantom Full Wipe V1.3; dnsmasq disabled.\n' > /etc/dnsmasq.conf
fi
PHASE=nginx
# Nginx: remove old custom main configuration and install a small valid baseline.
# Do NOT remove unrelated /etc/nginx/sites-enabled contents.
if [[ -f /etc/nginx/nginx.conf ]]; then
 cat > /etc/nginx/nginx.conf <<'NGINX'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
events { worker_connections 768; }
http {
 include /etc/nginx/mime.types;
 default_type application/octet-stream;
 sendfile on;
 keepalive_timeout 65;
 access_log /var/log/nginx/access.log;
 error_log /var/log/nginx/error.log;
 include /etc/nginx/conf.d/*.conf;
 include /etc/nginx/sites-enabled/*;
}
NGINX
 if nginx -t >/dev/null 2>&1; then
  systemctl reload nginx 2>/dev/null || fail 'Nginx reload failed'
  echo 'Nginx main config replaced with tested baseline.'
 else
  cp -a "$RECOVERY/etc/nginx/nginx.conf" /etc/nginx/nginx.conf
  fail 'baseline nginx -t failed; original nginx.conf restored; deleted Xray includes cannot be restored automatically'
 fi
fi
PHASE=verify
systemctl daemon-reload || fail 'systemd daemon-reload failed'
systemctl reset-failed >/dev/null 2>&1 || true
# Do not apply sysctl --system or restart network/SSH. Runtime sysctl may remain until reboot.

echo; echo '=== POST WIPE VERIFICATION ==='
if timeout 10 getent ahostsv4 debian.org >/dev/null; then echo 'DNS: OK'; else fail 'DNS: FAILED (restore resolver from recovery)'; fi
if nginx -t >/dev/null 2>&1; then echo 'Nginx syntax: OK'; else fail 'Nginx syntax: FAILED'; fi
if systemctl is-active --quiet ssh.service || systemctl is-active --quiet sshd.service; then echo 'SSH: ACTIVE'; else fail 'SSH: NOT ACTIVE'; fi
systemctl list-unit-files --no-legend 2>/dev/null | grep -Ei 'jsphantom|xray|nginx-memory-guard|auto_logger|auto-clear-ram' || true
nft list tables 2>/dev/null | grep 'jsphantom' || true
for p in /etc/nftables.conf /etc/iptables/rules.v6 /backup /user /etc/nginx/sites-enabled /etc/nginx/conf.d /etc/sysctl.d; do [[ -e "$p" ]] && echo "MANUAL REVIEW: $p"; done
echo "RECOVERY: $RECOVERY"
echo "LOG: $LOG"
echo "FAILURES: $FAILURES | WARNINGS: $WARNINGS"
echo 'NOT a factory reset: inspect persistent resolver, unknown addons, shared directories and sysctl after reboot.'
if (( FAILURES > 0 )); then
 echo 'RESULT: INCOMPLETE — review failures before reboot/reinstall.'
 exit 1
fi
echo 'RESULT: WIPE COMPLETED WITH POST-REBOOT VERIFICATION REQUIRED.' 
