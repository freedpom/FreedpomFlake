{
  description = "NixOS and Home-Manager presets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      _:
      let
        fmtModule = flake-parts.lib.importApply ./modules/flake/fmt-module.nix { inherit inputs; };
      in
      {
        systems = [
          "aarch64-linux"
          "x86_64-linux"
        ];

        imports = [
          fmtModule
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
