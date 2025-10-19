variables {
  vm_hostname = "debian"
  vm_prepare_script = "base-prepare.sh"
  vm_install_base = "base-debian.d/"
  vm_debian_ver = "13"
  vm_send_boot_keys = true
  source_image = "https://cdimage.debian.org/debian-cd/12.9.0/amd64/iso-cd/debian-12.9.0-amd64-netinst.iso"
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
    "/base.preseed" = templatefile(
        "${path.root}/preseed/debian_${local.deb_preseed_suffix}.pkrtpl", {
        var=var, local=local,
        partman_recipe = file("${path.root}/preseed/snippets/${local.deb_part_template}"),
      })
  }

  boot_wait = (var.use_backing_file ? null : var.boot_wait)
  boot_command = ((var.use_backing_file && var.vm_send_boot_keys) ? null :
    local.deb_boot_commands)
  shutdown_command  = "sudo /sbin/shutdown -h now"
}

