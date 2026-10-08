#!/bin/bash
# Arch Linux unattended installer
set -euxo pipefail

# guard: the boot command types the install twice (getty timing race)
exec 9>/root/.install.lock
flock -n 9 || { echo ">>> install already running, skipping"; exit 0; }

DISK=/dev/vda
TARGET=/mnt
ROOT_PART="" EFI_PART=""
if [[ "${USE_EFI}" == "true" ]]; then
	ROOT_PART="${DISK}2"
	EFI_PART="${DISK}1"
else
	ROOT_PART="${DISK}1"
fi

echo ">>> [1/5] wiping & partitioning ${DISK}"
sgdisk --zap "${DISK}"
wipefs --all "${DISK}"
if [[ -n "${EFI_PART}" ]]; then
	sgdisk --new=1:1:300M "${DISK}" --type=1:EF00
	sgdisk --new=2:0:0 "${DISK}" --type=2:8300
else
	parted --script "${DISK}" \
    	mklabel msdos \
    	mkpart primary 1MiB 100% \
		set 1 boot on
fi

echo ">>> [2/5] filesystems"
mkfs.ext4 -F -m 0 -L root "${ROOT_PART}"
mount -o noatime,errors=remount-ro "${ROOT_PART}" "${TARGET}"
if [[ -n "${EFI_PART}" ]]; then
	mkfs.fat -F 32 -n BOOT "${EFI_PART}"
	mkdir -p "${TARGET}/boot/efi"
	mount "${EFI_PART}" "${TARGET}/boot/efi"
fi

echo ">>> [3/5] pacstrap base system"
pacstrap_args=(base linux grub openssh sudo)
pacstrap -K "${TARGET}" "${pacstrap_args[@]}"
genfstab -p "${TARGET}" >> "${TARGET}/etc/fstab"

echo ">>> [4/5] configure system (chroot)"
cat << EOF > "${TARGET}/usr/local/bin/arch-config.sh"
#!/bin/bash
set -euxo pipefail

# hostname / timezone / locale
echo "$VM_HOSTNAME" > /etc/hostname
ln -sf "/usr/share/zoneinfo/$VM_TIMEZONE" /etc/localtime
echo "KEYMAP=us" > /etc/vconsole.conf
sed -i "s|^#\?$VM_LOCALE UTF-8|$VM_LOCALE UTF-8|" /etc/locale.gen
locale-gen

# passwords & users (single-quoted: the hash contains $ chars)
usermod -p '$VM_CRYPTED_PASSWORD' root
useradd -m -s /bin/bash -G wheel "$VM_USER"
usermod -p '$VM_CRYPTED_PASSWORD' "$VM_USER"
echo "$VM_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$VM_USER"
chmod 0440 "/etc/sudoers.d/$VM_USER"

# services (network + ssh)
echo "UseDNS no" >> /etc/ssh/sshd_config
systemctl enable sshd systemd-networkd systemd-resolved

# kernel cmdline (matches common-snippets.d/kernel-cmdline defaults)
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT='console=tty0 console=ttyS0,115200n8 no_timer_check edd=off'|" /etc/default/grub

# initramfs
mkinitcpio -p linux
EOF
chmod 0755 "${TARGET}/usr/local/bin/arch-config.sh"
arch-chroot "${TARGET}" /usr/local/bin/arch-config.sh 2>&1 | tee /root/config.log
cat << EOF > "${TARGET}/etc/systemd/network/20-ethernet.network"
[Match]
Type=ether

[Network]
DHCP=yes
EOF

rm "${TARGET}/usr/local/bin/arch-config.sh"
echo ">>> post-chroot shadow check"; grep -E '^(root|student)' "${TARGET}/etc/shadow" | cut -c1-45

# install & configure the bootloader
GRUB_DEV_ARGS=()
if [[ "${USE_EFI}" == "true" ]]; then
	[[ "${ARCH}" == "aarch64" ]] && GRUB_TARGET=arm64-efi || GRUB_TARGET=x86_64-efi
	GRUB_DEV_ARGS=(--efi-directory=/boot/efi --bootloader-id=GRUB)
else
	GRUB_TARGET=i386-pc
	GRUB_DEV_ARGS=("$DISK")
fi
arch-chroot "${TARGET}" grub-install --target="${GRUB_TARGET}" "${GRUB_DEV_ARGS[@]}" --recheck
arch-chroot "${TARGET}" grub-mkconfig -o /boot/grub/grub.cfg

echo ">>> [5/5] rebooting into the installed system"
umount -R "${TARGET}"
systemctl reboot

