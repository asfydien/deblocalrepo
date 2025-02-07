## Tujuan
Script ini digunakan untuk membuat sebuah CT Debian di Proxmox supaya dapat digunakan sebagai repositori lokal dalam jaringan LAN

## Tahapan

1. Buat sebuah CT dengan template OS Debian
2. Install curl
3. Download script, lalu beri ijin eksekusi
    ```shell
    curl -o lanrepo.sh https://raw.githubusercontent.com/asfydien/deblocalrepo/refs/heads/main/lanrepo.sh
    chmod +x lanrepo.sh
    ```
4. Jalankan
    ```shell
    ./lanrepo.sh
    ```  
