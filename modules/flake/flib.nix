{ inputs, lib, ... }:
{
  options.flake = inputs.flake-parts.lib.mkSubmoduleOptions {
    flib = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "flib helper functions";
    };
  };
  config.flake.flib = rec {
    mkHosts =
      dir:
      let
        hostnames = lib.attrNames (
          lib.filterAttrs (n: v: v == "directory" && (builtins.readDir "${dir}/${n}") ? "default.nix") (
            builtins.readDir dir
          )
        );
      in
      lib.genAttrs hostnames (
        hostname:
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              inputs
              hostname
              ;
          };
          modules = [ "${dir}/${hostname}" ];
        }
      );
    mkHostsWithModules = dir: myModules: {inputs, ...}:
      let
        hostnames = lib.attrNames (
          lib.filterAttrs (n: v: v == "directory" && (builtins.readDir "${dir}/${n}") ? "default.nix") (
            builtins.readDir dir
          )
        );
      in
      lib.genAttrs hostnames (
        hostname:
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              # inputs
              hostname
              ;
          };
          modules = [ "${dir}/${hostname}" ] ++ myModules;
        }
      );
  };
}
