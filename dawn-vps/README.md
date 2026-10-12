# DAWN Validator runner di VPS Ubuntu

Paket ini menjaga **Chrome/Chromium dan extension DAWN resmi** tetap berjalan menggunakan satu browser profile persisten. Runner hanya memulai Xvfb dan browser, memantau proses, lalu melakukan restart jika Chrome berhenti.

> **Penting:** paket ini tidak melakukan auto-login, tidak membaca email/password, tidak membuat `.env` untuk kredensial, dan tidak menjalankan claim, referral, CAPTCHA, multi-account, proxy rotation, spoofing, atau manipulasi reward.

## Yang perlu disiapkan

Gunakan VPS Ubuntu 22.04 atau 24.04 dengan:

- User non-root dengan akses `sudo`.
- RAM yang cukup untuk Chrome; 2 GB atau lebih lebih aman untuk mengurangi risiko OOM.
- IP publik dan koneksi outbound HTTPS yang stabil.
- DNS aktif dan jam sistem tersinkronisasi.
- Satu akun DAWN dan satu browser profile.

VPS datacenter tidak selalu diperlakukan sama seperti koneksi residential. DAWN juga dapat membatasi atau membatalkan aktivitas yang dianggap automated, abusive, manipulative, atau tidak sesuai ketentuan.

## 1. Update Ubuntu dan install dependensi

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y \
  ca-certificates \
  curl \
  wget \
  gnupg \
  xvfb \
  dbus-x11 \
  fonts-liberation \
  unzip \
  procps \
  iproute2 \
  dnsutils
```

Install **salah satu** browser berikut, bukan keduanya.

### Pilihan A: Chromium dari repository Ubuntu

```bash
sudo apt-get install -y chromium
```

### Pilihan B: Google Chrome Stable

```bash
wget -qO /tmp/google-chrome.deb \
  https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt-get install -y /tmp/google-chrome.deb
rm -f /tmp/google-chrome.deb
```

Periksa browser dan Xvfb:

```bash
command -v chromium || command -v google-chrome || command -v google-chrome-stable
Xvfb -version
```

## 2. Periksa koneksi VPS sebelum menjalankan browser

Jalankan semua pemeriksaan berikut:

```bash
getent hosts dawninternet.com
getent hosts dashboard.dawninternet.com
curl -fsSI --max-time 20 https://dawninternet.com/
curl -fsSI --max-time 20 https://dashboard.dawninternet.com/
timedatectl status --no-pager
```

Jika DNS gagal, periksa resolver:

```bash
resolvectl status
```

Pastikan VPS tidak menggunakan proxy yang tidak diperlukan:

```bash
env | grep -iE '^(http|https|all|no)_proxy=' || true
```

Jika Anda memang memerlukan proxy perusahaan, jangan memasukkannya ke script tanpa memastikan DAWN mengizinkan penggunaannya.

## 3. Atur firewall dasar

Jika SSH Anda memakai port 22:

```bash
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status verbose
```

Runner tidak memerlukan port remote-debugging Chrome yang terbuka ke internet. Jangan membuka port seperti `9222` ke publik.

Jika SSH Anda memakai port lain, izinkan port tersebut **sebelum** mengaktifkan UFW agar tidak terkunci dari VPS.

## 4. Salin paket dan pasang unit systemd

Jika repository sudah di-clone:

```bash
cd "$HOME/Initial-D"
chmod +x "$HOME/Initial-D/dawn-vps/run-dawn-validator.sh"
```

Jika folder ini disalin ke home dengan nama `dawn-vps`, sesuaikan path berikut:

```bash
chmod +x "$HOME/dawn-vps/run-dawn-validator.sh"
sudo install -m 0644 \
  "$HOME/dawn-vps/dawn-validator@.service" \
  /etc/systemd/system/dawn-validator@.service
