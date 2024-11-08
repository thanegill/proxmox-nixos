{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkOption types;

  typeVlan = types.ints.between 1 4094;

  typeMacAddress = types.strMatching "/^(?:[[:xdigit:]]{2}([:]))(?:[[:xdigit:]]{2}\1){4}[[:xdigit:]]{2}$/";

  typeListOfMaxLength = maxLength: elemType: types.addCheck (types.listOf elemType) (l: builtins.length l <= maxLength);

  mkNullDefaultOption = type: description: mkOption {
    inherit description;
    type = types.nullOr type;
    default = null;
  };

  mkNullDefaultBoolOption = mkNullDefaultOption types.bool;

  mkNullDefaultStrOption = mkNullDefaultOption types.str;

  mkNullDefaultUnsignedOption = mkNullDefaultOption types.ints.unsigned;

  mkNullDefaultEnumOption = description: enum: mkNullDefaultOption (types.enum enum) description;

  mkRateOption = mkNullDefaultOption (types.strMatching "[0-9]+(K|M|G)");

  mkSizeOption = mkNullDefaultOption (types.strMatching "[0-9]+(K|M|G)(iB)?");

  commonVolumeOptions = {
    options = {
      file = mkOption {
        type = types.str;
        description = "The volume file.";
        example = "/path/to/volume.img";
      };
      aio = mkNullDefaultEnumOption "Asynchronous I/O mode." [
        "native"
        "threads"
        "io_uring"
      ];
      backup = mkNullDefaultBoolOption "Whether to backup.";
      bps = mkRateOption "Bytes per second rate." // {
        example = "10M";
      };
      bps_max_length = mkNullDefaultUnsignedOption "Maximum length in seconds for BPS." // {
        example = 60;
      };
      bps_rd = mkRateOption "Read BPS rate." // {
        example = "5M";
      };
      bps_rd_max_length = mkNullDefaultUnsignedOption "Maximum length in seconds for read BPS." // {
        example = 30;
      };
      bps_wr = mkRateOption "Write BPS rate." // {
        example = "5M";
      };
      bps_wr_max_length = mkNullDefaultUnsignedOption "Maximum length in seconds for write BPS." // {
        example = 30;
      };
      cache = mkNullDefaultEnumOption "Cache mode." [
        "directsync"
        "none"
        "unsafe"
        "writeback"
        "writethrough"
      ];
      cyls = mkNullDefaultUnsignedOption "Number of cylinders." // {
        example = 1024;
      };
      detect_zeroes = mkNullDefaultBoolOption "Whether to detect zeroes.";
      discard = mkNullDefaultEnumOption "Discard mode." [ "ignore" "on" ];
      format = mkNullDefaultEnumOption "Disk format." [
        "cloop"
        "cow"
        "qcow"
        "qcow2"
        "qed"
        "raw"
        "vmdk"
      ];
      heads = mkNullDefaultUnsignedOption "Number of disk heads." // {
        example = 16;
      };
      import-from = mkNullDefaultOption types.path "Source volume to import from." // {
        example = "/path/to/source-volume.img";
      };
      iops = mkRateOption "IO operations per second rate." // {
        example = "1000";
      };
      iops_max = mkNullDefaultUnsignedOption "Maximum IOPS rate." // {
        example = 2000;
      };
      iops_max_length = mkNullDefaultUnsignedOption "Maximum length in seconds for IOPS." // {
        example = 60;
      };
      iops_rd = mkNullDefaultUnsignedOption "Read IOPS rate." // {
        example = 500;
      };
      iops_rd_max = mkNullDefaultUnsignedOption "Maximum read IOPS rate." // {
        example = 1000;
      };
      iops_rd_max_length = mkNullDefaultUnsignedOption "Maximum length in seconds for read IOPS." // {
        example = 30;
      };
      iops_wr = mkNullDefaultUnsignedOption "Write IOPS rate." // {
        example = 500;
      };
      iops_wr_max = mkNullDefaultUnsignedOption "Maximum write IOPS rate." // {
        example = 1000;
      };
      iops_wr_max_length = mkNullDefaultUnsignedOption "Maximum length in seconds for write IOPS." // {
        example = 30;
      };
      mbps = mkRateOption "Megabytes per second rate." // {
        example = "10M";
      };
      mbps_max = mkRateOption "Maximum MBPS rate." // {
        example = "20M";
      };
      mbps_rd = mkRateOption "Read MBPS rate." // {
        example = "5M";
      };
      mbps_rd_max = mkRateOption "Maximum read MBPS rate." // {
        example = "10M";
      };
      mbps_wr = mkRateOption "Write MBPS rate." // {
        example = "5M";
      };
      mbps_wr_max = mkRateOption "Maximum write MBPS rate." // {
        example = "10M";
      };
      media = mkNullDefaultEnumOption "Media type." [ "cdrom" "disk" ];
      model = mkNullDefaultStrOption "Model name." // {
        example = "virtio";
      };
      replicate = mkNullDefaultBoolOption "Whether to replicate.";
      rerror = mkNullDefaultStrOption "Read error handling." // {
        example = "report";
      };
      secs = mkNullDefaultUnsignedOption "Number of seconds." // {
        example = 120;
      };
      serial = mkNullDefaultStrOption "Serial number." // {
        example = "123456789";
      };
      shared = mkNullDefaultBoolOption "Whether the volume is shared.";
      size = mkNullDefaultOption (types.strMatching "[0-9]+(K|M|G)") // {
        example = "10G";
      };
      snapshot = mkNullDefaultBoolOption "Whether to enable snapshots.";
      ssd = mkNullDefaultBoolOption "Whether the disk is SSD.";
      trans = mkNullDefaultEnumOption "Translation mode." [ "auto" "lba" "none" ];
      werror = mkNullDefaultEnumOption "Write error handling." [
        "enospc"
        "ignore"
        "report"
        "stop"
      ];
      wwn = mkNullDefaultStrOption "World Wide Name (WWN)." // {
        example = "12345678-1234-1234-1234-1234567890ab";
      };
    };
  };
