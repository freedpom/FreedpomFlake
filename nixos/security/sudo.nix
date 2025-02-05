{
  lib,
  config,
  ...
}:
let
  cfg = config.ff.security.sudo;
in
{
  options.ff.security.sudo = {
    enable = lib.mkEnableOption "Enable sudo-rs instead of regular sudo";
  };

  config = lib.mkIf cfg.enable {
    security = {
      sudo.enable = lib.mkForce false;
      sudo-rs = {
        enable = true;
        execWheelOnly = true;
      };
    };
  };
}
