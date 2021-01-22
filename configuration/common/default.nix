{ config, pkgs, lib, ... }:

{
  imports =
    [ ./nginx ./node-exporter ./zsh ./make-nixpkgs.nix ./kloenk.nix ./pbb.nix ];

  # environment.etc."src/nixpkgs".source = config.sources.nixpkgs;
  #  environment.etc."src/nixos-config".text = ''
  #      ((import (fetchTarball "https://github.com/kloenk/nix/archive/master.tar.gz") { }).configs.${config.networking.hostName})
  #  '';
  #  environment.variables.NIX_PATH = lib.mkOverride 25 "/etc/src";

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  nix.gc.automatic = lib.mkDefault true;
  nix.gc.options = lib.mkDefault "--delete-older-than 7d";
  nix.trustedUsers = [ "root" "@wheel" "kloenk" ];
  # nix flakes
  #nix.package = lib.mkDefault pkgs.nixFlakes;
  nix.systemFeatures = [ "recursive-nix" "kvm" "nixos-test" "big-parallel" ];
  nix.extraOptions = ''
    experimental-features = nix-command flakes ca-references recursive-nix progress-bar
  '';

  system.autoUpgrade.flake = "kloenk";

  # binary cache
  nix.binaryCachePublicKeys =
    [ "cache.kloenk.de:ea1cL0mwRMABkALTC/cYV84V0eoL1UWkj3e2TvS4Y6o=" ];
  #nix.binaryCaches = if config.networking.hostName != "sauron" then
  #  [ "https://cache.kloenk.de" ]
  #else
  #  [ ];

  networking.domain = lib.mkDefault "kloenk.de";
  networking.useNetworkd = lib.mkDefault true;
  networking.search = [ "kloenk.de" ];
  networking.extraHosts = ''
    127.0.0.1 ${config.networking.hostName}.kloenk.de
  '';
  networking.useDHCP = lib.mkDefault false;

  # ssh
  services.openssh = {
    enable = true;
    ports = [ 62954 ];
    passwordAuthentication = lib.mkDefault
      (if (config.networking.hostName != "kexec") then false else true);
    challengeResponseAuthentication = false;
    permitRootLogin = lib.mkDefault "prohibit-password";
    hostKeys = if (config.networking.hostName != "kexec") then [{
      path = config.petabyte.secrets."ssh_host_ed25519_key".path;
      type = "ed25519";
    }] else
      [ ];
    extraConfig = if (config.networking.hostName == "kexec"
      || config.networking.hostName == "veantur") then
      ""
    else
      let
        hostCertificate = pkgs.writeText "host_cert_ed25519" (builtins.readFile
          (toString ../ca
            + "/ssh_host_ed25519_key_${config.networking.hostName}-cert.pub"));
      in ''
        HostCertificate ${hostCertificate}
        StreamLocalBindUnlink yes
      '';
  };
  petabyte.secrets."ssh_host_ed25519_key".owner = "root";
  #petabyte.secretsDefaultPath = ../secrets + "/${config.networking.hostName}";
  #petabyte.secretsDefaultPath = "../../secrets/${config.networking.hostName}";

  # monitoring
  services.vnstat.enable = lib.mkDefault true;
  programs.sysdig.enable = lib.mkDefault true;
  security.sudo.wheelNeedsPassword = false;

  petabyte.nftables.enable = true;
  petabyte.nftables.forwardPolicy = lib.mkDefault "drop";

  services.journald.extraConfig = "SystemMaxUse=2G";

  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "neo";
  console.font = "Lat2-Terminus16";

  time.timeZone = "Europe/Berlin";

  environment.systemPackages = with pkgs; [
    #termite.terminfo
    kitty.terminfo
    alacritty.terminfo
    rxvt_unicode.terminfo
    restic
    tmux
    exa
    iptables
    bash-completion
    whois
    qt5.qtwayland

    fd
    ripgrep

    erlang # for escript scripts
    rclone
    wireguard-tools

    usbutils
    pciutils
    git
  ];

  environment.variables.EDITOR = "vim";

  users.users.kloenk.shell = lib.mkOverride 75 pkgs.zsh;

  home-manager.users.kloenk = import ./home.nix {
    pkgs = pkgs;
    lib = lib;
  };

  #programs.fish.enable = true;
  programs.zsh.enable = true;
  programs.mtr.enable = true;

  #users.users.root.shell = pkgs.fish;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBps9Mp/xZax8/y9fW1Gt73SkskcBux1jDAB8rv0EYUt cardno:000612029874"
  ];

  # initrd ssh foo
  boot.initrd.network.ssh = {
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBps9Mp/xZax8/y9fW1Gt73SkskcBux1jDAB8rv0EYUt cardno:000612029874"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9fXR2sAD3q5hHURKg2of2OoZiKz9Nr2Z7qx6nfLLMwK1nie1rFhbwSRK8/6QUC+jnpTvUmItUo+etRB1XwEOc3rabDUYQ4dQ+PMtQNIc4IuKfQLHvD7ug9ebJkKYaunq6+LFn8C2Tz4vbiLcPFSVpVlLb1+yaREUrN9Yk+J48M3qvySJt9+fa6PZbTxOAgKsuurRb8tYCaQ9TzefKJvZXIVd+W2tzYV381sSBKRyAJLu/8tA+niSJ8VwHntAHzaKzv6ozP5yBW2SB7R7owGd1cnP7znEPxB9jeDBBWLonsocwFalP1RGt1WsOiIGEPhytp5RDXWgZM5sIS42iL61hMB9Yz3PaQYLuR+1XNzdGRLIKPUDh58lGdk2P5HUqPnvE/FqfzU3jkv6ebJmcGfZiEN1TPc5ar8sQkpn56hB2DnJYWICuryTm0XpzSizf9fGyLGBw3GVBlnZjzTaBf7iokGFIu+ade5AqEjX6FxlNja1ESFNKhDAdLAHFnaKJ3u0= kloenk@kloenkX"
    ];
    port = lib.mkDefault 62954;
    hostKeys = lib.mkDefault [ "/persist/data/ssh_initrd_ed25519" ];
  };

  systemd.tmpfiles.rules = [
    "Q /persist 755 root - - -"
    "Q /persist/data 755 root - - -"

    "Q /persist/data/acme 750 nginx - - -"
    #"L /var/lib/acme - acme - - /persist/data/acme"
    #"L+ /etc/shadow - - - - /persist/data/shadow"
  ];

  fileSystems."/var/lib/acme" = {
    device = "/persist/data/acme";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/root/.gnupg" = {
    device = "/persist/data/gnupg-root";
    fsType = "none";
    options = [ "bind" ];
  };

}
