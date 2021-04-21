# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [ "usbhid" "sr_mod" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/b927fa3e-682b-4115-b63b-cdef5fb28039";
      fsType = "xfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/B39C-C99E";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/ee5b0e76-3b3c-46c4-b6ac-c78b75c1d8a4";
      fsType = "xfs";
    };

  fileSystems."/persist" =
    { device = "/dev/disk/by-uuid/bfb6918c-27bc-4ed7-8ff0-2e89f5dd37c7";
      fsType = "xfs";
    };

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 2;
}
