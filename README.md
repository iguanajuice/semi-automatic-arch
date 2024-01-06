**Disclaimer: This guide is for UEFI only. I also recommend not installing to a disk with important data on it, unless you know what you're doing or have a backup.**

*This script has you mount and partition your disks manually. I made it this way, since I never had much luck with `arch-install`'s partitioner, so doing it myself gives me better control and is much more predictable.*

# Installation:

Connect to wifi, if needed: `iwctl station wlan0 connect [your wifi's name here]`

Test internet connection: `ping archlinux.org` *- 'Ctrl+c' to stop pinging*

Locate target disk: `lsblk` *- In this guide we'll use the name `/dev/sda`, be sure to substitute `/dev/sda` with your disk's actual name.*

Partition disk: `cfdisk /dev/sda`

Select option `gpt` if prompted.

Create a partion sized 512m. This will be your `efi` partition. Make note of its name, e.g. `/dev/sda1`.

Change type to "EFI System".

Create a second partition of *at least* 50g, preferably the remaining space. This will be your `root` partition. Also make note of its name, e.g. `/dev/sda2`. Leave its type as default.

Select option `write` and enter "yes".

Press 'q' to quit.

Create the filesystem on `efi`: `mkfs.fat /dev/sda1` *- Remember to substitute `/dev/sda1` with the partition's actual name.*

Create the filesystem on `root`: `mkfs.btrfs -f /dev/sda2` *- It's recommended to use `btrfs` over `ext4`.*

Create the BTRFS subvolumes:
```
mount /dev/sda2 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/swap
umount /mnt
```
*Tip: Press 'up' on your keyboard instead of retyping the same command.*

Mount partitions and subvolumes:
```
mount -o compress=zstd,subvol=@ /dev/sda2 /mnt
mount -o compress=zstd,subvol=@home /dev/sda2 /mnt/home --mkdir
mount -o compress=zstd,subvol=swap /dev/sda2 /mnt/swap --mkdir
mount /dev/sda1 /mnt/boot/efi --mkdir
```

*If mounting subvolumes from a hard drive, add `autodefrag,` before `subvol=`*

*Also make use of the 'up' key here.*

Enable swap:
```
btrfs fi m /mnt/swap/swapfile -s 8g
swapon /mnt/swap/swapfile
```
*Note: `-s` sets the size of your swap; it's recommended to have at least as much swap as RAM.*

Verify that swap is working: `free -h`

Download and configure `semi-automatic-arch`:
```
pacman -Sy git
git clone https://github.com/iguanajuice/semi-automatic-arch
cd semi-automatic-arch
nano install.sh
```
When finsihed with configuration, press `Ctrl+s` to save and `Ctrl+x` to quit, then run `sh install.sh start` to begin installation.

Once the install script is done, run command `reboot` if no errors are shown.

# Where is my user interface?

This script does not install a desktop environment.

If you aren't sure on how to install one, here's how:

*(This will also install a greeter and some basic applications)*

KDE Plasma:
```
sudo pacman -S plasma plasma-wayland-session dolphin gwenview konsole
sudo sed -i 's/Current=/Current=breeze/g' /usr/lib/sddm/sddm.conf.d/default.conf
sudo systemctl enable --now sddm
```
GNOME: 
```
sudo pamcan -S gnome
sudo systemctl enable --now gdm
```
GNOME w/extras: 
```
sudo pamcan -S gnome gnome-extras
sudo systemctl enable --now gdm
```
Cinnamon:
```
sudo pacman -S cinnamon eog nemo-fileroller gnome-terminal mint-themes mint-y-icons lightdm-slick-greeter
sudo sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter' /etc/lightdm/lightdm.conf
sudo systemctl enable --now lightdm
```
MATE:
```
sudo pacman -S mate mate-extra lightdm-gtk-greeter
sudo systemctl enable --now lightdm
```
XFCE:
```
sudo pacman -S xfce4 xfce4-goodies lightdm-gtk-greeter
sudo systemctl enable --now lightdm
```
After installing your DE of choice, run:
```
sudo pacman -S xdg-user-dirs
xdg-user-dirs-update
```
...to create your user directories.

If using Cinnamon, MATE, or XFCE; also run:
```
mkdir ~/.config/gtk-3.0
echo 'file:///home/lel/Documents Documents
file:///home/lel/Downloads Downloads
file:///home/lel/Music Music
file:///home/lel/Pictures Pictures
file:///home/lel/Videos Videos' > ~/.config/gtk-3.0/bookmarks
```
...to create the shortcuts in your file manager's side pane.

# Make your system bullet proof:

Since we're using `btrfs` as our filesystem, we can easily make snapshots of the system using `timeshift`, then boot into those snapshots directly using `grub-btrfs`. This way, even if the system breaks to the point it's unbootable, we can still restore from a working snapshot.

Here's how to set it up:

Install the required packages: `sudo pacman -S timeshift grub-btrfs inotify-tools xorg-xhost`

Launch and setup Timeshift from your menu or app launcher, or run command `sudo timeshift-launcher`.

Edit `grub-btrfsd.service`:
```
EDITOR=your_editor_of_choice su
systemctl edit --full grub-btrfsd
```
Replace `--syslog /.snapshots` with `-t`

Save and quit.

Enable the service: `systemctl enable --now grub-btrfsd`

Sanity check: `systemctl status grub-btrfsd`

`Ctrl+d` to exit `su`.

# Nvidia:

Linux comes with an in-kernel graphics driver for nvidia called `nouveau`. While this works fine for basic usage, performance for games is lackluster; so it's recommended to install the proprietery drivers for gaming: https://wiki.archlinux.org/title/NVIDIA

# Closing notes:

Even with everything in this guide and all the creature comforts the script installs for you, Arch is still very barebones; you'll be missing quite a bit of stuff, such as:

* A web browser (firefox, chromium)
* A media player (vlc, mpv, celluloid)
* A graphical text editor (gedit, kate)
* A games launcher (steam, lutris)
* A software center (gnome-software, pamac-nosnap)

Check out the official Arch wiki for more info and helpful guides: https://wiki.archlinux.org/
