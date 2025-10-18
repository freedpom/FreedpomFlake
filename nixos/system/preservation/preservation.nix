{
  config,
  lib,
  ...
}: let
  cfg = config.ff.system.preservation;

  # Directories in / that should always be preserved
  sysDirs = [
    "/var/log"
    "/var/lib/nixos"
    "/var/lib/systemd/coredump"
    "/etc/NetworkManager/system-connections"
  ];

  # Files in / that should always be preserved
  sysFiles = [
    {
      file = "/etc/machine-id";
      inInitrd = true;
    }
  ];

  # Directories in / that should be preserved if a program is enabled
  sysProgDirs = lib.flatten [
    (lib.mkIf config.hardware.bluetooth.enable "/var/lib/bluetooth")
    (lib.mkIf config.services.tailscale.enable "/var/lib/tailscale")
    (lib.mkIf config.virtualisation.libvirtd.enable "/var/lib/libvirt")
  ];

  # Files in / that should be preserved if a program is enabled
  sysProgFiles = [
  ];

  # Directory for nix builds, will not be preserved if set to /tmp
  build-dir = lib.optionals (cfg.build-dir != "/tmp") [
    {
      directory = "${cfg.build-dir}";
      mode = "0755";
    }
  ];

  # Directories in $HOME that should always be preserved
  homeDirs = [
    "Documents"
    "Downloads"
    "Music"
    "Pictures"
    "Videos"
    ".ssh"
  ];

  # Files in $HOME that should always be preserved
  homeFiles = [];

  # Directories and files in $HOME that should be preserved if a program is installed
  homePaths = import ./homePaths.nix;

  # Some directories need tmpfiles rules otherwise they will be owned by root
  tmpRules = u: let
    defaults = {
      inherit (config.users.users.${u}) group;
      user = u;
      mode = "0755";
    };
  in {
    "/home/${u}/.config".d = defaults;
    "/home/${u}/.local".d = defaults;
    "/home/${u}/.local/share".d = defaults;
    "/home/${u}/.local/state".d = defaults;
  };

  # Return a list of all normal users
  users = lib.attrNames (lib.filterAttrs (_n: v: v.isNormalUser) config.users.users);
  userCfg = config.ff.userConfig.users;

  # Return a list of all packages installed on the system
  parsePackages = user:
    lib.map (d: (builtins.parseDrvName d.name).name) (
      config.environment.systemPackages
      ++ config.users.users.${user}.packages
      ++ lib.optionals (
        config ? "home-manager" && config.home-manager.users ? ${user}
      )
      config.home-manager.users.${user}.home.packages
    );

  # Compare list of parsed packages to an attribute set of package names and directories, output list of attribute values
  preserveProgs = user: pd:
    lib.flatten (lib.attrValues (lib.filterAttrs (n: _v: lib.elem n (parsePackages user)) pd));

  # Return an attribute set of directories and files that must be preserved
  mkPreserveHome = user: {
    directories =
      (preserveProgs user homePaths.directories)
      ++ homeDirs
      ++ lib.optionals (userCfg ? ${user}) userCfg.${user}.preservation.directories;
    files =
      (preserveProgs user homePaths.files)
      ++ homeFiles
      ++ lib.optionals (userCfg ? ${user}) userCfg.${user}.preservation.files;
    commonMountOptions =
      [
        "x-gvfs-hide"
      ]
      ++ lib.optionals (userCfg ? ${user}) userCfg.${user}.preservation.mountOptions;
  };
in {
  config = lib.mkIf cfg.enable {
    ### Preserve files and directories based on the above
    preservation = {
      enable = true;
      preserveAt.${cfg.storageDir} = {
        directories = sysDirs ++ sysProgDirs ++ cfg.directories ++ build-dir;
        files = sysFiles ++ sysProgFiles ++ cfg.files;
        users = lib.mkIf cfg.preserveHome (lib.genAttrs users mkPreserveHome);
      };
    };

    # Set nix build directory
    nix.settings.build-dir = cfg.build-dir;

    # Modify default machine-id service to use actual file location
    systemd = {
      services.systemd-machine-id-commit = {
        unitConfig.ConditionPathIsMountPoint = [
          ""
          "/persistent/etc/machine-id"
        ];
        serviceConfig.ExecStart = [
          ""
          "systemd-machine-id-setup --commit --root ${cfg.storageDir}"
        ];
      };

      # Generate tmpfiles settings for each user
      tmpfiles.settings.preservation = lib.mkIf cfg.preserveHome (
        lib.foldl' (r: u: r // tmpRules u) {} users
      );
    };
  };
}
