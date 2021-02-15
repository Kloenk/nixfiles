{ config, lib, pkgs, ... }:

{
  fileSystems."/var/lib/factorio" = {
    device = "/persist/data/factorio";
    options = [ "bind" ];
  };

  services.factorio = {
    enable = true;
    mods = [ ];
    saveName = "multi";
    game-name = "Kloenk's factorio server";
    extraSettings = {
      admins = [
        "Kloenk"
      ];
    };
    autosave-interval = 5;
    game-password = "very-secure-password"; # todo move out of config
  };

  systemd.services.factorio.serviceConfig.RequireMountsFor = "/var/lib/factorio";
  systemd.services.factorio.serviceConfig.ReadWritePaths = "/persist/data/factorio";
}

