{
  description = "NixOS and Home-Manager presets";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";

    fpFmt = {
      url = "github:freedpom/FreedpomFormatter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      imports = [
        inputs.fpFmt.flakeModule
        inputs.home-manager.flakeModules.home-manager
      ];

      flake = {
        homeModules = {
          freedpomFlake = ./home-manager;
        };
        nixosModules = {
          freedpomFlake = ./nixos;
        };
      };
    };
}
