packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variables {
  vm_name = "PackerVM"
  vm_pause = 0
  vm_debug = 0
  vm_noinstall = 0
  vm_scripts_dir = "scripts/"
  vm_prepare_script = "vm-prepare.sh"
  vm_install_stage1 = "install-stage1.d/"
  vm_install_stage2 = "install-stage2.d/"
  vm_authorized_keys = ""
  qemu_unmap = false
  qemu_ssh_forward = 20022
  disk_size = 8192
  source_image = "./path/to/base-vm.qcow2"
  source_checksum = "none"
  use_backing_file = true
  output_directory = "/tmp/packer-out"
  ssh_username = "TODO"
  ssh_password = "TODO"
}
variable "vm_scripts_list" {
  type    = list(string)
  default = []
}

locals {
  scripts_dir = "/opt/vm-scripts"
  envs = [
    "DEBUG=${var.vm_debug}", "VM_DEBUG=${var.vm_debug}",
    "VM_SCRIPTS_DIR=${local.scripts_dir}",
    "VM_AUTHORIZED_KEYS=${basename(var.vm_authorized_keys)}"
  ]
  sudo = "{{.Vars}} sudo -E -S bash -e '{{.Path}}'"
  provision_init = "set -e; source $VM_SCRIPTS_DIR/lib/base.sh; @import 'vmrunner';"
}

source "qemu" "vm" {
  // VM Info:
  vm_name       = var.vm_name
  headless      = false

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

  shutdown_command  = "sudo /sbin/shutdown -h now"
}

build {
  sources = ["sources.qemu.vm"]

  provisioner "shell" {
    inline = [
      "mkdir -p $VM_SCRIPTS_DIR",
      "chown ${var.ssh_username}:${var.ssh_username} $VM_SCRIPTS_DIR -R"
    ]
    execute_command = local.sudo
    environment_vars = local.envs
  }
  provisioner "file" {
    sources = concat(
      (var.vm_scripts_dir != "" ? [var.vm_scripts_dir] : var.vm_scripts_list),
      (var.vm_authorized_keys == "" ? [] : ["${var.vm_authorized_keys}"]),
    )
    destination = "${local.scripts_dir}/"
  }

  # default VM build pipeline: prepare, stage1, optionally reboot, finally stage2
  provisioner "shell" {
    # run the preparation script (if any)
    inline = [
      "${local.provision_init}",
      "[[ -n '${var.vm_prepare_script}' ]] || { sh_log_info 'SKIP prepare script!'; exit 0; }",
      "vm_run_script \"${var.vm_prepare_script}\""
    ]
    expect_disconnect = true
    execute_command = local.sudo
    environment_vars = local.envs
  }
  provisioner "shell" {
    # run the first stage scripts (where a reboot is properly expected)
    inline = [
      "${local.provision_init}",
      "[[ -n '${var.vm_install_stage1}' ]] || { sh_log_info 'SKIP stage 1!'; exit 0; }",
      "vm_run_scripts \"${var.vm_install_stage1}\""
    ]
    expect_disconnect = true
    execute_command = local.sudo
    environment_vars = local.envs
  }
  provisioner "shell" {
    # run the second stage scripts
    inline = [
      "${local.provision_init}",
      "[[ -n '${var.vm_install_stage2}' ]] || { sh_log_info 'SKIP stage 2!'; exit 0; }",
      "vm_run_scripts \"${var.vm_install_stage2}\""
    ]
    execute_command = local.sudo
    environment_vars = local.envs
  }

  # optionally, when PAUSE=1, keep the qemu VM open!
  provisioner "breakpoint" {
    disable = (var.vm_pause == 0)
    note    = "this is a breakpoint"
  }
}

