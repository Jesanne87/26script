#!/bin/bash
set -euo pipefail
[[ ${EUID:-1} -eq 0 ]] || { echo 'Run as root'; exit 1; }
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP=/usr/local/bin/jsphantom-user-status
TRACKER=/usr/local/bin/jsphantom-last-online-tracker
UNIT=/etc/systemd/system
[[ -f "$APP" ]] || { echo "Missing $APP"; exit 1; }
command -v python3 >/dev/null
command -v systemctl >/dev/null
python3 -m py_compile "$DIR/tracker.py" "$DIR/patch_backend.py"
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="/root/jsphantom-last-online-backup-$STAMP"
mkdir -p "$BACKUP"
cp -a "$APP" "$BACKUP/jsphantom-user-status"
for x in "$TRACKER" "$UNIT/jsphantom-last-online.service" "$UNIT/jsphantom-last-online.timer"; do
  [[ ! -e "$x" ]] || cp -a "$x" "$BACKUP/$(basename "$x")"
done
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
cp -a "$APP" "$TMP"
python3 "$DIR/patch_backend.py" "$TMP"
python3 -m py_compile "$TMP"
install -m 0755 "$TMP" "$APP"
install -m 0755 "$DIR/tracker.py" "$TRACKER"
cat > "$UNIT/jsphantom-last-online.service" <<'EOF'
[Unit]
Description=JsPhantom Last Online V2.4.1 activity tracker
After=local-fs.target
[Service]
Type=oneshot
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/jsphantom-last-online-tracker
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7
EOF
cat > "$UNIT/jsphantom-last-online.timer" <<'EOF'
[Unit]
Description=JsPhantom Last Online activity refresh (1 minute)
[Timer]
OnBootSec=30s
OnUnitInactiveSec=60s
AccuracySec=10s
Unit=jsphantom-last-online.service
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now jsphantom-last-online.timer
systemctl start jsphantom-last-online.service
systemctl restart jsphantom-user-status.service
systemctl is-active --quiet jsphantom-user-status.service || { echo 'ERROR: User Detail not running. Restore backend from backup'; exit 1; }
echo "Installed JsPhantom Last Online V2.4.1; backup: $BACKUP"
echo 'No Xray restart. Check: systemctl status jsphantom-last-online.timer'
