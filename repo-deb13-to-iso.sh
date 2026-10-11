#!/bin/bash
# ==============================================================================
# PEMBUAT ISO REPOSITORY DEBIAN 13 (TRIXIE)
# Didesain khusus untuk Praktikum Virtual Machine (VM)
# ==============================================================================
set -e

# Pastikan script dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
    echo -e "\033[0;31m[Error]\033[0m Script ini harus dijalankan sebagai root!"
    exit 1
fi

# Variabel
ISO_NAME="repo-deb13-kahiang.iso"
REPO_DIR="/var/www/html/repo"          # direktori deb dari skrip sebelumnya
ISO_DIR="/root/repo-iso"               # direktori kerja sementara ISO
WEB_DIR="/var/www/html/repo"           # Tempat ISO disajikan (via Nginx)
ISO_LABEL="Debian13_Kahiang"

echo -e "\033[0;34m[Task]\033[0m Memastikan tools terinstal (genisoimage)..."
apt update
# HANYA install genisoimage. Tidak install apache2 karena kita pakai Nginx!
apt install -y genisoimage dpkg-dev

# Buat direktori kerja (Metode Flat Repository untuk Debian 13)
echo -e "\033[0;34m[Task]\033[0m Membuat direktori kerja ISO (Flat Mode)..."
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/deb13repo"

echo -e "\033[0;34m[Task]\033[0m Menyalin file .deb (Filter ketat)..."
if [ -d "$REPO_DIR" ] && [ -n "$(ls -A "$REPO_DIR"/*.deb 2>/dev/null)" ]; then
    # Hanya copy file berakhiran .deb
    cp "$REPO_DIR"/*.deb "$ISO_DIR/deb13repo/"
else
    echo -e "\033[0;31m[Error]\033[0m Tidak ada file .deb di $REPO_DIR!"
    exit 1
fi

echo -e "\033[0;34m[Task]\033[0m Membuat metadata repository di dalam ISO..."
cd "$ISO_DIR/deb13repo"
# Generate Packages index (Metode Flat)
dpkg-scanpackages . /dev/null > Packages
gzip -k -f Packages
apt-ftparchive release . > Release

echo -e "\033[0;34m[Task]\033[0m Membangun file ISO..."
cd "$ISO_DIR"
genisoimage -o "/root/$ISO_NAME" -J -R -V "$ISO_LABEL" .

echo -e "\033[0;34m[Task]\033[0m Memindahkan ISO ke Web Server (Nginx)..."
mv "/root/$ISO_NAME" "$WEB_DIR/"
cd "$WEB_DIR"
sha256sum "$ISO_NAME" > "$ISO_NAME.sha256"
chmod 644 "$ISO_NAME" "$ISO_NAME.sha256"
chown www-data:www-data "$ISO_NAME" "$ISO_NAME.sha256"

# Bersihkan sampah
rm -rf "$ISO_DIR"

# Info akhir
IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "\033[1;32m[Sukses]\033[0m Repository ISO siap!"
echo -e "   URL ISO : http://$IP_ADDR/repo/$ISO_NAME"
echo -e "   SHA256  : http://$IP_ADDR/repo/$ISO_NAME.sha256"

echo -e "\n\033[0;33m[Petunjuk Praktikum Siswa VM]\033[0m"
echo "1. Masukkan ISO ke dalam Virtual Machine (VirtualBox/VMware/Proxmox)."
echo "2. Mount ISO di Debian 13 VM:"
echo "   mkdir -p /mnt/iso"
echo "   mount /dev/cdrom /mnt/iso"
echo "3. Daftarkan repository (Abaikan GPG / Trust Absolute):"
echo "   cat << 'EOF' > /etc/apt/sources.list.d/iso.sources"
echo "Types: deb"
echo "URIs: file:///mnt/iso/deb13repo"
echo "Suites: ./"
echo "Trusted: yes"
echo "EOF"
echo "4. Update dan Install:"
echo "   apt update"
echo "   apt install webmin"
