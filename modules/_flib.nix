{ inputs, lib, ... }:
{
  options.flake = inputs.flake-parts.lib.mkSubmoduleOptions {
    flib = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "flib helper functions";
    };
  };
  config.flake.flib = {
  };
}
