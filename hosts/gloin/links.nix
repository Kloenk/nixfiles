{ config, pkgs, lib, ... }:

let
  links = config.systemd.network.links;
  netdevs = config.systemd.network.netdevs;
  networks = config.systemd.network.networks;
in {
  systemd.network = {
    links."10-eth0" = {
      matchConfig.MACAddress = "96:00:02:b4:f1:e6";
      linkConfig.Name = "eth0";
    };
    networks."10-eth0" = {
      name = "eth0";
      DHCP = "yes";
    };
  };
}
