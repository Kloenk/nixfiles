{
  description = "Kloenk's Nixos configuration";

  inputs.home-manager = {
    type = "github";
    owner = "nix-community";
    repo = "home-manager";
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
    inputs.nixpkgs.follows = "/nixpkgs"; # broken
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

  inputs.website = {
    type = "git";
    url = "https://git.petabyte.dev/kloenk/website.git";
    flake = false;
    #ref = "lexbeserious";
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

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  inputs.rtmp-auth = {
    url = "git+https://git.kloenk.dev/usee/rtmp-auth?ref=main";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.workadventure = {
    type = "gitlab";
    owner = "kloenk";
    repo = "workadventure-nix";
    ref = "overlay";
    flake = false;
  };

  inputs.event_start = {
    type = "github";
    owner = "holbeh";
    repo = "eventstart";
    ref = "postshow";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.office-map = {
    type = "github";
    owner = "holbeh";
    repo = "office-map";
    flake = false;
  };

  outputs = inputs@{ self, nixpkgs, nix, moodlepkgs, hydra, home-manager, mail-server
    , website, dns, grahamc-config, rtmp-auth, ... }:
    let

      overlayCombined = system: [
        nix.overlay
        #home-manager.overlay
        self.overlay
        (overlays system)
        rtmp-auth.overlay
        moodlepkgs.overlay
      ];

      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

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
          [
            "services/games/minecraft-server.nix"
            "tasks/auto-upgrade.nix"
            "services/networking/pleroma.nix"
            "services/web-apps/wordpress.nix"
          ];
        imports = [
          self.nixosModules.autoUpgrade
        ];
        nixpkgs.overlays = [ (overlays system) nix.overlay (import (inputs.workadventure + "/overlay.nix"))];
      };

      overlays = system: final: prev: {
        utillinuxMinimal = final.util-linuxMinimal;
      };

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
        } // { });

      legacyPackages = forAllSystems
        (system: nixpkgsFor.${system});


      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) home-manager wallpapers;
      });

      nixosConfigurations = (nixpkgs.lib.mapAttrs (name: host:
        (nixpkgs.lib.nixosSystem rec {
          system = host.system;
          modules = [
            {
              nixpkgs.overlays = [
                #home-manager.overlay
                self.overlay
              ] ++ (overlayCombined host.system);
            }
            nixpkgs.nixosModules.notDetected
            home-manager.nixosModules.home-manager
            (import (./configuration + "/hosts/${name}/configuration.nix"))
            self.nixosModules.secrets
            self.nixosModules.nftables
            self.nixosModules.deluge2
            self.nixosModules.firefox
            self.nixosModules.pleroma
            self.nixosModules.wordpress
            self.nixosModules.transient
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
              [ mail-server.nixosModules.mailserver ]
            else
              [ ]);
        })) nixosHosts);

      nixosModules = {
        ferm2 = import ./modules/ferm2;
        deluge2 = import ./modules/deluge.nix;
        autoUpgrade = import ./modules/upgrade;
        firefox = import ./modules/firefox;
        secrets = import ./modules/secrets;
        pleroma = import ./modules/pleroma;
        transient = import ./modules/transient;
        nftables = import ./modules/nftables;

        wordpress = import ./modules/wordpress.nix;
      };

      # hydra jobs
      hydraJobs = {
        /*configurations = let
          lib = nixpkgs.lib;
         in lib.mapAttrs' (name: config:
          lib.nameValuePair name config.config.system.build.toplevel)
         self.nixosConfigurations;*/
        packages = self.packages;
      };
    };
}

