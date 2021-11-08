{ config, lib, ... }:

{
  networking.firewall.allowedUDPPorts = [
    51820 # wg0
    51830 # yougen
  ];

  # NATING
  boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };

  #chain POSTROUTING {
  #  outerface enp1s0 SNAT to 195.39.247.6
  #}
  nftables.extraConfig = ''
    table ip nat {
      chain postrouting {
        type nat hook postrouting priority srcnat;
        ip saddr { 192.168.242.0-192.168.242.255 } oifname { "wg0" } snat to 192.168.242.1
        ip saddr { 172.16.16.0-172.16.16.255 } oifname "yougen" snat to 172.16.16.1
        oifname "enp1s0" masquerade
      }
    }
  '';
  nftables.forwardPolicy = "accept";

  systemd.network.netdevs."30-wg0" = {
    netdevConfig = {
      Kind = "wireguard";
      Name = "wg0";
    };
    wireguardConfig = {
      FirewallMark = 51820;
      ListenPort = 51820;
      PrivateKeyFile = config.petabyte.secrets."wg0.key".path;
    };
    wireguardPeers = [
      /* {
           wireguardPeerConfig = {
             AllowedIPs = [
               "192.168.42.102/32"
               #"195.39.246.10" # ???
             ];
             PublicKey = "";
             PersistentKeepalive = 21;
           };
         }
      */

      { # bombadil
        wireguardPeerConfig = {
          AllowedIPs = [ "192.168.242.52/32" ];
          PublicKey = "zXEZM2MwTNHENXA5aSL5h0mVWvVWxTH3TlKmYoIxzCk=";
        };
      }

      { # thrain
        wireguardPeerConfig = {
          AllowedIPs = [ "192.168.242.101/32" ];
          PublicKey = "RiRB/fiZ/x88f78kRQasSwWYBuBjc5DxW2OFaa67zjg=";
          PersistentKeepalive = 21;
        };
      }
      { # barahir
        wireguardPeerConfig = {
          AllowedIPs = [ "192.168.242.102/32" ];
          PublicKey = "4SUbImacuAjRwiK/G3CTmczirJQCI20EdJvPwJfCQxQ=";
          PersistentKeepalive = 21;
        };
      }
      { # manwe
        wireguardPeerConfig = {
          AllowedIPs = [ "192.168.242.103/32" ];
          PublicKey = "JRI1Z4XOrTAsyMqQ39f3QZ47aUftUnNeIjpxnfTUT3k=";
          Endpoint = "manwe.kloenk.dev:51820";
        };
      }

      { # mi 9 t
        wireguardPeerConfig = {
          AllowedIPs = [ "192.168.242.111/32" ];
          PublicKey = "3DpdBLKiw10+nnoh3Fvohdbo4NQDblfGH7WNmk7J7lA=";
          PersistentKeepalive = 21;
        };
      }

      { # Pocophone
        wireguardPeerConfig = {
          AllowedIPs = [ "192.168.242.202/32" ];
          PublicKey = "FvBat+gZV47VgiyVRF0QL79rzpk66kQxai0cs9Zvyhw=";
          PersistentKeepalive = 21;
        };
      }
      { # laptop
        wireguardPeerConfig = {
          AllowedIPs = [ "192.168.242.203/32" ];
          PublicKey = "HZ4+ZZ7OOJj7cidpUGtvzJEFr9tF3sb8zFDbELjsYjo=";
          PersistentKeepalive = 21;
        };
      }
      { # mbp
        wireguardPeerConfig = {
          AllowedIPs = [ "192.168.242.201/32" ];
          PublicKey = "5dwOBGEIencNKOu5NzL9R7q+CxPIbJ8c9CzVPma4g3U=";
          PersistentKeepalive = 21;
        };
      }
      { # iphone
        wireguardPeerConfig = {
          AllowedIPs = [ "192.168.242.210/32" ];
          PublicKey = "iSYB99dCUvYhHAz5HaPSzhXYPyyntOtiucrDUBFVvBE=";
          PersistentKeepalive = 21;
        };
      }
      { # old phone
        wireguardPeerConfig = {
          AllowedIPs = [ "192.168.242.211/32" ];
          PublicKey = "w3UoZ8XT7K9CVPnvXCZ3SVAkiaWXUFOub9i2EFyGmyg=";
          PersistentKeepalive = 21;
        };
      }
      { # louwa (luis)
        wireguardPeerConfig = {
          AllowedIPs = [ "192.168.242.204/32" ];
          PublicKey = "EAeeDBxci3TAhQExLNU0GzKyhBV30Ku9O1uLKXYzUkU=";
          PersistentKeepalive = 21;
        };
      }
      { # mum
        wireguardPeerConfig = {
          AllowedIPs = [ "192.168.242.205/32" ];
          PublicKey = "QWsfx59OadImT9nLGbx19Unr6GG6zObFBJSoLdtIFls=";
          PersistentKeepalive = 21;
        };
      }
    ];
  };
  systemd.network.networks."30-wg0" = {
    name = "wg0";
    linkConfig = { RequiredForOnline = "no"; };
    addresses = [
      { addressConfig.Address = "192.168.242.1/24"; }
    ];
    routes = [{
      routeConfig.Destination = "192.168.242.0/24";
    }
    #{ routeConfig.Destination = "10.0.0.0/24"; }
      ];
  };

  networking.hosts = {
    #"10.0.0.2" = [ "io.yougen.de" "git.yougen.de" ];
    #"10.0.0.5" = [ "grafana.yougen.de" "hydra.yougen.de" "lycus.yougen.de" ];
    "172.16.16.3" = [ "core.josefstrasse.yougen.de" ];
  };

  systemd.network.netdevs."30-yougen" = {
    netdevConfig = {
      Kind = "wireguard";
      Name = "yougen";
    };
    wireguardConfig = {
      FirewallMark = 51820;
      ListenPort = 51830;
      PrivateKeyFile = config.petabyte.secrets."yougen.key".path;
    };
    wireguardPeers = [{
      wireguardPeerConfig = {
        AllowedIPs = [ "172.16.16.3/32" ];
        PublicKey = "UDdUoBRXy+3skbUuh7gLNmHnnbtJPncbCPPeZNX/rBU=";
        PersistentKeepalive = 21;
      };
    }];
  };
  systemd.network.networks."30-yougen" = {
    name = "yougen";
    linkConfig.RequiredForOnline = "no";
    addresses = [{ addressConfig.Address = "172.16.16.1/24"; }];
    routes = [{ routeConfig.Destination = "172.16.16.0/24"; }];
  };

  users.users.systemd-network.extraGroups = [ "keys" ];
  petabyte.secrets."wg0.key".owner = "systemd-network";
  petabyte.secrets."yougen.key".owner = "systemd-network";
}
