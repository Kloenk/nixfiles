{ pkgs, lib, ... }: {
  boot.initrd.supportedFilesystems = [ "vfat" "bcachefs" ];
  boot.supportedFilesystems = [ "bcachefs" "cifs" "vfat" "xfs" ];

  # working:
  boot.kernelPackages = lib.mkForce pkgs.linuxKernel.packages.linux_6_6;
  boot.kernelPatches =
    let currentCommit = "b9bd69421f7364ca4ff11c827fd0e171a8b826ea";
    in [{
      name = "bcachefs-${currentCommit}";
      patch = pkgs.fetchpatch {
        name = "bcachefs-${currentCommit}.diff";
        url =
          "https://evilpiepirate.org/git/bcachefs.git/rawdiff/?id=${currentCommit}&id2=v6.6";
        sha256 = "sha256-+Gp/1kTBgRx5a01l9xtaDbiLuOP58uZ7rx27WyYcMT4=";
      };
      extraConfig = ''
        BCACHEFS_QUOTA y
        BCACHEFS_POSIX_ACL y
      '';
      # extra config is inherited through boot.supportedFilesystems
    }];

  services.fstrim.enable = true;
}
