#!/bin/bash

# Kode warna ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Pastikan skrip dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR]${NC} Skrip ini harus dijalankan sebagai root!"
    exit 1
fi

# Nama ISO yang akan dibuat
ISO_NAME="repo-deb13-kahiang.iso"

# Direktori repositori lokal yang berisi file .deb
REPO_DIR="/var/www/html/repo"

# Direktori kerja untuk pembuatan ISO
ISO_DIR="/root/repo-iso"

# Direktori webserver untuk menyimpan ISO
WEB_DIR="/var/www/html"

# Label ISO agar dikenali oleh `apt-cdrom add`
ISO_LABEL="Debian_13_Kahiang"

# --- Bagian 1: Persiapan dan Verifikasi ---

echo -e "${BLUE}[Task]${NC} Memeriksa dependensi..."
# Cek genisoimage
if ! command -v genisoimage &> /dev/null; then
    echo -e "${YELLOW}[INFO]${NC} Menginstal genisoimage..."
    apt update && apt install -y genisoimage
fi
# Cek apt-utils (untuk apt-ftparchive)
if ! command -v apt-ftparchive &> /dev/null; then
    echo -e "${YELLOW}[INFO]${NC} Menginstal apt-utils..."
    apt update && apt install -y apt-utils
fi
# Cek gnupg (opsional, untuk tanda tangan)
if ! command -v gpg &> /dev/null; then
    echo -e "${YELLOW}[INFO]${NC} Menginstal gnupg (opsional)..."
    apt install -y gnupg
fi

echo -e "${BLUE}[Task]${NC} Membersihkan direktori kerja..."
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR"/{dists/stable/main/binary-amd64,pool/main}

echo -e "${BLUE}[Task]${NC} Menyalin paket ke struktur repositori..."
if [ -d "$REPO_DIR" ] && [ -n "$(ls -A "$REPO_DIR" 2>/dev/null)" ]; then
    cp "$REPO_DIR"/*.deb "$ISO_DIR/pool/main/"
else
    echo -e "${YELLOW}[WARNING]${NC} Repositori lokal kosong atau tidak ditemukan di $REPO_DIR!"
    echo "  Skrip akan tetap berjalan, tetapi ISO tidak akan berisi paket."
fi

# --- Bagian 2: Pembuatan Repositori APT ---

cd "$ISO_DIR"

echo -e "${BLUE}[Task]${NC} Membuat file Packages.gz..."
dpkg-scanpackages --arch amd64 pool/main | gzip -9c > dists/stable/main/binary-amd64/Packages.gz

echo -e "${BLUE}[Task]${NC} Membuat file Release..."
apt-ftparchive release dists/stable > dists/stable/Release

# --- Bagian 3: Tanda Tangan GPG (Opsional, sangat disarankan) ---

if [ -f /root/.gnupg/secring.gpg ] || [ -f /root/.gnupg/pubring.kbx ]; then
    echo -e "${BLUE}[Task]${NC} Menandatangani Release file..."
    
    # PERHATIAN: Ganti "your_signing_key_id" dengan ID kunci GPG Anda
    # Jika Anda tidak tahu ID-nya, jalankan `gpg --list-keys`
    gpg --clearsign -o dists/stable/InRelease dists/stable/Release
    gpg -abs -o dists/stable/Release.gpg dists/stable/Release
    
    echo -e "${GREEN}[SUKSES]${NC} Release file berhasil ditandatangani."
else
    echo -e "${YELLOW}[WARNING]${NC} Kunci GPG tidak ditemukan. Repositori tidak akan ditandatangani."
    echo "  Anda akan mendapatkan peringatan '...can't be done securely' saat apt update."
fi

# --- Bagian 4: Pembuatan dan Penempatan ISO ---

echo -e "${BLUE}[Task]${NC} Membuat file ISO: $ISO_NAME..."
genisoimage -o "/root/$ISO_NAME" -J -r -V "$ISO_LABEL" "$ISO_DIR"

# Periksa apakah file ISO berhasil dibuat
if [ ! -f "/root/$ISO_NAME" ]; then
    echo -e "${RED}[ERROR]${NC} Pembuatan ISO gagal! Periksa apakah genisoimage berfungsi dengan benar."
    exit 1
fi

echo -e "${BLUE}[Task]${NC} Memindahkan ISO ke web server..."
mv "/root/$ISO_NAME" "$WEB_DIR/"

echo -e "${BLUE}[Task]${NC} Membuat checksum SHA256..."
cd "$WEB_DIR"
sha256sum "$ISO_NAME" > "$ISO_NAME.sha256"

echo -e "${BLUE}[Task]${NC} Mengatur izin file agar bisa diunduh..."
chmod 644 "$WEB_DIR/$ISO_NAME" "$WEB_DIR/$ISO_NAME.sha256"
chown www-data:www-data "$WEB_DIR/$ISO_NAME" "$WEB_DIR/$ISO_NAME.sha256"

# --- Bagian 5: Instruksi Penggunaan ---

IP_ADDR=$(hostname -I | awk '{print $1}')
echo ""
echo "==========================================================="
echo -e "${GREEN}[SUKSES]${NC} Pembuatan ISO Selesai!"
echo "-----------------------------------------------------------"
echo "File ISO siap! Bisa diunduh di:"
echo "URL: http://$IP_ADDR/$ISO_NAME"
echo "Checksum SHA256 tersedia di:"
echo "URL: http://$IP_ADDR/$ISO_NAME.sha256"
echo ""
echo "Instruksi untuk menggunakannya di client:"
echo "1. Unduh ISO dan pindahkan ke mesin client."
echo "2. Mount ISO: sudo mount -o loop /path/ke/$ISO_NAME /mnt"
echo "3. Tambahkan repositori: sudo apt-cdrom add"
echo "4. Perbarui daftar paket: sudo apt update"
echo "==========================================================="
