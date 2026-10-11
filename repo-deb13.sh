#!/bin/bash
# ==============================================================================
# DEB13-LOCALREPO-BUILDER
# Skrip Otomatis Pembuatan Repository Lokal Debian 13 (Trixie)
# Didesain khusus untuk Praktikum Lab. ASJ / TJKT
#
# Penulis       : Asfydien (SMKN 1 Soreang)
# Peruntukan    : Lingkungan Lab Offline/Hybrid (Server Proxmox) nomaden
# Fitur         : Auto-Resolve Dependencies & Auto-Include Webmin + Usermin
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. KONFIGURASI IDENTITAS & DIREKTORI
# ------------------------------------------------------------------------------
REPO_DIR="/var/www/html/repo"
GPG_NAME="Repo Lokal ASJ SMKN 1 Soreang"
GPG_EMAIL="repo@smkn1soreang.sch.id"
GPG_COMMENT="Praktikum Jaringan Debian 13"

C_TASK="\033[0;34m[Task]\033[0m"
C_INFO="\033[0;33m[Info]\033[0m"
C_SUCC="\033[1;32m[Sukses]\033[0m"
C_RESET="\033[0m"

# ------------------------------------------------------------------------------
# 2. DAFTAR PAKET PRAKTIKUM
# ------------------------------------------------------------------------------
PKGS_BASE="nginx nginx-common gnupg2 wget curl dpkg-dev apt-utils psmisc"
PKGS_DHCP="isc-dhcp-server kea-dhcp4-server chrony ntpsec"
PKGS_FTP="proftpd-core vsftpd pure-ftpd"
PKGS_REMOTE="freeradius freeradius-mysql freeradius-utils openssh-server openssh-client openssh-sftp-server sshpass"
PKGS_FILE="samba samba-common-bin samba-libs libldap2 libldb2 libndr6 attr python3-samba samba-ad-dc smbclient winbind libpam-winbind libnss-winbind krb5-config samba-dsdb-modules samba-vfs-modules slapd ldap-utils wsdd2 nfs-kernel-server nfs-common"
PKGS_WEB="apache2 libaprutil1-ldap libbrotli1 libcurl4t64 libldap2 libnghttp3-9 librtmp1 libssh2-1t64 libxslt1.1 libgcrypt20 libgpg-error0 php php8.4 perl perl-base perl-modules-5.40 libperl5.40 ruby openssl python3 certbot apache2-utils php-fpm php8.4-fpm php8.4-cli php8.4-readline php8.4-opcache nginx-extras libpam-krb5 lighttpd php-curl php8.4-curl php-gd php8.4-gd php-mbstring php8.4-mbstring php-xml php8.4-xml php-xmlrpc php8.4-xmlrpc php-soap php8.4-soap php-intl php8.4-intl php-zip php8.4-zip php-pgsql php8.4-pgsql php-mysql php8.4-mysql php-common php8.4-common php-enchant php8.4-enchant hunspell"
PKGS_DNS="bind9 bind9-utils bind9-dnsutils dnsmasq resolvconf"
PKGS_DB="mariadb-server mariadb-client mariadb-common mariadb-server-core mariadb-client-core libdbi-perl libhtml-template-perl pv mariadb-plugin-provider-bzip2 mariadb-plugin-provider-lz4 mariadb-plugin-provider-lzma mariadb-plugin-provider-lzo mariadb-plugin-provider-snappy mysql-common libmariadb3 phpmyadmin postgresql"
PKGS_MAIL="postfix sasl2-bin dovecot-core dovecot-pop3d dovecot-imapd roundcube courier-imap courier-pop clamav-daemon amavisd-new mailutils swaks"
PKGS_CPANEL="cockpit libnet-ssleay-perl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions shared-mime-info unzip tar libglib2.0-0 libglib2.0-0t64 libglib2.0-data libxml2 perl-openssl-defaults libatomic1 xdg-user-dirs"
PKGS_VPN="pptpd openvpn libnss3-dev libnspr4-dev pkg-config libpam0g-dev libcap-ng-dev libcap-ng-utils libselinux1-dev libcurl4-openssl-dev flex bison gcc make libnss3-tools libevent-dev libsystemd-dev uuid-runtime ppp xl2tpd fail2ban"
PKGS_MONITOR="sysstat cacti snmp snmpd rrdtool librrd8 htop"
PKGS_NET="net-tools iptables iptables-persistent iproute2 nftables frr haproxy gawk grep sed squid zip ufw tcpdump traceroute nmap iperf3 telnet rsync acl sudo bash-completion vim nano"

