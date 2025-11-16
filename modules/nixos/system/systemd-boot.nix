{
  lib,
  config,
  ...
}:
let
  cfg = config.ff.system.systemd-boot;
in
{
  options.ff.system.systemd-boot = {
    enable = lib.mkEnableOption "Enable systemd-boot";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      plymouth = {
        enable = true;
      };
      loader = {
        timeout = lib.mkDefault 0;
        systemd-boot = {
          editor = false;
          enable = true;
          graceful = lib.mkDefault true;
          configurationLimit = lib.mkDefault 10;
        };
        efi = {
          efiSysMountPoint = "/boot";
          canTouchEfiVariables = lib.mkDefault false;
        };
      };
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "loglevel=3"
        "systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
        "vga=current"
      ];
      consoleLogLevel = lib.mkForce 0;
      initrd = {
        includeDefaultModules = lib.mkDefault false;

        verbose = false;
        systemd.enable = true;
      };
    };
  };
}
