# VM Framework - Common provisioning scripts

This directory contains several common (but optional) Linux VM provisioning
snippets such as `ssh-authorized-keys`.

The snippets are synced into the base image by default, though they remain
inactive. Thus, you must manually cherry pick and run them inside a VM
provisioning stage.

## Usage

The recommended way to call a script is to symlink them inside an installation
stage dir (e.g., [generic layer's](../../layers/generic/Readme.md)
`install-stage2.d`) inside your preparation script (`vm-prepare.sh`). 

See the [cloud layer's prepare
script](../../layers/cloud/scripts/cloud-prepare.sh) for an example:

