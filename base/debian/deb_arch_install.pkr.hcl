// Packer Debian installer specializations for multi-arch

locals {
  // Kudos: https://github.com/GeoffWilliams/packer_images
  deb_boot_keys_efi = join("", [
    "<wait><wait><wait>e<wait><wait><wait>",
    "<down><down><down>",
    "<leftCtrlOn>k<leftCtrlOff><wait>linux ",
  ])
  deb_boot_keys_bios = "<wait><wait><wait><esc><wait><wait><wait>"

  deb_preseed_suffix = "${var.vm_debian_ver}"
  deb_boot_keys = lookup(lookup(local.deb_arch_defs, var.arch, {}), "boot_keys", "")
  deb_install = lookup(lookup(local.deb_arch_defs, var.arch, {}), "boot_dir", "")
  deb_kernel_cmdline = lookup(lookup(local.deb_arch_defs, var.arch, {}), "kernel_cmdline", "")
  deb_part_template = (local.qemu_arch_firmware != "" ? "gpt_efi_root.conf" : "mbr_boot_root.conf")

  deb_boot_commands = [
    "${local.deb_boot_keys}",
    "/${local.deb_install}/vmlinuz ",
    "initrd=/${local.deb_install}/initrd.gz ",
    "auto=true ",
    "url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/base.preseed ",
    "hostname=${var.vm_hostname} domain= ",
    "interface=auto ", local.deb_kernel_cmdline
  ] 

  deb_arch_defs = {
    "x86_64" = {
      boot_dir = "install.amd"
      boot_keys = (local.qemu_arch_firmware != "" ? local.deb_boot_keys_efi : 
        local.deb_boot_keys_bios )
      kernel_cmdline = join("", ["vga=788 noprompt quiet -- ",
        (local.qemu_arch_firmware != "" ? "<f10>" : "<enter>")]),
    }

    "aarch64" = {
      boot_dir = "install.a64"
      boot_keys = local.deb_boot_keys_efi
      kernel_cmdline = " console=tty0 console=ttyS0 -- <f10>",
    }
  }
}
