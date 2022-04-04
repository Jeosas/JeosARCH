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
# Disk Partition setup and base ArchLinux install
#
#----------------------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------------------"
echo "- Setting up pacman for optimal download"
echo "----------------------------------------------------------------------------------"
echo ""

timedatectl set-ntp true
sed -i 's/^#Para/Para/' /etc/pacman.conf
pacman -S --noconfirm reflector
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
iso=$(curl -4 ifconfig.co/country-iso)
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt


echo ""
echo "----------------------------------------------------------------------------------"
echo "- Preparing disk for Archlinux install"
echo "----------------------------------------------------------------------------------"
echo ""

echo -e "\nInstalling prereqs...\n"

pacman -S --noconfirm gptfdisk btrfs-progs

echo -e "\nTHIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"
read -p "Are you sure you want to continue (y/N):" formatdisk
case $formatdisk in
y|Y|yes|Yes|YES)
	echo -e "\nFormatting disk...\n"

	# disk prep
	sgdisk -Z $DISK # zap all on disk
	sgdisk -a 2048 -o $DISK # new gpt disk 2048 alignment

	# create partitions
	sgdisk -n 1::+550M -t=1:ef00 --change-name=1:'EFI' $DISK # partition 1 (EFI Boot Partition)
	sgdisk -n 2::-0 -t=3:8306 --change-name=2:'ROOT' $DISK # partition 2 (Root Partition)

	# make filesystems
	echo -e "\nCreating Filesystems...\n"

	# formating /boot/efi
	mkfs.vfat -F32 -n "EFI" $ESP_PART

	# encryption
	cryptsetup luksFormat -y --perf-no_read_workqueue --perf-no_write_workqueue --type luks2 --cipher aes-xts-plain64 --key-size 512 --iter-time 2000 --pbkdf argon2id --hash sha3-512 $ROOT_PART
	cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent open $ROOT_PART crypt

	# init btrfs /
	mkfs.btrfs -L ROOT /dev/mapper/crypt
	mount /dev/mapper/crypt /mnt
	ls /mnt | xargs btrfs subvolume delete
	btrfs sub create /mnt/@
	btrfs sub create /mnt/@home
	btrfs sub create /mnt/@pkg
	btrfs sub create /mnt/@abs
	btrfs sub create /mnt/@tmp
	btrfs sub create /mnt/@snapshots
	btrfs sub create /mnt/@btrfs
	btrfs sub create /mnt/@swap
	umount /mnt

	# mounting file system
	mount -o subvol=@ /dev/mapper/crypt /mnt
	mkdir -p /mnt/{boot,home,.snapshots,.swap,btrfs}
	mkdir -p /mnt/var/{cache/pacman/pkg,abs,tmp}
	mount -o compress=zst,space_cache,autodefrag,subvol=@home /dev/mapper/crypt /mnt/boot
	mount -o compress=zst,space_cache,autodefrag,subvol=@pkg  /dev/mapper/crypt /mnt/var/cache/pacman/pkg
	mount -o compress=zst,space_cache,autodefrag,subvol=@abs /dev/mapper/crypt /mnt/var/abs
	mount -o compress=zst,space_cache,autodefrag,subvol=@tmp /dev/mapper/crypt /mnt/var/tmp
	mount -o compress=zst,space_cache,autodefrag,subvol=@snapshots /dev/mapper/crypt /mnt/.snapshots
	mount -o compress=no,space_cache,subvol=@swap /dev/mapper/crypt /mnt/boot
	mount -o compress=zst,space_cache,autodefrag,subvolid=5 /dev/mapper/crypt /mnt/btrfs

	# create Swap
	TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*' | sed 's/^\(.*\)....../\1/')  # get total RAM in GB
	truncate -s 0 /mnt/.swapvol/swapfile
	chattr +C /mnt/.swapvol/swapfile
	btrfs property set /mnt/.swapvol/swapfile compression none
	fallocate -l ${TOTALMEM}G /mnt/.swapvol/swapfile
	chmod 600 /mnt/.swapvol/swapfile
	mkswap /mnt/.swapvol/swapfile
	swapon /mnt/.swapvol/swapfile

	# mount the EFI partition
	mount $ESP_PART /mnt/boot
	;;
*)
	echo "Rebooting 3 ..." && sleep 1
	echo "Rebooting 2 ..." && sleep 1
	echo "Rebooting 1" && sleep 1
	reboot now
	;;
esac


if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted, can not continue. Aborting..."
    echo "Rebooting 3 ..." && sleep 1
	echo "Rebooting 2 ..." && sleep 1
	echo "Rebooting 1" && sleep 1
    reboot now
fi

echo ""
echo "----------------------------------------------------------------------------------"
echo "- Installing Archlinux (Base system) "
echo "----------------------------------------------------------------------------------"
echo ""

pacstrap /mnt base base-devel linux linux-firmware \
	git \
	vim \
	nano \
	opendoas \
	btrfs-progs \
	archlinux-keyring \
	wget \
	man-db \
	man-pages \
	openssh \
	bc \
	zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting \
	networkmanager \
	--noconfirm --needed

# generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# updating system clock
timedatectl set-ntp true

# END - Continue with 1-install.sh
