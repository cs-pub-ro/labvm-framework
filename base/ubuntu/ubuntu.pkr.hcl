variables {
  // Note: multi-arch not yet supported for Ubuntu
   = "x86_64"
  vm_hostname = "ubuntu"
  vm_prepare_script = "base-prepare.sh"
  vm_install_base = "base-debian.d/"
  vm_ubuntu_ver = "22"
  vm_ubuntu_kernel_pkg = "linux-image-virtual"
  source_image = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
  source_checksum = "none"
}

source "qemu" "base" {
  // VM Info:
  vm_name       = var.vm_name
  headless      = false

  // Arch-specific qemu config
  qemu_binary  = var.qemu_binary
  machine_type = var.qemu_machine_type
  firmware     = var.qemu_bios
  accelerator  = var.qemu_accelerator
  qemuargs     = concat([], var.qemu_extra_args)
  // Virtual Hardware Specs
  memory         = 2048
  cpus           = 2
  disk_size      = var.disk_size
  disk_interface = "virtio"
  net_device     = "virtio-net"
  // disk usage optimizations (unmap zeroes as free space)
  disk_discard   = (var.qemu_unmap ? "unmap" : "")
  disk_detect_zeroes = (var.qemu_unmap ? "unmap" : "")
  // skip_compaction = true
  
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
    "/meta-data" = "",
    "/user-data" = templatefile("${path.root}/preseed/cloud-config.yaml.pkrtpl", {
      hostname = var.vm_hostname,
      locale = var.vm_locale,
      timezone = var.vm_timezone,
      ssh_username = var.ssh_username,
      ssh_password = var.ssh_password,
      crypted_password = var.vm_crypted_password,
      ubuntu_kernel_pkg = var.vm_ubuntu_kernel_pkg
    })
  }

  boot_wait = (var.use_backing_file ? null : var.boot_wait)
  boot_command = (var.use_backing_file ? null : [
    "c<wait>",
    "linux /casper/vmlinuz autoinstall ds=\"nocloud;s=http://{{.HTTPIP}}:{{.HTTPPort}}/\" ---",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ])
  shutdown_command  = "sudo /sbin/shutdown -h now"
}

