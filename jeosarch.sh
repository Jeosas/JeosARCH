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
# JeosARCH setup script
#
#----------------------------------------------------------------------------------


echo -ne "
----------------------------------------------------------------------------------
    $$$$$\                                $$$$$$\  $$$$$$$\   $$$$$$\  $$\   $$\
    \__$$ |                              $$  __$$\ $$  __$$\ $$  __$$\ $$ |  $$ |
       $$ | $$$$$$\   $$$$$$\   $$$$$$$\ $$ /  $$ |$$ |  $$ |$$ /  \__|$$ |  $$ |
       $$ |$$  __$$\ $$  __$$\ $$  _____|$$$$$$$$ |$$$$$$$  |$$ |      $$$$$$$$ |
 $$\   $$ |$$$$$$$$ |$$ /  $$ |\$$$$$$\  $$  __$$ |$$  __$$< $$ |      $$  __$$ |
 $$ |  $$ |$$   ____|$$ |  $$ | \____$$\ $$ |  $$ |$$ |  $$ |$$ |  $$\ $$ |  $$ |
 \$$$$$$  |\$$$$$$$\ \$$$$$$  |$$$$$$$  |$$ |  $$ |$$ |  $$ |\$$$$$$  |$$ |  $$ |
  \______/  \_______| \______/ \_______/ \__|  \__|\__|  \__| \______/ \__|  \__|
----------------------------------------------------------------------------------
"

echo ""
echo "----------------------------------------------------------------------------------"
echo "- Selecting install disk"
echo "----------------------------------------------------------------------------------"
echo ""

echo "-------------------------------------------------"
echo "- Available disks\n\n"

lsblk

echo "-------------------------------------------------"
echo "Please enter disk to use for this install: (example /dev/sda)"
read DISK
if [ ! -e DISK ]; then
    echo "Couldn't find disk: ${DISK}. Aborting..."
    echo "Rebooting 3 ..." && sleep 1
    echo "Rebooting 2 ..." && sleep 1
    echo "Rebooting 1" && sleep 1
    reboot now
fi

# storing partition names
if [[ $DISK =~ "nvme" ]]; then
    ESP_PART="${DISK}p1"
    ROOT_PART="${DISK}p2"
else
    ESP_PART="${DISK}1"
    ROOT_PART="${DISK}2"
fi

# base install
DISK=$DISK ESP_PART=$ESP_PART ROOT_PART=$ROOT_PART ./scripts/0-install.sh
# copy scripts
mkdir -p /mnt/root/scripts
cp -R ./scripts /mnt/root/scripts
# base archlinux setup
archroot /mnt $HOME/scripts/1-install.sh
# user setup and dotfiles installation
archroot /mnt $HOME/scripts/2-user.sh
# bootloader install and setup
archroot /mnt ROOT_PART=$ROOT_PART $HOME/scripts/3-bootloader.sh

# unmounting system and reboot
umount -R /mnt
swapoff -a

echo -ne "
----------------------------------------------------------------------------------
    $$$$$\                                $$$$$$\  $$$$$$$\   $$$$$$\  $$\   $$\
    \__$$ |                              $$  __$$\ $$  __$$\ $$  __$$\ $$ |  $$ |
       $$ | $$$$$$\   $$$$$$\   $$$$$$$\ $$ /  $$ |$$ |  $$ |$$ /  \__|$$ |  $$ |
       $$ |$$  __$$\ $$  __$$\ $$  _____|$$$$$$$$ |$$$$$$$  |$$ |      $$$$$$$$ |
 $$\   $$ |$$$$$$$$ |$$ /  $$ |\$$$$$$\  $$  __$$ |$$  __$$< $$ |      $$  __$$ |
 $$ |  $$ |$$   ____|$$ |  $$ | \____$$\ $$ |  $$ |$$ |  $$ |$$ |  $$\ $$ |  $$ |
 \$$$$$$  |\$$$$$$$\ \$$$$$$  |$$$$$$$  |$$ |  $$ |$$ |  $$ |\$$$$$$  |$$ |  $$ |
  \______/  \_______| \______/ \_______/ \__|  \__|\__|  \__| \______/ \__|  \__|
----------------------------------------------------------------------------------
                   Done - Please Eject Install Media and Reboot

"