sudo systemctl daemon-reload
```

Unit service dijalankan sebagai user yang Anda pilih, bukan sebagai root.

## 5. Pasang extension dan login manual satu kali

**Login DAWN tidak termasuk dalam script.** Email dan password tidak disimpan di `.env`, source code, command history, unit systemd, atau log.

Anda perlu membuka desktop VPS melalui console provider, VNC, atau remote desktop yang Anda kelola sendiri. Pada display virtual, jalankan runner secara manual:

```bash
"$HOME/dawn-vps/run-dawn-validator.sh"
```

Kemudian, secara manual:

1. Pasang extension **DAWN Validator Chrome Extension** dari Chrome Web Store resmi.
2. Masukkan email dan password DAWN melalui UI extension.
3. Selesaikan verifikasi tambahan jika DAWN memintanya.
4. Pastikan extension menampilkan status connected/aktif.
5. Tutup runner dengan `Ctrl+C` setelah profile berhasil tersimpan.

Runner memakai profile persisten di:

```text
$HOME/.config/dawn-validator
```

Chrome menyimpan sesi browser di profile tersebut sesuai mekanisme Chrome. Itu bukan password yang disimpan oleh script. Lindungi permission folder tersebut:

```bash
chmod 700 "$HOME/.config/dawn-validator"
```

Jika sesi kedaluwarsa atau DAWN meminta login ulang, lakukan login manual lagi. Jangan menaruh password ke file `.env` sebagai solusi.

## 6. Akses tampilan untuk login pertama kali

Runner memakai Xvfb sehingga tidak memerlukan monitor fisik. Untuk login manual, gunakan console/VNC resmi dari provider VPS. Jika Anda memakai VNC melalui SSH tunnel, pasang komponen VNC sesuai kebijakan keamanan Anda dan bind hanya ke localhost. Jangan menjalankan VNC tanpa password dan jangan membuka port VNC ke internet.

Setelah login selesai, service systemd dapat berjalan tanpa PC Anda tetap menyala.

## 7. Jalankan otomatis saat boot

Ganti `ubuntu` dengan username VPS Anda:

```bash
sudo systemctl enable --now dawn-validator@ubuntu.service
sudo systemctl status dawn-validator@ubuntu.service --no-pager
```

Periksa log:

```bash
journalctl -u dawn-validator@ubuntu.service -f
 tail -f "$HOME/.local/state/dawn-validator/runner.log"
 tail -f "$HOME/.local/state/dawn-validator/chrome.log"
```

Hentikan dan nonaktifkan:

```bash
sudo systemctl disable --now dawn-validator@ubuntu.service
```

## 8. Troubleshooting koneksi dan crash

### Service restart terus-menerus

```bash
systemctl status dawn-validator@ubuntu.service --no-pager
journalctl -u dawn-validator@ubuntu.service -n 100 --no-pager
```

Pastikan Xvfb, browser, dan permission profile tersedia:

```bash
command -v Xvfb
command -v chromium || command -v google-chrome || command -v google-chrome-stable
ls -ld "$HOME/.config/dawn-validator"
```

### Browser tidak dapat tersambung ke DAWN

```bash
getent hosts dashboard.dawninternet.com
curl -v --max-time 20 https://dashboard.dawninternet.com/
```

Periksa juga firewall provider, security group, DNS, system time, dan apakah VPS memaksa HTTP/HTTPS proxy.

### Profile terkunci setelah proses crash

Pastikan service tidak sedang berjalan, lalu periksa proses Chrome:

```bash
sudo systemctl stop dawn-validator@ubuntu.service
pgrep -a -u "$USER" 'chrome|chromium' || true
```

Jangan menghapus profile sebelum memastikan Anda memiliki cara login ulang. Jika profile rusak, backup terlebih dahulu:

```bash
cp -a "$HOME/.config/dawn-validator" "$HOME/.config/dawn-validator.backup.$(date +%Y%m%d-%H%M%S)"
```

## Batasan keamanan dan kepatuhan

- Gunakan satu akun dan satu profile browser.
- Jangan menyimpan email/password di `.env`; file tersebut bukan tempat yang aman untuk kredensial DAWN.
- Jangan membagikan password, cookie, token sesi, seed phrase, atau private key.
- Jangan memakai multi-account, referral palsu, proxy rotation, CAPTCHA bypass, spoofing, atau modifikasi request extension.
- Jangan membuka remote-debugging Chrome ke internet.
- DAWN dapat mengubah sistem reward, membatasi koneksi VPS, atau membatalkan aktivitas yang dianggap otomatis/manipulatif.
