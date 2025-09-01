#!/bin/bash
set -e

# Pastikan script dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
    echo -e "\033[0;31m[Error]\033[0m Script ini harus dijalankan sebagai root!"
    exit 1
fi

# Variabel
ISO_NAME="repo-deb13-kahiang.iso"
REPO_DIR="/var/www/html/repo"          # direktori deb
ISO_DIR="/root/repo-iso"               # direktori kerja ISO
WEB_DIR="/var/www/html"                # direktori web
ISO_LABEL="Debian13_Repo"

echo -e "\033[0;34m[Task]\033[0m Pastikan tools terinstal..."
apt update
apt install -y genisoimage dpkg-dev apache2

# Buat direktori kerja
echo -e "\033[0;34m[Task]\033[0m Membuat direktori kerja..."
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR"/{dists/stable/main/binary-amd64,pool/main}

echo -e "\033[0;34m[Task]\033[0m Menyalin paket ke pool..."
if [ -d "$REPO_DIR" ] && [ -n "$(ls -A "$REPO_DIR"/*.deb 2>/dev/null)" ]; then
    cp "$REPO_DIR"/*.deb "$ISO_DIR/pool/main/"
else
    echo -e "\033[0;31m[Error]\033[0m Tidak ada file .deb di $REPO_DIR"
    exit 1
fi

echo -e "\033[0;34m[Task]\033[0m Membuat metadata repo..."
cd "$ISO_DIR"
dpkg-scanpackages pool/main /dev/null > dists/stable/main/binary-amd64/Packages
gzip -c dists/stable/main/binary-amd64/Packages > dists/stable/main/binary-amd64/Packages.gz

# Release sederhana (tanpa tanda tangan)
cat > dists/stable/Release <<EOF
Origin: Debian
Label: Debian13_Repo
Suite: stable
Codename: bookworm
Architectures: amd64
Components: main
Description: Debian 13 Local Repository (Kahiang)
EOF

echo -e "\033[0;34m[Task]\033[0m Membuat file ISO..."
genisoimage -o "/root/$ISO_NAME" -J -r -V "$ISO_LABEL" "$ISO_DIR"

mv "/root/$ISO_NAME" "$WEB_DIR/"
cd "$WEB_DIR"
sha256sum "$ISO_NAME" > "$ISO_NAME.sha256"
chmod 644 "$ISO_NAME" "$ISO_NAME.sha256"
chown www-data:www-data "$ISO_NAME" "$ISO_NAME.sha256"

# Aktifkan listing direktori
APACHE_CONF="/etc/apache2/apache2.conf"
if ! grep -q "Options Indexes" "$APACHE_CONF"; then
    echo -e "\033[0;34m[Task]\033[0m Mengaktifkan index directory di Apache..."
    echo "<Directory /var/www/html>
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>" >> "$APACHE_CONF"
    systemctl restart apache2
fi

# Info akhir
IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "\033[0;32m[Info]\033[0m Repository ISO siap!"
echo -e "   ISO     : http://$IP_ADDR/$ISO_NAME"
echo -e "   SHA256  : http://$IP_ADDR/$ISO_NAME.sha256"

echo -e "\n\033[0;34m[Petunjuk]\033[0m Cara pakai di client:"
echo "1. Mount ISO:"
echo "   sudo mount -o loop /path/to/$ISO_NAME /mnt"
echo "2. Tambahkan repository:"
echo "   sudo apt-cdrom add -d=/mnt"
echo "3. Patch sources.list agar trusted:"
echo "   sudo sed -i 's|^deb cdrom:|deb [trusted=yes] cdrom:|' /etc/apt/sources.list"
echo "4. Update APT:"
echo "   sudo apt update"
