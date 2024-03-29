{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.services.xonotic;

  toCfg = lib.generators.toKeyValue {
    mkKeyValue = lib.generators.mkKeyValueDefault {
      mkValueString = v:
        if v == true then
          "1"
        else if v == false then
          "0"
        else if builtins.isString v then
          ''"${v}"''
        else
          lib.generators.mkValueStringDefault { } v;
    } " ";
  };

  toConfig = config: toCfg config;

  writeConfig = { config, extraConfig }:
    pkgs.writeText "server.cfg" ''
      ${toConfig config}
      ${extraConfig}
    '';

  serverModule = types.submodule ({ name, ... }: {
    options = {
      config = mkOption {
        type = types.attrsOf (types.oneOf [ types.str types.int types.bool ]);
        description = ''
          server config, see
          <link xlink:href="https://github.com/xonotic/xonotic/wiki/basic-server-configuration">https://github.com/xonotic/xonotic/wiki/basic-server-configuration</link>
          and
          <link xlink:href="https://xonotic.org/tools/cacs/#0a/0/">https://xonotic.org/tools/cacs/#0a/0/</link>
        '';
        default = {
          hostname = name;
          port = 26000;
        };
      };

      extraConfig = mkOption {
        type = types.lines;
        description = "extra config written to server.cfg";
        example = ''
          duel
        '';
        default = "";
      };

      preStart = mkOption {
        type = types.lines;
        description = "command to execute before starting xonotic";
        example = "ln -s ${
            ./warfare.pk3
          } ./data/maps"; # TODO: validate on how to install a map
        default = "";
      };

      openFirewall = (mkEnableOption "open udp port for xonotic") // {
        default = true;
      };

      package = mkOption {
        type = types.package;
        description = "xonotic package";
        default = pkgs.xonotic-dedicated;
      };
    };
  });
in {
  options = {
    services.xonotic = {
      servers = mkOption {
        type = types.attrsOf serverModule;
        default = { };
        description = "available servers";
      };

      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/xonotic";
        description = "user home of the xonotic server user";
      };
    };
  };

  config = mkIf (cfg.servers != { }) {
    users.users.xonotic = {
      description = "xonetic server service user";
      home = cfg.dataDir;
      createHome = true;
      isSystemUser = true;
    };

    networking.firewall.allowedUDPPorts = let
      firewallServers =
        lib.filterAttrs (name: host: host.openFirewall) cfg.servers;
    in lib.mapAttrsToList (name: host: host.config.port) cfg.servers;

    systemd.tmpfiles.rules =
      let makeRule = name: host: "Q ${cfg.dataDir}/${name} 750 xonotic - - -";
      in lib.mapAttrsToList (name: host: makeRule name host) cfg.servers;

    systemd.services = (lib.mapAttrs' (name: config:
      let userDir = "${cfg.dataDir}/${name}";
      in lib.nameValuePair "xonotic-${name}" {
        description = "Xonotic server ${config.config.hostname}";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          ExecStart =
            "${config.package}/bin/xonotic-dedicated -userdir ${userDir}";
          Restart = "always";
          User = "xonotic";
          WorkingDirectory = userDir;
        };

        preStart =
          let configFile = writeConfig { inherit (config) config extraConfig; };
          in ''
            mkdir -p ${userDir}/data/
            ln -sf ${configFile} ${userDir}/data/server.cfg
            chown -R xonotic ${userDir}

            ${config.preStart}
          '';
      }) cfg.servers);
  };
}
