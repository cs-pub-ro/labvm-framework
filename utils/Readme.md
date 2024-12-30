# VM Framework host utilities

This directory contains a couple of utility scripts designed to be ran on the
development machine.

List of scripts and their purpose:

- `zerofree.sh`: uses qemu-nbd to mount the root partition of a virtual disk,
  zeroes all free space then copies the image, thus "compressing it": minimizing
  space taken on the host; requires `root` privileges!

