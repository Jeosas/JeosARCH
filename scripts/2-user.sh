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
# Creating user and installing dotfiles
#
#----------------------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------------------"
echo "- Admin user"
echo "----------------------------------------------------------------------------------"
echo ""

read -p "Enter new user name:" USER

# add user
useradd -mg users -G -s /bin/zsh $USER
# user password
passwd $USER
# make user admin with no pass
echo "permit nopass $USER" > /etc/doas.conf

echo ""
echo "----------------------------------------------------------------------------------"
echo "- Installing dotfiles"
echo "----------------------------------------------------------------------------------"
echo ""

su $USER
cd ~

# clone git repository

# doas install.sh

exit

# revert nopass for admin user
echo "permit persist $USER" > /etc/doas.conf

# END - Continue with 3-bootloader.sh
