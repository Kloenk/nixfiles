
{ config, pkgs, lib, ... }:

{
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "ca@kloenk.de";

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx = {
    package = pkgs.nginxMainline;
    enableReload = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    commonHttpConfig = ''
      server_names_hash_bucket_size 64;
      charset utf-8;
      map $scheme $hsts_header {
        https "max-age=31536000; includeSubdomains";
      }

      add_header Referrer-Policy "no-referrer-when-downgrade" always;
      add_header Strict-Transport-Security $hsts_header always;
      add_header X-Content-Type-Options "nosniff";
      add_header X-Frame-Options "SAMEORIGIN";
      add_header X-Xss-Protection "1; mode=block";

      access_log off;
    '';
    statusPage = true;
  };

  # Public file serving
  services.nginx.virtualHosts."${config.networking.hostName}.${config.networking.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/public/".alias = lib.mkDefault "/persist/data/public/";
    locations."/public/".extraConfig = "autoindex on;";
  };

  # Montioring
  services.telegraf.extraConfig.inputs = {
    nginx = { urls = [ "http://localhost/nginx_status" ]; };
  };
}