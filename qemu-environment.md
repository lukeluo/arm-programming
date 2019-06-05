# Qemu dev env for arm and aarch64 setup



### 1.  Requirement

- A "native" virtual dev/debug environment for  Arm learning , instead of cross tool chain in PC host.   Since the focus is on Arm assembly, toolchain(c/c++/gdb),  a general Arm v7/v8 qemu machine will suffice .  The generic "virt" machine type will be used when creating Qemu virtual machine,  for both arm/aarch64,  instead of  a specific board. 

- A 32bit arm cpu could be used for arm 32 programming;  A 64 bit  cpu could be used for aarch64 arm programming;  For detailed list of cortex-A series CPU, please refer to [Arm contex-A](<https://en.wikipedia.org/wiki/ARM_Cortex-A>)

  

- Linux distro:  Archlinux will be used, for both arm/aarch64.   Similarly, a generic build of archlinux will be used instead of a build for specific board. 

  [Archlinux arm distro Link] 

  [armv7](http://www.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz)

  [aarch64](http://www.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz)



### 2.  Host environment

Archlinux for PC.   Here are the necessary packages:

```bash
pacman -S qemu qemu-arch-extra multipath-tools

```



### 3.  arm(32) qemu setup

- ##### disk image/kernel  preparation

  ```bash
  [luke@nuc armv7]$ wget http://tw.mirror.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
  [luke@nuc armv7]$ truncate -s 16G arm.raw
  [luke@nuc armv7]$ gdisk ./arm.raw 
  GPT fdisk (gdisk) version 1.0.4
  Command (? for help): n
  Partition number (1-128, default 1): 
  First sector (34-33554398, default = 2048) or {+-}size{KMGTP}: 
  Last sector (2048-33554398, default = 33554398) or {+-}size{KMGTP}: 
  Current type is 'Linux filesystem'
  Hex code or GUID (L to show codes, Enter = 8300): 
  Changed type of partition to 'Linux filesystem'
  Command (? for help): p
  Disk ./arm.raw: 33554432 sectors, 16.0 GiB
  Sector size (logical): 512 bytes
  Disk identifier (GUID): C7C74D91-ADBE-4CDA-BD1B-F24AD85EA70F
  Partition table holds up to 128 entries
  Main partition table begins at sector 2 and ends at sector 33
  First usable sector is 34, last usable sector is 33554398
  Partitions will be aligned on 2048-sector boundaries
  Total free space is 2014 sectors (1007.0 KiB)
  Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048        33554398   16.0 GiB    8300  Linux filesystem
  Command (? for help): w
  Final checks complete. About to write GPT data. THIS WILL OVERWRITE EXISTING
  PARTITIONS!!
  Do you want to proceed? (Y/N): Y
  OK; writing new GUID partition table (GPT) to ./arm.raw.
  Warning: The kernel is still using the old partition table.
  The new table will be used at the next reboot or after you
  run partprobe(8) or kpartx(8)
  The operation has completed successfully.
  ```


```bash
[luke@nuc armv7]$ sudo kpartx -a -v ./arm.raw 
add map loop0p1 (254:0): 0 33552351 linear 7:0 2048
[luke@nuc armv7]$ sudo blkid | grep loop0p1
/dev/mapper/loop0p1: PARTLABEL="Linux filesystem" PARTUUID="2950092c-7763-4c6d-9da3-bd066cdd6b0a"

[luke@nuc armv7]$ sudo mkfs.ext4 /dev/mapper/loop0p1 
[luke@nuc armv7]$ sudo mount /dev/mapper/loop0p1 /mnt
[luke@nuc armv7]$ sudo bsdtar -xpf ArchLinuxARM-armv7-latest.tar.gz -C /mnt
[luke@nuc armv7]$ cp -r /mnt/boot ./
[luke@nuc armv7]$ ls -lh
total 1.5G
-rw-r--r-- 1 luke luke 424M Jun  5 16:18 ArchLinuxARM-armv7-latest.tar.gz
-rw-r--r-- 1 luke luke  16G Jun  5 17:52 arm.raw
drwxr-xr-x 3 luke luke   59 Jun  5 17:52 boot
[luke@nuc armv7]$ ls -l ./boot
total 13044
drwxr-xr-x 2 luke luke   28672 Jun  5 17:52 dtbs
-rw-r--r-- 1 luke luke 6611550 Jun  5 17:52 initramfs-linux.img
-rwxr-xr-x 1 luke luke 6696600 Jun  5 17:52 zImage

[luke@nuc armv7]$ sudo umount /mnt
[luke@nuc armv7]$ sudo kpartx -d ./arm.raw 
loop deleted : /dev/loop0

```


 - ##### Qemu startup script
 ```bash
[luke@nuc armv7]$ cat arm.sh
#!/usr/bin/bash
qemu-system-arm -M virt,highmem=off \
  -cpu cortex-a15 \
  -m 2048 \
  -drive file=./arm.raw,format=raw,index=0,if=virtio,media=disk \
  -smp 2  \
  -kernel boot/zImage \
  -initrd boot/initramfs-linux.img \
  -append 'root=PARTUUID=2950092c-7763-4c6d-9da3-bd066cdd6b0a  rw' \
  -nographic

 ```

There are two caveats that need to be fixed before this startup script can work:

  - qemu-system-arm bug
	  According to [pci bug](https://bugs.launchpad.net/qemu/+bug/1790975) , I need to use **"-M virt,highmem"**  to workaround this bug. "Virt" machine simulate pci disk, unfortunately there is a bug, which still is not fixed. 
	
  - virtio_pci.ko 
	  The stock 32bit kernel from  archlinuxarm does not have virtio_pci built in , and the stock /boot/initramfs-linux.img  does not contains "virtio_pci.ko" module, so kernel can not load up the pci disk. I have to find the "virtio_pci.ko.gz" in the stock rootfs,  add it into /boot/initramfs-linux.img, then reboot qemu. Under the emergency shell, I have to load this module manually, then kernel can find rootfs and boot. 
	
  - root owned files in initramfs-linux.img
	
	  Be reminded that all the files within initramfs-linux.img must be owned by root.  Switch to root before you touch any files related to initramfs-linux.img, or when booting, kernel will complain these files are not owned by root and refuse to load them. 
	
	  

```bash

[luke@nuc initram]$ su - root

[root@nuc newram]# zcat ../initramfs-linux.img | bsdcpio -i 
27810 blocks
[root@nuc newram]# ls
bin  buildconfig  config  dev  etc  hooks  init  init_functions  lib  new_root  proc  run  sbin  sys  tmp  usr  var  VERSION

[luke@nuc armv7]$ sudo mount /dev/mapper/loop0p1 /mnt
[luke@nuc armv7]$ cd /mnt


[luke@nuc mnt]$ sudo find . -name "virtio_pci.ko*"
./usr/lib/modules/5.1.5-1-ARCH/kernel/drivers/virtio/virtio_pci.ko.gz
[luke@nuc mnt]$ sudo cp ./usr/lib/modules/5.1.5-1-ARCH/kernel/drivers/virtio/virtio_pci.ko.gz /data/luke/qemu/newram/lib/modules/5.1.5-1-ARCH/kernel/

[luke@nuc newram]$ sudo find . -name "virtio_pci*"
./usr/lib/modules/5.1.6-1-ARCH/kernel/drivers/virtio/virtio_pci.ko.gz

[root@nuc newram]# find . -mindepth 1 -printf '%P\0' | LANG=C bsdcpio -0 -o -H newc | gzip  > ../armv7/boot/initramfs-linux.img
297879 blocks

[root@nuc ~]# umount /mnt
[root@nuc initram]# exit
logout

```


Now we have create a new initramfs with virtio_pci module in it , let us start qemu and mount rootfs manually so we can boot archlinuxarm rootfs on Qemu "Virt" machine. 



```bash
[luke@nuc armv7]$ ./arm.sh

--------------------------------
Starting version 242.29-1-arch
:: running hook [udev]
:: Triggering uevents...
Waiting 10 seconds for device /dev/disk/by-partuuid/2950092c-7763-4c6d-9da3-bd066cdd6b0a ...
ERROR: device 'PARTUUID=2950092c-7763-4c6d-9da3-bd066cdd6b0a' not found. Skipping fsck.
:: mounting 'PARTUUID=2950092c-7763-4c6d-9da3-bd066cdd6b0a' on real root
mount: /new_root: can't find PARTUUID=2950092c-7763-4c6d-9da3-bd066cdd6b0a.
You are now being dropped into an emergency shell.
sh: can't access tty; job control turned off
[rootfs ]# blkid
[rootfs ]# cd lib/modules/5.1.5-1-ARCH/kernel/
[rootfs kernel]# ls
virtio_blk.ko     virtio_pci.ko.gz
[rootfs kernel]# insmod ./virtio_pci.ko.gz 
[  110.777837] virtio-pci 0000:00:01.0: enabling device (0100 -> 0103)
[  110.785949] virtio-pci 0000:00:02.0: enabling device (0100 -> 0103)
[rootfs kernel]# [  110.833466] virtio_blk virtio1: [vda] 33554432 512-byte logical blocks (17.2 GB/16.0 GiB)
[  110.851266]  vda: vda1

[rootfs kernel]# blkid
/dev/vda1: UUID="c5b30ae8-0610-4d5e-9e49-38c029bbca51" TYPE="ext4" PARTLABEL="Linux filesystem" PARTUUID="2950092c-7763-4c6d-9da3-bd066cdd6b0a"

[rootfs kernel]# fsck.ext4 /dev/vda1
[rootfs kernel]# mount -o rw /dev/vda1 /new_root
[rootfs kernel]# exit

Trying to continue (this will most likely fail) ...
:: running cleanup hook [udev]
[  332.545045] systemd[1]: systemd 242.29-1-arch running in system mode. (+PAM +AUDIT -SELINUX -IMA -APPARMOR +SMACK -SYSVINIT +UTMP +LIBCRYPTSETUP +GCRYPT +GNUTLS +ACL +XZ +LZ4 +SECCOMP +BLKID +ELFUTILS +KMOD +IDN2 -IDN +PCRE2 default-hierarchy=hybrid)
[  332.550276] systemd[1]: Detected virtualization qemu.
[  332.550759] systemd[1]: Detected architecture arm.

Welcome to Arch Linux ARM!

[  332.790661] systemd[1]: Set hostname to <alarm>.

      .......................
      
[  OK  ] Reached target Graphical Interface.
[  348.795061] random: crng init done
[  348.795607] random: 7 urandom warning(s) missed due to ratelimiting

Arch Linux 5.1.5-1-ARCH (ttyAMA0)

alarm login: root
Password: 
.........
Last login: Wed Jun  5 13:53:51 on ttyAMA0
[root@alarm ~]# 


```

Now the archlinuxarm has booted O.K,  it is time to generate a new initramfs so the next  booting, we do not need to manually mount the rootfs again. 

```bash
[root@alarm ~]# mkinitcpio -p linux-armv7
[root@alarm ~]# lsinitcpio /boot/initramfs-linux.img | grep virtio_*
usr/lib/modules/5.1.5-1-ARCH/kernel/virtio_net.ko
usr/lib/modules/5.1.5-1-ARCH/kernel/virtio_blk.ko
usr/lib/modules/5.1.5-1-ARCH/kernel/virtio_mmio.ko
usr/lib/modules/5.1.5-1-ARCH/kernel/virtio_pci.ko
[root@alarm ~]# 

```

Now we have a new initramfs with "virtio_pci" module built in.  We still need to copy  /boot/initramfs-linux.img  out of Qemu VM to replace the original initramfs used by qemu booting.  After that,  the booting shall be automatically O.K without manual mounting. 



- ##### Qemu network setup 

It is time to install gcc toolchain in Qemu machine.  To do that , we need internet access.   I would create a bridge network environment for Qemu. Here is what I did:

```bash
[luke@nuc armv7]$ ip  a
......
3: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 94:c6:91:14:91:72 brd ff:ff:ff:ff:ff:ff
    inet 192.168.200.100/24 brd 192.168.200.255 scope global eno1
       valid_lft forever preferred_lft forever
    inet6 fe80::96c6:91ff:fe14:9172/64 scope link 
       valid_lft forever preferred_lft forever

[luke@nuc armv7]$ sudo ip l set eno1 down
[luke@nuc armv7]$ sudo ip l add br0 type bridge
[luke@nuc armv7]$ sudo ip l set eno1 master br0
[luke@nuc armv7]$ sudo ip l set eno1 up
[luke@nuc armv7]$ sudo ip l set br0 up
[luke@nuc armv7]$ ip a
.......
3: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master br0 state UP group default qlen 1000
    link/ether 94:c6:91:14:91:72 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::96c6:91ff:fe14:9172/64 scope link 
       valid_lft forever preferred_lft forever
5: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether de:13:8e:1a:02:8e brd ff:ff:ff:ff:ff:ff
    inet 192.168.200.208/24 brd 192.168.200.255 scope global dynamic br0
       valid_lft 172754sec preferred_lft 172754sec
    inet6 fe80::dc13:8eff:fe1a:28e/64 scope link 
       valid_lft forever preferred_lft forever
```

Now we have a bridge device **"br0"** working.   Let us add a tap device for Qemu, so it can join the bridged network. 

```bash
sudo ip tuntap add dev tap0 mode tap user luke
sudo ip tuntap list
sudo ip l set tap0 master br0
sudo ip l set tap0 up

[luke@nuc ~]$ ip  l
.......
3: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master br0 state UP mode DEFAULT group default qlen 1000
    link/ether 94:c6:91:14:91:72 brd ff:ff:ff:ff:ff:ff
5: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether de:13:8e:1a:02:8e brd ff:ff:ff:ff:ff:ff
6: tap0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master br0 state UP mode DEFAULT group default qlen 1000
    link/ether 66:21:ee:9d:f2:9b brd ff:ff:ff:ff:ff:ff
```

With tap device **"tap0"** in place, let us modify our qemu startup script to use it.

```bash
[luke@nuc armv7]$ cat arm.sh
#!/usr/bin/bash
qemu-system-arm -M virt,highmem=off \
  -cpu cortex-a15 \
  -m 2048 \
  -drive file=./arm.raw,format=raw,index=0,if=virtio,media=disk \
  -smp 2  \
  -kernel boot/zImage \
  -initrd boot/initramfs-linux.img \
  -append 'root=PARTUUID=2950092c-7763-4c6d-9da3-bd066cdd6b0a  rw' \
  -nographic \
  -netdev tap,id=nd0,ifname=tap0,script=no,downscript=no -device e1000,netdev=nd0
```



- ##### User space toolchain setup

```bash
[root@alarm ~]# ip a
..............
2: enp0s1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff
    inet 192.168.200.209/24 brd 192.168.200.255 scope global dynamic enp0s1
       valid_lft 172359sec preferred_lft 172359sec
    inet6 fe80::5054:ff:fe12:3456/64 scope link 
       valid_lft forever preferred_lft forever

[root@alarm ~]# pacman -Syy
[root@alarm ~]# pacman-key --init
[root@alarm ~]# pacman-key --populate archlinuxarm
[root@alarm ~]# pacman -S gcc gdb pwndbg radare2

[alarm@alarm ~]$ lscpu
Architecture:        armv7l
Byte Order:          Little Endian
CPU(s):              2
On-line CPU(s) list: 0,1
Thread(s) per core:  1
Core(s) per socket:  2
Socket(s):           1
Vendor ID:           ARM
Model:               1
Model name:          Cortex-A15
Stepping:            r2p1
BogoMIPS:            125.00
Flags:               half thumb fastmult vfp edsp thumbee neon vfpv3 tls vfpv4 idiva idivt vfpd32 lpae evtstrm
[alarm@alarm ~]$ lspci
00:00.0 Host bridge: Red Hat, Inc. QEMU PCIe Host bridge
00:01.0 Ethernet controller: Intel Corporation 82540EM Gigabit Ethernet Controller (rev 03)
00:02.0 SCSI storage controller: Red Hat, Inc. Virtio block device

```



-  ##### Some small test
```bash
[alarm@alarm ~]$ cat hello.c
#include <stdio.h>

int main(void) {
        printf("Hello Arm World!\n");
        return 0;
}

[alarm@alarm ~]$ gcc -g hello.c
[alarm@alarm ~]$ ./a.out
Hello Arm World!

[alarm@alarm ~]$ gdb ./a.out
(gdb) l
1       #include <stdio.h>
2
3       int main(void) {
4               printf("Hello Arm World!\n");
5               return 0;
6       }
7
(gdb) b main
Breakpoint 1 at 0x580: file hello.c, line 4.
(gdb) r
Starting program: /home/alarm/a.out 

Breakpoint 1, main () at hello.c:4
4               printf("Hello Arm World!\n");
(gdb) n
Hello Arm World!
5               return 0;
(gdb) c
Continuing.
[Inferior 1 (process 1007) exited normally]
```