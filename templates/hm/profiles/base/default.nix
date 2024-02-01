{ lib, pkgs, config, ... }:

{
  imports = [ ./network.nix ./ssh.nix ./nginx.nix ./nix.nix ];

  nix.settings.system-features =
    [ "recursive-nix" "kvm" "nixos-test" "big-parallel" ];

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "us";
  console.font = "Lat2-Terminus16";

  services.resolved.dnssec = "allow-downgrade";

  services.journald.extraConfig = lib.mkDefault "SystemMaxUse=2G";

  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;
  hardware.enableRedistributableFirmware = true;
  programs.mtr.enable = true;

  environment.systemPackages = with pkgs; [
    tmux
    bash-completion
    whois

    rclone
    wireguard-tools

    usbutils
    pciutils
  ];

  sops.defaultSopsFile = ../../secrets + "/${config.networking.hostName}.yaml";
}
