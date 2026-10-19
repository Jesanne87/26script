# 🚀 JsPhantom Xray VPN

**All-in-One VPN Management untuk Debian/Ubuntu VPS** — pemasangan, akaun VLESS/VMESS, pemantauan dan penyelenggaraan melalui menu terminal.

## ✨ Fungsi utama

- **VPN:** VLESS WebSocket / XHTTP, VMESS WebSocket, TLS, Nginx dan pengurusan Xray.
- **Account Control:** cipta/padam/lanjut akaun, expiry, had IP, kuota, lock/unlock dan pengurusan polisi.
- **User Detail:** status akaun, penggunaan, amaran IP limit, sebab lock, Last Online dan panduan Android/iOS.
- **Keselamatan:** MY Protection (mod MONITOR untuk pemasangan baharu), Lock History dan pemeriksaan konfigurasi.
- **Pengurusan:** Central Admin (Master/Agent), Telegram, backup, DNS cache, WARP dan VPS optimization.
- **Diagnostic & Update:** System Diagnostic V2.0 dan **Safe Update V2.1.1** (Standard / Critical / Dry-run / Backup).

## 🖥️ Sistem disokong

Debian **11 / 12 / 13** atau Ubuntu **20.04 / 22.04 / 24.04**. Gunakan VPS baharu untuk pemasangan penuh. Jalankan sebagai `root`.

## 🚀 Fresh VPS — pemasangan penuh

> **Hanya untuk VPS baharu. Jangan jalankan installer penuh pada VPS yang sudah ada pengguna VPN.**

```bash
apt-get update && apt-get install -y ca-certificates curl wget
curl -fLsS https://raw.githubusercontent.com/Jesanne87/26script/main/xray.sh -o /root/xray.sh
chmod +x /root/xray.sh
/root/xray.sh
```

## 🔄 VPS sedia ada — migrasi Safe Update (tanpa reinstall VPN)

> Upload dahulu `menu/menu.sh` dan semua fail dalam folder `safe-update/` versi baharu ke GitHub. Arahan di bawah hanya memasang/migrasi menu updater, **bukan** menaik taraf semua modul secara automatik.

```bash
curl -fLsS https://raw.githubusercontent.com/Jesanne87/26script/main/safe-update/jsphantom-safe-update-install.sh -o /root/jsphantom-safe-update-install.sh
chmod +x /root/jsphantom-safe-update-install.sh
/root/jsphantom-safe-update-install.sh --dry-run
```

Jika dry-run berjaya, jalankan:

```bash
/root/jsphantom-safe-update-install.sh --migrate
menu
```

Pilih **15 — JsPhantom Safe Update** untuk semak dan kemas kini modul. Migration membuat backup menu/updater lama di `/root/jsphantom-safe-update-migration/`; ia tidak reinstall Xray/Nginx atau menukar mod MY Protection.

## 🩺 Diagnostic

```bash
system-diagnostic
system-diagnostic --report
```

Diagnostic V2.0 menyemak komponen yang dipasang tanpa mengubah servis atau firewall. Modul pilihan yang tiada sepatutnya dipaparkan sebagai N/A, bukan dianggap rosak.

## 👨‍💻 Developer

**JsPhantom** · GitHub: [Jesanne87](https://github.com/Jesanne87) · Repo: [26script](https://github.com/Jesanne87/26script)

> ⚠️ Gunakan hanya pada VPS dan rangkaian yang anda dibenarkan urus. Simpan backup sebelum sebarang kemas kini kritikal.
