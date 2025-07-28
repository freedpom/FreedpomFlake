{
  lib,
  config,
  ...
}:
let
  cfg = config.ff.system.preservation;
in
{

  options.ff.system.preservation = {

    enable = lib.mkEnableOption "Enable system persistence";

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
          { file = "/etc/machine-id"; inInitrd = true; }
        ] ++ cfg.extraFiles;
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
