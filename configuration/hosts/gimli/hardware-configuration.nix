# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/0a556e8a-e849-4d3e-b701-ecee617c92a9";
      fsType = "xfs";
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/e25fb804-736c-4ff1-819e-d70738d29297";
      fsType = "xfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/9EA4-E311";
      fsType = "vfat";
    };

  fileSystems."/persist" =
    { device = "/dev/disk/by-uuid/506b3452-d9d5-466a-bbbb-836f72f05961";
      fsType = "xfs";
    };

  fileSystems."/var/lib/acme" = {
    device = "/persist/acme";
    fsType = "none";
    options = [ "bind" ];
  };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/d2d2f5d2-22db-435a-9b5a-872a236f964e"; }
    ];

}
