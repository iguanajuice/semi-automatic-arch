#!/bin/bash

if [[ $1 != start ]]
then
	echo Please read through install.sh and configure it where necessary
	echo then rerun the script using command: sh install.sh start
	exit
fi

USER=user              # Username of auto-generated user (set as blank if you wish to not create one)
FULLNAME='Arch User'   # Full name of auto-generated user (use quotes)
HOSTNAME=archlinux     # The system's hostname
EDITOR=micro           # Choice for terminal-based text editor
SHELL=fish             # Set default interactive shell, does NOT change system shell
KERNEL=linux           # Which Linux kernel to use: linux, linux-lts, linux-zen, linux-rt, linux-rt-lts
UCODE=                 # Set to either amd-ucode or intel-ucode or leave blank if using neither
HVA=libva-mesa-drivers # Hardware video acceleration: Radeon=libva-mesa-drivers, Nvidia=libva-nvidia-drivers,
                       # Intel (pre-2014)=libva-intel-drivers, Intel (2014+)=intel-media-driver
TZ=America/New_York    # Your timezone (Region/City). Your timezone can be found using `ls /usr/share/zoneinfo`
ALIASES=false          # Add global aliases for sudo, pacman, systemctl, and $EDITOR
USE_DOAS=true          # Use `doas` instead of `sudo`
MBRDEVICE=             # Ignore this if using UEFI

sed -i 's/#Parallel/Parallel/g' /etc/pacman.conf # haha package download go brrrrr
pacstrap -K /mnt --needed \
	base base-devel $KERNEL $KERNEL-headers linux-firmware dkms $UCODE $EDITOR $SHELL dash `# Core packages` \
	grub efibootmgr os-prober                                                              `# Bootloader` \
	arch-install-scripts neofetch git wget man-db usbutils lshw dmidecode                  `# CLI tools` \
	btrfs-progs lvm2 gvfs-mtp ntfs-3g                                                      `# Expanded filesystem support` \
	networkmanager iptables-nft net-tools wireless_tools iw                                `# Networking` \
	wireplumber pipewire-pulse pipewire-jack pipewire-alsa                                 `# Audio` \
	$HVA libva-utils gstreamer-vaapi                                                       `# Hardware video acceleration` \
	gnu-free-fonts libertinus-font ttf-liberation ttf-ubuntu-font-family ttf-dejavu        `# Extra fonts` \
	noto-fonts noto-fonts-cjk noto-fonts-emoji                                             `# Full unicode support`

genfstab -U /mnt > /mnt/etc/fstab
sed -i 's/subvolid=//g' /mnt/etc/fstab # Timeshift doesn't play nice with subvolid

arch-chroot /mnt sh -c "
	grub-install $MBRDEVICE || return
	sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/g' /etc/default/grub
	sed -i 's/ quiet//g' /etc/default/grub
	grub-mkconfig -o /boot/grub/grub.cfg
 
	if [ $SHELL = fish ]
		then echo -e '\nset fish_greeting' > /etc/fish/config.fish
	fi

	if [ $ALIASES = true ]
	then
		ln -s /usr/bin/$EDITOR /usr/local/bin/vi
		ln -s /usr/bin/pacman /usr/local/bin/pm
		ln -s /usr/bin/systemctl /usr/local/bin/sv
	
		if [ $USE_DOAS = true ]
		then
			ln -s /usr/bin/doas /usr/local/bin/s
		else
			ln -s /usr/bin/sudo /usr/local/bin/s
		fi
	fi

	if [ $USE_DOAS = true ]
	then
		pacman --noconfirm -Rndd sudo
		pacman --noconfirm --needed -S doas
		ln -s /usr/bin/doas /usr/local/bin/sudo
		echo permit persist keepenv :wheel > /etc/doas.conf
	else
 		sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
   	fi

	echo -e '\n~ Password for root:'
	while true; do passwd && break; done
	chsh -s /bin/$SHELL
	if [ -n $USER ]
	then
		useradd -m $USER -c '$FULLNAME' -s /bin/$SHELL -G wheel
		echo -e '\n~ Password for $USER'
		while true; do passwd $USER && break; done
	fi
	echo $HOSTNAME > /etc/hostname

	echo -e '\n~ Uncomment your keyboard locale from the upcoming list...press enter to continue'
	read
	$EDITOR /etc/locale.gen
	locale-gen | awk 'NR==2 {print substr(\$1,1,length(\$1)-3)}' > /tmp/locale
	echo LANG=\$(cat /tmp/locale) > /etc/locale.conf
	ln -sf /usr/share/zoneinfo/$TZ /etc/localtime

	pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	pacman-key --lsign-key 3056513887B78AEB
	pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
	echo -e '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf

	sed -i 's/#Parallel/Parallel/g' /etc/pacman.conf
	sed -i 's/#Color/Color/g' /etc/pacman.conf
	sed -i 's/#IgnorePkg/IgnorePkg/g' /etc/pacman.conf
	sed -i 's/#IgnoreGroup/IgnoreGroup/g' /etc/pacman.conf
	sed -i '90,91 s/#//' /etc/pacman.conf # This enables the 32-bit repo
	pacman --noconfirm -Syu > /dev/null

	echo kernel.sysrq=1 > /etc/sysctl.d/kernel.conf # Enable REISUB keys
 
	systemctl enable NetworkManager

	# If something goes wrong, you won't have to wait 90 seconds
	sed -i 's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=15s/g' /etc/systemd/system.conf
	sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=15s/g' /etc/systemd/system.conf
	sed -i 's/#DefaultDeviceTimeoutSec=90s/DefaultDeviceTimeoutSec=15s/g' /etc/systemd/system.conf

	# Use `dash` for POSIX shell
 	ln -sf /usr/bin/dash /usr/bin/sh

 	# Fix OpenAL audio
  	mkdir /home/$USER/.config
  	echo drivers=pulse > /home/$USER/.config/alsoft.conf
   	chown -R $USER:$USER /home/$USER/.config
 
	exit
"
