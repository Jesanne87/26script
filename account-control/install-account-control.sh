#!/bin/bash
set -e
D="$(cd "$(dirname "$0")" && pwd)"; mkdir -p /etc/jsphantom/account-control/policies
install -m755 "$D/jsphantom-account-control.py" /usr/local/bin/jsphantom-account-control
install -m755 "$D/account-control-menu.sh" /usr/local/bin/jsphantom-account-menu
install -m644 "$D/jsphantom-account-control.service" /etc/systemd/system/
install -m644 "$D/jsphantom-account-control.timer" /etc/systemd/system/
systemctl daemon-reload; systemctl enable --now jsphantom-account-control.timer
echo 'JsPhantom Account Control V1 installed.'
