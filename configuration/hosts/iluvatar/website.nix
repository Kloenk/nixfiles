{ config, lib, inputs, ... }:

let
  commonHeaders = lib.concatStringsSep "\n"
    (lib.filter (line: lib.hasPrefix "add_header" line)
      (lib.splitString "\n" config.services.nginx.commonHttpConfig));
in {
  services.nginx.virtualHosts = {
    /*"lexbeserious.kloenk.dev" = {
      enableACME = true;
      forceSSL = true;
      root = inputs.website;
      locations."/".index = "lexbeserious.html";
      extraConfig = ''
        ${commonHeaders}
        add_header Content-Security-Policy "default-src 'self'; frame-ancestors 'none'; object-src 'none'" always;
        add_header Cache-Control $cacheable_types;
      '';
    };*/
    "kloenk.dev" = {
      enableACME = true;
      forceSSL = true;
      root = inputs.website;
      locations."/public/".alias = "/persist/data/public/";
      extraConfig = ''
        ${commonHeaders}
        add_header Content-Security-Policy "default-src 'self'; frame-ancestors 'none'; object-src 'none'" always;
        add_header Cache-Control $cacheable_types;
      '';
    };
    "kloenk.de" = {
      enableACME = true;
      forceSSL = true;
      root = inputs.website;
      locations."/public/".alias = "/persist/data/public/";
      extraConfig = ''
        ${commonHeaders}
        add_header Content-Security-Policy "default-src 'self'; frame-ancestors 'none'; object-src 'none'" always;
        add_header Cache-Control $cacheable_types;
      '';
    };
    "iluvatar.kloenk.de" = {
      locations."/public/".alias =
        config.services.nginx.virtualHosts."kloenk.de".locations."/public/".alias;
    };
    "dev.matrix-push.kloenk.dev" = {
      locations."/".proxyPass = "http://localhost:5000/";
    };
  };
}
