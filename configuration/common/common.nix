{ config, lib, pkgs, ... }:

{
  nix.trusted-users = [ "root" "@wheel" "kloenk" ];
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  ''; # recursive-nix progress-bar

  nix.gc.automatic = lib.mkDefault true;
  nix.gc.options = lib.mkDefault "--delete-older-than 7d";

  # binary cache
  nix.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
  nix.substituters = [
  #  "https://nix-community.cachix.org/"
  ];
  nix.registry.kloenk = {
    from.type = "indirect";
    from.id = "kloenk";
    #to.url = "git+https://git.kloenk.dev/kloenk/nix";
    to.type = "gitlab";
    to.repo = "nix";
    to.owner = "kloenk";
    to.host = "cyberchaos.dev";
    exact = false;
  };

  time.timeZone = "Europe/Berlin";

  environment.systemPackages = with pkgs; [
    exa
    fd
    ripgrep

    htop

  ];
}
