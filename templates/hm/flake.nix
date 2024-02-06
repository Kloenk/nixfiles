{
  description = "Home Manager template with kloenk opinions";

  inputs.nixpkgs = { url = "github:nixos/nixpkgs/master"; };

  inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "/nixpkgs";
    inputs.nixpkgs-stable.follows = "/nixpkgs";
  };

  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "/nixpkgs";
  };

  inputs.colmena = {
    url = "github:zhaofengli/colmena";
    inputs.nixpkgs.follows = "/nixpkgs";
    inputs.stable.follows = "/nixpkgs";
  };

  inputs.pre-commit = {
    url = "github:cachix/pre-commit-hooks.nix";
    inputs.nixpkgs.follows = "/nixpkgs";
    inputs.nixpkgs-stable.follows = "/nixpkgs";
  };

  outputs =
    inputs@{ self, nixpkgs, sops-nix, home-manager, colmena, pre-commit }:
    let
      systems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      forSomeSystems = systems: f:
        nixpkgs.lib.genAttrs systems (system: f system);
      forAllSystems = f: forSomeSystems systems f;

      # Memoize nixpkgs for different platforms for efficiency.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ colmena.overlay ];
        });
    in {
      # reexport for convenience
      legacyPackages = nixpkgsFor;

      nixosConfigurations =
        (inputs.colmena.lib.makeHive self.outputs.colmena).nodes;

      colmena = {
        meta = {
          nixpkgs = import nixpkgs { system = "x86_64-linux"; };

          specialArgs.inputs = inputs;
          specialArgs.self = self;
        };

        defaults = { ... }: {
          imports = [
            ./profiles/base

            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
          ];

          nix.channel.enable = false;
        };
      };

      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [ nixfmt pkgs.colmena sops ];
            inherit (self.checks.${system}.pre-commit) shellHook;
          };
        });

      formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt);

      checks = forAllSystems (system: {
        pre-commit = pre-commit.lib.${system}.run {
          src = self;
          hooks = { nixfmt.enable = true; };
        };
      });
    };
}
