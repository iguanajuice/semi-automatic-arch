#!/bin/sh

HAVEREAD=0 # Set this to 1 if you have read this script

if [ $HAVEREAD = 0 ]
	then echo Please read through \`semi-automatic-arch/install.sh\` and configure it where necessary
	exit
fi

USER=user        # Name of auto-generated user
EDITOR=micro     # micro > nano :)
SHELL=fish       # Set default interactive shell, does NOT change system shell
KERNEL=linux     # Pick which Linux kernel you want: linux, linux-lts, linux-zen, linux-rt linux-rt-lts
UCODE=           # Set to either amd-ucode or intel-ucode or leave blank if using neither
LIBVA=mesa       # Driver for hardware video encoding/decoding using your GPU: Radeon=mesa, Intel=intel, Nvidia=vdpau

echo ParrelelDownloads = 5 >> /etc/nano.conf # haha package download go brrrrr
pacstrap -K /mnt base base-devel $KERNEL $KERNEL-headers $UCODE doas $EDITOR \ # Core packages
	git wget htop neofetch man-db usbutils \                               # Miscellaneous CLI tools
	lvm2 ntfs-3g \                                                         # Support additional filesystem types
	networkmanager net-tools wireless_tools \                              # Networking packages
	wireplumber pipewire-pulse pipewire-jack \                             # Audio packages
	libva-$LIBVA-driver gstreamer-vaapi                                    # Hardware video codecs

genfstab -U /mnt > /mnt/etc/fstab
if [ $SHELL = fish ]
	then echo -e '\nset fish_greeting'
fi
echo "#!/bin/sh
	ln -s /usr/bin/doas /usr/local/bin/sudo
	pacman --noconfirm -Rndd sudo > /dev/null

	echo Password for root:
	passwd
	chsh -s /bin/"$SHELL"
	useradd -m "$USER"
	echo Password for "$USER"
	passwd "$USER"
	usermod -s /bin/"$SHELL" -aG wheel "$USER"

	echo Uncomment your keyboard locale from the upcoming list...press enter to continue
	read
	"$EDITOR" /etc/locale.gen
	locale-gen | awk 'NR==2 {print substr($1,1,length($1)-3)}' > /etc/locale.conf
	echo LANG=$(cat /etc/locale.conf) > /etc/locale.conf

	grub-install
	echo Edit GRUB's configuration if you like...press enter to continue
	read
	"$EDITOR" /etc/default/grub
	grub-mkconfig -o /boot/grub/grub.cfg

	pacman-key --init
	pacman-key --populate
	
	pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	pacman-key --lsign-key 3056513887B78AEB
	pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
	echo '
	#[chaotic-aur]
	#Include = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
 	pacman --noconfirm -Syu > /dev/null
	
	sed -ei 's/#Parallel/Parallel/g' /etc/pacman.conf
	sed -ei 's/#Color/Color/g' /etc/pacman.conf
	sed -ei 's/#IgnorePkg/IgnorePkg/g' /etc/pacman.conf
	sed -ei 's/#IgnoreGroup/IgnoreGroup/g' /etc/pacman.conf

	echo About to edit pacman config, optional repos can be enabled at the bottom by uncommenting them...press enter to continue
	read
	"$EDITOR" /etc/pacman.conf

	echo kernel.sysrq=1 > /etc/sysctl.d/kernel.conf
	systemctl enable NetworkManager

	echo All done, press enter and run command \`reboot\` to restart your system'
	read
	exit
" > /mnt/tmp/setup.sh
echo About to enter system using chroot, press enter and run command \`sh /tmp/setup.sh\`
arch-chroot /mnt
