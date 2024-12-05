# Makefile templates to generate VMware project files

## <vm>-specific (placeholder for VM's ID + goal) variables and their defaults
-vmware-name = $(call _def_value,$(vm)-vmname,$(-vm-name))
-vmware-ostype = $(call _def_value,$(vm)-ostype,ubuntu-64)
-vmware-ramsize = $(call _def_value,$(vm)-ramsize,2048)
-vmware-vcpus = $(call _def_value,$(vm)-vcpus,2)
-vmware-ssh-nat = $(call _def_value,$(vm)-vmware-ssh-nat,10022)
# <vm>-src-image: take source image from another file (when ! <vm>-source-from)
-vmware-src-vmdk = $(strip $(if $(-vm-source-from),\
			$(let vm,$(-vm-source-from),$($(vm)-vmdk-file)),\
			$(call _def_value,$(vm)-src-image,$(vm).vmdk)))

define vmware-prj-template=
#!/usr/bin/vmware
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "20"
pciBridge0.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge4.functions = "8"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge5.functions = "8"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge6.functions = "8"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"
vmci0.present = "TRUE"
hpet0.present = "TRUE"
nvram = "$(-vm-name).nvram"
virtualHW.productCompatibility = "hosted"
gui.exitOnCLIHLT = "FALSE"
powerType.powerOff = "soft"
powerType.powerOn = "soft"
powerType.suspend = "soft"
powerType.reset = "soft"
displayName = "$(-vmware-name)"
guestOS = "$(-vmware-ostype)"
tools.syncTime = "FALSE"
sound.autoDetect = "TRUE"
sound.present = "FALSE"
sound.startConnected = "FALSE"
numvcpus = "$(-vmware-vcpus)"
cpuid.coresPerSocket = "1"
vcpu.hotadd = "TRUE"
memsize = "$(-vmware-ramsize)"
mem.hotadd = "TRUE"
scsi0.virtualDev = "lsilogic"
scsi0.present = "TRUE"
scsi0:0.fileName = "$(notdir $($(vm)-vmware-dest-vmdk))"
scsi0:0.present = "TRUE"
sata0.present = "TRUE"
sata0:1.deviceType = "cdrom-raw"
sata0:1.fileName = "auto detect"
sata0:1.present = "FALSE"
usb.present = "TRUE"
usb.vbluetooth.startConnected = "FALSE"
usb:0.present = "TRUE"
usb:0.deviceType = "hid"
usb:0.port = "0"
usb:0.parent = "-1"
usb:1.speed = "2"
usb:1.present = "TRUE"
usb:1.deviceType = "hub"
usb:1.port = "1"
usb:1.parent = "-1"
svga.graphicsMemoryKB = "8388608"
ethernet0.connectionType = "nat"
ethernet0.addressType = "generated"
ethernet0.virtualDev = "e1000"
ethernet0.present = "TRUE"
floppy0.present = "FALSE"
vhv.enable = "FALSE"
ehci.present = "TRUE"
endef

define vm_gen_vmware_prj_rule=
$(vm)-vmx-prj := $(-vm-dest-dir)/$(-vm-name).vmx
$$($(vm)-vmx-prj):
	mkdir -p "$(-vm-dest-dir)"
	echo "$$$$$(call normalize_id,_VM_VMWARE_DATA__$(vm))" > "$$@"

export $(call normalize_id,_VM_VMWARE_DATA__$(vm)):=$$(vmware-prj-template)

endef

define vm_gen_vmware_rules=
.PHONY: $(vm) $(vm)_clean
#@ $(vm) VMware project build goal
$(vm)-vmware-dest-vmdk := $(-vm-dest-dir)/$(-vm-name).vmdk
$$($(vm)-vmware-dest-vmdk): $(-vmware-src-vmdk)
	mkdir -p "$(-vm-dest-dir)"
	cp -f "$$<" "$$@"
$(vm_gen_vmware_prj_rule)
$(vm): $$($(vm)-vmware-dest-vmdk) $$($(vm)-vmx-prj)

$(vm)_clean:
	rm -rf "$(-vm-dest-dir)"

endef

