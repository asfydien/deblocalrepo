## Tujuan
Idenya script ini digunakan untuk membuat sebuah CT Debian 12 di Proxmox supaya dapat digunakan sebagai repositori lokal dalam jaringan LAN, masih banyak masalah dependensi!

## Tahapan

1. Buat sebuah CT dengan template OS Debian
2. Download script, lalu beri ijin eksekusi
    ```shell
    wget https://raw.githubusercontent.com/asfydien/deblocalrepo/refs/heads/main/lanrepo.sh
    chmod +x lanrepo.sh
    ```
3. Jalankan
    ```shell
    ./lanrepo.sh
    ```  
