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
          editor = lib.mkForce false;
          consoleMode = "auto";
          enable = true;
          graceful = lib.mkDefault true;
          configurationLimit = lib.mkDefault 10;
        };
        efi = {
          efiSysMountPoint = "/boot";
          canTouchEfiVariables = true;
        };
      };
      kernelParams = [
        "quiet"
        "loglevel=3"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
        "splash"
        "boot.shell_on_fail"
        "systemd.show_status=auto"
        # "vga=current"
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
