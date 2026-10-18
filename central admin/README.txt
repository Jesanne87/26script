JsPhantom Central Admin · Deployment Menu V1.2 · Complete Agent Recovery

One ZIP, one menu for Master Shinjiru and Agent DigitalOcean / NewMediaExpress.
Stable Master/Agent Sync Engine V1.2. Existing live installations are not auto-upgraded.

INSTALL:
  cd /root
  bash /usr/local/sbin/jsphantom-central-deploy-update
  ln -sfn /opt/jsphantom-central-deployment/v1.2/menu.sh /usr/local/bin/jsphantom-central-menu
  jsphantom-central-menu

7) Agent Complete Backup: creates agent-complete-*.tar.gz in
   /root/jsphantom-central-recovery/ with agent credentials, User Detail settings,
   tutorial images, agent code and polling service files where available.
   IMPORTANT: contains SECRET AGENT TOKEN. Keep private; copy OFF VPS.

15) Agent Recovery:
  1 Verify Agent Complete backup (READ ONLY)
  2 Restore User Detail settings only (backs up current state first)
  3 Restore agent credentials only (refuses replacement of different existing token)

Fresh Agent install: requires existing User Detail installation. If credentials are
restored first, installer uses them; otherwise prompts for registered name/token.
Newly installed poll timer starts OFF. Run Agent preview (option 5), then manually
start poll timer (option 11) when ready. Existing active poll timers are not changed
by updating the menu.

For a freshly reset VPS, install User Detail first; restore credentials (15/3),
Setup Agent (2), restore settings (15/2), preview (5), then enable polling (11).
Agent backup does NOT contain the complete User Detail app, Xray config, Nginx,
VPN accounts or user database. Restore those separately using their own backups.

Option 8 still rolls back a pre-sync snapshot in /var/backups/jsphantom-central-agent.
Option 9 remains Master Verify / Data Only / Full Recovery.
Do not test restore on a production VPS. Verify backups first.
