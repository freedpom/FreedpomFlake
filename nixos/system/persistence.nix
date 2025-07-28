{
  lib,
  config,
  ...
}:
let
  cfg = config.ff.system.preservation;

  enabledUserProgs = user: lib.attrNames (lib.filterAttrs (name: value: let result = builtins.tryEval (value.enable or false); in result.success && result.value) config.home-manager.users.${user}.programs);
  preserveProgs = user: list: lib.attrValues (lib.filterAttrs (n: _v: lib.elem n (enabledUserProgs user)) list);
  mkPreserveHome = user: {
    directories = (preserveProgs user progDirs) ++ cfg.homeExtraDirs;
    files = (preserveProgs user progFiles) ++ cfg.homeExtraFiles;
  };
  progDirs = { };
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

    extraDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra directories to be persisted";

    };

    extraFiles = lib.mkOption {
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
        ] ++ cfg.extraDirectories;
        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
        ] ++ cfg.extraFiles;
        users = lib.mkif cfg.preserveHome lib.genAttrs (lib.attrNames config.home-manager.users) mkPreserveHome;
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
