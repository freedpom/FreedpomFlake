{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ff.system.rust-utils.uutils;
in
{
  options.ff.system.rust-utils.uutils.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable uutils rust replacement of gnu coreutils";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      uutils-coreutils
    ];
  };
}
