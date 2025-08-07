{
  lib,
  config,
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

  # Compare list of parsed packages to progDirs or progFiles, output list of attribute values
  preserveProgs = user: pd:
    lib.flatten (lib.attrValues (lib.filterAttrs (n: _v: lib.elem n (parsePackages user)) pd));

  # Return an attribute set of directories and files that must be preserved
  mkPreserveHome = user: {
    directories = (preserveProgs user progDirs) ++ homeDirs ++ userAs.${user}.preservation.directories;
    files = (preserveProgs user progFiles) ++ homeFiles ++ userAs.${user}.preservation.files;
    commonMountOptions = userAs.${user}.preservation.mountOptions;
  };

  # Directories in / that should always be preserved
  sysDirs = [
    "/var/log"
    "/var/lib/nixos"
    "/var/lib/systemd/coredump"
    "/var/lib/tailscale"
    "/etc/NetworkManager/system-connections"
  ];

  # Files in / that should always be preserved
  sysFiles = [
    {
      file = "/etc/machine-id";
      inInitrd = true;
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

  # Directories in $HOME that should be preserved if a program is installed
  progDirs = {
    firefox = ".mozilla";
    gh = ".config/gh";
    legcord = ".config/legcord";
    librewolf = ".librewolf";
    tidal-hifi = ".config/tidal-hifi";
    wivrn = ".config/wivrn";
    steam = ".local/share/steam";
    stremio-shell = [
      ".stremio-server"
      ".local/share/Smart Code ltd/Stremio"
    ];
  };

  # Files in $HOME that should be preserved if a program is installed
  progFiles = {};

  # Some directories need tmpfiles rules otherwise they will be owned by root
  tmpRules = u: {
    "/home/${u}/.config".d = {
      user = u;
      inherit (config.users.users.${u}) group;
      mode = "0755";
    };
    "/home/${u}/.local".d = {
      user = u;
      inherit (config.users.users.${u}) group;
      mode = "0755";
    };
    "/home/${u}/.local/share".d = {
      user = u;
      inherit (config.users.users.${u}) group;
      mode = "0755";
    };
    "/home/${u}/.local/state".d = {
      user = u;
      inherit (config.users.users.${u}) group;
      mode = "0755";
    };
  };
in {
  options.ff.system.preservation = {
    enable = lib.mkEnableOption "Enable preservation";

    preserveHome = lib.mkEnableOption "Preserve user directories on an ephemeral /home";

    storageDir = lib.mkOption {
      type = lib.types.str;
      default = "/nix/persist";
      description = "Directory where persistent data will be stored";
    };

    extraDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra directories to be preserved";
    };

    extraFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra files to be preserved";
    };

    homeExtraDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra $HOME directories to be preserved";
    };

    homeExtraFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra $HOME files to be preserved";
    };
  };

  config = lib.mkIf cfg.enable {
    preservation = {
      enable = true;
      preserveAt.${cfg.storageDir} = {
        directories = sysDirs ++ cfg.extraDirs;
        files = sysFiles ++ cfg.extraFiles;
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
      tmpfiles.settings.preservation = lib.mkIf cfg.preserveHome (lib.mkMerge (lib.map tmpRules users));
    };
  };
}
