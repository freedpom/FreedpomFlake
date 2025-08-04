{
  lib,
  config,
  ...
}:
let
  cfg = config.ff.system.preservation;

  enabledUserProgs =
    user:
    lib.attrNames (
      lib.filterAttrs (
        _name: value:
        let
          result = builtins.tryEval (value.enable or false);
        in
        result.success && result.value
      ) config.home-manager.users.${user}.programs
    );

  preserveProgs =
    user: list:
    lib.flatten (lib.attrValues (lib.filterAttrs (n: _v: lib.elem n (enabledUserProgs user)) list));

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
    ".config/wivrn" # need to read system programs
    ".local/share/steam"
    ".stremio-server" # need to read home.packages
    ".local/share/Smart Code ltd/Stremio"
    {
      directory = ".config/legcord";
      configureParent = true;
    }
  ];
  homeFiles = [ ];
  progDirs = {
    firefox = ".mozilla";
    gh = ".config/gh";
    librewolf = ".librewolf";
    tidal-hifi = ".config/tidal-hifi";
  };
  progFiles = { };

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
    systemd.services.systemd-machine-id-commit = {
      unitConfig.ConditionPathIsMountPoint = [
        ""
        "/persistent/etc/machine-id"
      ];
      serviceConfig.ExecStart = [
        ""
        "systemd-machine-id-setup --commit --root ${cfg.storageDir}"
      ];
    };
  };
}
