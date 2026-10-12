# DAWN Validator runner di VPS Ubuntu

Skrip ini hanya menjaga **Chrome/Chromium dan extension DAWN resmi** tetap berjalan menggunakan satu browser profile persisten. Skrip tidak membaca password dan tidak melakukan login, claim, referral, CAPTCHA, multi-account, proxy rotation, spoofing, atau manipulasi reward.

## 1. Install dependensi

```bash
sudo apt-get update
sudo apt-get install -y xvfb curl ca-certificates
```

Install Google Chrome atau Chromium sesuai kebijakan VPS Anda. Contoh Chromium:

```bash
sudo apt-get install -y chromium
```

## 2. Pasang skrip

```bash
chmod +x "$HOME/dawn-vps/run-dawn-validator.sh"
sudo install -m 0644 "$HOME/dawn-vps/dawn-validator@.service" /etc/systemd/system/dawn-validator@.service
sudo systemctl daemon-reload
```

## 3. Login manual satu kali

Jalankan skrip sebagai user VPS yang tidak memiliki hak root:

```bash
"$HOME/dawn-vps/run-dawn-validator.sh"
```

Pada tahap ini, skrip hanya membuka Chrome di display virtual. Untuk login dan memasang extension resmi, gunakan akses VNC/remote desktop ke VPS atau mekanisme desktop yang Anda kelola sendiri. Masukkan email dan password secara manual. Jangan menyimpan password di source code, command history, atau file konfigurasi.

Setelah extension terpasang dan sesi login berhasil, tekan `Ctrl+C` lalu gunakan systemd.

## 4. Jalankan otomatis saat boot

Ganti `ubuntu` dengan username VPS Anda:

```bash
sudo systemctl enable --now dawn-validator@ubuntu.service
sudo systemctl status dawn-validator@ubuntu.service
```

Log:

```bash
journalctl -u dawn-validator@ubuntu.service -f
 tail -f "$HOME/.local/state/dawn-validator/runner.log"
```

Hentikan:

```bash
sudo systemctl disable --now dawn-validator@ubuntu.service
```

## Catatan keamanan

- Gunakan satu akun dan satu profile browser.
- Batasi SSH dan jangan membuka port remote-debugging ke internet.
- Gunakan firewall dan update Ubuntu/Chrome secara rutin.
- VPS datacenter dapat diperlakukan berbeda dari koneksi residential.
- Jika DAWN meminta login ulang atau verifikasi tambahan, lakukan manual.
- DAWN menyatakan aktivitas automated, abusive, manipulative, atau non-compliant dapat dianggap tidak valid dan dapat menyebabkan reward atau akun dibatasi.
