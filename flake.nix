{
  description = "Kloenk's NixOS configuration";

  inputs.nixpkgs = {
    type = "github";
    owner = "nixos";
    repo = "nixpkgs";
    #    ref = "from-unstable";
  };

  inputs.nix = {
    type = "github";
    owner = "nixos";
    repo = "nix";
    #inputs.nixpkgs.follows = "/nixpkgs"; # broken
  };

  inputs.moodlepkgs = {
    type = "github";
    owner = "kloenk";
    repo = "moodlepkgs";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.mail-server = {
    type = "gitlab";
    owner = "simple-nixos-mailserver";
    repo = "nixos-mailserver";
    ref = "master";
  };

  inputs.kloenk-www = {
    type = "gitlab";
    owner = "kloenk";
    repo = "www";
    host = "cyberchaos.dev";
  };

  inputs.dns = {
    type = "github";
    owner = "kirelagin";
    repo = "dns.nix";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.darwin = {
    type = "github";
    owner = "lnl7";
    repo = "nix-darwin";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.mac-app-util = {
    url = "github:hraban/mac-app-util";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote/v0.3.0";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  /* inputs.leona = {
       url = "gitlab:leona/nixfiles?host=cyberchaos.dev";
       inputs.nixpkgs.follows = "/nixpkgs";
       inputs.mailserver.follows = "/mail-server";
     };
  */

  /* inputs.vika = {
       type = "sourcehut";
       owner = "~vikanezrimaya";
       repo = "nix-flake";
     };
  */

  inputs.colmena = {
    url = "github:zhaofengli/colmena";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.jlly = {
    url = "github:kloenk/jlly_bot";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.fleet_bot = {
    url = "github:fleetyards/fleet_bot";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.p3tr = {
    url = "github:kloenk/p3tr";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.sysbadge = {
    url = "gitlab:kloenk/sysbadge?host=cyberchaos.dev";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.oxalica = {
    url = "github:oxalica/rust-overlay";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.bcachefs-tools = {
    url = "git+https://evilpiepirate.org/git/bcachefs-tools.git";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.pre-commit = {
    url = "github:cachix/pre-commit-hooks.nix";
    inputs.nixpkgs.follows = "/nixpkgs";
    inputs.nixpkgs-stable.follows = "/nixpkgs";
  };

  inputs.kloenk-cv = {
    url = "gitlab:kloenk/cv?host=cyberchaos.dev";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix, moodlepkgs, mail-server, kloenk-www
    , dns, darwin, sops-nix, colmena, jlly, fleet_bot, p3tr, sysbadge, oxalica
    , disko, ... }:
    let
      overlayCombined = system: [
        #nix.overlays.default
        #(final: prev: { nix = nix.packages.${system}.nix; })
        #home-manager.overlay
        self.overlays.kloenk
        self.overlays.iso
        moodlepkgs.overlay
        kloenk-www.overlay
        colmena.overlay
        jlly.overlays.default
        fleet_bot.overlays.default
        p3tr.overlays.default
        sysbadge.overlays.sysbadge
        oxalica.overlays.default
        inputs.bcachefs-tools.overlays.default
        (final: prev: { bcachefs-tools = final.bcachefs; })
      ];

      systems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      forSomeSystems = systems: f:
        nixpkgs.lib.genAttrs systems (system: f system);
      forAllSystems = f: forSomeSystems systems f;
      #forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # Memoize nixpkgs for different platforms for efficiency.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = (overlayCombined system);
        });

      darwinHosts = nixpkgs.lib.filterAttrs
        (name: host: if host ? darwin then host.darwin else false)
        (import ./darwin { });

      # patche modules
      /* patchModule = system: {
           disabledModules =
             [
               "services/games/minecraft-server.nix"
               "tasks/auto-upgrade.nix"
               "services/web-apps/wordpress.nix"
               "services/web-apps/restya-board.nix"
             ];
           imports = [
           ];
           nixpkgs.overlays = [ (overlays system) nix.overlays.default ];
         };
      */

    in {
      overlays.kloenk = final: prev:
        (import ./pkgs/overlay.nix inputs final prev);
      overlays.default = self.overlays.kloenk;
      overlays.iso = final: prev: {
        iso = (nixpkgs.lib.nixosSystem {
          system = final.stdenv.targetPlatform.system;
          modules = [
            (import ./profiles/iso.nix)
            {
              nixpkgs.overlays =
                (overlayCombined final.stdenv.targetPlatform.system);
            }
            sops-nix.nixosModules.sops
            colmena.nixosModules.deploymentOptions
            inputs.home-manager.nixosModules.home-manager
            self.nixosModules.kloenk

            self.nixosModules.nftables
            self.nixosModules.helix

            # vika.nixosModules.colorfulMotd # TODO: fix
          ];
          specialArgs.inputs = inputs;
          specialArgs.self = self;
        }).config.system.build.isoImage;
      };

      legacyPackages = forAllSystems (system: nixpkgsFor.${system});

      packages = (forAllSystems (system: { }))
        // (forSomeSystems [ "x86_64-linux" "aarch64-linux" ]
          (system: { inherit (nixpkgsFor.${system}) iso; }));

      apps = forAllSystems (system: {
        update-ssh-keys = {
          type = "app";
          program = toString nixpkgsFor.${system}.update-ssh-host-keys;
        };
        update-dns = {
          type = "app";
          program = let
            pkgs = nixpkgsFor.${system};
            script = pkgs.writeShellScriptBin "update-dns" ''
              ${pkgs.kloenk-octodns}/bin/octodns-sync --config-file ${pkgs.kloenk-octodns-config} $@
            '';
          in "${script}/bin/update-dns";
        };
      });

      nixosConfigurations =
        let hive = inputs.colmena.lib.makeHive self.outputs.colmena;
        in hive.nodes;

      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = (overlayCombined "x86_64-linux");
          };
          nodeNixpkgs.ktest = import nixpkgs {
            system = "aarch64-linux";
            overlays = (overlayCombined "aarch64-linux");
          };
          nodeNixpkgs.varda = import nixpkgs {
            system = "aarch64-linux";
            overlays = (overlayCombined "aarch64-linux");
          };
          nodeNixpkgs.gimli = import nixpkgs {
            system = "aarch64-linux";
            overlays = (overlayCombined "aarch64-linux");
          };
          nodeNixpkgs.sc-social = import nixpkgs {
            system = "aarch64-linux";
            overlays = (overlayCombined "aarch64-linux");
          };
          nodeNixpkgs.gloin = import nixpkgs {
            system = "x86_64-linux";
            overlays = (overlayCombined "x86_64-linux");
          };
          #allowApplyAll = false;

          specialArgs.inputs = inputs;
          specialArgs.self = self;
        };

        defaults = { pkgs, ... }: {
          disabledModules = [
            "services/games/minecraft-server.nix"
            "services/web-apps/wordpress.nix"
          ];
          imports = [
            ./profiles/base/nixos
            #home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            self.nixosModules.matrix-sliding-sync
            jlly.nixosModules.default
            fleet_bot.nixosModules.default
            p3tr.nixosModules.default
            disko.nixosModules.default

            self.nixosModules.nftables
            self.nixosModules.deluge2
            #self.nixosModules.firefox
            self.nixosModules.wordpress
            self.nixosModules.transient
            self.nixosModules.helix
            self.nixosModules.kloenk
            self.nixosModules.vouch-proxy
            self.nixosModules.backups

            # TODO: 
            #vika.nixosModules.colorfulMotd
            #vika.nixosModules.secureSSHClient

            inputs.home-manager.nixosModules.default
          ];
          # disable home-manager manpage (breaks hydra see https://github.com/rycee/home-manager/issues/1262)
          #home-manager.users.kloenk.manual.manpages.enable = false;

          environment.systemPackages = [ # pkgs.colmena
          ];

          k.ports = import ./lib/ports.nix;

          nix.channel.enable = false;

          deployment = {
            buildOnTarget = true;
            allowLocalDeployment = true;
            targetPort = 62954;
            targetUser = "kloenk";
          };
        };

        # hetzner
        varda = { pkgs, node, ... }: {
          deployment = {
            targetHost = "varda.kloenk.de";
            tags = [ "hetzner" "falkenstein" "remote" ];
          };

          imports = [
            ./hosts/varda
            (import (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix"))
          ];
        };
        gimli = { pkgs, nodes, ... }: {
          deployment = {
            targetHost = "gimli.kloenk.de";
            tags = [ "hetzner" "falkenstein" "remote" ];
          };

          imports = [
            ./hosts/gimli
            mail-server.nixosModules.mailserver
            (import (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix"))
          ];
        };

        sc-social = { pkgs, nodes, ... }: {
          deployment = {
            targetHost = "starcitizen.social";
            tags = [ "hetzner" "falkenstein" "remote" "fleetyards" ];
          };

          imports = [
            ./hosts/sc-social
            self.nixosModules.restic-backups
            (import (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix"))
          ];
        };

        # USee
        moodle-usee = { pkgs, nodes, ... }: {
          deployment.targetHost = "moodle-usee.kloenk.de";
          deployment.tags = [ "usee" "remote" ];

          imports = [
            ./hosts/moodle-usee
            (import (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix"))
          ];
        };

        # Pony
        thrain = { pkgs, nodes, ... }: {
          deployment.targetHost = "thrain.net.kloenk.de";
          deployment.tags = [ "pony" "local" ];

          imports = [ ./hosts/thrain ];

          # ZFS kernel
          nixpkgs.config.allowBroken = true;
        };
        elrond = { pkgs, nodes, ... }: {
          deployment.targetHost = "elrond.net.kloenk.de";
          deployment.tags = [ "pony" "local" ];

          imports = [ ./hosts/elrond ];
          users.users.kloenk.packages =
            [ inputs.nixpkgs.legacyPackages.x86_64-linux.nil ];
        };

        gloin = { pkgs, nodes, ... }: {
          deployment.targetHost = "gloin.net.kloenk.de";
          deployment.tags = [ "local" ];

          imports = [ ./hosts/gloin ];
          users.users.kloenk.packages =
            [ inputs.nixpkgs.legacyPackages.x86_64-linux.nil ];
        };

        ktest = { pkgs, nodes, ... }: {
          deployment.targetHost = "192.168.64.101";
          deployment.tags = [ "vm" "frodo" ];

          imports = [
            ./hosts/ktest
            (import (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix"))
          ];
        };
      };

      nixosModules = {
        ferm2 = import ./modules/ferm2;
        deluge2 = import ./modules/deluge.nix;
        autoUpgrade = import ./modules/upgrade;
        #firefox = import ./modules/firefox;
        #secrets = import ./modules/secrets;
        transient = import ./modules/transient;
        nftables = import ./modules/nftables;
        kloenk = import ./modules/kloenk;

        restya-board = import ./modules/restya-board;
        restic-backups = import ./modules/restic-backups.nix;

        wordpress = import ./modules/wordpress.nix;
        matrix-sliding-sync = import ./modules/matrix-sliding-sync;
        helix = import ./modules/helix;
        vouch-proxy = import ./modules/vouch-proxy;
        backups = import ./modules/backups;
      };

      darwinModules = {
        epmd = import ./modules/darwin/epmd;
        git = import ./modules/darwin/git.nix;
        helix = import ./modules/helix/darwin.nix;
      };

      darwinConfigurations = (nixpkgs.lib.mapAttrs (name: host:
        (darwin.lib.darwinSystem {
          system = host.system;
          modules = [
            { nixpkgs.overlays = (overlayCombined host.system); }
            ./profiles/base/darwin
            #home-manager.nixosModules.home-manager
            (import (./darwin + "/${name}/darwin.nix"))
            sops-nix.darwinModules.sops

            self.darwinModules.epmd
            self.darwinModules.git
            self.darwinModules.helix

            inputs.home-manager.darwinModules.home-manager
            inputs.mac-app-util.darwinModules.default
            ({ pkgs, config, inputs, ... }: {
              home-manager.users.kloenk.imports =
                [ inputs.mac-app-util.homeManagerModules.default ];
            })
          ];
          specialArgs.inputs = inputs;
          specialArgs.self = self;
        })) darwinHosts);

      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          kernel = pkgs.callPackage ./dev/kernel.nix { };
          zephyr =
            pkgs.callPackage ./dev/zephyr.nix { python3 = pkgs.python310; };
          default = pkgs.mkShell {
            nativeBuildInputs = [ pkgs.nixfmt pkgs.colmena pkgs.sops ];
            inherit (self.checks.${system}.pre-commit) shellHook;
          };
        });

      formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt);

      templates = {
        hm = {
          path = ./templates/hm;
          description = "Template using home manager";
        };
      };

      checks = forAllSystems (system: {
        pre-commit = inputs.pre-commit.lib.${system}.run {
          src = self;
          hooks = { nixfmt.enable = true; };
        };
      });
    };
  nixConfig = {
    extra-substituters = [ "https://kloenk.cachix.org" ];
    extra-trusted-public-keys =
      [ "kloenk.cachix.org-1:k52XSkCLOxnmEnjzuedYOzf0MtQp8P3epqOmAlCHYpc=" ];
  };
}
