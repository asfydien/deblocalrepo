#!/bin/bash

# Pastikan script dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
    echo -e "\033[0;31m[Task]\033[0m Script ini harus dijalankan sebagai root!"
    exit 1
fi

# Tentukan alamat IP repository (ubah sesuai kebutuhan)
#REPO_IP="192.168.1.100"  # <-- Ganti dengan IP statis server Anda
# Jika tidak ingin IP statis, gunakan deteksi otomatis:
if [[ -z "$REPO_IP" ]]; then
    REPO_IP=$(hostname -I | awk '{print $1}')
fi

echo -e "\033[0;34m[Task]\033[0m Memastikan Apache dan alat pendukung terinstal..."
apt update && apt install -y apache2 apt-mirror dpkg-dev

REPO_DIR="/var/www/html/repo"
CACHE_DIR="/repo-cache"

echo -e "\033[0;34m[Task]\033[0m Menghapus paket lama di repository..."
rm -rf "$REPO_DIR"
mkdir -p "$REPO_DIR"
chmod -R 755 "$REPO_DIR"

echo -e "\033[0;34m[Task]\033[0m Menghapus cache lama dan menyiapkan direktori baru..."
rm -rf "$CACHE_DIR"
mkdir -p "$CACHE_DIR"

echo -e "\033[0;34m[Task]\033[0m Mengunduh paket-paket LAMP dan dependensinya..."
cd "$CACHE_DIR"

# Daftar paket LAMP
PACKAGES="apache2 mariadb-server php php-mysql libapache2-mod-php php-cli php-curl php-gd php-mbstring php-xml php-zip"

# Mengunduh semua paket beserta dependensinya
apt download $PACKAGES

echo -e "\033[0;34m[Task]\033[0m Memindahkan paket terbaru ke repository..."
mv *.deb "$REPO_DIR/"

echo "\033[0;34m[Task]\033[0m Membuat ulang indeks repository..."
cd "$REPO_DIR"
rm -f Packages.gz
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz

echo -e "\033[0;34m[Task]\033[0m Memberikan izin yang sesuai..."
chown -R www-data:www-data "$REPO_DIR"
chmod -R 755 "$REPO_DIR"

echo ""
echo "Repository lokal berhasil diperbarui!"
echo "Repository tersedia di: http://$REPO_IP/repo"
echo ""
echo "Untuk menggunakan repository ini di client, tambahkan baris berikut ke /etc/apt/sources.list:"
echo -e "\033[0;32m[Task]\033[0m deb [trusted=yes] http://$REPO_IP/repo ./"
echo ""
echo "Kemudian jalankan: apt update"
echo ""