ALL_PACKAGES="$PKGS_BASE $PKGS_DHCP $PKGS_FTP $PKGS_REMOTE $PKGS_FILE $PKGS_WEB $PKGS_DNS $PKGS_DB $PKGS_MAIL $PKGS_CPANEL $PKGS_VPN $PKGS_MONITOR $PKGS_NET"

echo -e "$C_TASK Persiapan sistem..."
echo 'APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/01keep-cache
apt update -y && apt upgrade -y
apt upgrade --download-only -y

# ------------------------------------------------------------------------------
# 3. SMART DOWNLOAD ENGINE
# ------------------------------------------------------------------------------
echo -e "$C_TASK Mengunduh seluruh paket praktikum..."
for pkg in $ALL_PACKAGES; do
    apt-get install -y --download-only "$pkg"
done

INSTALLED_PKGS=$(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' | awk '/^ii/ {print $2}')
for pkg in $ALL_PACKAGES; do
    if echo "$INSTALLED_PKGS" | grep -qx "$pkg"; then
        apt-get install -y --reinstall --download-only "$pkg"
    fi
done

apt-get install -y nginx gnupg2 dpkg-dev apt-utils curl wget

# ------------------------------------------------------------------------------
# 4. INTEGRASI WEBMIN & USERMIN (Terpisah)
# ------------------------------------------------------------------------------
echo -e "$C_TASK Menambahkan Webmin & Usermin..."
cd /tmp

wget -qO webmin.deb https://webmin.com/download/deb/webmin-current.deb
wget -qO usermin.deb https://webmin.com/download/deb/usermin-current.deb

echo -e "$C_INFO Membedah dan mengunduh dependensi Webmin..."
apt-get install -y --allow-downgrades --download-only ./webmin.deb

echo -e "$C_INFO Membedah dan mengunduh dependensi Usermin..."
apt-get install -y --allow-downgrades --download-only ./usermin.deb

# ------------------------------------------------------------------------------
# 5. KONFIGURASI KEAMANAN (GPG SIGNATURE)
# ------------------------------------------------------------------------------
echo -e "$C_TASK Menyiapkan Kunci GPG..."
cat > /tmp/gen-key-script <<EOF
%echo Men-generate kunci RSA...
Key-Type: RSA
Key-Length: 4096
Name-Real: $GPG_NAME
Name-Comment: $GPG_COMMENT
Name-Email: $GPG_EMAIL
Expire-Date: 0
%no-protection
%commit
%echo Selesai
EOF

if ! gpg --list-keys "$GPG_EMAIL" > /dev/null 2>&1; then
    gpg --batch --generate-key /tmp/gen-key-script
fi

KEY_ID=$(gpg --list-keys --with-colons "$GPG_EMAIL" | awk -F: '/^pub:/ { print $5 }')

# ------------------------------------------------------------------------------
# 6. PEMBUATAN STRUKTUR REPOSITORY
# ------------------------------------------------------------------------------
echo -e "$C_TASK Membangun struktur repositori di $REPO_DIR..."
mkdir -p "$REPO_DIR"

cd /var/cache/apt/archives || exit
for file in *.deb; do
    [ -e "$file" ] || continue
    new_name=$(echo "$file" | sed 's/%253a/-/g; s/%/-/g')
    cp -u "$file" "$REPO_DIR/$new_name"
done

cp -u /tmp/webmin.deb "$REPO_DIR/webmin.deb"
cp -u /tmp/usermin.deb "$REPO_DIR/usermin.deb"

echo -e "$C_TASK Men-generate Index, Release, dan menempelkan Signature..."
cd "$REPO_DIR" || exit
dpkg-scanpackages -m . > Packages
gzip -k -f Packages
apt-ftparchive release . > Release
rm -f Release.gpg InRelease
gpg --batch --yes --default-key "$KEY_ID" -abs -o Release.gpg Release
gpg --batch --yes --default-key "$KEY_ID" --clearsign -o InRelease Release
gpg --armor --export "$KEY_ID" > "$REPO_DIR/repo-key.asc"

chown -R www-data:www-data "$REPO_DIR"
chmod -R 755 "$REPO_DIR"

# ------------------------------------------------------------------------------
# 7. PORTAL WEB INSTRUKSI KLIEN
# ------------------------------------------------------------------------------
echo -e "$C_TASK Membuat portal web instruksi otomatis..."
IP_ADDRESS=$(hostname -I | awk '{print $1}')

cat > "$REPO_DIR/index.html" <<EOF
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Repository Lokal Praktikum Lab</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f4f4f9; color: #333; line-height: 1.6; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); max-width: 800px; margin: auto; }
        h1 { color: #0056b3; border-bottom: 2px solid #0056b3; padding-bottom: 10px;}
        h3 { color: #333; margin-top: 25px; }
        pre { background: #2d2d2d; color: #f8f8f2; padding: 15px; border-radius: 5px; overflow-x: auto; font-size: 14px; position: relative; }
        .info { background: #e7f3fe; border-left: 6px solid #2196F3; padding: 10px; margin-bottom: 20px; }
        .badge { background: #28a745; color: white; padding: 3px 8px; border-radius: 12px; font-size: 12px; vertical-align: middle;}
    </style>
</head>
<body>
    <div class="container">
        <h1>Repository Lokal Praktikum ASJ <span class="badge">Debian 13</span></h1>
        <div class="info">
            <p><strong>Perhatian Siswa/i:</strong> <em>Copy</em> kode di dalam kotak hitam di bawah ini secara berurutan, lalu <em>paste</em> di terminal LXC Debian 13 kalian.</p>
        </div>

        <h3>1. Matikan Repository Internet (Wajib Mode Offline)</h3>
        <pre><code>mv /etc/apt/sources.list /etc/apt/sources.list.backup 2&gt;/dev/null
mv /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.backup 2&gt;/dev/null</code></pre>

        <h3>2. Unduh GPG Key Keamanan Repository Lokal</h3>
        <pre><code>mkdir -p /etc/apt/keyrings
wget -qO /etc/apt/keyrings/repo-lokal.asc http://$IP_ADDRESS/repo/repo-key.asc
chmod 644 /etc/apt/keyrings/repo-lokal.asc</code></pre>

        <h3>3. Daftarkan Alamat Repository Lokal</h3>
        <pre><code>cat &lt;&lt; 'INNER_EOF' > /etc/apt/sources.list.d/lokal.sources
Types: deb
URIs: http://$IP_ADDRESS/repo
Suites: ./
Signed-By: /etc/apt/keyrings/repo-lokal.asc
INNER_EOF</code></pre>

        <h3>4. Lakukan Update & Mulai Praktikum!</h3>
        <pre><code>apt update</code></pre>

        <h3>💡 Info Ekstra (Modul Kontrol Panel)</h3>
        <p>Aplikasi <strong>Webmin</strong> dan <strong>Usermin</strong> sudah tersedia di dalam repositori lokal ini. Kalian cukup mengetikkan perintah berikut untuk menginstalnya (disarankan dipisah):</p>
        <pre><code>apt install webmin
apt install usermin</code></pre>
    </div>
</body>
</html>
EOF

echo -e "\n$C_SUCC Instalasi Repository Lokal Selesai!"
echo -e "Silakan instruksikan siswa untuk mengakses portal di: \033[1;32mhttp://$IP_ADDRESS/repo\033[0m"
