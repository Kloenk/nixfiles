{ pkgs, ... }: {
  fileSystems."/var/lib/youtrack" = {
    device = "/persist/data/youtrack";
    fsType = "none";
    options = [ "bind" ];
  };

  services.youtrack = {
    enable = true;
    environmentalParameters.listen-port = 7012;
    virtualHost = "yt.kloenk.dev";
    package = pkgs.youtrack;
  };

  services.nginx.virtualHosts."yt.kloenk.dev" = {
    enableACME = true;
    kTLS = true;
    forceSSL = true;
  };

  backups.youtrack = {
    user = "youtrack";
    paths = [ "/persist/data/youtrack/backups" ];
  };
}
