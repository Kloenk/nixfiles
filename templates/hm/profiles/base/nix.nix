{ lib, pkgs, ... }@args:

{
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
      builders-use-substitutes = true
    '';
    settings = {
      trusted-users = [ "root" "@wheel" ];
      trusted-public-keys = [ ];
      substituters = [ ];
    };
    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 7d";
    };
    registry = {
      # short hand to kloenk's flake
      kloenk = {
        from.type = "indirect";
        from.id = "kloenk";
        to.type = "gitlab";
        to.host = "cyberchaos.dev";
        to.owner = "kloenk";
        to.repo = "nix";
        exact = false;
      };
      # pin non exact nixpkgs to be the same as the system eval nixpkgs
      nixpkgs.flake = args.inputs.nixpkgs;
    };
  };
  environment.systemPackages = [ pkgs.nix-output-monitor ];
}
