#!/bin/bash
#Daftar aplikasi yang digunakan untuk praktik latihan Debian 13 trixie

# Mengaktifkan opsi untuk menyimpan paket yang sudah diunduh
echo -e "\033[0;34m[Task]\033[0m Persiapan..." 
echo 'APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/01keep-cache

# Lakukan update, dan download semua update-an
echo -e "\033[0;34m[Task]\033[0m Update sistem..." 
apt update -y && apt upgrade -y
apt upgrade --download-only

echo -e "\033[0;34m[Task]\033[0m aptitude..." 
apt install -y aptitude

echo -e "\033[0;34m[Task]\033[0m Downlaoad paket yang dibutuhkan..." 
# Paket dhcp server
aptitude install -d -y isc-dhcp-server
aptitude install -d -y kea-dhcp4-server

# Paket FTP Server
aptitude install -d -y proftpd 
aptitude install -d -y vsftpd 
aptitude install -d -y pure-ftpd

# Paket Remote Server
aptitude install -d -y freeradius freeradius-mysql freeradius-utils
aptitude install -d -y openssh-server openssh-client openssh-sftp-server sshpass ntp

# Paket File Server
aptitude install -d -y samba smbclient
aptitude install -d -y winbind libpam-winbind libnss-winbind krb5-config samba-dsdb-modules samba-vfs-modules
aptitude install -d -y slapd ldap-utils

# Paket Web Server
aptitude install -d -y apache2 php
aptitude install -d -y perl ruby openssl python3 certbot apache2-utils
aptitude install -d -y nginx php-fpm nginx-extras libpam-krb5
aptitude install -d -y lighttpd
aptitude install -d -y php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip php-pgsql php-mysql
aptitude install -d -y php-common php-enchant hunspell

# Paket DNS Server
aptitude install -d -y bind9 bind9utils dnsutils
aptitude install -d -y dnsmasq resolvconf 

#Paket Database Server
aptitude install -d -y mariadb-server mariadb-client phpmyadmin
aptitude install -d -y postgresql

# Paket Mail Server
aptitude install -d -y postfix sasl2-bin
aptitude install -d -y dovecot-core dovecot-pop3d dovecot-imapd
aptitude install -d -y roundcube courier-imap courier-pop
aptitude install -d -y clamav-daemon amavisd-new

# Paket Control Panel
aptitude install -d -y cockpit
aptitude install -d -y libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions
aptitude install -d -y shared-mime-info unzip wget curl

# Paket VPN
aptitude install -d -y pptpd openvpn
aptitude install -d -y libnss3-dev libnspr4-dev pkg-config libpam0g-dev libcap-ng-dev libcap-ng-utils libselinux1-dev libcurl4-nss-dev flex bison gcc make libnss3-tools libevent-dev libsystemd-dev uuid-runtime ppp xl2tpd
aptitude install -d -y fail2ban

# Paket Monitoring
aptitude install -d -y netdata sysstat
aptitude install -d -y cacti snmpd
aptitude install -d -y htop

# Paket Extra
aptitude install -d -y net-tools iptables iproute2 gawk grep sed net-tools
aptitude install -d -y dpkg-dev
aptitude install -d -y squid
aptitude install -d -y asterisk asterisk-dahdi
aptitude install -d -y zip
aptitude install -d -y ufw

echo -e "\033[0;34m[Task]\033[0m Persiapan membuat repository..." 
# Instal semua alat yang dibutuhkan
apt install -y apache2 dpkg-dev

echo -e "\033[0;34m[Task]\033[0m Menyalin semua cache..." 
mkdir -p /var/www/html/repo
cd /var/cache/apt/archives

# bersihkan dari karakter % atau %253a jadi -
for file in *; do
    new_name=$(echo "$file" | sed 's/%253a/-/g; s/%/-/g')
    cp "$file" "/var/www/html/repo/$new_name"
done

echo -e "\033[0;34m[Task]\033[0m Menyusun index..." 
cd /var/www/html/repo
dpkg-scanpackages -m . > Packages
dpkg-scanpackages -m . | gzip > Packages.gz

# Berikan izin yang sesuai pada direktori repository
chown -R www-data:www-data /var/www/html/repo
chmod -R 755 /var/www/html/repo

# Dapatkan alamat IP dari CT Debian
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo -e "\033[0;34m[Task]\033[0m Selesai..." 
echo -e ""
echo -e "Tambahkan baris berikut ke /etc/apt/sources.list"
echo -e ""
echo -e "\033[0;34m   deb [trusted=yes] http://$IP_ADDRESS/repo/ ./ \033[0m"
echo -e ""
