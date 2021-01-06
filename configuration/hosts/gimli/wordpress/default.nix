{ config, lib, pkgs, ... }:

{
  imports = [
    ./trudeltiere.nix
  ];

  services.httpd.enable = lib.mkOverride 25 false; # No thanks
  services.httpd.group = config.services.nginx.group;

  fileSystems."/var/lib/wordpress" = {
    device = "/persist/data/wordpress";
    fsType = "none";
    options = [ "bind" ];
  };
}