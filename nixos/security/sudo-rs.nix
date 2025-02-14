{ lib, config, ... }:
let
  cfg = config.ff.security.sudo-rs;
in
{
  options.ff.security.sudo-rs = {
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
