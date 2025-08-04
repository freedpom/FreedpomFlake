{
  lib,
  config,
  ...
}:
let
  cfg = config.ff.system.preservation;

  parsePackages =
    user:
    lib.map (d: (builtins.parseDrvName d.name).name) (
      config.home-manager.users.${user}.home.packages ++ config.environment.systemPackages
    );

  preserveProgs =
    user: list:
    lib.flatten (lib.attrValues (lib.filterAttrs (n: _v: lib.elem n (parsePackages user)) list));

  mkPreserveHome = user: {
    directories = (preserveProgs user progDirs) ++ homeDirs ++ cfg.homeExtraDirs;
    files = (preserveProgs user progFiles) ++ homeFiles ++ cfg.homeExtraFiles;
  };

  homeDirs = [
    "Documents"
    "Downloads"
    "Music"
    "Pictures"
    "Videos"
    ".ssh"
  ];

  homeFiles = [ ];

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

  progFiles = { };

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

in
{

  options.ff.system.preservation = {

    enable = lib.mkEnableOption "Enable system persistence";

    preserveHome = lib.mkEnableOption "Preserve user directories on an ephemeral /home";

    storageDir = lib.mkOption {
      type = lib.types.str;
      default = "/nix/persist";
      description = "Directory where persistent data will be stored";
    };

    extraDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra directories to be persisted";

    };

    extraFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra files to be persisted";
    };

    homeExtraDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra directories to be persisted";

    };

    homeExtraFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra files to be persisted";
    };
  };

  config = lib.mkIf cfg.enable {
    preservation = {
      enable = true;
      preserveAt.${cfg.storageDir} = {
        directories = [
          "/var/log"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/var/lib/tailscale"
          "/etc/NetworkManager/system-connections"
        ] ++ cfg.extraDirs;
        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
        ] ++ cfg.extraFiles;
        users = lib.mkIf cfg.preserveHome (
          lib.genAttrs (lib.attrNames config.home-manager.users) mkPreserveHome
        );
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
      tmpfiles.settings.preservation = lib.mkIf cfg.preserveHome (
        lib.mkMerge (lib.map tmpRules (lib.attrNames config.home-manager.users))
      );
    };
  };
}
