{ config, pkgs, lib, ... }:

let
  v6 = "2a01:4f8:c012:b874::";
  v4 = "168.119.57.172";

  wgv6 = "2a01:4f8:c013:1a4b:ecba::2";
  wgv4 = "192.168.242.2";
in {
  networking.firewall.allowedUDPPorts = [
    51820 # wg0
  ];

  k.dns.ipv4 = v4;
  k.dns.ipv6 = v6;
  k.dns.public = true;

  k.wg = {
    enable = true;
    id = 2;
  };

  systemd.network = {
    links."10-eth0" = {
      matchConfig.MACAddress = "96:00:02:ae:9b:77";
      linkConfig.Name = "eth0";
    };
    networks."10-eth0" = {
      name = "eth0";
      addresses = [{ addressConfig.Address = "${v6}/64"; }];
      routes = [{ routeConfig.Gateway = "fe80::1"; }];
      DHCP = "ipv4";
    };
  };
}
