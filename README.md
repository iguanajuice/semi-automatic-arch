# Usage:

*Disclaimer: This guide is for UEFI only. I also recommend not installing to a disk with important data on it, unless you know what you're doing.*

Locate target disk: `lsblk` *- In this guide we'll use the name `/dev/sda`, be sure to substitute `/dev/sda` with your disk's actual name.*

Partition disk: `cfdisk /dev/sda`

Select option `gpt` if prompted.

Create a partion sized 512m. This will be your `efi` partition. Make note of its name, e.g. `/dev/sda1`.

Change type to "EFI Partition".

Create a second partition at least 50g in size. This will be your `root` partition. Also make note of its name, e.g. `/dev/sda2`.

Select option `write` and enter "yes".

Press 'q' to quit.

Create the filesystem on `efi`: `mkfs.fat /dev/sda1` *- Remember to substitute `/dev/sda` with the partition's actual name.*

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

Mount partitions and subvols:
```
mount -o compress=zstd,subvol=@ /dev/sda2 /mnt
mount -o compress=zstd,subvol=@home /dev/sda2 /mnt/home --mkdir
mount -o compress=zstd,subvol=swap /dev/sda2 /mnt/swap --mkdir
mount /dev/sda1 /mnt/boot/efi --mkdir
```
*Also make use of the 'up' key here.*

Enable swap:
```
btrfs fi m /mnt/swap/swapfile -s 8g
swapon /mnt/swap/swapfile
```
*Note: `-s` sets the size of your swap; it's recommended to have at least as much swap as RAM.*

Verify that swap is working: `free-h`

Download and configure `semi-automatic-arch`:
```
pacman -Sy git
git clone https://github.com/iguanajuice/semi-automatic-arch
cd semi-automatic-arch
nano install.sh
```
Once finsihed with configuration, press `Ctrl+s` and `Ctrl+x` to save and quit, then run `sh install.sh start` to begin installation.
