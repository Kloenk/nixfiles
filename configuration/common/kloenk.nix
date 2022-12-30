{ lib, pkgs, config, ... }:

{
  /* nix.registry.kloenk = {
       from.type = "indirect";
       from.id = "kloenk";
       #to.url = "git+https://git.kloenk.dev/kloenk/nix";
       to.type = "gitlab";
       to.repo = "nix";
       to.owner = "kloenk";
       to.host = "lab.kloenk.dev";
       exact = false;
     };
  */

  users.users.kloenk = {
    isNormalUser = true;
    uid = lib.mkDefault 1000;
    #initialPassword = lib.mkDefault "foobar";
    extraGroups = [ "wheel" "bluetooth" "libvirtd" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBps9Mp/xZax8/y9fW1Gt73SkskcBux1jDAB8rv0EYUt cardno:000611120054"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLNxiPZehrmMebnU9HgqEHo278F1promBrgixOaHnyIrEVZ+Vd1l9AiVwTPYn1s65OfiuZ8n/Eg2rKStNOr5wBA="
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNRVDZB2ID/R2S6ErIaMvmOcSNiakBgMZoPuwgzPFVuUv6xDMaOQf65viu5DoD+VvTWAJTezQYtuuxc7aUDQiQY= mac@secretive.Finn’s-MacBook-Pro.local"
    ];
    packages = with pkgs; [
      wget
      tmux
      nload
      htop
      ripgrep
      exa
      bat
      progress
      pv
      file
      #elinks
      bc
      #zstd
      unzip
      jq
      pass
      #pass-otp
      neofetch
      onefetch
      sl
      tcpdump
      binutils
      nixfmt
      perl
    ];
  };

  programs.gnupg.agent = {
    enable = lib.mkDefault true;
    enableSSHSupport = true;
  };

  programs.ssh.knownHosts = {
    "kloenk.de" = {
      extraHostNames = [ "*.kloenk.de" ];
      certAuthority = true;
      publicKeyFile = toString ./server_ca.pub;
    };
    "kloenk.dev" = {
      extraHostNames = [ "*.kloenk.dev" ];
      certAuthority = true;
      publicKeyFile = toString ./server_ca.pub;
    };
  };
}
