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

echo ""
echo -e "\033[0;34m[Task]\033[0m Memastikan Apache dan alat pendukung terinstal..."
apt update && apt install -y apache2 apt-mirror dpkg-dev

REPO_DIR="/var/www/html/repo"
CACHE_DIR="/var/cache/apt/archives"

echo ""
echo -e "\033[0;34m[Task]\033[0m Membuat direktori repository jika belum ada..."
mkdir -p "$REPO_DIR"
chmod -R 755 "$REPO_DIR"

echo ""
echo -e "\033[0;34m[Task]\033[0m Memastikan direktori cache tersedia..."
mkdir -p "$CACHE_DIR/partial"

echo ""
echo -e "\033[0;34m[Task]\033[0m Mengunduh paket-paket LAMP dan dependensinya..."
# Daftar paket LAMP
PACKAGES="apache2 mariadb-server php php-mysql libapache2-mod-php php-cli php-curl php-gd php-mbstring php-xml php-zip"

# Mengambil semua dependensi paket utama
ALL_PACKAGES=$(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances $PACKAGES | grep "^\w" | sort -u)

# Unduh ulang paket, meskipun sudah terinstal
apt update
apt install -d --reinstall -y $ALL_PACKAGES

echo ""
echo -e "\033[0;34m[Task]\033[0m Memindahkan paket terbaru ke repository..."
mv "$CACHE_DIR"/*.deb "$REPO_DIR/"

echo ""
echo -e "\033[0;34m[Task]\033[0m Membuat ulang indeks repository..."
cd "$REPO_DIR"
rm -f Packages.gz
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz

echo ""
echo -e "\033[0;34m[Task]\033[0m Memberikan izin yang sesuai..."
chown -R www-data:www-data "$REPO_DIR"
chmod -R 755 "$REPO_DIR"

echo ""
echo -e "\033[0;34m[Info]\033[0m Repository lokal berhasil dibuat!"
echo "Repository tersedia di: http://$REPO_IP/repo"
echo ""
echo "Untuk menggunakan repository ini di client, tambahkan baris berikut ke /etc/apt/sources.list:"
echo ""
echo -e "\033[0;32mdeb [trusted=yes] http://$REPO_IP/repo ./\033[0m"
echo ""
echo "Kemudian jalankan: apt update"
echo ""
