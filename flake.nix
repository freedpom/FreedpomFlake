{
  description = "Collection of NixOS and Home-Manager presets";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      flake = {
        nixosModules = {
          freedpomFlake = ./nixos;
        };
      };
    };
}
