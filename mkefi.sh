#! /bin/sh

findmods=$(find ./grub-core -name '*\.mod' -printf '%f ' | sed 's/\.mod / /g')
#echo "findmods [$findmods]"
#./grub-mkimage -O x86_64-efi -d ./grub-core -o bootx64.efi -p "" $findmods
./grub-mkimage -O x86_64-efi -d ./grub-core -o grubx64.efi -p "" part_gpt part_msdos ntfs ntfscomp hfsplus fat ext2 normal chain boot configfile linux multiboot serial