#!/bin/bash
# VM Disk Compaction utility.
# Fills out the empty disk space with zeroes to minimize VM image size.

QEMU_NBD_DEV=nbd0
MOUNTPOINT=/tmp/vm-framework-zerofree
WAIT_SEC=${WAIT_SEC:-'5'}

if ! lsmod | grep -wq "nbd"; then
	modprobe nbd max_part=8 || exit 1
	# wait for the module to initialize (yep, ugly hack)
	sleep "$WAIT_SEC"
fi

mkdir -p "$MOUNTPOINT"

exit_fail() {
	set +x
	mountpoint -q "$MOUNTPOINT" && umount "$MOUNTPOINT" || true
	qemu-nbd -d "/dev/${QEMU_NBD_DEV}"
	exit 3
}

qemu-nbd -c "/dev/$QEMU_NBD_DEV" "$1"  || exit 2
sleep "$WAIT_SEC"
mount "/dev/${QEMU_NBD_DEV}p2" "$MOUNTPOINT" || exit_fail
e4defrag "$MOUNTPOINT" > /dev/null
if command -v zerofree &> /dev/null; then
	# use zerofree, it's much more thorough than creating a file
	# occupying 100% of free space
	mountpoint -q "$MOUNTPOINT" && umount "$MOUNTPOINT" || true
	zerofree "/dev/${QEMU_NBD_DEV}p2" || exit_fail
else
	mountpoint -q "$MOUNTPOINT" || exit_fail
	dd if=/dev/zero of="$MOUNTPOINT/.zerofile" bs=1M || true
	rm -f "$MOUNTPOINT/.zerofile" || true
fi

mountpoint -q "$MOUNTPOINT" && umount "$MOUNTPOINT" || true
qemu-nbd -d "/dev/${QEMU_NBD_DEV}"

qemu-img convert -O qcow2 "$1" "$1_tmp.qcow2" && {
	rm -f "$1" && mv "$1_tmp.qcow2" "$1"
}

