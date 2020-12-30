{
  description = "Kloenk's Nixos configuration";

  inputs.home-manager = {
    type = "github";
    owner = "kloenk";
    repo = "home-manager";
    ref = "flake-overlay";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

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
    #ref = "flakes";
    inputs.nixpkgs.follows = "/nixpkgs"; # broken
  };

  inputs.hydra = {
    type = "github";
    owner = "nixos";
    repo = "hydra";
    #inputs.nixpkgs.follows = "/nixpkgs";
    #inputs.nix.inputs.nixpkgs.follows = "/nixpkgs";
    #inputs.nix.follows = "/nix";
  };

  inputs.mail-server = {
    #type = "git";
    #url = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver.git";
    type = "gitlab";
    owner = "simple-nixos-mailserver";
    repo = "nixos-mailserver";
    ref = "master";
    flake = false;
  };

  inputs.website = {
    type = "git";
    url = "https://git.petabyte.dev/kloenk/website.git";
    flake = false;
    ref = "lexbeserious";
  };

  inputs.nixos-org = {
    type = "github";
    owner = "nixos";
    repo = "nixos-org-configurations";
    flake = false;
  };

  inputs.dns = {
    type = "github";
    owner = "kloenk";
    #owner = "kirelagin";
    repo = "nix-dns";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.grahamc-config = {
    type = "github";
    owner = "grahamc";
    repo = "nixos-config";
    flake = false;
  };

  inputs.qyliss = {
    type = "git";
    url = "https://git.qyliss.net/nixlib";
    flake = false;
  };

  inputs.mixnix.url = "git+https://git.petabyte.dev/petabyteboy/mixnix";
  inputs.mixnix.flake = false;

  outputs = inputs@{ self, nixpkgs, nix, hydra, home-manager, mail-server
    , website, nixos-org, dns, grahamc-config, qyliss, ... }:
    let

      overlayCombined = system: [
        nix.overlay
        home-manager.overlay
        self.overlay
        (overlays system)
      ];

      systems = [ "x86_64-linux" ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # Memoize nixpkgs for different platforms for efficiency.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = (overlayCombined system);
        });

      # patche modules
      patchModule = system: {
        disabledModules =
          [ "services/games/minecraft-server.nix" "tasks/auto-upgrade.nix" ];
        imports = [
          self.nixosModules.autoUpgrade
        ];
        nixpkgs.overlays = [ (overlays system) nix.overlay ];
      };

      overlays = system: final: prev: {
        utillinuxMinimal = final.util-linuxMinimal;
        #hydra = builtins.trace "eval hydra" hydra.packages.${system}.hydra;
      };

      # iso image
      iso = system:
        (nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            (import ./lib/iso-image.nix)
            (import (nixpkgs
              + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"))
            nixpkgs.nixosModules.notDetected
            (import (nixpkgs + "/nixos/modules/installer/cd-dvd/channel.nix"))
            home-manager.nixosModules.home-manager
            (patchModule system)
            sourcesModule
            {
              # disable home-manager manpage (breaks hydra see https://github.com/rycee/home-manager/issues/1262)
              home-manager.users.kloenk.manual.manpages.enable = false;
            }
          ];
        }).config.system.build.isoImage;

      # evals
      hosts = import ./configuration/hosts { };
      nixosHosts = nixpkgs.lib.filterAttrs
        (name: host: if host ? nixos then host.nixos else false) hosts;
      sourcesModule = {
        _file = ./flake.nix;
        _module.args.inputs = inputs;
      };

    in {
      overlay = final: prev:
        let
          grahamc = (import (grahamc-config + "/packages/overlay.nix") {
            secrets = null;
          } final prev);
        in ((import ./pkgs/overlay.nix inputs final prev) // {
          inherit (grahamc)
            nixpkgs-maintainer-tools sway-cycle-workspace mutate wl-freeze
            resholve abathur-resholved;
        }
        // {
          inherit (import (qyliss + "/overlays/patches/nixpkgs-wayland") final prev) waylandPkgs;
        }
          // { });

      legacyPackages = forAllSystems
        (system: nixpkgsFor.${system} // { isoImage = (iso system); });

      packages = nixpkgs.lib.recursiveUpdate (forAllSystems (system: {
        inherit (self.legacyPackages.${system})
          isoImage home-manager redshift jblock deploy_secrets wallpapers;
      })) {
        "x86_64-linux" = {
          inherit (import ./lib/deploy.nix {
            pkgs = nixpkgsFor."x86_64-linux";
            lib = nixpkgsFor."x86_64-linux".lib;
            configurations = self.nixosConfigurations;
          })
            deploy;
        };
      };

      nixosConfigurations = (nixpkgs.lib.mapAttrs (name: host:
        (nixpkgs.lib.nixosSystem rec {
          system = host.system;
          modules = [
            { nixpkgs.overlays = [ home-manager.overlay self.overlay ]; }
            nixpkgs.nixosModules.notDetected
            home-manager.nixosModules.home-manager
            (import (./configuration + "/hosts/${name}/configuration.nix"))
            self.nixosModules.secrets
            self.nixosModules.nftables
            self.nixosModules.deluge2
            self.nixosModules.firefox
            self.nixosModules.pleroma
            sourcesModule
            {
              # disable home-manager manpage (breaks hydra see https://github.com/rycee/home-manager/issues/1262)
              home-manager.users.kloenk.manual.manpages.enable = false;
              #home-manager.users.pbb.manual.manpage.enable = false;
            }
            (patchModule host.system)
          ] ++ (if (if (host ? vm) then host.vm else false) then
            (nixpkgs.lib.singleton
              (import (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")))
          else
            [ ]) ++ (if (if (host ? mail) then host.mail else false) then
              [ (import (mail-server + "/default.nix")) ] # nixos-mailserver
            else
              [ ]);
        })) nixosHosts);

      nixosModules = {
        secrets = import ./modules/secrets;
        ferm2 = import ./modules/ferm2;
        nftables = import ./modules/nftables;
        deluge2 = import ./modules/deluge.nix;
        autoUpgrade = import ./modules/upgrade;
        firefox = import ./modules/firefox;
        pleroma = import ./modules/pleroma;
      };

      # apps
      apps = forAllSystems (system: {
        deploy_secrets = let
          app = self.packages.${system}.deploy_secrets.override {
            #passDir = toString (secrets + "/");
          };
        in {
          type = "app";
          program = "${app}";
        };
      });

      # hydra jobs
      hydraJobs = {
        isoImage.x86_64-linux = (iso "x86_64-linux");
        configurations = let lib = nixpkgs.lib;
        in lib.mapAttrs' (name: config:
          lib.nameValuePair name config.config.system.build.toplevel)
        self.nixosConfigurations;
        packages = self.packages;
      };
    };
}

