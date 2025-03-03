{
  description = "NixOS and Home-Manager presets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    fpFmt = {
      url = "github:freedpom/FreedpomFormatter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        inputs.home-manager.flakeModules.home-manager
        inputs.fpFmt.flakeModule
      ];

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
