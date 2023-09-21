#!/bin/bash

if [[ $1 != start ]]
then
	echo Please read through install.sh and configure it where necessary
 	echo then rerun the script using command: sh install.sh start
	exit
fi

_USER=user           # Username of auto-generated user (set as blank if you wish to not create one)
FULLNAME='Arch User' # Full name of auto-generated user (be sure to use quotes)
_EDITOR=micro        # Choice for terminal-based text editor
_SHELL=fish          # Set default interactive shell, does NOT change system shell
KERNEL=linux         # Which Linux kernel to use: linux, linux-lts, linux-zen, linux-rt, linux-rt-lts
UCODE=               # Set to either amd-ucode or intel-ucode or leave blank if using neither
LIBVA=mesa           # Driver for hardware video encoding/decoding: Radeon=mesa, Intel=intel, Nvidia=vdpau
TZ=America/New_York  # Your timezone (Region/City). Your timezone can be found in /usr/share/zoneinfo

sed -i 's/#Parallel/Parallel/g' /etc/pacman.conf # haha package download go brrrrr
pacstrap -K /mnt --needed base base-devel $KERNEL $KERNEL-headers linux-firmware $UCODE doas $_EDITOR $_SHELL `# Core packages` \
	grub efibootmgr                                                                 `# Bootloader` \
	git wget btop neofetch man-db usbutils dmidecode                                `# Miscellaneous CLI tools` \
	btrfs-progs lvm2 ntfs-3g gvfs-mtp                                               `# Filesystem support` \
	networkmanager net-tools wireless_tools                                         `# Networking` \
	wireplumber pipewire-pulse pipewire-jack                                        `# Audio` \
	libva-$LIBVA-driver gstreamer-vaapi                                             `# Hardware video codecs` \
 	gnu-free-fonts libertinus-font ttf-liberation ttf-ubuntu-font-family ttf-dejavu `# Extra fonts` \
  	noto-fonts noto-fonts-cjk noto-fonts-emoji                                      `# Full unicode support`

genfstab -U /mnt > /mnt/etc/fstab
sed -i 's/subvolid/_subvolid/g' > /mnt/etc/fstab # Timeshift doesn't play nice with subvolid ;)
echo permit persist keepenv :wheel > /mnt/etc/doas.conf
if [ $_SHELL = fish ]
	then echo -e '\nset fish_greeting' > /mnt/etc/fish/config.fish
fi
arch-chroot /mnt sh -c "
	ln -s /usr/bin/doas /usr/local/bin/sudo
	pacman --noconfirm -Rndd sudo > /dev/null

	echo -e '\n Password for root:'
	while true; do passwd && break; done
	chsh -s /bin/$_SHELL
 	if [ -n \"$_USER\" ]
  	then
		useradd -m $_USER -c $FULLNAME -s /bin/$_SHELL -G wheel
		echo -e '\n Password for $_USER'
		while true; do passwd $_USER && break; done
	fi
	echo -e '\n Uncomment your locale from the upcoming list...press enter to continue'
	read
	$_EDITOR /etc/locale.gen
	locale-gen | awk 'NR==2 {print substr(\$1,1,length(\$1)-3)}' > /tmp/locale
	echo LANG=\$(cat /tmp/locale) > /etc/locale.conf
	ln -sf /usr/share/zoneinfo/$TZ /etc/localtime

	grub-install
	sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/g' /etc/default/grub
 	sed -i 's/ quiet//g' /etc/default/grub
	grub-mkconfig -o /boot/grub/grub.cfg

	pacman-key --init
	pacman-key --populate
	
	pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	pacman-key --lsign-key 3056513887B78AEB
	pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
	echo '
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf

	sed -i 's/#Parallel/Parallel/g' /etc/pacman.conf
	sed -i 's/#Color/Color/g' /etc/pacman.conf
	sed -i 's/#IgnorePkg/IgnorePkg/g' /etc/pacman.conf
	sed -i 's/#IgnoreGroup/IgnoreGroup/g' /etc/pacman.conf
 	sed -i '90,91 s/#//' /etc/pacman.conf
 	pacman --noconfirm -Syu > /dev/null
   
	echo kernel.sysrq=1 > /etc/sysctl.d/kernel.conf
	systemctl enable NetworkManager

	sed -i 's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=10s/g' /etc/systemd/system.conf
 	sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/g' /etc/systemd/system.conf
  	sed -i 's/#DefaultDeviceTimeoutSec=90s/DefaultDeviceTimeoutSec=10s/g' /etc/systemd/system.conf

	exit
"
echo -e '\n All done, run command reboot to restart your system'
