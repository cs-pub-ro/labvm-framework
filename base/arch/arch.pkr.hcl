variables {
  vm_hostname = "arch"
  vm_prepare_script = ""
  vm_install_base = "base-arch.d/"
  vm_send_boot_keys = true
  source_image = "https://mirrors.kernel.org/archlinux/iso/latest/archlinux-x86_64.iso"
  source_checksum = "none"
}

source "qemu" "base" {
  // VM Info:
  vm_name       = var.vm_name
  headless      = false

  // Arch-specific qemu config
  qemu_binary  = local.qemu_arch_binary
  machine_type = local.qemu_arch_machine_type
  firmware     = local.qemu_arch_firmware
  accelerator  = local.qemu_arch_accelerator
  qemuargs     = local.qemu_arch_qemuargs
  // Virtual Hardware Specs
  memory         = 2048
  cpus           = 2
  disk_size      = var.disk_size
  disk_interface = "virtio"
  net_device     = "virtio-net"
  // disk usage optimizations (unmap zeroes as free space)
  disk_discard   = (var.qemu_unmap ? "unmap" : "")
  disk_detect_zeroes = (var.qemu_unmap ? "unmap" : "")

  // ISO & Output details
  iso_url           = var.source_image
  iso_checksum      = var.source_checksum
  disk_image        = var.use_backing_file
  use_backing_file  = var.use_backing_file
  output_directory  = var.output_directory

  ssh_username      = var.ssh_username
  ssh_password      = var.ssh_password
  ssh_timeout       = "30m"
  host_port_min     = var.qemu_ssh_forward
  host_port_max     = var.qemu_ssh_forward

  http_content = {
    "/arch-install.sh" = file("${path.root}/arch-install.sh")
    "/b.sh" = templatefile("${path.root}/bootstrap.sh.pkrtpl", {
      var=var, local=local, arch=var.arch, build=build,
      packer_http="http://{{ .HTTPIP }}:{{ .HTTPPort }}",
      use_efi=(local.qemu_arch_firmware != ""),
    })
  }

  boot_wait = (var.use_backing_file ? null : var.boot_wait)
  boot_command = ((var.use_backing_file && var.vm_send_boot_keys) ? null :
    local.arch_boot_commands)
  shutdown_command  = "sudo /sbin/shutdown -h now"
}

// Arch ISO boots to a root shell on tty1 (BIOS & EFI), where curl is
// available - we download & run the installer from Packer's HTTP server
locals {
  // The ISO's kernel line has no console param, so we add both:
  //  - console=tty0       -> VNC-typed keys reach the tty1 getty
  //  - console=ttyS0      -> debug/observable serial console
  // The live ISO boots to a getty login (root, no password).
  arch_boot_commands = [
    "<wait><wait><wait><tab> console=tty0 console=ttyS0,115200n8<enter>",
    "<wait10><wait10><wait10>",
    "U=http://{{ .HTTPIP }}:{{ .HTTPPort }};curl -sL \"$U/b.sh\" | bash -sx -- \"$U\"<enter>",
  ]
}
