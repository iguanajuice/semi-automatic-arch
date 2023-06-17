#!/bin/sh

#HAVEREAD=1 # Uncomment if you have read this script

if [ $HAVEREAD != 1 ]
	then echo Please read through semi-automatic-arch/install.sh and configure it where necessary
	exit
fi

_USER=user        # Name of auto-generated user
_EDITOR=micro     # micro > nano :)
_SHELL=fish       # Set default interactive shell, does NOT change system shell
KERNEL=linux      # Pick which Linux kernel you want: linux, linux-lts, linux-zen, linux-rt linux-rt-lts
UCODE=            # Set to either amd-ucode or intel-ucode or leave blank if using neither
LIBVA=mesa        # Driver for hardware video encoding/decoding: Radeon=mesa, Intel=intel, Nvidia=vdpau

sed -ie 's/#Parallel/Parallel/g' /etc/pacman.conf # haha package download go brrrrr
pacstrap -K /mnt --needed base base-devel $KERNEL $KERNEL-headers $UCODE doas $_EDITOR `# Core packages` \
	grub efibootmgr                                                      `# Bootloader packages` \
	git wget htop neofetch man-db usbutils arch-install-scripts          `# Miscellaneous CLI tools` \
	btrfs-progs lvm2 ntfs-3g gvfs-mtp                                    `# Support additional filesystem types` \
	networkmanager net-tools wireless_tools                              `# Networking packages` \
	wireplumber pipewire-pulse pipewire-jack                             `# Audio packages` \
	libva-$LIBVA-driver gstreamer-vaapi                                  `# Hardware video codecs`

genfstab -U /mnt > /mnt/etc/fstab
if [ $_SHELL = fish ]
	then echo -e '\nset fish_greeting' > /mnt/etc/fish/config.fish
fi
echo "#!/bin/sh
	ln -s /usr/bin/doas /usr/local/bin/sudo
	pacman --noconfirm -Rndd sudo > /dev/null

	echo '
Password for root:'
	passwd
	chsh -s /bin/"$_SHELL"
	useradd -m "$_USER"
	echo '
Password for "$_USER"'
	passwd "$_USER"
	usermod -s /bin/"$_SHELL" -aG wheel "$_USER"

	echo '
Uncomment your keyboard locale from the upcoming list...press enter to continue'
	read
	"$_EDITOR" /etc/locale.gen
	locale-gen | awk 'NR==2 {print substr(\$1,1,length(\$1)-3)}' > /etc/locale.conf
	echo LANG=$(cat /etc/locale.conf) > /etc/locale.conf

	grub-install
	echo '
Edit the GRUB configuration if you like...press enter to continue'
	read
	"$_EDITOR" /etc/default/grub
	grub-mkconfig -o /boot/grub/grub.cfg

	pacman-key --init
	pacman-key --populate
	
	pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	pacman-key --lsign-key 3056513887B78AEB
	pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
	echo '
#[chaotic-aur]
#Include = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf

	sed -ie 's/#Parallel/Parallel/g' /etc/pacman.conf
	sed -ie 's/#Color/Color/g' /etc/pacman.conf
	sed -ie 's/#IgnorePkg/IgnorePkg/g' /etc/pacman.conf
	sed -ie 's/#IgnoreGroup/IgnoreGroup/g' /etc/pacman.conf

	echo '
Ready to edit pacman config, optional repos can be enabled at the bottom by uncommenting them...press enter to continue'
	read
	"$_EDITOR" /etc/pacman.conf
 	pacman --noconfirm -Syu > /dev/null

	echo kernel.sysrq=1 > /etc/sysctl.d/kernel.conf
	systemctl enable NetworkManager

	echo '
All done, press enter then Ctrl+D and run command reboot to restart your system'
	read
 	rm setup.sh
	exit
" > /mnt/setup.sh
echo '
Entering system using chroot, please run command sh setup.sh'
arch-chroot /mnt
