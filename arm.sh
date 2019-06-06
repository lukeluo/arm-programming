#!/usr/bin/bash -x
qemu-system-arm -M virt,highmem=off \
  -cpu cortex-a15 \
  -m 2048 \
  -drive file=./arm.raw,format=raw,index=0,if=virtio,media=disk \
  -smp 2  \
  -kernel boot/zImage \
  -initrd boot/initramfs-linux.img \
  -nographic \
  -netdev tap,id=nd0,ifname=tap0,script=no,downscript=no -device e1000,netdev=nd0  \
-append 'root=PARTUUID="cc88b513-db87-4d01-aa75-267bfd2b53c4" rw'
