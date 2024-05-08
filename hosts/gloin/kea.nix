{ pkgs, ... }:

let
  hostname = "192.168.45.1";

  ipxeConfig = {
    client-classes = [
      {
        "name" = "XClient_iPXE";
        "test" = "substring(option[77].hex,0,4) == 'iPXE'";
        "boot-file-name" = "http://${hostname}/nixos.ipxe";
      }
      {
        "name" = "UEFI-32-1";
        "test" = "substring(option[60].hex,0,20) == 'PXEClient:Arch:00006'";
        "boot-file-name" = "ipxe.efi";
      }
      {
        "name" = "UEFI-32-2";
        "test" = "substring(option[60].hex,0,20) == 'PXEClient:Arch:00002'";
        "boot-file-name" = "ipxe.efi";
      }
      {
        "name" = "UEFI-64-1";
        "test" = "substring(option[60].hex,0,20) == 'PXEClient:Arch:00007'";
        "boot-file-name" = "ipxe.efi";
      }
      {
        "name" = "UEFI-64-2";
        "test" = "substring(option[60].hex,0,20) == 'PXEClient:Arch:00008'";
        "boot-file-name" = "ipxe.efi";
      }
      {
        "name" = "UEFI-64-3";
        "test" = "substring(option[60].hex,0,20) == 'PXEClient:Arch:00009'";
        "boot-file-name" = "ipxe.efi";
      }
      {
        "name" = "Legacy";
        "test" = "substring(option[60].hex,0,20) == 'PXEClient:Arch:00000'";
        "boot-file-name" = "undionly.kpxe";
      }
    ];
  };
in {
  fileSystems."/var/lib/private/kea" = {
    device = "/persist/data/kea";
    fsType = "none";
    options = [ "bind" ];
  };

  networking.firewall.allowedUDPPorts = [ 69 ];

  services.kea = {
    dhcp4 = {
      enable = true;
      settings = {
        inherit (ipxeConfig) client-classes;

        lease-database = {
          name = "/var/lib/kea/dhcp4.leases";
          persist = false;
          type = "memfile";
        };
        rebind-timer = 2000;
        renew-timer = 1000;
        valid-lifetime = 4000;

        interfaces-config.interfaces = [ "dhcp0" ];
        subnet4 = [{
          pools = [{ pool = "192.168.45.50 - 192.168.45.150"; }];
          subnet = "192.168.45.0/24";
        }];
      };
    };
  };

  services.nginx.virtualHosts."192.168.45.1" = {
    default = true;
    listenAddresses = [ "192.168.45.1" ];
    root = "/persist/data/secunet/public/";
    locations."/" = { extraConfig = "autoindex on;"; };
  };

  services.atftpd = {
    enable = true;
    extraOptions = [ "--bind-address 192.168.45.1" ];
    root = "${pkgs.ipxe.override {
      embedScript = pkgs.writeText "embed.ipxe" ''
        #!ipxe
        dhcp
        chain http://192.168.45.1/nixos.ipxe gwp.server=192.168.45.1
      '';
    }}";
  };
}
