{
  config,
  lib,
  ...
}: let
  cfg = config.ff.system.preservation;

  # Return a list of all normal users
  users = lib.attrNames (lib.filterAttrs (_n: v: v.isNormalUser) config.users.users);
  userAs = config.ff.userConfig.users;

  # Return a list of all packages installed on the system
  parsePackages = user:
    lib.map (d: (builtins.parseDrvName d.name).name) (
      config.home-manager.users.${user}.home.packages ++ config.environment.systemPackages
    );

  # Compare list of parsed packages to homeProgDirs or homeProgFiles, output list of attribute values
  preserveProgs = user: pd:
    lib.flatten (lib.attrValues (lib.filterAttrs (n: _v: lib.elem n (parsePackages user)) pd));

  # Return an attribute set of directories and files that must be preserved
  mkPreserveHome = user: {
    directories = (preserveProgs user homeProgDirs) ++ homeDirs ++ userAs.${user}.preservation.directories;
    files = (preserveProgs user homeProgFiles) ++ homeFiles ++ userAs.${user}.preservation.files;
    commonMountOptions = ["x-gvfs-hide"] ++ userAs.${user}.preservation.mountOptions;
  };

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
  sysProgDirs = [
    (lib.optionals config.hardware.bluetooth.enable "/var/lib/bluetooth")
    (lib.optionals config.services.tailscale.enable "/var/lib/tailscale")
  ];

  # Files in / that should be preserved if a program is enabled
  sysProgFiles = [
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

  # Directories in $HOME that should be preserved if a program is installed
  homeProgDirs = {
    firefox = ".mozilla";
    gh = ".config/gh";
    legcord = ".config/legcord";
    librewolf = ".librewolf";
    tidal-hifi = ".config/tidal-hifi";
    wivrn = ".config/wivrn";
    steam = ".local/share/Steam";
    stremio-shell = [
      ".stremio-server"
      ".local/share/Smart Code ltd/Stremio"
    ];
  };

  # Files in $HOME that should be preserved if a program is installed
  homeProgFiles = {};

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
in {
  preservation = {
    enable = true;
    preserveAt.${cfg.storageDir} = {
      directories = sysDirs ++ sysProgDirs ++ cfg.extraDirs;
      files = sysFiles ++ sysProgFiles ++ cfg.extraFiles;
      users = lib.mkIf cfg.preserveHome (lib.genAttrs users mkPreserveHome);
    };
  };

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
    tmpfiles.settings.preservation = lib.mkIf cfg.preserveHome (lib.foldl' (r: u: r // tmpRules u) {} users);
  };
}
