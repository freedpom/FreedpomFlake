{ inputs, lib, ... }:
{
  options.flake = inputs.flake-parts.lib.mkSubmoduleOptions {
    flib = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      description = "flib helper functions";
    };
  };
  config.flake.flib = rec {
    mkHosts =
      dir:
      {
        modules ? [ ],
        specialArgs ? { },
        ...
      }:
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
          modules = modules ++ [ "${dir}/${hostname}" ];
          specialArgs = specialArgs // {
            inherit hostname;
          };
        }
      );
  };
}
