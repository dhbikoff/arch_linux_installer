#!/bin/bash

timedatectl set-ntp true

parted --script /dev/sda \
  mklabel gpt \
  mkpart ESP fat32 1MiB 513MiB \
  set 1 boot on \
  mkpart primary linux-swap 513MiB 2.5GiB \
  mkpart primary ext4 2.5GiB 100% \

mkfs.fat -F32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3

mount /dev/sda3 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

echo -e "Server = http://mirror.math.princeton.edu/pub/archlinux/\$repo/os/\$arch\n$(cat /etc/pacman.d/mirrorlist)" > /etc/pacman.d/mirrorlist 

pacstrap /mnt base

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt << EOF
  ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
  hwclock --systohc --utc
  locale-gen
  echo LANG=en_US.UTF-8 > /etc/locale.conf
  echo arch > /etc/hostname
  mkinitcpio -p linux
  echo -e "arch\narch" | passwd
  bootctl --path=/boot install
  echo -e "default arch\ntimeout 4\n" > /boot/loader/loader.conf
  echo -e "title Arch Linux\nlinux /vmlinuz-linux\ninitrd /initramfs-linux.img\noptions root=/dev/sda3 rw" > /boot/loader/entries/arch.conf
EOF

umount -R /mnt
reboot