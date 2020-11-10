{ config, pgks, lib, ... }:

let bondName = "world";
in {
  systemd.network = {
    #netdevs."30-bond0" = {
    #  netdevConfig = {
    #    Kind = "bond";
    #    Name = bondName;
    #  };
    #  bondConfig = {
    #    Mode = "active-backup";
    #    MinLinks = "1";
    #    FailOverMACPolicy = "active";
    #  };
    #};
    #networks."50-bond0" = {
    #  name = bondName;
    #  DHCP = "yes";
    #};
    #networks."30-bond0" = {
    #  name = bondName;
    #  DHCP = "yes";
    #  matchConfig.SSID = "TT-WLAN";
    #};

    netdevs."25-vlan" = {
      netdevConfig = {
        Kind = "vlan";
        Name = "vlan1337";
      };
      vlanConfig.Id = 1337;
    };

    networks."25-vlan" = {
      name = config.systemd.network.netdevs."25-vlan".netdevConfig.Name;
      DHCP = "no";
      addresses = [{ addressConfig.Address = "6.0.2.5/24"; }];
    };

    networks."20-eno0" = {
      name = "eno0";
      DHCP = "yes";
      vlan = lib.singleton "vlan1337";
      dhcpV4Config.RouteMetric = 512;
    };
    networks."20-wlp2s0" = {
      name = "wlp2s0";
      DHCP = "yes";
    };
    networks."30-lo" = {
      name = "lo";
      DHCP = "no";
      addresses = [
        { addressConfig.Address = "127.0.0.1/32"; }
        { addressConfig.Address = "127.0.0.53/32"; }
        { addressConfig.Address = "::1/128"; }
      ];
    };
    links."30-xiaomi" = {
      matchConfig = { Property = "ID_SERIAL=Xiaomi_Mi_Note_2_d10974cf"; };
      linkConfig = {
        Description = "Xiaomi LTE Uplink";
        Name = "xiaomi";
      };
    };
    networks."30-xiaomi" = {
      name = "xiaomi";
      DHCP = "yes";
      dhcpV4Config.RouteMetric = 500;
      linkConfig.RequiredForOnline = "no";
    };
    networks."99-how_cares".linkConfig.RequiredForOnline = "no";
    networks."99-how_cares".linkConfig.Unmanaged = "yes";
  };
}
