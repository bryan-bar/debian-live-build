#!/bin/bash
set -eou
[ "${DEBUG:=false}" == 'true' ] && set -x && exec 6>&1 && exec 1>&2

# when using containers,
# access to chroot is needed
# this usually means --priviledged option or specifying SYS_CHROOT permissions

SOURCE_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
TEMP_DIR="/tmp/live-build-debian"
ISO_NAME="live-image-amd64.hybrid.iso"
DEBIAN_FRONTEND=noninteractive

apt-get clean
apt-get update
apt-get install --yes live-build

mkdir "$TEMP_DIR"
cd "$TEMP_DIR"

lb clean --purge
lb config \
	--distribution bookworm \
	--architectures amd64 \
	--binary-images iso-hybrid \
	--iso-volume "Debian Bookworm ZFS" \
	--archive-areas "main contrib non-free non-free-firmware" \
	--linux-packages "linux-image linux-headers" \
	--backports true \
	--bootappend-live "boot=live nomodeset toram" \
	--memtest "memtest86+" \
	--bootloaders "grub-efi" \
	--security true \
	--updates true \
	--debian-installer "live" \
	--debian-installer-gui true \
	--bootappend-install "nomodeset" \
	--win32-loader false

# Copy configuration files
cp "$SOURCE_DIR/packages.list.chroot" "config/package-lists/"
cp "$SOURCE_DIR/1000-zfs.hook.chroot" "config/hooks/live/"
cp "$SOURCE_DIR/1001-ddrescue.hook.chroot" "config/hooks/live/"
cp "$SOURCE_DIR/1002-tools.hook.chroot" "config/hooks/live/"
cp "$SOURCE_DIR/1003-monitor.hook.chroot" "config/hooks/live/"

# lb build - wget randomly fails to fetch deb.debian.org
# It might be related to a disconnect setting which forces a new connection after 100 connections, which wget respects
#
# Manually calling each step seems to help
# Not sure if it is the cacheing or wget resetting its connections
# I have <100 packages, so I might just be lucky to face it less when splitting the steps up

lb bootstrap --verbose
lb chroot --verbose
lb installer --verbose
lb binary --verbose
lb source --verbose
mv "${ISO_NAME}" "${SOURCE_DIR}"
lb clean --purge
cd "${SOURCE_DIR}"
rm -r "${TEMP_DIR}"

[ "${DEBUG:=false}" == 'true' ] && exec 1>&6 && exec 6>&-

# return success output as the last line
printf "\n%s\n" "$SOURCE_DIR/$ISO_NAME" 

