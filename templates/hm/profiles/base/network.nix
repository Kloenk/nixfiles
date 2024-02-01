{ lib, config, ... }:

{
  networking.useNetworkd = lib.mkDefault true;
  networking.hosts = {
    "127.0.0.1" = [ config.networking.hostName config.networking.fqdn ];
  };
  networking.useDHCP = lib.mkDefault false;
  networking.interfaces.lo = lib.mkDefault {
    ipv4.addresses = [
      {
        address = "127.0.0.1";
        prefixLength = 8;
      }
      # systemd-resolved address
      {
        address = "127.0.0.53";
        prefixLength = 32;
      }
    ];
  };
}
