{
  lib,
  config,
  ...
}:

let
  cfg = config.ff.system.boot;
in
{
  options.ff.system.boot = {
    enable = lib.mkEnableOption "Enable the bootloader module.";

    verbosity = lib.mkOption {
      type = lib.types.enum [
        "quiet"
        "normal"
        "verbose"
      ];
      default = "quiet";
      description = "Controls boot verbosity level: quiet, normal, or verbose.";
    };

    splash = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the graphical splash screen.";
    };

    nvme-nopower = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "When enabled, this will disable nvme APST and ACPI (power management features).";
    };

    hard = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "make the kernel hard ;)";
    };

    firmware = lib.mkOption {
      type = lib.types.enum [
        "uefi"
        "bios"
      ];
      default = "uefi";
      description = "Select the firmware mode used for booting.";
    };

    loaderEntries = lib.mkOption {
      type = lib.types.int;
      default = 9;
      description = "Maximum number of loader entries to keep.";
    };

    editor = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable or disable the boot editor.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      loader.grub.enable = lib.mkForce false;
      plymouth.enable = cfg.splash;

      loader = {
        timeout =
          if cfg.verbosity == "quiet" then
            0
          else if cfg.verbosity == "normal" then
            3
          else
            6;

        efi = lib.mkIf (cfg.firmware == "uefi") {
          efiSysMountPoint = "/boot";
          canTouchEfiVariables = true;
        };

        limine = lib.mkIf (cfg.firmware == "bios") {
          enable = true;
          enableEditor = cfg.editor;
          maxGenerations = cfg.loaderEntries;
          biosSupport = true;
        };

        systemd-boot = lib.mkIf (cfg.firmware == "uefi") {
          enable = true;
          inherit (cfg) editor;
          consoleMode = "auto";
          graceful = lib.mkDefault true;
          configurationLimit = cfg.loaderEntries;
        };
      };

      blacklistedKernelModules = [
        # Obscure network protocols
        "ax25"
        "netrom"
        "rose"

        # Old or rare or insufficiently audited filesystems
        "adfs"
        "affs"
        "bfs"
        "befs"
        "cramfs"
        "efs"
        "erofs"
        "exofs"
        "freevxfs"
        "f2fs"
        "hfs"
        "hpfs"
        "jfs"
        "minix"
        "nilfs2"
        "ntfs"
        "omfs"
        "qnx4"
        "qnx6"
        "sysv"
        "ufs"
      ];

      kernelParams =
        (lib.optionals (cfg.verbosity == "quiet") [
          "quiet"
          "loglevel=3"
          "rd.udev.log_level=3"
          "udev.log_priority=3"
          "systemd.show_status=auto"
        ])
        ++ (lib.optionals (cfg.verbosity == "verbose") [
          "loglevel=7"
          "systemd.show_status=1"
          "boot.shell_on_fail"
        ])
        ++ (lib.optionals cfg.splash [
          "splash"
        ])
        ++ (lib.optionals cfg.nvme-nopower [
          "nvme.noacpi=1"
          "nvme_core.default_ps_max_latency_us=0"
        ])
        ++ (lib.optionals cfg.hard [
          # Don't merge slabs
          "slab_nomerge"
          # Overwrite free'd pages
          "page_poison=1"
          # Enable page allocator randomization
          "page_alloc.shuffle=1"
          # Disable debugfs
          "debugfs=off"
        ]);
      consoleLogLevel = if cfg.verbosity == "quiet" then lib.mkForce 0 else lib.mkForce 7;
      initrd = {
        includeDefaultModules = lib.mkDefault false;
        verbose = cfg.verbosity == "verbose";
        systemd.enable = true;
      };
    };
  };
}
