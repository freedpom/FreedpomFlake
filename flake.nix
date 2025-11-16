{
  description = "NixOS and Home-Manager presets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      let
        inherit (flake-parts.lib) importApply;
        fmtModule = importApply ./fmt-module.nix;
      in
      {
        systems = [
          "aarch64-linux"
          "x86_64-linux"
        ];

        imports = [
          fmtModule
          inputs.home-manager.flakeModules.home-manager
        ];
        flake = {
          inherit fmtModule;
          homeModules = {
            freedpomFlake = ./modules/home-manager;
          };
          nixosModules = {
            freedpomFlake = ./modules/nixos;
          };
        };
      }
    );
}
