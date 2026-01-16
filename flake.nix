{
  description = "NixOS and Home-Manager presets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix2container.url = "github:nlewo/nix2container";
    wm-hypr.url = "github:hyprwm/Hyprland?ref=v0.53.1";
    wm-niri.url = "github:sodiboo/niri-flake";
    home-manager.url = "github:nix-community/home-manager";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      let
        fmtModule = flake-parts.lib.importApply ./modules/flake/formatModule.nix { inherit inputs; };
      in
      {
        systems = [
          "aarch64-linux"
          "x86_64-linux"
        ];

        imports = [
          fmtModule
          inputs.home-manager.flakeModules.home-manager
          inputs.flake-parts.flakeModules.easyOverlay
          inputs.flake-parts.flakeModules.partitions
          ./modules/home-manager
          ./modules/nixos
          ./packages
          ./modules/flake/windowManagers
          ./modules/flake/default
        ];
        flake = {
          inherit fmtModule;
        };
      }
    );
}
