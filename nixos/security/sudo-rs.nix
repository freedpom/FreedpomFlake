{ lib, config, ... }:
let
  cfg = config.ff.security.sudo-rs;
in
{
  # Configuration options for sudo-rs
  options.ff.security.sudo-rs = {
    enable = lib.mkEnableOption "Enable sudo-rs instead of regular sudo";
  };

  config = lib.mkIf cfg.enable {
    # Security configuration
    security = {
      # Disable standard sudo
      sudo.enable = lib.mkForce false;
      
      # Enable sudo-rs with security settings
      sudo-rs = {
        enable = true;
        execWheelOnly = true;
      };
    };
  };
}
