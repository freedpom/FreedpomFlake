{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ff.system.rust-utils.fuc;
in
{
  options.ff.system.rust-utils.fuc.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Fast Unix Commands";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      fuc
    ];
  };
}
