#!/bin/bash
#----------------------------------------------------------------------------------
#    $$$$$\                                $$$$$$\  $$$$$$$\   $$$$$$\  $$\   $$\ 
#    \__$$ |                              $$  __$$\ $$  __$$\ $$  __$$\ $$ |  $$ |
#       $$ | $$$$$$\   $$$$$$\   $$$$$$$\ $$ /  $$ |$$ |  $$ |$$ /  \__|$$ |  $$ |
#       $$ |$$  __$$\ $$  __$$\ $$  _____|$$$$$$$$ |$$$$$$$  |$$ |      $$$$$$$$ |
# $$\   $$ |$$$$$$$$ |$$ /  $$ |\$$$$$$\  $$  __$$ |$$  __$$< $$ |      $$  __$$ |
# $$ |  $$ |$$   ____|$$ |  $$ | \____$$\ $$ |  $$ |$$ |  $$ |$$ |  $$\ $$ |  $$ |
# \$$$$$$  |\$$$$$$$\ \$$$$$$  |$$$$$$$  |$$ |  $$ |$$ |  $$ |\$$$$$$  |$$ |  $$ |
#  \______/  \_______| \______/ \_______/ \__|  \__|\__|  \__| \______/ \__|  \__|
#                                                                               
#
# Base Archlinux installation and configuration
#
#----------------------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------------------"
echo "- System setup "
echo "----------------------------------------------------------------------------------"
echo ""

# optimizing pacman
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist
sed -i 's/^#Para/Para/' /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm

# optimizing makepkg
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -gt 8000000 ]]; then
	nc=$(grep -c ^processor /proc/cpuinfo)
	echo "You have " $nc" cores."
	echo "-------------------------------------------------"
	echo "Changing the makeflags for "$nc" cores."
	sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /mnt/etc/makepkg.conf
	echo "Changing the compression settings for "$nc" cores."
	sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /mnt/etc/makepkg.conf
fi

# set timezone
read -p "Enter a time zone [Europe/Paris]: " timezone
timezone=${timezone:-"Europe/Paris"}
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc --utc

# set locals
sed -i "s/^#fr_FR.UTF-8/fr_FR.UTF-8/" /etc/locale.gen
sed -i "s/^#en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
export LANG="en_US.UTF-8"
echo "KEYMAP=fr-pc" > /etc/vconsole.conf  # setting up an AZERTY keymap

# set hostname
HOST=
while [[ $HOST = "" ]]; do
   read -p "Enter a hostname for your PC: " HOST
done
echo $HOST > /etc/hostname
cat << EOF > /etc/hosts
# <ip-address>	<hostname.domain.org>	<hostname>
127.0.0.1	localhost
::1		localhost
127.0.1.1	${HOST}.localdomain	$HOST
EOF

# setup mkinitcpio
sed -i 's/BINARIES=()/BINARIES=("\/usr\/bin\/btrfs")/' /etc/mkinitcpio.conf
sed -i 's/#COMPRESSION="lz4"/COMPRESSION="lz4"/' mkinitcpio.conf
sed -i 's/#COMPRESSION_OPTIONS=()/COMPRESSION_OPTIONS=(-9)/' mkinitcpio.conf
sed -i 's/^HOOKS/HOOKS=(base systemd autodetect modconf block sd-encrypt resume filesystems keyboard fsck)/' /etc/mkinitcpio.conf

mkinitcpio -p linux

# preventing snapshot slowdowns
echo 'PRUNENAMES = ".snapshots"' >> /etc/updatedb.conf

# installing paru
git clone https://aur.archlinux.org/paru.git
cr paru
makepkg -si
cd .. && rm -rf paru

echo ""
echo "----------------------------------------------------------------------------------"
echo "- Root password"
echo "----------------------------------------------------------------------------------"
echo ""

passwd

# END - Continue with 2-user.sh
