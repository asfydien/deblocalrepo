## Tujuan

Idenya script ini digunakan untuk membuat sebuah CT Debian 12 di Proxmox supaya dapat digunakan sebagai repositori lokal dalam jaringan LAN, belum teruji sepenuhnya mungkin masih ada masalah dependensi!

## Tahapan

1. Buat sebuah CT dengan template OS Debian
2. Download script, lalu beri ijin eksekusi
    ```shell
    wget https://raw.githubusercontent.com/asfydien/deblocalrepo/refs/heads/main/repo.sh
    chmod +x repo.sh
    ```
3. Jalankan
    ```shell
    ./repo.sh
    ```  
