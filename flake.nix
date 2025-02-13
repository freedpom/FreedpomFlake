{
  description = "Collection of NixOS and Home-Manager presets";

  inputs = {
    treefmt-nix.url = "github:numtide/treefmt-nix";
    devshell.url = "github:numtide/devshell";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";

    # Flake infrastructure
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.devshell.flakeModule
        inputs.flake-root.flakeModule
        inputs.git-hooks-nix.flakeModule
        inputs.home-manager.flakeModules.home-manager
      ];

      # Per-system configuration
      perSystem =
        { config, pkgs, ... }:
        {
          # Code formatting and linting setup
          treefmt.config = {
            inherit (config.flake-root) projectRootFile;
            flakeCheck = false;
            programs = {
              # Nix formatting tools
              nixfmt = {
                enable = true;
                package = pkgs.nixfmt-rfc-style;
              };
              statix.enable = true; # Static analysis for Nix
              deadnix.enable = true; # Detect dead code in Nix

              typos.enable = true;
              typos.excludes = [
                "*.png"
                "*.yaml"
                "modules/nixos/packages/nvf.nix"
              ];

              # Additional formatters
              actionlint.enable = true; # GitHub Actions linter
              mdformat.enable = true; # Markdown formatter
              yamlfmt.enable = true;
              shfmt.enable = true;
            };
          };

          # Development environment configuration
          devshells.default = {
            name = "nixdev";
            motd = ""; # Message of the day
            packages = [
              pkgs.nil # Nix Language Server
              config.treefmt.build.wrapper
            ] ++ (pkgs.lib.attrValues config.treefmt.build.programs);
          };

          # Git pre-commit hooks
          pre-commit.settings.hooks = {
            treefmt = {
              enable = true;
              package = config.treefmt.build.wrapper;
            };
            statix = {
              enable = true;
              package = config.treefmt.build.programs.statix;
            };
          };
        };
      flake = {
        nixosModules = {
          freedpomFlake = ./nixos;
        };
        homeManagerModules = {
          freedpomFlake = ./home-manager;
        };
      };
    };
}
