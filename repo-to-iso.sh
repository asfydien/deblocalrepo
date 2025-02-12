#!/bin/bash

# Pastikan script dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
    echo "Script ini harus dijalankan sebagai root!"
    exit 1
fi

# Nama ISO yang akan dibuat
ISO_NAME="debian12-repo.iso"

# Direktori repository lokal yang berisi file .deb
REPO_DIR="/var/www/html/repo"

# Direktori kerja untuk pembuatan ISO
ISO_DIR="/root/repo-iso"

# Direktori webserver untuk menyimpan ISO
WEB_DIR="/var/www/html"

# Label ISO agar dikenali oleh `apt-cdrom add`
ISO_LABEL="Debian12_Repo"

echo "🔎 Memeriksa apakah genisoimage sudah terinstal..."
if ! command -v genisoimage &> /dev/null; then
    echo "📦 Menginstal genisoimage..."
    apt update && apt install -y genisoimage
fi

echo "🔄 Membersihkan direktori kerja..."
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR"/{dists/stable/main/binary-amd64,pool/main}

echo "📦 Menyalin paket ke struktur repository..."
if [ -d "$REPO_DIR" ] && [ -n "$(ls -A "$REPO_DIR" 2>/dev/null)" ]; then
    cp "$REPO_DIR"/*.deb "$ISO_DIR/pool/main/"
else
    echo "⚠️ Repository lokal kosong atau tidak ditemukan di $REPO_DIR!"
    exit 1
fi

echo "📝 Membuat daftar paket..."
cd "$ISO_DIR"
dpkg-scanpackages pool/main /dev/null | gzip -9c > dists/stable/main/binary-amd64/Packages.gz

echo "📄 Membuat file Release..."
cat > dists/stable/Release <<EOF
Origin: Debian
Label: Debian12_Repo
Suite: stable
Codename: bookworm
Architectures: amd64
Components: main
Description: Debian 12 Local Repository
EOF

echo "📀 Membuat file ISO: $ISO_NAME..."
genisoimage -o "/root/$ISO_NAME" -J -r -V "$ISO_LABEL" "$ISO_DIR"

# Periksa apakah file ISO berhasil dibuat
if [ ! -f "/root/$ISO_NAME" ]; then
    echo "❌ Pembuatan ISO gagal! Periksa apakah genisoimage berfungsi dengan benar."
    exit 1
fi

echo "📂 Memindahkan ISO ke web server..."
mv "/root/$ISO_NAME" "$WEB_DIR/"

echo "🔑 Membuat checksum SHA256..."
cd "$WEB_DIR"
sha256sum "$ISO_NAME" > "$ISO_NAME.sha256"

echo "🛠️ Mengatur izin file agar bisa diunduh..."
chmod 644 "$WEB_DIR/$ISO_NAME" "$WEB_DIR/$ISO_NAME.sha256"
chown www-data:www-data "$WEB_DIR/$ISO_NAME" "$WEB_DIR/$ISO_NAME.sha256"

# Aktifkan listing direktori jika belum diaktifkan
APACHE_CONF="/etc/apache2/apache2.conf"
if ! grep -q "Options Indexes" "$APACHE_CONF"; then
    echo "📄 Mengaktifkan list direktori di Apache..."
    echo "<Directory /var/www/html>
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>" >> "$APACHE_CONF"
    systemctl restart apache2
fi

# Tampilkan link unduhan
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "✅ File ISO siap! Bisa diunduh di:"
echo "🔗 http://$IP_ADDR/$ISO_NAME"
echo "🔑 Checksum SHA256 tersedia di:"
echo "🔗 http://$IP_ADDR/$ISO_NAME.sha256"

echo "🚀 Untuk menggunakannya di client:"
echo "1️⃣ Masukkan/mount ISO: sudo mount -o loop /path/to/$ISO_NAME /mnt"
echo "2️⃣ Tambahkan repository: sudo apt-cdrom add"
echo "3️⃣ Update APT: sudo apt update"