in

{
  meta.maintainers = with lib.maintainers; [
    julienmalka
    camillemndn
  ];

  options = {
    vmid = mkNullDefaultOption (types.ints.between 100 999999999) "The (unique) ID of the VM.";

    # Options below are from https://pve.vanguard.vashonsd.org/pve-docs/chapter-qm.html#qm_options
    acpi = mkNullDefaultBoolOption "Enable/disable ACPI.";

    affinity = mkNullDefaultStrOption "List of host cores used to execute guest processes." // {
      example = "0,5,8-11";
    };

    agent = mkOption {
      description = "Enable/disable communication with the QEMU Guest Agent and its properties.";
      default = null;
      type = types.nullOr (types.submodule {
        options = {
          enabled = mkEnableOption "Enable or disable communication with the QEMU Guest Agent.";
          freeze_fs_on_backup = mkNullDefaultBoolOption "Freeze file systems on backup.";
          fstrim_cloned_disks = mkNullDefaultBoolOption "Enable or disable fstrim on cloned disks.";
          type = mkNullDefaultEnumOption "Specify the type of QEMU Guest Agent device." [ "virtio" "isa" ];
        };
      });
    };

    arch = mkNullDefaultEnumOption "Virtual processor architecture. Defaults to the host." [ "x86_64" "aarch64" ];

    archive = mkNullDefaultStrOption "The backup archive. Either the file system path to a .tar or .vma file or a proxmox storage backup volume identifier.";

    args = mkNullDefaultStrOption "Arbitrary arguments passed to kvm. This option is for experts only." // {
      example = "-no-reboot -smbios 'type=0,vendor=FOO'";
    };

    audio0 = mkOption {
      description = "Configure an audio device, useful in combination with QXL/Spice.";
      default = null;
      type = types.nullOr (types.submodule {
        options = {
          device = mkOption {
            type = types.enum [
              "ich9-intel-hda"
              "intel-hda"
              "AC97"
            ];
            default = "ich9-intel-hda";
            description = "Specify the type of audio device to be used.";
          };
          driver = mkNullDefaultEnumOption "Specify the audio driver to be used." [ "spice" "none" ];
        };
      });
    };

    autostart = mkNullDefaultBoolOption "Automatic restart after crash (currently ignored).";

    balloon = mkNullDefaultUnsignedOption "Amount of target RAM for the VM in MiB. Using zero disables the balloon driver.";

    bios = mkNullDefaultEnumOption "Select BIOS implementation." [ "seabios" "ovmf" ];

    boot = mkOption {
      description = "Specify guest boot order.";
      default = null;
      type = types.nullOr (types.submodule {
        options = {
          order = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Specify boot order of devices (e.g., 'disk', 'cdrom').";
          };
        };
      });
    };

    bwlimit = mkNullDefaultUnsignedOption "Override I/O bandwidth limit (in KiB/s).";

    cdrom = mkNullDefaultStrOption "Alias for option -ide2.";

    cores = mkNullDefaultOption types.ints.positive "The number of cores per socket.";

    cpu = mkOption {
      default = null;
      type = types.nullOr (types.submodule {
        options = {
          cputype = mkNullDefaultStrOption "Specify the CPU type to emulate.";
          flags = mkNullDefaultStrOption "CPU flags to enable or disable." // {
            example = "+vmx;-svm";
          };
          hidden = mkNullDefaultBoolOption "Whether to hide the CPU from the guest.";
          hv-vendor-id = mkNullDefaultStrOption "Hypervisor vendor ID string." // {
            example = "MyHypervisor";
          };
          phys-bits = mkOption {
            type = types.nullOr (types.either (types.ints.between 8 64) types.enum [ "host" ]);
            default = null;
            example = 64;
            description = "Number of physical address bits to use (between 8 and 64) or 'host' to use host settings.";
          };
          reported-model = mkNullDefaultEnumOption "Reported CPU model string." [
            "486"
            "Broadwell"
            "Broadwell-IBRS"
            "Broadwell-noTSX"
            "Broadwell-noTSX-IBRS"
            "Cascadelake-Server"
            "Cascadelake-Server-noTSX"
            "Cascadelake-Server-v2"
            "Cascadelake-Server-v4"
            "Cascadelake-Server-v5"
            "Conroe"
            "Cooperlake"
            "Cooperlake-v2"
            "EPYC"
            "EPYC-Genoa"
            "EPYC-IBPB"
            "EPYC-Milan"
            "EPYC-Milan-v2"
            "EPYC-Rome"
            "EPYC-Rome-v2"
            "EPYC-Rome-v3"
            "EPYC-Rome-v4"
            "EPYC-v3"
            "EPYC-v4"
            "GraniteRapids"
            "Haswell"
            "Haswell-IBRS"
            "Haswell-noTSX"
            "Haswell-noTSX-IBRS"
            "Icelake-Client"
            "Icelake-Client-noTSX"
            "Icelake-Server"
            "Icelake-Server-noTSX"
            "Icelake-Server-v3"
            "Icelake-Server-v4"
            "Icelake-Server-v5"
            "Icelake-Server-v6"
            "IvyBridge"
            "IvyBridge-IBRS"
            "KnightsMill"
            "Nehalem"
            "Nehalem-IBRS"
            "Opteron_G1"
            "Opteron_G2"
            "Opteron_G3"
            "Opteron_G4"
            "Opteron_G5"
            "Penryn"
            "SandyBridge"
            "SandyBridge-IBRS"
            "SapphireRapids"
            "SapphireRapids-v2"
            "Skylake-Client"
            "Skylake-Client-IBRS"
            "Skylake-Client-noTSX-IBRS"
            "Skylake-Client-v4"
            "Skylake-Server"
            "Skylake-Server-IBRS"
            "Skylake-Server-noTSX-IBRS"
            "Skylake-Server-v4"
            "Skylake-Server-v5"
            "Westmere"
            "Westmere-IBRS"
            "athlon"
            "core2duo"
            "coreduo"
            "host"
            "kvm32"
            "kvm64"
            "max"
            "pentium"
            "pentium2"
            "pentium3"
            "phenom"
            "qemu32"
            "qemu64"
          ];
        };
      }
      );
    };

    cpulimit = mkNullDefaultUnsignedOption ''
      Limit of CPU usage.
      NOTE: If the computer has 2 CPUs, it has total of '2' CPU time. Value '0' indicates no CPU limit.
    '';

    cpuunits = mkNullDefaultUnsignedOption "CPU weight for a VM. The larger the number, the more CPU time this VM gets.";

    description = mkNullDefaultStrOption "Description for the VM. Shown in the web-interface VM's summary.";

    efidisk0 = mkOption {
      description = "Configure a disk for storing EFI vars.";
      default = null;
      type = types.nullOr (types.submodule {
        options = {
          file = mkOption {
            type = types.str;
            example = "STORAGE_ID:10";
            description = ''
              Specify the volume for the disk.
              Use STORAGE_ID:SIZE_IN_GiB to allocate a new volume.
              Note that SIZE_IN_GiB is ignored here and that the default EFI vars are copied to the volume instead.
              Use STORAGE_ID:0 and the 'import-from' parameter to import from an existing volume.
            '';
          };
          efitype = mkNullDefaultEnumOption "Specify the EFI vars disk size type." [ "2m" "4m" ];
          format = mkOption {
            description = "Specify the disk format.";
            type = types.enum [
              "cloop"
              "cow"
              "qcow"
              "qcow2"
              "qed"
              "raw"
              "vmdk"
            ];
          };
          import-from = mkNullDefaultStrOption "Specify the source volume to import from." // {
            example = "source-volume";
          };
          pre-enrolled-keys = mkNullDefaultBoolOption "Whether to pre-enroll keys.";
          size = mkSizeOption "Specify the size of the disk. This parameter is ignored if 'file' specifies an EFI vars disk." // {
            example = "10GiB";
          };
        };
      }
      );
    };

    force = mkNullDefaultBoolOption "Allow to overwrite existing VM.";

    freeze = mkNullDefaultBoolOption "Freeze CPU at startup.";

    hookscript = mkNullDefaultStrOption "Script that will be executed during various steps in the VM's lifetime.";

    hostpci = mkOption {
      description = ''
        Map host PCI devices into guest.

        NOTE: This option allows direct access to host hardware. So it is no longer
        possible to migrate such machines - use with special care.

        CAUTION: Experimental! User reported problems with this option.
      '';
      default = null;
      type = types.nullOr (types.listOf (
        types.submodule {
          options = {
            host = mkOption {
              type = types.listOf types.str;
              example = [ "0000:00:1f.2" ];
              default = [ ];
              description = "Specify the host PCI IDs to map into the guest.";
            };
            device-id = mkNullDefaultStrOption "Specify the device ID of the PCI device." // {
              example = "1234";
            };
            legacy-igd = mkNullDefaultBoolOption "Enable or disable legacy integrated graphics device support.";
            mapping = mkNullDefaultStrOption "Specify the mapping ID for the PCI device.";
            mdev = mkOption {
              type = types.str;
              description = "Specify the mediated device for PCI passthrough.";
            };
            pcie = mkNullDefaultBoolOption "Enable or disable PCIe support for the device.";
            rombar = mkNullDefaultBoolOption "Enable or disable ROMBAR for the device.";
            romfile = mkNullDefaultOption types.path "Specify the path to the ROM file for the device." // {
              example = "/path/to/romfile.rom";
            };
            sub-device-id = mkNullDefaultStrOption "Specify the sub-device ID of the PCI device." // {
              example = "5678";
            };
            sub-vendor-id = mkNullDefaultStrOption "Specify the sub-vendor ID of the PCI device." // {
              example = "abcd";
            };
            vendor-id = mkNullDefaultStrOption "Specify the vendor ID of the PCI device." // {
              example = "dead";
            };
            x-vga = mkNullDefaultBoolOption "Enable or disable VGA support for the PCI device.";
          };
        }
      )
      );
    };

    hotplug = mkOption {
      description = "Selectively enable hotplug features. Use 'false' to disable hotplug completely.";
      default = null;
      type = types.nullOr (types.either types.bool (
        types.listOf (
          types.enum [
            "network"
            "disk"
            "cpu"
            "memory"
            "usb"
            "cloudinit"
          ]
        )
      ));
    };

    hugepages = mkNullDefaultEnumOption "Enable/disable hugepages memory." [
      "any"
      "2"
      "1024"
    ];

    ide = mkOption {
      type = typeListOfMaxLength 3 (types.submodule commonVolumeOptions);
      default = [ ];
      description = "Use volume as IDE hard disk or CD-ROM.";
    };

    ivshmem = mkOption {
      description = "Inter-VM shared memory. Useful for direct communication between VMs, or to the host.";
      default = null;
      type = types.nullOr (
        types.submodule {
          options = {
            size = mkOption {
              type = types.ints.positive;
              description = "Size of the shared memory in megabytes.";
            };

            name = mkOption {
              type = types.str;
              description = "Name for the shared memory region.";
              example = "vmshm1";
            };
          };
        }
      );
    };

    keephugepages = mkNullDefaultBoolOption "Use together with hugepages. If enabled, hugepages will not not be deleted after VM shutdown and can be used for subsequent starts.";

    keyboard = mkNullDefaultEnumOption "Keyboard layout for VNC server. This option is generally not required and is often better handled from within the guest OS." [
      "de"
      "de-ch"
      "da"
      "en-gb"
      "en-us"
      "es"
      "fi"
      "fr"
      "fr-be"
      "fr-ca"
      "fr-ch"
      "hu"
      "is"
      "it"
      "ja"
      "lt"
      "mk"
      "nl"
      "no"
      "pl"
      "pt"
      "pt-br"
      "sv"
      "sl"
      "tr"
    ];

    kvm = mkNullDefaultBoolOption "Enable/disable KVM hardware virtualization.";

    live-restore = mkNullDefaultBoolOption "Start the VM immediately while importing or restoring in the background.";

    localtime = mkNullDefaultBoolOption "Set the real time clock (RTC) to local time.";

    lock = mkNullDefaultEnumOption "Lock/unlock the VM." [
      "backup"
      "clone"
      "create"
      "migrate"
      "rollback"
      "snapshot"
      "snapshot-delete"
      "suspending"
      "suspended"
    ];

    machine = mkOption {
      description = "Specify the QEMU machine.";
      default = null;
      type = types.nullOr (
        types.submodule {
          options = {
            type = mkOption {
              type = types.str;
              description = "Specifies the QEMU machine type.";
              example = "pc-i440fx-6.0";
            };

            viommu = mkNullDefaultEnumOption "Specifies the IOMMU type for the QEMU machine." [ "intel" "virtio" ];
          };
        }
      );
    };

    memory = mkOption {
      type = types.ints.unsigned;
      description = "Specifies the current memory size in megabytes.";
      example = 2048;
    };

    migrate_downtime = mkNullDefaultOption types.numbers.positive "Set maximum tolerated downtime (in seconds) for migrations. Should the migration not be able to converge in the very end, because too much newly dirtied RAM needs to be transferred, the limit will be increased automatically step-by-step until migration can converge.";

    migrate_speed = mkNullDefaultUnsignedOption "Set maximum speed (in MB/s) for migrations. Value 0 is no limit.";

    net = mkOption {
      description = "Specify network devices.";
      default = [ ];
      type = types.listOf (
        types.submodule {
          options = {
            model = mkOption {
              type = types.enum [
                "e1000"
                "virtio"
                "rtl8139"
                "vmxnet3"
              ];
              description = "Specifies the network device model.";
              example = "virtio";
            };
            bridge = mkNullDefaultStrOption "Specifies the bridge to which the network device will be connected." // {
              example = "vmbr0";
            };
            firewall = mkOption {
              type = types.bool;
              default = true;
              description = "Enable or disable the firewall on this network device.";
            };
            link_down = mkEnableOption "Specifies whether the network link is down.";
            macaddr = mkNullDefaultOption typeMacAddress "Specifies the MAC address for the network device." // {
              example = "52:54:00:12:34:56";
            };
            mtu = mkNullDefaultOption (types.ints.between 1 655200) "Specifies the MTU (Maximum Transmission Unit) for the network device." // {
              example = 1500;
            };
            queues = mkNullDefaultOption (types.ints.between 0 64) "Specifies the number of queues for the network device." // {
              example = 4;
            };
            rate = mkOption {
              type = types.nullOr types.numbers.positive;
              default = null;
              description = "Specifies the network rate limit in Mbps.";
              example = 100.0;
            };
            tag = mkNullDefaultOption typeVlan "Specifies the VLAN tag ID." // {
              example = 100;
            };
            trunks = mkOption {
              type = types.listOf typeVlan;
              default = [ ];
              description = "Specifies a list of VLAN IDs for trunking.";
              example = [
                100
                200
                300
              ];
            };
            custom_macaddr = mkNullDefaultOption typeMacAddress "Specifies a custom MAC address for the network device." // {
              example = "52:54:00:ab:cd:ef";
            };
          };
        }
      );
    };

    numa = mkNullDefaultBoolOption "NUMA.";

    numa_config = mkOption {
      description = "NUMA topology.";
      default = [ ];
      type = types.listOf (
        types.submodule {
          options = {
            cpus = mkOption {
              type = types.listOf types.str;
              description = "Specifies the CPU IDs or ranges of IDs to be associated with the NUMA node.";
              example = [
                "0-3"
                "5"
              ];
            };
            hostnodes = mkOption {
              type = types.str;
              description = "Specifies the host NUMA node IDs or ranges of IDs.";
              example = "0-1";
            };
            memory = mkOption {
              type = types.ints.unsigned;
              description = "Specifies the amount of memory (in MiB) to be allocated to the NUMA node.";
              example = 2048;
            };
            policy = mkOption {
              type = types.enum [
                "preferred"
                "bind"
                "interleave"
              ];
              description = "Specifies the NUMA memory policy.";
              example = "preferred";
            };
          };
        }
      );
    };

    onboot = mkNullDefaultBoolOption "Specifies whether a VM will be started during system bootup.";

    ostype = mkOption {
      description = "Specify guest operating system.";
      default = "l26";
      type = types.enum [
        "other"
        "l24"
        "l26"
      ];
    };

    parallel = mkOption {
      description = "Map host parallel devices.";
      type = typeListOfMaxLength 2 (types.strMatching "(/dev/parport[[:digit:]]+|/dev/usb/lp[[:digit:]]+)");
      default = [ ];
      example = [ "/dev/parport0" ];
    };

    pool = mkNullDefaultStrOption ''
      Map host parallel devices (up to 3).

      NOTE: This option allows direct access to host hardware. So it is no longer possible to migrate such
      machines - use with special care.

      CAUTION: Experimental! User reported problems with this option.
    '';

    protection = mkNullDefaultBoolOption "Sets the protection flag of the VM. This will disable the remove VM and remove disk operations.";

    reboot = mkNullDefaultBoolOption "Allow reboot. If set to 'false' the VM exit on reboot.";

    rng0 = mkOption {
      description = "Configure a VirtIO-based Random Number Generator.";
      default = null;
      type = types.nullOr (types.submodule {
        options = {
          source = mkNullDefaultEnumOption "Specifies the source of entropy for the VirtIO-based RNG device." [
            "/dev/urandom"
            "/dev/random"
            "/dev/hwrng"
          ];
          max_bytes = mkNullDefaultUnsignedOption "Specifies the maximum number of bytes that can be consumed from the RNG source per period." // {
            example = 1024;
          };
          period = mkNullDefaultUnsignedOption "Specifies the period in milliseconds during which max_bytes can be consumed." // {
            example = 1000;
          };
        };
      });
    };

    sata = mkOption {
      type = typeListOfMaxLength 5 (types.submodule commonVolumeOptions);
      default = [ ];
      description = "Use volume as SATA hard disk or CD-ROM.";
    };

    scsi = mkOption {
      description = "Use volume as SCSI hard disk or CD-ROM (up to 30).";
      default = [ ];
      type = typeListOfMaxLength 30 (types.submodule {
        options = commonVolumeOptions.options // {
          iothread = mkNullDefaultBoolOption "Enable or disable I/O threads.";
          product = mkNullDefaultStrOption "Product name for the SCSI disk.";
          queues = mkNullDefaultUnsignedOption "Number of SCSI queues.";
          scsiblock = mkNullDefaultBoolOption "Enable or disable SCSI block mode.";
          ro = mkNullDefaultBoolOption "Enable or disable read-only mode.";
          vendor = mkNullDefaultStrOption "Vendor name for the SCSI disk.";
        };
      });
    };

    scsihw = mkOption {
      type = types.enum [
        "lsi"
        "lsi53c810"
        "virtio-scsi-pci"
        "virtio-scsi-single"
        "megasas"
        "pvscsi"
      ];
      default = "virtio-scsi-single";
      description = "SCSI controller model.";
    };

    serial0 = mkOption {
      description = ''
        Create a serial device inside the VM (up to 3), and pass through a
        host serial device (i.e. /dev/ttyS0), or create a unix socket on the
        host side (use 'qm terminal' to open a terminal connection).

        NOTE: If you pass through a host serial device, it is no longer possible to migrate such machines -
        use with special care.

        CAUTION: Experimental! User reported problems with this option.
      '';
      default = null;
      type = types.nullOr (types.strMatching "(/dev/.+|socket)");
    };

    shares = mkNullDefaultOption (types.ints.between 0 50000) "Amount of memory shares for auto-ballooning. The larger the number is, the more memory this VM gets. Number is relative to weights of all other running VMs. Using zero disables auto-ballooning. Auto-ballooning is done by pvestatd.";

    smbios1 = mkOption {
      description = "Specify SMBIOS type 1 fields.";
      default = null;
      type = types.nullOr (types.submodule {
        options = {
          base64 = mkNullDefaultBoolOption "Indicates whether the provided SMBIOS fields are Base64 encoded.";
          family = mkNullDefaultStrOption "Specifies the family of the SMBIOS type 1 fields in Base64 encoded string." // {
            example = "QmFzZTY0RmFtaWx5";
          };
          manufacturer = mkNullDefaultStrOption "Specifies the manufacturer of the SMBIOS type 1 fields in Base64 encoded string." // {
            example = "QmFzZTY0TWFudWZhY3R1cmVy"; # Example encoded string
          };
          product = mkNullDefaultStrOption "Specifies the product name of the SMBIOS type 1 fields in Base64 encoded string." // {
            example = "QmFzZTY0UHJvZHVjdA==";
          };
          serial = mkNullDefaultStrOption "Specifies the serial number of the SMBIOS type 1 fields in Base64 encoded string." // {
            example = "U2VyaWFsTnVtYmVy";
          };
          sku = mkNullDefaultStrOption "Specifies the SKU number of the SMBIOS type 1 fields in Base64 encoded string." // {
            example = "U0tVTnVtYmVy";
          };
          uuid = mkNullDefaultStrOption "Specifies the UUID for the SMBIOS type 1 fields." // {
            example = "123e4567-e89b-12d3-a456-426614174000";
          };
          version = mkNullDefaultStrOption "Specifies the version of the SMBIOS type 1 fields in Base64 encoded string." // {
            example = "VmVyc2lvbk5hbWU=";
          };
        };
      });
    };

    sockets = mkNullDefaultOption types.ints.positive "Number of CPU sockets.";

    spice_enhancements = mkOption {
      description = "Configure additional enhancements for SPICE.";
      default = null;
      type = types.nullOr (types.submodule {
        options = {
          foldersharing = mkNullDefaultBoolOption "Enable or disable folder sharing through SPICE.";
          videostreaming = mkNullDefaultEnumOption "Configure video streaming options for SPICE." [
            "off"
            "all"
            "filter"
          ];
        };
      });
    };

    start = mkNullDefaultBoolOption "Start VM after it was created successfully.";

    startdate = mkNullDefaultStrOption "Set the initial date of the real time clock. Valid format for date are:'now' or '2006-06-17T16:01:21' or '2006-06-17'.";

    startup = mkOption {
      description = "Startup and shutdown behavior. Order is a non-negative number defining the general startup order. Shutdown in done with reverse ordering. Additionally you can set the 'up' or 'down' delay in seconds, which specifies a delay to wait before the next VM is started or stopped.";
      default = null;
      type = types.nullOr (types.submodule {
        options = {
          order = mkNullDefaultUnsignedOption "";
          up = mkNullDefaultUnsignedOption "";
          down = mkNullDefaultUnsignedOption "";
        };
      });
    };

    storage = mkNullDefaultStrOption "Default storage ID.";

    tablet = mkNullDefaultBoolOption "Enable/disable the USB tablet device. This device is usually needed to allow absolute mouse positioning with VNC. Else the mouse runs out of sync with normal VNC clients. If you're running lots of console-only guests on one host, you may consider disabling this to save some context switches. This is turned off by default if you use spice (`qm set <vmid> --vga qxl`).";

    tags = mkNullDefaultStrOption "Tags of the VM. Tags are only meta information.";

    tdf = mkNullDefaultBoolOption "time drift fix.";

    template = mkNullDefaultBoolOption "Template.";

    tpmstate0 = mkOption {
      description = "Configure a Disk for storing TPM state. The format is fixed to 'raw'.";
      default = null;
      type = types.nullOr (types.submodule {
        options = {
          file = mkOption {
            description = "Specify the volume for storing TPM state. Use STORAGE_ID:SIZE_IN_GiB to allocate a new volume. Note that SIZE_IN_GiB is ignored here and 4 MiB will be used instead. Use STORAGE_ID:0 and the 'import-from' parameter to import from an existing volume.";
            type = types.str;
            example = "STORAGE_ID:0";
          };
          import-from = mkNullDefaultStrOption "Specify the source volume to import TPM state from.";
          version = mkNullDefaultEnumOption "Specify the version of the TPM state." [
            "v1.2"
            "v2.0"
          ];
        };
      });
    };

    unique = mkNullDefaultBoolOption "Assign a unique random ethernet address.";

    usb = mkOption {
      description = "Configure an USB device (up to 4).";
      default = [ ];
      type = typeListOfMaxLength 4 (types.submodule {
        options = {
          host = mkOption {
            type = types.str;
            description = "Specify the USB device or SPICE to be configured.";
            example = "/dev/bus/usb/001/002";
          };
          mapping = mkOption {
            type = types.str;
            description = "Specify the mapping ID for the USB device.";
          };
          usb3 = mkNullDefaultBoolOption "Enable or disable USB 3.0 support.";
        };
      });
    };

    vga = mkOption {
      description = "Configure the VGA Hardware.";
      default = null;
      type = types.nullOr (types.submodule {
        options = {
          type = mkOption {
            description = "Specify the type of VGA hardware.";
            type = types.enum [
              "cirrus"
              "none"
              "qxl"
              "qxl2"
              "qxl3"
              "qxl4"
              "serial0"
              "serial1"
              "serial2"
              "serial3"
              "std"
              "virtio"
              "virtio-gl"
              "vmware"
            ];
          };
          clipboard = mkNullDefaultEnumOption "Enable clipboard sharing for VNC." [ "vnc" ];
          memory = mkNullDefaultUnsignedOption "Specify the amount of VGA memory in MiB." // {
            example = 16;
          };
        };
      });
    };

    virtio = mkOption {
      description = "Use volume as VIRTIO hard disk.";
      default = [ ];
      type = typeListOfMaxLength 15 (
        types.submodule {
          options = commonVolumeOptions.options // {
            iothread = mkNullDefaultBoolOption "Enable or disable I/O threads.";
            ro = mkNullDefaultBoolOption "Enable or disable read-only mode.";
          };
        }
      );
    };

    vmgenid = mkNullDefaultStrOption "Virtual Machine Generation Identifier.";

    vmstatestorage = mkNullDefaultStrOption "Reference to the volume storing the VM state. This is used internally.";

    watchdog = mkOption {
      description = "Create a virtual hardware watchdog device.";
      default = null;
      type = types.nullOr (types.submodule {
        options = {
          model = mkNullDefaultEnumOption "Specify the model of the virtual hardware watchdog device." [
            "i6300esb"
            "ib700"
          ];
          action = mkNullDefaultEnumOption "Specify the action to be taken if the watchdog is not polled by the guest." [
            "reset"
            "shutdown"
            "poweroff"
            "pause"
            "debug"
            "none"
          ];
        };
      });
    };
  };

}
