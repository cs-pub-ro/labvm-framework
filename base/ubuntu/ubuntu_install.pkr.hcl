// Packer Ubuntu installer specializations for multi-arch

locals {
  ubuntu_boot_keys_efi = join("", [
    "c<wait>",
  ])
  ubuntu_boot_keys_bios = join("", [
    "c<wait>",
  ])

  ubuntu_preseed_suffix = "${var.vm_ubuntu_ver}"
  ubuntu_boot_keys = lookup(lookup(local.ubuntu_arch_defs, var.arch, {}), "boot_keys", "")
  ubuntu_kernel_cmdline = lookup(lookup(local.ubuntu_arch_defs, var.arch, {}), "kernel_cmdline", "")
  ubuntu_part_template = (local.qemu_arch_firmware != "" ? "gpt_efi_root.conf" : "mbr_boot_root.conf")

  ubuntu_boot_commands = [
    "${local.ubuntu_boot_keys}",
    "linux /casper/vmlinuz ",
    "autoinstall ds=\"nocloud;s=http://{{.HTTPIP}}:{{.HTTPPort}}/\" ",
    local.ubuntu_kernel_cmdline,
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot<enter>",
  ] 

  ubuntu_arch_defs = {
    "x86_64" = {
      boot_keys = (local.qemu_arch_firmware != "" ? local.ubuntu_boot_keys_efi : 
        local.ubuntu_boot_keys_bios )
      kernel_cmdline = " --- "
    }

    "aarch64" = {
      boot_keys = local.ubuntu_boot_keys_efi
      kernel_cmdline = " console=tty0 console=ttyS0 -- <f10>",
    }
  }
}
