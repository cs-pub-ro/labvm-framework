packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variables {
  vm_name = "basevm"
  vm_locale = "en_US"
  vm_timezone = "Europe/Bucharest"
  vm_crypted_password = "TODO"
  vm_pause = 0
  vm_debug = 0
  vm_scripts_dir = "scripts/"
  qemu_ssh_forward = 20022
  disk_size = 8192
  use_backing_file = false
  output_directory = "/tmp/packer-out"
  boot_wait = "5s"
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
  ]
  sudo = "{{.Vars}} sudo -E -S bash -e '{{.Path}}'"
  provision_init = "set -e; source $VM_SCRIPTS_DIR/lib/base.sh; @import 'vmrunner';"
}


build {
  sources = ["sources.qemu.base"]

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
    )
    destination = "${local.scripts_dir}/"
  }

  provisioner "shell" {
    # run the base preparation script (if any)
    inline = [
      "${local.provision_init}",
      "vm_run_script --optional \"${var.vm_prepare_script}\""
    ]
    expect_disconnect = true
    execute_command = local.sudo
    environment_vars = local.envs
  }
  provisioner "shell" {
    # run the base provisioning scripts
    inline = [
      "${local.provision_init}",
      "vm_run_scripts --optional \"${var.vm_install_base}\""
    ]
    expect_disconnect = true
    execute_command = local.sudo
    environment_vars = local.envs
  }

  provisioner "breakpoint" {
    disable = (var.vm_pause == 0)
    note    = "this is a breakpoint"
  }
}

