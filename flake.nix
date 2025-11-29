{
  description = "NixOS and Home-Manager presets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix2container.url = "github:nlewo/nix2container";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
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
          ./modules/nixos
          ./packages
        ];
        flake = {
          inherit fmtModule;
          homeModules = {
            freedpomFlake = ./modules/home-manager;
          };
        };
      }
    );
}
