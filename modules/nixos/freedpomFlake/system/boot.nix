{
  lib,
  config,
  ...
}:

let
  cfg = config.ff.boot;
in
{
  options.ff.system.boot = {
    enable = lib.mkEnableOption "Enable the bootloader module.";
    quiet = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable quiet boot with reduced kernel and system logs.";
    };
    verbose = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable verbose boot with full kernel and system logs.";
    };
    splash = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the graphical splash screen.";
    };
    firmware = lib.mkOption {
      type = lib.types.enum [
        "uefi"
        "bios"
      ];
      default = "uefi";
      description = "Select the firmware mode used for booting.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader.grub.enable = lib.mkForce false;

    boot.plymouth.enable = cfg.splash;

    boot.loader = {
      timeout = lib.mkDefault 0;

      efi = lib.mkIf (cfg.firmware == "uefi") {
        efiSysMountPoint = "/boot";
        canTouchEfiVariables = true;
      };

      limine = lib.mkIf (cfg.firmware == "bios") {
        enable = true;
      };

      systemd-boot = lib.mkIf (cfg.firmware == "uefi") {
        enable = true;
        editor = lib.mkForce false;
        consoleMode = "auto";
        graceful = lib.mkDefault true;
        configurationLimit = lib.mkDefault 10;
      };
    };

    boot.kernelParams =
      (lib.optionals cfg.quiet [
        "quiet"
        "loglevel=3"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
        "systemd.show_status=auto"
      ])
      ++ (lib.optionals cfg.verbose [
        "loglevel=7"
        "systemd.show_status=1"
      ])
      ++ (lib.optionals cfg.splash [
        "splash"
      ])
      ++ [
        "boot.shell_on_fail"
      ];

    boot.consoleLogLevel = if cfg.quiet then lib.mkForce 0 else lib.mkForce 7;

    boot.initrd = {
      includeDefaultModules = lib.mkDefault false;
      inherit (cfg) verbose;
      systemd.enable = true;
    };
  };
}
