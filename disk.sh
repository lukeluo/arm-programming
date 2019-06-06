#!/usr/bin/bash -x

sudo rm -rf boot arm.raw initram 

#prepare raw disk file for Qemu

wget -c http://tw.mirror.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz

truncate -s 16G arm.raw

# create GPT disk partion. only one partition
sgdisk -Z ./arm.raw
sgdisk -o ./arm.raw
sgdisk -n 1:0:0   ./arm.raw
sgdisk -t 1:8300  ./arm.raw



#loop device setup and file system creation
# extract kernel/initramfs (under /boot) from stock archlinuxarm image
sudo kpartx -a -v ./arm.raw
part=$(sudo blkid | grep mapper | grep -v 'TYPE=' | tail -n 1 |  cut -f 1 -d ':')
partuuid=$(sudo blkid | grep mapper | grep -v 'TYPE=' | tail -n 1 |  cut -f 2 -d ':' | tr -d "[:blank:]")
sed -i -e '/-append/d' arm.sh
newappend="-append 'root=$partuuid rw'"
echo $newappend  >> arm.sh
sudo mkfs.ext4 $part
sudo mount $part /mnt
sudo bsdtar -xpf ArchLinuxARM-armv7-latest.tar.gz -C /mnt
sudo cp -r /mnt/boot ./


#inject virtio_pci driver into initramfs
mkdir initram 
cd initram 
sudo bsdcpio -i -I  ../boot/initramfs-linux.img
sudo cp /mnt/usr/lib/modules/5.1.5-1-ARCH/kernel/drivers/virtio/virtio_pci.ko.gz ./lib/modules/5.1.5-1-ARCH/kernel/
sudo bash -c "find . -mindepth 1 -printf '%P\0' | LANG=C bsdcpio -z -o -H newc -O ../boot/initramfs-linux.img"
cd ..


#cp userspace pacman install script to /root and change default mirror
sudo cp userspace.sh  /mnt/root
sudo cp mirrorlist /mnt/etc/pacman.d/mirrorlist

#umount /mnt
sudo umount /mnt
sudo kpartx -d ./arm.raw
