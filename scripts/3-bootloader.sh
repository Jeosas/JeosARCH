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
# Installing bootloader
#
#----------------------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------------------"
echo "- Installing rEFInd (bootloader)"
echo "----------------------------------------------------------------------------------"
echo ""

# install microcode
proc_type=$(lscpu | awk '/Vendor ID:/ {print $3}')
case "$proc_type" in
    GenuineIntel)
        echo "Installing Intel microcode"
        pacman -S intel-ucode --noconfirm --needed
        MICRO_CODE="/intel-ucode.img"
        ;;
    AuthenticAMD)
        echo "Installing AMD microcode"
        pacman -S amd-ucode --noconfirm --needed
        MICRO_CODE="/amd-ucode.img"
        ;;
esac

# install rEFInd
paru -S refind preloader-signed
cp /usr/share/preloader-signed/{PreLoader,HashTool}.efi /boot/EFI/systemd
refind-install --preloader /usr/share/preloader-signed/PreLoader.efi

# install theme (LightAir/darkmini)
cd /boot/EFI/refind
mkdir themes && cd themes
git clone https://github.com/LightAir/darkmini.git
cd ~

# configure rEFInd
cat << EOF >> /boot/EFI/refind/refind.conf
menuentry "Arch Linux" {
    icon     icon /EFI/refind/themes/darkmini/icons/os_arch.png
    volume   "Arch Linux"
    loader   /vmlinuz-linux
    initrd   /initramfs-linux.img
    options  "rd.luks.name=$(blkid $ROOT_PART | cut -d " " -f2 | cut -d '=' -f2 | sed 's/\"//g')=crypt root=/dev/mapper/crypt rootflags=subvol=@ resume=/dev/mapper/crypt resume_offset=$( echo "$(btrfs_map_physical /.swapvol/swapfile | head -n2 | tail -n1 | awk '{print $6}') / $(getconf PAGESIZE) " | bc) rw add_efi_memmap initrd=${MICRO_CODE}"
    submenuentry "Boot using fallback initramfs" {
        initrd /boot/initramfs-linux-fallback.img
    }
}

include themes/darkmini/theme-mini.conf
banner themes/darkmini/bg/background.png
EOF

# pacman hooks
cat << EOF > /etc/pacman.d/hooks/refind.hook
[Trigger]
Operation=Upgrade
Type=Package
Target=refind
[Action]
Description = Updating rEFInd on ESP
When=PostTransaction
Exec=/usr/bin/refind-install --preloader /usr/share/preloader-signed/PreLoader.efi
EOF

# END - System is ready !!
