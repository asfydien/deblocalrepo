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
GPG_DIR="/root/repo-gpg"               # direktori penyimpanan key GPG
KEY_NAME="Debian Local Repo"

echo -e "\033[0;34m[Task]\033[0m Pastikan tools terinstal..."
apt update
apt install -y genisoimage apt-utils dpkg-dev gpg apache2

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

echo -e "\033[0;34m[Task]\033[0m Membuat metadata repo dengan apt-ftparchive..."
cd "$ISO_DIR"

# Packages
apt-ftparchive packages pool/main > dists/stable/main/binary-amd64/Packages
gzip -c dists/stable/main/binary-amd64/Packages > dists/stable/main/binary-amd64/Packages.gz

# Release
cat > dists/stable/Release.conf <<EOF
APT::FTPArchive::Release::Origin "Debian";
APT::FTPArchive::Release::Label "Debian13_Repo";
APT::FTPArchive::Release::Suite "stable";
APT::FTPArchive::Release::Codename "bookworm";
APT::FTPArchive::Release::Architectures "amd64";
APT::FTPArchive::Release::Components "main";
APT::FTPArchive::Release::Description "Debian 13 Local Repository (Kahiang)";
EOF

apt-ftparchive -c dists/stable/Release.conf release dists/stable > dists/stable/Release

echo -e "\033[0;34m[Task]\033[0m Membuat / mengecek kunci GPG..."
mkdir -p "$GPG_DIR"
if ! gpg --homedir "$GPG_DIR" --list-keys "$KEY_NAME" &>/dev/null; then
    gpg --homedir "$GPG_DIR" --batch --gen-key <<EOF
        %no-protection
        Key-Type: RSA
        Key-Length: 2048
        Name-Real: $KEY_NAME
        Expire-Date: 0
        %commit
EOF
    echo -e "\033[0;32m[Info]\033[0m Kunci GPG baru dibuat."
else
    echo -e "\033[0;32m[Info]\033[0m Kunci GPG sudah ada, menggunakan yang lama."
fi

# Sign Release
echo -e "\033[0;34m[Task]\033[0m Menandatangani Release dengan GPG..."
gpg --homedir "$GPG_DIR" --yes -abs -o dists/stable/Release.gpg dists/stable/Release
gpg --homedir "$GPG_DIR" --yes --clearsign -o dists/stable/InRelease dists/stable/Release

# Export public key untuk siswa
echo -e "\033[0;34m[Task]\033[0m Mengekspor public key..."
gpg --homedir "$GPG_DIR" --armor --export "$KEY_NAME" > "$WEB_DIR/repo.gpg.key"
chmod 644 "$WEB_DIR/repo.gpg.key"
chown www-data:www-data "$WEB_DIR/repo.gpg.key"

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
echo -e "\033[0;32m[Info]\033[0m Repository ISO & GPG key siap!"
echo -e "   ISO     : http://$IP_ADDR/$ISO_NAME"
echo -e "   SHA256  : http://$IP_ADDR/$ISO_NAME.sha256"
echo -e "   GPG KEY : http://$IP_ADDR/repo.gpg.key"

echo -e "\n\033[0;34m[Petunjuk]\033[0m Cara pakai di client:"
echo "1. Import GPG key:"
echo "   wget http://$IP_ADDR/repo.gpg.key -O- | sudo apt-key add -"
echo "2. Mount ISO:"
echo "   sudo mount -o loop /path/to/$ISO_NAME /mnt"
echo "3. Tambahkan repository:"
echo "   sudo apt-cdrom add"
echo "4. Update APT:"
echo "   sudo apt update"
