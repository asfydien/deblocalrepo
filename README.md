## Tujuan

Ide dasarnya adalah script ini digunakan untuk membuat sebuah CT Debian 13 di Proxmox supaya dapat digunakan sebagai repositori lokal dalam jaringan LAN yang kadang tidak ada akses internet, skript belum teruji sepenuhnya mungkin masih ada masalah dependensi!

## Tahapan

1. Buat sebuah CT dengan template OS Debian 13 dan sudah terpasang Nginx
2. Download script, lalu beri ijin eksekusi
    ```shell
    wget https://raw.githubusercontent.com/asfydien/deblocalrepo/refs/heads/main/repo-deb13.sh
    chmod +x repo.sh
    ```
3. Jalankan
    ```shell
    ./repo-deb13.sh
    ```  
