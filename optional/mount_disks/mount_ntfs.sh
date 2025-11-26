#!/bin/sh -e
sleep 1m
#mount ntfs
#mount -t ntfs-3g /dev/sda4 /media/Archivos
mount -t ntfs-3g /dev/disk/by-uuid/7831DFE8367E8754 /media/Archivos
systemctl restart smb
systemctl restart nmb
echo "listo"
