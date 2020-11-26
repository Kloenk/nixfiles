{ config, pkgs, ... }:

let
  grubDev = "/dev/sda";
  interface = "eno0";
  hostname = "nixos";
  supportedFilesystems = [ ];
  nixpkgs = (fetchTarball
    "https://github.com/nixos/nixpkgs/archive/nixos-unstable-small.tar.gz");
  pkgs = import nixpkgs { };
  lib = pkgs.lib;
in {
  imports = [
    ./hardware-configuration.nix
    ((fetchTarball
      "https://github.com/rycee/home-manager/archive/master.tar.gz") + "/nixos")
  ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = grubDev;
    useOSProber = true;
  };

  environment.etc."src/nixpkgs".source = nixpkgs;
  environment.variables.NIX_PATH = lib.mkOverride 25 "/etc/src";

  boot.supportedFilesystems = [ "xfs" "ext2" ] ++ supportedFilesystems;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = hostname;
  networking.useDHCP = false;
  networking.interfaces."${interface}".useDHCP = true;

  services.openssh = {
    enable = true;
    ports = [ 62954 ];
    passwordAuthentication = false;
    permitRootLogin = "without-password";
  };

  security.sudo.wheelNeedsPassword = false;

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "neo";
  console.font = "Lat2-Terminus16";

  time.timeZone = "Europe/Berlin";

  environment.systemPackages = with pkgs; [
    termite.terminfo
    kitty.terminfo
    tmux
    exa
    vim
    bat
    file
  ];

  environment.variables.EDITOR = "vim";

  users.users.kloenk = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBps9Mp/xZax8/y9fW1Gt73SkskcBux1jDAB8rv0EYUt cardno:000611120054"
    ];
    packages = with pkgs; [
      wget
      nload
      htop
      ripgrep
      git
      gptfdisk
      nix-prefetch-git
      pass
      pass-otp
      sl
      neofetch
    ];
  };

  system.activationScripts = {
    base-dirs = {
      text = ''
        mkdir -p /nix/var/nix/profiles/per-user/kloenk
        mkdir -p /var/src/secrets
      '';
      deps = [ ];
    };
  };

  home-manager.users.kloenk = {
    programs = {
      git = {
        enable = true;
        userName = "Finn Behrens";
        userEmail = "me@kloenk.de";
        extraConfig = {
          core.editor = "${pkgs.vim}/bin/vim";
          color.ui = true;
        };
      };

      fish = {
        enable = true;
        shellInit = ''
          set PAGER less
        '';
        shellAbbrs = {
          admin-YouGen = "ssh admin-yougen";
          cb = "cargo build";
          cr = "cargo run";
          ct = "cargo test";
          exit = " exit";
          gc = "git commit";
          gis = "git status";
          gp = "git push";
          hubble = "mosh hubble";
          ipa = "ip a";
          ipr = "ip r";
          s = "sudo";
          ssy = "sudo systemctl";
          sy = "systemctl";
          v = "vim";
          jrnl = " jrnl";
        };
        shellAliases = {
          ls = "exa";
          l = "exa -a";
          ll = "exa -lgh";
          la = "exa -lagh";
          lt = "exa -T";
          lg = "exa -lagh --git";
        };
      };

      ssh = {
        enable = true;
        forwardAgent = false;
        controlMaster = "auto";
        controlPersist = "15m";
        matchBlocks = {
          hubble = {
            hostname = "kloenk.de";
            port = 62954;
            user = "kloenk";
            forwardAgent = true;
          };
          hubble-encrypt = {
            hostname = "51.254.249.187";
            port = 62954;
            user = "root";
            forwardAgent = false;
            #identityFile = toString <secrets/id_rsa>;
            checkHostIP = false;
            extraOptions = { "UserKnownHostsFile" = "/dev/null"; };
          };
          lycus = {
            hostname = "10.0.0.4";
            port = 62954;
            user = "kloenk";
            forwardAgent = true;
          };
          admin-yougen = {
            hostname = "10.66.6.42";
            port = 62954;
            user = "kloenk";
            forwardAgent = true;
          };
          admin-yougen-io = {
            hostname = "10.66.6.42";
            port = 62954;
            user = "kloenk";
            forwardAgent = true;
            proxyJump = "io-llg0";
          };
          pluto = {
            hostname = "10.0.0.3";
            port = 62954;
            user = "kloenk";
            forwardAgent = true;
          };
          pluto-io = {
            hostname = "10.0.0.3";
            port = 62954;
            user = "kloenk";
            forwardAgent = true;
            proxyJump = "io-llg0";
          };
          io = {
            hostname = "10.0.0.2";
            port = 62954;
            user = "kloenk";
            forwardAgent = true;
          };
          io-llg0 = {
            hostname = "192.168.43.2";
            port = 62954;
            user = "kloenk";
            forwardAgent = true;
          };
          atom = {
            hostname = "192.168.178.248";
            port = 62954;
            user = "kloenk";
            forwardAgent = true;
          };
          atom-wg = {
            hostname = "192.168.42.7";
            port = 62954;
            user = "kloenk";
            forwardAgent = true;
          };
          kloenkX-fritz = {
            hostname = "192.168.178.43";
            port = 62954;
            user = "kloenk";
            forwardAgent = true;
          };
        };
      };

      vim = { enable = true; };
    };

    services = {
      gpg-agent = {
        enable = true;
        defaultCacheTtl = 300; # 5 min
        defaultCacheTtlSsh = 600; # 10 min
        maxCacheTtl = 7200; # 2h
      };
    };
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "gtk2";
  };

  programs.fish.enable = true;
  programs.mtr.enable = true;

  nix.trustedUsers = [ "kloenk" "@wheel" ];

  users.users.root.shell = pkgs.fish;

  system.stateVersion = "20.03";
}
